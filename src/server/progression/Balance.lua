local Balance = {}

Balance.MaxTier = 7
Balance.MaxItems = 200

Balance.RarityOrder = { "common", "uncommon", "rare", "epic", "legendary", "mythical" }

Balance.RarityWeight = {
	common = 1,
	uncommon = 1.5,
	rare = 2.25,
	epic = 3.5,
	legendary = 5.5,
	mythical = 9,
}

Balance.TierIncomeMult = { 1, 1.5, 2.5, 4, 7, 12, 20 }

Balance.TierWelcome = { 0, 0.2, 0.4, 0.6, 0.9, 1.2, 1.6 }

Balance.UpgradeCost = {
	[2] = 0,
	[3] = 12000,
	[4] = 100000,
	[5] = 600000,
	[6] = 4000000,
	[7] = 25000000,
}

Balance.CategoryIncome = {
	torah = 0.05,
	ark = 0.15,
	siddur = 0.02,
	menorah = 0.06,
	kiddush_cup = 0.03,
	chandelier = 0.05,
	ornament = 0.02,
	holiday_decor = 0.02,
}

Balance.CategoryWelcome = {
	torah = 0,
	ark = 0.1,
	siddur = 0.05,
	menorah = 0,
	kiddush_cup = 0,
	chandelier = 0.04,
	ornament = 0.03,
	holiday_decor = 0.04,
}

Balance.CategoryOrder = { "siddur", "ornament", "holiday_decor", "kiddush_cup", "ark", "menorah", "torah", "chandelier" }

Balance.CategoryBasePrice = {
	siddur = 50,
	ornament = 120,
	holiday_decor = 150,
	kiddush_cup = 200,
	ark = 300,
	menorah = 400,
	torah = 500,
	chandelier = 600,
}

Balance.RarityPriceMult = {
	common = 1,
	uncommon = 8,
	rare = 60,
	epic = 400,
	legendary = 2500,
	mythical = 15000,
}

Balance.RarityMinTier = {
	common = 1,
	uncommon = 2,
	rare = 3,
	epic = 4,
	legendary = 5,
	mythical = 6,
}

Balance.RobuxItemRarities = { "epic", "legendary", "mythical" }

Balance.RobuxItemPrice = {
	epic = 79,
	legendary = 199,
	mythical = 499,
}

Balance.MoneyPacks = {
	{ id = "money_pack_small", name = "Small Money Pack", priceRobux = 49, scale = 1 },
	{ id = "money_pack_medium", name = "Medium Money Pack", priceRobux = 149, scale = 4 },
	{ id = "money_pack_large", name = "Large Money Pack", priceRobux = 399, scale = 12 },
}

Balance.MoneyPackBase = { 2000, 5000, 20000, 60000, 200000, 600000, 2000000 }

Balance.Boosts = {
	{ id = "boost_x2_15m", name = "x2 Money 15 min", priceRobux = 49, multiplier = 2, durationSeconds = 900 },
	{ id = "boost_x2_60m", name = "x2 Money 1 hour", priceRobux = 149, multiplier = 2, durationSeconds = 3600 },
}

Balance.TorahMilestones = {
	minyan = "common",
	tier2 = "uncommon",
	tier3 = "uncommon",
	tier4 = "rare",
	tier5 = "epic",
	tier6 = "legendary",
	tier7 = "mythical",
}

Balance.RaritySkin = {
	common = { material = Enum.Material.SmoothPlastic },
	uncommon = { material = Enum.Material.SmoothPlastic },
	rare = { material = Enum.Material.Metal },
	epic = { material = Enum.Material.Foil, glow = 8 },
	legendary = { material = Enum.Material.Foil, glow = 10, particles = 3 },
	mythical = { material = Enum.Material.Foil, glow = 12, particles = 5 },
}

Balance.RemoteCooldown = 0.25
Balance.AutosaveSeconds = 60
Balance.LoadRetries = 5
Balance.SaveRetries = 3

local function round2(n)
	return math.floor(n * 100 + 0.5) / 100
end

function Balance.incomeMult(tier, equippedItems)
	local bonus = 0
	for _, item in ipairs(equippedItems) do
		bonus += (Balance.CategoryIncome[item.category] or 0) * (Balance.RarityWeight[item.rarity] or 1)
	end
	return round2((Balance.TierIncomeMult[tier] or 1) * (1 + bonus))
end

function Balance.welcomeBonus(tier, equippedItems)
	local bonus = Balance.TierWelcome[tier] or 0
	for _, item in ipairs(equippedItems) do
		bonus += (Balance.CategoryWelcome[item.category] or 0) * (Balance.RarityWeight[item.rarity] or 1)
	end
	return round2(bonus)
end

function Balance.itemPrice(category, rarity)
	return Balance.CategoryBasePrice[category] * Balance.RarityPriceMult[rarity]
end

function Balance.moneyPackAmount(scale, tier)
	return (Balance.MoneyPackBase[tier] or Balance.MoneyPackBase[1]) * scale
end

function Balance.nextRarity(rarity)
	for i, id in ipairs(Balance.RarityOrder) do
		if id == rarity then
			return Balance.RarityOrder[i + 1]
		end
	end
	return nil
end

return Balance
