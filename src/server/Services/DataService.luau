--!strict
-- Dueño: Luis.
-- Carga y guarda los datos de cada jugador con ProfileStore, que ya trae bloqueo de sesión
-- (si el jugador entra a otro servidor, este suelta sus datos) y guardado al cerrar el servidor.
-- Los demás servicios leen y cambian los datos con getData y luego llaman a replicate.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local ProfileStore = require(ServerScriptService.ServerPackages.ProfileStore)
local Types = require(ReplicatedStorage.Shared.Types)

-- Cambiar este nombre empieza una base de datos nueva: todos pierden su progreso.
local STORE_NAME = "PlayerData_v1"

local TEMPLATE: Types.PlayerData = {
	WingPower = 0,
	Coins = 0,
	Wins = 0,
	Rebirths = 0,
	BestDistance = 0,
	Dragons = {},
	EquippedDragons = {},
	LastSeen = 0,
	LastDailyDay = 0,
	DailyStreak = 0,
	FreeEggs = 0,
	LuckUntil = 0,
	StarterPackBought = false,
	PurchaseHistory = {},
}

local playerStore = ProfileStore.New(STORE_NAME, TEMPLATE)

-- El tipo exacto de perfil que devuelve esta tienda (typeof en un tipo no ejecuta nada).
type Profile = typeof(assert(playerStore:StartSessionAsync("", {})))
local profiles: { [Player]: Profile? } = {}
local loadedCallbacks: { (Player, Types.PlayerData) -> () } = {}

local DataService = {}

-- Los datos en memoria del jugador, o nil si todavía no cargaron (o ya se fue).
function DataService.getData(player: Player): Types.PlayerData?
	local profile = profiles[player]
	return if profile ~= nil then profile.Data else nil
end

-- Publica los stats visibles como atributos del Player y en la tabla de clasificación.
-- Llamarlo después de cambiar WingPower, Coins, Wins o BestDistance.
function DataService.replicate(player: Player)
	local data = DataService.getData(player)
	if data == nil then
		return
	end

	player:SetAttribute("WingPower", data.WingPower)
	player:SetAttribute("Coins", data.Coins)
	player:SetAttribute("Wins", data.Wins)
	player:SetAttribute("BestDistance", data.BestDistance)
	player:SetAttribute("Rebirths", data.Rebirths)

	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats ~= nil then
		local power = leaderstats:FindFirstChild("Power")
		local coins = leaderstats:FindFirstChild("Coins")
		if power ~= nil and power:IsA("NumberValue") then
			power.Value = data.WingPower
		end
		if coins ~= nil and coins:IsA("NumberValue") then
			coins.Value = data.Coins
		end
	end
end

-- Guarda ya los datos del jugador (normalmente se guardan solos cada tanto). Solo para momentos críticos, como una compra
-- con Robux. Espera a que termine el guardado. Devuelve false si no pudo.
function DataService.saveNow(player: Player): boolean
	local profile = profiles[player]
	if profile == nil then
		return false
	end
	local ok = pcall(function()
		profile:Save()
	end)
	return ok
end

-- Corre el callback para cada jugador cuyos datos terminan de cargar.
function DataService.onLoaded(callback: (Player, Types.PlayerData) -> ())
	table.insert(loadedCallbacks, callback)
end

local function createLeaderstats(player: Player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"

	local power = Instance.new("NumberValue")
	power.Name = "Power"
	power.Parent = leaderstats

	local coins = Instance.new("NumberValue")
	coins.Name = "Coins"
	coins.Parent = leaderstats

	leaderstats.Parent = player
end

local function onPlayerAdded(player: Player)
	local profile = playerStore:StartSessionAsync(`{player.UserId}`, {
		Cancel = function()
			return player.Parent ~= Players
		end,
	})

	if profile == nil then
		player:Kick("We couldn't load your data. Please rejoin in a moment.")
		return
	end

	profile:AddUserId(player.UserId)
	profile:Reconcile()
	profile.OnSessionEnd:Connect(function()
		profiles[player] = nil
		player:Kick("Your data was opened in another server. Please rejoin.")
	end)

	if player.Parent ~= Players then
		profile:EndSession()
		return
	end

	profiles[player] = profile
	createLeaderstats(player)
	DataService.replicate(player)

	for _, callback in loadedCallbacks do
		task.spawn(callback, player, profile.Data)
	end
end

local function onPlayerRemoving(player: Player)
	local profile = profiles[player]
	if profile ~= nil then
		profile:EndSession()
	end
	profiles[player] = nil
end

function DataService.start()
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
end

return table.freeze(DataService)
