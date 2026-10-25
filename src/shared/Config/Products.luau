--!strict
-- IDs de pases y productos de Robux. Se crean en Creator Hub → Monetización y se pegan aquí.
-- 0 = todavía no existe: el código lo trata como "no está a la venta" y nunca lo ofrece.

export type GamePassKey =
	"DoublePower"
	| "AutoTrain"
	| "Vip"
	| "ExtraDragonSlots"
	| "DoubleLuck"
	| "FastHatch"
export type ProductKey =
	"StarterPack"
	| "EggPack3"
	| "EggPack10"
	| "LuckPotion"
	| "SkipRealm"
	| "DoubleOffline"

-- Todas las claves, en lista, para poder recorrerlas con tipos.
local GAME_PASS_KEYS: { GamePassKey } =
	{ "DoublePower", "AutoTrain", "Vip", "ExtraDragonSlots", "DoubleLuck", "FastHatch" }
local PRODUCT_KEYS: { ProductKey } =
	{ "StarterPack", "EggPack3", "EggPack10", "LuckPotion", "SkipRealm", "DoubleOffline" }

local GamePasses: { [GamePassKey]: number } = table.freeze({
	DoublePower = 0, -- x2 poder de alas al entrenar
	AutoTrain = 0, -- entrena solo, más lento que un jugador activo
	Vip = 0, -- +25 % de monedas de vuelos y nido, y la marca VIP
	ExtraDragonSlots = 0, -- +3 espacios de dragón equipado
	DoubleLuck = 0, -- x2 de suerte al eclosionar
	FastHatch = 0, -- la UI se salta la animación de eclosión
})

local DevProducts: { [ProductKey]: number } = table.freeze({
	StarterPack = 0, -- una sola vez: monedas y huevos gratis
	EggPack3 = 0, -- 3 huevos gratis
	EggPack10 = 0, -- 10 huevos gratis
	LuckPotion = 0, -- x2 de suerte durante 15 minutos
	SkipRealm = 0, -- pendiente: depende de los reinos de Isaac, no se vende todavía
	DoubleOffline = 0, -- repite las ganancias sin conexión de esta sesión
})

local Products = {
	GamePasses = GamePasses,
	DevProducts = DevProducts,
	GamePassKeys = table.freeze(GAME_PASS_KEYS),
	ProductKeys = table.freeze(PRODUCT_KEYS),
}

-- Valida un texto que llega por RemoteEvent: devuelve la clave del pase o nil si no existe.
function Products.asGamePassKey(value: string): GamePassKey?
	for index = 1, #GAME_PASS_KEYS do
		local key: GamePassKey = GAME_PASS_KEYS[index]
		if key == value then
			return key
		end
	end
	return nil
end

-- Igual, para productos.
function Products.asProductKey(value: string): ProductKey?
	for index = 1, #PRODUCT_KEYS do
		local key: ProductKey = PRODUCT_KEYS[index]
		if key == value then
			return key
		end
	end
	return nil
end

-- Qué producto es este ID de Roblox. El 0 nunca coincide.
function Products.productKeyFromId(id: number): ProductKey?
	if id == 0 then
		return nil
	end
	for index = 1, #PRODUCT_KEYS do
		local key: ProductKey = PRODUCT_KEYS[index]
		if DevProducts[key] == id then
			return key
		end
	end
	return nil
end

return table.freeze(Products)
