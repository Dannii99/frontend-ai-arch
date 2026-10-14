#!/usr/bin/env bash
#
# install.sh — equipa CUALQUIER proyecto con este ecosistema de IA.
#
# Qué hace, en orden:
#   1. Detecta el package manager, el STACK del proyecto (Angular/React/Next) leyendo package.json,
#      y la VERSIÓN instalada de cada framework (avisa si queda fuera del rango que cubren las skills)
#   2. Detecta el AGENTE de IA (si hay 0 o varios, pregunta; si hay 1, sigue)
#   3. Chequea los MOTORES (OpenSpec, Engram). Si falta alguno, te dice cuál y
#      OFRECE instalarlo con el comando correcto para tu SO (no instala a la fuerza)
#   4. Instala las SKILLS relevantes: core/ (siempre) + la del framework detectado,
#      más agents/ (roles + subagentes, destino garantizado) y los comandos
#      /fea:* (best-effort, no bloqueante)
#   5. Orquesta OpenSpec y Engram (que hacen su propio wiring por-agente), y
#      cablea los MCP de Playwright (revisión en vivo), Context7 y el MCP oficial
#      del framework (doc viva por versión — ver framework-version-awareness)
#
# Núcleo portable (idéntico en todo agente): skills, agents (roles + subagentes), bloque de AGENTS.md.
# Capa de adaptadores (lo único agent-specific): DÓNDE va cada cosa.
#
# Uso:
#   ./install.sh                          # sobre el proyecto actual, autodetecta todo
#   ./install.sh --project /ruta/al/proyecto
#   ./install.sh --agent claude|cursor|codex|opencode   # fuerza el agente
#   ./install.sh --yes                    # responde sí a las ofertas de instalación
#   ./install.sh --dry-run                # muestra el plan sin tocar nada
#   ./install.sh --with conversion-ui     # instala skill(s) opt-in de domains/
#
set -euo pipefail

# ---------------------------------------------------------------------------
# Configuración y flags
# ---------------------------------------------------------------------------
ARCH_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(pwd)"
AGENT=""
ASSUME_YES=0
DRY_RUN=0
DOMAINS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project) PROJECT_DIR="$(cd "$2" && pwd)"; shift 2 ;;
    --agent)   AGENT="$2"; shift 2 ;;
    --yes|-y)  ASSUME_YES=1; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    --with)    IFS=',' read -ra _d <<< "$2"; DOMAINS+=("${_d[@]}"); shift 2 ;;
    -h|--help) grep '^#' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "Opción desconocida: $1"; exit 1 ;;
  esac
done

# ---------------------------------------------------------------------------
# Helpers de salida y confirmación
# ---------------------------------------------------------------------------
log()  { printf '  %s\n' "$*"; }
ok()   { printf '  \033[32m✓\033[0m %s\n' "$*"; }
warn() { printf '  \033[33m•\033[0m %s\n' "$*"; }
step() { printf '\n\033[1m%s\033[0m\n' "$*"; }
run()  { if [[ $DRY_RUN -eq 1 ]]; then log "[dry-run] $*"; else eval "$*"; fi; }

# confirm "pregunta" -> 0 (sí) / 1 (no). Respeta --yes y entornos sin terminal.
confirm() {
  [[ $ASSUME_YES -eq 1 ]] && return 0
  if [[ ! -t 0 ]]; then warn "sin terminal interactiva; se omite (usá --yes para forzar)"; return 1; fi
  read -r -p "  ¿$1 [y/N] " r; [[ "$r" =~ ^[yY]$ ]]
}

# ---------------------------------------------------------------------------
# 1. Detección de package manager y stack
# ---------------------------------------------------------------------------
detect_pm() {
  if   [[ -f "$PROJECT_DIR/pnpm-lock.yaml" ]]; then echo "pnpm"
  elif [[ -f "$PROJECT_DIR/yarn.lock" ]];      then echo "yarn"
  elif [[ -f "$PROJECT_DIR/bun.lockb" ]];      then echo "bun"
  else echo "npm"; fi
}

has_dep() { grep -q "\"$1\"" "$PROJECT_DIR/package.json" 2>/dev/null; }

# Paquete npm que define la versión de cada framework (el mismo que declara
# metadata.versions.package en su skill de arquitectura).
framework_package() { case "$1" in angular) echo "@angular/core" ;; next) echo "next" ;; react) echo "react" ;; esac; }

