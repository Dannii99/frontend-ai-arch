---
name: next-conventions
description: >-
  Convenciones y decisiones de Next.js (App Router, v15+) que el agente debe
  seguir: Server/Client Components, Server Actions vs Route Handlers, params
  async, next/image y next/font, runtime, manejo de errores y navegación. Úsala
  en cualquier tarea de Next para fijar los defaults correctos y evitar los
  errores típicos (client components async, props no serializables, try-catch
  sobre redirect, <img> en vez de next/image). No la uses para React puro
  (Vite/CRA) — para eso está react/.
compatibility: next
metadata:
  category: next-conventions
  framework: next
---

# Next.js Conventions

Esta skill no re-enseña Next — para eso está `next-best-practices` (referencia
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
[rsc-boundaries.md](../next-best-practices/rsc-boundaries.md) en
`next-best-practices`.

## Data

- **Lecturas internas**: fetch directo en Server Components, sin capa de API.
- **Mutaciones desde la UI**: Server Actions (`'use server'`).
- **APIs externas, webhooks, REST público**: Route Handlers (`route.ts`).
- **Evitá waterfalls**: `Promise.all` para fetches independientes; `Suspense`
  para streamear de a secciones.

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
  Carpetas privadas con prefijo `_`. En v16, `middleware.ts` pasó a `proxy.ts`.
- `metadata` / `generateMetadata` solo en Server Components. Para la mayoría,
  archivos estáticos (`opengraph-image`, `sitemap`, `robots`) alcanzan. OG con
  `next/og`, no `@vercel/og`.

## Qué NO va acá

Los principios universales —tipado, nombres, estado, componentes chicos, a11y—
viven en `frontend-clean-code` y `accessibility-a11y` (core); SOLID y los
patrones de arquitectura (Facade, Repository, Adapter, límites entre módulos)
viven en `frontend-design-principles` (core). Acá va solo el *cómo se hace en
Next*. Y como Next ya es React, en un proyecto Next no se cargan además las
convenciones de React puro.

## Referencias (capa profunda, se abren cuando hacen falta)

Esta skill fija criterio, no repite la API completa de Next. Para el detalle
línea por línea de cada tema (convenciones de archivos, async patterns, data
patterns, metadata, imágenes, fuentes, bundling, hydration, etc.), está
`next-best-practices` — la referencia dura, agnóstica de tus decisiones, que
cubre Next.js API por API. No dupliques contenido de ahí acá: si una regla ya
está en `next-best-practices`, esta skill solo la cita y decide un default.

- [rsc-boundaries.md](../next-best-practices/rsc-boundaries.md) — casos límite
  Server↔Client con ejemplos Bad/Good (el único tema que esta skill cita en
  detalle, porque es donde más se rompe en la práctica).
- Doc oficial para lo que ni siquiera `next-best-practices` cubra:
  https://nextjs.org/docs/app · https://react.dev/reference/rsc/use-client

## Al terminar, reportá

1. Qué convenciones aplicaste o corregiste (patrón viejo/inválido → correcto).
2. Qué dejaste sin migrar por respetar el estado del proyecto (Pages Router,
   versión).
3. Cualquier API que dependa de la versión de Next (async params, `proxy.ts`,
   runtime).
