--!strict
-- Dueño: Luis.
-- Huevos, dragones y nido. El servidor decide todo: cobrar, sortear, guardar y equipar.
--   Equipados:  dan planeo (getGlideMultiplier) y siguen al jugador (modelos de Isaac).
--   En el nido: los que NO están equipados pagan monedas por segundo, también sin conexión.
--
-- Lo que ve el cliente (todo se replica solo, sin esperar a ningún RemoteEvent):
--   Atributos del Player: GlideMultiplier, NestRate, DragonSlots, OfflineCoins, OfflineSeconds.
--   Carpetas dentro del Player: "Dragons" y "EquippedDragons", con un IntValue por dragón (nombre = id, valor = cantidad).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Balance = require(ReplicatedStorage.Shared.Config.Balance)
local DataService = require(script.Parent.DataService)
local Dragons = require(ReplicatedStorage.Shared.Config.Dragons)
local Eggs = require(ReplicatedStorage.Shared.Config.Eggs)
local MonetizationService = require(script.Parent.MonetizationService)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Types = require(ReplicatedStorage.Shared.Types)

local MAX_ID_LENGTH = 40

local random = Random.new()
local lastActionAt: { [Player]: number? } = {}
local ready: { [Player]: boolean? } = {} -- ya se aplicó lo de la carga (sin conexión, inventario)
local initializing: { [Player]: boolean? } = {} -- se está aplicando ahora mismo

local EggService = {}

local function countOf(list: { string }, id: string): number
	local total = 0
	for _, entry in list do
		if entry == id then
			total += 1
		end
	end
	return total
end

local function slotLimit(player: Player): number
	return Balance.BASE_DRAGON_SLOTS + MonetizationService.getExtraDragonSlots(player)
end

