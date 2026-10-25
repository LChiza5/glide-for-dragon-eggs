--!strict
-- Dueño: Luis.
-- Copia local de los stats del jugador. El servidor los publica como atributos del Player;
-- aquí se convierten en estados de Fusion para que la UI se actualice sola.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Types = require(ReplicatedStorage.Shared.Types)

local scope = Fusion.scoped(Fusion)

local values: { [Types.StatName]: Fusion.Value<number> } = {
	WingPower = scope:Value(0),
	Coins = scope:Value(0),
	Wins = scope:Value(0),
	BestDistance = scope:Value(0),
	GlideMultiplier = scope:Value(1),
	NestRate = scope:Value(0),
	DragonSlots = scope:Value(0),
	OfflineCoins = scope:Value(0),
	OfflineSeconds = scope:Value(0),
	Rebirths = scope:Value(0),
	RebirthMultiplier = scope:Value(1),
	RebirthCost = scope:Value(0),
	DailyReady = scope:Value(0),
	DailyStreak = scope:Value(0),
	DailyReward = scope:Value(0),
	DailyResetAt = scope:Value(0),
}

local StatsController = {}

-- Estado reactivo de un stat. Usarlo en la UI con use(...) dentro de un Computed.
function StatsController.get(name: Types.StatName): Fusion.Value<number>
	return values[name]
end

function StatsController.start()
	local player = Players.LocalPlayer
	for name, state in values do
		local function sync()
			local raw = player:GetAttribute(name)
			state:set(if typeof(raw) == "number" then raw else 0)
		end
		sync()
		table.insert(scope, player:GetAttributeChangedSignal(name):Connect(sync))
	end
end

return table.freeze(StatsController)
