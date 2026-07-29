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
- **Seguridad:** sin XSS, sin inyección, CSRF cubierto, validación de input
  siempre revalidada del lado server, secrets fuera del cliente. Ver
  `frontend-security` (core) y la sección "Seguridad" de la skill de
  arquitectura del framework correspondiente. Distinto de deploy safety
  (abajo): esto es runtime de la aplicación, no build.
- **Deploy safety:** nada de dev (URLs locales, endpoints de staging, tokens,
  valores hardcodeados) se filtra al build de producción. Ver la sección de
  deploy safety dentro de la skill de arquitectura del framework
  correspondiente (p. ej. `angular-architecture`).

## Precedencia

Ante un conflicto entre fuentes de contexto, este es el orden (de mayor a
menor autoridad):

1. **Reglas del proyecto** (abajo, en este mismo archivo) — lo que el
   cliente/equipo pidió explícitamente para ESTE proyecto.
2. **`docs/project-context.md`** — objetivo, MVP y reglas de negocio del
   producto, si existe.
3. **`openspec/specs/`** — specs técnicos canónicos ya aprobados.
4. **Skill de arquitectura del framework** (`angular-architecture` /
   `react-architecture` / `next-architecture`) — el criterio de casa para
   ese stack.
5. **Skills core** (`frontend-clean-code`, `frontend-design-principles`,
   `frontend-security`, etc.) — principios agnósticos de framework.

Ante ambigüedad entre dos fuentes del mismo nivel, preferir la más
específica a este proyecto sobre la más genérica.

Este bloque viene de **frontend-ai-arch (Wordflow)**, un ecosistema
portable de skills/agentes/comandos instalado sobre este proyecto (no es
propio de este proyecto). Para reinstalar o actualizar a una versión más
nueva, correr de nuevo `<ruta-al-repo-de-frontend-ai-arch>/install.sh
--project <ruta-a-este-proyecto>` — mismo comando que la instalación
original (ver `.fea/manifest.json`, si existe, para el commit exacto
instalado).

## Reglas del proyecto (completar por proyecto)

- Stack: <!-- TODO: completar — ej: Angular 18, TypeScript 5.x -->
- Comando de build: <!-- TODO: completar — ej: ng build --configuration production -->
- Comando de test: <!-- TODO: completar — ej: npm test -->
- Convenciones específicas: <!-- TODO: completar — lo puntual de este cliente -->

### Excepciones a los estándares

Documentá acá cualquier desvío justificado de "Estándares no negociables"
(arriba) — alcance exacto y motivo. Si no hay excepciones, dejá esta
sección con el placeholder.

- <!-- ej: excepción de contraste WCAG AA en el ícono de marca del header,
  motivo: restricción de branding aprobada por diseño — alcance: solo ese
  ícono, no aplica al resto de la UI -->
