--!strict
-- Dueño: Luis (base) · Isaac (feel, animaciones y cámara).
-- Al dejar una plataforma "LaunchPad" en el aire, abre las alas: un impulso hacia arriba y luego planeo hacia donde mira
-- la cámara. Más WingPower y GlideMultiplier = planeo más largo. Los números están en Config/Balance (sección Vuelo).
-- El cliente solo mueve al personaje; el servidor (GlideService) mide el vuelo y paga.
--
-- Para la UI de José: GlideController.isGliding(), GlideController.distance() (studs desde el despegue, solo para mostrar),
-- onGlideStarted(fn) y onGlideEnded(fn(distancia)). El resultado real llega por "GlideResult".

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Balance = require(ReplicatedStorage.Shared.Config.Balance)
local Remotes = require(ReplicatedStorage.Shared.Remotes)

local LAUNCH_TAG = "LaunchPad"
local PAD_MEMORY = 0.75 -- segundos que "recuerda" haber pisado la plataforma
local GROUND_RAY = 4.5
local HEIGHT_RAY = 2000

type Glide = {
	character: Model,
	humanoid: Humanoid,
	root: BasePart,
	attachment: Attachment,
	velocity: LinearVelocity,
	align: AlignOrientation,
	direction: Vector3,
	start: Vector3,
	startedAt: number,
	target: number, -- studs que intenta planear
	speed: number,
}

local current: Glide? = nil
local lastPadAt = -math.huge
local startedCallbacks: { () -> () } = {}
local endedCallbacks: { (number) -> () } = {}

local GlideController = {}

local function flat(vector: Vector3): Vector3
	return Vector3.new(vector.X, 0, vector.Z)
end

local function castDown(character: Model, origin: Vector3, length: number): RaycastResult?
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }
	return Workspace:Raycast(origin, Vector3.new(0, -length, 0), params)
end

local function hasLaunchTag(instance: Instance): boolean
	local node: Instance? = instance
	while node ~= nil and node ~= Workspace do
		if CollectionService:HasTag(node, LAUNCH_TAG) then
			return true
		end
		node = node.Parent
	end
	return false
end

local function stop()
	local glide = current
	if glide == nil then
		return
	end
	current = nil
	glide.velocity:Destroy()
	glide.align:Destroy()
	glide.attachment:Destroy()
	glide.humanoid.AutoRotate = true

	local distance = flat(glide.root.Position - glide.start).Magnitude
	Remotes.get("GlideLanded"):FireServer()
	for _, callback in endedCallbacks do
		task.spawn(callback, distance)
	end
end

local function begin(character: Model, humanoid: Humanoid, root: BasePart, now: number)
	local player = Players.LocalPlayer
	local power = player:GetAttribute("WingPower")
	local multiplier = player:GetAttribute("GlideMultiplier")
	local target = math.max(if typeof(power) == "number" then power else 0, 1)
		* Balance.MAX_GLIDE_STUDS_PER_POWER
		* (if typeof(multiplier) == "number" then multiplier else 1)
		* Balance.GLIDE_EFFICIENCY
	local speed =
		math.clamp(target / Balance.GLIDE_TARGET_SECONDS, Balance.GLIDE_MIN_SPEED, Balance.GLIDE_MAX_SPEED)

	local look = flat(root.CFrame.LookVector)
	local direction = if look.Magnitude > 0.01 then look.Unit else Vector3.new(0, 0, 1)

	local attachment = Instance.new("Attachment")
	attachment.Name = "GlideAttachment"
	attachment.Parent = root

	local velocity = Instance.new("LinearVelocity")
	velocity.Name = "GlideVelocity"
	velocity.Attachment0 = attachment
	velocity.RelativeTo = Enum.ActuatorRelativeTo.World
	velocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Vector
	velocity.MaxForce = math.huge
	velocity.VectorVelocity = direction * speed + Vector3.new(0, Balance.GLIDE_LAUNCH_BOOST, 0)
	velocity.Parent = root

	local align = Instance.new("AlignOrientation")
	align.Name = "GlideAlign"
	align.Mode = Enum.OrientationAlignmentMode.OneAttachment
	align.Attachment0 = attachment
	align.MaxTorque = math.huge
	align.Responsiveness = 30
	align.CFrame = CFrame.lookAt(Vector3.zero, direction)
	align.Parent = root

	humanoid.AutoRotate = false
	current = {
		character = character,
		humanoid = humanoid,
		root = root,
		attachment = attachment,
		velocity = velocity,
		align = align,
		direction = direction,
		start = root.Position,
		startedAt = now,
		target = target,
		speed = speed,
	}
	for _, callback in startedCallbacks do
		task.spawn(callback)
	end
