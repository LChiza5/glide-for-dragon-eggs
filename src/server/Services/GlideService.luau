--!strict
-- Dueño: Luis (medición y pago) · Isaac (feel del planeo, en GlideController y Balance).
-- El servidor mide cada vuelo por su cuenta, con la posición del personaje; nunca usa una distancia del cliente.
--   1. Despegue: el personaje estaba sobre una parte con la etiqueta "LaunchPad" y queda en el aire fuera de ella.
--   2. Vuelo: cada GLIDE_CHECK_INTERVAL revisa que no vaya más rápido de lo posible (teletransportes) ni dure demasiado.
--   3. Aterrizaje: toca suelo; la distancia es la horizontal entre el despegue y el aterrizaje -> rewardDistance.
--   4. Después de GLIDE_RETURN_DELAY segundos lo regresa al punto con la etiqueta "ReturnPoint".
-- "GlideLanded" (sin datos) solo pide que el servidor revise ya; el servidor igual lo comprueba solo.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Balance = require(ReplicatedStorage.Shared.Config.Balance)
local DataService = require(script.Parent.DataService)
local EggService = require(script.Parent.EggService)
local LeaderboardService = require(script.Parent.LeaderboardService)
local MetricsService = require(script.Parent.MetricsService)
local MonetizationService = require(script.Parent.MonetizationService)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Types = require(ReplicatedStorage.Shared.Types)

local LAUNCH_TAG = "LaunchPad"
local RETURN_TAG = "ReturnPoint"
local PAD_MARGIN = 2 -- studs alrededor de la plataforma que todavía cuentan como "sobre ella"
local PAD_HEIGHT = 10 -- studs sobre la plataforma que todavía cuentan (saltar encima)
local GROUND_RAY = 4.5 -- desde el centro del HumanoidRootPart hasta el suelo cuando está parado
local HINT_COOLDOWN = 0.2

type Phase = "Armed" | "Flying"
type Flight = {
	phase: Phase,
	character: Model,
	launchPos: Vector3, -- en "Armed": la última posición sobre la plataforma
	launchedAt: number,
	lastPos: Vector3,
	lastAt: number,
}

local lastRewardAt: { [Player]: number? } = {}
local flights: { [Player]: Flight? } = {}
local lastHintAt: { [Player]: number? } = {}
local returning: { [Player]: boolean? } = {}

local GlideService = {}

-- Paga un vuelo ya medido por el servidor. Recorta la distancia al máximo posible con el poder
-- actual, para que un error de medición o un exploit no regale monedas.
-- Devuelve lo que se pagó (y se lo avisa al cliente por "GlideResult"), o nil si no se pagó nada.
function GlideService.rewardDistance(player: Player, studs: number): Types.GlideResult?
	if studs ~= studs or studs <= 0 then -- descarta NaN y valores negativos
		return nil
	end

	local now = os.clock()
	local last = lastRewardAt[player]
	if last ~= nil and now - last < Balance.MIN_GLIDE_INTERVAL then
		return nil
	end

	local data = DataService.getData(player)
	if data == nil then
		return nil
	end
	lastRewardAt[player] = now

	-- Los dragones equipados dan planeo, así que también suben el tope de lo que se puede pagar.
	local maxStuds = math.max(data.WingPower, 1)
		* Balance.MAX_GLIDE_STUDS_PER_POWER
		* EggService.getGlideMultiplier(player)
	local distance = math.min(studs, maxStuds)
	local coins =
		math.floor(distance * Balance.COINS_PER_STUD * MonetizationService.getCoinMultiplier(player))
	local previousBest = data.BestDistance

	data.Coins += coins
	data.BestDistance = math.max(previousBest, distance)
	DataService.replicate(player)
	MetricsService.reach(player, "FirstFlight")
	MetricsService.coinsGained(player, coins, "Gameplay", "Flight")

	local result: Types.GlideResult = {
		distance = distance,
		coins = coins,
		isNewBest = distance > previousBest,
	}
	if result.isNewBest then
		LeaderboardService.submit(player, distance)
	end
	Remotes.get("GlideResult"):FireClient(player, result)
	return result
end

local function flat(vector: Vector3): Vector3
	return Vector3.new(vector.X, 0, vector.Z)
end

local function isOnPad(position: Vector3): boolean
	for _, pad in CollectionService:GetTagged(LAUNCH_TAG) do
		if pad:IsA("BasePart") then
			local localPos = pad.CFrame:PointToObjectSpace(position)
			local half = pad.Size / 2
			if
				math.abs(localPos.X) <= half.X + PAD_MARGIN
				and math.abs(localPos.Z) <= half.Z + PAD_MARGIN
				and localPos.Y >= -half.Y
				and localPos.Y <= half.Y + PAD_HEIGHT
			then
				return true
			end
		end
	end
	return false
