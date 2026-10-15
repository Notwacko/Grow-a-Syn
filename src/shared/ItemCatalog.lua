local fromRGB = Color3 and Color3.fromRGB or function(r, g, b)
	return { r, g, b }
end
local newRandom = Random and Random.new

local ItemCatalog = {}

ItemCatalog.RESTOCK_SECONDS = 300
ItemCatalog.PATRON_RESTOCK_SECONDS = 240
ItemCatalog.MAX_ITEMS = 400
ItemCatalog.MERGE_COUNT = 3
ItemCatalog.SHOP_SLOTS = 8
ItemCatalog.STARTER_SHELF = { id = "siddur_common", quantity = 6 }
ItemCatalog.PITY = { rare = 6, epic = 18, legendary = 60 }

ItemCatalog.RARITIES = {
	{ id = "common", name = "Common", color = fromRGB(154, 165, 177), price = 1, bonus = 1, grow = 60, weight = 62, stockMin = 3, stockMax = 6 },
	{ id = "uncommon", name = "Uncommon", color = fromRGB(43, 182, 115), price = 5, bonus = 1.8, grow = 180, weight = 24, stockMin = 2, stockMax = 4 },
	{ id = "rare", name = "Rare", color = fromRGB(47, 128, 237), price = 25, bonus = 3.2, grow = 600, weight = 9, stockMin = 1, stockMax = 3 },
	{ id = "epic", name = "Epic", color = fromRGB(155, 81, 224), price = 120, bonus = 5.6, grow = 2400, weight = 4, stockMin = 1, stockMax = 2 },
	{ id = "legendary", name = "Legendary", color = fromRGB(242, 169, 0), price = 600, bonus = 10, grow = 10800, weight = 1, stockMin = 1, stockMax = 1 },
	{ id = "mythical", name = "Mythical", color = fromRGB(255, 61, 154), price = 3000, bonus = 18, grow = 43200, weight = 0.2, stockMin = 1, stockMax = 1 },
}

ItemCatalog.PREFIX = {
	common = "Simple",
	uncommon = "Fine",
	rare = "Silver",
	epic = "Golden",
	legendary = "Jeweled",
	mythical = "Majestic",
}

ItemCatalog.CATEGORIES = {
	{ id = "siddur", name = "Siddur", price = 50, bonus = 0.03, fit = 1.5, weight = 16 },
	{ id = "ornament", name = "Wall Ornament", price = 60, bonus = 0.03, fit = 2.1, weight = 15 },
	{ id = "kiddush_cup", name = "Kiddush Cup", price = 90, bonus = 0.04, fit = 1.2, weight = 14 },
	{ id = "holiday_decor", name = "Holiday Banner", price = 150, bonus = 0.05, fit = 4.6, weight = 12 },
	{ id = "menorah", name = "Menorah", price = 250, bonus = 0.08, fit = 3.2, weight = 10 },
	{ id = "torah", name = "Sefer Torah", price = 400, bonus = 0.1, fit = 2.1, weight = 6, noMerge = true },
	{ id = "chandelier", name = "Chandelier", price = 500, bonus = 0.1, fit = 4.2, weight = 8 },
	{ id = "ark", name = "Aron Kodesh", price = 700, bonus = 0.12, fit = 6.2, weight = 4 },
}

ItemCatalog.MUTATIONS = {
	{ id = "polished", name = "Polished", chance = 0.06, mult = 1.5, color = fromRGB(214, 226, 255) },
	{ id = "gilded", name = "Gilded", chance = 0.025, mult = 3, color = fromRGB(255, 214, 80) },
	{ id = "radiant", name = "Radiant", chance = 0.01, mult = 6, color = fromRGB(255, 255, 255) },
	{ id = "luminous", name = "Luminous", chance = 0.004, mult = 15, color = fromRGB(120, 255, 240) },
	{ id = "ancient", name = "Ancient", chance = 0.001, mult = 50, color = fromRGB(96, 214, 196) },
}

