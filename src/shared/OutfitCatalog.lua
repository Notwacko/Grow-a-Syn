local OutfitCatalog = {}

OutfitCatalog.styles = { "classic", "modest" }

OutfitCatalog.list = {
	{
		id = "starter",
		name = "Everyday Rabbi",
		tier = 1,
		blurb = "Kippah and tallit",
		classic = { "gear_kippah", "gear_tallit" },
		modest = { "gear_kippah", "gear_tallit", "skirt_navy" },
	},
	{
		id = "reform",
		name = "Reform Style",
		tier = 2,
		blurb = "Colorful kippah, tallit and a light blazer",
		classic = { "kippah_rainbow", "tallit_sky", "blazer_gray" },
		modest = { "kippah_rainbow", "tallit_sky", "blazer_gray", "skirt_gray" },
	},
	{
		id = "conservative",
		name = "Conservative Style",
		tier = 3,
		blurb = "Navy suit jacket, tie, kippah and striped tallit",
		classic = { "kippah_navy", "tallit_classic", "jacket_navy", "tie_blue" },
		modest = { "kippah_navy", "tallit_classic", "jacket_navy", "skirt_navy" },
	},
	{
		id = "orthodox",
		name = "Orthodox Style",
		tier = 4,
		blurb = "Knitted kippah, dark suit jacket and tzitzit",
		classic = { "kippah_knit", "tallit_classic", "jacket_black", "tzitzit" },
		modest = { "tichel_blue", "jacket_black", "skirt_black" },
	},
	{
		id = "ultra_orthodox",
		name = "Ultra-Orthodox Style",
		tier = 5,
		blurb = "Black hat, black suit and tzitzit",
		classic = { "kippah_velvet", "fedora_black", "jacket_black", "tzitzit", "beard" },
		modest = { "hat_modest", "jacket_black", "skirt_black" },
	},
	{
		id = "hasidic",
		name = "Hasidic Style",
		tier = 6,
		blurb = "Long black coat, gartel, wide black hat and white socks",
		classic = { "kippah_velvet", "hat_black_wide", "kapote_black", "gartel_black", "socks_white", "peyot", "beard" },
		modest = { "tichel_black", "jacket_black", "skirt_black" },
	},
	{
		id = "haredi",
		name = "Haredi Festive Style",
		tier = 7,
		blurb = "Silk coat, white gartel, fur hat and white socks",
		classic = { "kippah_velvet", "shtreimel", "bekishe_silk", "gartel_white", "socks_white", "tallit_gold", "peyot", "beard" },
		modest = { "tichel_silk", "jacket_velvet", "skirt_black" },
	},
}

OutfitCatalog.AUTO = "auto"

local byId = {}
for index, outfit in OutfitCatalog.list do
	outfit.order = index
	byId[outfit.id] = outfit
end

function OutfitCatalog.get(id)
	return byId[id]
end

function OutfitCatalog.forTier(tier)
	tier = math.floor(tonumber(tier) or 1)
	local best = OutfitCatalog.list[1]
	for _, outfit in OutfitCatalog.list do
		if outfit.tier <= tier then
			best = outfit
		end
	end
	return best
end

function OutfitCatalog.resolve(selection, tier)
	if selection == OutfitCatalog.AUTO or byId[selection] == nil then
		return OutfitCatalog.forTier(tier)
	end
	return byId[selection]
end

function OutfitCatalog.validStyle(style)
	return style == "classic" or style == "modest"
end

function OutfitCatalog.validSelection(selection)
	return selection == OutfitCatalog.AUTO or byId[selection] ~= nil
end

function OutfitCatalog.nextSelection(selection)
	if selection == OutfitCatalog.AUTO or byId[selection] == nil then
		return OutfitCatalog.list[1].id
	end
	local nextOutfit = OutfitCatalog.list[byId[selection].order + 1]
	if nextOutfit then
		return nextOutfit.id
	end
	return OutfitCatalog.AUTO
end

function OutfitCatalog.pieces(outfit, style)
	if OutfitCatalog.validStyle(style) and outfit[style] then
		return outfit[style]
	end
	return outfit.classic
end

return OutfitCatalog
