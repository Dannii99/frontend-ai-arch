---
name: playwright-visual-review
description: >-
  Revisión de UI con Playwright, en dos modalidades: (1) revisión en vivo vía
  Playwright MCP — un agente maneja un browser real contra la app corriendo,
  sin dejar archivos de test, para chequear accesibilidad real del DOM,
  consistencia visual y los WHEN/THEN observables en UI de un spec — y (2)
  generación de tests e2e persistidos en .spec.ts para los golden paths que
  la política de testing del proyecto marca como e2e. Úsala antes de
  archivar un change con superficie de UI, o cuando un escenario de spec
  necesita quedar cubierto en CI. Opt-in — no se autocarga por stack.
compatibility: agnostic
metadata:
  category: testing
  scope: domain          # situacional: no se autocarga por stack, se opta por ella
  framework: agnostic
---

# Playwright Visual Review

Esta skill no reemplaza `/fea:verify` (análisis estático de código y
artifacts) ni a `code-auditor` (calidad de código) — cubre lo que ninguno de
los dos puede: **mirar la UI corriendo de verdad**, en un browser real. Tiene
dos modalidades independientes; usá la que corresponda al momento.

## Cuándo usar

- Antes de `/fea:archive` en un change con superficie de UI observable
  (pantallas nuevas, flujos, estados visuales, animaciones) — vía
  `/fea:review`.
- Cuando un escenario del spec (`#### Scenario:` WHEN/THEN) describe un
  golden path crítico de negocio (checkout, login, un submit que no puede
  romperse) — ese escenario amerita un test e2e persistido, no solo revisión
  puntual.
- **No** la uses para lógica pura sin superficie de UI (un mapper, un cálculo,
  un endpoint sin pantalla) — eso lo cubren los tests unit/integration que ya
  genera `test-generator`.

## Precondición común a ambas modalidades

La app tiene que estar corriendo (`npm run dev`, o build + start si el
escenario depende de comportamiento solo-prod). Esta skill no levanta el
servidor — lo asume como precondición y lo indica si no detecta un puerto
respondiendo.

## Modalidad 1 — Revisión en vivo (Playwright MCP)

Usás las herramientas del servidor MCP de Playwright (`browser_navigate`,
`browser_snapshot`, `browser_click`, `browser_type`,
`browser_console_messages`, `browser_take_screenshot`, etc.) para recorrer el
flujo del change y contrastarlo contra:

1. **Accesibilidad real** — `browser_snapshot` devuelve el árbol de
   accesibilidad real del DOM (no el HTML fuente). Cruzalo con los criterios
   de `accessibility-a11y`: roles correctos, foco visible, orden de
   navegación por teclado, textos accesibles en controles interactivos. Esto
   detecta cosas que una lectura de código no puede — ej. un `div` con
   `onClick` que el árbol de accesibilidad expone sin rol de botón.
2. **Consistencia visual** — `browser_take_screenshot` en los estados
   relevantes (vacío, con datos, error, loading) y comparación de criterio
   contra `ui-visual-craft` (jerarquía, espaciado, estados).
3. **Movimiento** — si el change incluye transiciones/animaciones, observar
   que respeten `motion-design-system` (timing, no motion gratuito).
4. **Los WHEN/THEN del spec** — cada escenario UI-observable de
   `openspec/changes/<nombre>/specs/` se recorre a mano en el browser: el
   WHEN se ejecuta con las herramientas de interacción, el THEN se confirma
   con snapshot/screenshot.
5. **Consola del browser** — `browser_console_messages` para errores/warnings
   que no aparecen en ningún lint ni build.

No se genera ningún archivo. El resultado es un reporte (ver formato en
`agents/visual-reviewer.md` / `commands/fea/review.md`), igual que
`code-auditor` reporta sin modificar código.

## Modalidad 2 — E2E persistido (`.spec.ts`)

No todo escenario necesita un test e2e — la política de testing de
`react-architecture` / `angular-architecture` ya define el criterio ("E2E
(Playwright) solo en golden paths de negocio críticos"); esta skill no
inventa uno nuevo, lo ejecuta.

1. Confirmar que el escenario es un golden path crítico (checkout, login, un
   submit irreversible) — si no lo es, no generar el spec; un smoke test o
   unit test ya alcanza (ver la skill de arquitectura del framework).
2. Si el proyecto target todavía no tiene Playwright como test runner
   (`@playwright/test` en `devDependencies` + `playwright.config.ts`), es
   responsabilidad del proyecto target agregarlo en ese momento — **esta
   skill no le agrega Playwright como dependencia a este ecosistema ni lo
   asume preinstalado**; si falta, indicarlo explícitamente en el reporte en
   vez de asumir que existe.
3. Escribir el `.spec.ts` en la convención de ubicación de e2e que ya use el
   proyecto (o `e2e/`/`tests/e2e/` si es la primera vez), con:
   - Selectores por rol/texto (`page.getByRole`, `getByText`) — nunca por
     clase CSS ni estructura del DOM, mismo criterio anti-frágil que
     `react-architecture` fija para RTL.
   - Un test por escenario del spec, nombrado con la descripción del
     escenario.
   - Setup/teardown mínimo — no dupliques fixtures que ya existan en el
     proyecto.
4. Correr con `npx playwright test` (o el script `test:e2e` si el proyecto ya
   lo define) y reportar pasado/fallado.

## Relación con otras skills y agentes

- `accessibility-a11y`, `ui-visual-craft`, `motion-design-system` — los
  criterios de juicio que esta skill aplica en vivo; no los reinventa.
- `react-architecture` / `angular-architecture` — dueñas de la política de
  "qué amerita e2e"; esta skill ejecuta ese criterio, no lo redefine.
- `code-auditor` — calidad de código estático; esta skill es el complemento
  de runtime/visual, no un sustituto.
- `test-generator` — sigue generando unit/integration; cuando un escenario
  cae en la categoría e2e, delega esa parte en esta skill (ver Modalidad 2).

## Al terminar, reportá

1. Qué modalidad aplicaste (revisión en vivo, e2e persistido, o ambas).
2. Si fue revisión en vivo: hallazgos por severidad (Crítico/Advertencia/
   Sugerencia), igual formato que `code-auditor`.
3. Si fue e2e persistido: qué archivos de test se crearon, qué escenarios
   cubren, y si el proyecto necesitó agregar Playwright como dependencia por
   primera vez.
4. Qué quedó sin cubrir y por qué (ej. dependencia externa no simulable en
   browser, feature detrás de un flag).
