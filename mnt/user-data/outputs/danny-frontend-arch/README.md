# Frontend AI Ecosystem

Un ecosistema de IA portable para desarrollo frontend. No es un asistente atado
a una herramienta: es una capa de **orden, memoria, skills y forma de trabajo**
que se instala sobre **cualquier agente de IA** (Claude Code, Cursor, Codex,
OpenCode…) y sobre cualquier proyecto, nuevo o existente.

La idea: que el agente cargue el criterio senior de frontend —accesibilidad,
testing, performance, seguridad de deploy— para que el output sea consistente y
con estándares, incluso cuando quien lo conduce no es experto en frontend.

## Por qué es agent-agnóstico de verdad

Se apoya en tres estándares abiertos (todos bajo la Linux Foundation), uno por
cada pilar:

| Pilar | Estándar | Qué aporta |
|-------|----------|------------|
| Cómo se trabaja | **Agent Skills (SKILL.md)** | Skills portables que corren sin cambios en 30+ agentes |
| Orientación | **AGENTS.md** | Instrucciones de proyecto que lee cualquier agente |
| Memoria | **MCP** | Memoria persistente (Engram) accesible desde cualquier agente |

El **núcleo** (skills, personas, AGENTS.md) es idéntico en todos lados. Lo único
específico de cada agente es **dónde va cada archivo** — eso vive en una capa
fina de adaptadores dentro de `install.sh`.

## Estructura

```
.
├── AGENTS.md                     # estándares canónicos (se inyectan al proyecto)
├── skills/                       # tu IP: cómo trabajás, encapsulado
│   ├── README.md                 # convención core vs framework
│   ├── core/                     # SIEMPRE (a11y, testing, performance…)
│   ├── angular/                  # solo si el proyecto usa Angular
│   │   └── angular-deploy-safety/SKILL.md
│   └── react/                    # solo si el proyecto usa React
├── personas/                     # roles (arquitecto, reviewer…)
│   └── frontend-architect.md
└── install.sh                    # instalador: detecta stack + agente, orquesta motores
```

## Uso

**Una sola vez** (los motores): un agente de IA (Claude Code / Cursor / Codex /
OpenCode), OpenSpec (`npm i -g @fission-ai/openspec@latest`) y Engram
(`brew install gentleman-programming/tap/engram` o `go install …`). El
instalador también los detecta y te ofrece instalarlos si faltan.

**Por proyecto**, parado en el proyecto (nuevo o existente):

```bash
~/dev/tools/frontend-ai-ecosystem/install.sh          # detecta stack y agente
~/dev/tools/frontend-ai-ecosystem/install.sh --dry-run # muestra el plan sin tocar
~/dev/tools/frontend-ai-ecosystem/install.sh --agent cursor --yes
```

El instalador detecta el framework por `package.json` e instala solo las skills
relevantes (`core` + framework), coloca skills y personas en el dir global del
agente (viajan con vos, no ensucian el repo), inyecta tus estándares en
`AGENTS.md` como bloque idempotente, y orquesta `openspec init` y
`engram setup` para que cada uno haga su propio wiring por-agente.

## Dos destinos, una regla

- **Global** (`~/.<agente>/skills/`, memoria de Engram): tuyo, viaja con vos,
  no se commitea al repo del cliente. Tu IP no queda regada en repos ajenos.
- **Proyecto** (`AGENTS.md`, `openspec/`): conocimiento de ese producto, se
  commitea y viaja con el repo.

## Roadmap de skills

- [x] `angular/angular-deploy-safety` — seguridad de build/deploy productivo
- [ ] `core/a11y-wcag` — principios de accesibilidad (qué revisar)
- [ ] `core/testing` — estrategia de testing
- [ ] `core/performance-budget` — Lighthouse / bundle size
- [ ] `angular/…`, `react/…` — el *cómo* de cada framework
