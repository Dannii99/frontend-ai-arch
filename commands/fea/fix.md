---
name: fix
description: "Fix rápido para bugs y tasks chicas. Evalúa complejidad, implementa vía code-writer, audita, y valida con lint/test del proyecto. Sin artifacts de OpenSpec — la investigación ya debería estar hecha vía /fea:explore."
argument-hint: <descripción del bug o tarea chica>
category: Workflow
tags: [workflow, fix, bugfix]
---

Fix rápido — evaluar, implementar, validar. La investigación ya debería estar
hecha vía `/fea:explore`.

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

### 2. Snapshot del baseline de tests

Correr el script `test` del proyecto. Registrar qué tests pasan y cuáles ya
fallaban — ese es el **baseline**. Solo las fallas NUEVAS después del fix son
regresiones.

### 3. Implementar — delegar a `code-writer`

Pasarle a `code-writer`: qué arreglar (descripción + contexto de la
conversación), archivos a modificar, patrones existentes (leer los archivos
primero). Esperar que devuelva el resultado.

### 4. Auditar — delegar a `code-auditor`

Pasarle al auditor los archivos que modificó `code-writer`.
- **Aprobado** → seguir.
- **Problemas críticos** → `code-writer` corrige → re-audit. Máx. 3
  reintentos; si se agotan, parar y mostrarle al usuario.

### 5. Validar

Correr el script `test` y el `lint` del proyecto.
**Comparar contra el baseline:**
- Ya fallaba antes → ignorar (no es nuestro problema).
- Pasaba antes y ahora falla → **regresión**: decirle a `code-writer` "arreglá
  el código fuente, NO modifiques el test." Re-audit, re-validar. Máx. 3
  reintentos; si se agotan, parar.

### 6. Listo

```
## Fix aplicado

**Archivos modificados:** <lista>
**Tests:** en verde (sin regresiones)
**Quality gate:** limpio
**Audit:** aprobado
```

## Reglas clave

- **Sin OpenSpec, sin artifacts** — esto es un fix rápido.
- **La investigación pasa en `/fea:explore`** — este comando solo aplica la
  corrección.
- **El gate de complejidad es obligatorio** — si es más grande, redirigir al
  flujo completo.
- **Protección de baseline** — nunca culpar a un test que ya fallaba antes.
- **Todo cambio de `code-writer` se audita** — sin excepciones.
- **Usá los scripts del `package.json`** — nunca hardcodees un toolchain.
- **NUNCA loopear indefinidamente** — máx. 3 reintentos, después reportar.
