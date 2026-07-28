---
name: review
description: "Revisión en vivo de un change corriendo en un browser real, vía Playwright MCP. Complementa a /fea:verify (que es solo estático) con lo que un análisis de código no puede ver: accesibilidad real del DOM, consistencia visual, consola del browser. Sugerido (no obligatorio) antes de /fea:archive en changes con superficie de UI."
category: Workflow
tags: [workflow, review, playwright]
---

Revisa un change **corriendo de verdad**, en un browser real — a diferencia
de `/fea:verify`, que es análisis estático únicamente (nunca abre un browser
ni llama un endpoint). Este comando es el paso que cierra ese hueco.

**Input**: opcionalmente un nombre de change (ej. `/fea:review add-auth`). Si
se omite, inferilo del contexto; si es ambiguo, preguntá con las opciones
disponibles.

## Pasos

1. **Seleccionar el change.** Igual criterio que `/fea:verify`. Anunciar:
   "Revisión en vivo: <nombre>".

2. **Chequear que el MCP de Playwright esté disponible.** Si las
   herramientas `browser_*` no están accesibles en esta sesión, PARAR y
   avisar: "Playwright MCP no está conectado. Corré `install.sh` de nuevo, o
   registralo manualmente: `claude mcp add playwright -- npx
   @playwright/mcp@latest`." No intentes simular una revisión sin el MCP
   real.

3. **Confirmar que la app está corriendo.** Preguntar o inferir la
   URL/puerto (ej. `npm run dev` en `localhost:3000`). Si no responde, PARAR
   — no hay revisión en vivo sin app viva.

4. **¿El change tiene superficie de UI observable?** Leer los specs del
   change (`openspec/changes/<nombre>/specs/`). Si ningún escenario es
   UI-observable (ej. es un cambio de API pura, un job en background), avisar
   que este comando no aplica y sugerir seguir directo a `/fea:archive`.

5. **Delegar en el agente `visual-reviewer`**, pasándole el nombre del change
   y la URL/puerto confirmados. No repitas su mecanismo acá — el comando
   orquesta, el agente revisa.

6. **Mostrar el reporte** que devuelve `visual-reviewer` (formato
   Crítico/Advertencia/Sugerencia + veredicto).

7. **Siguiente paso:**
   - ✅ Aprobado → sugerir `/fea:archive <nombre>`.
   - ❌ Con críticos → listar qué arreglar vía `/fea:execute`/`/fea:fix` y
     re-correr `/fea:review` después.

## Guardrails

- No es obligatorio — es el mismo criterio que `/fea:verify`: sugerido, no
  bloqueante, salvo que el usuario pida que sí bloquee.
- Nunca reemplaza `/fea:verify` ni `code-auditor` — es el complemento de
  runtime/visual, no el chequeo de código ni de artifacts.
- Sin anidar agentes — el comando delega en `visual-reviewer` una vez,
  directo.
- Si el proyecto instaló la skill `playwright-visual-review` (`--with`), el
  agente la usa como guía extendida; si no está instalada, igual puede
  operar el MCP con el criterio base de las skills core de UI/a11y.
- No genera archivos de test — eso es `/fea:test` (vía `test-generator`),
  para los escenarios que la política de testing marque como e2e.
