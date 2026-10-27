--!strict
-- Dueño: Luis (base) · Isaac (modelos finales y animaciones).
-- Muestra los dragones solo en el cliente (no cuesta nada al servidor):
--   Seguidores: los de la carpeta EquippedDragons de cada jugador vuelan detrás de su personaje.
--   Nido: los dragones del jugador local que descansan y pagan (los mejores Balance.NEST_SLOTS, igual que EggService)
--         se paran sobre las partes con la etiqueta "NestSlot" (atributo Slot = 1, 2, 3…).
-- Modelos: ReplicatedStorage.DragonModels, un Model por id de Config/Dragons. Si falta uno se salta sin error.

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Balance = require(ReplicatedStorage.Shared.Config.Balance)
local Dragons = require(ReplicatedStorage.Shared.Config.Dragons)

local NEST_TAG = "NestSlot"
local WAIT_TIMEOUT = 10
local FOLLOW_SPEED = 8 -- qué tan rápido alcanzan su lugar (más = más pegados)
local FOLLOW_SIDE = 4 -- studs a cada lado del personaje (el primero a la izquierda, el segundo a la derecha…)
local FOLLOW_SPACING = 3 -- studs extra hacia afuera y hacia atrás por cada par
local FOLLOW_BEHIND = 1
local FOLLOW_HEIGHT = 2.5
local BOB_HEIGHT = 0.5
local BOB_SPEED = 2

type Counts = { [string]: number }
type Follower = { model: Model, index: number }

local container: Folder? = nil
local followers: { [Player]: { Follower }? } = {}
local nestModels: { Model } = {}

local DragonController = {}

local function readCounts(folder: Instance?): Counts
	local counts: Counts = {}
	if folder == nil then
		return counts
	end
	for _, child in folder:GetChildren() do
		if child:IsA("IntValue") and child.Value > 0 then
			counts[child.Name] = child.Value
		end
	end
	return counts
end

local function cloneModel(id: string): Model?
	local models = ReplicatedStorage:FindFirstChild("DragonModels")
	local template = if models ~= nil then models:FindFirstChild(id) else nil
	if template == nil or not template:IsA("Model") then
		return nil
	end
	local model = template:Clone()
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored = true
			part.CanCollide = false
			part.CanQuery = false
			part.CanTouch = false
		end
	end
	model.Parent = container
	return model
end

local function clear(models: { Model })
	for _, model in models do
		model:Destroy()
	end
	table.clear(models)
end

-- Lista de ids, uno por copia, del más valioso al menos (por planeo o por monedas).
local function expand(counts: Counts, score: (Dragons.DragonDef) -> number): { string }
	local ids: { string } = {}
	for id, count in counts do
		if Dragons.byId[id] ~= nil then
			for _ = 1, count do
				table.insert(ids, id)
			end
		end
	end
	table.sort(ids, function(a, b)
		return score(Dragons.byId[a]) > score(Dragons.byId[b])
	end)
	return ids
end

local function rebuildFollowers(player: Player)
	local old = followers[player]
	if old ~= nil then
		for _, follower in old do
			follower.model:Destroy()
		end
	end
	local list: { Follower } = {}
	local ids = expand(readCounts(player:FindFirstChild("EquippedDragons")), function(def)
		return def.glideBonus
	end)
	for index, id in ids do
		local model = cloneModel(id)
		if model ~= nil then
			table.insert(list, { model = model, index = index })
		end
	end
	followers[player] = list
end

