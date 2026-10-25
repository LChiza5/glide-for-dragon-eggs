--!strict
-- Dueño: Luis.
-- Cada vez que el cliente pide entrenar, el servidor suma poder de alas. El cliente solo pide;
-- el servidor decide cuánto se suma y con qué frecuencia. Con el pase AutoTrain, el servidor entrena solo
-- cada AUTO_TRAIN_INTERVAL segundos (más lento que un jugador activo).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Balance = require(ReplicatedStorage.Shared.Config.Balance)
local DataService = require(script.Parent.DataService)
local MetricsService = require(script.Parent.MetricsService)
local MonetizationService = require(script.Parent.MonetizationService)
local RebirthService = require(script.Parent.RebirthService)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local lastTrainAt: { [Player]: number? } = {}

local TrainingService = {}

-- Suma un entrenamiento. El límite de velocidad lo pone quien llama.
local function grantTraining(player: Player)
	local data = DataService.getData(player)
	if data == nil then
		return
	end

	local gain = Balance.TRAIN_GAIN * MonetizationService.getPowerMultiplier(player)
	gain *= RebirthService.getMultiplier(player)
	data.WingPower += gain
	DataService.replicate(player)
	MetricsService.reach(player, "FirstTrain")
end

local function onTrain(player: Player)
	local now = os.clock()
	local last = lastTrainAt[player]
	if last ~= nil and now - last < Balance.TRAIN_COOLDOWN then
		return
	end
	lastTrainAt[player] = now
	grantTraining(player)
end

function TrainingService.start()
	Remotes.get("Train").OnServerEvent:Connect(onTrain)
	Players.PlayerRemoving:Connect(function(player)
		lastTrainAt[player] = nil
	end)

	task.spawn(function()
		while true do
			task.wait(Balance.AUTO_TRAIN_INTERVAL)
			for _, player in Players:GetPlayers() do
				if MonetizationService.isAutoTrainOn(player) then
					grantTraining(player)
				end
			end
		end
	end)
end

return table.freeze(TrainingService)
