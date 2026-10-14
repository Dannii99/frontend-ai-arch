---
name: fix
description: "Nivel 1 — fix rápido para bugs y mejoras chicas con lógica. Evalúa complejidad, implementa inline, audita una vez con code-auditor, valida con los tests relacionados y sincroniza el spec canónico si cambió un comportamiento. Sin change de OpenSpec — la investigación ya debería estar hecha vía /fea:explore."
argument-hint: <descripción del bug o tarea chica>
category: Workflow
tags: [workflow, fix, bugfix]
---

Fix rápido: evaluar, implementar, validar, sincronizar. La investigación ya
debería estar hecha vía `/fea:explore`.

**Input**: descripción del bug o de qué arreglar. Usa el contexto de la
conversación si venís de un `/fea:explore` previo.

## Pasos

### 1. Evaluar complejidad

Antes de tocar código, evaluá si esto es realmente un fix:
- ¿Hace falta modificar más de 3 archivos?
- ¿Hay cambios de arquitectura (módulos nuevos, interfaces cambiadas,
  dependencias nuevas)?
- ¿Se necesitan escenarios de test nuevos (no solo que pasen los existentes)?

**Si aplica CUALQUIERA → PARAR.** Decile al usuario: "Esto es más grande que
un fix rápido. Recomiendo: `/fea:explore` → `/fea:plan` → `/fea:execute` →
`/fea:archive`."

**Al revés también:** si el cambio es solo de presentación (estilos,
responsive, copy) y no toca lógica ni estado, sugerí `/fea:tweak`, que es más
barato. No bloquees: sugerís y el usuario decide.

### 2. Recuperar contexto (una vez)

Si no venís de un `/fea:explore` en esta misma sesión, hacé **una** búsqueda
en Engram con los términos de la tarea (componente, módulo, síntoma). No
hagas búsquedas genéricas del proyecto entero.

### 3. Snapshot del baseline de tests (solo los relacionados)

Identificá los tests relacionados con los archivos a tocar: los colocados
junto al source (`*.spec.ts`, `*.test.tsx`) y los que importan esos
archivos. Corrélos con el script `test` del proyecto filtrando por path o
patrón (la forma de filtrar depende del runner del proyecto). Registrá cuáles
pasan y cuáles ya fallaban: ese es el **baseline**.

Si el runner no permite filtrar, corré la suite completa.

### 4. Implementar inline

Implementá vos, en la sesión principal: ya tenés el contexto de la
conversación y de `/fea:explore`, y un subagente tendría que reconstruirlo
desde cero. Leé primero los archivos a modificar y seguí sus patrones.

### 5. Auditar: delegar a `code-auditor` (una pasada)

Pasale al auditor los archivos que modificaste.
- **Aprobado** → seguir.
- **Problemas críticos** → corregí y re-auditá. Máx. 3 reintentos; si se
  agotan, parar y mostrarle al usuario.

### 6. Validar

Re-correr los mismos tests relacionados del paso 3 y el `lint` del proyecto.
**Comparar contra el baseline:**
- Ya fallaba antes → ignorar (no es nuestro problema).
- Pasaba antes y ahora falla → **regresión**: arreglar el código fuente, NO
  el test. Re-auditar, re-validar. Máx. 3 reintentos; si se agotan, parar.

### 7. Sincronizar el spec canónico

Buscá en `openspec/specs/` el requirement que describe el comportamiento que
tocaste (grep por componente, módulo o término del dominio).

- **El comportamiento cambió y hay un requirement que lo describe** → editá
  ese requirement o su `#### Scenario:` **en el lugar**, manteniendo su
  `REQ-NNN`. Si el test `[REQ-NNN]` existente ya no refleja el nuevo
  comportamiento, ajustalo (este es el único caso en que se toca un test, y
  es porque cambió el requirement, no para tapar una regresión).
- **Era un bug** (el código no cumplía el spec y ahora sí) → el spec ya
  estaba bien; no lo toques.
- **No hay spec que lo describa** → no inventes uno.

### 8. Listo

```
## Fix aplicado

**Archivos modificados:** <lista>
**Tests relacionados:** en verde (sin regresiones)
**Quality gate:** limpio
**Audit:** aprobado
**Spec:** sin cambios | actualizado <REQ-NNN> en openspec/specs/<ruta>
```

Si la causa raíz no era obvia (un efecto colateral, una trampa del framework,
un supuesto falso del código), guardala en Engram en 2–3 líneas. Si era un
bug trivial, no guardes nada.

## Reglas clave

- **Sin change de OpenSpec** — pero sí se sincroniza el spec canónico si
  cambió un comportamiento (paso 7). Así el spec no se desactualiza por
  acumulación de fixes chicos.
- **La investigación pasa en `/fea:explore`** — este comando solo aplica la
  corrección.
- **El gate de complejidad es obligatorio** — si es más grande, redirigir al
  flujo completo.
- **Protección de baseline** — nunca culpar a un test que ya fallaba antes.
- **Todo cambio se audita** — una pasada de `code-auditor`, sin excepciones.
- **Usá los scripts del `package.json`** — nunca hardcodees un toolchain.
- **NUNCA loopear indefinidamente** — máx. 3 reintentos, después reportar.
