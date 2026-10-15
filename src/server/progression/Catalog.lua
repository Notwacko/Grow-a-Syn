local Balance = require(script.Parent.Balance)

local Catalog = {}

Catalog.rarities = {
	{ id = "common", name = "Common", color = Color3.fromRGB(200, 200, 200) },
	{ id = "uncommon", name = "Uncommon", color = Color3.fromRGB(80, 210, 90) },
	{ id = "rare", name = "Rare", color = Color3.fromRGB(50, 140, 255) },
	{ id = "epic", name = "Epic", color = Color3.fromRGB(170, 80, 255) },
	{ id = "legendary", name = "Legendary", color = Color3.fromRGB(255, 175, 20) },
	{ id = "mythical", name = "Mythical", color = Color3.fromRGB(255, 60, 130) },
}

Catalog.categories = {
	{ id = "torah", name = "Sefer Torah" },
	{ id = "ark", name = "Aron Kodesh" },
	{ id = "siddur", name = "Siddur" },
	{ id = "menorah", name = "Menorah" },
	{ id = "kiddush_cup", name = "Kiddush Cup" },
	{ id = "chandelier", name = "Chandelier" },
	{ id = "ornament", name = "Ornament" },
	{ id = "holiday_decor", name = "Holiday Decor" },
}

Catalog.denominations = {
	{
		id = "ashkenazi",
		name = "Ashkenazi",
		blurb = "Jews of Central and Eastern European heritage, with Yiddish roots and a rich tradition of cantorial prayer.",
		stageNames = { "Reform", "Conservative", "Orthodox", "Ultra Orthodox", "Hasidic", "Haredi" },
	},
	{
		id = "sephardic",
		name = "Sephardic",
		blurb = "Jews whose heritage traces to Spain and Portugal, later North Africa and Ottoman lands, with Ladino song.",
		stageNames = { "Masorti", "Kahal Kadosh", "Dati", "Torani", "Mekubalim", "Haredi" },
	},
	{
		id = "mizrahi",
		name = "Mizrahi",
		blurb = "Jews of Middle Eastern and Central Asian heritage, from Iraq, Iran, Yemen and Syria, with ancient prayer customs.",
		stageNames = { "Masorti", "Kehilla", "Dati", "Torani", "Hakhamim", "Haredi" },
	},
}

Catalog.slots = {
	torah = { prefix = "Slot_Torah", count = 6 },
	ark = { prefix = "Slot_Ark", count = 0 },
	siddur = { prefix = "Slot_Siddur", count = 4 },
	menorah = { prefix = "Slot_Menorah", count = 0 },
	kiddush_cup = { prefix = "Slot_Kiddush", count = 2 },
	chandelier = { prefix = "Slot_Chandelier", count = 2 },
	ornament = { prefix = "Slot_Ornament", count = 6 },
	holiday_decor = { prefix = "Slot_HolidayDecor", count = 4 },
}

local rarityById = {}
for _, r in ipairs(Catalog.rarities) do
	rarityById[r.id] = r
end

local categoryById = {}
for _, c in ipairs(Catalog.categories) do
	categoryById[c.id] = c
end

local denominationById = {}
for _, d in ipairs(Catalog.denominations) do
	denominationById[d.id] = d
end

local function itemName(category, rarity)
	return rarityById[rarity].name .. " " .. categoryById[category].name
end

local offers = {}

for _, category in ipairs(Balance.CategoryOrder) do
	for _, rarity in ipairs(Balance.RarityOrder) do
		table.insert(offers, {
			id = category .. "_" .. rarity,
			kind = "item",
			category = category,
			rarity = rarity,
			name = itemName(category, rarity),
			priceMoney = Balance.itemPrice(category, rarity),
			minTier = Balance.RarityMinTier[rarity],
		})
	end
end

for tier = 3, Balance.MaxTier do
	table.insert(offers, {
		id = "building_t" .. tier,
		kind = "building",
		name = "Building Tier " .. tier,
		priceMoney = Balance.UpgradeCost[tier],
		tier = tier,
	})
