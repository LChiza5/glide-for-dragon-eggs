# Qué le toca a cada quien

Estado al 24 de octubre de 2026. Luis dejó listos los datos, el entrenamiento, el pago del vuelo, los huevos, los dragones, el nido y las
ganancias sin conexión. Todo está probado en Staging con guardado real. Lo que sigue es de Isaac y de José.

Los contratos exactos (funciones, atributos, eventos) están en [EQUIPO.md](EQUIPO.md), secciones **Contratos entre sistemas**.
Mientras los Pull Requests no se junten en `main`, esas secciones viven en las ramas `feat/api-etapa1` y `feat/huevos`.

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

**Más adelante (Etapa 3 en adelante):** tienda y ofertas, icono, miniaturas, trailer y página del juego.

## Luis: lo que sigue de su parte

- [ ] Revisar y juntar los Pull Requests abiertos.
- [ ] Etapa 3: pases y productos con compra segura, renacer, recompensa diaria y clasificaciones.
- [ ] Balance de probabilidades y economía al cerrar la Etapa 2, con lo que vean jugando los tres.
- [ ] Publicar en Producción solo lo probado en Staging, con su nota de actualización.
