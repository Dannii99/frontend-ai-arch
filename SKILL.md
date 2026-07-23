---
name: angular-deploy-safety
description: >-
  Verifica que un build de Angular sea seguro para producción antes de
  desplegar. Úsala siempre que se vaya a hacer un build o deploy productivo,
  cuando se toque angular.json, environments, fileReplacements o el alias
  @env/environment, o cuando exista riesgo de que URLs de dev, endpoints
  locales, tokens o valores hardcodeados se filtren al bundle de producción.
---

# Angular Deploy Safety

Antes de desplegar un build de Angular a producción, el agente debe verificar
que la configuración de entorno se resolvió correctamente y que nada de
desarrollo se filtró al bundle. El objetivo es cero sorpresas en producción con
el mínimo de cambios.

## Cuándo usar esta skill

- Se va a correr un build o deploy productivo (`--configuration production`).
- Se modificó `angular.json`, un archivo de `environments/`, o el alias
  `@env/environment`.
- Se agregó configuración sensible al entorno (URLs de API, números de
  teléfono de canales, claves, feature flags).
- Hay sospecha de que un valor de dev pueda estar hardcodeado en el código.

## Principio rector

La verdad de qué se despliega está en `dist/`, no en el código fuente. La
verificación final siempre corre contra el output compilado, no contra los
`.ts`.

## Checklist de verificación

### 1. Confirmar el swap de environments

En `angular.json`, la configuración `production` debe tener `fileReplacements`
apuntando de `environment.ts` a `environment.prod.ts`:

```json
"fileReplacements": [
  {
    "replace": "src/environments/environment.ts",
    "with": "src/environments/environment.prod.ts"
  }
]
```

Verificar que:
- El build usa esa configuración (`ng build --configuration production`).
- El alias `@env/environment` en `tsconfig`/`paths` resuelve al archivo base,
  no directamente al de prod (el swap lo hace Angular en build time).
- Cualquier campo nuevo agregado en `environment.ts` existe también en
  `environment.prod.ts` con su valor productivo. Un campo que falta en prod
  rompe el build o queda `undefined` en runtime.

### 2. Grep contra el bundle compilado

Después del build, buscar marcadores de dev en `dist/` antes de subir nada:

```bash
# URLs y hosts de desarrollo
grep -rE "localhost|127\.0\.0\.1|\.dev\.|:4200|ngrok" dist/ || echo "OK: sin hosts de dev"

# Endpoints o dominios de staging/dev conocidos del proyecto
grep -rE "dev-api|staging|internal\." dist/ || echo "OK: sin endpoints de dev"

# Ruido de desarrollo
grep -rE "console\.(log|debug)|debugger" dist/ || echo "OK: sin logs de debug"
```

Cualquier match es un stop: no se despliega hasta resolverlo.

### 3. Cambios mínimos y dirigidos

Si hay que corregir algo (por ejemplo, mover un valor hardcodeado a
environment), hacer el cambio más chico posible. En contextos productivos
sensibles se prefiere un swap puntual guiado por entorno antes que un refactor
amplio. Ejemplo: un selector que elige un número de canal debe leerlo de
`environment` en vez de tener el número en el código.

### 4. Dry-run antes del deploy real

Preferir siempre una verificación previa (build local + grep + revisión del
`dist/`) antes de disparar el pipeline productivo. Nunca desplegar "a ciegas"
un build que no se inspeccionó.

## Salida esperada

Reportar al usuario:
- Configuración de build usada.
- Resultado de cada grep (OK o el match encontrado).
- Campos de environment que falten o difieran entre base y prod.
- Recomendación explícita: seguro para deploy / no seguro y por qué.
