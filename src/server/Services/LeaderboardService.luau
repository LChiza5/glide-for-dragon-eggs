--!strict
-- Dueño: Luis.
-- Clasificación mundial por mejor distancia, guardada en un OrderedDataStore.
--   - Cada vez que un jugador supera su marca, GlideService avisa con submit y se guarda como mucho una vez por minuto.
--   - Cada minuto se lee el Top y se publica en ReplicatedStorage.LeaderboardTop (un StringValue con JSON) para que la UI
--     y los tableros del mapa lo lean y se actualicen con .Changed. Formato: Types.LeaderboardSnapshot.
--   - Sin acceso a DataStore (por ejemplo, en una copia local de Studio) funciona en memoria, así se puede probar todo.

local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Balance = require(ReplicatedStorage.Shared.Config.Balance)
local Types = require(ReplicatedStorage.Shared.Types)

-- Cambiar este nombre empieza una clasificación nueva, vacía.
local STORE_NAME = "BestDistance_v1"
local BOARD_NAME = "LeaderboardTop"

type Row = { key: string, value: number }

type Store = {
	isMock: boolean,
	-- Sube el valor guardado si el nuevo es mayor. Devuelve false si falló y conviene reintentar.
	raise: (key: string, value: number) -> boolean,
	-- Los `count` mejores, de mayor a menor. nil si falló la lectura.
	top: (count: number) -> { Row }?,
}

local function createMockStore(): Store
	local values: { [string]: number } = {}
	return {
		isMock = true,
		raise = function(key, value)
			values[key] = math.max(values[key] or 0, value)
			return true
		end,
		top = function(count)
			local rows: { Row } = {}
			for key, value in values do
				table.insert(rows, { key = key, value = value })
			end
			table.sort(rows, function(a, b)
				return a.value > b.value
			end)
			while #rows > count do
				table.remove(rows)
			end
			return rows
		end,
	}
end

-- La tienda de verdad si hay acceso a DataStore; si no, la de memoria.
local function createStore(): Store
	local okStore, ordered = pcall(function()
		return DataStoreService:GetOrderedDataStore(STORE_NAME)
	end)
	if okStore then
		local okProbe = pcall(function()
			ordered:GetSortedAsync(false, 1)
		end)
		if okProbe then
			return {
				isMock = false,
				raise = function(key, value)
					local ok, err = pcall(function()
						ordered:UpdateAsync(key, function(old: any): number?
							if typeof(old) == "number" and old >= value then
								return nil -- ya hay una marca igual o mejor: no se escribe
							end
							return value
						end)
					end)
					if not ok then
						warn(`Clasificación: no se pudo guardar {key}: {err}`)
					end
					return ok
				end,
				top = function(count)
					local ok, result = pcall(function()
						return ordered:GetSortedAsync(false, count):GetCurrentPage()
					end)
					if not ok then
						warn(`Clasificación: no se pudo leer el Top: {result}`)
						return nil
					end
					local rows: { Row } = {}
					for _, entry in result :: { { key: string, value: number } } do
						table.insert(rows, { key = entry.key, value = entry.value })
					end
					return rows
				end,
			}
		end
	end
	print("[Clasificación] sin acceso a DataStore: se usa la memoria del servidor")
	return createMockStore()
end

local store: Store = createMockStore() -- se reemplaza en start()
local pending: { [number]: number } = {} -- userId -> mejor distancia todavía sin guardar
local nameCache: { [number]: string } = {}

local LeaderboardService = {}

-- Apunta una marca para guardarla en el próximo guardado. Para un jugador conectado, usar submit.
function LeaderboardService.submitUser(userId: number, distance: number)
	if distance ~= distance or distance <= 0 then
		return
	end
	pending[userId] = math.max(pending[userId] or 0, distance)
end

function LeaderboardService.submit(player: Player, distance: number)
	LeaderboardService.submitUser(player.UserId, distance)
end

-- Guarda lo pendiente. Lo que falle vuelve a la cola.
function LeaderboardService.flush()
	local batch = pending
	pending = {}
	for userId, value in batch do
		if not store.raise(tostring(userId), math.floor(value)) then
			LeaderboardService.submitUser(userId, value)
		end
	end
end

local function nameOf(userId: number): string
	local cached = nameCache[userId]
	if cached ~= nil then
		return cached
	end
	local online = Players:GetPlayerByUserId(userId)
	if online ~= nil then
		nameCache[userId] = online.Name
		return online.Name
	end
	local ok, name = pcall(function()
		return Players:GetNameFromUserIdAsync(userId)
	end)
	local resolved = if ok then name else `Jugador {userId}`
	nameCache[userId] = resolved
	return resolved
end

local function getBoard(): StringValue
	local existing = ReplicatedStorage:FindFirstChild(BOARD_NAME)
	if existing ~= nil and existing:IsA("StringValue") then
		return existing
	end
	local board = Instance.new("StringValue")
	board.Name = BOARD_NAME
	board.Value = HttpService:JSONEncode({ updatedAt = 0, entries = {} })
	board.Parent = ReplicatedStorage
	return board
end

-- Lee el Top y lo publica. Devuelve lo publicado, o nil si la lectura falló y se conserva lo anterior.
function LeaderboardService.refresh(): Types.LeaderboardSnapshot?
	local rows = store.top(Balance.LEADERBOARD_SIZE)
	if rows == nil then
		return nil
	end

	local entries: { Types.LeaderboardEntry } = {}
	for index, row in rows do
		local userId = tonumber(row.key)
		if userId ~= nil then
			table.insert(
				entries,
				{ rank = index, userId = userId, name = nameOf(userId), distance = row.value }
			)
		end
	end

	local snapshot: Types.LeaderboardSnapshot = { updatedAt = os.time(), entries = entries }
	getBoard().Value = HttpService:JSONEncode(snapshot)
	return snapshot
end

function LeaderboardService.isMock(): boolean
	return store.isMock
end

function LeaderboardService.start()
	store = createStore()
	getBoard()

	Players.PlayerRemoving:Connect(function(player)
		local value = pending[player.UserId]
		if value ~= nil then
			pending[player.UserId] = nil
			if not store.raise(tostring(player.UserId), math.floor(value)) then
				LeaderboardService.submitUser(player.UserId, value)
			end
		end
	end)

	game:BindToClose(function()
		LeaderboardService.flush()
	end)

	task.spawn(function()
		LeaderboardService.refresh()
		while true do
			task.wait(Balance.LEADERBOARD_REFRESH)
			LeaderboardService.flush()
			LeaderboardService.refresh()
		end
	end)
end

return table.freeze(LeaderboardService)
