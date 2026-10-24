--!strict
-- Dueño: Isaac.
-- Pide entrenar al servidor. El cooldown de aquí es solo para que se sienta bien;
-- el que manda es el del servidor (TrainingService).
--
-- Pendiente, Etapa 1: máquinas de entrenamiento en el mapa (ProximityPrompt o tocar la máquina)
-- y animación del personaje al entrenar.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Balance = require(ReplicatedStorage.Shared.Config.Balance)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local trainRemote: RemoteEvent? = nil
local lastTrainAt = 0
local trainedCallbacks: { () -> () } = {}

local TrainingController = {}

function TrainingController.train()
	if trainRemote == nil then
		return
	end

	local now = os.clock()
	if now - lastTrainAt < Balance.TRAIN_COOLDOWN then
		return
	end
	lastTrainAt = now

	trainRemote:FireServer()
	for _, callback in trainedCallbacks do
		task.spawn(callback)
	end
end

-- Para efectos visuales (el "+1" que salta, sonidos). Corre en cada entrenamiento enviado.
function TrainingController.onTrained(callback: () -> ())
	table.insert(trainedCallbacks, callback)
end

function TrainingController.start()
	trainRemote = Remotes.get("Train")
end

return table.freeze(TrainingController)
