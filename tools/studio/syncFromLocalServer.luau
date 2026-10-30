--!strict
-- Copia el código del repo al lugar abierto en Studio sin Rojo.
-- Antes: en la carpeta src del repo, `python -m http.server 8765 --bind 127.0.0.1` (solo lectura).
-- Luego pegar este archivo en run_code (modo edición). Sigue default.project.json:
--   src/shared -> ReplicatedStorage.Shared
--   src/server -> ServerScriptService.Server (Script)
--   src/client -> StarterPlayer.StarterPlayerScripts.Client (LocalScript)
-- Los Packages no se tocan.

local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")

local BASE = "http://127.0.0.1:8765/"

-- Lista de archivos que se copian (rutas dentro de src)
local FILES = {
	"shared/Remotes.luau",
	"shared/Types.luau",
	"shared/formatNumber.luau",
	"shared/Config/Balance.luau",
	"shared/Config/Daily.luau",
	"shared/Config/Dragons.luau",
	"shared/Config/Eggs.luau",
	"shared/Config/Products.luau",
	"server/init.server.luau",
	"server/Services/DailyService.luau",
	"server/Services/DataService.luau",
	"server/Services/EggService.luau",
	"server/Services/GlideService.luau",
	"server/Services/LeaderboardService.luau",
	"server/Services/MetricsService.luau",
	"server/Services/MonetizationService.luau",
	"server/Services/RebirthService.luau",
	"server/Services/TrainingService.luau",
	"client/init.client.luau",
	"client/Controllers/DragonController.luau",
	"client/Controllers/GlideController.luau",
	"client/Controllers/InventoryController.luau",
	"client/Controllers/PurchaseController.luau",
	"client/Controllers/StatsController.luau",
	"client/Controllers/TrainingController.luau",
	"client/UI/GlideDistanceBar.luau",
	"client/UI/Hud.luau",
	"client/UI/Theme.luau",
}

local ROOTS: { [string]: { parent: Instance, name: string, className: string } } = {
	shared = { parent = ReplicatedStorage, name = "Shared", className = "Folder" },
	server = { parent = ServerScriptService, name = "Server", className = "Script" },
	client = {
		parent = StarterPlayer:WaitForChild("StarterPlayerScripts"),
		name = "Client",
		className = "LocalScript",
	},
}

local function ensure(parent: Instance, name: string, className: string): Instance
	local existing = parent:FindFirstChild(name)
	if existing ~= nil and existing.ClassName == className then
		return existing
	end
	local created = Instance.new(className)
	created.Name = name
	if existing ~= nil then
		-- Cambió de tipo: pasar los hijos al nuevo antes de borrar el viejo
		for _, child in existing:GetChildren() do
			child.Parent = created
		end
		existing:Destroy()
	end
	created.Parent = parent
	return created
end

local function setSource(target: Instance, source: string)
	if target:IsA("LuaSourceContainer") then
		(target :: any).Source = source
	end
end

for _, path in FILES do
	local parts = string.split(path, "/")
	local root = ROOTS[parts[1]]
	local node = ensure(root.parent, root.name, root.className)
	for i = 2, #parts - 1 do
		node = ensure(node, parts[i], "Folder")
	end
	local fileName = parts[#parts]
	local source = HttpService:GetAsync(BASE .. path, true)
	if string.find(fileName, "^init%.") ~= nil then
		setSource(node, source)
	else
		local name = string.gsub(fileName, "%.luau$", "")
		setSource(ensure(node, name, "ModuleScript"), source)
	end
	print(`copiado {path} ({#source} bytes)`)
end

print("listo")
