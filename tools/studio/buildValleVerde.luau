--!strict
-- Viste el mapa gris como el "Valle verde" (Workspace.Map), en modo edición (barra de comandos o run_code del MCP).
-- No toca el contrato con el código: TrainingMachine (y su ProximityPrompt), LaunchPad, ReturnPoint y NestSlot (Slot 1-12)
-- quedan en su lugar. Lo decorativo va en Map.Decor y en un modelo "Deco" dentro de cada máquina; volver a correr el
-- script los reconstruye. Todo es Anchored y liviano. Al final quita el atributo Greybox del mapa para que
-- buildGreybox.luau ya no lo toque.

local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local map = Workspace:FindFirstChild("Map")
assert(map ~= nil, "Falta Workspace.Map: corre primero buildGreybox.luau")

local GRASS = Color3.fromRGB(108, 186, 84)
local GRASS_DARK = Color3.fromRGB(78, 150, 64)
local STONE = Color3.fromRGB(226, 212, 176)
local WOOD = Color3.fromRGB(128, 86, 50)
local WOOD_DARK = Color3.fromRGB(92, 60, 36)
local STRAW = Color3.fromRGB(222, 190, 118)
local ROCK = Color3.fromRGB(150, 146, 140)
local METAL = Color3.fromRGB(70, 74, 84)
local PLATES = {
	Color3.fromRGB(235, 80, 70),
	Color3.fromRGB(70, 140, 235),
	Color3.fromRGB(250, 200, 60),
	Color3.fromRGB(120, 210, 110),
	Color3.fromRGB(190, 110, 230),
	Color3.fromRGB(255, 140, 60),
}
local FLOWERS = {
	Color3.fromRGB(255, 120, 150),
	Color3.fromRGB(255, 230, 90),
	Color3.fromRGB(255, 255, 255),
	Color3.fromRGB(170, 140, 255),
}

local function newPart(
	parent: Instance,
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material?
): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cframe
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanTouch = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = parent
	return p
end

local function decor(
	parent: Instance,
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material?
): Part
	local p = newPart(parent, name, size, cframe, color, material)
	p.CanCollide = false
	p.CanQuery = false
	p.CastShadow = false
	return p
end

local function oval(parent: Instance, name: string, size: Vector3, cframe: CFrame, color: Color3): Part
	local p = decor(parent, name, size, cframe, color)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = p
	return p
end

local function cylinder(
	parent: Instance,
	name: string,
	length: number,
	diameter: number,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material?
): Part
	-- El eje del cilindro de Roblox es X: se gira para que quede vertical salvo que cframe diga otra cosa.
	local p = decor(parent, name, Vector3.new(length, diameter, diameter), cframe, color, material)
	p.Shape = Enum.PartType.Cylinder
	return p
end

local function upright(position: Vector3): CFrame
	return CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90))
end

-- 1. Luz y cielo
for _, name in { "ValleAtmosphere", "ValleSky", "ValleColor", "ValleBloom", "ValleSunRays" } do
	local old = Lighting:FindFirstChild(name)
	if old ~= nil then
		old:Destroy()
	end
end
Lighting.ClockTime = 14.5
Lighting.Brightness = 2.6
Lighting.Ambient = Color3.fromRGB(90, 90, 110)
Lighting.OutdoorAmbient = Color3.fromRGB(150, 150, 165)
Lighting.EnvironmentDiffuseScale = 0.6
Lighting.EnvironmentSpecularScale = 0.4
local atmosphere = Instance.new("Atmosphere")
atmosphere.Name = "ValleAtmosphere"
atmosphere.Density = 0.28
atmosphere.Offset = 0.2
atmosphere.Color = Color3.fromRGB(200, 225, 255)
atmosphere.Decay = Color3.fromRGB(120, 160, 210)
atmosphere.Glare = 0.2
atmosphere.Haze = 1.2
atmosphere.Parent = Lighting
local sky = Instance.new("Sky")
sky.Name = "ValleSky"
sky.SunAngularSize = 14
sky.Parent = Lighting
local color = Instance.new("ColorCorrectionEffect")
color.Name = "ValleColor"
color.Saturation = 0.18
color.Contrast = 0.06
color.Brightness = 0.02
color.Parent = Lighting
local bloom = Instance.new("BloomEffect")
bloom.Name = "ValleBloom"
bloom.Intensity = 0.35
bloom.Size = 20
bloom.Threshold = 1.6
bloom.Parent = Lighting
local rays = Instance.new("SunRaysEffect")
rays.Name = "ValleSunRays"
rays.Intensity = 0.04
rays.Parent = Lighting

