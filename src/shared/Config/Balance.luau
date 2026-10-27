--!strict
-- Números del juego. Si algo se siente lento o rápido, se ajusta aquí, no dentro de los servicios.

local Balance = {
	-- Entrenamiento
	TRAIN_GAIN = 1, -- poder de alas por cada entrenamiento
	TRAIN_COOLDOWN = 0.2, -- segundos mínimos entre entrenamientos (el servidor lo hace cumplir)

	-- Planeo
	COINS_PER_STUD = 0.15, -- monedas por cada stud planeado
	MAX_GLIDE_STUDS_PER_POWER = 2, -- tope anti-trampas: distancia máxima por punto de poder
	MIN_GLIDE_INTERVAL = 3, -- segundos mínimos entre dos aterrizajes pagados

	-- Vuelo: cómo se siente (GlideController, en el cliente). Isaac ajusta el feel aquí.
	GLIDE_EFFICIENCY = 0.9, -- fracción del tope de distancia que logra un planeo recto, sin hacer nada
	GLIDE_TARGET_SECONDS = 14, -- lo que dura, más o menos, un vuelo largo (la velocidad se ajusta a esto)
	GLIDE_MIN_SPEED = 30, -- velocidad horizontal mínima del planeo (studs por segundo)
	GLIDE_MAX_SPEED = 160, -- velocidad horizontal máxima del planeo (el servidor la hace cumplir)
	GLIDE_TURN_RATE = 2, -- radianes por segundo que gira siguiendo la cámara
	GLIDE_LAUNCH_BOOST = 40, -- impulso hacia arriba al despegar (studs por segundo)
	GLIDE_LAUNCH_BOOST_SECONDS = 0.5,
	GLIDE_MIN_SINK = 4, -- caída mínima por segundo mientras planea
	GLIDE_MAX_SINK = 120, -- caída máxima por segundo (al terminarse el planeo baja en picada)

	-- Vuelo: anti-trampas (GlideService, en el servidor). El servidor mide el despegue y el aterrizaje.
	GLIDE_CHECK_INTERVAL = 0.1, -- segundos entre dos revisiones de la posición de cada jugador en vuelo
	GLIDE_SPEED_TOLERANCE = 1.5, -- margen sobre GLIDE_MAX_SPEED y GLIDE_LAUNCH_BOOST antes de llamarlo teletransporte
	GLIDE_SPEED_MARGIN = 12, -- studs extra que se perdonan en cada revisión (lag)
	MAX_FLIGHT_SECONDS = 180, -- un vuelo más largo que esto se cancela sin pago
	MIN_FLIGHT_SECONDS = 0.3, -- un "aterrizaje" antes de esto no cuenta
	GLIDE_RETURN_DELAY = 3, -- segundos tras aterrizar antes de volver al inicio

	-- Dragones
	BASE_DRAGON_SLOTS = 3, -- dragones que puede llevar equipados (el pase ExtraDragonSlots suma más)
	EGG_ACTION_COOLDOWN = 0.25, -- segundos mínimos entre dos pedidos de eclosionar o equipar
	NEST_TICK = 1, -- cada cuántos segundos el nido paga sus monedas
	NEST_SLOTS = 12, -- cuántos dragones en reposo pagan (los mejores); el resto solo se colecciona
	EGG_PRICE_STEP = 0.05, -- cada huevo pagado con monedas sube 5 % el precio de todos (el precio base es el de Config/Eggs)

	-- Renacer
	REBIRTH_BASE_POWER = 1_000, -- poder que pide el primer renacer
	REBIRTH_POWER_GROWTH = 1.6, -- cada renacer pide 1.6 veces el poder del anterior
	REBIRTH_BONUS = 0.5, -- cada renacer suma +50 % al poder que se gana al entrenar
	REBIRTH_COOLDOWN = 1, -- segundos mínimos entre dos pedidos de renacer

	-- Clasificación
	LEADERBOARD_SIZE = 50, -- puestos que se publican
	LEADERBOARD_REFRESH = 60, -- segundos entre guardar las marcas nuevas y volver a leer el Top

	-- Monetización
	DOUBLE_POWER_MULTIPLIER = 2, -- pase DoublePower: poder por entrenamiento
	AUTO_TRAIN_INTERVAL = 1, -- pase AutoTrain: segundos entre entrenamientos automáticos
	VIP_COIN_MULTIPLIER = 1.25, -- pase Vip: monedas de vuelos y nido
	EXTRA_DRAGON_SLOTS = 3, -- pase ExtraDragonSlots
	LUCK_PASS_MULTIPLIER = 2, -- pase DoubleLuck
	LUCK_POTION_MULTIPLIER = 2, -- poción de suerte; se multiplica con el pase
	LUCK_POTION_SECONDS = 15 * 60, -- lo que dura cada poción (se suman si compra otra antes de que termine)
	STARTER_PACK_COINS = 500,
	STARTER_PACK_EGGS = 3, -- huevos gratis del paquete inicial
	EGG_PACK_SMALL = 3, -- huevos gratis del paquete chico
	EGG_PACK_LARGE = 10, -- huevos gratis del paquete grande
	DOUBLE_OFFLINE_FALLBACK_COINS = 200, -- si compra "duplicar" y ya no hay ganancias que repetir
	PURCHASE_HISTORY_LIMIT = 200, -- PurchaseIds que se recuerdan para no entregar dos veces
	PURCHASE_PROMPT_COOLDOWN = 1, -- segundos mínimos entre dos pedidos de compra

	-- Ganancias sin conexión
	OFFLINE_MIN_SECONDS = 60, -- ausencias más cortas que esto no pagan
	OFFLINE_MAX_SECONDS = 8 * 60 * 60, -- tope de horas que se pagan
	OFFLINE_EFFICIENCY = 0.1, -- fracción de lo que el nido pagaría conectado (el producto de duplicar repite lo ganado)
}

return table.freeze(Balance)
