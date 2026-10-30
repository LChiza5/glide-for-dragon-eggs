# Base jugable: mapa gris, vuelo, máquinas y dragones

Luis armó la base para que el juego se pueda probar de punta a punta. Empezó gris y el 30 de octubre se vistió como el
**Valle verde** con **dragones estilo caricatura** (ver abajo). Isaac la pule, manteniendo las etiquetas y los nombres
de abajo (son el contrato con el código).

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

## El Valle verde (30 de octubre)

`tools/studio/buildValleVerde.luau` viste el mapa gris (se corre en Studio, en modo edición, después de `buildGreybox.luau`):

- **Luz y cielo:** `Lighting` a las 14:30, con `Atmosphere`, `Sky`, corrección de color, brillo suave y rayos de sol
  (todos con nombre `Valle...` para poder rehacerlos).
- **Suelo y piedra:** pasto en el suelo y arriba del acantilado, plaza de piedra, acantilado de roca y rampa de tablas.
- **Máquinas de gimnasio:** la `Base` (con el ProximityPrompt) se queda donde estaba; encima va un modelo `Deco` con tapete,
  banco, postes, barra y discos de color. La parte `Weight` vieja queda invisible.
- **Nido:** paja bajo los 12 lugares y un anillo doble de ramas alrededor.
- **Carteles:** de madera con letras redondas; los que están cerca del suelo tienen postes.
- **Árboles, rocas y flores:** 70 árboles, 40 rocas y 50 grupos de flores fuera de la plaza, el nido y el camino de planeo.
- Todo es `Anchored`; lo decorativo no choca (`CanCollide` apagado), salvo troncos y rocas. Al final quita el atributo `Greybox`.
- Lo decorativo vive en `Map.Decor` y en los `Deco` de las máquinas: volver a correr el script solo rehace eso.

## Dragones estilo caricatura

`tools/studio/buildCartoonDragons.luau` crea los 15 dragones en `ReplicatedStorage.DragonModels` con óvalos suaves
(cabeza grande, ojos con brillo, cachetes, alas, cola y patitas). Más rareza = más tamaño y detalle:

| Rareza | Qué agrega |
|---|---|
| Common | Lo básico: cuernitos y un ala por lado |
| Uncommon | Púas en la espalda y alas dobles |
| Rare | Cuernos largos, cola de pala y hueso en las alas |
| Epic | Ojos y cola que brillan, cuernos extra y chispas |
| Legendary | Corona dorada con gema, alas con brillo, luz propia y más chispas |

Cada modelo mira hacia -Z, su pivote es el cuerpo (`PrimaryPart = Body`) y tiene los atributos `Cartoon` y `Rarity`.
El script solo reemplaza modelos con `Greybox` o `Cartoon`; un modelo de Blender sin esos atributos no se toca.

## Barra de distancia

`src/client/UI/GlideDistanceBar.luau` (Fusion) muestra arriba al centro, solo mientras se planea, la distancia del vuelo
y una barra que se llena hacia tu `BestDistance`. Al superarla se pone dorada y dice "NEW BEST!". Es la que ve el cliente;
la que paga el servidor llega por `GlideResult`.

## Copiar el código al Staging sin Rojo

Para no conectar Rojo al Staging:

1. En la carpeta `src` del repo: `python -m http.server 8765 --bind 127.0.0.1` (servidor local de solo lectura).
2. En Studio, con el Staging abierto en modo edición, correr `tools/studio/syncFromLocalServer.luau` (barra de comandos o run_code).
   Escribe el `Source` de cada script según `default.project.json`; los `Packages` no se tocan.
3. Guardar (Ctrl+S). Si se agrega un archivo nuevo en `src`, hay que sumarlo a la lista `FILES` del script.

## Probado en Staging (30 de octubre, Play)

- El código de `main` quedó copiado (28 archivos) y el juego arranca sin errores.
- Entrenar: el aviso "Entrenar (mantener)" aparece junto a la máquina y cada pedido de entrenar sube `WingPower` (27 → 32).
  La tecla E real no se pudo probar con la automatización: falta que alguien la presione con el teclado.
- Vuelo: pagó monedas, guardó `BestDistance` y regresó al jugador al inicio, también con el mapa nuevo.
- Barra de distancia: aparece al despegar, cuenta 0 → 45 studs, se llena hacia el récord y se esconde al aterrizar.
- Dragones: con 3 equipados (uno legendario) vuelan a 4–8 studs del jugador y los otros 12 aparecen en el nido.