# installed_version <paquete> -> "<versión>|<origen>" (origen: instalada|rango).
# Prioriza lo instalado de verdad (node_modules); si no hay, cae al rango de
# package.json sin el prefijo (^19.2.0 -> 19.2.0) y lo marca como "rango".
# No parsea lockfiles en bash (frágil entre npm/pnpm/yarn/bun): eso lo hace
# el agente en runtime, ver framework-version-awareness.
installed_version() {
  local pkg="$1" f="$PROJECT_DIR/node_modules/$1/package.json" v=""
  if [[ -f "$f" ]]; then
    v="$(grep -m1 '"version"' "$f" | sed -E 's/.*"version" *: *"([^"]+)".*/\1/')"
    [[ -n "$v" ]] && { echo "$v|instalada"; return; }
  fi
  v="$(grep -m1 "\"$pkg\" *:" "$PROJECT_DIR/package.json" 2>/dev/null \
        | sed -E "s#.*\"$pkg\" *: *\"([^\"]+)\".*#\\1#" | sed -E 's/^[^0-9]*//')"
  [[ -n "$v" ]] && echo "$v|rango" || true
}

# skill_version_field <framework> <campo> -> valor de metadata.versions.<campo>
# en la skill de arquitectura de ese framework (ej. verified_against).
skill_version_field() {
  local skill="$ARCH_DIR/skills/$1/$1-architecture/SKILL.md"
  [[ -f "$skill" ]] || return 0
  grep -m1 -E "^ +$2:" "$skill" | sed -E 's/^ +[a-z_]+: *"?([^"]*)"?.*/\1/'
}

# check_version_drift <framework> <versión>: compara la versión mayor del
# proyecto contra el rango que cubre la skill. Nunca bloquea — avisa que el
# agente va a verificar contra doc viva en las áreas que toque.
check_version_drift() {
  local fw="$1" v="$2" major min ver
  major="${v%%.*}"
  [[ "$major" =~ ^[0-9]+$ ]] || return 0
  min="$(skill_version_field "$fw" min_supported)"
  ver="$(skill_version_field "$fw" verified_against)"
  [[ "$min" =~ ^[0-9]+$ && "$ver" =~ ^[0-9]+$ ]] || return 0
  if (( major < min )); then
    warn "$fw $v es anterior a lo que cubre $fw-architecture (v$min–v$ver): el agente va a verificar las APIs contra la doc de v$major antes de usarlas"
  elif (( major > ver )); then
    warn "$fw $v es más nuevo que lo verificado en $fw-architecture (v$min–v$ver): el agente va a consultar doc viva de v$major en las áreas que toque (y reportar desfases)"
  else
    ok "$fw $v dentro del rango verificado de las skills (v$min–v$ver)"
  fi
}

# ---------------------------------------------------------------------------
# 2. Adaptadores por agente: rutas y capacidades
# ---------------------------------------------------------------------------
AGENT_BINS=(claude cursor codex opencode)

skills_dir_for() {
  case "$1" in
    claude)   echo "$HOME/.claude/skills" ;;
    cursor)   echo "$PROJECT_DIR/.cursor/skills" ;;      # cursor: a nivel proyecto
    codex)    echo "$HOME/.codex/skills" ;;
    opencode) echo "$HOME/.config/opencode/skills" ;;    # confirmado: opencode.ai/docs/skills
  esac
}
# commands/ es best-effort: a diferencia de skills_dir_for() (que es el
# requisito núcleo y hace exit 1 si no hay match), esta puede devolver "" —
# el custom-slash-command no es parte de los 3 estándares abiertos del
# proyecto (Agent Skills, AGENTS.md, MCP), es nativo de Claude Code. Si
# devuelve vacío, copy_optional_dir() avisa y sigue.
commands_dir_for() {
  case "$1" in
    claude)   echo "$HOME/.claude/commands" ;;
    cursor)   echo "$HOME/.cursor/commands" ;;           # verificar soporte de custom commands
    codex)    echo "" ;;                                  # sin comandos custom conocidos
    opencode) echo "$HOME/.config/opencode/commands" ;;   # confirmado: opencode.ai/docs/commands
  esac
}
# agents/ SÍ tiene destino garantizado para los 4 agentes (mismo criterio que
# skills_dir_for() — antes esto lo cubría la copia especial de personas/ a
# $SKILLS_DIR/_personas; ahora agents/ incluye esos roles y asume esa
# garantía directamente). En claude, además, esta ruta es la carpeta nativa
# de subagentes (Task tool). En los demás, es "mejor esfuerzo con ruta real":
# el archivo llega, aunque el agente no lo invoque nativamente como subagente.
agents_dir_for() {
  case "$1" in
    claude)   echo "$HOME/.claude/agents" ;;
    cursor)   echo "$PROJECT_DIR/.cursor/agents" ;;       # verificar soporte nativo de subagents
    codex)    echo "$HOME/.codex/agents" ;;               # sin subagents nativos conocidos — carpeta de referencia
    opencode) echo "$HOME/.config/opencode/agents" ;;     # confirmado: opencode.ai/docs/agents
  esac
}
# Nombre que espera 'engram setup <agente>'
engram_agent_arg() { case "$1" in claude) echo "claude-code" ;; *) echo "$1" ;; esac; }
# OpenSpec NO necesita una función equivalente: sus tool IDs (--tools) son
# idénticos a nuestro $AGENT — claude, cursor, codex, opencode — 1:1. Se pasa
# "$AGENT" directo a `openspec init --tools`. Ver "Orquestar los motores".
reads_agentsmd_natively() { case "$1" in cursor|codex|opencode) return 0 ;; *) return 1 ;; esac; }

detect_agents() {
  local found=()
  for a in "${AGENT_BINS[@]}"; do command -v "$a" >/dev/null 2>&1 && found+=("$a"); done
  printf '%s\n' "${found[@]}"
}

