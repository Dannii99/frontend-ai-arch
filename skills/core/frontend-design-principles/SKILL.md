---
name: frontend-design-principles
description: >-
  SOLID aplicado a frontend (componentes, hooks/composables, servicios) y los
  patrones que sostienen la arquitectura cuando el proyecto escala: Facade para
  aislar SDKs/APIs de terceros, Repository para la capa de acceso a datos,
  Adapter para normalizar datos externos al modelo interno. Úsala al diseñar la
  capa de servicios/datos de una feature, al integrar un SDK externo, o al
  revisar si un módulo viola SRP/DIP. Cada patrón tiene un disparador concreto
  para aplicarse — nunca por defecto, para evitar over-engineering. Agnóstica
  de framework.
compatibility: agnostic
metadata:
  category: frontend-architecture-principles
  framework: agnostic
---

# Frontend Design Principles

Esta skill es la capa del medio: `frontend-clean-code` cubre calidad a nivel
micro (nombres, tipos, tamaño de función); `angular-architecture` /
`react-architecture` / `next-architecture` deciden estructura de carpetas y
estado por framework. Acá van los **principios** (SOLID) y los **patrones**
que mantienen esa arquitectura estable cuando el proyecto crece — el nivel de
módulo/servicio, no el de función ni el de carpeta.

## Cuándo usar

- Diseñás la capa de servicios/datos de una feature nueva.
- Vas a integrar un SDK o API de terceros (pagos, analytics, auth, mapas).
- Revisás un módulo que empieza a ser difícil de testear o de extender sin
  tocar lo que ya funciona.
- Un `switch`/`if-else` de reglas de negocio crece cada vez que aparece un
  caso nuevo.

## SOLID en frontend

- **S — Single Responsibility**: un componente/hook/servicio cambia por una
  sola razón. Si un componente hace fetch, transforma datos y maneja el layout
  de tres secciones, son tres responsabilidades — se parte.
  (`frontend-clean-code` ya aplica esto a nivel de función; acá aplica a nivel
  de módulo completo.)
- **O — Open/Closed**: se extiende sin modificar lo que ya funciona. Una regla
  de negocio con variantes (cálculo de precio, validación por tipo de usuario)
  se resuelve agregando una implementación nueva, no una rama más a un
  `if/else` que ya es largo — eso es Strategy en la práctica.
- **L — Liskov Substitution**: si dos implementaciones cumplen la misma
  interfaz (dos adaptadores de pago, dos repositorios), tienen que ser
  intercambiables sin que quien las consume note la diferencia. Si una
  "variante" de un componente rompe el contrato del original (props que dejan
  de funcionar, eventos que no se disparan), no es una variante — es otro
  componente con otro nombre.
- **I — Interface Segregation**: no le impongas a un consumidor props/métodos
  que no usa. Preferí varias interfaces chicas (props específicas, hooks
  separados) a una interfaz gigante con la mitad de los campos `undefined`
  según el caso de uso.
- **D — Dependency Inversion**: los módulos de alto nivel (componentes de
  feature) dependen de una abstracción (un hook, una interfaz de repositorio),
  no de una implementación concreta (un SDK, un cliente HTTP específico). Es
  la base de Facade y Repository, más abajo.

## Patrones — y cuándo NO usarlos todavía

Regla de fondo: **ningún patrón de acá se aplica por defecto.** Se introduce
cuando aparece un disparador concreto; antes de eso, la solución directa
(fetch en la función, llamada directa al SDK) es preferible. Meter la
abstracción antes de tiempo es la misma complejidad injustificada que ya
evitamos al no sumar un store sin necesidad en `angular-architecture` /
`react-architecture` — mismo criterio, aplicado acá a patrones en vez de a
estado.

### Facade — aislar un SDK o API de terceros

Envolvé Stripe, Firebase, un SDK de analytics, etc. detrás de una interfaz
propia con solo los métodos que tu app usa.

**Aplicá cuando:**
- El SDK se usa en 3+ lugares del código (si se usa en uno solo, no hay nada
  que aislar todavía).
- Hay razón concreta para anticipar un cambio de proveedor.
- Necesitás mockearlo en tests sin cargar el SDK real.

**No apliques si:** el SDK se usa en un solo componente y no hay plan de
reemplazarlo — el facade ahí es una capa extra sin beneficio.

```ts
// el resto de la app importa esto, nunca el SDK directo
export const paymentsFacade = {
  charge: (amountCents: number, token: string) =>
    stripe.charges.create({ amount: amountCents, source: token }),
};
```

### Repository — abstraer el origen de los datos

La feature no llama al fetch o al ORM directo; depende de una interfaz que
abstrae de dónde vienen los datos.

**Aplicá cuando:**
- Los tests necesitan mockear el origen de datos sin levantar red.
- Hay 2+ fuentes reales (API + cache local, o dos backends en migración).
- Hay un plan concreto de cambiar de backend o proveedor.

**No apliques si:** es un CRUD simple contra un solo backend, sin necesidad de
mockear — ahí el fetch directo en la capa de datos de la feature (la carpeta
`api/` de `angular-architecture`/`react-architecture`) alcanza.

### Adapter — normalizar datos externos al modelo interno

El shape que devuelve un backend o API externa se traduce a tu modelo interno
en un solo punto de entrada — nunca se propaga crudo por la UI.
`frontend-clean-code` ya pide esto a nivel de tipado (DTO → modelo de vista);
acá es el patrón que lo implementa cuando la traducción deja de ser trivial.

**Aplicá cuando:** el shape externo cambia entre entornos/versiones de API, o
cuando 2+ fuentes distintas necesitan mapearse al mismo modelo interno.

**No apliques si:** el DTO ya es el modelo que necesitás — mapear por mapear
no aporta nada.

## Límites entre módulos (DIP a nivel de carpeta)

La dirección de dependencia va de específico a genérico, nunca al revés:

```
features/<a>  →  shared/  →  core/
```

Una feature puede depender de `shared/` y `core/`; nunca al revés, y nunca una
feature de otra feature directamente. Si dos features necesitan compartir
algo, ese algo se promueve a `shared/` — no se importa cruzado. La regla de
carpetas ya está en `angular-architecture`/`react-architecture`; esto es el
principio general detrás: DIP aplicado a nivel de módulo, no de clase.

## Qué NO va acá

- Nomenclatura, tipado, tamaño de función → `frontend-clean-code` (core).
- Dónde vive cada archivo, estado de UI vs servidor, testing por framework →
  `angular-architecture` / `react-architecture` / `next-architecture`.
- Esta skill da el principio y el patrón; las de framework deciden la
  implementación concreta (un `inject()` en Angular, un hook en React).

## Al terminar, reportá

1. Qué principio SOLID motivó un cambio de diseño (o "ninguno, el diseño
   existente ya cumple").
2. Si introdujiste un patrón (Facade/Repository/Adapter), qué disparador
   concreto lo justificó.
3. Si detectaste una violación (una feature importando de otra, un módulo con
   más de una razón para cambiar) y qué dejaste señalado sin migrar de prepo.