end

local function isGrounded(character: Model, root: BasePart): boolean
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }
	return Workspace:Raycast(root.Position, Vector3.new(0, -GROUND_RAY, 0), params) ~= nil
end

local function getRoot(player: Player): (Model?, BasePart?)
	local character = player.Character
	if character == nil then
		return nil, nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	if humanoid == nil or humanoid.Health <= 0 or root == nil or not root:IsA("BasePart") then
		return nil, nil
	end
	return character, root
end

-- Lo regresa al inicio. El servidor lo mueve, así que no cuenta como teletransporte.
local function returnToStart(player: Player, character: Model)
	if returning[player] then
		return
	end
	returning[player] = true
	task.delay(Balance.GLIDE_RETURN_DELAY, function()
		returning[player] = nil
		flights[player] = nil
		if player.Parent == nil or player.Character ~= character or character.Parent == nil then
			return
		end
		local point = CollectionService:GetTagged(RETURN_TAG)[1]
		if point ~= nil and point:IsA("BasePart") then
			character:PivotTo(point.CFrame + Vector3.new(0, 4, 0))
		end
	end)
end

local function cancel(player: Player, flight: Flight, reason: string)
	flights[player] = nil
	MetricsService.event(player, "FlightRejected", 1, { reason = reason })
	returnToStart(player, flight.character)
end

local function land(player: Player, flight: Flight, position: Vector3, now: number)
	flights[player] = nil
	local elapsed = now - flight.launchedAt
	local distance = flat(position - flight.launchPos).Magnitude
	-- Revisión final: la distancia total tiene que caber en el tiempo de vuelo a la velocidad máxima.
	local maxDistance = elapsed * Balance.GLIDE_MAX_SPEED * Balance.GLIDE_SPEED_TOLERANCE
		+ Balance.GLIDE_SPEED_MARGIN
	if distance > maxDistance then
		cancel(player, flight, "TooFar")
		return
	end
	GlideService.rewardDistance(player, distance)
	returnToStart(player, flight.character)
end

local function check(player: Player, now: number)
	if returning[player] then
		return
	end
	local character, root = getRoot(player)
	local flight = flights[player]
	if character == nil or root == nil then
		flights[player] = nil
		return
	end
	if flight ~= nil and flight.character ~= character then
		flight = nil
		flights[player] = nil
	end

	local position = root.Position
	if isOnPad(position) then
		flights[player] = {
			phase = "Armed",
			character = character,
			launchPos = position,
			launchedAt = now,
			lastPos = position,
			lastAt = now,
		}
		return
	end
	if flight == nil then
		return
	end

	local grounded = isGrounded(character, root)
	if flight.phase == "Armed" then
		if grounded then
			flights[player] = nil -- se bajó caminando, no despegó
		else
			flight.phase = "Flying"
			flight.launchedAt = now
			flight.lastPos = position
			flight.lastAt = now
		end
		return
	end

	local dt = math.max(now - flight.lastAt, 1 / 60)
	local horizontal = flat(position - flight.lastPos).Magnitude
	local rise = position.Y - flight.lastPos.Y
	local tolerance = Balance.GLIDE_SPEED_TOLERANCE
	if horizontal > Balance.GLIDE_MAX_SPEED * tolerance * dt + Balance.GLIDE_SPEED_MARGIN then
		cancel(player, flight, "TooFast")
		return
	end
	if rise > Balance.GLIDE_LAUNCH_BOOST * tolerance * dt + Balance.GLIDE_SPEED_MARGIN then
		cancel(player, flight, "Rising")
		return
	end
	if now - flight.launchedAt > Balance.MAX_FLIGHT_SECONDS then
		cancel(player, flight, "TooLong")
		return
	end
	flight.lastPos = position
	flight.lastAt = now

	if grounded and now - flight.launchedAt >= Balance.MIN_FLIGHT_SECONDS then
		land(player, flight, position, now)
	end
end

function GlideService.start()
	Players.PlayerRemoving:Connect(function(player)
		lastRewardAt[player] = nil
		flights[player] = nil
		lastHintAt[player] = nil
		returning[player] = nil
	end)

	Remotes.get("GlideLanded").OnServerEvent:Connect(function(player)
		local now = os.clock()
		local last = lastHintAt[player]
		if last ~= nil and now - last < HINT_COOLDOWN then
			return
		end
		lastHintAt[player] = now
		check(player, now)
	end)

	task.spawn(function()
		while true do
			task.wait(Balance.GLIDE_CHECK_INTERVAL)
			local now = os.clock()
			for _, player in Players:GetPlayers() do
				check(player, now)
			end
		end
	end)
end

return table.freeze(GlideService)
