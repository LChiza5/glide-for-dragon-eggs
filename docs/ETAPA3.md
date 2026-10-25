# Etapa 3: renacer, recompensa diaria, clasificación, compras y analítica

Lo que Luis dejó hecho del lado del servidor. Todo se publica como atributos del `Player` (se leen con `StatsController.get(nombre)`)
o con RemoteEvents. Los pedidos del cliente siempre se validan en el servidor; el cliente solo pide.

## Renacer

Cambia todo el poder por un multiplicador permanente del poder por entrenamiento (se conserva lo demás).

- Atributos: `Rebirths`, `RebirthMultiplier` (1, 1.5, 2…), `RebirthCost` (poder que pide el próximo).
- Pedir: `Remotes.get("Rebirth"):FireServer()`. Respuesta: `Remotes.get("RebirthResult")` con `Types.RebirthResult`
  (`ok`, `rebirths`, `multiplier` o `reason`: `NotEnoughPower`, `TooFast`, `NoData`).
- Botón activo cuando `WingPower >= RebirthCost`.

## Recompensa diaria

Los días cambian a medianoche UTC; solo cuenta la hora del servidor.

- Atributos: `DailyReady` (1 o 0), `DailyStreak`, `DailyReward` (monedas del próximo reclamo), `DailyResetAt` (hora del servidor).
- Cuenta regresiva: `DailyResetAt - workspace:GetServerTimeNow()`.
- Pedir: `Remotes.get("ClaimDaily"):FireServer()`. Respuesta: `DailyResult` con `Types.DailyResult` (`coins`, `streak`, `day` 1 a 7).
- El calendario de 7 días está en `Config/Daily.luau` (`Daily.REWARDS`).

## Clasificación por distancia

- `ReplicatedStorage.LeaderboardTop` es un `StringValue` con JSON (`Types.LeaderboardSnapshot`: `updatedAt` y `entries` con
  `rank`, `userId`, `name`, `distance`). Se actualiza cada minuto.
- Para un tablero en el mapa o en la UI: `HttpService:JSONDecode(board.Value)` y volver a pintar con `board.Changed`.

## Compras con Robux

Las claves y su efecto (los IDs se pegan en `Config/Products.luau`; mientras estén en 0 no se ofrece nada):

| Clave | Tipo | Efecto |
|---|---|---|
| `DoublePower` | pase | poder x2 al entrenar |
| `AutoTrain` | pase | entrena solo cada segundo; se enciende y apaga con `PurchaseController.setAutoTrain(bool)` |
| `Vip` | pase | +25 % de monedas de vuelos y nido |
| `ExtraDragonSlots` | pase | +3 espacios de dragón equipado |
| `DoubleLuck` | pase | suerte x2 al eclosionar |
| `FastHatch` | pase | la UI puede saltarse la animación (atributo `OwnsFastHatch`) |
| `StarterPack` | producto, una vez | 500 monedas y 3 huevos gratis |
| `EggPack3`, `EggPack10` | producto | 3 o 10 huevos gratis |
| `LuckPotion` | producto | suerte x2 durante 15 minutos (se suman) |
| `DoubleOffline` | producto | repite las ganancias sin conexión de esta sesión |

- Pedir una compra: `PurchaseController.request("EggPack3")`. El servidor valida y abre la ventana de Roblox. Respuesta en
  `PurchaseController.onResult` (`Types.PurchaseResult`: `NotForSale`, `AlreadyOwned`, `Unavailable`, `TooFast`).
- El resultado de la compra se ve en atributos: `OwnsDoublePower`, `OwnsAutoTrain`, `OwnsVip`, `OwnsExtraDragonSlots`,
  `OwnsDoubleLuck`, `OwnsFastHatch` (1 o 0), `AutoTrainOn`, `LuckUntil` (hora del servidor), `FreeEggs`.
- **Huevos gratis:** `FreeEggs` se gasta antes que las monedas cuando se pide `InventoryController.hatch`, así que la animación de
  eclosión es la misma.
- **Regla de Roblox:** los huevos que se compran con Robux tienen que mostrar sus probabilidades antes de comprar.
- `SkipRealm` no se vende todavía: depende de los reinos de Isaac.

## Huevos y nido (cambios del balance)

- Tres huevos en `Config/Eggs.luau`: `Basic`, `Gilded` y `Mythic`. El precio real es `price x EggPriceMultiplier`.
- El jugador nuevo empieza con 1 huevo gratis (`FreeEggs = 1`).
- El nido solo paga con los 12 mejores dragones en reposo (`Balance.NEST_SLOTS`). Detalle y números en [BALANCE.md](BALANCE.md).

## Pendiente de Luis (a mano en Roblox)

1. Crear en Creator Hub los 6 pases y los 5 productos con sus precios y pegar los IDs en `Config/Products.luau`.
2. Probar las compras en Staging con cuentas de prueba antes de publicar en Producción.
3. Probar la clasificación con el DataStore real en Staging (hoy solo se probó en memoria).
