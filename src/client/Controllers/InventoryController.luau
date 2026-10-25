--!strict
-- Dueño: Luis.
-- Copia local de los dragones del jugador y los pedidos al servidor. El servidor publica el inventario en las
-- carpetas "Dragons" y "EquippedDragons" del Player (un IntValue por dragón); aquí se convierten en estados de
-- Fusion para que la UI (inventario, índice) se actualice sola. El cliente solo pide: el servidor decide.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Fusion = require(ReplicatedStorage.Packages.Fusion)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Types = require(ReplicatedStorage.Shared.Types)

type Counts = { [string]: number }

local scope = Fusion.scoped(Fusion)
local owned = scope:Value({} :: Counts)
local equipped = scope:Value({} :: Counts)
local hatchCallbacks: { (Types.HatchResult) -> () } = {}

local InventoryController = {}

local function readCounts(folder: Instance): Counts
	local counts: Counts = {}
	for _, child in folder:GetChildren() do
		if child:IsA("IntValue") then
			counts[child.Name] = child.Value
		end
	end
	return counts
end

-- Mantiene `state` al día con la carpeta `folderName` del jugador, aunque la carpeta llegue después.
local function track(player: Player, folderName: string, state: Fusion.Value<Counts>)
	local function watch(folder: Instance)
		local function refresh()
			state:set(readCounts(folder))
		end
		local function hook(child: Instance)
			if child:IsA("IntValue") then
				table.insert(scope, child.Changed:Connect(refresh))
			end
		end

		for _, child in folder:GetChildren() do
			hook(child)
		end
		table.insert(
			scope,
			folder.ChildAdded:Connect(function(child)
				hook(child)
				refresh()
			end)
		)
		table.insert(scope, folder.ChildRemoved:Connect(refresh))
		refresh()
	end

	local existing = player:FindFirstChild(folderName)
	if existing ~= nil then
		watch(existing)
	end
	table.insert(
		scope,
		player.ChildAdded:Connect(function(child)
			if child.Name == folderName then
				watch(child)
			end
		end)
	)
end

-- Dragones que tiene: id -> cantidad.
function InventoryController.owned(): Fusion.Value<Counts>
	return owned
end

-- Dragones equipados: id -> cantidad.
function InventoryController.equipped(): Fusion.Value<Counts>
	return equipped
end

-- Pide eclosionar un huevo (ids en Config/Eggs). La respuesta llega por onHatchResult.
function InventoryController.hatch(eggId: string)
	Remotes.get("Hatch"):FireServer(eggId)
end

function InventoryController.equip(dragonId: string)
	Remotes.get("EquipDragon"):FireServer(dragonId)
end

function InventoryController.unequip(dragonId: string)
	Remotes.get("UnequipDragon"):FireServer(dragonId)
end

-- Para la animación de eclosión: corre cada vez que el servidor responde a un pedido de eclosionar.
function InventoryController.onHatchResult(callback: (Types.HatchResult) -> ())
	table.insert(hatchCallbacks, callback)
end

function InventoryController.start()
	local player = Players.LocalPlayer
	track(player, "Dragons", owned)
	track(player, "EquippedDragons", equipped)

	Remotes.get("HatchResult").OnClientEvent:Connect(function(result: Types.HatchResult)
		for _, callback in hatchCallbacks do
			task.spawn(callback, result)
		end
	end)
end

return table.freeze(InventoryController)
