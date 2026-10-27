# Balance de la economía (Etapa 2)

Los números del juego salen de un simulador que lee `src/shared/Config/` y mide cuánto tarda un jugador en llegar a cada hito.
Los resultados dependen de supuestos sobre el vuelo (ver abajo), así que son **provisionales** hasta que exista el planeo real.

```bash
node tools/balance/simulate.mjs 3          # 3 horas simuladas, 200 jugadores por perfil
node tools/balance/simulate.mjs 3 --set NEST_SLOTS=8 --set EGG_PRICE_STEP=0.07   # probar valores sin tocar Config
node tools/balance/simulate.mjs 3 --eggs "Basic:100:1,Gilded:4000:2" --cps 0.5   # huevos propios, dragones que pagan la mitad
node tools/balance/simulate.mjs 3 --weights "Common:63,Uncommon:26,Rare:8,Epic:2.3,Legendary:0.7"   # probar pesos de rareza
```

Los huevos son tiradas independientes, **sin garantías ni "pity"**: a un jugador con suerte le puede salir un legendario en la primera.
Por eso el simulador da tres columnas por hito: **p10** (el 10 % con más suerte llega antes), **p50** (la mediana) y **p90** (el 10 % con
menos suerte llega después). También dice qué rarezas tiene cada jugador a los 12 minutos (la primera sesión) y cuenta el huevo
de regalo (un Basic).

## Qué se encontró

Con los números originales (huevo fijo en 100 monedas y un nido que paga por cada dragón sin límite), la economía crecía
**de forma exponencial**: cada dragón pagaba para comprar más huevos. Un jugador activo tenía unos 1.000 dragones a los 30 minutos,
el nido pagaba 680 monedas por segundo y el primer legendario salía a los 20 minutos.

## Qué se cambió

| Cambio | Dónde | Por qué |
|---|---|---|
| Solo los **12 mejores dragones en reposo** pagan en el nido | `Balance.NEST_SLOTS` | Coleccionar más no hace crecer el ingreso sin límite |
| El precio de los huevos **sube 5 %** por cada huevo pagado con monedas | `Balance.EGG_PRICE_STEP` | Frena el ritmo de eclosión con el tiempo |
| Tres huevos: **Basic** 100, **Gilded** 4.000 (suerte x2), **Mythic** 100.000 (suerte x4) | `Config/Eggs.luau` | Una meta a largo plazo; los caros dan más rarezas altas |
| Los dragones **pagan una cuarta parte** | `Config/Dragons.luau` | El nido acompaña al vuelo, no lo reemplaza |
| Monedas por stud **0,10 → 0,15** | `Balance.COINS_PER_STUD` | Que los primeros minutos den huevos rápido |
| Ganancias sin conexión **50 % → 10 %** | `Balance.OFFLINE_EFFICIENCY` | 8 horas fuera eran demasiado; "duplicar" repite lo ganado |
| **Huevo de regalo** al empezar | `FreeEggs = 1` en `DataService` | El primer dragón llega en segundos |

## Cómo queda el ritmo (mediana, 3 horas simuladas)

| Hito | Jugador activo | Jugador casual |
|---|---|---|
| Primer huevo comprado | 2 min 54 s | 4 min 50 s |
| Primer Uncommon | 5 min | 9 min |
| Primer Rare | 8 min 30 s | 14 min 35 s |
| Primer Epic | 21 min | 31 min |
| Primer Legendary | 52 min (86 % lo logra en 3 h) | 63 min (82 %) |
| Primer renacer | 8 min 40 s | 15 min 40 s |
| Huevos a la hora | 61 | 45 |
| Ganancia de 8 h fuera tras la hora 1 | ~10.400 monedas | ~8.300 monedas |

Supuestos del jugador simulado: activo = 4,5 clics por segundo y logra el 70 % del tope de distancia; casual = 2 clics por segundo y el 50 %.
Cada vuelo gasta 15 a 20 s fijos más la distancia a 30 studs por segundo, y se entrena 30 a 45 s entre vuelos. Si el vuelo real es
más lento, más corto o más difícil, **los tiempos cambian**: hay que volver a correr el simulador con los números medidos.

## Metas y palancas

| Si pasa esto | Mover |
|---|---|
| El primer legendario sale demasiado pronto (hoy ~52 min, la meta es más de 90) | subir `EGG_PRICE_STEP` (0,07) o el precio de Gilded |
| Los primeros 10 minutos se sienten lentos | bajar el precio de Basic o subir `COINS_PER_STUD` |
| El nido pesa más que volar | bajar los `coinsPerSecond` o `NEST_SLOTS` |
| El renacer llega demasiado pronto o tarde | `REBIRTH_BASE_POWER`, `REBIRTH_POWER_GROWTH` y `REBIRTH_BONUS` |

## Qué afecta a Isaac y a José

- **José:** la UI de eclosión debe mostrar el precio real (`price` del huevo por el atributo `EggPriceMultiplier`) y mostrar las probabilidades
  de cada huevo (pesos de `Eggs.RARITY_WEIGHTS` con la suerte `luck` del huevo). Ya hay tres huevos para listar.
- **Isaac:** el nido solo paga con los 12 mejores dragones en reposo; el resto se coleccionan. Si el nido físico tiene menos espacios,
  conviene bajar `Balance.NEST_SLOTS` a la misma cantidad.
