---
name: framework-version-awareness
description: >-
  Protocolo para que el consejo de framework (Angular, React, Next) respete la
  versión REAL instalada en el proyecto: leer la versión resuelta del lockfile,
  compararla con el rango que cubren las skills/referencias locales
  (metadata.versions de cada skill de arquitectura), y consultar doc oficial
  viva de esa versión (MCP oficial del framework, Context7, o la doc web
  versionada) cuando el proyecto queda fuera de ese rango o la API a usar es
  más nueva o más vieja que la versión instalada. Úsala antes de generar o
  revisar código que dependa de una API del framework, al arrancar en un
  proyecto existente, cuando una referencia local menciona "desde vX", o
  cuando haya duda de si una API existe, cambió de nombre o está deprecada en
  la versión del proyecto. No decide arquitectura (eso es de
  angular-architecture / react-architecture / next-architecture).
compatibility: agnostic
metadata:
  category: version-awareness
  framework: agnostic
---

# Framework Version Awareness

Las skills de framework de este ecosistema son una foto: se escribieron y
verificaron contra una versión concreta. El framework sigue avanzando, y el
proyecto donde trabajás puede estar atrás o adelante de esa foto. Esta skill
separa dos preguntas que no tienen la misma fuente de verdad:

- **"¿Qué existe y cómo se usa?"** → depende de la versión instalada. Fuente:
  la doc oficial de *esa* versión.
- **"¿Qué decidimos nosotros?"** (carpetas, cuándo un store, qué se testea) →
  criterio de casa, vive en la skill de arquitectura del framework y cambia
  poco entre versiones.

El objetivo no es consultar doc viva todo el tiempo, sino saber **cuándo** la
doc local alcanza y cuándo no.

## Cuándo usar

- Arrancás a trabajar en un proyecto existente y todavía no sabés qué versión
  de framework tiene.
- Vas a usar una API marcada `(desde vX)` en una skill de arquitectura, o una
  que sabés que es reciente (signals, Signal Forms, `use cache`, React
  Compiler, Actions…).
- La versión del proyecto queda fuera del rango `metadata.versions` de la
  skill de arquitectura del framework.
- Dudás si una API existe, se renombró (ej. `middleware` → `proxy` en Next
  16) o está deprecada en la versión instalada.
- Revisás un PR y querés validar que no usa APIs que la versión del proyecto
  no tiene.

## Cuándo NO usar

- Para cada línea de código: si la versión está dentro del rango cubierto y la
  API no tiene marca de versión, la doc local alcanza.
- Para decidir arquitectura: eso no cambia con la versión menor del framework
  y sigue en la skill de arquitectura.
- Para proponer un upgrade de versión por iniciativa propia. Podés mencionar
  que una API está deprecada en la versión actual; el upgrade lo decide el
  equipo.

## 1. Resolver la versión real (no el rango)

`package.json` declara un rango (`^19.0.0`); lo que corre es la versión
resuelta. Leela en este orden y quedate con la primera que encuentres:

1. `node_modules/<paquete>/package.json` → campo `version` (lo instalado de
   verdad).
2. El lockfile: `package-lock.json` (`packages["node_modules/<paquete>"].version`),
   `pnpm-lock.yaml`, `yarn.lock` o `bun.lock`.
3. `package.json` como último recurso — y decí que es un rango, no una
   versión exacta.

`.fea/manifest.json` (si existe) trae `frameworks[].version` del último
`install.sh`: sirve como pista rápida, pero puede estar viejo — el lockfile
manda.

Paquetes a mirar:

| Framework | Paquete principal | Satélites que también cambian el consejo |
|-----------|-------------------|-------------------------------------------|
| Angular   | `@angular/core`   | `@angular/cli`, `@angular/ssr`, `typescript`, `rxjs`, `zone.js` (si está o no) |
| Next      | `next`            | `react`, `react-dom`, `typescript` |
| React     | `react`           | `react-dom`, router (`react-router` / `@tanstack/react-router`), `@tanstack/react-query`, `babel-plugin-react-compiler` |

En un monorepo, resolvé la versión del paquete/app que estás tocando, no la
de la raíz.

## 2. Comparar con la cobertura local

Cada skill de arquitectura de framework declara qué rango cubre:

```yaml
metadata:
  versions:
    package: "@angular/core"
    min_supported: "17"      # por debajo, la skill no se aplica a ciegas
    verified_against: "21"   # versión contra la que se escribió/revisó
    verified_at: "2026-07-23"
```

Con la versión mayor del proyecto (`N`), hay tres casos:

- **`min_supported ≤ N ≤ verified_against`** → usá la skill y su referencia
  tal cual. Solo cuidá las secciones marcadas `(desde vX)` con `X > N`: esas
  APIs no existen todavía en el proyecto; usá el fallback que indica la skill.
