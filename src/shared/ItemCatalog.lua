local ItemCatalog = {}

local fromRGB = Color3 and Color3.fromRGB or function(r, g, b)
	return { r, g, b }
end
local newRandom = Random and Random.new

ItemCatalog.RESTOCK_SECONDS = 300
ItemCatalog.MAX_ITEMS = 300
ItemCatalog.MERGE_COUNT = 3

ItemCatalog.RARITIES = {
	{ id = "common", name = "Common", color = fromRGB(170, 180, 200), price = 1, bonus = 1, grow = 45, chance = 1, stockMin = 3, stockMax = 6 },
	{ id = "uncommon", name = "Uncommon", color = fromRGB(80, 215, 110), price = 5, bonus = 1.8, grow = 90, chance = 0.75, stockMin = 2, stockMax = 4 },
	{ id = "rare", name = "Rare", color = fromRGB(70, 160, 255), price = 25, bonus = 3.2, grow = 180, chance = 0.45, stockMin = 1, stockMax = 3 },
	{ id = "epic", name = "Epic", color = fromRGB(176, 100, 255), price = 120, bonus = 5.6, grow = 360, chance = 0.22, stockMin = 1, stockMax = 2 },
	{ id = "legendary", name = "Legendary", color = fromRGB(255, 190, 50), price = 600, bonus = 10, grow = 720, chance = 0.08, stockMin = 1, stockMax = 1 },
	{ id = "mythical", name = "Mythical", color = fromRGB(255, 80, 140), price = 3000, bonus = 18, grow = 1200, chance = 0.025, stockMin = 1, stockMax = 1 },
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
	{ id = "siddur", name = "Siddur", price = 50, bonus = 0.03, fit = 1.5 },
	{ id = "ornament", name = "Wall Ornament", price = 60, bonus = 0.03, fit = 2.1 },
	{ id = "kiddush_cup", name = "Kiddush Cup", price = 90, bonus = 0.04, fit = 1.2 },
	{ id = "holiday_decor", name = "Holiday Banner", price = 150, bonus = 0.05, fit = 4.6 },
	{ id = "menorah", name = "Menorah", price = 250, bonus = 0.08, fit = 3.2 },
	{ id = "torah", name = "Sefer Torah", price = 400, bonus = 0.1, fit = 2.1, noMerge = true },
	{ id = "chandelier", name = "Chandelier", price = 500, bonus = 0.1, fit = 4.2 },
	{ id = "ark", name = "Aron Kodesh", price = 700, bonus = 0.12, fit = 6.2 },
}

ItemCatalog.MUTATIONS = {
	{ id = "gilded", name = "Gilded", chance = 0.12, mult = 1.5, color = fromRGB(255, 214, 80) },
	{ id = "radiant", name = "Radiant", chance = 0.04, mult = 2.2, color = fromRGB(255, 255, 255) },
	{ id = "ancient", name = "Ancient", chance = 0.01, mult = 3.5, color = fromRGB(96, 214, 196) },
}

ItemCatalog.MATURITY_FLOOR = 0.4

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

function ItemCatalog.bonusOf(entry, growth, mutationId)
	if not entry then
		return 0
	end
	local mutation = mutationId and mutationById[mutationId]
	return entry.bonus * ItemCatalog.maturityFactor(growth) * (mutation and mutation.mult or 1)
end

function ItemCatalog.displayName(entry, mutationId)
	local mutation = mutationId and mutationById[mutationId]
	if mutation then
		return mutation.name .. " " .. entry.name
	end
	return entry.name
end

function ItemCatalog.stockFor(epoch, factory)
	factory = factory or newRandom
	local stock = {}
	for index, entry in list do
		local rarity = ItemCatalog.rarity(entry.rarity)
		local random = factory(epoch * 7919 + index * 104729)
		local count = 0
		if entry.id == "siddur_common" then
			count = random:NextInteger(4, 7)
		elseif random:NextNumber() < rarity.chance then
			count = random:NextInteger(rarity.stockMin, rarity.stockMax)
		end
		stock[entry.id] = count
	end
	return stock
end

function ItemCatalog.epochOf(unixTime)
	return math.floor(unixTime / ItemCatalog.RESTOCK_SECONDS)
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
			table.insert(result, entry)
		end
	end
	return result
end

return ItemCatalog
