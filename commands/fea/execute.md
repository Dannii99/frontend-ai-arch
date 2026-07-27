---
name: execute
description: "Implementa las tasks de un change de OpenSpec. Orquesta code-writer y code-auditor desde la sesión principal, sin anidar agentes."
category: Workflow
tags: [workflow, execution]
---

Implementa las tasks de un change de OpenSpec. Vos (la sesión principal)
orquestás todo — delegás a los agentes de uno en uno, nunca anidás llamadas a
agentes.

**Input**: opcionalmente un nombre de change (ej. `/fea:execute add-auth`).
Si se omite, inferilo del contexto; si es ambiguo, preguntá con las opciones
disponibles.

## 0. Detectar el stack y los comandos de validación

Leer `package.json`: framework (Angular/Next/React) y los scripts disponibles
(`lint`, `test`, `build`). Usá esos scripts directo — nunca hardcodees un
toolchain distinto al que declara el proyecto.

## Pasos

1. **Seleccionar el change.** Si viene nombrado, usalo. Si no, inferilo, o
   auto-seleccioná si hay un solo change activo, o preguntá con
   `openspec list --json`. Anunciar: "Usando change: <nombre>".

2. **Verificar precondiciones**

   ```bash
   openspec status --change "<nombre>" --json
   ```
   - `state: "blocked"` (faltan artifacts) → sugerir `/fea:plan`.
   - `state: "all_done"` → sugerir `/fea:archive`.
   - Los tests NO son requisito para arrancar. Se escriben después de
     implementar, vía `/fea:test`. No bloquear por falta de tests.

3. **Cargar contexto**

   ```bash
   openspec instructions apply --change "<nombre>" --json
   ```
   Leer todos los `contextFiles`, `CLAUDE.md`/`AGENTS.md`, el archivo de
   tasks, y `design.md` (incluyendo la sección de contracts si existe).

4. **Snapshot de tests existentes (si hay)**

   Si ya hay tests en el proyecto, correr el script `test` y registrar cuáles
   pasan — ese es el **baseline** (un test que pasaba antes y falla después es
   una **regresión**: se arregla el código, no el test). Si todavía no hay
   tests, saltear el snapshot — los tests de este change se escriben después,
   vía `/fea:test`.

5. **Loop de implementación — por cada task pendiente** (`- [ ]`, en orden de
   dependencia):

   a. **Anunciar:** `## Task N/M: <descripción>`

   b. **Delegar a `code-writer`** con: descripción de la task, el WHEN/THEN
      del spec relevante, decisiones de diseño (+ contracts si existen),
      archivos a tocar, patrones existentes a reusar. Esperar su resumen.

   c. **Delegar a `code-auditor`** con los archivos que tocó el writer.
      Esperar su reporte.

   d. **Manejar el resultado del audit:**
      - Aprobado → task lista, siguiente.
      - Problemas críticos → `code-writer` corrige con el reporte → re-audit.
        Máx. 3 reintentos por task; si se agotan, parar y mostrarle al usuario.

   e. **Anunciar:** `✓ Task N/M completa (implementada + auditada)`

6. **Fase de validación — inline, sin agente separado.** Correr los scripts
   `lint`/`build` del proyecto siempre, y `test` solo si ya existen tests.
   Marcar las tasks como `[x]` si todo pasa, o armar un reporte de falla SIN
   arreglar nada.

   **Manejar el resultado:**
   - Éxito → paso 7.
   - Falla → analizar contra el baseline: un test que pasaba y ahora falla es
     **REGRESIÓN** (decirle a `code-writer` que arregle el código fuente, no
     el test); un lint que falla se arregla en el código. Delegar
     `code-writer` → `code-auditor` → re-validar. Máx. 5 intentos; si se
     agotan, parar y mostrar el reporte completo.

7. **Mostrar el resultado final**

   **En éxito:**
   ```
   ## Ejecución completa

   **Change:** <nombre>
   **Progreso:** N/N tasks completas

   **Tests:** <pasando | ninguno todavía>
   **Quality gate:** limpio
   **Audit:** todo aprobado

   Archivos modificados: <lista>

   Siguiente paso: /fea:test para generar y correr tests contra este código
   (opcional), después /fea:archive para cerrar el change.
   ```

   **En pausa (fin de sesión):** mostrar completadas vs. pendientes y
   "Reanudá con: /fea:execute <nombre>".

## Reglas clave

- **VOS orquestás todo** — delegás a los agentes de uno en uno.
- **NUNCA dejes que un agente llame a otro agente** — los subagentes no
  pueden generar sub-agentes.
- **Todo cambio de `code-writer` se audita** — sin excepciones, incluidos los
  arreglos de tests que fallan.
- **Protección de baseline** — los tests preexistentes son sagrados; si
  fallan después del cambio, se arregla el código.
- **Usá los scripts del `package.json` del proyecto** — nunca hardcodees un
  toolchain.
- **Máximo de reintentos** — 3 por task en el loop de audit, 5 en el loop de
  validación. Después, parar y reportar.
- **NUNCA loopear indefinidamente** — reportar y que decida el usuario.
