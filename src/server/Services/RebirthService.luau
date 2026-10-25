--!strict
-- Dueño: Luis.
-- Renacer: el jugador cambia todo su poder de alas por un multiplicador permanente del poder que gana al entrenar.
-- Se conserva todo lo demás (monedas, dragones, mejor distancia). El servidor decide cuándo se puede y cuánto vale.
--
-- Lo que ve el cliente: atributos del Player Rebirths, RebirthMultiplier y RebirthCost (poder que pide el próximo renacer).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Balance = require(ReplicatedStorage.Shared.Config.Balance)
local DataService = require(script.Parent.DataService)
local MetricsService = require(script.Parent.MetricsService)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Types = require(ReplicatedStorage.Shared.Types)

local lastRequestAt: { [Player]: number? } = {}

local RebirthService = {}

-- Multiplicador permanente del poder por entrenamiento: 1 sin renacer, 1.5 con uno, 2 con dos...
function RebirthService.getMultiplier(player: Player): number
	local data = DataService.getData(player)
	if data == nil then
		return 1
	end
	return 1 + Balance.REBIRTH_BONUS * data.Rebirths
end

-- Poder de alas que pide el próximo renacer. Sin datos cargados devuelve infinito: nadie renace sin datos.
function RebirthService.getRequiredPower(player: Player): number
	local data = DataService.getData(player)
	if data == nil then
		return math.huge
	end
	return math.floor(Balance.REBIRTH_BASE_POWER * Balance.REBIRTH_POWER_GROWTH ^ data.Rebirths)
end

local function publish(player: Player)
	local data = DataService.getData(player)
	if data == nil then
		return
	end
	player:SetAttribute("Rebirths", data.Rebirths)
	player:SetAttribute("RebirthMultiplier", RebirthService.getMultiplier(player))
	player:SetAttribute("RebirthCost", RebirthService.getRequiredPower(player))
end

local function fail(reason: Types.RebirthFailure): Types.RebirthResult
	return { ok = false, reason = reason }
end

-- Reinicia el poder y suma un renacer si alcanza. Sin yields: dos pedidos seguidos no pueden cobrar el mismo poder.
function RebirthService.rebirth(player: Player): Types.RebirthResult
	local data = DataService.getData(player)
	if data == nil then
		return fail("NoData")
	end
	if data.WingPower < RebirthService.getRequiredPower(player) then
		return fail("NotEnoughPower")
	end

	data.WingPower = 0
	data.Rebirths += 1
	DataService.replicate(player)
	publish(player)
	MetricsService.reach(player, "FirstRebirth")
	MetricsService.event(player, "Rebirth", data.Rebirths)
	return { ok = true, rebirths = data.Rebirths, multiplier = RebirthService.getMultiplier(player) }
end

function RebirthService.start()
	DataService.onLoaded(publish)
	-- Si algún jugador ya cargó antes de conectarnos (por ejemplo, en Studio), se le publica ahora.
	for _, player in Players:GetPlayers() do
		publish(player)
	end

	Players.PlayerRemoving:Connect(function(player)
		lastRequestAt[player] = nil
	end)

	-- El pedido no lleva parámetros: todo lo que importa lo sabe el servidor.
	Remotes.get("Rebirth").OnServerEvent:Connect(function(player: Player)
		local now = os.clock()
		local last = lastRequestAt[player]
		if last ~= nil and now - last < Balance.REBIRTH_COOLDOWN then
			Remotes.get("RebirthResult"):FireClient(player, fail("TooFast"))
			return
		end
		lastRequestAt[player] = now
		Remotes.get("RebirthResult"):FireClient(player, RebirthService.rebirth(player))
	end)
end

return table.freeze(RebirthService)
