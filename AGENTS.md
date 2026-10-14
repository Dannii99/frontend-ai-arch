# AGENTS.md

Archivo canónico de instrucciones para cualquier agente de IA que trabaje en
este proyecto. Es el estándar cross-tool (lo leen Codex, Cursor, OpenCode,
Copilot y más de forma nativa; Claude Code lo importa vía `CLAUDE.md`).

> Este archivo es la fuente única de verdad. No dupliques instrucciones en
> archivos por-agente: apuntalos a este.

> **Qué podés tocar acá:** "Cómo se trabaja aquí", "Estándares no
> negociables" y "Precedencia" son el núcleo del ecosistema — se
> regeneran completos en cada `install.sh` (nunca los edites a mano, se
> pierde en el próximo reinstall). Lo pensado para completar a mano es
> "Reglas del proyecto" de abajo (stack, comandos, restricciones,
> excepciones) — eso sí se preserva entre reinstalls.

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
<nombre-del-cambio> -y`).

**Niveles de ceremonia.** No todo cambio paga el flujo completo. Regla
guía: si cambia **cómo se ve** → liviano; si cambia **qué hace o qué datos
maneja** → SDD. El usuario elige el nivel al elegir el comando; el agente
solo sugiere subir o bajar.

| Nivel | Comando | Cuándo |
|---|---|---|
| 0 Tweak | `/fea:tweak` | Estilos, responsive, copy, rename. Sin lógica, estado ni contratos. Sin subagentes, sin tests nuevos, valida con lint + build. |
| 1 Fix | `/fea:fix` | Bug acotado o mejora chica con lógica, ≤3 archivos. Una auditoría, tests relacionados, y sync del spec canónico si cambió un comportamiento. |
| 2 Feature | `/fea:plan` → `/fea:execute` → `/fea:test` → `/fea:archive` | Feature, flujo nuevo, cambio de contrato/estado/routing, cálculos o datos sensibles. |

Cada requirement de un spec declara `Verificación: test | e2e | visual`:
lo `visual` se demuestra con evidencia de revisión, no con un test.

**Contexto de producto antes que arquitectura.** Si existe
`docs/project-context.md` (objetivo, MVP, reglas de negocio en lenguaje
humano), leerlo antes de decidir arquitectura o implementar. `docs/` (producto)
y `openspec/` (specs técnicas) son carpetas distintas, con dueños distintos —
no se mezclan.

**Memoria (Engram, vía MCP).** Las decisiones, causas raíz no obvias y
convenciones se guardan en memoria persistente. Consultá memoria al empezar
solo en nivel 1–2, con los términos de la tarea (no búsquedas genéricas del
proyecto); en nivel 0 no hace falta. Guardá decisiones y causas raíz, no
narrativa de lo que hiciste. Un chat por cambio: al cerrar, lo relevante
queda en memoria y el próximo cambio arranca en una sesión limpia.

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
- **Versión del framework:** el código respeta la versión instalada en este
  proyecto (lockfile, no el rango de `package.json`) — ni APIs que todavía no
  existen en ella, ni APIs deprecadas en ella. Ver
  `framework-version-awareness` (core).

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

Ese orden gobierna **decisiones** (qué se hace y cómo se organiza). Para
**qué existe y cómo se usa** una API del framework, manda otro eje: la doc
oficial de la versión instalada en este proyecto está por encima de las
referencias locales de las skills, y ambas por encima del conocimiento
propio del modelo. Cómo resolver la versión y cuándo consultar doc viva
(MCP oficial del framework, Context7, doc web versionada): ver
`framework-version-awareness`.

Este bloque viene de **frontend-ai-arch (Wordflow)**, un ecosistema
portable de skills/agentes/comandos instalado sobre este proyecto (no es
propio de este proyecto). Para reinstalar o actualizar a una versión más
nueva, correr de nuevo `<ruta-al-repo-de-frontend-ai-arch>/install.sh
--project <ruta-a-este-proyecto>` — mismo comando que la instalación
original (ver `.fea/manifest.json`, si existe, para el commit exacto
instalado).

## Reglas del proyecto (completar por proyecto)

Constitución técnica de ESTE proyecto. La visión de producto y las reglas
de negocio viven en `docs/project-context.md` (secciones "Propuesta de
valor" / "Reglas de negocio", si ese archivo existe); los specs técnicos ya
aprobados viven en `openspec/specs/`. No dupliques ese contenido acá.

- Stack: <!-- TODO: completar — ej: Angular 18, TypeScript 5.x -->
- Comando de build: <!-- TODO: completar — ej: ng build --configuration production -->
- Comando de test: <!-- TODO: completar — ej: npm test -->
- Convenciones específicas: <!-- TODO: completar — lo puntual de este cliente -->
- Restricciones técnicas: <!-- TODO: completar — ej: debe soportar IE11, sin analytics de terceros, data residency en UE -->

### Excepciones a los estándares

Documentá acá cualquier desvío justificado de "Estándares no negociables"
(arriba) — alcance exacto y motivo. Si no hay excepciones, dejá esta
sección con el placeholder.

- <!-- ej: excepción de contraste WCAG AA en el ícono de marca del header,
  motivo: restricción de branding aprobada por diseño — alcance: solo ese
  ícono, no aplica al resto de la UI -->
