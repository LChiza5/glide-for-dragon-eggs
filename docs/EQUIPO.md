# Equipo, dueños y etapas

## Roles

| Integrante | Rol | Es dueño de |
|---|---|---|
| **Luis** | Líder y sistemas | Datos, economía, huevos y probabilidades, monetización, analítica. Dueño del repo y de las publicaciones. |
| **Isaac** | Gameplay y mundo | Entrenamiento, lanzamiento y planeo, reinos, dragones que te siguen, nido. Modelos en Blender. |
| **José** | Interfaz, arte y marketing | HUD, tienda, inventario, índice de dragones, animaciones de UI, icono, miniaturas, trailer. |

## Dueños por archivo

| Archivo o carpeta | Dueño |
|---|---|
| `src/server/Services/DataService.luau` | Luis |
| `src/server/Services/TrainingService.luau` | Luis |
| `src/server/Services/EggService.luau` | Luis |
| `src/server/Services/MonetizationService.luau` | Luis |
| `src/server/Services/GlideService.luau` | Isaac (medición) · Luis (pago) |
| `src/client/Controllers/StatsController.luau` | Luis |
| `src/client/Controllers/TrainingController.luau` | Isaac |
| `src/client/Controllers/GlideController.luau` | Isaac |
| `src/client/UI/` | José |
| `src/shared/Config/` | Luis (José e Isaac proponen cambios) |
| Mapa y modelos (Team Create) | Isaac |
| Icono, miniaturas, página del juego | José |

## Etapas

En cada etapa los tres trabajan a la vez, en relevo: el primero deja lista la base que usa el siguiente.

| Etapa | 1º | 2º | 3º | Cierre |
|---|---|---|---|---|
| **0 · Preparación** (días 1–3) | **Luis:** Grupo de Roblox, lugares Staging y Producción, este repo, invitar a los dos | **Isaac:** mapa en bloques (spawn, máquinas, acantilado, primer reino con marcas de distancia) | **José:** dirección de arte, paleta, bocetos de HUD, tienda e inventario | **Luis:** todos sincronizan con Rojo y entran a Staging |
| **1 · Bucle principal** (semanas 1–2) | **Luis:** datos, stats, entrenamiento validado en servidor | **Isaac:** lanzamiento y planeo, distancia → recompensa, zonas | **José:** HUD con “+1”, barra de distancia, pantalla de resultado, sonidos | **Luis:** integrar y probar: 5 minutos ya divertidos |
| **2 · Colección** (semanas 3–4) | **Luis:** huevos, rarezas, inventario, equipar, nido, ganancias offline | **Isaac:** huevos en el aire, modelos de dragones, dragón que te sigue, nido | **José:** eclosión animada, inventario, índice, avisos de rareza | **Luis:** balance de probabilidades y economía |
| **3 · Monetización y retención** (semana 5) | **Luis:** pases, productos, compra segura, renacer, recompensa diaria, clasificaciones | **Isaac:** reino 2, obstáculos en vuelo, optimización | **José:** tienda y ofertas, icono, miniaturas, trailer, página del juego | **Luis:** prueba completa de compras en Staging |
| **4 · Lanzamiento suave** (semana 6) | **Isaac:** pruebas con amigos, lista de errores | **José:** pulir primeros 5 minutos y tutorial | **Luis:** analítica (entrar → primer vuelo → primer huevo → renacer) y publicar | **Todos:** primeros anuncios con presupuesto pequeño |
| **5 · Operación** (cada semana) | **Luis (lun):** revisar métricas y decidir la actualización | **Isaac (mar–jue):** reino, evento o mecánica nueva | **José (mar–jue):** UI, cosméticos, miniatura nueva | **Luis:** vie integrar en Staging · sáb publicar |

## Contratos entre sistemas (Etapa 1)

Lo que Luis deja listo para que Isaac y José lo usen sin tocar el código de datos.

### Para Isaac: pagar un vuelo (`GlideService.rewardDistance`)