local function rebuildNest()
	clear(nestModels)
	local player = Players.LocalPlayer
	local owned = readCounts(player:FindFirstChild("Dragons"))
	local equipped = readCounts(player:FindFirstChild("EquippedDragons"))
	local resting: Counts = {}
	for id, count in owned do
		local left = count - (equipped[id] or 0)
		if left > 0 then
			resting[id] = left
		end
	end
	local ids = expand(resting, function(def)
		return def.coinsPerSecond
	end)

	local slots: { BasePart } = {}
	for _, slot in CollectionService:GetTagged(NEST_TAG) do
		if slot:IsA("BasePart") then
			table.insert(slots, slot)
		end
	end
	table.sort(slots, function(a, b)
		local slotA = a:GetAttribute("Slot")
		local slotB = b:GetAttribute("Slot")
		return (if typeof(slotA) == "number" then slotA else math.huge)
			< (if typeof(slotB) == "number" then slotB else math.huge)
	end)

	for index = 1, math.min(#ids, #slots, Balance.NEST_SLOTS) do
		local model = cloneModel(ids[index])
		if model ~= nil then
			local slot = slots[index]
			local _, size = model:GetBoundingBox()
			model:PivotTo(slot.CFrame * CFrame.new(0, slot.Size.Y / 2 + size.Y / 2, 0))
			table.insert(nestModels, model)
		end
	end
end

-- Llama a `onChange` cuando cambia cualquier IntValue de la carpeta `folderName` del jugador (también si la carpeta llega tarde).
local function watchFolder(player: Player, folderName: string, onChange: () -> ())
	task.spawn(function()
		local folder = player:WaitForChild(folderName, WAIT_TIMEOUT)
		if folder == nil then
			return
		end
		local function watchValue(child: Instance)
			if child:IsA("IntValue") then
				child.Changed:Connect(onChange)
			end
		end
		for _, child in folder:GetChildren() do
			watchValue(child)
		end
		folder.ChildAdded:Connect(function(child)
			watchValue(child)
			onChange()
		end)
		folder.ChildRemoved:Connect(onChange)
		onChange()
	end)
end

local function onPlayerAdded(player: Player)
	watchFolder(player, "EquippedDragons", function()
		rebuildFollowers(player)
	end)
	if player == Players.LocalPlayer then
		watchFolder(player, "Dragons", rebuildNest)
		watchFolder(player, "EquippedDragons", rebuildNest)
	end
end

local function onPlayerRemoving(player: Player)
	local list = followers[player]
	if list ~= nil then
		for _, follower in list do
			follower.model:Destroy()
		end
	end
	followers[player] = nil
end

local function follow(dt: number)
	local now = os.clock()
	local alpha = 1 - math.exp(-FOLLOW_SPEED * dt)
	for player, list in followers do
		local character = player.Character
		local root = if character ~= nil then character:FindFirstChild("HumanoidRootPart") else nil
		if list == nil or root == nil or not root:IsA("BasePart") then
			continue
		end
		for _, follower in list do
			-- A los lados del personaje, alternando izquierda y derecha, para no tapar la cámara.
			local pair = (follower.index - 1) // 2
			local direction = if follower.index % 2 == 1 then -1 else 1
			local side = direction * (FOLLOW_SIDE + pair * FOLLOW_SPACING)
			local behind = FOLLOW_BEHIND + pair * FOLLOW_SPACING
			local bob = math.sin(now * BOB_SPEED + follower.index) * BOB_HEIGHT
			local goal = root.CFrame * CFrame.new(side, FOLLOW_HEIGHT + bob, behind)
			local pivot = follower.model:GetPivot()
			follower.model:PivotTo(pivot:Lerp(goal, alpha))
		end
	end
end

function DragonController.start()
	local folder = Instance.new("Folder")
	folder.Name = "ClientDragons"
	folder.Parent = Workspace
	container = folder

	-- Los modelos llegan con ReplicatedStorage; si tardan, se vuelve a pintar todo cuando estén.
	task.spawn(function()
		if ReplicatedStorage:WaitForChild("DragonModels", WAIT_TIMEOUT) == nil then
			warn("Falta ReplicatedStorage.DragonModels: los dragones no se van a ver")
			return
		end
		for _, player in Players:GetPlayers() do
			rebuildFollowers(player)
		end
		rebuildNest()
	end)
	CollectionService:GetInstanceAddedSignal(NEST_TAG):Connect(rebuildNest)

	for _, player in Players:GetPlayers() do
		onPlayerAdded(player)
	end
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	RunService.RenderStepped:Connect(follow)
end

return table.freeze(DragonController)
