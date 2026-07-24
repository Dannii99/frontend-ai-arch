# RSC Boundaries — casos límite Server ↔ Client

Referencia de `next-conventions`. Se abre cuando hay que cruzar el límite entre
Server y Client Components y el patrón correcto no es obvio. Es el punto donde
más fácil se rompe.

Doc oficial: https://react.dev/reference/rsc/use-client

## 1. Un Client Component NO puede ser async

Solo los Server Components pueden ser `async`. Si un componente con `'use client'`
necesita `await`, el patrón es fetchear en el server padre y pasar los datos.

```tsx
// ❌ Mal: client component async
'use client'
export default async function Perfil() {
  const user = await getUser()        // no se puede await acá
  return <div>{user.name}</div>
}
```

```tsx
// ✅ Bien: el server padre trae los datos
// page.tsx (server component — sin 'use client')
export default async function Page() {
  const user = await getUser()
  return <Perfil user={user} />
}

// perfil.tsx (client)
'use client'
export function Perfil({ user }: { user: User }) {
  return <div>{user.name}</div>
}
```

## 2. Las props Server → Client tienen que ser serializables

Lo que cruza de un Server Component a uno Client viaja como JSON. Si mandás algo
no serializable, o se rompe en runtime o llega mutado en silencio.

| Se pasa a Client | ¿Válido? | Arreglo |
|---|---|---|
| `string` / `number` / `boolean` | Sí | — |
| objeto/array plano | Sí | — |
| `Date` | No | Pasá `.toISOString()`, reconstruí con `new Date()` del lado cliente |
| `Map` / `Set` | No | Convertí a objeto/array (`Object.fromEntries`, `Array.from`) |
| función | No* | *Excepto Server Actions (`'use server'`) |
| instancia de clase | No | Pasá un objeto plano con los campos que usás |

```tsx
// ❌ Mal: Date cruza y explota en el cliente
return <PostCard createdAt={post.createdAt} />   // Date

// ✅ Bien: serializás en el server
return <PostCard createdAt={post.createdAt.toISOString()} />  // string
```

## 3. La excepción: las Server Actions SÍ cruzan

Una función marcada con `'use server'` se puede pasar a un Client Component. Es
el único tipo de función que cruza el límite.

```tsx
// actions.ts
'use server'
export async function guardar(formData: FormData) { /* corre en server */ }

// page.tsx (server)
import { guardar } from './actions'
export default function Page() {
  return <FormCliente onSubmit={guardar} />   // válido
}
```

## Regla mental

Si dudás si algo cruza bien: ¿sobrevive a `JSON.stringify` y vuelve igual? Si no,
serializalo del lado server antes de pasarlo. La única excepción es una Server
Action.