-- 2. Suelo, plaza, acantilado y rampa
local function restyle(path: { string }, colorValue: Color3, material: Enum.Material)
	local node: Instance? = map
	for _, step in path do
		node = if node ~= nil then node:FindFirstChild(step) else nil
	end
	if node == nil then
		return
	end
	local targets: { Instance } = if node:IsA("BasePart") then { node :: Instance } else node:GetChildren()
	for _, child in targets do
		if child:IsA("BasePart") then
			child.Color = colorValue
			child.Material = material
		end
	end
end
restyle({ "Ground" }, GRASS, Enum.Material.Grass)
restyle({ "Start", "Plaza" }, STONE, Enum.Material.Cobblestone)
restyle({ "Cliff", "Cliff" }, Color3.fromRGB(140, 128, 112), Enum.Material.Rock)
restyle({ "Cliff", "Ramp" }, WOOD, Enum.Material.WoodPlanks)

local old = map:FindFirstChild("Decor")
if old ~= nil then
	old:Destroy()
end
local decorFolder = Instance.new("Folder")
decorFolder.Name = "Decor"
decorFolder.Parent = map

local cliff = map:FindFirstChild("Cliff")
local cliffPart = if cliff ~= nil then cliff:FindFirstChild("Cliff") else nil
if cliffPart ~= nil and cliffPart:IsA("BasePart") then
	-- Tapa de pasto arriba del acantilado (un poco más baja que la plataforma de despegue)
	local top = cliffPart.Position.Y + cliffPart.Size.Y / 2
	local cap = newPart(
		decorFolder,
		"CliffGrass",
		Vector3.new(cliffPart.Size.X + 2, 0.8, cliffPart.Size.Z + 2),
		CFrame.new(cliffPart.Position.X, top + 0.2, cliffPart.Position.Z),
		GRASS,
		Enum.Material.Grass
	)
	cap.CastShadow = false
end

