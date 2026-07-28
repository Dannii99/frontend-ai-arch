---
name: angular-architecture
description: >-
  Fija las decisiones de arquitectura Angular que la sintaxis del framework
  deja abiertas: estructura de carpetas (core/shared/features), cuándo signals
  alcanza vs cuándo sumar un store, política de interop RxJS↔signals, qué se
  testea siempre vs qué alcanza con un smoke test, cuándo usar SSR vs CSR,
  qué sistema de forms usar, manejo de errores, los escape hatches de
  sanitización a evitar (`bypassSecurityTrust*`), y la verificación de deploy
  safety antes de un build productivo. Úsala al organizar un proyecto nuevo,
  al decidir dónde vive un archivo nuevo, al evaluar si un estado necesita un
  store, al revisar un PR de Angular, o antes de cualquier build/deploy
  productivo. No es referencia de sintaxis (ver angular-references/angular-developer
  para eso).
compatibility: angular
metadata:
  category: angular-architecture
  framework: angular
---

# Angular Architecture

Esta skill no re-enseña la API de Angular ni su sintaxis moderna — eso ya está
cubierto en profundidad en `angular-references/angular-developer` (referencia
oficial de Angular: signals, inputs/outputs, forms, DI, routing, testing
mechanics, etc.). Consultá esa skill para "qué existe y cómo se usa".

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
- Se va a correr un build o deploy productivo, se tocó `angular.json`, un
  archivo de `environments/`, o el alias `@env/environment` (ver "Deploy
  safety" más abajo).

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
  inicial (la verificación de qué termina en el bundle de producción está en
  "Deploy safety", más abajo).

## Rendering y detección de cambios

- **Standalone por default**: desde Angular 19, `standalone: true` es el
  default de los componentes (ver `angular-references/angular-developer`,
  `references/components.md`) — no generes `NgModule` para código nuevo
  salvo que el proyecto ya sea NgModule-based y migrarlo no esté en alcance.
- **`ChangeDetectionStrategy.OnPush` en todo componente nuevo.** Combinado
  con signals (que ya notifican sus propios cambios), `OnPush` evita el
  costo de que Angular revise el árbol entero en cada evento. No hay razón
  para arrancar en `Default` en código nuevo.
- **Zoneless**: si el proyecto ya lo habilitó (`provideZonelessChangeDetection()`),
  respetalo — no reintroduzcas Zone.js ni asumas que hace falta para que
  `OnPush` funcione. Si el proyecto todavía usa Zone.js, no migres a zoneless
  de prepo; es una migración explícita, no un default silencioso.

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

## Forms

Angular tiene tres sistemas de forms; no es indiferente cuál usar:

- **Reactive Forms** (`FormGroup`/`FormControl`) es el default hoy para
  cualquier form con validación real, campos condicionales, o más de 2-3
  campos. Es el sistema maduro, con la mecánica cubierta en
  `angular-references/angular-developer` (`references/reactive-forms.md`).
- **Signal Forms** (nuevo, disponible desde Angular v21) — usalo solo si el
  proyecto ya es Angular 21+ y ya adoptó signals-first en el resto de la
  arquitectura (ver "Manejo de estado" arriba). No lo introduzcas en un
  proyecto que todavía está en Reactive Forms sin que te lo pidan — es una
  migración, no un default silencioso. Mecánica en
  `references/signal-forms.md`.
- **Template-driven Forms** (`ngModel`) solo para 1-2 campos triviales sin
  validación cruzada (ej. un buscador, un toggle). No lo escales a un form
  real — ahí ya corresponde Reactive Forms. Mecánica en
  `references/template-driven-forms.md`.

## Testing: qué se testea y qué no

La mecánica de testing (Vitest, `TestBed`, patrón Act/Wait/Assert) está en
`angular-references/angular-developer` (`references/testing-fundamentals.md`).
Acá va la política de **qué amerita test**:

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

## SSR e Hydration

- **CSR por default** salvo que haya una razón concreta de SEO o de
  contenido dinámico indexable. Tabla de decisión (de
  `angular-references/angular-developer`, `references/rendering-strategies.md`):
  SEO + contenido estático → SSG; SEO + contenido dinámico → SSR; sin SEO y
  alta interactividad → CSR.
- **Si el proyecto ya usa SSR** (`@angular/ssr`): nada que difiera entre
  server y cliente en el primer render — `Date`/hora, valores random,
  acceso directo a `window`/`document` fuera de un guard de plataforma
  (`isPlatformBrowser`). Un mismatch ahí rompe la hydration, mismo tipo de
  error que en React/Next.
- No migres un proyecto CSR a SSR de prepo — es una decisión de producto
  (SEO, Core Web Vitals de carga inicial), proponela, no la impongas.

## Manejo de errores

- **`ErrorHandler` global** (vía `provideErrorHandler` o el provider
  equivalente) para errores no capturados — logging/reporting centralizado,
  nunca un error que solo se ve en la consola del usuario.
- **Errores de datos** (guard o resolver que falla) se manejan explícitamente
  en el guard/resolver mismo (redirect a una ruta de error, o un estado de
  error tipado que el componente renderiza) — no dejes que un resolver
  fallido cuelgue la navegación en silencio.

## Seguridad

Principios agnósticos (XSS, inyección, CSRF, validación de input, secrets)
en `frontend-security` (core) — no los repitas acá, aplicalos. El matiz
Angular:

- **Angular sanitiza `[innerHTML]` por default** vía `DomSanitizer` — el
  riesgo real está en `bypassSecurityTrustHtml`/`bypassSecurityTrustScript`/
  `bypassSecurityTrustUrl`/`bypassSecurityTrustResourceUrl`: son escape
  hatches que desactivan esa sanitización. Usalos solo con contenido 100%
  controlado por el proyecto, nunca con input de usuario o de una API
  externa sin sanitizar antes con DOMPurify u equivalente.
- No confundir con "Deploy safety" (arriba): esto es sobre lo que el
  componente renderiza en runtime, no sobre qué se filtra al bundle.

## Deploy safety

Antes de desplegar un build de Angular a producción, verificá que la
configuración de entorno se resolvió correctamente y que nada de desarrollo se
filtró al bundle. El objetivo es cero sorpresas en producción con el mínimo de
cambios.

### Cuándo aplicar esto

- Se va a correr un build o deploy productivo (`--configuration production`).
- Se modificó `angular.json`, un archivo de `environments/`, o el alias
  `@env/environment`.
- Se agregó configuración sensible al entorno (URLs de API, números de
  teléfono de canales, claves, feature flags).
- Hay sospecha de que un valor de dev pueda estar hardcodeado en el código.

### Principio rector

La verdad de qué se despliega está en `dist/`, no en el código fuente. La
verificación final siempre corre contra el output compilado, no contra los
`.ts`.

### Checklist de verificación

**1. Confirmar el swap de environments**

En `angular.json`, la configuración `production` debe tener `fileReplacements`
apuntando de `environment.ts` a `environment.prod.ts`:

```json
"fileReplacements": [
  {
    "replace": "src/environments/environment.ts",
    "with": "src/environments/environment.prod.ts"
  }
]
```

Verificar que:
- El build usa esa configuración (`ng build --configuration production`).
- El alias `@env/environment` en `tsconfig`/`paths` resuelve al archivo base,
  no directamente al de prod (el swap lo hace Angular en build time).
- Cualquier campo nuevo agregado en `environment.ts` existe también en
  `environment.prod.ts` con su valor productivo. Un campo que falta en prod
  rompe el build o queda `undefined` en runtime.

**2. Grep contra el bundle compilado**

Después del build, buscar marcadores de dev en `dist/` antes de subir nada:

```bash
# URLs y hosts de desarrollo
grep -rE "localhost|127\.0\.0\.1|\.dev\.|:4200|ngrok" dist/ || echo "OK: sin hosts de dev"

# Endpoints o dominios de staging/dev conocidos del proyecto
grep -rE "dev-api|staging|internal\." dist/ || echo "OK: sin endpoints de dev"

# Ruido de desarrollo
grep -rE "console\.(log|debug)|debugger" dist/ || echo "OK: sin logs de debug"
```

Cualquier match es un stop: no se despliega hasta resolverlo.

**3. Cambios mínimos y dirigidos**

Si hay que corregir algo (por ejemplo, mover un valor hardcodeado a
environment), hacer el cambio más chico posible. En contextos productivos
sensibles se prefiere un swap puntual guiado por entorno antes que un refactor
amplio. Ejemplo: un selector que elige un número de canal debe leerlo de
`environment` en vez de tener el número en el código.

**4. Dry-run antes del deploy real**

Preferir siempre una verificación previa (build local + grep + revisión del
`dist/`) antes de disparar el pipeline productivo. Nunca desplegar "a ciegas"
un build que no se inspeccionó.

### Salida esperada

Reportar al usuario:
- Configuración de build usada.
- Resultado de cada grep (OK o el match encontrado).
- Campos de environment que falten o difieran entre base y prod.
- Recomendación explícita: seguro para deploy / no seguro y por qué.

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
4. Si el cambio tocó un build/deploy productivo: resultado de la verificación
   de deploy safety (ver esa sección) — seguro para deploy o qué faltó
   resolver.
5. Si el cambio introdujo o tocó un form: qué sistema usaste (Reactive/Signal
   Forms/Template-driven) y por qué.
6. Si el proyecto usa SSR: cualquier riesgo de hydration mismatch detectado
   o corregido.
7. Si el código usa `bypassSecurityTrust*`: confirmá que el contenido está
   sanitizado o es 100% controlado por el proyecto.
