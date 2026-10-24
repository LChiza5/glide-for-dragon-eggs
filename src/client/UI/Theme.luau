--!strict
-- Dueño: José.
-- Colores, letras y espacios de toda la interfaz. Nunca escribir un Color3 suelto en un componente:
-- se agrega aquí y se usa desde aquí.

local Theme = {
	-- Colores
	Surface = Color3.fromRGB(24, 28, 48),
	SurfaceElevated = Color3.fromRGB(36, 42, 70),
	Primary = Color3.fromRGB(255, 153, 51), -- naranja fuego de dragón
	OnPrimary = Color3.fromRGB(40, 20, 0),
	Text = Color3.fromRGB(245, 247, 255),
	TextMuted = Color3.fromRGB(170, 178, 205),
	Coins = Color3.fromRGB(255, 214, 64),
	Power = Color3.fromRGB(120, 200, 255),

	-- Letras
	Font = Font.fromEnum(Enum.Font.FredokaOne),

	-- Escala de espacios (px): 4 8 12 16 24 32 48
	Space = table.freeze({ XS = 4, S = 8, M = 12, L = 16, XL = 24, XXL = 32, XXXL = 48 }),

	-- Radios de borde: solo dos
	RadiusButton = UDim.new(0, 12),
	RadiusPanel = UDim.new(0, 16),
}

return table.freeze(Theme)
