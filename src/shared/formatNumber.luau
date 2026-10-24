--!strict
-- Números grandes para la UI: 950 -> "950", 1234 -> "1.2K", 5_600_000 -> "5.6M".

local SUFFIXES = { "", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc" }

local function formatNumber(value: number): string
	local magnitude = math.abs(value)
	if magnitude < 1000 then
		return tostring(math.floor(value))
	end

	local tier = math.min(math.floor(math.log10(magnitude) / 3), #SUFFIXES - 1)
	-- Truncar (no redondear) para no mostrar "1000K" en vez de "1M".
	local scaled = math.floor(value / 1000 ^ tier * 10) / 10
	return `{scaled}{SUFFIXES[tier + 1]}`
end

return formatNumber
