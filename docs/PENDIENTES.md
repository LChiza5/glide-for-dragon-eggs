# Qué le toca a cada quien

Estado al 30 de octubre de 2026. Luis dejó listo todo el lado del servidor (datos, entrenamiento, vuelo, huevos, dragones, nido,
ganancias sin conexión, renacer, recompensa diaria, clasificación, compras con Robux y analítica) y además **la base jugable**:
vuelo con medición en el servidor, máquinas de entrenamiento y dragones que siguen al jugador y se ven en el nido.
El 30 de octubre se pasó el código al Staging y se vistió el mapa: ya hay **Valle verde**, **15 dragones estilo caricatura**
y **barra de distancia** durante el vuelo. Ya se puede probar con gente; lo que falta es **pulir el arte y el feel** (Isaac)
y **el resto de la interfaz** (José).

> **Lo más urgente es lo visual:** el juego ya funciona, pero todavía se ve feo. Cada pendiente de Isaac y José también está
> como **Issue en GitHub** (se ven en GitKraken, sección **ISSUES** del panel izquierdo), con su lista de casillas y estas
> etiquetas: `isaac`, `jose`, `visual`, `prioridad` y `etapa-3`. Empiecen por los que dicen `prioridad`.
> Al terminar uno, ciérrenlo desde su Pull Request (escribiendo "Closes #número" en la descripción).
> Lista: <https://github.com/LChiza5/glide-for-dragon-eggs/issues>

> **Isaac: tu lista cambió.** Luis hizo la base de tu parte para poder probar el juego. No la rehagas: tu trabajo ahora es
> convertirla en el juego bonito (arte, modelos, animaciones y el feel del planeo). Todo lo que hizo Luis está explicado en
> [BASE-JUGABLE.md](BASE-JUGABLE.md).

Los contratos exactos (funciones, atributos, eventos) están en [EQUIPO.md](EQUIPO.md) (secciones **Contratos entre sistemas**, Etapas 1 y 2)
y en [ETAPA3.md](ETAPA3.md) (renacer, recompensa diaria, clasificación y compras). La economía se explica en [BALANCE.md](BALANCE.md).
Todo está ya en `main`: con `git pull` lo tienen.

## Primer arranque (Isaac y José)

1. **Grupo de Roblox:** ya son miembros de **LIJ Devs** con permiso para probar y editar las experiencias.
   Enlace: <https://www.roblox.com/communities/486088653/LIJ-Devs>
2. **Repo:** pasarle a Luis su usuario de GitHub para que los agregue en Settings → Collaborators del repo privado
   `LChiza5/glide-for-dragon-eggs`. Después aceptar la invitación que les llega por correo.
3. **Herramientas:** seguir "Primera vez" del [README](../README.md): Studio, Git, VS Code, Rokit, y dentro del repo
   `rokit install`, `wally install` y `rojo plugin install`.
4. **Abrir Staging:** Creator Hub → el grupo **LIJ Devs** → experiencia **[Staging]** → Editar en Studio. Ahí se hace el mapa, los modelos
   y el diseño de la UI en Team Create.
5. **Probar código:** en su propia rama, `rojo serve`; en Studio, Plugins → Rojo → Connect. Rojo avisa si el lugar no está en la lista:
   confirmar una vez. Los scripts se editan solo en el repo, nunca en Studio.

Reglas de siempre: una rama por tarea (`feat/...`), commits cortos en español, Pull Request hacia `main` con otro integrante revisando,
y `stylua src` y `selene src` antes de abrirlo. Detalle en [CONTRIBUTING.md](../CONTRIBUTING.md).

## Isaac: arte, modelos y feel del juego

