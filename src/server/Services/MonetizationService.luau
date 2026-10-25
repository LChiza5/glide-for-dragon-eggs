--!strict
-- Dueño: Luis.
-- Pases y productos de Robux con compra segura.
--   - Pases: se revisa si los tiene al entrar (con reintentos) y se escucha la compra en vivo. Dan multiplicadores.
--   - Productos: ProcessReceipt entrega una sola vez cada PurchaseId (queda en PurchaseHistory), guarda antes de confirmar
--     y, si algo falla, devuelve NotProcessedYet para que Roblox reintente sin entregar dos veces.
--   - Ningún pase ni producto con ID 0 en Config/Products se ofrece ni se entrega.
--
-- Lo que ve el cliente (atributos del Player): OwnsDoublePower, OwnsAutoTrain, OwnsVip, OwnsExtraDragonSlots, OwnsDoubleLuck,
-- OwnsFastHatch (1 o 0), AutoTrainOn (1 o 0) y LuckUntil (hora del servidor en que termina la poción; 0 si no hay).

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Balance = require(ReplicatedStorage.Shared.Config.Balance)
local DataService = require(script.Parent.DataService)
local Products = require(ReplicatedStorage.Shared.Config.Products)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Types = require(ReplicatedStorage.Shared.Types)

type GamePassKey = Products.GamePassKey
type ProductKey = Products.ProductKey

local PASS_LOAD_ATTEMPTS = 3 -- intentos de preguntarle a Roblox si tiene cada pase
local PASS_LOAD_RETRY_SECONDS = 2
local PASS_WAIT_SECONDS = 15 -- lo máximo que esperan otros servicios a saber qué pases tiene

local owned: { [Player]: { [string]: boolean }? } = {}
local passesLoaded: { [Player]: boolean? } = {}
local autoTrain: { [Player]: boolean? } = {}
local offlineClaimable: { [Player]: number? } = {}
local lastPromptAt: { [Player]: number? } = {}
local changedCallbacks: { (Player) -> () } = {}

local MonetizationService = {}

local function exhaustiveMatch(value: never): never
	error(`Producto sin manejar: {value}`)
end

local function fireChanged(player: Player)
	for _, callback in changedCallbacks do
		task.spawn(callback, player)
	end
end

-- Corre el callback cada vez que una compra cambia algo del jugador (para que otros servicios republiquen sus datos).
function MonetizationService.onChanged(callback: (Player) -> ())
	table.insert(changedCallbacks, callback)
end

function MonetizationService.ownsPass(player: Player, key: GamePassKey): boolean
	local set = owned[player]
	return set ~= nil and set[key] == true
end

local function publish(player: Player)
	for index = 1, #Products.GamePassKeys do
		local key: GamePassKey = Products.GamePassKeys[index]
		player:SetAttribute(`Owns{key}`, if MonetizationService.ownsPass(player, key) then 1 else 0)
	end
	player:SetAttribute(
		"AutoTrainOn",
		if MonetizationService.ownsPass(player, "AutoTrain") and autoTrain[player] == true then 1 else 0
	)
	local data = DataService.getData(player)
	player:SetAttribute("LuckUntil", if data ~= nil then data.LuckUntil else 0)
end

-- Marca un pase como suyo (o no). Lo usa la revisión al entrar y la compra en vivo.
function MonetizationService.setPassOwned(player: Player, key: GamePassKey, value: boolean)
	local set = owned[player] or {}
	owned[player] = set
	set[key] = value
	if key == "AutoTrain" and value and autoTrain[player] == nil then
		autoTrain[player] = true -- si lo compró, empieza encendido
	end
	publish(player)
	fireChanged(player)
end

-- Multiplicador del poder por entrenamiento (pase DoublePower).
function MonetizationService.getPowerMultiplier(player: Player): number
	return if MonetizationService.ownsPass(player, "DoublePower") then Balance.DOUBLE_POWER_MULTIPLIER else 1
end

-- Multiplicador de las monedas que se ganan jugando: vuelos y nido (pase Vip).
function MonetizationService.getCoinMultiplier(player: Player): number
	return if MonetizationService.ownsPass(player, "Vip") then Balance.VIP_COIN_MULTIPLIER else 1
end

function MonetizationService.isLuckPotionActive(player: Player): boolean
	local data = DataService.getData(player)
	return data ~= nil and data.LuckUntil > os.time()
end

