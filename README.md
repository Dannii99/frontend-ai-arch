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
│   ├── core/                     # SIEMPRE — agnóstico de framework
│   │   ├── accessibility-a11y/
│   │   ├── frontend-clean-code/          # calidad micro: nombres, tipos, funciones
│   │   ├── frontend-design-principles/   # SOLID + patrones (Facade, Repository, Adapter)
│   │   ├── ui-visual-craft/
│   │   ├── motion-design-system/
│   │   └── documentation-writer/
│   ├── angular/                   # solo si el proyecto usa Angular
│   │   ├── skills-main/           # vendored: angular/skills oficial (referencia dura)
│   │   ├── angular-architecture/  # tu criterio: carpetas, estado, testing
│   │   └── angular-deploy-safety/
│   ├── react/                     # solo si el proyecto usa React puro (sin Next)
│   │   ├── vercel-react-best-practices/  # vendored: referencia de performance
│   │   └── react-architecture/    # tu criterio: carpetas, server/client state, testing
│   ├── next/                      # solo si el proyecto usa Next (gana sobre react/)
│   │   ├── next-best-practices/   # referencia dura, API por API
│   │   └── next-conventions/      # tu criterio: Server/Client, data, optimización
│   └── domains/                   # opt-in, nunca se auto-cargan por stack
│       ├── conversion-ui/
│       └── next-partial-prefetching-adoption/
├── personas/                     # roles: quién hace qué con las skills de arriba
│   ├── frontend-architect.md     # orquestador: decide stack, delega, abre specs
│   ├── frontend-angular-senior.md
│   ├── frontend-react-next.md
│   └── project-owner.md          # scoping de producto, previo a cualquier decisión técnica
└── install.sh                    # instalador: detecta stack + agente, orquesta motores
```

Cada skill (menos las vendored) sigue el mismo patrón de dos capas por
framework: una **referencia dura** (sintaxis/API — vendored, no se edita como
si fuera propia) y una skill de **arquitectura** (las decisiones que esa
referencia deja abiertas: carpetas, estado, testing — esa sí es tu criterio).
`frontend-clean-code` y `frontend-design-principles` (core) son la capa que
está por encima de las tres: agnósticas de framework, las citan las tres
arquitecturas en vez de repetir contenido.

## Personas: quién usa las skills

Las skills son el *qué*; las personas son el *quién* y en qué orden:

1. **`project-owner`** — antes de cualquier decisión técnica, convierte una
   idea en `docs/project-context.md` (producto, MVP, reglas de negocio). No
   toca código ni arquitectura.
2. **`frontend-architect`** — lee ese contexto si existe, detecta o decide el
   stack, y para cambios no triviales abre una propuesta en `openspec/` antes
   de delegar. No implementa directamente.
3. **`frontend-angular-senior`** / **`frontend-react-next`** — especialistas
   de ejecución. Implementan apoyándose en las skills del framework
   correspondiente; no reinventan el criterio que esas skills ya fijan.

`docs/` (contexto de producto) y `openspec/` (specs técnicas) son carpetas
distintas con dueños distintos — no se mezclan.

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

> **Excepción deliberada:** los archivos que genera `openspec init` dentro del
> proyecto target (p. ej. `.claude/skills/openspec-*/SKILL.md`,
> `.claude/commands/opsx/*.md`, y sus equivalentes `.cursor/`, `.codex/`,
> `.opencode/`) son *project-local* a propósito — los coloca OpenSpec, no
> nosotros, y se commitean con el repo del cliente junto a `openspec/`. No es
> una inconsistencia con la regla de arriba: es el propio motor OpenSpec
> haciendo su wiring por-agente (ver el paso "Orquestar los motores" de
> `install.sh`). Si ves `.claude/skills/openspec-*` adentro de un repo de
> cliente, es lo esperado — no lo confundas con una fuga de nuestras skills
> globales (`~/.claude/skills/`), que siguen viviendo solo en tu máquina.

## Roadmap de skills

- [x] `core/accessibility-a11y` — principios de accesibilidad (qué revisar)
- [x] `core/frontend-clean-code`, `core/frontend-design-principles` — calidad
      micro + SOLID/patrones
- [x] `core/ui-visual-craft`, `core/motion-design-system`,
      `core/documentation-writer`
- [x] `angular/` — `angular-architecture` + `angular-deploy-safety` +
      referencia oficial vendored (`skills-main`)
- [x] `react/` — `react-architecture` + referencia de performance vendored
      (`vercel-react-best-practices`)
- [x] `next/` — `next-conventions` + referencia vendored (`next-best-practices`)
- [x] `domains/conversion-ui`, `domains/next-partial-prefetching-adoption`
      (opt-in)
- [ ] `core/performance-budget` — presupuesto de bundle/Lighthouse como skill
      propia (hoy vive disperso entre `vercel-react-best-practices` y
      `ui-visual-craft`)
- [ ] `vue/` — sin skills todavía; la persona de Vue se sacó hasta que exista
      esta base (mismo patrón referencia + arquitectura que los otros tres)
