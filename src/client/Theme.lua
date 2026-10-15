-- Design tokens. Every UI file uses these and nothing else.
local Theme = {}

Theme.Font = Enum.Font.FredokaOne

Theme.TextSize = { XS = 12, S = 16, M = 20, L = 28, XL = 40 } -- 5 sizes
Theme.Radius = { S = 8, M = 16, L = 24 } -- 3 radii
Theme.Stroke = { Thin = 2, Thick = 4 } -- 2 outline thicknesses
Theme.Space = { XS = 4, S = 8, M = 12, L = 16, XL = 24, XXL = 32, Tab = 48, Touch = 56 } -- multiples of 4
Theme.Shadow = { Offset = 4, Transparency = 0.55 } -- one shadow style

Theme.Color = {
	Red = Color3.fromRGB(255, 70, 85),
	Orange = Color3.fromRGB(255, 150, 40),
	Yellow = Color3.fromRGB(255, 215, 40),
	Green = Color3.fromRGB(60, 205, 80),
	Blue = Color3.fromRGB(50, 150, 255),
	Purple = Color3.fromRGB(165, 85, 240),
	Grey = Color3.fromRGB(150, 160, 180),
	Panel = Color3.fromRGB(52, 60, 120),
	Ink = Color3.fromRGB(28, 22, 58),
	White = Color3.fromRGB(255, 255, 255),
}

Theme.Rainbow = { "Red", "Orange", "Yellow", "Green", "Blue", "Purple" }

-- default rarity colors; the catalog (rarityColors) overrides them when B provides colors
Theme.Rarity = {
	common = Theme.Color.Grey,
	uncommon = Theme.Color.Green,
	rare = Theme.Color.Blue,
	epic = Theme.Color.Purple,
	legendary = Theme.Color.Yellow,
	mythical = Theme.Color.Red,
}

function Theme.rarityColor(rarity, catalog)
	local override = catalog and catalog.rarityColors and catalog.rarityColors[rarity]
	return override or Theme.Rarity[rarity] or Theme.Color.Grey
end

function Theme.light(color)
	return color:Lerp(Theme.Color.White, 0.3)
end

function Theme.dark(color)
	return color:Lerp(Theme.Color.Ink, 0.25)
end

return Theme