# ---------------------------------------------------------------------------
# 3. Motores: chequear y ofrecer instalar
# ---------------------------------------------------------------------------
os_kind() { case "$(uname -s)" in Darwin) echo mac ;; Linux) echo linux ;; MINGW*|MSYS*|CYGWIN*) echo windows ;; *) echo other ;; esac; }
# Arquitectura en el vocabulario de los releases de Engram (amd64/arm64)
arch_kind() { case "$(uname -m)" in x86_64|amd64) echo amd64 ;; arm64|aarch64) echo arm64 ;; *) echo "" ;; esac; }

ensure_openspec() {
  command -v openspec >/dev/null 2>&1 && { ok "OpenSpec ya instalado"; return; }
  local pm cmd; pm="$(detect_pm)"
  case "$pm" in
    pnpm) cmd="pnpm add -g @fission-ai/openspec@latest" ;;
    yarn) cmd="yarn global add @fission-ai/openspec@latest" ;;
    bun)  cmd="bun add -g @fission-ai/openspec@latest" ;;
    *)    cmd="npm install -g @fission-ai/openspec@latest" ;;
  esac
  warn "OpenSpec no está instalado."
  if confirm "instalar OpenSpec con: $cmd"; then run "$cmd" && ok "OpenSpec instalado"
  else warn "se salta OpenSpec (sin workflow SDD)"; fi
}

ensure_engram() {
  command -v engram >/dev/null 2>&1 && { ok "Engram ya instalado"; return; }
  local cmd=""
  if [[ "$(os_kind)" == "mac" ]] && command -v brew >/dev/null 2>&1; then
    cmd="brew install gentleman-programming/tap/engram"
  elif command -v go >/dev/null 2>&1; then
    cmd="go install github.com/Gentleman-Programming/engram/cmd/engram@latest"
  fi
  warn "Engram no está instalado."
  if [[ -n "$cmd" ]]; then
    if confirm "instalar Engram con: $cmd"; then run "$cmd" && ok "Engram instalado"
    else warn "se salta Engram (sin memoria persistente)"; fi
    return
  fi
  # Sin brew ni go: fallback a bajar el binario pre-compilado de GitHub
  # Releases para tu OS/arch y dejarlo en ~/.local/bin (mismo directorio que
  # ya usan otros binarios de este flujo, p. ej. el de Claude Code).
  if confirm "no encontré brew ni go — ¿instalar Engram descargando el binario de GitHub Releases a \$HOME/.local/bin?"; then
    if install_engram_from_release; then ok "Engram instalado en \$HOME/.local/bin"
    else warn "no pude resolver/instalar un binario para tu OS/arch automáticamente. Si ya se descargó, revisá que \$HOME/.local/bin esté en tu PATH; si no, instalalo a mano desde: https://github.com/Gentleman-Programming/engram/releases"; fi
  else
    warn "se salta Engram (sin memoria persistente). Alternativa manual: https://github.com/Gentleman-Programming/engram/releases"
  fi
}

# Resuelve, sin depender de jq, la URL del asset de la última release de
# Engram que matchea <os>_<arch>.<ext> (zip en windows, tar.gz en mac/linux).
# Buscar por patrón en vez de reconstruir el nombre a mano evita romperse si
# el formato de versión del asset cambia.
engram_release_asset_url() {
  local os="$1" arch="$2" ext pattern
  case "$os" in
    windows) ext="zip" ;;
    *)       ext="tar.gz" ;;
  esac
  pattern="${os}_${arch}\\.${ext}"
  curl -fsSL "https://api.github.com/repos/Gentleman-Programming/engram/releases/latest" 2>/dev/null \
    | grep -o "https://github.com/Gentleman-Programming/engram/releases/download/[^\"]*${pattern}" \
    | head -1
}

install_engram_from_release() {
  local os arch url tmp
  os="$(os_kind)"; arch="$(arch_kind)"
  if [[ "$os" == "other" || -z "$arch" ]]; then return 1; fi
  url="$(engram_release_asset_url "$os" "$arch")"
  [[ -n "$url" ]] || return 1
  tmp="$(mktemp -d)"
  run "mkdir -p '$HOME/.local/bin'"
  if [[ "$os" == "windows" ]]; then
    run "curl -fsSL '$url' -o '$tmp/engram.zip' && unzip -oq '$tmp/engram.zip' -d '$tmp' && mv -f '$tmp/engram.exe' '$HOME/.local/bin/engram.exe'"
  else
    run "curl -fsSL '$url' -o '$tmp/engram.tar.gz' && tar -xzf '$tmp/engram.tar.gz' -C '$tmp' && chmod +x '$tmp/engram' && mv -f '$tmp/engram' '$HOME/.local/bin/engram'"
  fi
  rm -rf "$tmp" 2>/dev/null || true
  [[ $DRY_RUN -eq 1 ]] && return 0
  command -v engram >/dev/null 2>&1
}

# Engram guarda todo en una sola SQLite global (un binario, un `engram setup
# <agente>` por máquina — no por proyecto). Pero cada memoria se etiqueta con
# un project_name que Engram auto-detecta por el repo git en el que estés
# parado, así que memorias de proyectos distintos no se mezclan solas. Este
# archivo "fija" ese nombre para evitar drift si el proyecto se mueve o
# renombra (ver AGENT-SETUP.md de Engram: "lock write tools to the canonical
# project"). No depende de que el binario esté instalado — es el archivo que
# Engram va a leer apenas se use en este repo.
ensure_engram_project_config() {
  local cfg="$PROJECT_DIR/.engram/config.json" name; name="$(basename "$PROJECT_DIR")"
  if [[ -f "$cfg" ]]; then ok "Engram: .engram/config.json ya existe (project_name fijado)"; return; fi
  if [[ $DRY_RUN -eq 1 ]]; then log "[dry-run] crearía .engram/config.json (project_name=$name)"; return; fi
  mkdir -p "$PROJECT_DIR/.engram"
  printf '{\n  "project_name": "%s"\n}\n' "$name" > "$cfg"
  ok "Engram: .engram/config.json creado (project_name=$name)"
}