-- Multiplicador de suerte al sortear rarezas: el pase DoubleLuck y la poción se multiplican entre sí.
function MonetizationService.getLuckMultiplier(player: Player): number
	local multiplier = 1
	if MonetizationService.ownsPass(player, "DoubleLuck") then
		multiplier *= Balance.LUCK_PASS_MULTIPLIER
	end
	if MonetizationService.isLuckPotionActive(player) then
		multiplier *= Balance.LUCK_POTION_MULTIPLIER
	end
	return multiplier
end

-- Espacios de dragón equipado que se suman a Balance.BASE_DRAGON_SLOTS (pase ExtraDragonSlots).
function MonetizationService.getExtraDragonSlots(player: Player): number
	return if MonetizationService.ownsPass(player, "ExtraDragonSlots") then Balance.EXTRA_DRAGON_SLOTS else 0
end

-- true si tiene el pase AutoTrain y no lo apagó.
function MonetizationService.isAutoTrainOn(player: Player): boolean
	return MonetizationService.ownsPass(player, "AutoTrain") and autoTrain[player] == true
end

-- EggService avisa cuántas monedas ganó sin conexión, por si compra "duplicar ganancias sin conexión".
function MonetizationService.setOfflineClaimable(player: Player, coins: number)
	offlineClaimable[player] = if coins > 0 then coins else nil
end

-- Pregunta a Roblox qué pases tiene. Quien necesite saberlo antes de decidir algo espera con waitForPasses.
local function loadPasses(player: Player)
	local pending = 0
	for index = 1, #Products.GamePassKeys do
		local key: GamePassKey = Products.GamePassKeys[index]
		local id = Products.GamePasses[key]
		if id ~= 0 then
			pending += 1
			task.spawn(function()
				for attempt = 1, PASS_LOAD_ATTEMPTS do
					local ok, result = pcall(function()
						return MarketplaceService:UserOwnsGamePassAsync(player.UserId, id)
					end)
					if ok then
						if result == true then
							MonetizationService.setPassOwned(player, key, true)
						end
						break
					end
					if attempt < PASS_LOAD_ATTEMPTS then
						task.wait(PASS_LOAD_RETRY_SECONDS)
					end
				end
				pending -= 1
			end)
		end
	end
	while pending > 0 and player.Parent == Players do
		task.wait(0.1)
	end
	passesLoaded[player] = true
	publish(player)
end

-- Espera (con tope) a saber qué pases tiene el jugador. Sin pases configurados, no espera nada.
function MonetizationService.waitForPasses(player: Player)
	local waited = 0
	while passesLoaded[player] ~= true and player.Parent == Players and waited < PASS_WAIT_SECONDS do
		task.wait(0.1)
		waited += 0.1
	end
end

-- Entrega un producto. Sin yields: tiene que terminar antes de anotar el PurchaseId.
local function grant(player: Player, data: Types.PlayerData, key: ProductKey)
	if key == "StarterPack" then
		data.Coins += Balance.STARTER_PACK_COINS
		data.FreeEggs += Balance.STARTER_PACK_EGGS
		data.StarterPackBought = true
	elseif key == "EggPack3" then
		data.FreeEggs += Balance.EGG_PACK_SMALL
	elseif key == "EggPack10" then
		data.FreeEggs += Balance.EGG_PACK_LARGE
	elseif key == "LuckPotion" then
		data.LuckUntil = math.max(data.LuckUntil, os.time()) + Balance.LUCK_POTION_SECONDS
	elseif key == "DoubleOffline" then
		-- Repite lo que ganó sin conexión en esta sesión; si ya no queda nada que repetir, paga una cantidad fija.
		data.Coins += offlineClaimable[player] or Balance.DOUBLE_OFFLINE_FALLBACK_COINS
		offlineClaimable[player] = nil
	elseif key == "SkipRealm" then
		-- Nunca llega aquí: processReceipt lo rechaza mientras los reinos no existan.
		error("SkipRealm todavía no se puede entregar")
	else
		exhaustiveMatch(key)
	end
end

-- Callback de MarketplaceService.ProcessReceipt. Pública para poder probarla.
function MonetizationService.processReceipt(receiptInfo: { [string]: any }): Enum.ProductPurchaseDecision
	local playerId = receiptInfo.PlayerId
	local productId = receiptInfo.ProductId
	local purchaseId = receiptInfo.PurchaseId
	if typeof(playerId) ~= "number" or typeof(productId) ~= "number" or purchaseId == nil then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local player = Players:GetPlayerByUserId(playerId)
	if player == nil then
		return Enum.ProductPurchaseDecision.NotProcessedYet -- se entrega cuando vuelva a entrar
	end
	local data = DataService.getData(player)
	if data == nil then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local id = tostring(purchaseId)
	if table.find(data.PurchaseHistory, id) ~= nil then
		return Enum.ProductPurchaseDecision.PurchaseGranted -- ya se entregó antes: no se entrega dos veces
	end

	local key: ProductKey? = Products.productKeyFromId(productId)
	if key == nil or key == "SkipRealm" then
		warn(`Compra de un producto que no se puede entregar todavía: {productId}`)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	grant(player, data, key)
	table.insert(data.PurchaseHistory, id)
	while #data.PurchaseHistory > Balance.PURCHASE_HISTORY_LIMIT do
		table.remove(data.PurchaseHistory, 1)
	end
	DataService.replicate(player)
	publish(player)
	fireChanged(player)

	-- Se guarda antes de confirmar; si falla, Roblox reintenta y el PurchaseId ya anotado evita entregar de nuevo.
	if not DataService.saveNow(player) then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