**Ya está hecho por Luis (no rehacer):** `GlideController` y la medición del vuelo en `GlideService`,
`TrainingController` con las máquinas, `DragonController` (dragones que siguen y nido de 12), la primera versión del
**Valle verde** (`tools/studio/buildValleVerde.luau`) y los **15 dragones estilo caricatura** (`tools/studio/buildCartoonDragons.luau`).
Están hechos con piezas de Studio: son buenos para probar con gente, pero tu arte de Blender puede reemplazarlos cuando quieras.
Cómo funcionan: [BASE-JUGABLE.md](BASE-JUGABLE.md).

**Etapa 1 y 2: que se vea y se sienta bien**
- [x] **Valle verde (primera versión, Luis):** pasto, luz y cielo, árboles, rocas, flores, máquinas con forma de pesas, nido de ramas
      y carteles de madera. El mapa ya no tiene el atributo `Greybox`.
- [ ] **Retoques del Valle verde:** colinas con Terrain, río o lago, más detalle en el acantilado, la rampa y la plaza,
      y lo que quieras cambiar. Mantener las etiquetas, que son el contrato con el código: `TrainingMachine` (con su ProximityPrompt),
      `LaunchPad`, `ReturnPoint` y `NestSlot` (atributo `Slot` 1 a 12). Si vuelves a correr `buildValleVerde.luau`, rehace solo
      `Map.Decor` y los modelos `Deco` de las máquinas.
- [x] **15 dragones estilo caricatura (Luis):** en `ReplicatedStorage.DragonModels`, más detalles y brillo según la rareza.
- [ ] **(Opcional) Dragones de Blender:** si haces uno mejor, ponlo con el mismo nombre que su `id` de `Config/Dragons.luau`,
      mirando hacia -Z, con el pivote en el cuerpo y **sin** los atributos `Greybox` ni `Cartoon` (así ningún script lo pisa).
- [ ] **Animaciones:** personaje al entrenar (`TrainingController.isHolding()`), pose y alas al planear
      (`GlideController.isGliding()`, `onGlideStarted`, `onGlideEnded`), y dragones volando y descansando en el nido.
- [ ] **Feel del planeo:** ajustar la sección **Vuelo** de `Config/Balance.luau` (velocidad, giro, impulso, caída) y la cámara
      durante el vuelo en `GlideController`. Si subes `GLIDE_MAX_SPEED` o `GLIDE_LAUNCH_BOOST`, avisa a Luis: el servidor los usa
      para detectar trampas.
- [ ] **Huevos en el aire (diseño):** dónde aparecen durante el vuelo y cómo se recogen. Hablar con Luis antes de programarlo;
      del lado del servidor se entrega con `EggService.hatch(player, "Basic", true)`.

**Etapa 3: reino nuevo y mapa**
- [ ] Tableros de clasificación en el mapa: leer `ReplicatedStorage.LeaderboardTop` (JSON) y repintar con `.Changed` (ver ETAPA3.md).
- [ ] Reino 2 (desierto de cañones) y obstáculos en vuelo. Cuando exista, avisar a Luis para activar el producto `SkipRealm`.
- [ ] Optimización del mapa real (cantidad de partes, streaming) antes de publicar.

## José: interfaz, arte y marketing

**Etapa 0 y 1**
- [ ] Dirección de arte, paleta y bocetos (HUD, tienda, inventario). Los colores y espacios van en `src/client/UI/Theme.luau`.
- [x] **Barra de distancia durante el vuelo (base de Luis):** `src/client/UI/GlideDistanceBar.luau`. Usa solo colores del Theme;
      cámbiale el estilo como quieras.
- [ ] HUD: el "+1" que salta (`TrainingController.onTrained`) y sonidos.
      El vuelo ya existe: `GlideController.isGliding()`, `GlideController.distance()`, `onGlideStarted(fn)` y `onGlideEnded(fn)`.
- [ ] Pantalla de resultado al aterrizar: escuchar `Remotes.get("GlideResult")` (`distance`, `coins`, `isNewBest`).
- [ ] Mostrar `BestDistance` con `StatsController.get("BestDistance")`.