# Playwright MCP no es un binario global a instalar (se sirve vía `npx` bajo
# demanda) — lo que hace falta es REGISTRARLO como MCP server para "$AGENT".
# Por eso no sigue el patrón command -v de ensure_openspec/ensure_engram: se
# llama más abajo, junto al wiring por-agente de OpenSpec/Engram (sección
# "Orquestar los motores"), no en "Chequeando motores…".
# ensure_mcp_server <nombre> <scope-claude> <aviso-si-se-salta> <args de npx...>
# Registra un MCP server que se lanza con `npx <args>`. Mismo esquema para
# todos los MCP del ecosistema: en claude lo registra (idempotente, chequea
# `claude mcp list` primero); en cursor/codex imprime el snippet manual
# (auto-escribir esos archivos arriesga romper una config existente); en
# opencode solo apunta, porque el formato no está confirmado.
# scope-claude: "local" = por proyecto (se registra parado en $PROJECT_DIR,
# que es la clave del scope local), "user" = global para la persona.
json_args() { local out="" a; for a in "$@"; do out+="${out:+, }\"$a\""; done; echo "[$out]"; }
ensure_mcp_server() {
  local name="$1" scope="$2" skip_msg="$3"; shift 3
  local args=("$@")
  case "$AGENT" in
    claude)
      if command -v claude >/dev/null 2>&1 && (cd "$PROJECT_DIR" && claude mcp list 2>/dev/null) | grep -qi "^$name:"; then
        ok "$name MCP ya registrado en Claude Code"
      else
        warn "$name MCP no está registrado en Claude Code."
        if confirm "registrar con: claude mcp add -s $scope $name -- npx ${args[*]}"; then
          run "cd '$PROJECT_DIR' && claude mcp add -s $scope $name -- npx ${args[*]}"
          ok "$name MCP registrado"
        else
          warn "se salta — $skip_msg"
        fi
      fi
      ;;
    cursor)
      warn "Cursor: agregá manualmente a .cursor/mcp.json (o ~/.cursor/mcp.json):"
      log "  { \"mcpServers\": { \"$name\": { \"command\": \"npx\", \"args\": $(json_args "${args[@]}") } } }"
      ;;
    codex)
      warn "Codex CLI: agregá manualmente a ~/.codex/config.toml:"
      log "  [mcp_servers.$name]"
      log '  command = "npx"'
      log "  args = $(json_args "${args[@]}")"
      ;;
    opencode)
      warn "OpenCode: formato de MCP servers no confirmado en esta versión —"
      log "  revisá la doc de tu instalación y apuntá el server '$name' a: npx ${args[*]}"
      ;;
  esac
}

ensure_playwright_mcp() {
  ensure_mcp_server playwright local "/fea:review no va a poder abrir un browser real" @playwright/mcp@latest
}

# Doc viva por versión (ver skills/core/framework-version-awareness). Context7
# es la fuente genérica para los tres frameworks — scope user, no depende del
# proyecto. El MCP oficial del framework, cuando existe, va scope local: lee
# el workspace (versión, angular.json) del proyecto donde corre.
ensure_context7_mcp() {
  ensure_mcp_server context7 user "el agente va a caer a la doc web oficial cuando la versión no coincida con las skills" -y @upstash/context7-mcp
}
ensure_framework_mcp() {
  local fw
  for fw in "${FRAMEWORKS[@]}"; do
    case "$fw" in
      angular) ensure_mcp_server angular-cli local "sin search_documentation/get_best_practices del Angular CLI (queda Context7)" -y @angular/cli mcp ;;
      next)    ensure_mcp_server next-devtools local "sin la doc/diagnóstico oficial de Next (queda Context7)" -y next-devtools-mcp@latest ;;
      react)   log "React: sin MCP oficial de docs — la doc viva sale de Context7 (o react.dev)" ;;
    esac
  done
}

# ---------------------------------------------------------------------------
# 4. Instalar skills según stack + agents/ + commands/
# ---------------------------------------------------------------------------
copy_skill_group() {  # $1 = subcarpeta de skills/ ; $2 = dir destino
  local src="$ARCH_DIR/skills/$1"
  [[ -d "$src" ]] || return 0
  # ¿hay skills reales (carpetas con SKILL.md) adentro?
  if ! find "$src" -name SKILL.md -mindepth 1 2>/dev/null | grep -q .; then
    log "skills/$1 vacío por ahora — nada que copiar"; return 0
  fi
  run "mkdir -p '$2'"
  run "cp -R '$src/.' '$2/'"
  ok "skills '$1' instaladas"
}