end

for _, category in ipairs(Balance.CategoryOrder) do
	for _, rarity in ipairs(Balance.RobuxItemRarities) do
		table.insert(offers, {
			id = category .. "_" .. rarity .. "_robux",
			kind = "item",
			category = category,
			rarity = rarity,
			name = itemName(category, rarity),
			priceRobux = Balance.RobuxItemPrice[rarity],
		})
	end
end

for _, pack in ipairs(Balance.MoneyPacks) do
	local amountByTier = {}
	for tier = 1, Balance.MaxTier do
		amountByTier[tier] = Balance.moneyPackAmount(pack.scale, tier)
	end
	table.insert(offers, {
		id = pack.id,
		kind = "money_pack",
		name = pack.name,
		priceRobux = pack.priceRobux,
		scale = pack.scale,
		amountByTier = amountByTier,
	})
end

for _, boost in ipairs(Balance.Boosts) do
	table.insert(offers, {
		id = boost.id,
		kind = "boost",
		name = boost.name,
		priceRobux = boost.priceRobux,
		multiplier = boost.multiplier,
		durationSeconds = boost.durationSeconds,
	})
end

Catalog.offers = offers

local offerById = {}
for _, o in ipairs(offers) do
	offerById[o.id] = o
end

function Catalog.rarity(id)
	return rarityById[id]
end

function Catalog.category(id)
	return categoryById[id]
end

function Catalog.denomination(id)
	return denominationById[id]
end

function Catalog.offer(id)
	return offerById[id]
end

function Catalog.isValidSlot(category, slotName)
	local rule = Catalog.slots[category]
	if not rule then
		return false
	end
	if rule.count == 0 then
		return slotName == rule.prefix
	end
	for i = 1, rule.count do
		if slotName == rule.prefix .. i then
			return true
		end
	end
	return false
end

local function clientItem(o)
	local nextRarity = Balance.nextRarity(o.rarity)
	return {
		id = o.id,
		kind = "item",
		name = o.name,
		category = o.category,
		rarity = o.rarity,
		price = o.priceMoney,
		robux = o.priceRobux,
		minTier = o.minTier,
		model = o.category,
		mergesTo = nextRarity and (o.category .. "_" .. nextRarity) or nil,
	}
end

function Catalog.public(products, tier)
	local list = {}
	local items, packs, boosts = {}, {}, {}
	for _, o in ipairs(offers) do
		if not o.priceRobux or (products[o.id] or 0) > 0 then
			table.insert(list, table.clone(o))
			if o.kind == "item" then
				table.insert(items, clientItem(o))
			elseif o.kind == "money_pack" then
				table.insert(packs, { id = o.id, kind = "pack", name = o.name, robux = o.priceRobux, money = Balance.moneyPackAmount(o.scale, tier) })
			elseif o.kind == "boost" then
				table.insert(boosts, { id = o.id, kind = "boost", name = o.name, robux = o.priceRobux, mult = o.multiplier, duration = o.durationSeconds })
			end
		end
	end
	local denominations = {}
	for _, d in ipairs(Catalog.denominations) do
		table.insert(denominations, { id = d.id, name = d.name, blurb = d.blurb, stageNames = d.stageNames, stages = d.stageNames, model = d.id .. "_T2" })
	end
	local rarityColors = {}
	for _, r in ipairs(Catalog.rarities) do
		rarityColors[r.id] = r.color
	end
	local upgrades = {}
	for t = 1, Balance.MaxTier do
		upgrades[t] = {
			cost = Balance.UpgradeCost[t] or 0,
			requirement = t == 2 and "Choose a denomination" or (t > 2 and ("Land tier " .. (t - 1)) or ""),
		}
	end
	return {
		rarities = Catalog.rarities,
		categories = Catalog.categories,
		denominations = denominations,
		offers = list,
		items = items,
		buildings = {},
		packs = packs,
		boosts = boosts,
		upgrades = upgrades,
		rarityColors = rarityColors,
	}
end

return Catalog
