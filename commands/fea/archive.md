---
name: archive
description: "Archiva un change completado — verifica el quality gate y sincroniza los delta specs. Agnóstico de stack (Angular/React/Next)."
category: Workflow
tags: [workflow, archive]
---

Archiva un change completado. Verifica el quality gate antes de archivar.

**Input**: opcionalmente un nombre de change (ej. `/fea:archive add-auth`).
Si se omite, inferilo del contexto; si es ambiguo, DEBÉS preguntar con las
opciones disponibles.

## Pasos

1. **Si no viene el nombre, preguntar cuál seleccionar**

   Correr `openspec list --json`. Usar AskUserQuestion para que el usuario
   elija. Mostrar solo changes activos. No auto-seleccionar.

2. **Verificar el quality gate**

   - Correr el script `lint` del `package.json`. Si falla → PARAR: "Quality
     gate en rojo. Corré `/fea:execute` primero." (lint es el gate duro).
   - Si ya hay tests en el proyecto, correr el script `test`; si fallan →
     PARAR: "Tests en rojo. Arreglalos o re-corré `/fea:test`."
   - Si NO hay tests, no bloquear — anotar "sin tests (no se generaron)" en
     el resumen. Generarlos vía `/fea:test` es opcional.
   - **Sugerir verify (no obligatorio):** si `/fea:verify` no se corrió en
     esta sesión, sugerir "Considerá correr `/fea:verify` antes de archivar
     para chequear la implementación contra los artifacts." No bloquear por
     esto.
   - **Sugerir review (no obligatorio):** si el change tiene superficie de UI
     observable y `/fea:review` no se corrió en esta sesión, sugerir
     "Considerá correr `/fea:review` antes de archivar para revisar el
     change en un browser real (accesibilidad real del DOM, consola,
     consistencia visual) — `/fea:verify` es solo análisis estático." No
     bloquear por esto.

3. **Gate de trazabilidad (REQ-ID → test).**

   - Extraer todos los `REQ-NNN` de los specs del change
     (`openspec/changes/<nombre>/specs/`).
   - Si ningún requirement tiene REQ-ID (specs pre-convención) → saltear
     sin bloquear, anotar "sin REQ-IDs (specs pre-convención)".
   - Si hay REQ-IDs, grepear `\[REQ-NNN\]` en la suite de tests del
     proyecto. Cualquier REQ-ID del change SIN tag correspondiente →
     **PARAR**: "Trazabilidad incompleta — faltan tests para: REQ-00X,
     REQ-00Y. Corré `/fea:test` o cubrilos antes de archivar." Sin bypass
     — gate duro, igual que lint.

5. **Chequear que los artifacts estén completos** —
   `openspec status --change "<nombre>" --json`. Si algún artifact no está
   `done`, avisar y confirmar antes de seguir.

6. **Chequear que las tasks estén completas** — leer el archivo de tasks;
   contar `- [ ]` vs `- [x]`. Si quedan tasks incompletas, avisar y confirmar.

7. **Archivar vía el CLI de OpenSpec** (valida, sincroniza los delta specs a
   `openspec/specs/`, y mueve el change a `archive/`):

   ```bash
   openspec archive <nombre> --yes
   ```

   Si hay delta specs, el CLI los fusiona (ADDED/MODIFIED/REMOVED) en
   `openspec/specs/` y reporta los totales. Revisar el resumen que imprime.

8. **Mostrar resumen**

   ```
   ## Archive completo

   **Change:** <nombre>
   **Archivado en:** openspec/changes/archive/YYYY-MM-DD-<nombre>/
   **Specs:** <totales sincronizados | sin delta specs>
   **Quality gate:** lint en verde
   **Tests:** <en verde | sin tests (no se generaron)>

   Actualizá CLAUDE.md/AGENTS.md ("Reglas del proyecto") si esto cambió cómo
   funciona el proyecto.
   ```

## Guardrails
- Siempre preguntar por el change si no viene indicado.
- **Lint es el gate duro antes de archivar. Los tests se verifican solo si
  existen (sin tests no es bloqueante).**
- Preferir `openspec archive` sobre un `mv` manual — valida y sincroniza los
  specs.
- Usar los scripts del `package.json` del proyecto — nunca hardcodear un
  toolchain.
- No bloquear el archive por advertencias — informar y confirmar.
- **Nuevo gate duro (además de lint): trazabilidad REQ-ID → test.** Sin
  bypass — es una escalada deliberada respecto a los gates existentes
  (antes solo lint bloqueaba).