copy_optional_dir() {  # $1 = dir origen ; $2 = dir destino (puede ser "") ; $3 = etiqueta para el log
  local src="$1" dst="$2" label="$3"
  [[ -d "$src" ]] || return 0
  if [[ -z "$dst" ]]; then
    warn "$label: sin destino conocido para '$AGENT' — se omite (podés seguir el flujo igual, ver $src/*.md como referencia)"
    return 0
  fi
  run "mkdir -p '$dst'"
  run "cp -R '$src/.' '$dst/'"
  ok "$label instalados"
}

# commands/fea/*.md está anidado bajo una subcarpeta (namespacing nativo de
# Claude Code: /fea:plan). OpenCode NO soporta subcarpetas para comandos
# (opencode.ai/docs/commands: el nombre de archivo ES el nombre del comando,
# sin nesting) — mismo motivo por el que OpenSpec instala sus propios
# comandos como opsx-apply.md (plano, con guion) para opencode en vez de
# opsx/apply.md (anidado, como sí hace para claude). Por eso comandos/ tiene
# su propia función en vez de reusar copy_optional_dir.
copy_commands() {  # $1 = agente
  local dst; dst="$(commands_dir_for "$1")"
  [[ -d "$ARCH_DIR/commands/fea" ]] || return 0
  if [[ -z "$dst" ]]; then
    warn "comandos /fea:*: sin destino conocido para '$1' — se omite (ver $ARCH_DIR/commands/fea/*.md como referencia)"
    return 0
  fi
  case "$1" in
    opencode)
      run "mkdir -p '$dst'"
      local f
      for f in "$ARCH_DIR"/commands/fea/*.md; do
        run "cp '$f' '$dst/fea-$(basename "$f")'"
      done
      ok "comandos /fea-* instalados (aplanados para opencode)"
      ;;
    *)
      run "mkdir -p '$dst'"
      run "cp -R '$ARCH_DIR/commands/.' '$dst/'"
      ok "comandos /fea:* instalados"
      ;;
  esac
}

list_domains() {  # nombres de domains disponibles (portable, sin xargs)
  local d
  for d in "$ARCH_DIR"/skills/domains/*/; do
    [[ -d "$d" ]] || continue
    basename "$d"
  done
}

copy_one_domain() {  # $1 = nombre del domain ; $2 = dir destino
  local src="$ARCH_DIR/skills/domains/$1"
  if [[ ! -f "$src/SKILL.md" ]]; then
    warn "domain '$1' no existe. Disponibles: $(list_domains | tr '\n' ' ')"
    return 1
  fi
  run "mkdir -p '$2/$1'"
  run "cp -R '$src/.' '$2/$1/'"
  ok "domain '$1' instalado (opt-in)"
}

# ---------------------------------------------------------------------------
# 5. Inyectar bloque de estándares en AGENTS.md (idempotente, sin pisar lo ajeno)
# ---------------------------------------------------------------------------
# Los 4 campos de "Reglas del proyecto" se identifican por su prefijo de
# bullet, no por rango de sección — así no se pisa "### Excepciones a los
# estándares" (debajo de esos bullets) al hacer splice.
PROJECT_RULE_FIELDS=("Stack" "Comando de build" "Comando de test" "Convenciones específicas" "Restricciones técnicas")

# extract_target_rule_value <target> <campo>
# Devuelve el valor actual de esa línea DENTRO del bloque FEA previo del
# target, si lo hay (vacío si no hay bloque previo, o no existe esa línea).
# Se llama ANTES de que inject_agents_block() pise el bloque viejo.
extract_target_rule_value() {
  local target="$1" field="$2"
  [[ -f "$target" ]] || return 0
  awk -v f="- $field:" '
    /<!-- FEA:START -->/ { infea=1 }
    infea && index($0, f) == 1 { sub("^" f " *", ""); print; exit }
    /<!-- FEA:END -->/ { infea=0 }
  ' "$target"
}

# extract_exception_bullets [--fea]
# Lee AGENTS.md por stdin y devuelve los bullets de "### Excepciones a los
# estándares": desde el primer "- " de esa sección hasta el fin del bloque FEA
# (con --fea, para el target) o el fin del archivo (sin --fea, para el
# AGENTS.md de este repo, que no lleva marcadores). El párrafo intro de la
# sección no se incluye: ese viene siempre de la versión nueva.
extract_exception_bullets() {
  local need_fea=0; [[ "${1:-}" == "--fea" ]] && need_fea=1
  awk -v need_fea="$need_fea" '
    /<!-- FEA:START -->/ { infea=1; next }
    /<!-- FEA:END -->/   { infea=0; insec=0; next }
    need_fea && !infea   { next }
    /^### Excepciones a los estándares/ { insec=1; inlist=0; next }
    insec && /^#/        { insec=0 }
    insec && !inlist && /^- / { inlist=1 }
    insec && inlist      { print }
  '
}

# ¿ya está completada esa línea (ni vacía ni un placeholder <!-- ... -->,
# viejo o nuevo formato)?
rule_value_is_filled() {
  local v="$1"
  [[ -n "$v" && "$v" != *'<!--'* ]]
}

