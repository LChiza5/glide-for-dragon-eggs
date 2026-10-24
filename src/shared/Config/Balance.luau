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
}

return table.freeze(Balance)
