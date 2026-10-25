--!strict
-- Dueño: Luis.
-- Analítica: el embudo de los primeros minutos y la economía (de dónde sale y a dónde va cada moneda).
-- Todo pasa por AnalyticsService de Roblox y se ve en Creator Hub → Analíticas (Embudos, Economía, Eventos personalizados).
-- Cada llamada va dentro de pcall: la analítica nunca puede romper el juego.
--
-- El embudo: Entered → FirstTrain → FirstFlight → FirstEgg → FirstRebirth. Cada paso se registra una sola vez
-- en la vida de la cuenta (queda anotado en data.FunnelDone), no una vez por sesión.

local AnalyticsService = game:GetService("AnalyticsService")

local DataService = require(script.Parent.DataService)

export type FunnelStep = "Entered" | "FirstTrain" | "FirstFlight" | "FirstEgg" | "FirstRebirth"

-- El orden de esta lista es el número de paso que ve Roblox.
local STEPS: { FunnelStep } = { "Entered", "FirstTrain", "FirstFlight", "FirstEgg", "FirstRebirth" }

local CURRENCY = "Coins"

local Metrics = {}

local function safe(label: string, callback: () -> ())
	local ok = pcall(callback)
	if not ok then
		warn(`Analítica ({label}): no se pudo enviar el evento`)
	end
end

-- Anota que el jugador llegó a este paso del embudo. La primera vez lo envía a Roblox; después no hace nada.
function Metrics.reach(player: Player, step: FunnelStep)
	local data = DataService.getData(player)
	if data == nil or data.FunnelDone[step] == true then
		return
	end
	data.FunnelDone[step] = true

	local number = table.find(STEPS, step)
	if number == nil then
		return
	end
	safe("embudo", function()
		AnalyticsService:LogOnboardingFunnelStepEvent(player, number, step)
	end)
end

-- Monedas que entran. transactionType: "Gameplay", "TimedReward", "Shop", "IAP" u "Onboarding".
function Metrics.coinsGained(player: Player, amount: number, transactionType: string, sku: string?)
	if amount <= 0 then
		return
	end
	local data = DataService.getData(player)
	local balance = if data ~= nil then data.Coins else 0
	safe("economía", function()
		AnalyticsService:LogEconomyEvent(
			player,
			Enum.AnalyticsEconomyFlowType.Source,
			CURRENCY,
			amount,
			balance,
			transactionType,
			sku
		)
	end)
end

-- Monedas que salen.
function Metrics.coinsSpent(player: Player, amount: number, transactionType: string, sku: string?)
	if amount <= 0 then
		return
	end
	local data = DataService.getData(player)
	local balance = if data ~= nil then data.Coins else 0
	safe("economía", function()
		AnalyticsService:LogEconomyEvent(
			player,
			Enum.AnalyticsEconomyFlowType.Sink,
			CURRENCY,
			amount,
			balance,
			transactionType,
			sku
		)
	end)
end

-- Un evento propio, por ejemplo "Hatch" con la rareza como dato extra.
function Metrics.event(player: Player, name: string, value: number?, fields: { [string]: any }?)
	safe(name, function()
		AnalyticsService:LogCustomEvent(player, name, value, fields)
	end)
end

function Metrics.start()
	DataService.onLoaded(function(player)
		Metrics.reach(player, "Entered")
	end)
end

return table.freeze(Metrics)
