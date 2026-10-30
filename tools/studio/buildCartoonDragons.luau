--!strict
-- Construye en Studio los 15 dragones estilo caricatura (ReplicatedStorage.DragonModels).
-- Se corre en modo edición (barra de comandos o run_code del MCP). No es parte del juego: Rojo no lo sincroniza.
-- Reemplaza solo los modelos de bloques (atributo Greybox) y los de este script (atributo Cartoon);
-- los modelos reales de Isaac (sin esos atributos) no se tocan.
-- Cada modelo mira hacia -Z y su pivote es el cuerpo. Mantener la lista igual a Config/Dragons.luau.
-- Más rareza = más detalles: Common sencillo; Uncommon con púas; Rare con cuernos largos y cola de pala;
-- Epic con ojos que brillan y chispas; Legendary con corona dorada, alas con brillo, luz y más chispas.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

type Entry = { id: string, rarity: string, color: Color3, accent: Color3 }

local LIST: { Entry } = {
	{
		id = "PebbleDrake",
		rarity = "Common",
		color = Color3.fromRGB(130, 135, 140),
		accent = Color3.fromRGB(220, 215, 200),
	},
	{
		id = "MeadowWyrmling",
		rarity = "Common",
		color = Color3.fromRGB(120, 190, 90),
		accent = Color3.fromRGB(250, 230, 140),
	},
	{
		id = "DustyWhelp",
		rarity = "Common",
		color = Color3.fromRGB(190, 150, 105),
		accent = Color3.fromRGB(245, 225, 190),
	},
	{
		id = "MistWisp",
		rarity = "Uncommon",
		color = Color3.fromRGB(200, 225, 240),
		accent = Color3.fromRGB(150, 190, 255),
	},
	{
		id = "CopperScale",
		rarity = "Uncommon",
		color = Color3.fromRGB(205, 120, 65),
		accent = Color3.fromRGB(255, 210, 140),
	},
	{
		id = "RiverDrake",
		rarity = "Uncommon",
		color = Color3.fromRGB(70, 140, 215),
		accent = Color3.fromRGB(140, 230, 230),
	},
	{
		id = "StormGlider",
		rarity = "Rare",
		color = Color3.fromRGB(95, 105, 210),
		accent = Color3.fromRGB(255, 235, 90),
	},
	{
		id = "FrostFang",
		rarity = "Rare",
		color = Color3.fromRGB(160, 215, 245),
		accent = Color3.fromRGB(240, 250, 255),
	},
	{
		id = "EmberWing",
		rarity = "Rare",
		color = Color3.fromRGB(235, 95, 45),
		accent = Color3.fromRGB(255, 200, 60),
	},
	{
		id = "ThunderWyrm",
		rarity = "Epic",
		color = Color3.fromRGB(245, 205, 55),
		accent = Color3.fromRGB(90, 110, 255),
	},
	{
		id = "AuroraDrake",
		rarity = "Epic",
		color = Color3.fromRGB(110, 225, 190),
		accent = Color3.fromRGB(220, 120, 255),
	},
	{
		id = "ObsidianTerror",
		rarity = "Epic",
		color = Color3.fromRGB(45, 35, 60),
		accent = Color3.fromRGB(255, 60, 80),
	},
	{
		id = "SunfireSovereign",
		rarity = "Legendary",
		color = Color3.fromRGB(255, 165, 35),
		accent = Color3.fromRGB(255, 240, 120),
	},
	{
		id = "StarlightLeviathan",
		rarity = "Legendary",
		color = Color3.fromRGB(190, 170, 255),
		accent = Color3.fromRGB(255, 255, 255),
	},
	{
		id = "EternalVoidwing",
		rarity = "Legendary",
		color = Color3.fromRGB(85, 25, 140),
		accent = Color3.fromRGB(60, 255, 220),
	},
}

local TIER: { [string]: number } = { Common = 1, Uncommon = 2, Rare = 3, Epic = 4, Legendary = 5 }
local SCALE: { [string]: number } =
	{ Common = 0.55, Uncommon = 0.6, Rare = 0.68, Epic = 0.78, Legendary = 0.95 }

local WHITE = Color3.new(1, 1, 1)
local BLACK = Color3.fromRGB(25, 20, 30)
local CREAM = Color3.fromRGB(250, 240, 215)
local GOLD = Color3.fromRGB(255, 200, 50)
local BLUSH = Color3.fromRGB(255, 150, 170)

type Ctx = { model: Model, s: number }

local function newPart(
	ctx: Ctx,
	className: string,
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3
): BasePart
	local p = Instance.new(className) :: BasePart
	p.Name = name
	p.Size = size * ctx.s
	p.CFrame = CFrame.new(cframe.Position * ctx.s) * cframe.Rotation
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = ctx.model
	return p