- **`N < min_supported`** (proyecto más viejo que la skill) → el criterio de
  arquitectura sigue valiendo, pero la sintaxis/API de la referencia local
  probablemente no existe. Antes de escribir código que dependa de una API,
  consultá la doc de la versión `N` (paso 3). No "modernices" el código del
  proyecto por arrastre.
- **`N > verified_against`** (proyecto más nuevo que la skill) → la referencia
  local puede tener APIs deprecadas, renombradas o reemplazadas. Para el área
  que vas a tocar (no para todo el proyecto), consultá la doc de la versión
  `N` antes de generar código y anotá las diferencias.

## 3. Cómo consultar doc viva de una versión

En este orden, usando la primera fuente disponible en tu sesión:

1. **MCP oficial del framework**, si está registrado:
   - Angular: el MCP del Angular CLI (`npx @angular/cli mcp`, registrado como
     `angular-cli`) — `search_documentation` y `get_best_practices` responden
     en función de la versión del workspace. Mecánica en
     `angular-references/angular-developer` (`references/mcp.md`).
   - Next: `next-devtools-mcp` — trae la doc oficial de Next y herramientas
     de diagnóstico/upgrade.
   - React: no tiene MCP oficial de docs → pasá a Context7.
2. **Context7** (MCP `context7`): resolvé el ID de la librería
   (`resolve-library-id`) y pedí la doc fijando la versión cuando el ID lo
   permite (ej. `/vercel/next.js/v15.x`, `/angular/angular/v19.x`), acotando
   el tema a lo que vas a tocar ("signal forms validation", "params async").
   El nombre exacto de la tool de docs depende de la versión del server
   (`get-library-docs` / `query-docs`) — usá la que exponga.
3. **Doc web oficial versionada** (WebFetch o equivalente):
   - Angular: `https://v<N>.angular.dev` para versiones anteriores,
     `https://angular.dev` para la actual; guía de migración en
     `https://angular.dev/update-guide`.
   - Next: `https://nextjs.org/docs` (selector de versión) y las guías de
     upgrade `https://nextjs.org/docs/app/guides/upgrading`.
   - React: `https://react.dev` (y `https://<N>.react.dev` para versiones
     anteriores cuando exista) y el blog de releases.
   - Si el sitio publica `llms.txt`, preferilo: es más corto y más fácil de
     leer para un agente.
4. **Nada disponible** → seguí con la doc local, pero decílo explícitamente
   ("no pude verificar contra la doc de vN; esto sale de la referencia local
   verificada contra vM") y marcá las APIs dudosas.

Consultá **por tema**, no "toda la doc": la pregunta es concreta ("¿existe
`linkedSignal` en v18?", "¿cómo se llama el archivo de middleware en v16?").

## 4. Precedencia entre fuentes de doc

Para "qué existe y cómo se usa" en la versión del proyecto:

1. Doc oficial de la versión instalada (MCP oficial / Context7 / web).
2. Referencia local (`angular-references`, `react-references`,
   `next-references`) — dentro de su rango.
3. Conocimiento propio del modelo — el menos confiable para APIs que cambian
   rápido (renombres, deprecaciones, defaults nuevos). Nunca lo uses para
   contradecir a 1 o 2.

Para "qué decidimos", la precedencia es la de la sección "Precedencia" de
`AGENTS.md` — la versión no la cambia. Si la doc nueva vuelve obsoleta una
decisión de casa (ej. un default que ya no existe), no la reemplaces por tu
cuenta: aplicá el equivalente más cercano y reportalo como desfase.

## 5. Desfases: cómo hacer que las skills evolucionen

Cada vez que la doc viva contradice a la referencia local para la versión del
proyecto, eso es información valiosa — no la tires:

- Reportala al usuario (ver "Al terminar, reportá").
- Si Engram está disponible, guardala como memoria del proyecto
  (`desfase-version: <framework> vN — <API> — local dice X, doc oficial dice Y`),
  así la próxima sesión no la vuelve a descubrir.
- Es la señal para actualizar la skill en el repo del ecosistema
  (frontend-ai-arch): bumpear `verified_against`/`verified_at` y anotar
  `(desde vX)` donde corresponda. No edites la skill instalada en la carpeta
  global del agente — se pisa en el próximo `install.sh`.

## Al terminar, reportá

1. Versión detectada del framework (y de dónde salió: `node_modules`,
   lockfile o rango de `package.json`).
2. Rango que cubre la skill local (`min_supported`–`verified_against`) y en
   cuál de los tres casos cayó el proyecto.
3. Si consultaste doc viva: qué fuente (MCP oficial, Context7, web) y sobre
   qué tema.
4. APIs que evitaste o reemplazaste por no existir (o estar deprecadas) en la
   versión del proyecto.
5. Desfases encontrados entre la doc local y la oficial — candidatos a
   actualizar en el repo del ecosistema.
