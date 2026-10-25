--!strict
-- Recompensa diaria: monedas por día de racha. La racha sube un día cada vez que reclama en días seguidos y vuelve
-- a 1 si se salta un día. Después del último día de la lista, la lista vuelve a empezar (con la racha siguiendo).
-- Está en Shared para que la UI pueda mostrar el calendario completo.

local REWARDS: { number } = { 100, 150, 200, 300, 400, 600, 1000 }

local Daily = {
	REWARDS = table.freeze(REWARDS), -- monedas del día 1 al día 7 del ciclo
}

-- Posición dentro del ciclo (1 a 7) que le toca a una racha: la racha 8 vuelve al día 1.
function Daily.dayInCycle(streak: number): number
	return (math.max(streak, 1) - 1) % #REWARDS + 1
end

-- Monedas que paga reclamar con esa racha.
function Daily.rewardFor(streak: number): number
	return REWARDS[Daily.dayInCycle(streak)]
end

return table.freeze(Daily)
