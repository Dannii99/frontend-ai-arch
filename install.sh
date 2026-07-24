#!/usr/bin/env bash
#
# install.sh — equipa CUALQUIER proyecto con este ecosistema de IA.
#
# Qué hace, en orden:
#   1. Detecta el package manager y el STACK del proyecto (Angular/React) leyendo package.json
#   2. Detecta el AGENTE de IA (si hay 0 o varios, pregunta; si hay 1, sigue)
#   3. Chequea los MOTORES (OpenSpec, Engram). Si falta alguno, te dice cuál y
#      OFRECE instalarlo con el comando correcto para tu SO (no instala a la fuerza)
#   4. Instala las SKILLS relevantes: core/ (siempre) + la del framework detectado
#   5. Orquesta OpenSpec y Engram (que hacen su propio wiring por-agente)
#
# Núcleo portable (idéntico en todo agente): skills, personas, bloque de AGENTS.md.
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
    opencode) echo "$HOME/.config/opencode/skills" ;;    # verificar según tu versión
  esac
}
# Nombre que espera 'engram setup <agente>'
engram_agent_arg() { case "$1" in claude) echo "claude-code" ;; *) echo "$1" ;; esac; }
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

# ---------------------------------------------------------------------------
# 4. Instalar skills según stack + personas
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
FRAMEWORKS=()
has_dep "@angular/core" && FRAMEWORKS+=("angular")
has_dep "react"         && FRAMEWORKS+=("react")
if [[ ${#FRAMEWORKS[@]} -eq 0 ]]; then log "stack front: ninguno detectado (solo core)"
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

# --- Skills (core + framework) + personas ---
step "Instalando skills y personas…"
copy_skill_group "core" "$SKILLS_DIR"
for fw in "${FRAMEWORKS[@]}"; do copy_skill_group "$fw" "$SKILLS_DIR"; done
# domains: opt-in explícito (NO se autocargan por stack)
if [[ ${#DOMAINS[@]} -gt 0 ]]; then
  for d in "${DOMAINS[@]}"; do copy_one_domain "$d" "$SKILLS_DIR"; done
elif [[ -n "$(list_domains)" ]]; then
  log "domains disponibles (opt-in): $(list_domains | tr '\n' ' ')"
  log "  → incluí con --with <nombre> (ej: --with conversion-ui)"
fi
if [[ -d "$ARCH_DIR/personas" ]]; then
  run "mkdir -p '$SKILLS_DIR/_personas'"
  run "cp -R '$ARCH_DIR/personas/.' '$SKILLS_DIR/_personas/'"
  ok "personas instaladas"
fi

# --- AGENTS.md canónico (mis estándares, como bloque) ---
step "Escribiendo estándares en el proyecto…"
inject_agents_block

# --- Orquestar los motores (ellos hacen su propio wiring por-agente) ---
step "Cableando workflow y memoria…"
if command -v openspec >/dev/null 2>&1; then
  run "cd '$PROJECT_DIR' && openspec init"; ok "OpenSpec inicializado (openspec/)"
else warn "OpenSpec ausente: corré 'openspec init' cuando lo instales"; fi

if command -v engram >/dev/null 2>&1; then
  run "engram setup $(engram_agent_arg "$AGENT")"; ok "Engram cableado (MCP) para $AGENT"
else warn "Engram ausente: corré 'engram setup $(engram_agent_arg "$AGENT")' cuando lo instales"; fi

# Para Claude: asegurar que CLAUDE.md importe AGENTS.md (sin pisar lo de OpenSpec)
if [[ "$AGENT" == "claude" && $DRY_RUN -eq 0 ]]; then
  if ! grep -q "@AGENTS.md" "$PROJECT_DIR/CLAUDE.md" 2>/dev/null; then
    echo "@AGENTS.md" >> "$PROJECT_DIR/CLAUDE.md"; ok "CLAUDE.md importa AGENTS.md"
  fi
fi

step "Listo."
log "Núcleo portable: skills (core${FRAMEWORKS:+ + ${FRAMEWORKS[*]}}) + personas + bloque AGENTS.md."
[[ ${#DOMAINS[@]} -gt 0 ]] && log "Domains opt-in instalados: ${DOMAINS[*]}."
log "Solo cambiaron las rutas según el agente — eso es la capa de adaptadores."
[[ $DRY_RUN -eq 1 ]] && log "(fue un dry-run: no se tocó nada)"