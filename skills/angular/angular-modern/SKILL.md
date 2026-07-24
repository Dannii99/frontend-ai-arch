---
name: angular-modern
description: >-
  Convenciones de Angular moderno (v17+) que el agente debe seguir al escribir o
  refactorizar componentes, servicios, templates y estado: standalone, signals,
  control flow nativo, inject(), host bindings e interop con RxJS. Úsala en
  cualquier tarea de Angular para fijar la sintaxis actual y evitar patrones
  viejos (NgModules, decorators de I/O, *ngIf, getters para estado derivado).
  No la uses para AngularJS ni proyectos no-Angular.
compatibility: angular
metadata:
  category: angular-conventions
  framework: angular
---

# Angular Modern

Esta skill no re-enseña la API de Angular — el modelo ya la sabe. Fija las
**convenciones** de Angular moderno que exigís y las decisiones de cuándo usar
qué, para que todo lo que se escriba salga con la sintaxis actual y consistente,
sin volver a patrones viejos.

Regla de fondo (igual que el resto de tus skills): respetá lo que el proyecto ya
usa. Si un repo todavía está en NgModules, no lo migres entero de prepo —proponé,
no impongas—. En código nuevo, estas convenciones son el default.

## Cuándo usar

- Cualquier tarea de Angular: crear o refactorizar componentes, servicios,
  templates, manejo de estado.
- Cuando el agente se va a sintaxis vieja: decorators de input/output, `*ngIf`,
  inyección por constructor, getters para derivar estado.

## Componentes

- **Standalone por defecto**: no declares `standalone: true` (ya lo es); nada de
  NgModules para código nuevo.
- **`OnPush` siempre** (`ChangeDetectionStrategy.OnPush`).
- **`input()` / `output()`**, no los decorators `@Input()` / `@Output()`.
- **`inject()`**, no inyección por constructor.
- **`model()`** para two-way binding, solo cuando de verdad hace falta.
- **`viewChild()` / `contentChild()`** (signal queries), no `@ViewChild` /
  `@ContentChild`.
- **Host bindings en el objeto `host`** del decorator, no `@HostBinding` /
  `@HostListener`.

## Templates

- **Control flow nativo**: `@if` / `@for` / `@switch`, no `*ngIf` / `*ngFor` /
  `*ngSwitch`.
- **Siempre `track`** en `@for`.
- **`@defer`** para contenido pesado fuera del viewport inicial.
- **Binding directo**: `[class.activo]`, `[style.width.px]` — no `[ngClass]` /
  `[ngStyle]`.
- **`NgOptimizedImage`** para imágenes estáticas.

## Estado y reactividad (signals primero)

- **Signals** para estado local; **`computed()`** para estado derivado (no
  getters, no recalcular a mano).
- **`effect()` solo para side effects**: sincronizar con el mundo externo (red,
  DOM, storage). Nunca para derivar estado — si un effect solo recalcula a partir
  de otras señales, eso es un `computed()`.
- **`linkedSignal()`** para estado dependiente que se resetea cuando cambia su
  fuente.
- **`resource()`** para fetch async con estado de carga/error integrado (donde la
  versión de Angular lo soporte).
- **Servicios con estado**: estado privado writable, señales públicas con
  `asReadonly()`, y `computed()` para los selectores.

## Interop con RxJS

- **`toSignal()` / `toObservable()`** para cruzar entre mundos; en el template,
  señales o `async` pipe.
- **No dejes subscripciones colgadas**: `takeUntilDestroyed()` o `async` pipe.
- **`catchError` dentro del `switchMap`**, para no matar el stream externo.
- **`switchMap`** para "solo el último", **`exhaustMap`** para "ignorar mientras
  está ocupado".

## Arquitectura (lo específico de Angular)

- Una feature por ruta lazy.
- Config por entorno, sin URLs ni claves hardcodeadas (la verificación pre-deploy
  la cubre `angular-deploy-safety`).

## Qué NO va acá

Los principios universales —tipado, nombres, componentes chicos, una
responsabilidad, modelado de estado— viven en `frontend-clean-code` (core). Acá
va solo el *cómo se hace en Angular*. Si algo aplica a cualquier front, no lo
repitas: es core.

## Al terminar, reportá

1. Qué convenciones aplicaste o corregiste (sintaxis vieja → moderna).
2. Qué dejaste sin migrar por respetar el estado actual del proyecto.
3. Cualquier API reciente que usaste y que dependa de la versión de Angular.