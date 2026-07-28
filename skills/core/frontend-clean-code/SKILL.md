---
name: frontend-clean-code
description: >-
  Estándar de código limpio para frontend, agnóstico de framework (React, Vue,
  Angular, Svelte o vanilla). Úsala al escribir o revisar componentes, lógica de
  UI, tipos o estado; cuando el código funciona pero cuesta leerlo o mantenerlo;
  o para dar feedback de calidad en un PR. Cubre nomenclatura, tipado en
  TypeScript, modelado de estado, separación de responsabilidades y efectos.
compatibility: agnostic
metadata:
  category: frontend-code-quality
  framework: agnostic
---

# Frontend Clean Code

El objetivo es código que otra persona —o vos en tres meses— pueda leer y
cambiar sin miedo. En frontend eso no se juega en "escribí prolijo" genérico, se
juega en lugares concretos: cómo modelás el estado, dónde vive la lógica y cómo
tipás los bordes. Esta skill apunta a esos lugares.

## Cuándo usar

- Escribís o revisás componentes, hooks/composables/services, tipos o estado.
- El código funciona pero cuesta leerlo, seguirlo o cambiarlo.
- Querés dar feedback de calidad en un PR con criterio, no por gusto.

## Nomenclatura

- Convención de casing: `camelCase` para variables y funciones, `PascalCase`
  para componentes y tipos, `UPPER_SNAKE` para constantes.
- Nombres que revelan intención: `elapsedDays`, no `d`. `userList` solo si es
  una lista de verdad (no mientas sobre la estructura).
- Booleanos con prefijo: `isLoading`, `hasError`, `canSubmit`, `shouldRender`.
- Handlers con convención: `handleSubmit` para la función; `onSubmit` para la
  prop que la recibe.
- Funciones = verbos (`fetchUser`, `formatPrice`); componentes = sustantivos
  (`UserCard`). Sin abreviaturas crípticas.

## Tipado (cuando hay TypeScript)

- Tipá los **bordes**: props, firmas de funciones, respuestas de API, contratos
  públicos. Adentro dejá que la inferencia trabaje — no anotes cada local obvio.
- Nada de `any`. Si algo es de verdad desconocido, usá `unknown` y estrechá con
  guardas de tipo.
- No filtres el tipo del backend (DTO) directo a la UI. Mapealo a un modelo de
  vista con solo lo que la interfaz necesita.
- `interface` para formas de objeto y contratos; `type` para uniones y
  utilidades. Elegí una convención y sostenela.
- `readonly` / inmutabilidad donde el dato no debe mutar.

## Estado (acá se gana o se pierde el frontend)

- Una sola fuente de verdad. Lo que se puede **derivar**, se deriva — no se
  guarda duplicado y se sincroniza a mano.
- Modelá los estados imposibles fuera de existencia. En vez de tres booleanos
  sueltos (`isLoading`, `hasError`, `data`) que permiten combinaciones inválidas,
  usá una unión discriminada:
  `{ status: 'idle' | 'loading' | 'success' | 'error' }`.
- Estado mínimo: si no cambia, es constante; si se calcula, es derivado; solo lo
  que realmente varía es estado.

## Separación de responsabilidades

- La lógica vive fuera del template/markup. La vista describe *qué* se muestra;
  el *cómo* se calcula va en funciones, hooks, composables o services.
- Una responsabilidad por componente/módulo. Si uno hace fetch, transforma y
  renderiza tres cosas, partilo.
- Nada de lógica de negocio en la capa de vista.
- Cuidado con el prop-drilling y los "god components": un componente que crece
  sin parar es señal de que hay que dividir.

## Funciones y control de flujo

- Chicas y de una sola cosa. Pocos argumentos; con 3+, pasá un objeto.
- Puras donde se pueda; aislá los side effects.
- Early return antes que anidar condicionales.
- Sin números ni strings mágicos: constantes con nombre.

## Efectos (side effects)

- Un efecto es para sincronizar con el mundo externo (red, DOM, storage,
  subscripciones), no para derivar datos que ya tenés.
- Siempre limpiá lo que abrís: listeners, timers, subscripciones.
- Si un efecto solo recalcula algo a partir de props o estado, probablemente no
  debería ser un efecto.

## Comentarios y ruido

- El código se explica solo; el comentario aclara el *por qué*, no el *qué*.
- Borrá código muerto y comentado — el historial de git ya lo guarda.

## Aditivo, no invasivo

- Respetá las convenciones que el proyecto ya tiene (naming, estructura de
  carpetas, estilo) por encima de tu preferencia. Consistencia > gusto personal.
- Limpieza en cambios mínimos y dirigidos; no reescribas medio módulo para
  renombrar una variable.

## Al terminar, reportá

1. Qué mejoraste y por qué (legibilidad, tipos, estado, responsabilidades).
2. Qué olores detectaste y cuáles dejaste sin tocar para no meter cambios
   grandes sin acordar.
3. Riesgos, si el cambio toca lógica.