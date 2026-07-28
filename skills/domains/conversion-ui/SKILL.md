---
name: conversion-ui
description: >-
  Mejora interfaces orientadas a conversión: landings, pricing, signup, checkout,
  onboarding. Úsala en superficies de marketing o venta donde el objetivo es que
  el usuario actúe — no en dashboards ni herramientas internas. Trabaja claridad
  de propuesta de valor, jerarquía de CTA, señales de confianza y reducción de
  fricción, sin dark patterns. Agnóstica de framework, situacional (opt-in).
compatibility: agnostic
metadata:
  category: conversion
  scope: domain          # situacional: no se autocarga por stack, se opta por ella
  framework: agnostic
---

# Conversion UI

Esta skill no es sobre que una página se vea bien —eso lo cubre
`ui-visual-craft`— sino sobre que **convierta**: que el usuario entienda el valor
y actúe. Es situacional: aplica a superficies de venta o captación, no a un
dashboard ni una herramienta interna.

## Cuándo usar

- Landing, home, página de producto, agencia, SaaS.
- Pricing, signup, checkout, onboarding, lead capture.
- **No** la uses en apps internas, dashboards o back-office: ahí el objetivo es
  eficiencia, no conversión, y las reglas son otras.

## Qué evaluar (de mayor a menor impacto)

1. **Propuesta de valor**: ¿se entiende en 5 segundos? El headline dice algo
   concreto y el subheadline saca una duda. Nada de frases genéricas.
2. **Jerarquía de acción**: un CTA principal claro, visible sin scroll, con texto
   específico ("Empezar gratis", no "Enviar"). No compite con otros cinco botones.
3. **Confianza**: logos, métricas reales, testimonios, casos, garantías,
   screenshots reales — ubicados donde reducen la duda, no amontonados.
4. **Fricción**: sacá lo que estorba (demasiadas opciones, formularios largos,
   texto de más, navegación innecesaria). Cada campo y cada link se gana su lugar.
5. **Escaneabilidad**: la página se lee en diagonal — títulos que resumen,
   contraste, orden de lectura claro.
6. **Pricing** (si hay): un plan recomendado marcado, diferencias claras entre
   planes, beneficios concretos, un CTA por plan.

## Línea ética (no negociable)

- Sin dark patterns: no escondas el precio, el botón de cancelar ni la letra chica.
- Sin claims ni métricas inventadas. Si no hay dato real, placeholder marcado
  como placeholder.
- Claridad, no manipulación: reducir fricción real, nunca engañar.

## Relación con otras skills

El *cómo se ve* (jerarquía visual, espaciado, estados, profundidad) lo resuelve
`ui-visual-craft`. Acá te enfocás en el *qué comunica y por qué convierte*. No
dupliques el trabajo visual — apoyate en esa skill.

## Al terminar, reportá

1. Qué cambios ayudan a conversión y por qué.
2. Qué cambios son solo visuales (para no atribuirles un impacto que no tienen).
3. Dónde tiene sentido un A/B test antes de dar algo por ganado.