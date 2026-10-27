--!strict
-- Construye en Studio el mapa gris (Workspace.Map): la base jugable que Isaac luego cambia por el arte real.
-- Se corre en modo edición (barra de comandos o run_code del MCP). No es parte del juego: Rojo no lo sincroniza.
-- Si ya hay un Workspace.Map sin el atributo Greybox (el de Isaac), no hace nada.
--
-- Contrato con el código (si Isaac rehace el mapa, mantener estas etiquetas de CollectionService):
--   "TrainingMachine"  máquina con un ProximityPrompt dentro (TrainingController).
--   "LaunchPad"        plataforma de despegue al borde del acantilado (GlideController y GlideService).
--   "ReturnPoint"      a dónde vuelve el jugador después de aterrizar (GlideService).
--   "NestSlot"         lugar del nido con atributo Slot = 1..12 (DragonController). 12 = Balance.NEST_SLOTS.
-- Medidas: suelo en Y = 0; acantilado de 100 studs; el borde de despegue está en Z = 0 y se vuela hacia +Z.

local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")

local STRIP_LENGTH = 20_000 -- studs de pista con marcas
local MARK_EVERY = 100
local CLIFF_HEIGHT = 100
local GROUND = Color3.fromRGB(110, 140, 100)
local STONE = Color3.fromRGB(150, 150, 150)
local STRIP = Color3.fromRGB(190, 190, 175)

local existing = Workspace:FindFirstChild("Map")
if existing ~= nil and existing:GetAttribute("Greybox") ~= true then
	error("Ya hay un Workspace.Map que no es el mapa gris; no lo toco")
end
if existing ~= nil then
	existing:Destroy()
end

local map = Instance.new("Folder")
map.Name = "Map"
map:SetAttribute("Greybox", true)

local function block(
	parent: Instance,
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material?
): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.CFrame = cframe
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function folder(name: string): Folder
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = map
	return f
end

-- Letrero que mira hacia -Z (hacia quien viene del inicio) salvo que se gire el CFrame.
local function sign(parent: Instance, text: string, size: Vector3, cframe: CFrame)
	local board = block(parent, "Sign", size, cframe, Color3.fromRGB(40, 40, 45))
	board.CanCollide = false
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.PixelsPerStud = 20
	gui.Parent = board
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Text = text
	label.Parent = gui
end

-- Suelo: losas de 2048 (el máximo de una parte) desde detrás del inicio hasta el final de la pista.
local ground = folder("Ground")
local z = -1024
while z < STRIP_LENGTH + 1024 do
	block(
		ground,
		"Ground",
		Vector3.new(2048, 4, 2048),
		CFrame.new(0, -2, z + 1024),
		GROUND,
		Enum.Material.Grass
	)
	z += 2048
end

-- Zona de inicio con el SpawnLocation (también es el ReturnPoint).
local start = folder("Start")
block(start, "Plaza", Vector3.new(160, 1, 140), CFrame.new(0, 0.5, -560), STONE)
local spawn = Instance.new("SpawnLocation")
spawn.Name = "Spawn"
spawn.Anchored = true
spawn.Size = Vector3.new(12, 1, 12)
spawn.CFrame = CFrame.new(0, 1.5, -600)
spawn.Neutral = true
spawn.Duration = 0
spawn.Color = Color3.fromRGB(90, 160, 230)
spawn.Parent = start
CollectionService:AddTag(spawn, "ReturnPoint")
sign(start, "Entrena y sube por la rampa", Vector3.new(30, 6, 0.5), CFrame.new(0, 12, -500))

