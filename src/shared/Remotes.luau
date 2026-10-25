--!strict
-- Un solo lugar para todos los RemoteEvents. El servidor los crea al arrancar; el cliente los espera.
-- Para agregar uno: sumarlo a RemoteName y a NAMES.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

export type RemoteName =
	"Train"
	| "GlideLanded"
	| "GlideResult"
	| "Hatch"
	| "HatchResult"
	| "EquipDragon"
	| "UnequipDragon"
	| "Rebirth"
	| "RebirthResult"

local NAMES: { RemoteName } = {
	"Train",
	"GlideLanded",
	"GlideResult",
	"Hatch",
	"HatchResult",
	"EquipDragon",
	"UnequipDragon",
	"Rebirth",
	"RebirthResult",
}
local FOLDER_NAME = "Remotes"
local CLIENT_TIMEOUT = 10

local Remotes = {}

function Remotes.setupServer()
	assert(RunService:IsServer(), "Remotes.setupServer solo corre en el servidor")

	local folder = Instance.new("Folder")
	folder.Name = FOLDER_NAME
	for _, name in NAMES do
		local remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = folder
	end
	folder.Parent = ReplicatedStorage
end

function Remotes.get(name: RemoteName): RemoteEvent
	local folder = if RunService:IsServer()
		then ReplicatedStorage:FindFirstChild(FOLDER_NAME)
		else ReplicatedStorage:WaitForChild(FOLDER_NAME, CLIENT_TIMEOUT)
	if folder == nil then
		error(`No existe la carpeta {FOLDER_NAME}; ¿el servidor llamó a Remotes.setupServer()?`)
	end

	local remote = if RunService:IsServer()
		then folder:FindFirstChild(name)
		else folder:WaitForChild(name, CLIENT_TIMEOUT)
	if remote == nil or not remote:IsA("RemoteEvent") then
		error(`No existe el RemoteEvent "{name}"`)
	end
	return remote :: RemoteEvent
end

return table.freeze(Remotes)
