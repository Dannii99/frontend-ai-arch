# AGENTS.md

Archivo canónico de instrucciones para cualquier agente de IA que trabaje en
este proyecto. Es el estándar cross-tool (lo leen Codex, Cursor, OpenCode,
Copilot y más de forma nativa; Claude Code lo importa vía `CLAUDE.md`).

> Este archivo es la fuente única de verdad. No dupliques instrucciones en
> archivos por-agente: apuntalos a este.

## Cómo se trabaja aquí

**Spec-Driven Development (OpenSpec).** Antes de escribir código, se acuerda el
spec. Cada cambio no trivial vive en `openspec/` con su propuesta, spec, diseño
y tareas. El código se implementa contra el spec acordado, no contra un prompt
suelto. Cambios chicos: revisar, implementar, archivar, repetir.

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
  valores hardcodeados) se filtra al build de producción. Ver la skill
  `angular-deploy-safety`.

## Reglas del proyecto (completar por proyecto)

- Stack: <!-- ej: Angular 18, TypeScript 5.x -->
- Comando de build: <!-- ej: ng build --configuration production -->
- Comando de test: <!-- ej: npm test -->
- Convenciones específicas: <!-- lo puntual de este cliente -->
