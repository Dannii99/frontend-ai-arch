# AGENTS.md

Archivo canónico de instrucciones para cualquier agente de IA que trabaje en
este proyecto. Es el estándar cross-tool (lo leen Codex, Cursor, OpenCode,
Copilot y más de forma nativa; Claude Code lo importa vía `CLAUDE.md`).

> Este archivo es la fuente única de verdad. No dupliques instrucciones en
> archivos por-agente: apuntalos a este.

## Cómo se trabaja aquí

**Spec-Driven Development (OpenSpec).** Antes de escribir código, se acuerda el
spec. Cambio no trivial: `/fea:plan <nombre-del-cambio>` genera
`openspec/changes/<nombre-del-cambio>/` con `proposal.md`, `design.md`,
`tasks.md` y el delta de `spec.md` — el código se implementa contra ese spec,
no contra un prompt suelto. Implementación: `/fea:execute` (delega por task a
un loop `code-writer` → `code-auditor`). Antes de cerrar: `/fea:verify`. Al
cerrar: `/fea:archive`. Estos comandos viven en `commands/fea/` y se instalan
globales junto con las skills — son nativos de Claude Code; si tu agente no
los soporta, usá el CLI directo (`openspec new change <nombre-del-cambio>`,
`openspec instructions <artifact> --json`, `openspec archive
<nombre-del-cambio> -y`). Cambios chicos: implementar directo, sin propuesta.

**Contexto de producto antes que arquitectura.** Si existe
`docs/project-context.md` (objetivo, MVP, reglas de negocio en lenguaje
humano), leerlo antes de decidir arquitectura o implementar. `docs/` (producto)
y `openspec/` (specs técnicas) son carpetas distintas, con dueños distintos —
no se mezclan.

**Memoria (Engram, vía MCP).** Las decisiones, bugs resueltos y convenciones se
guardan en memoria persistente. Al empezar una sesión, recuperá el contexto del
proyecto antes de actuar. Guardá lo significativo al terminar trabajo relevante.

**Skills.** Aplicá las skills disponibles según la tarea. No reinventes lo que
ya está encapsulado en una skill.

## Estándares no negociables (frontend)

- **Accesibilidad (WCAG):** ARIA correcto, teclado, foco visible, contraste.
- **Testing:** cobertura significativa; los tests fallan por la razón correcta.
- **Performance:** respetar el budget de bundle y métricas de carga.
- **Deploy safety:** nada de dev (URLs locales, endpoints de staging, tokens,
  valores hardcodeados) se filtra al build de producción. Ver la sección de
  deploy safety dentro de la skill de arquitectura del framework
  correspondiente (p. ej. `angular-architecture`).

## Reglas del proyecto (completar por proyecto)

- Stack: <!-- ej: Angular 18, TypeScript 5.x -->
- Comando de build: <!-- ej: ng build --configuration production -->
- Comando de test: <!-- ej: npm test -->
- Convenciones específicas: <!-- lo puntual de este cliente -->