```luau
local GlideService = require(ServerScriptService.Server.Services.GlideService)
local result = GlideService.rewardDistance(player, studs) -- Types.GlideResult?
```

1. Llamarla **solo desde el servidor**, al aterrizar, con la distancia que mide el servidor
   (posición de despegue contra posición de aterrizaje del personaje). Nunca con un número que mande el cliente.
2. La función se encarga de todo lo demás: descarta valores raros (NaN, cero o negativos), exige
   `MIN_GLIDE_INTERVAL` segundos entre dos pagos, recorta la distancia a `WingPower × MAX_GLIDE_STUDS_PER_POWER`,
   suma las monedas, actualiza `BestDistance`, publica los atributos y avisa al cliente.
3. Devuelve `{ distance, coins, isNewBest }`, o `nil` si no pagó (por ejemplo, por pagar demasiado seguido).
4. Para probarla sin el mapa, en Play desde el servidor:
   `require(game.ServerScriptService.Server.Services.GlideService).rewardDistance(game.Players:GetPlayers()[1], 50)`.
5. Si hace falta otro tope o más monedas por stud, se pide el cambio en `src/shared/Config/Balance.luau`
   (es de Luis; se avisa antes de tocarlo).

### Para José: leer los datos del jugador

- **Stats reactivos** (Fusion): `StatsController.get(nombre)` devuelve un `Fusion.Value<number>`.
  Nombres válidos (`Types.StatName`): `"WingPower"`, `"Coins"`, `"Wins"`, `"BestDistance"`.

  ```luau
  Text = scope:Computed(function(use)
      return formatNumber(use(StatsController.get("BestDistance")))
  end)
  ```

- **Atributos del Player**: son lo mismo, por si algún día hace falta leerlos a mano:
  `Players.LocalPlayer:GetAttribute("WingPower" | "Coins" | "Wins" | "BestDistance")`.
- **Pantalla de resultado al aterrizar**: el servidor manda el RemoteEvent `GlideResult` cada vez que paga un vuelo.

  ```luau
  Remotes.get("GlideResult").OnClientEvent:Connect(function(result: Types.GlideResult)
      -- result.distance (studs), result.coins, result.isNewBest
  end)
  ```

- La tabla de clasificación (`leaderstats`) ya muestra `Power` y `Coins`; no hay que crearla.
- Los números para mostrar siempre pasan por `formatNumber` (`src/shared/formatNumber.luau`).

## Contratos entre sistemas (Etapa 2)

Cómo funcionan los huevos, los dragones y el nido. Todo lo decide el servidor (`EggService`); la UI y los modelos solo lo muestran.

**Reglas del sistema**

- Eclosionar cobra monedas (`Eggs.EGGS[id].price`), sortea la rareza con `Eggs.RARITY_WEIGHTS` y elige un dragón de esa rareza al azar.
- **Equipados** (hasta `DragonSlots`: 3 de base, +3 con el pase): dan planeo y siguen al jugador.
- **En el nido** (los que tiene y no están equipados): pagan `coinsPerSecond` cada uno, también sin conexión.
- Sin conexión paga el 50 %, con un mínimo de 60 s y un máximo de 8 h. Todos los números están en `src/shared/Config/Balance.luau` y `Dragons.luau`.

### Para Isaac: modelos, dragones que siguen y nido

1. **Modelos:** un `Model` por dragón, con el mismo nombre que su `id` en `src/shared/Config/Dragons.luau`
   (15 ids: `PebbleDrake`, `StormGlider`, `SunfireSovereign`…), dentro de `ReplicatedStorage.DragonModels` en Team Create.
   Propuesta: en `ReplicatedStorage` para que José también los use en el inventario con un `ViewportFrame`. Si prefieres otro lugar, avisa.
