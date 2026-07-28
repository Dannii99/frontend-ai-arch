---
name: audit
description: "Corre una auditoría de calidad de código sobre archivos fuente puntuales. Delega al agente code-auditor."
argument-hint: <archivo_o_carpeta>
category: Workflow
tags: [workflow, audit]
---

Corre una auditoría de calidad de código sobre los archivos indicados.

## Uso

```
/fea:audit <archivo_o_carpeta>
```

## Comportamiento

1. Si se pasa un archivo, auditar solo ese archivo.
2. Si se pasa una carpeta, auditar todos los archivos fuente dentro (mismas
   extensiones que ya usa el proyecto — `.ts`/`.tsx` para Angular/React/Next).
3. Si no se pasa ningún argumento, auditar los archivos modificados en git:
   `git diff --name-only --diff-filter=ACMR HEAD`.

## Ejecución

Delegar al agente `code-auditor` con los archivos identificados. El agente
detecta el framework del proyecto, cita las skills correspondientes
(`frontend-clean-code`, `frontend-design-principles`, `accessibility-a11y`,
`frontend-security`, y la skill de arquitectura del framework detectado),
corre el lint del proyecto, y produce un reporte estructurado con veredicto.

**Instrucción:** invocar al agente `code-auditor` con los archivos que indicó
el usuario. Si no indicó ninguno, correr primero
`git diff --name-only --diff-filter=ACMR HEAD`, y pasarle esos archivos al
agente.
