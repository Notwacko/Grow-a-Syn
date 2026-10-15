local Theme = {}

local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

Theme.ink = rgb(30, 42, 74)
Theme.inkSoft = rgb(66, 78, 112)
Theme.cream = rgb(255, 244, 220)
Theme.cream2 = rgb(246, 228, 192)
Theme.cardBase = rgb(255, 250, 238)
Theme.white = rgb(255, 255, 255)
Theme.disabled = rgb(184, 191, 204)
Theme.muted = rgb(120, 130, 156)

Theme.blue = { rgb(91, 155, 255), rgb(46, 106, 217) }
Theme.green = { rgb(91, 214, 106), rgb(47, 178, 74) }
Theme.gold = { rgb(255, 210, 63), rgb(245, 165, 36) }
Theme.red = { rgb(255, 107, 107), rgb(224, 62, 62) }
Theme.purple = { rgb(167, 118, 255), rgb(124, 77, 224) }
Theme.orange = { rgb(255, 170, 84), rgb(240, 120, 36) }
Theme.teal = { rgb(70, 214, 214), rgb(30, 160, 170) }
Theme.gray = { rgb(200, 208, 222), rgb(150, 160, 182) }
Theme.navy = { rgb(70, 90, 150), rgb(40, 54, 102) }

Theme.titleFont = Enum.Font.FredokaOne
Theme.bodyFont = Enum.Font.GothamBold
Theme.softFont = Enum.Font.Gotham

Theme.radius = { panel = 22, card = 16, button = 14, pill = 999 }

Theme.rarity = {
	common = { name = "Common", color = rgb(154, 165, 177), pips = 1, stroke = 3 },
	uncommon = { name = "Uncommon", color = rgb(43, 182, 115), pips = 2, stroke = 3 },
	rare = { name = "Rare", color = rgb(47, 128, 237), pips = 3, stroke = 4 },
	epic = { name = "Epic", color = rgb(155, 81, 224), pips = 4, stroke = 4 },
	legendary = { name = "Legendary", color = rgb(242, 169, 0), pips = 5, stroke = 5 },
	mythical = { name = "Mythical", color = rgb(255, 61, 154), pips = 6, stroke = 6 },
}

Theme.rarityOrder = { "common", "uncommon", "rare", "epic", "legendary", "mythical" }

Theme.colorblind = {
	common = rgb(150, 150, 150),
	uncommon = rgb(0, 158, 115),
	rare = rgb(0, 114, 178),
	epic = rgb(204, 121, 167),
	legendary = rgb(230, 159, 0),
	mythical = rgb(213, 94, 0),
}

Theme.useColorblind = false

function Theme.rarityColor(id)
	if Theme.useColorblind and Theme.colorblind[id] then
		return Theme.colorblind[id]
	end
	local entry = Theme.rarity[id]
	return entry and entry.color or Theme.rarity.common.color
end

function Theme.shade(color, amount)
	return color:Lerp(Color3.new(0, 0, 0), amount)
end

function Theme.tint(color, amount)
	return color:Lerp(Color3.new(1, 1, 1), amount)
end

return Theme
