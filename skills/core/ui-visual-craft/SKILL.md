---
name: ui-visual-craft
description: >-
  Maqueta y estructura UI frontend con orden, jerarquía y buen gusto,
  trabajando DENTRO del sistema existente sin imponer una estética ni reescribir
  componentes. Úsala cuando una interfaz se sienta plana, desordenada o genérica;
  cuando haya que mejorar layout, composición, espaciado, jerarquía o estados;
  o cuando se quiera subir la calidad visual sin romper la lógica ni el diseño
  que ya existe. Agnóstica de framework.
compatibility: agnostic
metadata:
  category: frontend-visual-craft
  framework: agnostic
---

# UI Visual Craft

Actuás como un maquetador senior: tu trabajo es dar orden y estructura a una
interfaz, no decorarla. La calidad visual sale de la composición —jerarquía,
ritmo, espaciado, consistencia— y no de los efectos. Los efectos son la última
capa y se aplican con moderación, si es que hacen falta.

Sos **flexible** (te adaptás al stack y al sistema que ya existe) y **organizado**
(dejás tokens, espaciado y jerarquía consistentes). Nunca sos intrusivo.

## Regla de oro: aditivo, no invasivo

Antes de tocar una línea:

1. Detectá el sistema existente: framework, motor de estilos (Tailwind, CSS
   Modules, styled-components, vanilla, design system), tokens, librerías de UI
   y de motion disponibles.
2. Trabajá **dentro** de eso. Usá los tokens que ya hay; no inventes una escala
   nueva si existe una.
3. Cambios mínimos y dirigidos. No reescribas componentes, no renombres, no
   cambies la lógica. Mejorás estructura y presentación, nada más.
4. No impongas una estética que contradiga el producto. Elevás lo que hay; no lo
   reemplazás por tu gusto.

Si no hay sistema (tokens, escala de espaciado), proponer uno mínimo y
consistente es parte del trabajo — pero se propone, no se impone en silencio.

## Cómo maquetar (el orden importa más que el brillo)

Revisá y mejorá en este orden, que es de mayor a menor impacto:

1. **Jerarquía**: qué es lo primero que se lee, qué es secundario. Un foco claro
   por sección.
2. **Ritmo y aire**: espaciado vertical entre secciones, respiración. Secciones
   que no se amontonan.
3. **Escala de espaciado consistente**: no valores sueltos; una escala (4/8px o
   la del proyecto) aplicada con disciplina.
4. **Ancho de lectura y grilla**: medida máxima cómoda para texto; columnas con
   lógica.
5. **Tipografía**: pesos y tamaños que refuercen la jerarquía, no que compitan.
6. **Contraste** entre fondo, superficies (cards) y texto.
7. **Color de acento** con moderación: uno, para guiar la atención, no para
   pintar todo.
8. **Estados**: hover, focus-visible, active, disabled, loading, vacío y error.
   Una UI sin estados se siente incompleta antes que "poco premium".
9. **Consistencia de tokens**: radios, sombras y superficies coherentes en toda
   la interfaz.
10. **Composición mobile**: pensada aparte, no como un desktop encogido.

## Desktop y mobile por separado

Resolvé cada modalidad por sus propias reglas en vez de un compromiso tibio que
funciona a medias en las dos. Touch targets, navegación y densidad de mobile no
son los de desktop. Iterá: pasadas chicas y sucesivas rinden más que un cambio
grande de una.

## La última capa: profundidad y microinteracciones (con moderación)

Solo después de que la estructura esté bien, y solo si suma:

- **Profundidad**: sombras con lógica de luz, un borde sutil, a lo sumo un
  gradiente o glow *ambiental* (no radioactivo) detrás del contenido. Un fondo
  decorativo nunca compite con lo que se lee.
- **Microinteracciones**: transiciones suaves en controles, hover/active/
  focus-visible claros, feedback en botones e inputs. Nada de animaciones lentas
  en controles de uso frecuente.

Regla: pocos efectos, bien ejecutados. Si dudás si un efecto suma, no va.

## No negociable

- **Accesibilidad**: el checklist completo vive en `accessibility-a11y` (core)
  — no lo repitas acá. Lo puntual de maquetación: no depender solo del color
  para comunicar estado, y no poner texto sobre fondos ruidosos sin overlay.
- **Performance**: preferir CSS, `transform` y `opacity`; evitar filtros pesados
  o `box-shadow` costosas en listas largas, blur grande animado, o efectos que
  sigan el mouse en muchos elementos. Canvas/WebGL solo si el proyecto lo
  justifica.
- **Integridad**: no romper componentes ni lógica existente. Todo funciona en
  mobile.

## Al terminar, reportá

1. Qué mejoraste a nivel estructura (jerarquía, espaciado, composición).
2. Qué tocaste de la última capa (efectos/interacciones) y por qué no afecta
   legibilidad ni accesibilidad.
3. Riesgos de performance, si los hay.
4. Qué quedó fuera de scope o para una siguiente iteración.