ItemCatalog.MATURITY_FLOOR = 0.4
ItemCatalog.MAX_STAR = 10

local rarityIndex = {}
for index, rarity in ItemCatalog.RARITIES do
	rarityIndex[rarity.id] = index
end

local categoryById = {}
for _, category in ItemCatalog.CATEGORIES do
	categoryById[category.id] = category
end

local mutationById = {}
for _, mutation in ItemCatalog.MUTATIONS do
	mutationById[mutation.id] = mutation
end

local list = {}
local byId = {}

for _, category in ItemCatalog.CATEGORIES do
	for index, rarity in ItemCatalog.RARITIES do
		local nextRarity = ItemCatalog.RARITIES[index + 1]
		local entry = {
			id = category.id .. "_" .. rarity.id,
			name = ItemCatalog.PREFIX[rarity.id] .. " " .. category.name,
			category = category.id,
			rarity = rarity.id,
			price = category.price * rarity.price,
			model = category.id,
			bonus = category.bonus * rarity.bonus,
			grow = rarity.grow,
			mergesTo = (nextRarity and not category.noMerge) and (category.id .. "_" .. nextRarity.id) or nil,
			starMerge = (not nextRarity and not category.noMerge) or nil,
		}
		table.insert(list, entry)
		byId[entry.id] = entry
	end
end

ItemCatalog.list = list
ItemCatalog.byId = byId

function ItemCatalog.item(id)
	return byId[id]
end

function ItemCatalog.rarity(id)
	local index = rarityIndex[id]
	return index and ItemCatalog.RARITIES[index] or nil
end

function ItemCatalog.rarityIndex(id)
	return rarityIndex[id]
end

function ItemCatalog.category(id)
	return categoryById[id]
end

function ItemCatalog.mutation(id)
	return mutationById[id]
end

function ItemCatalog.rarityColors()
	local colors = {}
	for _, rarity in ItemCatalog.RARITIES do
		colors[rarity.id] = rarity.color
	end
	return colors
end

function ItemCatalog.growth(entry, grownSeconds)
	if not entry or not entry.grow or entry.grow <= 0 then
		return 1
	end
	return math.clamp((grownSeconds or 0) / entry.grow, 0, 1)
end

function ItemCatalog.maturityFactor(growth)
	return ItemCatalog.MATURITY_FLOOR + (1 - ItemCatalog.MATURITY_FLOOR) * math.clamp(growth, 0, 1)
end

local STAR_STEPS = { 4, 4, 4, 4, 4, 3.5, 3.5, 3.5, 3.2, 3.2 }

function ItemCatalog.starMult(star)
	star = math.clamp(math.floor(tonumber(star) or 0), 0, ItemCatalog.MAX_STAR)
	local value = 1
	for step = 1, star do
		value *= STAR_STEPS[step]
	end
	return value
end

function ItemCatalog.bonusOf(entry, growth, mutationId, star)
	if not entry then
		return 0
	end
	local mutation = mutationId and mutationById[mutationId]
	return entry.bonus * ItemCatalog.maturityFactor(growth) * (mutation and mutation.mult or 1) * ItemCatalog.starMult(star)
end

function ItemCatalog.displayName(entry, mutationId, star)
	local name = entry.name
	local mutation = mutationId and mutationById[mutationId]
	if mutation then
		name = mutation.name .. " " .. name
	end
	if star and star > 0 then
		name = name .. " +" .. star
	end
	return name
end

function ItemCatalog.mergeResult(itemId, star)
	local entry = byId[itemId]
	star = star or 0
	if not entry then
		return nil
	end
	if entry.mergesTo then
		return { id = entry.mergesTo, star = 0 }
	end
	if entry.starMerge and star < ItemCatalog.MAX_STAR then
		return { id = itemId, star = star + 1 }
	end
	return nil
end

