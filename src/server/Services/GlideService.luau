--!strict
-- Dueño: Isaac (medición del vuelo) · Luis (pago con rewardDistance).
--
-- Pendiente de Isaac, Etapa 1:
--   1. Detectar en el servidor cuándo y desde dónde despega cada jugador (zona del acantilado).
--   2. Al aterrizar, medir la distancia EN EL SERVIDOR con la posición del personaje.
--      Nunca usar una distancia que mande el cliente: es lo primero que intenta un tramposo.
--   3. Llamar a GlideService.rewardDistance(player, distancia).
--
-- El RemoteEvent "GlideLanded" ya existe por si el cliente necesita avisar que aterrizó;
-- el servidor igual debe comprobarlo por su cuenta.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Balance = require(ReplicatedStorage.Shared.Config.Balance)
local DataService = require(script.Parent.DataService)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Types = require(ReplicatedStorage.Shared.Types)

local lastRewardAt: { [Player]: number? } = {}

local GlideService = {}

-- Paga un vuelo ya medido por el servidor. Recorta la distancia al máximo posible con el poder
-- actual, para que un error de medición o un exploit no regale monedas.
-- Devuelve lo que se pagó (y se lo avisa al cliente por "GlideResult"), o nil si no se pagó nada.
function GlideService.rewardDistance(player: Player, studs: number): Types.GlideResult?
	if studs ~= studs or studs <= 0 then -- descarta NaN y valores negativos
		return nil
	end

	local now = os.clock()
	local last = lastRewardAt[player]
	if last ~= nil and now - last < Balance.MIN_GLIDE_INTERVAL then
		return nil
	end

	local data = DataService.getData(player)
	if data == nil then
		return nil
	end
	lastRewardAt[player] = now

	local maxStuds = math.max(data.WingPower, 1) * Balance.MAX_GLIDE_STUDS_PER_POWER
	local distance = math.min(studs, maxStuds)
	local coins = math.floor(distance * Balance.COINS_PER_STUD)
	local previousBest = data.BestDistance

	data.Coins += coins
	data.BestDistance = math.max(previousBest, distance)
	DataService.replicate(player)

	local result: Types.GlideResult = {
		distance = distance,
		coins = coins,
		isNewBest = distance > previousBest,
	}
	Remotes.get("GlideResult"):FireClient(player, result)
	return result
end

function GlideService.start()
	Players.PlayerRemoving:Connect(function(player)
		lastRewardAt[player] = nil
	end)
end

return table.freeze(GlideService)