-- Máquinas de entrenamiento a los lados del camino.
local machines = folder("TrainingMachines")
for index, x in { -70, -50, -30, 30, 50, 70 } do
	local model = Instance.new("Model")
	model.Name = `Machine{index}`
	local base =
		block(model, "Base", Vector3.new(8, 4, 8), CFrame.new(x, 3, -540), Color3.fromRGB(200, 120, 60))
	block(
		model,
		"Weight",
		Vector3.new(6, 2, 2),
		CFrame.new(x, 6, -540),
		Color3.fromRGB(60, 60, 70),
		Enum.Material.Metal
	)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Entrenar (mantener)"
	prompt.ObjectText = "Máquina"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.Parent = base
	model.PrimaryPart = base
	model.Parent = machines
	CollectionService:AddTag(model, "TrainingMachine")
end

-- Acantilado con rampa y plataforma de despegue en el borde (Z = 0).
local cliff = folder("Cliff")
block(
	cliff,
	"Cliff",
	Vector3.new(120, CLIFF_HEIGHT, 220),
	CFrame.new(0, CLIFF_HEIGHT / 2, -110),
	STONE,
	Enum.Material.Slate
)
local rampRun, rampStartZ = 260, -480
local rampLength = math.sqrt(rampRun ^ 2 + CLIFF_HEIGHT ^ 2)
local rampAngle = math.atan2(CLIFF_HEIGHT, rampRun)
block(
	cliff,
	"Ramp",
	Vector3.new(40, 2, rampLength),
	CFrame.new(0, CLIFF_HEIGHT / 2, rampStartZ + rampRun / 2)
		* CFrame.Angles(-rampAngle, 0, 0)
		* CFrame.new(0, -1, 0),
	STRIP,
	Enum.Material.Concrete
)
local pad = block(
	cliff,
	"LaunchPad",
	Vector3.new(40, 1, 24),
	CFrame.new(0, CLIFF_HEIGHT + 0.5, -12),
	Color3.fromRGB(255, 140, 30),
	Enum.Material.Neon
)
CollectionService:AddTag(pad, "LaunchPad")
sign(cliff, "¡Corre y salta!", Vector3.new(24, 6, 0.5), CFrame.new(0, CLIFF_HEIGHT + 14, -40))

-- Pista de aterrizaje con una línea y un cartel cada 100 studs.
local strip = folder("LandingStrip")
local segment = 2000
for start = 0, STRIP_LENGTH - segment, segment do
	block(
		strip,
		"Strip",
		Vector3.new(60, 0.2, segment),
		CFrame.new(0, 0.1, start + segment / 2),
		STRIP,
		Enum.Material.Concrete
	)
end
for distance = MARK_EVERY, STRIP_LENGTH, MARK_EVERY do
	local big = distance % 1000 == 0
	local line = block(
		strip,
		"Mark",
		Vector3.new(60, 0.3, if big then 3 else 1),
		CFrame.new(0, 0.15, distance),
		Color3.new(1, 1, 1)
	)
	line.CanCollide = false
	local height = if big then 8 else 5
	sign(
		strip,
		`{distance}`,
		Vector3.new(if big then 16 else 10, height, 0.4),
		CFrame.new(38, height / 2 + 1, distance)
	)
end

-- Nido con 12 lugares (atributo Slot).
local nest = folder("Nest")
block(
	nest,
	"NestFloor",
	Vector3.new(100, 1, 90),
	CFrame.new(-200, 0.5, -560),
	Color3.fromRGB(160, 130, 90),
	Enum.Material.WoodPlanks
)
local slot = 0
for row = 0, 2 do
	for column = 0, 3 do
		slot += 1
		local pedestal = block(
			nest,
			`Slot{slot}`,
			Vector3.new(8, 2, 8),
			CFrame.new(-230 + column * 20, 2, -585 + row * 25),
			Color3.fromRGB(120, 95, 70),
			Enum.Material.Wood
		)
		pedestal:SetAttribute("Slot", slot)
		CollectionService:AddTag(pedestal, "NestSlot")
	end
end
sign(
	nest,
	"Nido: tus 12 mejores dragones en reposo pagan monedas",
	Vector3.new(40, 6, 0.5),
	CFrame.new(-200, 10, -510)
)

map.Parent = Workspace
print(`Mapa gris listo: {#map:GetDescendants()} piezas`)
