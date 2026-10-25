# Qué le toca a cada quien

Estado al 25 de octubre de 2026. Luis dejó listo todo el lado del servidor: datos, entrenamiento, pago del vuelo, huevos, dragones, nido,
ganancias sin conexión, renacer, recompensa diaria, clasificación, compras con Robux y analítica. Todo está probado en Studio y, lo de
las Etapas 1 y 2, también en Staging con guardado real. Lo que sigue es de Isaac y de José.

**Importante:** el servidor ya hace su parte, pero sin mapa ni interfaz casi nada se ve. Por eso lo que falta es de ustedes.

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

## Isaac: gameplay y mundo

**Etapa 1: el bucle principal**
- [ ] Mapa en bloques en Staging: spawn, máquinas de entrenamiento, acantilado y primer reino con marcas de distancia.
- [ ] Máquinas que entrenan: `TrainingController` (ProximityPrompt o tocar la máquina) y animación del personaje.
- [ ] Lanzamiento y planeo en `GlideController` y `GlideService`: detectar el despegue y medir la distancia **en el servidor**
      con la posición del personaje, y llamar a `GlideService.rewardDistance(player, studs)`. Nunca usar una distancia que mande el cliente.

**Etapa 2: dragones**
- [ ] Un modelo por dragón en `ReplicatedStorage.DragonModels`, con el mismo nombre que su `id` de `src/shared/Config/Dragons.luau` (15 ids).
- [ ] Que los dragones equipados sigan al jugador: leer la carpeta `EquippedDragons` del `Player`.
- [ ] Nido: mostrar los dragones que descansan (carpeta `Dragons` menos `EquippedDragons`).
- [ ] Planeo: que el atributo `GlideMultiplier` pueda llevar el planeo hasta `poder × 2 × GlideMultiplier` studs.
- [ ] Huevos en el aire: hablar con Luis si el huevo se abre al instante o se guarda. Hoy, desde el servidor:
      `EggService.hatch(player, "Basic", true)`.

**Etapa 3: reino nuevo y mapa**
- [ ] Nido: solo los 12 mejores dragones en reposo pagan (`Balance.NEST_SLOTS`). Si el nido del mapa tiene otra cantidad de lugares,
      avisar a Luis para igualarlo.
- [ ] Tableros de clasificación en el mapa: leer `ReplicatedStorage.LeaderboardTop` (JSON) y repintar con `.Changed` (ver ETAPA3.md).
- [ ] Reino 2 (desierto de cañones), obstáculos en vuelo y optimización.
- [ ] Reinos: cuando existan, avisar a Luis para activar el producto "saltar de reino" (`SkipRealm`), que hoy está bloqueado.

## José: interfaz, arte y marketing

**Etapa 0 y 1**
- [ ] Dirección de arte, paleta y bocetos (HUD, tienda, inventario). Los colores y espacios van en `src/client/UI/Theme.luau`.
- [ ] HUD: el "+1" que salta (`TrainingController.onTrained`), barra de distancia durante el vuelo y sonidos.
- [ ] Pantalla de resultado al aterrizar: escuchar `Remotes.get("GlideResult")` (`distance`, `coins`, `isNewBest`).
- [ ] Mostrar `BestDistance` con `StatsController.get("BestDistance")`.

**Etapa 2: colección**
- [ ] Eclosión animada con `InventoryController.hatch("Basic")` y `onHatchResult`.
- [ ] Inventario con `InventoryController.owned()` y `equipped()`, y botones de equipar y desequipar.
- [ ] Índice de dragones con `Dragons.LIST` (nombre, rareza, planeo y monedas).
- [ ] Mostrar las probabilidades de `Eggs.RARITY_WEIGHTS` antes de comprar un huevo con Robux (regla de Roblox).
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
- [ ] Crear en Creator Hub los 6 pases y los 5 productos y pegar sus IDs en `Config/Products.luau`.
- [ ] Probar las compras y la clasificación con el DataStore real en Staging.
- [ ] Ajustar el balance (hoy provisional, ver BALANCE.md) con lo que opinen Isaac y José y con el vuelo real.
- [ ] Revisar los Pull Requests de Isaac y José y juntarlos en `main`.
- [ ] Publicar en Producción solo lo probado en Staging, con su nota de actualización.
