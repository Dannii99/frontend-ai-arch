#!/usr/bin/env bash
#
# install.sh — equipa CUALQUIER proyecto con este ecosistema de IA.
#
# Qué hace, en orden:
#   1. Detecta el package manager y el STACK del proyecto (Angular/React/Next) leyendo package.json
#   2. Detecta el AGENTE de IA (si hay 0 o varios, pregunta; si hay 1, sigue)
#   3. Chequea los MOTORES (OpenSpec, Engram). Si falta alguno, te dice cuál y
#      OFRECE instalarlo con el comando correcto para tu SO (no instala a la fuerza)
#   4. Instala las SKILLS relevantes: core/ (siempre) + la del framework detectado,
#      más agents/ (roles + subagentes, destino garantizado) y los comandos
#      /fea:* (best-effort, no bloqueante)
#   5. Orquesta OpenSpec y Engram (que hacen su propio wiring por-agente), y
#      cablea el MCP de Playwright (revisión en vivo — ver ensure_playwright_mcp)
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
os_kind() { case "$(uname -s)" in Darwin) echo mac ;; Linux) echo linux ;; *) echo other ;; esac; }

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
  if [[ -z "$cmd" ]]; then
    warn "no encontré brew ni go. Instalá el binario desde: https://github.com/Gentleman-Programming/engram/releases"
    return
  fi
  if confirm "instalar Engram con: $cmd"; then run "$cmd" && ok "Engram instalado"
  else warn "se salta Engram (sin memoria persistente)"; fi
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
ensure_playwright_mcp() {
  case "$AGENT" in
    claude)
      if command -v claude >/dev/null 2>&1 && claude mcp list 2>/dev/null | grep -qi '^playwright:'; then
        ok "Playwright MCP ya registrado en Claude Code"
      else
        warn "Playwright MCP no está registrado en Claude Code."
        if confirm "registrar con: claude mcp add playwright -- npx @playwright/mcp@latest"; then
          run "claude mcp add playwright -- npx @playwright/mcp@latest"
          ok "Playwright MCP registrado"
        else
          warn "se salta — /fea:review no va a poder abrir un browser real"
        fi
      fi
      ;;
    cursor)
      warn "Cursor: agregá manualmente a .cursor/mcp.json (o ~/.cursor/mcp.json):"
      log '  { "mcpServers": { "playwright": { "command": "npx", "args": ["@playwright/mcp@latest"] } } }'
      ;;
    codex)
      warn "Codex CLI: agregá manualmente a ~/.codex/config.toml:"
      log '  [mcp_servers.playwright]'
      log '  command = "npx"'
      log '  args = ["@playwright/mcp@latest"]'
      ;;
    opencode)
      warn "OpenCode: formato de MCP servers no confirmado en esta versión —"
      log "  revisá la doc de tu instalación y apuntá el server 'playwright' a: npx @playwright/mcp@latest"
      ;;
  esac
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
inject_agents_block() {
  local target="$PROJECT_DIR/AGENTS.md" block; block="$(cat "$ARCH_DIR/AGENTS.md")"
  if [[ $DRY_RUN -eq 1 ]]; then log "[dry-run] inyectaría bloque de estándares en AGENTS.md"; return; fi
  touch "$target"
  # quita un bloque FEA previo si existe
  awk '/<!-- FEA:START -->/{s=1} s!=1{print} /<!-- FEA:END -->/{s=0}' "$target" > "$target.tmp"
  { cat "$target.tmp"; echo; echo "<!-- FEA:START -->"; echo "$block"; echo "<!-- FEA:END -->"; } > "$target"
  rm -f "$target.tmp"
  ok "AGENTS.md actualizado (bloque FEA)"
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

# Para Claude: asegurar que CLAUDE.md importe AGENTS.md (sin pisar lo de OpenSpec)
if [[ "$AGENT" == "claude" && $DRY_RUN -eq 0 ]]; then
  if ! grep -q "@AGENTS.md" "$PROJECT_DIR/CLAUDE.md" 2>/dev/null; then
    echo "@AGENTS.md" >> "$PROJECT_DIR/CLAUDE.md"; ok "CLAUDE.md importa AGENTS.md"
  fi
fi

step "Listo."
log "Núcleo portable: skills (core${FRAMEWORKS:+ + ${FRAMEWORKS[*]}}) + agentes (roles + subagentes) + bloque AGENTS.md."
log "Motores: OpenSpec (workflow) + Engram (memoria) + Playwright MCP (revisión en vivo)."
[[ ${#DOMAINS[@]} -gt 0 ]] && log "Domains opt-in instalados: ${DOMAINS[*]}."
log "Solo cambiaron las rutas según el agente — eso es la capa de adaptadores."
[[ $DRY_RUN -eq 1 ]] && log "(fue un dry-run: no se tocó nada)"