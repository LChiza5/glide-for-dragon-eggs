# Base jugable: mapa gris, vuelo, máquinas y dragones

Luis armó la base para que el juego se pueda probar de punta a punta. Es **gris a propósito**: Isaac la reemplaza con el arte
real del Valle verde y los modelos de Blender, manteniendo las etiquetas y los nombres de abajo (son el contrato con el código).

## El mapa (`Workspace.Map`)

Lo construye `tools/studio/buildGreybox.luau` (se corre en Studio, en modo edición). No toca un `Map` que no tenga el atributo `Greybox`.

| Parte | Dónde | Etiqueta o atributo |
|---|---|---|
| Suelo | todo el mapa, en Y = 0 | — |
| Inicio y `SpawnLocation` | Z = -600 | `ReturnPoint` (a dónde vuelve el jugador al aterrizar) |
| 6 máquinas de entrenamiento | Z = -540, a los lados del camino | `TrainingMachine` + un `ProximityPrompt` dentro |
| Rampa y acantilado (100 studs de alto) | Z = -480 a 0 | — |
| Plataforma de despegue (naranja) | borde del acantilado, Z = -24 a 0 | `LaunchPad` |
| Pista de aterrizaje con marcas cada 100 studs | Z = 0 a 20.000, hacia +Z | — |
| Nido con 12 lugares | X = -200, Z = -560 | `NestSlot` + atributo `Slot` (1 a 12) |

Si el nido real tiene otra cantidad de lugares, hay que avisar a Luis para igualar `Balance.NEST_SLOTS`.

## El vuelo

1. El jugador sube la rampa y sale de la plataforma `LaunchPad` en el aire (corriendo o saltando).
2. **Cliente** (`GlideController`): impulso hacia arriba y planeo recto. Con WASD o el stick se gira. La distancia a la que
   intenta llegar es `poder × 2 × GlideMultiplier × 0,9`, y la velocidad se ajusta para que un vuelo largo dure unos 14 s.
3. **Servidor** (`GlideService`): mide el despegue y el aterrizaje con la posición del personaje y paga con `rewardDistance`.
   Cancela sin pago si va más rápido de lo posible (teletransporte), si sube demasiado o si el vuelo dura más de 3 minutos.
4. A los 3 s de aterrizar, el servidor lo regresa al `ReturnPoint`.

Todos los números están en `Config/Balance.luau`, sección **Vuelo** (el feel lo ajusta Isaac ahí, no dentro del código).
Para la UI de José: `GlideController.isGliding()`, `GlideController.distance()`, `onGlideStarted(fn)`, `onGlideEnded(fn)`
y el resultado real en `Remotes.get("GlideResult")`.

## Las máquinas

Mantener la tecla del prompt (E) entrena a la velocidad que permite el servidor. El botón de entrenar del HUD sigue funcionando.
Para la animación: `TrainingController.isHolding()`.

## Los dragones

- `tools/studio/buildDragonModels.luau` crea `ReplicatedStorage.DragonModels` con un modelo de bloques por cada `id` de
  `Config/Dragons.luau` (15). Cada modelo mira hacia -Z y su pivote es el cuerpo. El script respeta los modelos que no tengan
  el atributo `Greybox`, así que Isaac puede ir cambiándolos uno por uno.
- `DragonController` (cliente) hace que los equipados de cada jugador vuelen a sus lados y pone en el nido a los 12 que pagan.

## Probado (copia local, Play)

- Vuelo con poder 300: planeó 527 studs en 14 s; el servidor pagó 524 studs y lo regresó al inicio.
- Vuelo con trampa (teletransporte de 800 studs en el aire): sin pago y de vuelta al inicio.
- 3 dragones siguiendo al jugador y 12 en el nido (15 modelos en pantalla).