end

-- Gira `from` hacia `to` (ambos horizontales y unitarios) como mucho `maxAngle` radianes.
local function turnToward(from: Vector3, to: Vector3, maxAngle: number): Vector3
	local angle = math.acos(math.clamp(from:Dot(to), -1, 1))
	if angle <= maxAngle then
		return to
	end
	local sign = if from:Cross(to).Y >= 0 then 1 else -1
	return (CFrame.Angles(0, sign * maxAngle, 0) * from).Unit
end

local function update(glide: Glide, dt: number, now: number)
	local elapsed = now - glide.startedAt
	if
		glide.humanoid.Health <= 0
		or glide.character.Parent == nil
		or elapsed > Balance.MAX_FLIGHT_SECONDS
	then
		stop()
		return
	end
	if
		elapsed >= Balance.MIN_FLIGHT_SECONDS
		and castDown(glide.character, glide.root.Position, GROUND_RAY) ~= nil
	then
		stop()
		return
	end

	local camera = Workspace.CurrentCamera
	if camera ~= nil then
		local look = flat(camera.CFrame.LookVector)
		if look.Magnitude > 0.01 then
			glide.direction = turnToward(glide.direction, look.Unit, Balance.GLIDE_TURN_RATE * dt)
		end
	end

	-- Baja lo justo para tocar el suelo cuando completa la distancia que le da su poder.
	local remaining = glide.target - flat(glide.root.Position - glide.start).Magnitude
	local hit = castDown(glide.character, glide.root.Position, HEIGHT_RAY)
	local height = if hit ~= nil then glide.root.Position.Y - hit.Position.Y else HEIGHT_RAY
	local vertical
	if elapsed < Balance.GLIDE_LAUNCH_BOOST_SECONDS then
		vertical = Balance.GLIDE_LAUNCH_BOOST
	elseif remaining > 0 then
		local timeLeft = math.max(remaining / glide.speed, 0.1)
		vertical = -math.clamp(height / timeLeft, Balance.GLIDE_MIN_SINK, Balance.GLIDE_MAX_SINK)
	else
		vertical = -Balance.GLIDE_MAX_SINK
	end

	glide.velocity.VectorVelocity = glide.direction * glide.speed + Vector3.new(0, vertical, 0)
	glide.align.CFrame = CFrame.lookAt(Vector3.zero, glide.direction)
end

local function step(dt: number)
	local now = os.clock()
	local glide = current
	if glide ~= nil then
		update(glide, dt, now)
		return
	end

	local character = Players.LocalPlayer.Character
	if character == nil then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	if humanoid == nil or humanoid.Health <= 0 or root == nil or not root:IsA("BasePart") then
		return
	end

	local below = castDown(character, root.Position, GROUND_RAY)
	if below ~= nil then
		if hasLaunchTag(below.Instance) then
			lastPadAt = now
		end
	elseif now - lastPadAt < PAD_MEMORY then
		lastPadAt = -math.huge
		begin(character, humanoid, root, now)
	end
end

function GlideController.isGliding(): boolean
	return current ~= nil
end

-- Studs horizontales desde el despegue del vuelo actual (0 si no vuela). Solo para mostrar; el servidor mide aparte.
function GlideController.distance(): number
	local glide = current
	if glide == nil then
		return 0
	end
	return flat(glide.root.Position - glide.start).Magnitude
end

function GlideController.onGlideStarted(callback: () -> ())
	table.insert(startedCallbacks, callback)
end

-- Recibe la distancia que vio el cliente; la pagada llega por "GlideResult".
function GlideController.onGlideEnded(callback: (number) -> ())
	table.insert(endedCallbacks, callback)
end

function GlideController.start()
	RunService.Heartbeat:Connect(step)
	Players.LocalPlayer.CharacterRemoving:Connect(function()
		if current ~= nil then
			current = nil -- el personaje se va con sus constraints; no hay aterrizaje que avisar
		end
	end)
end

return table.freeze(GlideController)