inject_agents_block() {
  local target="$PROJECT_DIR/AGENTS.md" block; block="$(cat "$ARCH_DIR/AGENTS.md")"
  if [[ $DRY_RUN -eq 1 ]]; then log "[dry-run] inyectaría bloque de estándares en AGENTS.md"; return; fi
  touch "$target"

  # --- Reglas del proyecto: preservar > preguntar > dejar TODO ---
  local interactive=0
  [[ $ASSUME_YES -eq 0 && -t 0 ]] && interactive=1
  local any_preserved=0 any_prompted=0
  local field val
  for field in "${PROJECT_RULE_FIELDS[@]}"; do
    val="$(extract_target_rule_value "$target" "$field")"
    if rule_value_is_filled "$val"; then
      any_preserved=1                              # (a) ya estaba completo: preservar
    elif [[ $interactive -eq 1 ]]; then
      read -r -p "  ¿$field? (Enter para dejar el TODO): " val
      [[ -n "$val" ]] && any_prompted=1             # (b) interactivo: preguntar ahora
    else
      val=""                                        # (c) no-interactivo: se deja el
    fi                                               #     placeholder pristino de $block
    if [[ -n "$val" ]]; then
      local esc; esc="$(printf '%s' "$val" | sed -e 's/[\/&]/\\&/g')"
      block="$(printf '%s\n' "$block" | sed -E "s/^- $field: .*/- $field: $esc/")"
    fi
  done
  [[ $any_preserved -eq 1 ]] && ok "Reglas del proyecto: se preservaron respuestas ya cargadas"
  [[ $any_prompted  -eq 1 ]] && ok "Reglas del proyecto: respuestas nuevas cargadas"
  [[ $any_preserved -eq 0 && $any_prompted -eq 0 && $interactive -eq 0 ]] && \
    warn "Reglas del proyecto sin completar — quedan marcadores <!-- TODO: completar --> en AGENTS.md"

  # --- Excepciones a los estándares: preservar los bullets del target ---
  # Si el target ya tenía bullets propios (distintos del placeholder de esta
  # versión), se conservan tal cual; el intro de la sección se actualiza.
  # Asume que "Excepciones" es la última sección de AGENTS.md: el splice
  # corta $block en su primer bullet y le pega los del target.
  local old_exc new_exc
  old_exc="$(extract_exception_bullets --fea < "$target")"
  new_exc="$(printf '%s\n' "$block" | extract_exception_bullets)"
  if [[ -n "$old_exc" && "$old_exc" != "$new_exc" ]]; then
    block="$(printf '%s\n' "$block" | awk '
      /^### Excepciones a los estándares/ { insec=1 }
      insec && /^- / { exit }
      { print }
    ')"
    block="$block"$'\n\n'"$old_exc"  # $(...) se come la línea en blanco previa
    ok "Excepciones a los estándares: se preservaron las ya cargadas"
  fi

  # quita un bloque FEA previo si existe
  awk '/<!-- FEA:START -->/{s=1} s!=1{print} /<!-- FEA:END -->/{s=0}' "$target" > "$target.tmp"
  { cat "$target.tmp"; echo; echo "<!-- FEA:START -->"; echo "$block"; echo "<!-- FEA:END -->"; } > "$target"
  rm -f "$target.tmp"
  ok "AGENTS.md actualizado (bloque FEA)"
}

# ---------------------------------------------------------------------------
# 6. Manifiesto del proyecto (.fea/manifest.json — commiteable, refleja el
#    último install; a diferencia de ensure_engram_project_config() NO tiene
#    guard de existencia: se reescribe siempre, para poder diffearse en git
#    cuando el ecosistema se actualiza.
# ---------------------------------------------------------------------------

# sha256 portable: probamos sha256sum (linux/git-bash), shasum -a 256 (mac),
# openssl como último fallback (las tres plataformas soportadas traen al
# menos una).
sha256_file() {
  if command -v sha256sum >/dev/null 2>&1; then sha256sum "$1" | awk '{print $1}'
  elif command -v shasum   >/dev/null 2>&1; then shasum -a 256 "$1" | awk '{print $1}'
  else openssl dgst -sha256 "$1" | awk '{print $NF}'
  fi
}

# manifest_skill_entries $1=carpeta-grupo (ej: skills/core, skills/react,
# skills/domains/conversion-ui) $2=etiqueta-grupo (core|<framework>|domain:<n>)
# Emite entradas JSON (una por línea, sin coma final) por cada SKILL.md
# encontrado. El hash es SOLO del SKILL.md (el contrato/entry-point), no de
# subcarpetas vendored como */references/*.md — que esas cambien no debe
# generar drift-noise en skills que solo las citan.
manifest_skill_entries() {
  local src="$1" group="$2" f name h first=1
  [[ -d "$src" ]] || return 0
  while IFS= read -r f; do
    name="$(basename "$(dirname "$f")")"
    h="$(sha256_file "$f")"
    [[ $first -eq 0 ]] && printf ',\n'
    printf '    { "name": "%s", "group": "%s", "sha256": "%s" }' "$name" "$group" "$h"
    first=0
  done < <(find "$src" -mindepth 1 -maxdepth 2 -name SKILL.md 2>/dev/null | sort)
}

