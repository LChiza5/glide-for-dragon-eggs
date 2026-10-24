--!strict
-- IDs de pases y productos de Robux. Se crean en Creator Hub → Monetización y se pegan aquí.
-- 0 = todavía no existe; el código lo trata como "no comprado".

local Products = {
	GamePasses = table.freeze({
		DoublePower = 0, -- x2 poder de alas
		AutoTrain = 0,
		Vip = 0,
		ExtraDragonSlots = 0,
		DoubleLuck = 0,
		FastHatch = 0,
	}),

	DevProducts = table.freeze({
		StarterPack = 0,
		EggPack3 = 0,
		EggPack10 = 0,
		LuckPotion = 0,
		SkipRealm = 0,
	}),
}

return table.freeze(Products)