end

-- Óvalo suave: una parte con SpecialMesh de esfera toma la forma de su tamaño.
local function oval(ctx: Ctx, name: string, size: Vector3, cframe: CFrame, color: Color3): BasePart
	local p = newPart(ctx, "Part", name, size, cframe, color)
	local mesh = Instance.new("SpecialMesh")
	mesh.MeshType = Enum.MeshType.Sphere
	mesh.Parent = p
	return p
end

local function at(x: number, y: number, z: number): CFrame
	return CFrame.new(x, y, z)
end

local function neon(p: BasePart, transparency: number?)
	p.Material = Enum.Material.Neon
	p.Transparency = transparency or 0
end

local function build(entry: Entry): Model
	local tier = TIER[entry.rarity] or 1
	local model = Instance.new("Model")
	model.Name = entry.id
	local ctx: Ctx = { model = model, s = SCALE[entry.rarity] or 0.6 }

	local main = entry.color
	local light = main:Lerp(WHITE, 0.55)
	local dark = main:Lerp(BLACK, 0.3)
	local wingColor = main:Lerp(entry.accent, 0.35)
	local hornColor = if tier >= 5 then GOLD elseif tier >= 4 then entry.accent else CREAM

	-- Cuerpo, panza, cabeza y hocico
	local body = oval(ctx, "Body", Vector3.new(2.6, 2.5, 3.4), at(0, 0, 0), main)
	oval(ctx, "Belly", Vector3.new(2.0, 2.2, 2.6), at(0, -0.25, -0.4), light)
	oval(ctx, "Head", Vector3.new(2.6, 2.4, 2.4), at(0, 1.5, -1.5), main)
	oval(ctx, "Snout", Vector3.new(1.5, 1.0, 1.2), at(0, 1.15, -2.65), light)
	for side = -1, 1, 2 do
		oval(ctx, "Nostril", Vector3.new(0.18, 0.18, 0.12), at(0.28 * side, 1.38, -3.22), dark)
		-- Ojos grandes con brillo
		oval(ctx, "Eye", Vector3.new(0.75, 0.95, 0.5), at(0.55 * side, 1.9, -2.5), WHITE)
		local pupil = oval(ctx, "Pupil", Vector3.new(0.42, 0.58, 0.2), at(0.58 * side, 1.86, -2.74), BLACK)
		if tier >= 4 then
			pupil.Color = entry.accent
			neon(pupil)
		end
		oval(ctx, "Shine", Vector3.new(0.16, 0.16, 0.08), at(0.5 * side, 2.04, -2.84), WHITE)
		oval(ctx, "Cheek", Vector3.new(0.45, 0.28, 0.2), at(0.95 * side, 1.3, -2.35), BLUSH)
		-- Patitas
		oval(ctx, "FrontLeg", Vector3.new(0.8, 1.0, 1.0), at(0.85 * side, -1.15, -0.8), main)
		oval(ctx, "BackLeg", Vector3.new(0.85, 1.0, 1.1), at(0.85 * side, -1.15, 0.9), main)
	end

	-- Cuernos: crecen con la rareza
	local hornSize = if tier >= 3
		then Vector3.new(0.42, 1.5, 0.42)
		else Vector3.new(0.38, 0.6 + 0.3 * tier, 0.38)
	for side = -1, 1, 2 do
		local horn = oval(
			ctx,
			"Horn",
			hornSize,
			at(0.5 * side, 2.6 + hornSize.Y * 0.2, -1.1)
				* CFrame.Angles(math.rad(30), 0, math.rad(-15 * side)),
			hornColor
		)
		if tier >= 5 then
			horn.Material = Enum.Material.Foil
		end
		if tier >= 4 then
			oval(
				ctx,
				"SmallHorn",
				Vector3.new(0.3, 0.8, 0.3),
				at(1.05 * side, 2.15, -0.95) * CFrame.Angles(math.rad(40), 0, math.rad(-45 * side)),
				hornColor
			)
		end
	end

	-- Cola en segmentos
	local tail: { { size: Vector3, cframe: CFrame } } = {
		{ size = Vector3.new(1.3, 1.2, 1.5), cframe = at(0, -0.4, 1.7) },
		{ size = Vector3.new(1.0, 0.9, 1.3), cframe = at(0, -0.35, 2.6) },
		{ size = Vector3.new(0.7, 0.65, 1.1), cframe = at(0, -0.1, 3.4) },
		{ size = Vector3.new(0.5, 0.45, 0.9), cframe = at(0, 0.25, 4.0) },
	}
	for i, seg in tail do
		oval(ctx, `Tail{i}`, seg.size, seg.cframe, main)
	end
	if tier >= 3 then
		local spade = oval(
			ctx,
			"TailSpade",
			Vector3.new(0.2, 1.0, 1.0),
			at(0, 0.55, 4.45) * CFrame.Angles(math.rad(45), 0, 0),
			entry.accent
		)
		if tier >= 4 then
			neon(spade)
		end
	end

	-- Púas en la espalda
	if tier >= 2 then
		local spikes = { at(0, 1.25, -0.2), at(0, 1.2, 0.55), at(0, 0.85, 1.3) }
		if tier >= 4 then
			table.insert(spikes, at(0, 0.35, 2.4))
			table.insert(spikes, at(0, 0.45, 3.2))
		end
		for i, cf in spikes do
			local spike = newPart(
				ctx,
				"WedgePart",
				`Spike{i}`,
				Vector3.new(0.15, 0.55, 0.6) * (1 + 0.1 * tier),
				cf,
				entry.accent
			)
			if tier >= 5 then
				neon(spike)
			end
		end
	end

	-- Alas: un óvalo plano por lado (Common); dos desde Uncommon; con brillo detrás en Legendary
	local wingScale = 0.8 + 0.12 * tier
	for side = -1, 1, 2 do
		local function wing(
			name: string,
			size: Vector3,
			x: number,
			y: number,
			z: number,
			color: Color3
		): BasePart
			return oval(
				ctx,
				name,
				size * wingScale,
				at(x * side * wingScale, y, z) * CFrame.Angles(0, math.rad(20 * side), math.rad(-55 * side)),
				color
			)
		end
		wing("Wing", Vector3.new(0.18, 2.6, 2.2), 1.8, 1.7, 0.4, wingColor)
		if tier >= 2 then
			wing("WingBack", Vector3.new(0.16, 1.9, 1.7), 1.5, 1.2, 1.2, wingColor:Lerp(entry.accent, 0.4))
		end
		if tier >= 3 then
			wing("WingBone", Vector3.new(0.3, 2.8, 0.3), 1.85, 1.85, -0.35, dark)
		end
		if tier >= 5 then
			local aura = wing("WingGlow", Vector3.new(0.12, 3.0, 2.6), 1.85, 1.75, 0.5, entry.accent)
			neon(aura, 0.45)
		end
	end

	-- Corona dorada para los legendarios
	if tier >= 5 then
		for i = 0, 4 do
			local angle = math.rad(i * 72)
			local cf = at(math.sin(angle) * 0.7, 2.8, -1.5 + math.cos(angle) * 0.7)
				* CFrame.Angles(0, angle, 0)
			local point = newPart(ctx, "WedgePart", `Crown{i}`, Vector3.new(0.12, 0.6, 0.35), cf, GOLD)
			point.Material = Enum.Material.Foil
		end
		local gem = oval(ctx, "Gem", Vector3.new(0.35, 0.35, 0.35), at(0, 2.75, -2.25), entry.accent)
		neon(gem)
	end

	-- Efectos: chispas desde Epic, luz en Legendary
	if tier >= 4 then
		local sparkles = Instance.new("ParticleEmitter")
		sparkles.Name = "Sparkles"
		sparkles.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		sparkles.Color = ColorSequence.new(entry.accent)
		sparkles.LightEmission = 1
		sparkles.Rate = if tier >= 5 then 8 else 3
		sparkles.Lifetime = NumberRange.new(0.8, 1.4)
		sparkles.Speed = NumberRange.new(0.5, 1.5)
		sparkles.SpreadAngle = Vector2.new(180, 180)
		sparkles.Size = NumberSequence.new(0.25 * ctx.s, 0)
		sparkles.Parent = body
	end
	if tier >= 5 then
		local glow = Instance.new("PointLight")
		glow.Color = entry.accent
		glow.Brightness = 1.5
		glow.Range = 10
		glow.Parent = body
	end

	model.PrimaryPart = body
	model:SetAttribute("Cartoon", true)
	model:SetAttribute("Rarity", entry.rarity)
	return model
end

local folder = ReplicatedStorage:FindFirstChild("DragonModels")
if folder == nil then
	local created = Instance.new("Folder")
	created.Name = "DragonModels"
	created.Parent = ReplicatedStorage
	folder = created
end
assert(folder ~= nil, "Falta la carpeta DragonModels")

local built = 0
for _, entry in LIST do
	local existing = folder:FindFirstChild(entry.id)
	if
		existing ~= nil
		and existing:GetAttribute("Greybox") ~= true
		and existing:GetAttribute("Cartoon") ~= true
	then
		continue -- modelo real de Isaac
	end
	if existing ~= nil then
		existing:Destroy()
	end
	build(entry).Parent = folder
	built += 1
end
print(`Dragones caricatura: {built} construidos`)
