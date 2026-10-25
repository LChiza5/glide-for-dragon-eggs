--!strict
-- Rarezas y probabilidades de los huevos. Está en Shared a propósito: Roblox exige mostrar las
-- probabilidades antes de comprar un objeto aleatorio con Robux, así que la UI las lee de aquí.

export type Rarity = "Common" | "Uncommon" | "Rare" | "Epic" | "Legendary"

export type RarityWeight = {
	rarity: Rarity,
	weight: number,
}

-- De la más común a la más rara. La suma no tiene que dar 100: son pesos relativos.
local RARITY_WEIGHTS: { RarityWeight } = {
	{ rarity = "Common", weight = 60 },
	{ rarity = "Uncommon", weight = 25 },
	{ rarity = "Rare", weight = 10 },
	{ rarity = "Epic", weight = 4 },
	{ rarity = "Legendary", weight = 1 },
}
for _, entry in RARITY_WEIGHTS do
	table.freeze(entry)
end

export type EggDef = {
	id: string,
	name: string,
	price: number, -- monedas
}

local EGG_LIST: { EggDef } = {
	{ id = "Basic", name = "Dragon Egg", price = 100 },
}

local EGGS: { [string]: EggDef } = {}
for _, egg in EGG_LIST do
	EGGS[egg.id] = table.freeze(egg)
end

local Eggs = {
	RARITY_WEIGHTS = table.freeze(RARITY_WEIGHTS),
	EGGS = table.freeze(EGGS), -- por id; EggService.hatch(player, "Basic")
}

return table.freeze(Eggs)