# write_fea_manifest: escribe .fea/manifest.json en el TARGET (no en el
# destino global de skills — respeta la regla de dos destinos). Se llama
# después de instalar skills/agents/commands, así que FRAMEWORKS/DOMAINS/
# AGENT ya están resueltos.
write_fea_manifest() {
  local out="$PROJECT_DIR/.fea/manifest.json"
  local commit; commit="$(git -C "$ARCH_DIR" rev-parse HEAD 2>/dev/null || echo unknown)"
  local date; date="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  if [[ $DRY_RUN -eq 1 ]]; then
    log "[dry-run] escribiría .fea/manifest.json (commit=$commit, agent=$AGENT)"
    return
  fi
  mkdir -p "$PROJECT_DIR/.fea"
  {
    echo '{'
    printf '  "ecosystem_commit": "%s",\n' "$commit"
    printf '  "installed_at": "%s",\n'      "$date"
    printf '  "agent": "%s",\n'             "$AGENT"
    echo '  "frameworks": ['
    local i fw_first=1
    for i in "${!FRAMEWORKS[@]}"; do
      [[ $fw_first -eq 0 ]] && printf ',\n'
      printf '    { "name": "%s", "package": "%s", "version": "%s", "version_source": "%s", "skill_min_supported": "%s", "skill_verified_against": "%s" }' \
        "${FRAMEWORKS[$i]}" "$(framework_package "${FRAMEWORKS[$i]}")" "${FW_VERSIONS[$i]}" "${FW_VERSION_SOURCES[$i]}" \
        "$(skill_version_field "${FRAMEWORKS[$i]}" min_supported)" "$(skill_version_field "${FRAMEWORKS[$i]}" verified_against)"
      fw_first=0
    done
    [[ $fw_first -eq 0 ]] && printf '\n'
    echo '  ],'
    echo '  "skills": ['
    local entries="" chunk
    entries="$(manifest_skill_entries "$ARCH_DIR/skills/core" "core")"
    local fw d
    for fw in "${FRAMEWORKS[@]}"; do
      chunk="$(manifest_skill_entries "$ARCH_DIR/skills/$fw" "$fw")"
      [[ -n "$chunk" ]] && entries+=$',\n'"$chunk"
    done
    for d in "${DOMAINS[@]}"; do
      chunk="$(manifest_skill_entries "$ARCH_DIR/skills/domains/$d" "domain:$d")"
      [[ -n "$chunk" ]] && entries+=$',\n'"$chunk"
    done
    printf '%s\n' "$entries"
    echo '  ]'
    echo '}'
  } > "$out"
  ok ".fea/manifest.json escrito (commit=$commit, agente=$AGENT)"
}

# ===========================================================================
# EJECUCIÓN
# ===========================================================================
step "Proyecto: $PROJECT_DIR"
[[ -f "$PROJECT_DIR/package.json" ]] || warn "no hay package.json — no puedo detectar el stack"
PM="$(detect_pm)"; log "package manager: $PM"

# --- Stack ---
# Next incluye "react" como dependencia, pero no querés las dos mitades a la
# vez: next/ ya asume React (ver next-architecture). Next gana si está.
FRAMEWORKS=()
has_dep "@angular/core" && FRAMEWORKS+=("angular")
if has_dep "next"; then
  FRAMEWORKS+=("next")
elif has_dep "react"; then
  FRAMEWORKS+=("react")