local function denied(key: string, reason: Types.PurchaseFailure): Types.PurchaseResult
	return { ok = false, key = key, reason = reason }
end

-- Valida un pedido de compra del cliente y, si procede, muestra la ventana de Roblox. El cliente solo pide una clave.
local function onRequestPurchase(player: Player, keyArg: unknown)
	if typeof(keyArg) ~= "string" or #keyArg == 0 or #keyArg > 40 then
		return
	end
	local now = os.clock()
	local last = lastPromptAt[player]
	if last ~= nil and now - last < Balance.PURCHASE_PROMPT_COOLDOWN then
		Remotes.get("PurchaseResult"):FireClient(player, denied(keyArg, "TooFast"))
		return
	end
	lastPromptAt[player] = now

	local data = DataService.getData(player)
	if data == nil then
		Remotes.get("PurchaseResult"):FireClient(player, denied(keyArg, "NoData"))
		return
	end

	local passKey: GamePassKey? = Products.asGamePassKey(keyArg)
	if passKey ~= nil then
		local passId = Products.GamePasses[passKey]
		if passId == 0 then
			Remotes.get("PurchaseResult"):FireClient(player, denied(keyArg, "NotForSale"))
		elseif MonetizationService.ownsPass(player, passKey) then
			Remotes.get("PurchaseResult"):FireClient(player, denied(keyArg, "AlreadyOwned"))
		else
			MarketplaceService:PromptGamePassPurchase(player, passId)
			Remotes.get("PurchaseResult"):FireClient(player, { ok = true, key = keyArg })
		end
		return
	end

	local productKey: ProductKey? = Products.asProductKey(keyArg)
	if productKey == nil then
		return -- una clave que no existe: se ignora
	end
	local productId = Products.DevProducts[productKey]
	if productId == 0 or productKey == "SkipRealm" then
		Remotes.get("PurchaseResult"):FireClient(player, denied(keyArg, "NotForSale"))
	elseif productKey == "StarterPack" and data.StarterPackBought then
		Remotes.get("PurchaseResult"):FireClient(player, denied(keyArg, "AlreadyOwned"))
	elseif productKey == "DoubleOffline" and offlineClaimable[player] == nil then
		Remotes.get("PurchaseResult"):FireClient(player, denied(keyArg, "Unavailable"))
	else
		MarketplaceService:PromptProductPurchase(player, productId)
		Remotes.get("PurchaseResult"):FireClient(player, { ok = true, key = keyArg })
	end
end

function MonetizationService.start()
	MarketplaceService.ProcessReceipt = MonetizationService.processReceipt

	DataService.onLoaded(function(player)
		loadPasses(player)
	end)
	-- Si algún jugador ya cargó antes de conectarnos (por ejemplo, en Studio), se le revisa ahora.
	for _, player in Players:GetPlayers() do
		if DataService.getData(player) ~= nil then
			task.spawn(loadPasses, player)
		end
	end

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(
		function(player: Player, passId: number, wasPurchased: boolean)
			if not wasPurchased or passId == 0 then
				return
			end
			for index = 1, #Products.GamePassKeys do
				local key: GamePassKey = Products.GamePassKeys[index]
				if Products.GamePasses[key] == passId then
					MonetizationService.setPassOwned(player, key, true)
				end
			end
		end
	)

	Remotes.get("RequestPurchase").OnServerEvent:Connect(onRequestPurchase)

	Remotes.get("SetAutoTrain").OnServerEvent:Connect(function(player: Player, on: unknown)
		if typeof(on) ~= "boolean" or not MonetizationService.ownsPass(player, "AutoTrain") then
			return
		end
		autoTrain[player] = on
		publish(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		owned[player] = nil
		passesLoaded[player] = nil
		autoTrain[player] = nil
		offlineClaimable[player] = nil
		lastPromptAt[player] = nil
	end)
end

return table.freeze(MonetizationService)