local function pickWeighted(random, entries, weightOf)
	local total = 0
	for _, entry in entries do
		total += weightOf(entry)
	end
	local roll = random:NextNumber() * total
	for _, entry in entries do
		roll -= weightOf(entry)
		if roll <= 0 then
			return entry
		end
	end
	return entries[#entries]
end

local function rarityPool(minimum)
	local pool = {}
	for index, rarity in ItemCatalog.RARITIES do
		if index >= minimum then
			table.insert(pool, rarity)
		end
	end
	return pool
end

function ItemCatalog.stockFor(epoch, factory)
	factory = factory or newRandom
	local stock = {}
	local forced = {}
	if epoch % ItemCatalog.PITY.legendary == 0 then
		table.insert(forced, rarityIndex.legendary)
	end
	if epoch % ItemCatalog.PITY.epic == 0 then
		table.insert(forced, rarityIndex.epic)
	end
	if epoch % ItemCatalog.PITY.rare == 0 then
		table.insert(forced, rarityIndex.rare)
	end
	for slot = 1, ItemCatalog.SHOP_SLOTS do
		local random = factory(epoch * 7919 + slot * 104729)
		local category = pickWeighted(random, ItemCatalog.CATEGORIES, function(entry)
			return entry.weight
		end)
		local minimum = forced[slot] or 1
		local rarity = pickWeighted(random, rarityPool(minimum), function(entry)
			return entry.weight
		end)
		local quantity = random:NextInteger(rarity.stockMin, rarity.stockMax)
		local id = category.id .. "_" .. rarity.id
		stock[id] = (stock[id] or 0) + quantity
	end
	local shelf = ItemCatalog.STARTER_SHELF
	stock[shelf.id] = math.max(stock[shelf.id] or 0, shelf.quantity)
	return stock
end

function ItemCatalog.epochOf(unixTime, restockSeconds)
	return math.floor(unixTime / (restockSeconds or ItemCatalog.RESTOCK_SECONDS))
end

function ItemCatalog.oddsTable()
	local total = 0
	for _, rarity in ItemCatalog.RARITIES do
		total += rarity.weight
	end
	local rows = {}
	for _, rarity in ItemCatalog.RARITIES do
		table.insert(rows, { id = rarity.id, name = rarity.name, percent = rarity.weight / total * 100 })
	end
	local mutations = {}
	local mutated = 0
	for _, mutation in ItemCatalog.MUTATIONS do
		mutated += mutation.chance
		table.insert(mutations, { id = mutation.id, name = mutation.name, percent = mutation.chance * 100, mult = mutation.mult })
	end
	table.insert(mutations, 1, { id = "none", name = "No mutation", percent = (1 - mutated) * 100, mult = 1 })
	return rows, mutations
end

function ItemCatalog.cleanSaved(raw)
	local result = {}
	if type(raw) ~= "table" then
		return result
	end
	local seen = {}
	for _, saved in raw do
		if #result >= ItemCatalog.MAX_ITEMS then
			break
		end
		if type(saved) == "table" and type(saved.uid) == "string" and #saved.uid <= 24 and not seen[saved.uid] and byId[saved.id] then
			seen[saved.uid] = true
			local entry = {
				uid = saved.uid,
				id = saved.id,
				grown = 0,
				star = 0,
			}
			if type(saved.grown) == "number" and saved.grown == saved.grown and saved.grown >= 0 then
				entry.grown = math.min(saved.grown, byId[saved.id].grow)
			end
			if type(saved.since) == "number" and saved.since == saved.since and saved.since > 0 then
				entry.since = saved.since
			end
			if type(saved.slot) == "string" and #saved.slot <= 32 then
				entry.slot = saved.slot
			end
			if type(saved.mut) == "string" and (mutationById[saved.mut] or saved.mut == "none") then
				entry.mut = saved.mut
			end
			if type(saved.star) == "number" and saved.star == saved.star then
				entry.star = math.clamp(math.floor(saved.star), 0, ItemCatalog.MAX_STAR)
			end
			table.insert(result, entry)
		end
	end
	return result
end

return ItemCatalog
