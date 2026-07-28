---
name: react-architecture
description: >-
  Fija las decisiones de arquitectura React que la librería deja abiertas:
  estructura de carpetas (core/shared/features), routing y code-splitting,
  el límite entre estado de servidor (TanStack Query/SWR) y estado de cliente
  (useState/Context/store), cuándo escalar a Zustand/Jotai, memoización manual
  vs React Compiler, qué librería de forms usar, error boundaries, y qué se
  testea siempre vs qué alcanza con un smoke test. Úsala al organizar un
  proyecto React puro (Vite/CRA/Remix, sin Next), al decidir dónde vive un
  archivo nuevo, al evaluar si un dato necesita un query client o un store, o
  al revisar un PR de React. No es referencia de performance (ver
  react-references para eso) ni aplica a proyectos Next (ver next/).
compatibility: react
metadata:
  category: react-architecture
  framework: react
---

# React Architecture

Esta skill no re-enseña React ni repite reglas de performance — eso ya está
cubierto en profundidad en `react-references` (referencia vendored
de Vercel Engineering: waterfalls, bundle size, rerenders, rendering, JS
micro-opts). Consultá esa skill para "qué patrón de performance aplica".

Acá van las decisiones que React deja abiertas y que este proyecto resuelve
siempre de la misma forma: dónde vive cada archivo, qué librería gestiona qué
estado, y qué se testea de verdad.

Los principios universales (tipado, nombres, componentes chicos, una
responsabilidad) viven en `frontend-clean-code` (core); SOLID y los patrones
de arquitectura (Facade, Repository, Adapter, límites entre módulos) viven en
`frontend-design-principles` (core). Si algo aplica a
cualquier front, no lo repitas acá: es core. Y si el proyecto es Next, no
cargues esta skill además de `next/` — Next ya es React, y `next-architecture`
cubre sus propias decisiones de Server/Client Components.

## Cuándo usar

- Organizás un proyecto React puro (Vite, CRA, Remix) nuevo o agregás una
  feature a uno existente.
- Dudás dónde poner un archivo nuevo (¿`core/`? ¿`shared/`? ¿dentro de la
  feature?).
- Vas a fetchear datos y no está claro si es estado de servidor o de cliente.
- Vas a sumar estado compartido y no está claro si alcanza con Context o hace
  falta un store dedicado.
- Revisás un PR de React y necesitás un criterio objetivo de qué debía tener
  test y qué no.

## Estructura de carpetas

```
src/
├── core/         # providers globales, config de router, clients (queryClient, etc.)
├── shared/       # componentes/hooks reutilizables, sin lógica de negocio
└── features/
    └── checkout/
        ├── checkout.routes.tsx
        ├── components/   # privados de la feature
        ├── hooks/
        └── api/          # queries/mutations de esta feature
```

- **`core/`**: solo lo transversal a toda la app — el `QueryClientProvider`,
  la config del router, clients de terceros instanciados una vez. Si dudás si
  algo va acá, probablemente no — default a `features/`.
- **`shared/`**: componentes y hooks reutilizables **sin** lógica de negocio.
  Un componente pasa de una feature a `shared/` recién cuando un segundo
  consumidor real lo necesita, no antes.
- **`features/<nombre>/`**: autocontenida, incluida su capa de datos
  (`api/` con las queries/mutations de esa feature). Sus `components/` y
  `hooks/` internos son privados a la feature por default; si hace falta
  compartirlos, se promueven a `shared/` explícitamente.

## Enrutamiento y code-splitting

React puro no trae router — es una decisión de arquitectura real, no un
detalle:

- **React Router** es el default pragmático para la gran mayoría de
  proyectos Vite/CRA/Remix-less: maduro, sin fricción de adopción.
- **TanStack Router** cuando el proyecto quiere rutas y loaders type-safe de
  punta a punta (search params tipados, validación de loaders en tiempo de
  compilación) — es más setup, no lo elijas por defecto sin esa necesidad
  concreta.
- **Una feature por ruta, lazy-cargada**: cada entrada de `features/` se
  carga con `React.lazy()` + `<Suspense>` en el punto de ruta, mismo
  criterio que evita que una feature no usada infle el bundle inicial (ver
  `bundle-dynamic-imports` en `react-references`).

## Estado de servidor vs estado de cliente

La primera pregunta ante cualquier estado nuevo: **¿este dato vive en un
servidor o solo en esta sesión de UI?** La respuesta decide la herramienta.

**Estado de servidor (cualquier dato que viene de una red): siempre TanStack
Query o SWR.** Nunca `useEffect` + `fetch` + `useState` a mano — eso reintroduce
manualmente el cache, la deduplicación y la revalidación que la librería ya
resuelve (y es exactamente lo que `react-references` marca como
anti-patrón en sus reglas `async-*` y `client-swr-dedup`).

