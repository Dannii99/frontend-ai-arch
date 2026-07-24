---
name: angular-architecture
description: >-
  Fija las decisiones de arquitectura Angular que la sintaxis del framework
  deja abiertas: estructura de carpetas (core/shared/features), cuándo signals
  alcanza vs cuándo sumar un store, política de interop RxJS↔signals, y qué se
  testea siempre vs qué alcanza con un smoke test. Úsala al organizar un
  proyecto nuevo, al decidir dónde vive un archivo nuevo, al evaluar si un
  estado necesita un store, o al revisar un PR de Angular. No es referencia de
  sintaxis (ver skills-main/angular-developer para eso).
compatibility: angular
metadata:
  category: angular-architecture
  framework: angular
---

# Angular Architecture

Esta skill no re-enseña la API de Angular ni su sintaxis moderna — eso ya está
cubierto en profundidad en `skills-main/angular-developer` (referencia oficial
de Angular: signals, inputs/outputs, forms, DI, routing, testing mechanics,
etc.). Consultá esa skill para "qué existe y cómo se usa".

Acá van las decisiones que Angular deja abiertas y que este proyecto resuelve
siempre de la misma forma: dónde vive cada archivo, cuándo un estado necesita
más que un signal, y qué se testea de verdad.

Los principios universales (tipado, nombres, componentes chicos, una
responsabilidad) viven en `frontend-clean-code` (core); SOLID y los patrones
de arquitectura (Facade, Repository, Adapter, límites entre módulos) viven en
`frontend-design-principles` (core). Si algo aplica a cualquier front, no lo
repitas acá: es core.

## Cuándo usar

- Organizás un proyecto Angular nuevo o agregás una feature a uno existente.
- Dudás dónde poner un archivo nuevo (¿`core/`? ¿`shared/`? ¿dentro de la
  feature?).
- Vas a sumar estado compartido y no está claro si alcanza con un servicio +
  signals o hace falta un store.
- Revisás un PR de Angular y necesitás un criterio objetivo de qué debía tener
  test y qué no.

## Estructura de carpetas

```
src/app/
├── core/          # interceptors, guards globales, servicios singleton
├── shared/        # componentes/pipes/directivas reutilizables, sin lógica de negocio
└── features/
    └── checkout/
        ├── checkout.routes.ts
        ├── checkout.component.ts
        ├── services/
        └── components/   # subcomponentes privados de la feature
```

- **`core/`**: solo lo que es singleton y transversal a toda la app
  (interceptors HTTP, guards globales, servicios `providedIn: 'root'` que no
  pertenecen a ninguna feature puntual). Si dudás si algo va acá, probablemente
  no — default a `features/`.
- **`shared/`**: componentes, pipes y directivas reutilizables **sin** lógica
  de negocio. Un componente pasa de una feature a `shared/` recién cuando un
  segundo consumidor real lo necesita — no lo muevas ahí "por si acaso".
- **`features/<nombre>/`**: autocontenida. Sus `components/` internos son
  privados a la feature por default; no se importan desde otra feature. Si
  hace falta compartirlo, se promueve a `shared/` explícitamente.
- **Una feature por ruta lazy**: cada entrada de `features/` se carga con lazy
  loading en su propia ruta. Evita que una feature no usada infle el bundle
  inicial (la verificación de qué termina en el bundle de producción la cubre
  `angular-deploy-safety`).

## Manejo de estado

Default: un servicio con `providedIn: 'root'` (o scoped a la feature), signal
privada writable, señales públicas expuestas con `asReadonly()`, y
`computed()` para los selectores derivados. Esto alcanza para la enorme
mayoría de los casos — no arranques con un store.

Escalá a un store (NgRx u otro) **solo** si se cumple alguna de estas:

- 3 o más features no relacionadas entre sí leen o escriben el mismo estado.
- Necesitás undo/redo o time-travel debugging real.
- El estado tiene una máquina de estados compleja (múltiples transiciones
  condicionadas entre sí, tipo XState).

Si ninguna aplica, **no** metas un store — es complejidad que no se paga sola.
Si más adelante alguna empieza a aplicar, es una migración localizada del
servicio afectado, no un rediseño de toda la app.

## Interop RxJS ↔ Signals

- **`toSignal()` / `toObservable()`** para cruzar entre los dos mundos; en el
  template, señales o `async` pipe — no ambos a la vez para el mismo dato.
- **No dejes subscripciones colgadas**: `takeUntilDestroyed()` o `async` pipe,
  nunca un `subscribe()` sin gestión de ciclo de vida.
- **`catchError` dentro del `switchMap`** (o el operador de turno), para que un
  error no mate el stream externo que lo contiene.
- **`switchMap`** para "solo importa la última petición" (búsquedas,
  filtros); **`exhaustMap`** para "ignorar mientras está ocupado" (submits,
  botones que no deben re-dispararse).

## Testing: qué se testea y qué no

La mecánica de testing (Vitest, `TestBed`, patrón Act/Wait/Assert) está en
`skills-main/angular-developer` (`references/testing-fundamentals.md`). Acá va
la política de **qué amerita test**:

- **Test completo siempre:**
  - Servicios con lógica de negocio (computed derivados, effects con side
    effects reales).
  - Guards y resolvers.
  - Componentes con lógica condicional no trivial (ramas, estados de
    error/carga).
- **Smoke test alcanza** (renderiza sin crashear, no más) en componentes de
  presentación pura: reciben `input()`, pintan template, sin lógica propia.
- **E2E (Playwright) solo en golden paths de negocio** críticos: checkout,
  login, el submit que no puede romperse. No dupliques ahí lo que ya cubre un
  unit test.
- **Mocks solo en los límites externos** (HTTP, storage, APIs de terceros).
  Nunca mockees un servicio propio para testear otro propio — si hace falta
  mockearlo, es señal de que el límite entre ambos está mal puesto.

## Respetar lo que ya existe

Si un proyecto ya tiene otra estructura de carpetas o ya usa NgRx sin
necesitarlo, no lo migres de prepo — proponé el cambio, no lo impongas. Estas
convenciones son el default en código **nuevo**; en un repo existente, el
patrón ya establecido gana salvo que el usuario pida migrar.

## Al terminar, reportá

1. Dónde ubicaste los archivos nuevos y por qué (core/shared/feature).
2. Si sumaste o evitaste sumar un store, y cuál de los criterios de escalación
   aplicó (o por qué ninguno aplicó).
3. Qué quedó con test completo, qué con smoke test, y qué dejaste sin migrar
   por respetar el estado actual del proyecto.
