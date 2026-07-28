---
name: verify
description: "Verifica un change implementado contra sus artifacts, antes de archivar. Análisis estático en tres dimensiones (completeness, correctness, coherence) + code-auditor + lint + contracts. Produce un reporte consolidado con veredicto. No ejecuta la app ni APIs."
category: Workflow
tags: [workflow, verify]
---

Verifica que un change implementado coincide con sus artifacts (specs, tasks,
design, contracts), **antes de archivar**. Esto es **análisis estático** — leés
artifacts y código y razonás sobre ellos. NO corrés la app, ni llamás APIs, ni
ejecutás curls. No arreglás código — reportás.

**Input**: opcionalmente un nombre de change (ej. `/fea:verify add-auth`). Si
se omite, inferilo del contexto; si es ambiguo, preguntá con las opciones
disponibles.

## Pasos

1. **Seleccionar el change.** Igual criterio que en `/fea:execute`. Anunciar:
   "Verificando change: <nombre>".

2. **Cargar artifacts.**
   ```bash
   openspec instructions apply --change "<nombre>" --json
   ```
   Leer todos los `contextFiles`: los specs (con sus `### Requirement:` y
   `#### Scenario:` WHEN/THEN), `tasks.md`, `design.md`, y `contracts.md` si
   existe.

3. **Dimensión 1 — Completeness** (¿está todo hecho?)
   - **Tasks**: contar `- [x]` vs `- [ ]` en `tasks.md`. Cada task
     incompleta → **CRÍTICO** ("completar task: <desc>" o marcarla si ya
     está implementada).
   - **Cobertura del spec**: por cada `### Requirement:` de los specs del
     change, buscar en el código evidencia de que existe. Requirement sin
     implementar → **CRÍTICO**.

4. **Dimensión 2 — Correctness** (¿está bien hecho?)
   - **Mapeo requirement → código**: para cada requirement, ubicar el
     archivo/líneas que lo implementan. Si la implementación parece
     divergir de la intención → **ADVERTENCIA** ("revisar <archivo>:<líneas>
     vs. requirement X").
   - **Cobertura de escenarios**: por cada `#### Scenario:` (WHEN/THEN),
     chequear que la condición esté manejada en el código y (si hay tests)
     cubierta por uno. Escenario sin cubrir → **ADVERTENCIA**.

5. **Dimensión 3 — Coherence** (¿es consistente?)
   - **Adherencia al diseño**: si `design.md` tiene decisiones clave,
     verificar que el código las siga. Contradicción → **ADVERTENCIA**. Sin
     `design.md` → anotar "salteado, no hay design.md".
   - **Consistencia de patrones**: código nuevo vs. patrones del proyecto
     (naming, estructura). Desviación significativa → **SUGERENCIA**.

6. **Calidad de código — delegar a `code-auditor`.** Pasarle los archivos que
   el change creó/modificó. Los críticos que reporte se suman como CRÍTICOS
   acá.

7. **Quality gate.** Correr el script `lint` del proyecto. Violaciones →
   CRÍTICO (el gate tiene que estar limpio para archivar).

8. **Contracts** (solo si el change tiene el artifact `contracts`). Chequear
   las interfaces implementadas (forma de las respuestas, auth, modelo de
   datos) contra `contracts.md`. Violación de un contract declarado →
   **CRÍTICO**. Sin artifact `contracts` → saltear sin error.

9. **Consolidar en UN solo reporte** con scorecard y veredicto.

## Formato del reporte

```
## Verificación: <nombre-del-change>

| Dimensión      | Resultado             |
|----------------|------------------------|
| Completeness   | X/Y tasks · N reqs     |
| Correctness    | M/N reqs mapeados      |
| Coherence      | seguido / con issues   |
| Calidad (lint) | limpio / N issues      |
| Auditor        | ✅ / N críticos        |
| Contracts      | ok / violaciones / n/a |

### 🔴 Crítico (arreglar antes de archivar)
- **[dimensión]** `archivo:línea` — <problema> → <recomendación>

### 🟡 Advertencias
- ...

### 🟢 Sugerencias
- ...

**Veredicto:** ✅ Listo para archivar (con notas) | ❌ N problema(s) crítico(s) — arreglar antes de archivar
```

## Reglas clave

- **Solo estático** — nunca llama a un endpoint desplegado ni corre curls.
- **Reporta, no arregla** — si hay críticos, el dev los arregla vía
  `/fea:execute`/`/fea:fix` y re-corre verify.
- **Sin anidar agentes** — VOS (el comando) orquestás; delegás a
  `code-auditor` una vez, directo.
- **Usá los scripts del `package.json`** — nunca hardcodees un toolchain.
- **Preferí falso negativo sobre falso positivo** — ante la duda, bajá
  SUGERENCIA < ADVERTENCIA < CRÍTICO.
- **Siguiente paso**: si ✅ → sugerir `/fea:archive`. Si ❌ → listar qué
  arreglar.
