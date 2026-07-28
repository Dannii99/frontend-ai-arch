---
name: frontend-security
description: >-
  Principios de seguridad de aplicación agnósticos de framework: XSS,
  inyección, CSRF, manejo de secrets/sesión, validación de input, y
  dependencias. Úsala al escribir o revisar cualquier código que renderice
  contenido dinámico, maneje input de usuario, llame una API, o gestione
  sesión/autenticación. No es seguridad de deploy/build (ver la sección
  Deploy safety de angular-architecture y Variables de entorno de
  next-architecture para eso) — es seguridad de runtime de la aplicación.
compatibility: agnostic
metadata:
  category: security
  framework: agnostic
---

# Frontend Security

La seguridad de aplicación no es un checklist aparte: es parte de escribir
bien cualquier código que toque input de usuario, contenido dinámico, o una
sesión. Esta skill fija los principios agnósticos; la sintaxis específica de
cada framework (qué API sanitiza qué) la cita `angular-architecture` /
`react-architecture` / `next-architecture` en su propia sección "Seguridad".

## Cuándo usar

- Renderizás contenido que viene de un usuario o de una API externa.
- Escribís o revisás un formulario, un endpoint, una Server Action, o
  cualquier código que reciba input.
- Manejás tokens de sesión, autenticación, o cualquier dato sensible.
- Agregás una dependencia nueva de peso.

## XSS

Todo framework moderno (Angular, React, Next) **escapa texto e interpolación
por default** — no hay XSS con `{valor}` en JSX o `{{ valor }}` en un
template Angular. El riesgo real está en los *escape hatches* que desactivan
ese auto-escape a propósito:

- `dangerouslySetInnerHTML` (React/Next), `[innerHTML]` con
  `bypassSecurityTrustHtml` (Angular) — nunca los uses con contenido que
  venga de un usuario o de una API externa sin sanitizar explícitamente
  primero (DOMPurify u equivalente). Si el contenido es 100% controlado por
  el proyecto (un CMS propio, contenido hardcodeado), el riesgo baja pero
  segui sanitizando si ese contenido puede editarlo alguien no confiable.
- URLs dinámicas en `href`/`src` que vienen de input de usuario: validá el
  esquema (bloqueá `javascript:`) antes de usarlas.

## Inyección

No es solo SQL: nunca interpoles input de usuario crudo en una query, un
comando de shell, una URL, o un header. Si el proyecto arma queries a mano en
vez de usar un ORM/query builder parametrizado, es una señal de riesgo — no
de estilo.

## CSRF

Cualquier acción que cambie estado server-side (no solo lecturas) necesita
protección real:

- Cookies de sesión con `SameSite=Lax` o `Strict`.
- Si el framework no lo resuelve solo (un endpoint REST clásico, a
  diferencia de una Server Action de Next, que ya valida same-origin),
  sumá un token anti-CSRF explícito.

## Secrets y datos sensibles

- Nunca en el bundle del cliente, nunca en `localStorage`/`sessionStorage`
  sin necesidad concreta — un token robado vía XSS en `localStorage` es
  inmediatamente usable; en una cookie `httpOnly` no.
- Esto ya lo operan, para su framework, la sección "Deploy safety" de
  `angular-architecture` (qué no filtra al bundle de producción) y
  "Variables de entorno" de `next-architecture` (`NEXT_PUBLIC_*`) — no
  repitas ese checklist acá, aplicalo.

## Validación de input

**Siempre en el server, nunca solo en el cliente.** La validación de
cliente es UX (feedback rápido); el gate real de seguridad es la
revalidación en el boundary server — Server Action, Route Handler, endpoint,
API. Un input que pasó la validación del form pero no se revalida del lado
del server es una vulnerabilidad, no un detalle.

## Sesión y autenticación

Nota breve, no un manual de auth completo: preferí una cookie de sesión
`httpOnly` + `Secure` + `SameSite` sobre guardar el token en
`localStorage`/`sessionStorage` — mitiga que un XSS robe la sesión
directamente. La elección de proveedor/flow de auth (OAuth, JWT, sesiones de
servidor) es una decisión de producto, fuera del alcance de esta skill.

## Dependencias

Antes de agregar una dependencia nueva de peso: revisá que no tenga
vulnerabilidades conocidas (`npm audit` u equivalente) y preferí una
mantenida activamente. Disciplina de lockfile (commiteado, no editado a
mano) — no es una política de supply chain completa, es higiene básica.

## Cabeceras de seguridad

Cuando el proyecto controla su config de hosting/servidor: Content-Security-
Policy, `X-Frame-Options`/`frame-ancestors` (anti-clickjacking),
`Referrer-Policy`. Si el hosting es de terceros sin control de config
(algunos static hosts), anotalo como limitación en vez de fingir que se
puede resolver desde el código de la app.

## Qué NO va acá

Seguridad de *deploy/build* (qué se filtra al bundle, environments) vive en
la sección Deploy safety de `angular-architecture` y Variables de entorno de
`next-architecture` — esta skill es runtime de aplicación, no build. No
dupliques esas secciones acá, citalas.

## Al terminar, reportá

1. Qué riesgo revisaste o corregiste (XSS, inyección, CSRF, secrets,
   validación) y en qué archivo.
2. Cualquier escape hatch (`dangerouslySetInnerHTML`, `bypassSecurityTrust*`)
   que quedó en el código, y si el contenido que sanitiza está confirmado
   como confiable o sanitizado explícitamente.
3. Si agregaste una dependencia nueva: resultado del chequeo de
   vulnerabilidades conocidas.
