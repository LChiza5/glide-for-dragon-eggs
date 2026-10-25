--!strict
-- Catálogo de dragones. Está en Shared porque la UI (inventario, índice) y los modelos lo leen igual que el servidor.
-- Agregar un dragón = una línea aquí + un modelo con el mismo `id` (ver docs/EQUIPO.md).
-- Los números salen del simulador (tools/balance/simulate.mjs) y son provisionales: se revisan cuando exista el vuelo real.

local Eggs = require(script.Parent.Eggs)

export type DragonDef = {
	id: string, -- también es el nombre del modelo
	name: string, -- el que ve el jugador
	rarity: Eggs.Rarity,
	glideBonus: number, -- suma al multiplicador de planeo mientras está equipado (0.05 = +5 %)
	coinsPerSecond: number, -- monedas por segundo mientras descansa en el nido (no equipado)
}

-- Por rareza hay uno que da más planeo, uno parejo y uno que da más monedas.
local LIST: { DragonDef } = {
	{
		id = "PebbleDrake",
		name = "Pebble Drake",
		rarity = "Common",
		glideBonus = 0.02,
		coinsPerSecond = 0.05,
	},
	{
		id = "MeadowWyrmling",
		name = "Meadow Wyrmling",
		rarity = "Common",
		glideBonus = 0.025,
		coinsPerSecond = 0.04,
	},
	{ id = "DustyWhelp", name = "Dusty Whelp", rarity = "Common", glideBonus = 0.015, coinsPerSecond = 0.06 },

	{ id = "MistWisp", name = "Mist Wisp", rarity = "Uncommon", glideBonus = 0.04, coinsPerSecond = 0.15 },
	{
		id = "CopperScale",
		name = "Copper Scale",
		rarity = "Uncommon",
		glideBonus = 0.05,
		coinsPerSecond = 0.11,
	},
	{
		id = "RiverDrake",
		name = "River Drake",
		rarity = "Uncommon",
		glideBonus = 0.03,
		coinsPerSecond = 0.19,
	},

	{ id = "StormGlider", name = "Storm Glider", rarity = "Rare", glideBonus = 0.1, coinsPerSecond = 0.28 },
	{ id = "FrostFang", name = "Frost Fang", rarity = "Rare", glideBonus = 0.08, coinsPerSecond = 0.38 },
	{ id = "EmberWing", name = "Ember Wing", rarity = "Rare", glideBonus = 0.06, coinsPerSecond = 0.48 },

	{ id = "ThunderWyrm", name = "Thunder Wyrm", rarity = "Epic", glideBonus = 0.19, coinsPerSecond = 0.75 },
	{ id = "AuroraDrake", name = "Aurora Drake", rarity = "Epic", glideBonus = 0.15, coinsPerSecond = 1 },
	{
		id = "ObsidianTerror",
		name = "Obsidian Terror",
		rarity = "Epic",
		glideBonus = 0.11,
		coinsPerSecond = 1.25,
	},

	{
		id = "SunfireSovereign",
		name = "Sunfire Sovereign",
		rarity = "Legendary",
		glideBonus = 0.38,
		coinsPerSecond = 1.9,
	},
	{
		id = "StarlightLeviathan",
		name = "Starlight Leviathan",
		rarity = "Legendary",
		glideBonus = 0.3,
		coinsPerSecond = 2.5,
	},
	{
		id = "EternalVoidwing",
		name = "Eternal Voidwing",
		rarity = "Legendary",
		glideBonus = 0.22,
		coinsPerSecond = 3.1,
	},
}

local byId: { [string]: DragonDef } = {}
local byRarity: { [Eggs.Rarity]: { DragonDef } } = {
	Common = {},
	Uncommon = {},
	Rare = {},
	Epic = {},
	Legendary = {},
}

for _, def in LIST do
	table.freeze(def)
	byId[def.id] = def
	table.insert(byRarity[def.rarity], def)
end
for _, group in byRarity do
	table.freeze(group)
end

local Dragons = {
	LIST = table.freeze(LIST), -- en orden, de la más común a la más rara (para el índice)
	byId = table.freeze(byId),
	byRarity = table.freeze(byRarity),
}

return table.freeze(Dragons)
