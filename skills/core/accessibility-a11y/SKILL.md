---
name: accessibility-a11y
description: >-
  Audita y mejora la accesibilidad (a11y) de una interfaz siguiendo WCAG.
  Úsala al construir o revisar UI, cuando haya que evaluar qué tan accesible es
  algo, o al trabajar HTML semántico, ARIA, navegación por teclado, contraste,
  foco, formularios accesibles o soporte de lectores de pantalla. Cierra siempre
  con un veredicto de semáforo (rojo/amarillo/verde). Agnóstica de framework.
compatibility: agnostic
metadata:
  category: accessibility
  framework: agnostic
---

# Accessibility (a11y)

La accesibilidad no es un extra ni un checklist al final: es parte de construir
bien. El objetivo es que cualquier persona pueda usar la interfaz —con teclado,
con lector de pantalla, con baja visión, con motricidad reducida— sin quedar
afuera.

Regla de fondo (como el resto de tus skills): mejorás lo que hay de forma
aditiva. No reescribas media UI para arreglar accesibilidad; los arreglos de a11y
suelen ser puntuales y de bajo riesgo (un `alt`, un `label`, un `role`, un foco).

## Cuándo usar

- Construís o revisás cualquier UI interactiva.
- Te piden evaluar o mejorar qué tan accesible es algo.
- Se tocan formularios, navegación, contenido dinámico, imágenes o color.

## HTML semántico primero

- Usá el elemento correcto: `<button>` para acciones, `<a>` para navegación,
  nunca un `<div>` con `onclick`. El elemento nativo trae rol, foco y teclado
  gratis.
- Estructura con landmarks: `<header>`, `<nav>`, `<main>`, `<aside>`, `<footer>`.
- Jerarquía de headings sin saltos (h1 → h2 → h3), una sola h1 por vista.
- ARIA solo donde el HTML no alcanza. La primera regla de ARIA es no usar ARIA si
  hay un elemento nativo que ya lo resuelve.

## ARIA (cuándo sí)

- `aria-label` / `aria-labelledby` para elementos sin texto visible.
- `aria-describedby` para contexto o ayuda.
- `aria-expanded`, `aria-controls` en desplegables; `aria-current="page"` en nav.
- `aria-live` para contenido que cambia sin recargar (resultados, notificaciones,
  errores).
- `aria-hidden="true"` en lo puramente decorativo.

## Teclado

- Toda la funcionalidad tiene que poder usarse solo con teclado.
- Orden de tabulación lógico; `tabindex="0"` para meter en el flujo, `-1` para
  foco programático. Evitá `tabindex` positivos.
- Sin trampas de foco (que no se pueda salir de un widget con teclado).
- Soportá Enter y Espacio en controles; flechas en widgets compuestos (tabs,
  menús, listas).
- Touch targets de al menos 44×44px.

## Color, contraste y foco

- Contraste mínimo AA: 4.5:1 texto normal, 3:1 texto grande.
- Nunca comuniques estado solo con color: sumá ícono, texto o patrón.
- Foco siempre visible. No borres el `outline` sin dar un reemplazo claro.

## Contenido

- Imágenes con `alt` descriptivo; `alt=""` en las decorativas.
- Captions en video, transcripción en audio.
- Texto de link con sentido propio ("ver factura", no "click aquí").
- Unidades relativas (`rem`/`em`); la UI aguanta zoom hasta 200% sin romperse.

## Preferencias del usuario

- Respetá `prefers-reduced-motion` si hay animación.
- Respetá `prefers-color-scheme` y, cuando aplique, `prefers-contrast`.

## Testing

- Automático: axe-core y/o Lighthouse; idealmente en CI. Resolvé los hallazgos
  críticos y serios.
- Manual: navegá solo con teclado, probá con un lector de pantalla (NVDA,
  VoiceOver o JAWS) y con zoom al 200%. Lo automático detecta ~30–40%; el resto
  es manual.

## Semáforo de accesibilidad

Cada vez que uses esta skill para auditar o mejorar algo, cerrá con un veredicto
de color. El color no es una impresión: se ancla en el nivel de conformidad WCAG
que alcanza lo revisado.

🔴 **Rojo — poco accesible.** Hay barreras críticas que dejan gente afuera; falla
nivel WCAG A. Señales típicas:
- elementos interactivos no semánticos (`<div>` que actúa de botón)
- imágenes con contenido sin `alt`
- funcionalidad que no se puede usar solo con teclado
- inputs sin `label` asociado
- contraste de texto por debajo de AA
- foco no visible o removido sin reemplazo

🟡 **Amarillo — parcialmente accesible.** Lo crítico está cubierto (cumple nivel
A) pero quedan huecos de AA o de robustez. Señales típicas:
- teclado y contraste OK, pero falta ARIA en contenido dinámico (`aria-live`,
  `aria-expanded`)
- jerarquía de headings desordenada o con saltos
- sin soporte de `prefers-reduced-motion` habiendo animación
- touch targets por debajo de 44px
- errores de validación que no se anuncian a lectores de pantalla

🟢 **Verde — muy accesible.** Cumple WCAG AA de forma consistente:
- HTML semántico y landmarks
- teclado completo, sin trampas, orden lógico, foco visible
- contraste AA (4.5:1 normal, 3:1 grande)
- `label` y ARIA donde el HTML no alcanza
- preferencias del usuario respetadas (reduced-motion, color-scheme, contrast)
- verificado con automático + revisión manual

Reglas del veredicto:
- El color lo determina el **peor** hallazgo, no el promedio: un solo bloqueante
  crítico deja todo en rojo aunque el resto esté impecable. La accesibilidad se
  trata de no dejar a nadie afuera.
- AAA es aspiracional; no lo exijas para dar verde, salvo que el proyecto lo pida.

## Al terminar, reportá

1. **El color del semáforo** (🔴/🟡/🟢) y qué hallazgo lo determinó.
2. Los problemas encontrados, ordenados por severidad.
3. Los pasos concretos para subir un escalón (rojo→amarillo→verde).

> Nota de sistema: los básicos visuales de a11y (contraste, foco) también los
> menciona `ui-visual-craft`, pero **esta skill es la fuente de verdad**. Para la
> técnica específica de Angular (host bindings con `role`/`aria-*`), combinala con
> `angular-modern`.