fi
if [[ ${#FRAMEWORKS[@]} -eq 0 ]]; then
  log "stack front: ninguno detectado (solo core)"
  [[ -f "$PROJECT_DIR/package.json" ]] || warn "proyecto nuevo sin stack todavía — cuando lo scaffoldees (ng new / create-next-app / npm create vite), volvé a correr este instalador para sumar la skill de arquitectura correspondiente"
else log "stack front: ${FRAMEWORKS[*]}"; fi

# --- Versión de cada framework (paralelo a FRAMEWORKS[], mismo índice) ---
FW_VERSIONS=(); FW_VERSION_SOURCES=()
for fw in "${FRAMEWORKS[@]}"; do
  vs="$(installed_version "$(framework_package "$fw")")"
  if [[ -z "$vs" ]]; then
    FW_VERSIONS+=(""); FW_VERSION_SOURCES+=("")
    warn "$fw: no pude resolver la versión — el agente la va a resolver del lockfile"
  else
    FW_VERSIONS+=("${vs%%|*}"); FW_VERSION_SOURCES+=("${vs#*|}")
    log "$fw: ${vs%%|*} (${vs#*|})"
    [[ "${vs#*|}" == "rango" ]] && log "  (sin node_modules: es el rango de package.json, no la versión exacta)"
    check_version_drift "$fw" "${vs%%|*}"
  fi
done

# --- Agente ---
step "Detectando agente de IA…"
if [[ -z "$AGENT" ]]; then
  mapfile -t DETECTED < <(detect_agents)
  if   [[ ${#DETECTED[@]} -eq 1 ]]; then AGENT="${DETECTED[0]}"; ok "detectado: $AGENT"
  elif [[ ${#DETECTED[@]} -eq 0 ]]; then
    warn "no detecté ningún agente instalado."
    log "opciones: ${AGENT_BINS[*]}"
    if [[ -t 0 && $ASSUME_YES -eq 0 ]]; then read -r -p "  ¿Cuál vas a usar? " AGENT
    else echo "  Pasá --agent <nombre>"; exit 1; fi
  else
    warn "hay varios agentes: ${DETECTED[*]}"
    if [[ -t 0 && $ASSUME_YES -eq 0 ]]; then read -r -p "  ¿Cuál usar? " AGENT
    else echo "  Pasá --agent <nombre> para elegir"; exit 1; fi
  fi
else
  ok "agente forzado: $AGENT"
fi
SKILLS_DIR="$(skills_dir_for "$AGENT")"
[[ -n "$SKILLS_DIR" ]] || { echo "Agente no soportado: $AGENT"; exit 1; }
log "skills dir: $SKILLS_DIR"

# --- Motores ---
step "Chequeando motores…"
ensure_openspec
ensure_engram

# --- Skills (core + framework) + agents/ + commands/ ---
step "Instalando skills, agentes y comandos…"
copy_skill_group "core" "$SKILLS_DIR"
for fw in "${FRAMEWORKS[@]}"; do copy_skill_group "$fw" "$SKILLS_DIR"; done
# domains: opt-in explícito (NO se autocargan por stack)
if [[ ${#DOMAINS[@]} -gt 0 ]]; then
  for d in "${DOMAINS[@]}"; do copy_one_domain "$d" "$SKILLS_DIR"; done
elif [[ -n "$(list_domains)" ]]; then
  log "domains disponibles (opt-in): $(list_domains | tr '\n' ' ')"
  log "  → incluí con --with <nombre> (ej: --with conversion-ui)"
fi
# comandos /fea:*: best-effort, nunca bloquean el install (ver commands_dir_for)
copy_commands "$AGENT"
# agents/ (roles + subagentes mecánicos): destino garantizado, igual que skills
copy_optional_dir "$ARCH_DIR/agents"   "$(agents_dir_for "$AGENT")"   "agentes"

# --- Manifiesto del proyecto (.fea/manifest.json) ---
step "Escribiendo manifiesto del proyecto…"
write_fea_manifest

# --- AGENTS.md canónico (mis estándares, como bloque) ---
step "Escribiendo estándares en el proyecto…"
inject_agents_block

# --- Orquestar los motores (ellos hacen su propio wiring por-agente) ---
step "Cableando workflow y memoria…"
if command -v openspec >/dev/null 2>&1; then
  if [[ -d "$PROJECT_DIR/openspec" ]]; then
    # Ya inicializado: refrescar config por-agente, no re-inicializar (init
    # con --force podría tocar specs/changes existentes de forma destructiva).
    run "cd '$PROJECT_DIR' && openspec update"
    ok "OpenSpec ya estaba inicializado — config regenerada (openspec update)"
  else
    # --tools: mismo valor que $AGENT — los tool IDs de OpenSpec (claude,
    # cursor, codex, opencode) son 1:1 con los nuestros, sin mapeo. Sin
    # --tools, `openspec init` pregunta interactivo y cuelga en modo --yes/CI.
    # No pasamos --profile: el surface por defecto de OpenSpec (explore +
    # propose, más apply/archive/sync) ya es el lean/"core" que queremos —
    # "expanded" es opt-in aparte vía `openspec config profile`, no un flag
    # de init.
    OPENSPEC_FORCE_FLAG=""
    if [[ $ASSUME_YES -eq 1 || ! -t 0 ]]; then OPENSPEC_FORCE_FLAG="--force"; fi
    run "cd '$PROJECT_DIR' && openspec init --tools '$AGENT' $OPENSPEC_FORCE_FLAG"
    ok "OpenSpec inicializado (openspec/, tools=$AGENT)"
  fi
else
  warn "OpenSpec ausente: corré 'openspec init --tools $AGENT' cuando lo instales"
fi

if command -v engram >/dev/null 2>&1; then
  run "engram setup $(engram_agent_arg "$AGENT")"; ok "Engram cableado (MCP) para $AGENT"
else warn "Engram ausente: corré 'engram setup $(engram_agent_arg "$AGENT")' cuando lo instales"; fi
ensure_engram_project_config

step "Cableando revisión con Playwright…"
ensure_playwright_mcp

step "Cableando doc viva por versión (Context7 + MCP oficial del framework)…"
ensure_context7_mcp
ensure_framework_mcp

# Para Claude: asegurar que CLAUDE.md importe AGENTS.md (sin pisar lo de OpenSpec)
if [[ "$AGENT" == "claude" && $DRY_RUN -eq 0 ]]; then
  if ! grep -q "@AGENTS.md" "$PROJECT_DIR/CLAUDE.md" 2>/dev/null; then
    echo "@AGENTS.md" >> "$PROJECT_DIR/CLAUDE.md"; ok "CLAUDE.md importa AGENTS.md"
  fi
fi

step "Listo."
log "Núcleo portable: skills (core${FRAMEWORKS:+ + ${FRAMEWORKS[*]}}) + agentes (roles + subagentes) + bloque AGENTS.md."
log "Motores: OpenSpec (workflow) + Engram (memoria) + Playwright MCP (revisión en vivo) + Context7/MCP oficial (doc por versión)."
[[ ${#DOMAINS[@]} -gt 0 ]] && log "Domains opt-in instalados: ${DOMAINS[*]}." || true
log "Solo cambiaron las rutas según el agente — eso es la capa de adaptadores."
[[ $DRY_RUN -eq 1 ]] && log "(fue un dry-run: no se tocó nada)" || true