**Estado de cliente (UI pura: un modal abierto, un tab activo, un formulario
en progreso): `useState`/`useReducer` local por defecto.** Sube a Context solo
lo que es genuinely transversal (tema, sesión, feature flags) — Context
re-renderiza todos sus consumidores en cada cambio, así que no es el default
para todo.

Escalá de Context a un store dedicado (Zustand, Jotai) **solo** si se cumple
alguna de estas:

- 3 o más features no relacionadas entre sí leen o escriben el mismo estado de
  UI.
- Necesitás selectors granulares para evitar que un cambio re-renderice
  consumidores que no leen ese campo — algo que Context no resuelve por sí
  solo.

Si ninguna aplica, no sumes un store — es complejidad que no se paga sola.

## Memoización: manual vs React Compiler

Antes de agregar `useMemo`/`useCallback`/`memo` a mano, confirmá si el
proyecto tiene **React Compiler** habilitado (`babel-plugin-react-compiler` o
el equivalente en su build). Si lo tiene, la memoización manual **no hace
falta** — el compilador ya optimiza los re-renders automáticamente, y
agregarla igual es ruido sin beneficio (ver la nota de
`react-references`, regla `rerender-memo`). Si el proyecto no lo tiene
habilitado, seguí aplicando las reglas de memoización de `react-references`
tal como están.

## Forms

Librería de forms es una decisión recurrente, no un detalle menor:

- **React Hook Form** como default para cualquier form con validación real,
  campos condicionales, o más de 2-3 campos — minimiza re-renders (no
  controlado por default) y su integración con schemas (Zod u otro) cubre la
  validación sin código a mano.
- **Controlled inputs nativos** (`useState` + `onChange`) solo para 1-2
  campos triviales sin validación cruzada (ej. un buscador). No lo escales a
  un form real — ahí ya corresponde React Hook Form.

## Testing: qué se testea y qué no

Stack: **Vitest + React Testing Library** para unit/integration,
**Playwright** para e2e. La mecánica (queries, `render`, `userEvent`) la sabe
el modelo; acá va la política de **qué amerita test**:

- **Test completo siempre:**
  - Hooks personalizados con lógica propia (no wrappers triviales de una
    query).
  - Componentes con lógica condicional no trivial (ramas, estados de
    error/carga).
  - Queries/mutations con lógica de transformación de datos (no solo un fetch
    directo).
- **Smoke test alcanza** (renderiza sin crashear, no más) en componentes de
  presentación pura: reciben props, pintan JSX, sin lógica propia.
- **E2E (Playwright) solo en golden paths de negocio** críticos: checkout,
  login, el submit que no puede romperse.
- **RTL: queries por rol/texto** (`getByRole`, `getByText`), nunca por clase o
  `data-testid` salvo que no haya otra forma accesible de ubicar el elemento —
  si hace falta un `data-testid`, es señal de que el componente no expone un
  rol/texto claro.
- **Mocks solo en los límites externos** (HTTP vía MSW, storage). Nunca
  mockees un hook o componente propio para testear otro propio.

## Manejo de errores

React no trae un mecanismo built-in (a diferencia de `error.tsx` en Next) —
dónde vive el Error Boundary es una decisión explícita:

- **Un Error Boundary raíz siempre**, envolviendo toda la app — última línea
  de defensa para que un error no deje una pantalla en blanco.
- **Boundaries por feature/ruta** cuando esa feature puede fallar de forma
  independiente del resto de la app (ej. un widget de terceros, una sección
  con su propio fetch) — así un error ahí no tira abajo el resto de la UI.
  No pongas un boundary por cada componente; es una herramienta de
  aislamiento a nivel de feature, no de detalle.

## Respetar lo que ya existe

Si un proyecto ya tiene otra estructura de carpetas o ya usa Redux/Recoil sin
necesitarlo, no lo migres de prepo — proponé el cambio, no lo impongas. Estas
convenciones son el default en código **nuevo**; en un repo existente, el
patrón ya establecido gana salvo que el usuario pida migrar.

## Al terminar, reportá

1. Dónde ubicaste los archivos nuevos y por qué (core/shared/feature).
2. Si un dato nuevo quedó en TanStack Query/SWR o en estado de cliente, y por
   qué.
3. Si sumaste o evitaste sumar un store, y cuál de los criterios de escalación
   aplicó (o por qué ninguno aplicó).
4. Qué quedó con test completo, qué con smoke test, y qué dejaste sin migrar
   por respetar el estado actual del proyecto.
5. Si el cambio introdujo o tocó un form: qué librería usaste y por qué.
6. Si agregaste o evitaste memoización manual, y si el proyecto tiene React
   Compiler habilitado.
