# Skills

Las skills se organizan por alcance para que el instalador cargue solo las
relevantes al stack del proyecto. Un proyecto Angular no necesita las de React
—cargar skills de más ensucia el contexto del agente y baja la calidad.

## Taxonomía

```
skills/
├── core/          # SIEMPRE se instalan. Principios agnósticos de framework.
├── angular/       # Solo si el proyecto usa Angular.
└── react/         # Solo si el proyecto usa React.
```

## La regla core vs framework

Muchas skills tienen un **principio universal** pero una **implementación
específica**. La accesibilidad como concepto es igual en todos lados; cómo
manejás foco y ARIA con Angular CDK vs con React cambia.

- En `core/` va el **principio** y el **qué revisar** (agnóstico): p. ej.
  "foco visible en todo elemento interactivo, contraste AA mínimo".
- En la carpeta del framework va el **cómo se hace en ese framework**: p. ej.
  el patrón concreto de foco con Angular CDK.

Así, un proyecto siempre recibe el criterio (core) y, encima, la técnica del
framework que realmente usa.

## Dónde va cada skill tuya

- ¿Sirve igual para cualquier front? → `core/`
- ¿Depende de APIs/archivos/patrones de un framework? → carpeta de ese framework
  (ej. `angular-deploy-safety` vive de `angular.json` y `fileReplacements`, así
  que va en `angular/`).

## Formato

Cada skill es una carpeta con un `SKILL.md` (estándar Agent Skills: frontmatter
con `name` + `description`, y el cuerpo en Markdown). El mismo archivo funciona
en Claude Code, Cursor, Codex y demás; solo cambia dónde lo coloca el instalador.

> Reescribí en tu voz y tus estándares cualquier skill que uses de referencia.
> Una skill copiada tal cual no refleja tu criterio —y tu criterio es lo que te
> distingue como arquitecto. Además evita problemas de licencia en un repo público.