-- 3. Máquinas con forma de pesas de gimnasio (la Base con el ProximityPrompt no se mueve)
for i, machine in CollectionService:GetTagged("TrainingMachine") do
	if not machine:IsA("Model") then
		continue
	end
	local oldDeco = machine:FindFirstChild("Deco")
	if oldDeco ~= nil then
		oldDeco:Destroy()
	end
	local base = machine:FindFirstChild("Base")
	if base == nil or not base:IsA("BasePart") then
		continue
	end
	local weight = machine:FindFirstChild("Weight")
	if weight ~= nil and weight:IsA("BasePart") then
		weight.Transparency = 1
		weight.CanCollide = false
	end
	base.Color = Color3.fromRGB(55, 58, 68)
	base.Material = Enum.Material.Rubber
	local deco = Instance.new("Model")
	deco.Name = "Deco"
	deco.Parent = machine
	local plate = PLATES[(i - 1) % #PLATES + 1]
	local c = base.Position
	local topY = c.Y + base.Size.Y / 2
	decor(
		deco,
		"Mat",
		Vector3.new(12, 0.3, 12),
		CFrame.new(c.X, 1.15, c.Z),
		plate:Lerp(Color3.new(0, 0, 0), 0.55),
		Enum.Material.Rubber
	)
	decor(
		deco,
		"Pad",
		Vector3.new(7, 0.8, 3),
		CFrame.new(c.X, topY + 0.4, c.Z + 1.5),
		Color3.fromRGB(30, 30, 36),
		Enum.Material.Fabric
	)
	for side = -1, 1, 2 do
		cylinder(
			deco,
			"Upright",
			5,
			0.5,
			upright(Vector3.new(c.X + 3.4 * side, topY + 2.5, c.Z - 1.5)),
			METAL,
			Enum.Material.Metal
		)
		cylinder(deco, "PlateBig", 0.6, 3.2, CFrame.new(c.X + 4.4 * side, topY + 4.8, c.Z - 1.5), plate)
		cylinder(
			deco,
			"PlateSmall",
			0.5,
			2.2,
			CFrame.new(c.X + 3.9 * side, topY + 4.8, c.Z - 1.5),
			plate:Lerp(Color3.new(1, 1, 1), 0.3)
		)
	end
	cylinder(
		deco,
		"Bar",
		10,
		0.35,
		CFrame.new(c.X, topY + 4.8, c.Z - 1.5),
		Color3.fromRGB(200, 205, 215),
		Enum.Material.Metal
	)
end

-- 4. Nido de ramas alrededor de los 12 lugares
local slots = CollectionService:GetTagged("NestSlot")
if #slots > 0 then
	local minP = Vector3.new(math.huge, 0, math.huge)
	local maxP = Vector3.new(-math.huge, 0, -math.huge)
	for _, slot in slots do
		if slot:IsA("BasePart") then
			minP = Vector3.new(math.min(minP.X, slot.Position.X), 0, math.min(minP.Z, slot.Position.Z))
			maxP = Vector3.new(math.max(maxP.X, slot.Position.X), 0, math.max(maxP.Z, slot.Position.Z))
			slot.Color = STRAW
			slot.Material = Enum.Material.Grass
		end
	end
	local center = (minP + maxP) / 2
	local radiusX = (maxP.X - minP.X) / 2 + 12
	local radiusZ = (maxP.Z - minP.Z) / 2 + 12
	local nest = Instance.new("Model")
	nest.Name = "NestDeco"
	nest.Parent = decorFolder
	oval(
		nest,
		"Straw",
		Vector3.new(radiusX * 2, 1.4, radiusZ * 2),
		CFrame.new(center.X, 0.6, center.Z),
		STRAW
	)
	local count = 32
	for layer = 0, 1 do
		for k = 0, count - 1 do
			local angle = (k + layer * 0.5) / count * math.pi * 2
			local pos = Vector3.new(
				center.X + math.cos(angle) * radiusX,
				1.5 + layer * 1.6,
				center.Z + math.sin(angle) * radiusZ
			)
			local tangent = Vector3.new(-math.sin(angle) * radiusX, 0, math.cos(angle) * radiusZ).Unit
			local cf = CFrame.lookAt(pos, pos + tangent)
				* CFrame.Angles(0, math.rad(90), math.rad((k % 3 - 1) * 8))
			cylinder(
				nest,
				"Twig",
				14,
				2.2 - layer * 0.4,
				cf,
				if k % 2 == 0 then WOOD else WOOD_DARK,
				Enum.Material.Wood
			)
		end
	end
end

-- 5. Carteles de madera con letras redondas
for _, sign in map:GetDescendants() do
	if sign.Name ~= "Sign" or not sign:IsA("BasePart") then
		continue
	end
	sign.Color = WOOD
	sign.Material = Enum.Material.WoodPlanks
	for _, label in sign:GetDescendants() do
		if label:IsA("TextLabel") then
			label.Font = Enum.Font.FredokaOne
			label.TextColor3 = Color3.fromRGB(255, 248, 225)
			label.TextStrokeColor3 = WOOD_DARK
			label.TextStrokeTransparency = 0.2
			label.BackgroundTransparency = 1
		end
	end
	-- Postes para los carteles que están cerca del suelo
	if sign.Position.Y < 20 then
		local bottom = sign.Position.Y - sign.Size.Y / 2
		if bottom > 0.5 then
			for side = -1, 1, 2 do
				local x = sign.CFrame * Vector3.new(sign.Size.X / 2 * 0.8 * side, 0, 0)
				cylinder(
					decorFolder,
					"SignPost",
					bottom,
					0.6,
					upright(Vector3.new(x.X, bottom / 2, x.Z)),
					WOOD_DARK,
					Enum.Material.Wood
				)
			end
		end
	end
end

-- 6. Árboles, rocas y flores (lejos del camino de planeo, la plaza y el nido)
local rng = Random.new(7)
local function blocked(x: number, z: number): boolean
	if math.abs(x) < 110 and z > -700 and z < 4200 then
		return true -- plaza, rampa, acantilado y pista
	end
	if x > -280 and x < -120 and z > -640 and z < -470 then
		return true -- nido
	end
	return false
end
local function spot(): (number?, number?)
	for _ = 1, 20 do
		local x = rng:NextNumber(-420, 420)
		local z = if rng:NextNumber() < 0.45 then rng:NextNumber(-800, -380) else rng:NextNumber(-380, 4000)
		if not blocked(x, z) then
			return x, z
		end
	end
	return nil, nil
end

local trees = Instance.new("Folder")
trees.Name = "Trees"
trees.Parent = decorFolder
for _ = 1, 70 do
	local x, z = spot()
	if x == nil or z == nil then
		continue
	end
	local scale = rng:NextNumber(0.8, 1.5)
	local height = 10 * scale
	local trunk = cylinder(
		trees,
		"Trunk",
		height,
		2.2 * scale,
		upright(Vector3.new(x, height / 2, z)),
		WOOD,
		Enum.Material.Wood
	)
	trunk.CanCollide = true
	local leaf = GRASS_DARK:Lerp(Color3.fromRGB(150, 210, 90), rng:NextNumber())
	oval(trees, "Leaves", Vector3.new(11, 9, 11) * scale, CFrame.new(x, height + 3 * scale, z), leaf)
	oval(
		trees,
		"Leaves",
		Vector3.new(7, 6, 7) * scale,
		CFrame.new(x + 3 * scale, height + 6.5 * scale, z - 1),
		leaf:Lerp(Color3.new(1, 1, 1), 0.12)
	)
	oval(
		trees,
		"Leaves",
		Vector3.new(6, 5, 6) * scale,
		CFrame.new(x - 3 * scale, height + 1.5 * scale, z + 2),
		leaf:Lerp(Color3.new(0, 0, 0), 0.08)
	)
end

local rocks = Instance.new("Folder")
rocks.Name = "Rocks"
rocks.Parent = decorFolder
for _ = 1, 40 do
	local x, z = spot()
	if x == nil or z == nil then
		continue
	end
	local s = rng:NextNumber(2, 7)
	local rock = oval(
		rocks,
		"Rock",
		Vector3.new(s * 1.4, s * 0.8, s),
		CFrame.new(x, s * 0.25, z) * CFrame.Angles(0, rng:NextNumber(0, math.pi), 0),
		ROCK:Lerp(Color3.new(1, 1, 1), rng:NextNumber(0, 0.2))
	)
	rock.CanCollide = true
end

local flowers = Instance.new("Folder")
flowers.Name = "Flowers"
flowers.Parent = decorFolder
for _ = 1, 50 do
	local x, z = spot()
	if x == nil or z == nil then
		continue
	end
	local petal = FLOWERS[rng:NextInteger(1, #FLOWERS)]
	for _ = 1, 4 do
		local fx = x + rng:NextNumber(-3, 3)
		local fz = z + rng:NextNumber(-3, 3)
		oval(flowers, "Flower", Vector3.new(0.9, 0.5, 0.9), CFrame.new(fx, 0.35, fz), petal)
	end
end

-- 7. El mapa ya no es el gris
map:SetAttribute("Greybox", nil)
print("Valle verde listo")
