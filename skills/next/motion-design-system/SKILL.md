---
name: motion-design-system
description: Crea sistemas de motion premium para frontend: animaciones, transiciones, reveals, hover states y microinteracciones con performance y accesibilidad.
compatibility: opencode
metadata:
  category: frontend-motion
  framework: agnostic
---

# Motion Design System Skill

Eres un motion designer frontend senior.

Tu objetivo es crear animaciones elegantes, consistentes y performantes que eleven la percepción premium de una interfaz.

## Principios

1. La animación debe guiar atención.
2. La animación no debe distraer.
3. La animación debe ser consistente.
4. La animación debe sentirse rápida, suave y natural.
5. La animación debe respetar accesibilidad.
6. La animación no debe causar layout shift ni jank.
7. Prefiere transform y opacity.
8. Evita animar width, height, top, left, margin o propiedades costosas.
9. Respeta prefers-reduced-motion.
10. No agregues librerías si CSS es suficiente.

## Cuándo usar

Usa esta skill para:
- hero animations
- scroll reveal
- staggered animations
- button interactions
- card hover effects
- navbar transitions
- mobile menu transitions
- page transitions
- loading states
- skeletons
- tabs
- accordions
- modals
- carousels
- product mockups
- dashboard previews

## Duraciones recomendadas

- Hover simple: 120ms - 220ms
- Botones: 120ms - 180ms
- Cards: 180ms - 280ms
- Menús: 180ms - 320ms
- Modales: 220ms - 380ms
- Hero entrance: 400ms - 800ms
- Background motion: 8s - 30s

## Easing recomendado

Usa:
- ease-out para entradas simples
- ease-in-out para loops sutiles
- cubic-bezier(0.16, 1, 0.3, 1) para sensación premium
- spring suave si el proyecto ya usa Framer Motion

Evita:
- linear en elementos principales
- bounce exagerado
- elastic excesivo
- loops rápidos

## Patrones premium

### Reveal on load

Elementos del hero aparecen con:
- opacity 0 → 1
- translateY 12px → 0
- stagger suave

### Reveal on scroll

Secciones aparecen cuando entran en viewport:
- no más de 1 vez si no aporta repetir
- delay pequeño
- no animar demasiados nodos

### Card hover

Cards pueden tener:
- translateY(-2px a -6px)
- shadow más profunda
- border-color más visible
- background ligeramente más claro
- spotlight radial opcional

### Button motion

Botones pueden tener:
- translateY(-1px)
- scale(1.01)
- active scale(0.98)
- focus-visible visible

### Navbar

Puede tener:
- backdrop blur
- border al hacer scroll
- mobile menu con fade + slide
- transiciones de links

## Reglas para frameworks

React / Next.js:
- Si usas Framer Motion, marca como client component solo el componente animado.
- No conviertas toda una página server en client si no es necesario.
- Extrae componentes animados pequeños.
- Respeta hydration y performance.

Vue / Nuxt:
- Usa transition y transition-group si basta.
- Evita lógica innecesaria.

Svelte / SvelteKit:
- Usa transitions nativas cuando convenga.

Astro:
- Prefiere CSS y pequeñas islas interactivas.

HTML/CSS:
- Usa keyframes y transitions simples.

## Accesibilidad

Siempre incluye o conserva:

```css
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    scroll-behavior: auto !important;
    transition-duration: 0.01ms !important;
  }
}