2. **Dragones que siguen al jugador:** el servidor publica dentro del `Player` la carpeta `EquippedDragons`, con un `IntValue` por dragón
   (nombre = id, valor = cuántos). Crear el modelo cuando aparece o sube el valor y quitarlo cuando baja o desaparece
   (`ChildAdded`, `ChildRemoved` y `Changed`). Si lleva dos iguales, el valor es 2.
3. **Planeo:** el atributo `GlideMultiplier` del `Player` vale 1 sin dragones y sube con cada equipado (1.25 = +25 %).
   El servidor ya sube el tope de lo que paga el vuelo en esa proporción (`poder × 2 × GlideMultiplier`); el planeo del mapa tiene que poder llegar hasta ahí.
4. **Nido:** lo que descansa es la carpeta `Dragons` menos la `EquippedDragons`, id por id. `NestRate` es lo que paga por segundo.
5. **Huevos en el aire:** desde el servidor, `EggService.hatch(player, "Basic", true)` abre un huevo gratis (sin cobrar) y devuelve un `Types.HatchResult`.
   Esa llamada no avisa al cliente: para la animación de José, mandar el resultado con `Remotes.get("HatchResult"):FireClient(player, result)`.
   Pendiente de hablar entre Luis e Isaac: si el huevo del aire se abre al instante o se guarda para después.

### Para José: eclosión, inventario, índice y bienvenida

- **`InventoryController`** (`src/client/Controllers/InventoryController.luau`), todo con estados de Fusion:
  - `InventoryController.owned()` y `.equipped()` devuelven `Fusion.Value<{ [string]: number }>` (id → cantidad). Usarlos con `use(...)` dentro de un `Computed`.
  - `InventoryController.hatch("Basic")`, `.equip(id)` y `.unequip(id)` piden la acción; el servidor decide.
  - `InventoryController.onHatchResult(callback)` recibe un `Types.HatchResult`: `{ ok = true, dragonId, rarity, isNew, coinsSpent }`
    o `{ ok = false, reason }`, donde `reason` es `NotEnoughCoins` ("no te alcanzan las monedas"), `TooFast` (ignorar), `UnknownEgg` o `NoData`.
- **Datos para pintar:** `Eggs.EGGS` (nombre y precio), `Eggs.RARITY_WEIGHTS` (probabilidades, hay que mostrarlas antes de comprar un huevo con Robux)
  y `Dragons.LIST` (índice: `name`, `rarity`, `glideBonus`, `coinsPerSecond`, en orden de la más común a la más rara).
- **Stats nuevos** en `StatsController.get(...)`: `GlideMultiplier`, `NestRate`, `DragonSlots` (para "2/3 equipados"), `OfflineCoins` y `OfflineSeconds`.
- **Pantalla de bienvenida:** si `OfflineCoins` es mayor que 0 al entrar, mostrar "Mientras no estabas, tu nido ganó X monedas" con `OfflineSeconds`.
  Estos dos valores no cambian en toda la sesión, así que basta leerlos una vez al cargar.
- **Reglas para los botones:** no se puede equipar si ya están equipadas todas las copias que tiene ni si `equipped` ya llenó `DragonSlots`.
  Se puede deshabilitar el botón con esos datos, pero el servidor igual lo valida.

### Pendiente de Luis (Etapa 3)

- Que `MonetizationService.getLuckMultiplier` (pase DoubleLuck y poción) y `getExtraDragonSlots` (pase ExtraDragonSlots) devuelvan sus valores reales, y que una compra llame a `EggService.refresh(player)`.
- El producto "duplicar ganancias offline": darle otra vez las mismas monedas que muestra `OfflineCoins`.

## Metas para saber si vamos bien

- Vuelve al día siguiente (D1): 20 % o más
- Sesión promedio: 12 minutos o más
- Me gusta: 90 % o más
- Compra algo: 2–5 % de los jugadores

## El dinero

El juego se publica a nombre del Grupo de Roblox. Los Robux entran al grupo y se reparten con pagos recurrentes por porcentaje, acordados por escrito entre los tres antes de lanzar.
