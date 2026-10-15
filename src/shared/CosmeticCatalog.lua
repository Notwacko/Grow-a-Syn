local CosmeticCatalog = {}

CosmeticCatalog.SLOTS = {
	{ id = "head", name = "Kippah" },
	{ id = "hat", name = "Hats" },
	{ id = "tallit", name = "Tallit" },
	{ id = "back", name = "Back" },
	{ id = "face", name = "Face" },
	{ id = "neck", name = "Neck" },
	{ id = "effect", name = "Effects" },
}

local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

local function kippah(base, mid, top)
	return { Base = base, Mid = mid or base, Top = top or mid or base }
end

CosmeticCatalog.RARITY_COLORS = {
	common = rgb(154, 165, 177),
	uncommon = rgb(43, 182, 115),
	rare = rgb(47, 128, 237),
	epic = rgb(155, 81, 224),
	legendary = rgb(242, 169, 0),
	mythical = rgb(255, 61, 154),
}

local list = {
	{ id = "kip_red", slot = "head", name = "Ruby Kippah", model = "ofit_kippah", colors = kippah(rgb(214, 60, 70), rgb(255, 120, 120), rgb(255, 214, 214)), money = 4000, rarity = "common" },
	{ id = "kip_sky", slot = "head", name = "Sky Kippah", model = "ofit_kippah", colors = kippah(rgb(70, 150, 235), rgb(130, 196, 255), rgb(220, 240, 255)), money = 4000, rarity = "common" },
	{ id = "kip_green", slot = "head", name = "Meadow Kippah", model = "ofit_kippah", colors = kippah(rgb(60, 170, 100), rgb(120, 220, 150), rgb(214, 255, 226)), money = 4000, rarity = "common" },
	{ id = "kip_orange", slot = "head", name = "Sunset Kippah", model = "ofit_kippah", colors = kippah(rgb(240, 130, 50), rgb(255, 180, 100), rgb(255, 232, 200)), money = 6000, rarity = "common" },
	{ id = "kip_pink", slot = "head", name = "Blossom Kippah", model = "ofit_kippah", colors = kippah(rgb(235, 110, 160), rgb(255, 170, 200), rgb(255, 226, 238)), money = 6000, rarity = "common" },
	{ id = "kip_teal", slot = "head", name = "Lagoon Kippah", model = "ofit_kippah", colors = kippah(rgb(40, 170, 170), rgb(110, 220, 220), rgb(210, 255, 255)), money = 10000, rarity = "uncommon" },
	{ id = "kip_black_gold", slot = "head", name = "Black and Gold Kippah", model = "ofit_kippah", colors = kippah(rgb(26, 26, 32), rgb(240, 190, 64), rgb(255, 232, 150)), money = 25000, rarity = "uncommon" },
	{ id = "kip_white_silver", slot = "head", name = "Silver Kippah", model = "ofit_kippah", colors = kippah(rgb(240, 240, 246), rgb(190, 196, 214), rgb(255, 255, 255)), money = 25000, rarity = "uncommon" },
	{ id = "kip_rainbowknit", slot = "head", name = "Rainbow Knit Kippah", model = "ofit_kippah_rainbowknit", money = 60000, rarity = "rare" },
	{ id = "kip_stripes", slot = "head", name = "Striped Kippah", model = "ofit_kippah_stripes", money = 150000, rarity = "rare" },
	{ id = "kip_emerald", slot = "head", name = "Emerald Kippah", model = "ofit_kippah_emerald", robux = 49, rarity = "rare" },
	{ id = "kip_purple", slot = "head", name = "Royal Purple Kippah", model = "ofit_kippah_purple", robux = 49, rarity = "rare" },
	{ id = "kip_starry", slot = "head", name = "Starry Night Kippah", model = "ofit_kippah_starry", robux = 99, rarity = "epic", premium = true },
	{ id = "kip_goldvelvet", slot = "head", name = "Golden Velvet Kippah", model = "ofit_kippah_goldvelvet", robux = 149, rarity = "epic", premium = true },

	{ id = "hat_flowers", slot = "hat", name = "Flower Crown", model = "ofit_hat_flowers", money = 400000, rarity = "rare" },
	{ id = "hat_sunhat", slot = "hat", name = "Garden Sun Hat", model = "ofit_hat_sunhat", money = 1200000, rarity = "rare" },
	{ id = "hat_crown", slot = "hat", name = "Golden Crown", model = "ofit_hat_crown", robux = 399, rarity = "legendary", premium = true },

	{ id = "tal_blue", slot = "tallit", name = "Blue Stripe Tallit", model = "ofit_tallit", colors = { Stripe = rgb(70, 120, 220) }, money = 12000, rarity = "common" },
	{ id = "tal_red", slot = "tallit", name = "Crimson Stripe Tallit", model = "ofit_tallit", colors = { Stripe = rgb(200, 60, 70) }, money = 12000, rarity = "common" },
	{ id = "tal_green", slot = "tallit", name = "Green Stripe Tallit", model = "ofit_tallit", colors = { Stripe = rgb(60, 160, 100) }, money = 12000, rarity = "common" },
	{ id = "tal_purple", slot = "tallit", name = "Violet Stripe Tallit", model = "ofit_tallit", colors = { Stripe = rgb(130, 90, 190) }, money = 30000, rarity = "uncommon" },
	{ id = "tal_gold", slot = "tallit", name = "Gold Stripe Tallit", model = "ofit_tallit", colors = { Stripe = rgb(240, 190, 64) }, money = 30000, rarity = "uncommon" },
	{ id = "tal_stone", slot = "tallit", name = "Jerusalem Stone Tallit", model = "ofit_tallit_stone", money = 250000, rarity = "rare" },
	{ id = "tal_royal", slot = "tallit", name = "Royal Tallit", model = "ofit_tallit_royal", money = 900000, rarity = "epic" },
	{ id = "tal_stars", slot = "tallit", name = "Starlight Tallit", model = "ofit_tallit_stars", robux = 99, rarity = "epic", premium = true },
	{ id = "tal_rainbow", slot = "tallit", name = "Rainbow Tallit", model = "ofit_tallit_rainbow", robux = 149, rarity = "epic", premium = true },
	{ id = "tal_gold_royal", slot = "tallit", name = "Golden Tallit", model = "ofit_tallit_gold", robux = 249, rarity = "legendary", premium = true },

	{ id = "pack_challah", slot = "back", name = "Challah Backpack", model = "ofit_pack_challah", money = 90000, rarity = "uncommon" },
	{ id = "pack_satchel", slot = "back", name = "Scholar Satchel", model = "ofit_pack_satchel", money = 350000, rarity = "rare" },
	{ id = "pack_candles", slot = "back", name = "Candlelight Pack", model = "ofit_pack_candles", robux = 149, rarity = "epic", premium = true },
	{ id = "cape_royal", slot = "back", name = "Royal Cape", model = "ofit_cape_royal", robux = 249, rarity = "epic", premium = true },
	{ id = "cape_starry", slot = "back", name = "Starry Cape", model = "ofit_cape_starry", robux = 399, rarity = "legendary", premium = true },
	{ id = "cape_gold", slot = "back", name = "Patron Golden Cape", model = "ofit_cape_gold", patron = true, rarity = "legendary" },
	{ id = "wings_dove", slot = "back", name = "Dove Wings", model = "ofit_wings_dove", robux = 399, rarity = "legendary", premium = true },
	{ id = "wings_gold", slot = "back", name = "Golden Wings", model = "ofit_wings_gold", robux = 799, rarity = "mythical", premium = true },

	{ id = "glasses_gold", slot = "face", name = "Golden Glasses", model = "ofit_glasses_gold", money = 45000, rarity = "uncommon" },

	{ id = "bowtie_blue", slot = "neck", name = "Blue Bow Tie", model = "ofit_bowtie_blue", money = 15000, rarity = "common" },

	{ id = "fx_sparkle", slot = "effect", name = "Golden Sparkles", effect = "sparkle", money = 200000, rarity = "rare" },
	{ id = "fx_stars", slot = "effect", name = "Star Aura", effect = "stars", robux = 99, rarity = "epic", premium = true },
	{ id = "fx_hearts", slot = "effect", name = "Heart Aura", effect = "hearts", robux = 99, rarity = "epic", premium = true },
	{ id = "fx_rainbow", slot = "effect", name = "Rainbow Trail", effect = "rainbow", robux = 249, rarity = "legendary", premium = true },
	{ id = "fx_snow", slot = "effect", name = "Snowfall", effect = "snow", money = 600000, rarity = "rare" },
	{ id = "fx_leaves", slot = "effect", name = "Falling Leaves", effect = "leaves", money = 350000, rarity = "rare" },
	{ id = "fx_confetti", slot = "effect", name = "Celebration Confetti", effect = "confetti", robux = 149, rarity = "epic", premium = true },
	{ id = "fx_glow", slot = "effect", name = "Warm Glow", effect = "glow", robux = 49, rarity = "rare" },
}

CosmeticCatalog.list = list

local byId = {}
for index, item in list do
	item.order = index
	byId[item.id] = item
end

function CosmeticCatalog.get(id)
	return byId[id]
end

function CosmeticCatalog.slot(id)
	for _, slot in CosmeticCatalog.SLOTS do
		if slot.id == id then
			return slot
		end
	end
	return nil
end

return CosmeticCatalog
