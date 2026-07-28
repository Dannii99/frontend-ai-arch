---
name: next-architecture
description: >-
  Convenciones y decisiones de Next.js (App Router, v15+) que el agente debe
  seguir: estructura de carpetas, Server/Client Components, Server Actions vs
  Route Handlers, params async, modelo de caching (fetch/revalidate/'use
  cache'), variables de entorno (qué puede llegar al cliente), next/image y
  next/font, runtime, middleware/proxy, manejo de errores y navegación, y qué
  se testea siempre vs qué alcanza con un smoke test vs qué queda para e2e.
  Úsala en cualquier tarea de Next para fijar los defaults correctos y evitar
  los errores típicos (client components async, props no serializables,
  try-catch sobre redirect, <img> en vez de next/image, secrets filtrados al
  bundle del cliente). No la uses para React puro (Vite/CRA) — para eso está
  react/.
compatibility: next
metadata:
  category: next-architecture
  framework: next
---

# Next.js Architecture

Esta skill no re-enseña Next — para eso está `next-references` (referencia
dura, API por API, en la misma carpeta). Acá van las **decisiones** que exigís
y los errores que Next hace fáciles de cometer, para que los defaults salgan
bien. Es criterio, no manual.

Regla de fondo (como el resto de tus skills): respetá lo que el proyecto ya usa.
Si está en Pages Router, no lo migres a App Router de prepo; si está en una
versión vieja, no fuerces APIs nuevas. Proponé, no impongas.

## Cuándo usar

- Cualquier tarea en un proyecto Next: componentes, rutas, data, config.
- Cuando el agente cae en patrones viejos o inválidos: client component async,
  `<img>`, o fetch en `useEffect` donde iría un Server Component.
- Dudás dónde poner un archivo nuevo (¿glue de `app/`? ¿`features/`?
  ¿`shared/`?) o qué amerita test completo.

## Estructura de carpetas

Mismo criterio `core/`/`shared/`/`features/` que fija `react-architecture` —
no repitas acá el porqué de ese límite (cuándo algo es transversal, cuándo se
promueve a `shared/`), solo lo que cambia por el file-system routing de Next:

```
app/
├── (marketing)/           # route groups, solo si agrupan sin tocar la URL
└── checkout/
    ├── page.tsx · layout.tsx · loading.tsx · error.tsx
    └── _components/       # privado a esta ruta (prefijo _ lo excluye del routing)
src/
├── core/          # providers globales, config, clients — igual criterio que react-architecture
├── shared/        # reutilizable sin lógica de negocio
└── features/
    └── checkout/
        ├── components/ · hooks/
        └── api/           # Server Actions / queries de esta feature
```

- **`app/`** contiene solo los archivos especiales que Next exige
  (`page`/`layout`/`loading`/`error`/`route`/`template`) más glue fino que
  importa de `src/features/<feature>/`. La lógica de negocio nunca vive
  directo en `app/` — si un `page.tsx` empieza a acumular lógica, esa lógica
  se mueve a la feature correspondiente.
- **`_components/`/`_lib/`** (prefijo `_`, Next los excluye del routing): solo
  para lo verdaderamente privado a una única ruta, sin otro consumidor. Se
  promueve a `src/shared/` recién con un segundo consumidor real — mismo
  trigger que `react-architecture`, no antes.
- **`src/core/`** / **`src/shared/`** / **`src/features/`**: mismas
  definiciones y mismo criterio de escalado que `react-architecture` — la
  única diferencia es que en Next el punto de entrada de cada ruta vive en
  `app/`, no en la feature.

## Server vs Client Components

- **Server Component por defecto.** `'use client'` solo cuando hace falta de
  verdad: hooks de estado/efecto, event handlers o browser APIs.
- **Empujá `'use client'` a las hojas**, no a la raíz. Un `'use client'` arriba
  cliente-iza todo el subárbol y perdés el beneficio de RSC.
- **Los Client Components no pueden ser async.** Si necesitás `await`, fetchealo
  en el Server Component padre y pasá los datos como props.
- **Props Server→Client tienen que ser serializables**: `Date` → ISO string;
  `Map`/`Set` → array u objeto; funciones → no (salvo Server Actions); instancias
  de clase → objeto plano.

Para los casos límite con ejemplos Bad/Good (client async, props no
serializables, la excepción de las Server Actions), ver
[rsc-boundaries.md](../next-references/rsc-boundaries.md) en
`next-references`.

## Data

- **Lecturas internas**: fetch directo en Server Components, sin capa de API.
- **Mutaciones desde la UI**: Server Actions (`'use server'`).
- **APIs externas, webhooks, REST público**: Route Handlers (`route.ts`).
- **Evitá waterfalls**: `Promise.all` para fetches independientes; `Suspense`
  para streamear de a secciones.

## Caching

Es el área donde más se rompe el default esperado — el criterio:

- **`fetch` con `revalidate`** (`fetch(url, { next: { revalidate: N } })`)
  para la mayoría de las lecturas: revalidación por tiempo, simple y
  suficiente para el caso común.
- **`'use cache'`** (Cache Components) cuando el proyecto ya adoptó esa
  feature — cachea la salida de una función o componente entero, con más
  control que `revalidate` puntual. Ver `next-references/directives.md`. No
  la introduzcas en un proyecto que no la adoptó explícitamente; es un
  cambio de modelo de caching, no un default silencioso.
- **`unstable_cache`** solo para envolver una función de datos que no es un
  `fetch` (una query directa a DB, por ejemplo) y necesita la misma
  semántica de cache que el resto de la app.
- Si el change va a adoptar partial prefetching o el sweep de insights de
  caching en profundidad, eso es un proyecto aparte — ver la skill opt-in
  `domains/next-partial-prefetching-adoption`, no la reinventes acá.

## Variables de entorno

Mismo tipo de riesgo que cubre "Deploy safety" en `angular-architecture`,
adaptado a cómo Next expone env vars al bundle:

- **`NEXT_PUBLIC_*` se filtra al bundle del cliente.** Nunca prefijes así un
  secret, token o cualquier valor que no deba ser público — una vez en el
  bundle, es visible para cualquiera que inspeccione el JS servido.
- **Env vars sin ese prefijo solo se leen server-side** (Server Components,
  Route Handlers, Server Actions, middleware/proxy). Si un Client Component
  necesita un valor de config, pasalo explícitamente como prop desde un
  Server Component — no accedas a `process.env` directo en un Client
  Component esperando que resuelva.
- Ante la duda de si un valor es sensible, tratalo como sensible: sin
  `NEXT_PUBLIC_`, acceso solo server-side.

## APIs async (v15+)

- `params`, `searchParams`, `cookies()` y `headers()` son **asíncronas**:
  tipalas `Promise<...>` y `await`. En componentes no-async, `use()`.

## Optimización (no negociable)

- **`next/image` siempre**, nunca `<img>`. Los remotos requieren `remotePatterns`
  en la config. `priority` en la imagen LCP; `sizes` cuando uses `fill`.
- **`next/font` siempre**, nunca `<link>` de Google Fonts ni `@import`. Importá
  una vez en el layout y exponé como CSS var; no re-instancies la fuente por
  componente.
- **`next/script`** para terceros; **`@next/third-parties`** para GA/GTM.
- **Runtime Node por defecto.** Edge solo con una razón concreta (latencia, deps
  compatibles).

## Errores y navegación

- `error.tsx` y `global-error.tsx` son **Client Components** (`'use client'`).
- **No envuelvas `redirect()`, `permanentRedirect()` ni `notFound()` en
  try-catch**: tiran errores internos que Next maneja. Llamalas fuera del try, o
  re-lanzá con `unstable_rethrow` en el catch.

## Hydration (los errores típicos)

- Nada que difiera entre server y cliente en el primer render: hora/`Date`,
  valores random, `window`. Para browser-only, montá en cliente con `useEffect`;
  para IDs, `useId()`.
- HTML válido (no `<div>` dentro de `<p>`).
- `useSearchParams` / `usePathname` en rutas estáticas requieren `Suspense` o
  cliente-izan la página entera — envolvé en `<Suspense>`.

## Routing y metadata (breve)

- Convenciones del App Router: `page`, `layout`, `loading`, `error`, `route`.
  Carpetas privadas con prefijo `_`. En v16, `middleware.ts` pasó a `proxy.ts`
  (ver `next-references/file-conventions.md` para la tabla de migración por
  versión).
- **Middleware/`proxy.ts` solo para lógica liviana**: auth (redirects según
  sesión), rewrites, headers. Nunca lógica de negocio pesada ni llamadas a
  DB ahí — corre en cada request que matchea, antes de llegar a la ruta, y
  un middleware lento degrada toda la app, no solo una página.
- `metadata` / `generateMetadata` solo en Server Components. Para la mayoría,
  archivos estáticos (`opengraph-image`, `sitemap`, `robots`) alcanzan. OG con
  `next/og`, no `@vercel/og`.

## Testing: qué se testea y qué no

Mismo stack y misma política de fondo que `react-architecture` (Vitest + React
Testing Library para unit/integration, Playwright para e2e) — no repitas acá
esa política base, solo el matiz que cambia por Server Components:

- **Un Server Component no se testea unitariamente** como uno Client — es
  async y no tiene hooks. Su cobertura real sale de un test de
  integration/e2e sobre la ruta completa, no de forzar un unit test artificial
  alrededor de un componente que no se presta a eso.
- **Test completo siempre:** Server Actions y Route Handlers con lógica de
  negocio (validación, mutación, side effects) — mismo criterio que un
  servicio en `angular-architecture`. Client Components con lógica
  condicional no trivial (ramas, estados de error/carga).
- **Smoke test alcanza** en Client Components de presentación pura.
- **E2E (Playwright) solo en golden paths de negocio críticos** (checkout,
  login, el submit que no puede romperse) — mismo criterio que
  `react-architecture`; no dupliques ahí lo que ya cubre un test de
  integration.

## Qué NO va acá

Los principios universales —tipado, nombres, estado, componentes chicos, a11y—
viven en `frontend-clean-code` y `accessibility-a11y` (core); SOLID y los
patrones de arquitectura (Facade, Repository, Adapter, límites entre módulos)
viven en `frontend-design-principles` (core). El límite `core/`/`shared/`/
`features/` en sí (por qué existe, cuándo promover algo) es el de
`react-architecture` — acá solo se adapta al routing de Next, no se
re-decide. Acá va solo el *cómo se hace en Next*. Y como Next ya es React, en
un proyecto Next no se cargan además las convenciones de React puro.

## Referencias (capa profunda, se abren cuando hacen falta)

Esta skill fija criterio, no repite la API completa de Next. Para el detalle
línea por línea de cada tema (convenciones de archivos, async patterns, data
patterns, metadata, imágenes, fuentes, bundling, hydration, etc.), está
`next-references` — la referencia dura, agnóstica de tus decisiones, que
cubre Next.js API por API. No dupliques contenido de ahí acá: si una regla ya
está en `next-references`, esta skill solo la cita y decide un default.

- [rsc-boundaries.md](../next-references/rsc-boundaries.md) — casos límite
  Server↔Client con ejemplos Bad/Good (el único tema que esta skill cita en
  detalle, porque es donde más se rompe en la práctica).
- Doc oficial para lo que ni siquiera `next-references` cubra:
  https://nextjs.org/docs/app · https://react.dev/reference/rsc/use-client

## Al terminar, reportá

1. Qué convenciones aplicaste o corregiste (patrón viejo/inválido → correcto).
2. Dónde ubicaste los archivos nuevos (`app/` como glue vs. `features/`/
   `shared/`/`core/`) y por qué.
3. Qué quedó con test completo, qué con smoke test, y qué quedó para e2e (o
   por qué un Server Component no se testeó unitariamente).
4. Qué dejaste sin migrar por respetar el estado del proyecto (Pages Router,
   versión).
5. Cualquier API que dependa de la versión de Next (async params, `proxy.ts`,
   runtime).
6. Qué estrategia de caching usaste (`revalidate`, `'use cache'`,
   `unstable_cache`) y por qué.
7. Si tocaste variables de entorno: confirmá que ninguna sensible quedó
   prefijada `NEXT_PUBLIC_`.
