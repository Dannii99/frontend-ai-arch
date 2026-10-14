---
name: tweak
description: "Nivel 0 — ajuste visual o cosmético (estilos, responsive, copy, rename) sin lógica, estado ni contratos. Inline en la sesión principal: sin subagentes, sin OpenSpec, sin tests nuevos. Valida con lint + build."
argument-hint: <qué ajustar y en qué archivos>
category: Workflow
tags: [workflow, tweak, ui]
---

Ajuste liviano: cambia **cómo se ve**, no **qué hace**. Es el nivel más
barato del ecosistema. Lo resolvés vos (la sesión principal), sin delegar a
subagentes.

**Input**: qué ajustar. Ejemplos: "paginación responsive bajo 768px",
"padding del header", "copy del botón de submit", "renombrar variable de
estilo".

## Pasos

### 1. Gate de alcance

Antes de tocar nada, chequeá si esto es realmente un tweak:
- ¿Toca lógica, servicios, estado (signals/store/hooks de datos), routing o
  contratos con el backend?
- ¿Agrega interacción nueva con comportamiento propio (un drawer con foco y
  cierre con Esc, un modal, un submit)?
- ¿Obliga a modificar un test existente para que pase?

**Si aplica CUALQUIERA → PARAR.** Decile al usuario: "Esto cambia
comportamiento, no solo presentación. Recomiendo `/fea:fix`."

### 2. Confirmar el alcance explícito

Dejá escrito, en una línea cada uno (inferilo del pedido; preguntá solo lo
que falte):
- **Archivos permitidos** (ej. el componente y su hoja de estilos).
- **Condición** (ej. breakpoint `< 768px`, tema oscuro, un estado).
- **Qué NO se toca** (ej. la vista desktop, la lógica, los servicios).

### 3. Implementar inline

Leé los archivos permitidos y aplicá el cambio. Cargá solo la skill que
aplica: `ui-visual-craft` para layout/visual, `motion-design-system` si hay
animación, `accessibility-a11y` si cambia el orden de foco, el contraste o
el tamaño de los touch targets. No cargues el resto del stack.

### 4. Validar

Correr los scripts `lint` y `build` del `package.json`. Si falla, corregí y
re-corré (máx. 3 intentos; si se agotan, parar y mostrar el error).

**No** corras la suite de tests ni los E2E: un tweak no cambia
comportamiento. Si sospechás que sí lo cambia, volvé al paso 1.

### 5. Chequeo contra el spec

Buscá en `openspec/specs/` el componente o la página que tocaste (grep por
nombre). Si algún `#### Scenario:` describe algo que este cambio contradice
→ avisar y recomendar `/fea:fix`, que sí sincroniza el spec. Si no hay spec
o no lo contradice, seguí.

### 6. Listo

```
## Tweak aplicado

**Archivos modificados:** <lista>
**Alcance:** <condición> — sin cambios en <lo que no se tocó>
**Lint/build:** en verde
**Spec:** sin conflicto | ⚠️ contradice <REQ-NNN> → /fea:fix
```

Si salió una **decisión de diseño reutilizable** (ej. "filtros en mobile =
drawer", "paginación compacta bajo 768px"), guardala en Engram. Si fue un
ajuste puntual, no guardes nada.

## Reglas clave

- **Sin subagentes** — ni `code-writer` ni `code-auditor`. El costo de un
  subagente arrancando en frío no se justifica para un ajuste visual.
- **Sin OpenSpec, sin tests nuevos, sin E2E.**
- **No leas memoria al empezar** — un tweak no depende de decisiones
  pasadas. Solo guardás si sale una decisión reutilizable.
- **El gate de alcance es obligatorio** — ante la duda, subí a `/fea:fix`.
- **Revisión visual a cargo del usuario** — sugerí los viewports a mirar
  (ej. 375px, 768px, desktop). `/fea:review` es opcional y solo si el
  proyecto tiene el MCP de Playwright.
- **Usá los scripts del `package.json`** — nunca hardcodees un toolchain.
