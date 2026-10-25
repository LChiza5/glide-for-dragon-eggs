--!strict
-- Números del juego. Si algo se siente lento o rápido, se ajusta aquí, no dentro de los servicios.

local Balance = {
	-- Entrenamiento
	TRAIN_GAIN = 1, -- poder de alas por cada entrenamiento
	TRAIN_COOLDOWN = 0.2, -- segundos mínimos entre entrenamientos (el servidor lo hace cumplir)

	-- Planeo
	COINS_PER_STUD = 0.1, -- monedas por cada stud planeado
	MAX_GLIDE_STUDS_PER_POWER = 2, -- tope anti-trampas: distancia máxima por punto de poder
	MIN_GLIDE_INTERVAL = 3, -- segundos mínimos entre dos aterrizajes pagados

	-- Dragones
	BASE_DRAGON_SLOTS = 3, -- dragones que puede llevar equipados (el pase ExtraDragonSlots suma más)
	EGG_ACTION_COOLDOWN = 0.25, -- segundos mínimos entre dos pedidos de eclosionar o equipar
	NEST_TICK = 1, -- cada cuántos segundos el nido paga sus monedas

	-- Renacer
	REBIRTH_BASE_POWER = 1_000, -- poder que pide el primer renacer
	REBIRTH_POWER_GROWTH = 1.6, -- cada renacer pide 1.6 veces el poder del anterior
	REBIRTH_BONUS = 0.5, -- cada renacer suma +50 % al poder que se gana al entrenar
	REBIRTH_COOLDOWN = 1, -- segundos mínimos entre dos pedidos de renacer

	-- Clasificación
	LEADERBOARD_SIZE = 50, -- puestos que se publican
	LEADERBOARD_REFRESH = 60, -- segundos entre guardar las marcas nuevas y volver a leer el Top

	-- Ganancias sin conexión
	OFFLINE_MIN_SECONDS = 60, -- ausencias más cortas que esto no pagan
	OFFLINE_MAX_SECONDS = 8 * 60 * 60, -- tope de horas que se pagan
	OFFLINE_EFFICIENCY = 0.5, -- fracción de lo que el nido pagaría conectado (el producto de duplicar la lleva a 1)
}

return table.freeze(Balance)
