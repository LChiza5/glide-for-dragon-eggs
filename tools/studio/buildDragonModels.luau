--!strict
-- Construye en Studio los dragones de bloques que sirven de molde (ReplicatedStorage.DragonModels).
-- Se corre en modo edición (barra de comandos o run_code del MCP). No es parte del juego: Rojo no lo sincroniza.
-- Respeta los modelos reales de Isaac: solo reemplaza los que tienen el atributo Greybox = true.
-- Cada modelo mira hacia -Z (como el personaje) y su pivote es el cuerpo. Mantener la lista igual a Config/Dragons.luau.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

type Entry = { id: string, rarity: string, color: Color3 }

local LIST: { Entry } = {
	{ id = "PebbleDrake", rarity = "Common", color = Color3.fromRGB(120, 120, 110) },
	{ id = "MeadowWyrmling", rarity = "Common", color = Color3.fromRGB(110, 160, 80) },
	{ id = "DustyWhelp", rarity = "Common", color = Color3.fromRGB(170, 140, 100) },
	{ id = "MistWisp", rarity = "Uncommon", color = Color3.fromRGB(200, 220, 230) },
	{ id = "CopperScale", rarity = "Uncommon", color = Color3.fromRGB(190, 110, 60) },
	{ id = "RiverDrake", rarity = "Uncommon", color = Color3.fromRGB(70, 130, 200) },
	{ id = "StormGlider", rarity = "Rare", color = Color3.fromRGB(100, 110, 200) },
	{ id = "FrostFang", rarity = "Rare", color = Color3.fromRGB(150, 210, 240) },
	{ id = "EmberWing", rarity = "Rare", color = Color3.fromRGB(230, 100, 40) },
	{ id = "ThunderWyrm", rarity = "Epic", color = Color3.fromRGB(240, 210, 60) },
	{ id = "AuroraDrake", rarity = "Epic", color = Color3.fromRGB(120, 230, 190) },
	{ id = "ObsidianTerror", rarity = "Epic", color = Color3.fromRGB(40, 30, 50) },
	{ id = "SunfireSovereign", rarity = "Legendary", color = Color3.fromRGB(255, 170, 30) },
	{ id = "StarlightLeviathan", rarity = "Legendary", color = Color3.fromRGB(200, 180, 255) },
	{ id = "EternalVoidwing", rarity = "Legendary", color = Color3.fromRGB(90, 20, 140) },
}

local SCALE: { [string]: number } = { Common = 1, Uncommon = 1.15, Rare = 1.3, Epic = 1.5, Legendary = 1.8 }

local function part(
	model: Model,
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
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = model
	return p
end

local function build(entry: Entry): Model
	local s = SCALE[entry.rarity] or 1
	local dark = entry.color:Lerp(Color3.new(0, 0, 0), 0.35)
	local model = Instance.new("Model")
	model.Name = entry.id
	model:SetAttribute("Greybox", true)
	model:SetAttribute("Rarity", entry.rarity)

	local base = CFrame.new()
	local body = part(model, "Body", Vector3.new(2, 1.5, 3) * s, base, entry.color)
	part(model, "Head", Vector3.new(1.4, 1.2, 1.4) * s, base * CFrame.new(0, 0.6 * s, -2 * s), entry.color)
	part(model, "Snout", Vector3.new(0.9, 0.6, 0.8) * s, base * CFrame.new(0, 0.4 * s, -3 * s), dark)
	for _, x in { -0.4, 0.4 } do
		part(
			model,
			"Eye",
			Vector3.new(0.25, 0.25, 0.1) * s,
			base * CFrame.new(x * s, 0.85 * s, -2.71 * s),
			Color3.new(1, 1, 1),
			Enum.Material.Neon
		)
		local wing = part(
			model,
			"Wing",
			Vector3.new(2.6, 0.2, 1.8) * s,
			base * CFrame.new(x * 4 * s, 0.6 * s, 0) * CFrame.Angles(0, 0, x * 0.9),
			dark
		)
		wing.Transparency = 0.1
	end
	part(
		model,
		"Tail",
		Vector3.new(0.6, 0.6, 2.4) * s,
		base * CFrame.new(0, 0.1 * s, 2.6 * s) * CFrame.Angles(0.25, 0, 0),
		dark
	)
	if entry.rarity ~= "Common" and entry.rarity ~= "Uncommon" then
		for _, x in { -0.4, 0.4 } do
			part(
				model,
				"Horn",
				Vector3.new(0.2, 0.7, 0.2) * s,
				base * CFrame.new(x * s, 1.45 * s, -1.8 * s) * CFrame.Angles(-0.4, 0, 0),
				dark
			)
		end
	end
	if entry.rarity == "Epic" or entry.rarity == "Legendary" then
		part(
			model,
			"Crest",
			Vector3.new(0.2, 0.5, 2.6) * s,
			base * CFrame.new(0, 0.95 * s, 0),
			entry.color:Lerp(Color3.new(1, 1, 1), 0.4),
			Enum.Material.Neon
		)
	end
	if entry.rarity == "Legendary" then
		local glow = Instance.new("PointLight")
		glow.Color = entry.color
		glow.Range = 10
		glow.Brightness = 1.5
		glow.Parent = body
	end
	model.PrimaryPart = body
	return model
end

local folder = ReplicatedStorage:FindFirstChild("DragonModels")
if folder == nil then
	folder = Instance.new("Folder")
	folder.Name = "DragonModels"
	folder.Parent = ReplicatedStorage
end
assert(folder ~= nil, "no se pudo crear DragonModels")

local built, kept = 0, 0
for _, entry in LIST do
	local existing = folder:FindFirstChild(entry.id)
	if existing ~= nil and existing:GetAttribute("Greybox") ~= true then
		kept += 1
	else
		if existing ~= nil then
			existing:Destroy()
		end
		build(entry).Parent = folder
		built += 1
	end
end
print(`DragonModels: {built} de bloques creados, {kept} modelos de Isaac respetados`)
