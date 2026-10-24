--!strict
-- Dueño: Luis.
-- Cada vez que el cliente pide entrenar, el servidor suma poder de alas. El cliente solo pide;
-- el servidor decide cuánto se suma y con qué frecuencia.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Balance = require(ReplicatedStorage.Shared.Config.Balance)
local DataService = require(script.Parent.DataService)
local MonetizationService = require(script.Parent.MonetizationService)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local lastTrainAt: { [Player]: number? } = {}

local TrainingService = {}

local function onTrain(player: Player)
	local now = os.clock()
	local last = lastTrainAt[player]
	if last ~= nil and now - last < Balance.TRAIN_COOLDOWN then
		return
	end
	lastTrainAt[player] = now

	local data = DataService.getData(player)
	if data == nil then
		return
	end

	data.WingPower += Balance.TRAIN_GAIN * MonetizationService.getPowerMultiplier(player)
	DataService.replicate(player)
end

function TrainingService.start()
	Remotes.get("Train").OnServerEvent:Connect(onTrain)
	Players.PlayerRemoving:Connect(function(player)
		lastTrainAt[player] = nil
	end)
end

return table.freeze(TrainingService)