-- Sortea una rareza según los pesos de Config/Eggs. luckMultiplier > 1 favorece las raras.
function EggService.rollRarity(rng: Random, luckMultiplier: number?): Eggs.Rarity
	local luck = luckMultiplier or 1
	local weights = Eggs.RARITY_WEIGHTS

	local total = 0
	for index, entry in weights do
		total += if index == 1 then entry.weight else entry.weight * luck
	end

	local roll = rng:NextNumber(0, total)
	for index, entry in weights do
		roll -= if index == 1 then entry.weight else entry.weight * luck
		if roll <= 0 then
			return entry.rarity
		end
	end
	return weights[#weights].rarity
end

-- Elige un dragón de esa rareza; dentro de la rareza todos tienen la misma probabilidad.
function EggService.pickDragon(rng: Random, rarity: Eggs.Rarity): Dragons.DragonDef
	local group = Dragons.byRarity[rarity]
	assert(#group > 0, "No hay dragones de esa rareza en Config/Dragons")
	return group[rng:NextInteger(1, #group)]
end

-- 1 = sin bono. Cada dragón equipado suma su glideBonus. Lo usa el pago del vuelo y lo lee Isaac para el planeo.
function EggService.getGlideMultiplier(player: Player): number
	local data = DataService.getData(player)
	if data == nil then
		return 1
	end

	local bonus = 0
	for _, id in data.EquippedDragons do
		local def = Dragons.byId[id]
		if def ~= nil then
			bonus += def.glideBonus
		end
	end
	return 1 + bonus
end

-- Monedas por segundo que paga el nido: los dragones que tiene y no lleva equipados.
function EggService.getNestRate(player: Player): number
	local data = DataService.getData(player)
	if data == nil then
		return 0
	end

	local rate = 0
	for id, owned in data.Dragons do
		local def = Dragons.byId[id]
		if def ~= nil then
			local resting = owned - countOf(data.EquippedDragons, id)
			if resting > 0 then
				rate += resting * def.coinsPerSecond
			end
		end
	end
	return rate * MonetizationService.getCoinMultiplier(player)
end

-- Deja la carpeta `folderName` del Player con un IntValue por cada id de `counts`.
local function syncCounts(player: Player, folderName: string, counts: { [string]: number })
	local existing = player:FindFirstChild(folderName)
	local folder: Folder
	if existing ~= nil and existing:IsA("Folder") then
		folder = existing
	else
		folder = Instance.new("Folder")
		folder.Name = folderName
		folder.Parent = player
	end

	for _, child in folder:GetChildren() do
		local count = counts[child.Name]
		if count == nil or count <= 0 then
			child:Destroy()
		end
	end
	for id, count in counts do
		if count > 0 then
			local value = folder:FindFirstChild(id)
			if value ~= nil and value:IsA("IntValue") then
				value.Value = count
			else
				local created = Instance.new("IntValue")
				created.Name = id
				created.Value = count
				created.Parent = folder
			end
		end
	end
end

-- Publica el inventario y lo derivado (planeo, nido, espacios). Llamarlo después de tocar Dragons o EquippedDragons.
local function replicateInventory(player: Player)
	local data = DataService.getData(player)
	if data == nil then
		return
	end

	local equippedCounts: { [string]: number } = {}
	for _, id in data.EquippedDragons do
		equippedCounts[id] = (equippedCounts[id] or 0) + 1
	end

	player:SetAttribute("GlideMultiplier", EggService.getGlideMultiplier(player))
	player:SetAttribute("NestRate", EggService.getNestRate(player))
	player:SetAttribute("DragonSlots", slotLimit(player))
	player:SetAttribute("FreeEggs", data.FreeEggs)
	syncCounts(player, "Dragons", data.Dragons)
	syncCounts(player, "EquippedDragons", equippedCounts)
end

-- Vuelve a publicar atributos e inventario. MonetizationService lo llama cuando una compra cambia los espacios.
function EggService.refresh(player: Player)
	replicateInventory(player)
end

-- Cobra (salvo `free`), sortea y guarda. Es el único camino para conseguir un dragón.
-- `free` es solo para código del servidor (por ejemplo, un huevo recogido en pleno vuelo); ningún RemoteEvent lo manda.
function EggService.hatch(player: Player, eggId: string, free: boolean?): Types.HatchResult
	local egg = Eggs.EGGS[eggId]
	if egg == nil then
		return { ok = false, reason = "UnknownEgg" }
	end

	local data = DataService.getData(player)
	if data == nil then
		return { ok = false, reason = "NoData" }
	end

	-- Sin yields entre comprobar las monedas y cobrarlas: dos pedidos seguidos no pueden gastar las mismas monedas.
	-- Un huevo gratis comprado con Robux (FreeEggs) se gasta antes que las monedas.
	local useToken = free ~= true and data.FreeEggs > 0
	local price = if free == true or useToken then 0 else egg.price
	if data.Coins < price then
		return { ok = false, reason = "NotEnoughCoins" }
	end

	local rarity: Eggs.Rarity = EggService.rollRarity(random, MonetizationService.getLuckMultiplier(player))
	local dragon = EggService.pickDragon(random, rarity)

	data.Coins -= price
	if useToken then
		data.FreeEggs -= 1
	end
	local before = data.Dragons[dragon.id]
	data.Dragons[dragon.id] = (before or 0) + 1

	DataService.replicate(player)
	replicateInventory(player)
	return { ok = true, dragonId = dragon.id, rarity = rarity, isNew = before == nil, coinsSpent = price }
end

-- Equipa un dragón que tenga y que no esté ya equipado en todas sus copias. Devuelve si lo logró.
function EggService.equip(player: Player, dragonId: string): boolean
	local data = DataService.getData(player)
	if data == nil or Dragons.byId[dragonId] == nil then
		return false
	end

	local owned = data.Dragons[dragonId] or 0
	if countOf(data.EquippedDragons, dragonId) >= owned then
		return false
	end
	if #data.EquippedDragons >= slotLimit(player) then
		return false
	end

	table.insert(data.EquippedDragons, dragonId)
	replicateInventory(player)
	return true
end

-- Manda un dragón de vuelta al nido. Devuelve si estaba equipado.
function EggService.unequip(player: Player, dragonId: string): boolean
	local data = DataService.getData(player)
	if data == nil then
		return false
	end

	for index = #data.EquippedDragons, 1, -1 do
		if data.EquippedDragons[index] == dragonId then
			table.remove(data.EquippedDragons, index)
			replicateInventory(player)
			return true
		end
	end
	return false
end

-- Quita de los equipados lo que ya no existe en el catálogo, lo que no tiene y lo que no cabe en los espacios.
local function sanitizeEquipped(player: Player, data: Types.PlayerData)
	local kept: { string } = {}
	local keptCounts: { [string]: number } = {}
	local limit = slotLimit(player)
	for _, id in data.EquippedDragons do
		local used = keptCounts[id] or 0
		if Dragons.byId[id] ~= nil and used < (data.Dragons[id] or 0) and #kept < limit then
			table.insert(kept, id)
			keptCounts[id] = used + 1
		end
	end
	data.EquippedDragons = kept
end

-- Paga lo que el nido ganó mientras el jugador estaba fuera y fija LastSeen para la sesión nueva.
-- Se llama sola al cargar los datos. Es pública para poder probarla; llamarla otra vez no paga nada,
-- porque deja LastSeen en "ahora".
function EggService.applyOffline(player: Player)
	local data = DataService.getData(player)
	if data == nil then
		return
	end

	local now = os.time()
	local away = if data.LastSeen > 0 then now - data.LastSeen else 0
	data.LastSeen = now

	local seconds = 0
	local coins = 0
	if away >= Balance.OFFLINE_MIN_SECONDS then
		seconds = math.min(away, Balance.OFFLINE_MAX_SECONDS)
		coins = math.floor(EggService.getNestRate(player) * seconds * Balance.OFFLINE_EFFICIENCY)
	end

	data.Coins += coins
	MonetizationService.setOfflineClaimable(player, coins)
	-- Atributos y no RemoteEvent: el cliente puede tardar en conectarse y un evento se perdería; un atributo siempre llega.
	player:SetAttribute("OfflineCoins", coins)
	player:SetAttribute("OfflineSeconds", if coins > 0 then seconds else 0)
end

local function initPlayer(player: Player)
	if ready[player] == true or initializing[player] == true then
		return
	end
	initializing[player] = true
	-- Los espacios de dragón dependen del pase ExtraDragonSlots: hay que saber si lo tiene antes de recortar los equipados.
	MonetizationService.waitForPasses(player)

	local data = DataService.getData(player)
	if data == nil then
		initializing[player] = nil
		return
	end

	sanitizeEquipped(player, data)
	EggService.applyOffline(player)
	DataService.replicate(player)
	replicateInventory(player)
	ready[player] = true
	initializing[player] = nil
end

-- Una vez por tick, el nido paga a cada jugador y se marca LastSeen (así sabemos desde cuándo estuvo fuera).
local function startNestLoop()
	task.spawn(function()
		local last = os.clock()
		while true do
			task.wait(Balance.NEST_TICK)
			local now = os.clock()
			local elapsed = now - last
			last = now

			for _, player in Players:GetPlayers() do
				local data = DataService.getData(player)
				if data ~= nil and ready[player] == true then
					data.LastSeen = os.time()
					local rate = EggService.getNestRate(player)
					if rate > 0 then
						data.Coins += rate * elapsed
						DataService.replicate(player)
					end
				end
			end
		end
	end)
end

-- Máximo un pedido cada EGG_ACTION_COOLDOWN segundos por jugador.
local function allowAction(player: Player): boolean
	local now = os.clock()
	local last = lastActionAt[player]
	if last ~= nil and now - last < Balance.EGG_ACTION_COOLDOWN then
		return false
	end
	lastActionAt[player] = now
	return true
end

-- Un id que llega por RemoteEvent: tiene que ser un string corto, nada más.
local function readId(value: unknown): string?
	if typeof(value) ~= "string" or #value == 0 or #value > MAX_ID_LENGTH then
		return nil
	end
	return value
end

function EggService.start()
	DataService.onLoaded(initPlayer)
	-- Una compra puede cambiar los espacios o los huevos gratis: se vuelve a publicar el inventario.
	MonetizationService.onChanged(replicateInventory)
	-- Si algún jugador ya cargó antes de conectarnos (por ejemplo, en Studio), se le aplica ahora.
	for _, player in Players:GetPlayers() do
		initPlayer(player)
	end

	Players.PlayerRemoving:Connect(function(player)
		lastActionAt[player] = nil
		ready[player] = nil
		initializing[player] = nil
	end)

	Remotes.get("Hatch").OnServerEvent:Connect(function(player: Player, eggId: unknown)
		local id = readId(eggId)
		if id == nil then
			return
		end
		if not allowAction(player) then
			Remotes.get("HatchResult"):FireClient(player, { ok = false, reason = "TooFast" })
			return
		end
		Remotes.get("HatchResult"):FireClient(player, EggService.hatch(player, id, false))
	end)

	Remotes.get("EquipDragon").OnServerEvent:Connect(function(player: Player, dragonId: unknown)
		local id = readId(dragonId)
		if id ~= nil and allowAction(player) then
			EggService.equip(player, id)
		end
	end)

	Remotes.get("UnequipDragon").OnServerEvent:Connect(function(player: Player, dragonId: unknown)
		local id = readId(dragonId)
		if id ~= nil and allowAction(player) then
			EggService.unequip(player, id)
		end
	end)

	startNestLoop()
end

return table.freeze(EggService)
