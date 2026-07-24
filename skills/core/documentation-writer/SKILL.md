---
name: documentation-writer
description: >-
  Escribe documentación técnica siguiendo el framework Diátaxis (tutorial,
  how-to, referencia, explicación). Úsala cuando te pidan crear o revisar
  documentación de un proyecto — README, guías, docs de API — y haga falta
  decidir qué tipo de documento es el correcto para el objetivo del lector, no
  solo redactarlo. Agnóstica de framework y de stack.
compatibility: agnostic
metadata:
  category: documentation
  framework: agnostic
---

# Documentation Writer

Buena documentación no es "escribir claro" en abstracto: es elegir el tipo de
documento correcto para lo que el lector necesita en ese momento. Diátaxis
(https://diataxis.fr/) distingue cuatro tipos, y mezclarlos es la causa más
común de docs que no sirven — un README que intenta ser tutorial, referencia y
explicación a la vez no cumple bien ninguno de los tres.

## Cuándo usar

- Te piden escribir o revisar documentación de un proyecto (README, guías,
  docs de API, onboarding).
- El pedido es ambiguo sobre qué tipo de documento hace falta.
- Hay que dar feedback de una doc existente que "no funciona" pero no está
  claro por qué.

## Los cuatro tipos (no los mezcles)

- **Tutorial** — orientado a aprender. Pasos concretos que llevan a un
  principiante a un resultado exitoso. Es una lección: se sigue de punta a
  punta, no se consulta por partes.
- **How-to** — orientado a un problema. Pasos para resolver algo puntual que
  el lector ya sabe que necesita. Es una receta.
- **Referencia** — orientado a información. Descripción técnica exacta de
  cómo funciona algo (API, props, comandos). Es un diccionario: se consulta,
  no se lee de corrido.
- **Explicación** — orientado a entender. Aclara el porqué de una decisión o
  un concepto. Es una discusión, no una receta.

Antes de escribir una línea, identificá cuál de los cuatro es el pedido real.
Si el pedido mezcla dos (p. ej. "un tutorial que también sea referencia"),
señalalo y proponé separarlos en dos documentos.

## Antes de escribir, determiná

1. **Tipo de documento**: tutorial, how-to, referencia o explicación.
2. **Audiencia**: quién lo lee (dev junior, alguien sin contexto del proyecto,
   un integrador externo) — determina cuánto contexto asumís.
3. **Objetivo del lector**: qué necesita poder hacer o entender al terminar.
4. **Alcance**: qué entra y, tan importante como eso, qué queda explícitamente
   afuera.

Si alguno de estos cuatro no está claro por el pedido, preguntá antes de
escribir — no asumas y sigas de largo.

## Al escribir

- Proponé una estructura (tabla de contenidos con una línea por sección) antes
  de redactar el documento completo, salvo que el pedido sea muy chico.
- Lenguaje simple y sin ambigüedad; términos consistentes de punta a punta.
- Código y detalles técnicos verificados contra el proyecto real — no
  inventes una API o un flag que no existe.
- Si te pasan otros `.md` del proyecto como contexto, usalos para igualar tono
  y terminología existentes; no copies contenido de ahí salvo que te lo pidan
  explícitamente.

## Al terminar, reportá

1. Qué tipo de documento Diátaxis escribiste o revisaste, y por qué ese y no
   otro.
2. Qué quedó explícitamente fuera de alcance.
3. Si detectaste que el pedido mezclaba dos tipos, cómo lo separaste.
