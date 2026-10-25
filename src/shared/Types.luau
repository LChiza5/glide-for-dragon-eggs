--!strict
-- Tipos compartidos entre servidor y cliente.

local Eggs = require(script.Parent.Config.Eggs)

-- Lo que se guarda de cada jugador. Agregar un campo aquí Y en la plantilla de DataService.
export type PlayerData = {
	WingPower: number,
	Coins: number,
	Wins: number,
	Rebirths: number,
	BestDistance: number,
	Dragons: { [string]: number }, -- id del dragón -> cantidad
	EquippedDragons: { string }, -- ids de los dragones equipados (se repite el id si lleva dos iguales)
	LastSeen: number, -- os.time() de la última vez que el nido pagó; sirve para las ganancias sin conexión
	LastDailyDay: number, -- día UTC (os.time() // 86400) en que reclamó la recompensa diaria por última vez; 0 = nunca
	DailyStreak: number, -- días seguidos reclamados
	EggsPaid: number, -- huevos pagados con monedas; el precio de los huevos sube con este número
	FunnelDone: { [string]: boolean }, -- pasos del embudo de analítica que ya se enviaron (una vez por cuenta)
	FreeEggs: number, -- huevos gratis comprados con Robux; se gastan antes que las monedas
	LuckUntil: number, -- os.time() en que termina la poción de suerte; 0 = sin poción
	StarterPackBought: boolean, -- el paquete inicial solo se vende una vez
	PurchaseHistory: { string }, -- PurchaseIds ya entregados, para no entregar una compra dos veces
}

-- Stats numéricos que el servidor publica como atributos del Player para que la UI los lea.
export type StatName =
	"WingPower"
	| "Coins"
	| "Wins"
	| "BestDistance"
	| "GlideMultiplier" -- 1 = sin bono; 1.25 = +25 % de planeo por los dragones equipados
	| "NestRate" -- monedas por segundo que paga el nido
	| "DragonSlots" -- cuántos dragones puede llevar equipados
	| "OfflineCoins" -- lo que ganó mientras estaba fuera (0 si no ganó nada); queda fijo toda la sesión
	| "OfflineSeconds" -- cuánto tiempo estuvo fuera, ya con el tope aplicado
	| "Rebirths" -- cuántas veces ha renacido
	| "RebirthMultiplier" -- multiplicador permanente del poder por entrenamiento (1 sin renacer)
	| "RebirthCost" -- poder de alas que pide el próximo renacer
	| "DailyReady" -- 1 si puede reclamar la recompensa diaria hoy, 0 si ya la reclamó
	| "DailyStreak" -- racha actual de días seguidos (0 si la perdió)
	| "DailyReward" -- monedas que daría el próximo reclamo
	| "DailyResetAt" -- hora del servidor (segundos) en que cambia el día
	| "EggPriceMultiplier" -- por cuánto se multiplica el precio base de los huevos (1 al empezar)
	| "FreeEggs" -- huevos gratis que puede abrir (de regalo o comprados con Robux)
	| "LuckUntil" -- hora del servidor (segundos) en que termina la poción de suerte; 0 si no hay
	| "AutoTrainOn" -- 1 si el entrenamiento automático está encendido
	| "OwnsDoublePower" -- 1 si tiene el pase, 0 si no (igual para los demás Owns...)
	| "OwnsAutoTrain"
	| "OwnsVip"
	| "OwnsExtraDragonSlots"
	| "OwnsDoubleLuck"
	| "OwnsFastHatch"

-- Por qué no se pudo eclosionar.
export type HatchFailure = "UnknownEgg" | "NotEnoughCoins" | "NoData" | "TooFast"

-- Respuesta del servidor al pedir eclosionar (RemoteEvent "HatchResult").
export type HatchResult =
	{
		ok: true,
		dragonId: string,
		rarity: Eggs.Rarity,
		isNew: boolean, -- true si es la primera vez que consigue ese dragón
		coinsSpent: number,
	}
	| {
		ok: false,
		reason: HatchFailure,
	}

-- Por qué no se mostró la ventana de compra.
export type PurchaseFailure = "NoData" | "TooFast" | "NotForSale" | "AlreadyOwned" | "Unavailable"

-- Respuesta del servidor a un pedido de compra (RemoteEvent "PurchaseResult"). ok = true significa que se mostró
-- la ventana de Roblox; el resultado de la compra llega después como cambio en los atributos del Player.
export type PurchaseResult =
	{
		ok: true,
		key: string,
	}
	| {
		ok: false,
		key: string,
		reason: PurchaseFailure,
	}

-- Un puesto de la clasificación por distancia.
export type LeaderboardEntry = {
	rank: number, -- 1 es el mejor
	userId: number,
	name: string,
	distance: number, -- mejor distancia, en studs
}

-- Lo que guarda ReplicatedStorage.LeaderboardTop (un StringValue) codificado como JSON.
export type LeaderboardSnapshot = {
	updatedAt: number, -- os.time() de la última lectura; 0 si todavía no hubo
	entries: { LeaderboardEntry },
}

-- Por qué no se pudo renacer.
export type RebirthFailure = "NoData" | "NotEnoughPower" | "TooFast"

-- Respuesta del servidor al pedir renacer (RemoteEvent "RebirthResult").
export type RebirthResult =
	{
		ok: true,
		rebirths: number, -- cuántos lleva ya, contando este
		multiplier: number, -- multiplicador nuevo del poder por entrenamiento
	}
	| {
		ok: false,
		reason: RebirthFailure,
	}

-- Por qué no se pudo reclamar la recompensa diaria.
export type DailyFailure = "NoData" | "AlreadyClaimed" | "TooFast"

-- Respuesta del servidor al reclamar la recompensa diaria (RemoteEvent "DailyResult").
export type DailyResult =
	{
		ok: true,
		coins: number, -- monedas recibidas
		streak: number, -- racha después de reclamar
		day: number, -- posición en el ciclo de 7 días (1 a 7)
	}
	| {
		ok: false,
		reason: DailyFailure,
	}

-- Lo que el servidor le avisa al cliente cuando paga un vuelo (RemoteEvent "GlideResult").
export type GlideResult = {
	distance: number, -- studs pagados, ya recortados al máximo permitido
	coins: number, -- monedas ganadas en este vuelo
	isNewBest: boolean, -- true si superó su mejor distancia
}

local Types = {}

return table.freeze(Types)
