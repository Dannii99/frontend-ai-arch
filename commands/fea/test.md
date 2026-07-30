---
name: test
description: "Genera y corre tests para un change ya implementado. Corre DESPUÉS de /fea:execute, contra el código real y los escenarios WHEN/THEN del spec. Opcional: si una feature no necesita tests, simplemente no se invoca."
category: Workflow
tags: [workflow, test]
---

Genera y corre tests para un change que **ya está implementado**. Este
comando es opcional y corre después de `/fea:execute` — si una feature no
necesita tests, simplemente no lo invoques.

Por qué después de execute: los tests se escriben contra el código REAL
(firmas reales), usando el spec solo para decidir qué casos cubrir. Así se
evita la divergencia que aparece cuando el test se escribe antes de que el
código exista.

**Input**: opcionalmente un nombre de change (ej. `/fea:test add-auth`). Si
se omite, inferilo del contexto; si es ambiguo, preguntá con las opciones
disponibles.

## Pasos

1. **Seleccionar el change.** Si viene nombrado, usalo. Si no, inferilo, o
   auto-seleccioná si hay uno solo activo, o preguntá con `openspec list --json`.
   Anunciar: "Usando change: <nombre>".

2. **Confirmar que está implementado.** Leer `tasks.md` del change. Si quedan
   tasks de implementación pendientes, avisar: "Este change no está
   completamente implementado — corré `/fea:execute` primero" y preguntar si
   seguir igual.

3. **Cargar contexto para `test-generator`:**
   - Los specs del change (`openspec/changes/<nombre>/specs/`) — los
     escenarios WHEN/THEN definen los casos a cubrir.
   - Los REQ-IDs de cada `### Requirement: REQ-NNN — <nombre>` del spec —
     se usan para taggear cada test generado.
   - El código implementado — las firmas reales que los tests deben invocar.
   - La sección de testing de la skill de arquitectura del stack detectado
     (`angular-architecture` / `react-architecture` / `next-architecture`):
     ahí está definido qué siempre lleva test completo, qué smoke test, y qué
     queda para e2e.
   - La convención de ubicación de tests que ya usa el proyecto (colocados
     junto al source vs. carpeta `__tests__/` — se detecta mirando los tests
     existentes, no se asume una ruta fija).

4. **Delegar al agente `test-generator`** con el nombre del change. Lee el
   código implementado (firmas) + los specs (casos) y escribe los tests
   siguiendo la convención de ubicación detectada. Los escenarios que la
   skill de arquitectura marque como "e2e" (golden path crítico de negocio)
   los genera como `.spec.ts` de Playwright en vez de unit/integration — ver
   `playwright-visual-review` si el proyecto la instaló. No generes los
   tests vos mismo. Cada test generado lleva un prefijo literal `[REQ-NNN]`
   en su título/descripción (el ID del requirement que cubre) — agnóstico
   de framework de testing, para poder grepearlo en el output del test
   runner sin depender de la ubicación del archivo.

5. **Correr los tests** con el script `test` del `package.json`. Si
   `test-generator` generó `.spec.ts` de Playwright, correrlos aparte con
   `npx playwright test` (o el script `test:e2e` si el proyecto ya lo
   define) — no son parte del mismo runner que unit/integration. Capturar
   pasados/fallados de ambos.

6. **Reportar:**
   - **Todo pasa** → listo; sugerir `/fea:archive`.
   - **Hay fallas** → reportar cada test fallado + causa probable. Una falla
     acá es un **defecto real** (el test vino del spec, las firmas vinieron
     del código), no divergencia de firmas. Decidir con el usuario:
     - El código está mal → arreglar vía `/fea:fix` o re-correr `/fea:execute`
       para la task afectada.
     - El test generado está mal → decirlo explícitamente y regenerar ese
       test.

   No reescribas tests en silencio para que pasen, y no modifiques código de
   aplicación vos mismo — reportá y que la orquestación decida.

## Output

```
## Tests: <nombre-del-change>

Generados: N tests
Resultado: X pasaron, Y fallaron
Escenarios del spec cubiertos: M/M

<si hay fallas: lista con causa probable + acción recomendada>
<si todo pasa: "Listo para archivar: /fea:archive">
```

## Reglas clave

- Corre DESPUÉS de la implementación — nunca inventa firmas; las lee del
  código real.
- Los casos vienen del WHEN/THEN del spec; las firmas vienen del código.
- Opcional — no invocarlo es una decisión válida para una feature.
- Usa el script `test` del `package.json` — nunca hardcodea un toolchain.
- Delega la generación a `test-generator`; nunca anida agentes.
