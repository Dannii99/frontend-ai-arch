---
name: plan
description: "Crea un change de OpenSpec con todos los artifacts de planificación (proposal, specs, design, contracts opcional, tasks). No genera tests — eso llega después de implementar, vía /fea:test."
category: Workflow
tags: [workflow, planning, openspec]
---

Crea un change y genera todos los artifacts de planificación en un paso.

Artifacts:
- `proposal.md` (qué y por qué)
- `specs/` (requirements con escenarios WHEN/THEN)
- `design.md` (cómo)
- `contracts.md` (interfaces compartidas — solo si el schema de OpenSpec del
  proyecto define este artifact y la feature toca varios módulos que
  interactúan)
- `tasks.md` (pasos de implementación)

Los tests NO se crean aquí — se escriben después de implementar, contra el
código real, vía `/fea:test`.

**Input**: un nombre de change (kebab-case) o una descripción de qué construir.

## 0. Detectar el stack

Leer `package.json` del proyecto: `@angular/core` → Angular; `next` →
Next.js; `react` (sin `next`) → React puro. Con eso ya sabés qué skill de
arquitectura citar más adelante (`angular-architecture` /
`react-architecture` / `next-architecture`) — no hace falta ninguna capa de
configuración adicional.

**Si no hay `package.json`, o hay uno pero no matchea ninguno de los tres**:
no asumas un framework — preguntá cuál es el stack (o confirmá si el
proyecto todavía no se scaffoldeó). Un `/fea:plan` corriendo contra un
proyecto sin stack decidido normalmente significa que falta el paso de
`frontend-architect` antes de esto.

## Pasos

1. **Si no hay input, preguntar qué construir** (AskUserQuestion, abierta).
   Derivar un nombre kebab-case. No avanzar sin entender el objetivo.

2. **Leer contexto del proyecto**
   - `CLAUDE.md` / `AGENTS.md` (arquitectura y reglas del proyecto)
   - `openspec/specs/` (specs canónicos existentes)
   - la skill de arquitectura del stack detectado (folder structure, límite
     de escalado de estado, política de testing)

3. **Crear el change** — `openspec new change "<nombre>"`.

4. **Obtener el orden de construcción** — `openspec status --change "<nombre>" --json`
   (parsear `applyRequires` + `artifacts`).

5. **Crear los artifacts en orden de dependencia**, usando
   `openspec instructions <artifact-id> --change "<nombre>" --json` para cada uno:
   - Leer primero los archivos de las dependencias ya completadas.
   - Usar el `template` devuelto como estructura; aplicar `context`/`rules`
     como restricciones (no copiarlos textualmente al archivo).
   - Re-correr `openspec status` después de cada uno; parar cuando todos los
     artifacts de `applyRequires` estén `done`.

   **Contracts (opcional):** intentar
   `openspec instructions contracts --change "<nombre>" --json`. Si el schema
   del proyecto lo define y la feature abarca varios módulos que interactúan
   (componente + store + servicio, front + back, varios endpoints), crear
   este artifact. Si el schema no lo define, o el módulo es aislado, omitir
   sin error — no es requisito para aplicar el change.

   Los tests no se generan aquí — ver `/fea:test`.

6. **Mostrar estado final** — `openspec status --change "<nombre>"`.

## Output

Resumir: nombre y ubicación del change, artifacts creados. Luego: "Revisá los
artifacts. Cuando estén aprobados, corré `/fea:execute` para implementar
(después `/fea:test` si querés tests)."

**PARAR AQUÍ.** No implementar. Esperar a que el usuario revise y apruebe.

## Guardrails
- Crear TODOS los artifacts que requiera `apply.requires` del schema.
- Leer siempre los artifacts de dependencia antes de crear uno nuevo.
- Preferir decisiones razonables antes que bloquear; preguntar solo si el
  contexto es críticamente ambiguo.
- Si el change ya existe, preguntar si continuarlo o crear uno nuevo.
- `context`/`rules` de OpenSpec son restricciones para VOS, no contenido para
  copiar en los archivos.
