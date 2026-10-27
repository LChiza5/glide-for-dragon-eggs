--!strict
-- Dueño: Luis (base) · Isaac (animación del personaje al entrenar).
-- Pide entrenar al servidor. El cooldown de aquí es solo para que se sienta bien;
-- el que manda es el del servidor (TrainingService).
-- Máquinas: cualquier parte o modelo con la etiqueta "TrainingMachine" y un ProximityPrompt dentro.
-- Mientras se mantiene presionada la tecla del prompt, entrena a la velocidad que permite el servidor.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Balance = require(ReplicatedStorage.Shared.Config.Balance)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local trainRemote: RemoteEvent? = nil
local lastTrainAt = 0
local trainedCallbacks: { () -> () } = {}
local holdToken = 0 -- cambia cada vez que empieza o termina un "mantener presionado"
local holding = false
local bound: { [ProximityPrompt]: boolean? } = {}

local MACHINE_TAG = "TrainingMachine"
local HOLD_INTERVAL = Balance.TRAIN_COOLDOWN * 1.05 -- un poco más lento que el servidor para que no descarte pedidos

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

local function stopHolding()
	holding = false
	holdToken += 1
end

local function startHolding()
	holding = true
	holdToken += 1
	local token = holdToken
	task.spawn(function()
		while holdToken == token do
			TrainingController.train()
			task.wait(HOLD_INTERVAL)
		end
	end)
end

local function bindPrompt(prompt: ProximityPrompt)
	if bound[prompt] then
		return
	end
	bound[prompt] = true
	prompt.Triggered:Connect(startHolding)
	prompt.TriggerEnded:Connect(stopHolding)
	prompt.PromptHidden:Connect(stopHolding)
	prompt.Destroying:Connect(function()
		bound[prompt] = nil
		stopHolding()
	end)
end

local function bindMachine(machine: Instance)
	if machine:IsA("ProximityPrompt") then
		bindPrompt(machine)
	end
	for _, descendant in machine:GetDescendants() do
		if descendant:IsA("ProximityPrompt") then
			bindPrompt(descendant)
		end
	end
	-- Con streaming el prompt puede llegar después que la máquina.
	machine.DescendantAdded:Connect(function(descendant)
		if descendant:IsA("ProximityPrompt") then
			bindPrompt(descendant)
		end
	end)
end

-- true mientras se mantiene presionada una máquina (para la animación de Isaac).
function TrainingController.isHolding(): boolean
	return holding
end

function TrainingController.start()
	trainRemote = Remotes.get("Train")
	for _, machine in CollectionService:GetTagged(MACHINE_TAG) do
		bindMachine(machine)
	end
	CollectionService:GetInstanceAddedSignal(MACHINE_TAG):Connect(bindMachine)
end

return table.freeze(TrainingController)