**Etapa 2: colección**
- [ ] Eclosión animada con `InventoryController.hatch("Basic")` y `onHatchResult`.
- [ ] Inventario con `InventoryController.owned()` y `equipped()`, y botones de equipar y desequipar.
- [ ] Índice de dragones con `Dragons.LIST` (nombre, rareza, planeo y monedas).
- [ ] Mostrar las probabilidades de `Eggs.RARITY_WEIGHTS` antes de comprar un huevo con Robux (regla de Roblox).
      Los pesos cambiaron (63 / 26 / 8 / 2,3 / 0,7): leerlos siempre de `Config/Eggs.luau`, nunca escribirlos a mano en la UI.
- [ ] **Aviso de legendario** para todo el servidor ("Fulano sacó un Sunfire Sovereign"): `InventoryController.onLegendaryHatched(fn)`
      con `displayName` y `dragonId` (el nombre bonito está en `Dragons.byId`).
- [ ] Avisos de rareza y pantalla de bienvenida con `OfflineCoins` y `OfflineSeconds`.

**Etapa 3: monetización y retención** (el servidor ya está listo; falta toda la interfaz; detalle en ETAPA3.md)
- [ ] **Renacer:** botón con `RebirthCost` y `RebirthMultiplier`, que pide con `Remotes.get("Rebirth"):FireServer()` y muestra `RebirthResult`.
- [ ] **Recompensa diaria:** ventana con el calendario de 7 días (`Daily.REWARDS`), la racha, la cuenta regresiva (`DailyResetAt`) y el botón de reclamar.
- [ ] **Clasificación:** lista del Top 50 con `LeaderboardTop`.
- [ ] **Tienda** con `PurchaseController.request(clave)`: los 6 pases y los productos (paquete inicial una sola vez, paquetes de huevos,
      poción de suerte con cuenta regresiva `LuckUntil`, y "duplicar ganancias sin conexión" dentro de la pantalla de bienvenida).
- [ ] **Entrenamiento automático:** interruptor con `PurchaseController.setAutoTrain` si tiene el pase (`OwnsAutoTrain`).
- [ ] **Huevos:** ahora hay tres (Basic, Gilded y Mythic). Mostrar el precio real (`price` por `EggPriceMultiplier`), las probabilidades de
      cada uno (pesos con su `luck`) y los huevos gratis (`FreeEggs`; el primero es un regalo de bienvenida).
- [ ] Marca visual para quien tiene VIP (`OwnsVip`).

**Más adelante:** icono, miniaturas, trailer y página del juego.

## Luis: lo que sigue de su parte

- [x] Etapa 3 del lado del servidor: renacer, recompensa diaria, clasificación, pases y productos, y analítica.
- [x] Base jugable: mapa gris, vuelo con medición en el servidor, máquinas y dragones de bloques (ver BASE-JUGABLE.md).
- [x] Gacha: simulador con percentiles y pesos de rareza ajustados (primer legendario ~91 min de mediana), y aviso de legendario.
- [x] Pasar el código de `main` al Staging (con `tools/studio/syncFromLocalServer.luau`, sin Rojo) y probar ahí: el servidor sube el
      poder al entrenar, el vuelo paga y regresa al inicio, la barra de distancia sale y los dragones siguen al jugador y llenan el nido.
- [ ] **Probar la E con el teclado de verdad** en una máquina del Staging (con la ventana del juego activa). El aviso aparece y el
      servidor sube el poder, pero la prueba automática no pudo apretar la tecla.
- [ ] Crear en Creator Hub los 6 pases y los 5 productos y pegar sus IDs en `Config/Products.luau`.
- [ ] Probar las compras y la clasificación con el DataStore real en Staging.
- [ ] Volver a correr el simulador con el vuelo real medido en Staging (el simulador supone 30 studs por segundo).
- [ ] Revisar los Pull Requests de Isaac y José y juntarlos en `main`.
- [ ] Publicar en Producción solo lo probado en Staging, con su nota de actualización.
