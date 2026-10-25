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

-- Lo que el servidor le avisa al cliente cuando paga un vuelo (RemoteEvent "GlideResult").
export type GlideResult = {
	distance: number, -- studs pagados, ya recortados al máximo permitido
	coins: number, -- monedas ganadas en este vuelo
	isNewBest: boolean, -- true si superó su mejor distancia
}

local Types = {}

return table.freeze(Types)
