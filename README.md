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

El **núcleo** (skills, agents, AGENTS.md) es idéntico en todos lados. Lo único
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
│       ├── next-partial-prefetching-adoption/
│       └── playwright-visual-review/  # revisión en vivo (MCP) + e2e persistido
├── commands/fea/                 # slash-commands (/fea:*): mecanizan el flujo de OpenSpec
│   ├── plan.md · execute.md · test.md · verify.md · review.md · archive.md
│   └── fix.md · explore.md · audit.md
├── agents/                       # roles + subagentes: quién hace qué con las skills de arriba
│   ├── project-owner.md          # rol: scoping de producto, previo a cualquier decisión técnica
│   ├── frontend-architect.md     # rol: orquestador, decide stack, delega, abre specs
│   ├── frontend-angular-senior.md    # rol: especialista de ejecución Angular
│   ├── frontend-react-next.md        # rol: especialista de ejecución React/Next
│   ├── code-writer.md            # subagente: implementa una task (usa /fea:execute, /fea:fix)
│   ├── code-auditor.md           # subagente: audita contra las skills de calidad
│   ├── test-generator.md         # subagente: genera tests (usa /fea:test)
│   └── visual-reviewer.md        # subagente: revisión en vivo con Playwright MCP (usa /fea:review)
└── install.sh                    # instalador: detecta stack + agente, orquesta motores
```

Cada skill (menos las vendored) sigue el mismo patrón de dos capas por
framework: una **referencia dura** (sintaxis/API — vendored, no se edita como
si fuera propia) y una skill de **arquitectura** (las decisiones que esa
referencia deja abiertas: carpetas, estado, testing — esa sí es tu criterio).
`frontend-clean-code` y `frontend-design-principles` (core) son la capa que
está por encima de las tres: agnósticas de framework, las citan las tres
arquitecturas en vez de repetir contenido.

## Agentes: quién usa las skills

Las skills son el *qué*; los agentes son el *quién* y en qué orden. `agents/`
mezcla a propósito dos tipos: roles conversacionales (los primeros 3 puntos,
pensados para sostener una sesión completa) y subagentes mecánicos (el 4to
punto, invocados por task desde `commands/fea/`):

1. **`project-owner`** — antes de cualquier decisión técnica, convierte una
   idea en `docs/project-context.md` (producto, MVP, reglas de negocio). No
   toca código ni arquitectura.
2. **`frontend-architect`** — lee ese contexto si existe, detecta o decide el
   stack, y para cambios no triviales abre una propuesta en `openspec/` antes
   de delegar — hoy ese flujo lo mecanizan los comandos `/fea:plan` →
   `/fea:execute` → `/fea:verify` → `/fea:archive` (`commands/fea/`). No
   implementa directamente.
3. **`frontend-angular-senior`** / **`frontend-react-next`** — especialistas
   de ejecución. Implementan apoyándose en las skills del framework
   correspondiente; no reinventan el criterio que esas skills ya fijan.
4. **`code-writer`** / **`code-auditor`** / **`test-generator`** — subagentes
   que usa `/fea:execute`/`/fea:fix`/`/fea:test` por cada task: implementan,
   auditan contra las mismas skills de calidad, y generan tests después de
   implementar (incluyendo `.spec.ts` de Playwright persistidos para los
   escenarios que la política de testing marca "e2e"). No se invocan
   directo — son la capa mecánica detrás de los comandos.
5. **`visual-reviewer`** — subagente que usa `/fea:review`: maneja Playwright
   MCP contra la app corriendo para una revisión en vivo (accesibilidad real
   del DOM, consistencia visual, consola del browser) — complementa a
   `/fea:verify`, que es solo análisis estático. No genera archivos.

`docs/` (contexto de producto) y `openspec/` (specs técnicas) son carpetas
distintas con dueños distintos — no se mezclan.

## Uso

**Una sola vez** (los motores): un agente de IA (Claude Code / Cursor / Codex /
OpenCode), OpenSpec (`npm i -g @fission-ai/openspec@latest`), Engram
(`brew install gentleman-programming/tap/engram` o `go install …`) y
Playwright MCP (se sirve vía `npx @playwright/mcp@latest`, sin instalación
global — el instalador lo registra como MCP server para tu agente). El
instalador detecta y cablea los tres.

**Por proyecto**, parado en el proyecto (nuevo o existente):

```bash
~/dev/tools/frontend-ai-ecosystem/install.sh          # detecta stack y agente
~/dev/tools/frontend-ai-ecosystem/install.sh --dry-run # muestra el plan sin tocar
~/dev/tools/frontend-ai-ecosystem/install.sh --agent cursor --yes
```

El instalador detecta el framework por `package.json` e instala solo las skills
relevantes (`core` + framework), coloca skills y agentes en el dir global del
agente (viajan con vos, no ensucian el repo), inyecta tus estándares en
`AGENTS.md` como bloque idempotente, y orquesta `openspec init`, `engram setup`
y el registro del MCP de Playwright para que cada motor haga su propio
wiring por-agente.

## Dos destinos, una regla

- **Global** (`~/.<agente>/skills/`, `~/.<agente>/agents/`,
  `~/.<agente>/commands/`, memoria de Engram): tuyo, viaja con vos, no se
  commitea al repo del cliente. Tu IP no queda regada en repos ajenos.
  `agents/` (los 4 roles + los 3 subagentes) tiene destino garantizado en los
  4 agentes soportados, igual que `skills/`. Los comandos `/fea:*` sí son
  nativos de Claude Code sin equivalente conocido en el resto — ahí
  `install.sh` instala en el mejor esfuerzo y avisa si no hay destino
  conocido, sin bloquear el resto.
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
- [x] `domains/conversion-ui`, `domains/next-partial-prefetching-adoption`,
      `domains/playwright-visual-review` (opt-in)
- [ ] `core/performance-budget` — presupuesto de bundle/Lighthouse como skill
      propia (hoy vive disperso entre `vercel-react-best-practices` y
      `ui-visual-craft`)
- [ ] `vue/` — sin skills todavía; el agente de Vue se sacó hasta que exista
      esta base (mismo patrón referencia + arquitectura que los otros tres)
