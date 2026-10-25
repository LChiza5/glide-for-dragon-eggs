--!strict
-- Dueño: Luis.
-- Recompensa diaria con racha. Los días se cuentan en UTC (cambian a medianoche UTC) y solo cuenta la hora del servidor:
-- cambiar el reloj de la computadora no sirve de nada.
--
-- Lo que ve el cliente (atributos del Player):
--   DailyReady    1 si ya puede reclamar hoy, 0 si ya reclamó.
--   DailyStreak   racha actual (0 si la perdió por saltarse un día).
--   DailyReward   monedas que daría el próximo reclamo.
--   DailyResetAt  hora del servidor (segundos, como workspace:GetServerTimeNow()) en que cambia el día; sirve para la cuenta regresiva.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Balance = require(ReplicatedStorage.Shared.Config.Balance)
local Daily = require(ReplicatedStorage.Shared.Config.Daily)
local DataService = require(script.Parent.DataService)
local MetricsService = require(script.Parent.MetricsService)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local Types = require(ReplicatedStorage.Shared.Types)

local SECONDS_PER_DAY = 86_400
local REFRESH_INTERVAL = 30 -- segundos entre revisiones para avisar que cambió el día mientras juega

local lastRequestAt: { [Player]: number? } = {}

local DailyService = {}

local function dayNumber(): number
	return os.time() // SECONDS_PER_DAY
end

-- Racha que daría reclamar hoy: sigue si reclamó ayer, vuelve a 1 si pasó más tiempo.
local function streakIfClaimed(data: Types.PlayerData, day: number): number
	if data.LastDailyDay == day - 1 then
		return data.DailyStreak + 1
	end
	return 1
end

-- Publica los atributos de la recompensa diaria. Se llama al cargar, al reclamar y cada REFRESH_INTERVAL segundos.
function DailyService.publish(player: Player)
	local data = DataService.getData(player)
	if data == nil then
		return
	end

	local day = dayNumber()
	local ready = data.LastDailyDay < day
	local upcoming = if ready then streakIfClaimed(data, day) else data.DailyStreak + 1
	local alive = data.LastDailyDay >= day - 1

	player:SetAttribute("DailyReady", if ready then 1 else 0)
	player:SetAttribute("DailyStreak", if alive then data.DailyStreak else 0)
	player:SetAttribute("DailyReward", Daily.rewardFor(upcoming))
	player:SetAttribute("DailyResetAt", (day + 1) * SECONDS_PER_DAY)
end

local function fail(reason: Types.DailyFailure): Types.DailyResult
	return { ok = false, reason = reason }
end

-- Reclama la recompensa de hoy si no la reclamó. Sin yields: dos pedidos seguidos no pueden cobrar dos veces.
function DailyService.claim(player: Player): Types.DailyResult
	local data = DataService.getData(player)
	if data == nil then
		return fail("NoData")
	end

	local day = dayNumber()
	if data.LastDailyDay >= day then
		return fail("AlreadyClaimed")
	end

	local streak = streakIfClaimed(data, day)
	local coins = Daily.rewardFor(streak)
	data.LastDailyDay = day
	data.DailyStreak = streak
	data.Coins += coins

	DataService.replicate(player)
	DailyService.publish(player)
	MetricsService.coinsGained(player, coins, "TimedReward", "Daily")
	return { ok = true, coins = coins, streak = streak, day = Daily.dayInCycle(streak) }
end

function DailyService.start()
	DataService.onLoaded(DailyService.publish)
	-- Si algún jugador ya cargó antes de conectarnos (por ejemplo, en Studio), se le publica ahora.
	for _, player in Players:GetPlayers() do
		DailyService.publish(player)
	end

	Players.PlayerRemoving:Connect(function(player)
		lastRequestAt[player] = nil
	end)

	Remotes.get("ClaimDaily").OnServerEvent:Connect(function(player: Player)
		local now = os.clock()
		local last = lastRequestAt[player]
		if last ~= nil and now - last < Balance.EGG_ACTION_COOLDOWN then
			Remotes.get("DailyResult"):FireClient(player, fail("TooFast"))
			return
		end
		lastRequestAt[player] = now
		Remotes.get("DailyResult"):FireClient(player, DailyService.claim(player))
	end)

	-- Si el jugador sigue conectado cuando cambia el día, el botón de reclamar tiene que activarse solo.
	task.spawn(function()
		while true do
			task.wait(REFRESH_INTERVAL)
			for _, player in Players:GetPlayers() do
				DailyService.publish(player)
			end
		end
	end)
end

return table.freeze(DailyService)
