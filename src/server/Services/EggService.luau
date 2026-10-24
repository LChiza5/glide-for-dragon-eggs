--!strict
-- Dueño: Luis.
--
-- Pendiente, Etapa 2:
--   1. Lista de dragones por rareza (Config/Dragons.luau) con su bono de planeo y de monedas.
--   2. hatch(player, eggId): cobrar, sortear rareza con rollRarity, elegir dragón, guardar en data.Dragons.
--   3. Equipar dragones (límite de espacios; el pase ExtraDragonSlots suma más).
--   4. Ganancias del nido y ganancias offline al volver a entrar.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Eggs = require(ReplicatedStorage.Shared.Config.Eggs)

local EggService = {}

-- Sortea una rareza según los pesos de Config/Eggs. luckMultiplier > 1 favorece las raras.
function EggService.rollRarity(random: Random, luckMultiplier: number?): Eggs.Rarity
	local luck = luckMultiplier or 1
	local weights = Eggs.RARITY_WEIGHTS

	local total = 0
	for index, entry in weights do
		total += if index == 1 then entry.weight else entry.weight * luck
	end

	local roll = random:NextNumber(0, total)
	for index, entry in weights do
		roll -= if index == 1 then entry.weight else entry.weight * luck
		if roll <= 0 then
			return entry.rarity
		end
	end
	return weights[#weights].rarity
end

-- Se conecta en la Etapa 2.
function EggService.start() end

return table.freeze(EggService)
