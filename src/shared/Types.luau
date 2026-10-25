--!strict
-- Tipos compartidos entre servidor y cliente.

-- Lo que se guarda de cada jugador. Agregar un campo aquí Y en la plantilla de DataService.
export type PlayerData = {
	WingPower: number,
	Coins: number,
	Wins: number,
	Rebirths: number,
	BestDistance: number,
	Dragons: { [string]: number }, -- id del dragón -> cantidad
	PurchaseHistory: { string }, -- PurchaseIds ya entregados, para no entregar una compra dos veces
}

-- Stats que el servidor publica como atributos del Player para que la UI los lea.
export type StatName = "WingPower" | "Coins" | "Wins" | "BestDistance"

-- Lo que el servidor le avisa al cliente cuando paga un vuelo (RemoteEvent "GlideResult").
export type GlideResult = {
	distance: number, -- studs pagados, ya recortados al máximo permitido
	coins: number, -- monedas ganadas en este vuelo
	isNewBest: boolean, -- true si superó su mejor distancia
}

local Types = {}

return table.freeze(Types)
