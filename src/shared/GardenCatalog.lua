local GardenCatalog = {}

GardenCatalog.RESTOCK_SECONDS = 300
GardenCatalog.BASKET_MAX = 80
GardenCatalog.SEED_MAX = 99
GardenCatalog.BED_COUNT = 18
GardenCatalog.BED_COLUMNS = { -22, 22, -31, 31, -40, 40 }
GardenCatalog.BED_ROWS = { 14, 23, 32 }
GardenCatalog.BED_SIZE = 7
GardenCatalog.WEATHER_GAP = { 240, 420 }

GardenCatalog.rarities = {
	{ id = "common", name = "Common", color = { 200, 205, 215 } },
	{ id = "uncommon", name = "Uncommon", color = { 94, 214, 130 } },
	{ id = "rare", name = "Rare", color = { 86, 156, 255 } },
	{ id = "epic", name = "Epic", color = { 176, 124, 255 } },
	{ id = "legendary", name = "Legendary", color = { 255, 190, 60 } },
}

GardenCatalog.crops = {
	{
		id = "wheat",
		name = "Wheat",
		rarity = "common",
		seedCost = 25,
		growSeconds = 15,
		sellBase = 50,
		weight = { 0.4, 1.2 },
		stock = { 4, 9 },
		stockChance = 1,
	},
	{
		id = "barley",
		name = "Barley",
		rarity = "common",
		seedCost = 60,
		growSeconds = 30,
		sellBase = 125,
		weight = { 0.4, 1.2 },
		stock = { 3, 7 },
		stockChance = 1,
	},
	{
		id = "grapes",
		name = "Grapes",
		rarity = "uncommon",
		seedCost = 180,
		growSeconds = 55,
		sellBase = 400,
		weight = { 0.6, 1.8 },
		stock = { 2, 5 },
		stockChance = 0.85,
		regrowSeconds = 40,
	},
	{
		id = "figs",
		name = "Figs",
		rarity = "rare",
		seedCost = 600,
		growSeconds = 100,
		sellBase = 1500,
		weight = { 0.5, 1.6 },
		stock = { 1, 3 },
		stockChance = 0.6,
	},
	{
		id = "olives",
		name = "Olives",
		rarity = "rare",
		seedCost = 1400,
		growSeconds = 160,
		sellBase = 3600,
		weight = { 0.3, 1.0 },
		stock = { 1, 3 },
		stockChance = 0.5,
		regrowSeconds = 100,
	},
	{
		id = "pomegranate",
		name = "Pomegranate",
		rarity = "epic",
		seedCost = 5200,
		growSeconds = 300,
		sellBase = 14000,
		weight = { 0.8, 2.4 },
		stock = { 1, 2 },
		stockChance = 0.3,
	},
	{
		id = "dates",
		name = "Dates",
		rarity = "legendary",
		seedCost = 20000,
		growSeconds = 600,
		sellBase = 62000,
		weight = { 0.6, 1.8 },
		stock = { 1, 1 },
		stockChance = 0.12,
		regrowSeconds = 360,
	},
}

GardenCatalog.mutations = {
	{ id = "wet", name = "Wet", mult = 2, kind = "weather", color = { 90, 170, 255 } },
	{ id = "sunlit", name = "Sunlit", mult = 2, kind = "weather", color = { 255, 214, 80 } },
	{ id = "golden", name = "Golden", mult = 10, kind = "variant", chance = 0.015, color = { 255, 200, 40 } },
	{ id = "rainbow", name = "Rainbow", mult = 25, kind = "variant", chance = 0.004, color = { 255, 120, 200 } },
}

GardenCatalog.weather = {
	{ id = "clear", name = "Clear skies", speed = 1 },
	{ id = "rain", name = "Rain", speed = 1.5, mutation = "wet", chance = 0.07, duration = { 90, 150 }, weight = 3 },
	{ id = "sunny", name = "Sunshine", speed = 1.25, mutation = "sunlit", chance = 0.07, duration = { 90, 150 }, weight = 2 },
}

local cropById = {}
for index, crop in GardenCatalog.crops do
	crop.order = index
	cropById[crop.id] = crop
end

local mutationById = {}
for _, mutation in GardenCatalog.mutations do
	mutationById[mutation.id] = mutation
end

local weatherById = {}
for _, entry in GardenCatalog.weather do
	weatherById[entry.id] = entry
end

local rarityById = {}
for index, rarity in GardenCatalog.rarities do
	rarity.order = index
	rarityById[rarity.id] = rarity
end

function GardenCatalog.crop(id)
	return cropById[id]
end

function GardenCatalog.mutation(id)
	return mutationById[id]
end

function GardenCatalog.weatherEntry(id)
	return weatherById[id] or weatherById.clear
end

function GardenCatalog.rarity(id)
	return rarityById[id]
end

function GardenCatalog.bedCount(landTier)
	landTier = math.floor(tonumber(landTier) or 1)
	return math.clamp(6 + (landTier - 1) * 3, 6, GardenCatalog.BED_COUNT)
end

function GardenCatalog.bedPosition(index)
	local columns = #GardenCatalog.BED_COLUMNS
	local row = math.floor((index - 1) / columns) + 1
	local column = (index - 1) % columns + 1
	return GardenCatalog.BED_COLUMNS[column], GardenCatalog.BED_ROWS[row]
end

function GardenCatalog.averageWeight(crop)
	return (crop.weight[1] + crop.weight[2]) / 2
end

function GardenCatalog.rollWeight(rng, crop)
	local value = crop.weight[1] + rng:NextNumber() * (crop.weight[2] - crop.weight[1])
	return math.floor(value * 100 + 0.5) / 100
end

function GardenCatalog.multiplier(mutationIds)
	local variant = 1
	local extra = 0
	for _, id in mutationIds or {} do
		local mutation = mutationById[id]
		if mutation then
			if mutation.kind == "variant" then
				variant = math.max(variant, mutation.mult)
			else
				extra += mutation.mult - 1
			end
		end
	end
	return variant + extra
end

function GardenCatalog.value(crop, weight, mutationIds)
	if not crop then
		return 0
	end
	weight = tonumber(weight) or GardenCatalog.averageWeight(crop)
	local raw = crop.sellBase * (weight / GardenCatalog.averageWeight(crop)) * GardenCatalog.multiplier(mutationIds)
	return math.max(1, math.floor(raw + 0.5))
end

function GardenCatalog.rollVariant(rng)
	for _, id in { "rainbow", "golden" } do
		if rng:NextNumber() < mutationById[id].chance then
			return id
		end
	end
	return nil
end

function GardenCatalog.rollStock(rng)
	local stock = {}
	for _, crop in GardenCatalog.crops do
		local count = 0
		if rng:NextNumber() < crop.stockChance then
			count = rng:NextInteger(crop.stock[1], crop.stock[2])
		end
		stock[crop.id] = count
	end
	local any = false
	for _, count in stock do
		if count > 0 then
			any = true
		end
	end
	if not any then
		stock.wheat = 3
	end
	return stock
end

function GardenCatalog.pickWeather(rng)
	local total = 0
	for _, entry in GardenCatalog.weather do
		total += entry.weight or 0
	end
	local roll = rng:NextNumber() * total
	for _, entry in GardenCatalog.weather do
		if entry.weight then
			roll -= entry.weight
			if roll <= 0 then
				return entry
			end
		end
	end
	return weatherById.rain
end

function GardenCatalog.stageFor(progress)
	if progress >= 1 then
		return 3
	elseif progress >= 0.5 then
		return 2
	elseif progress >= 0.2 then
		return 1
	end
	return 0
end

function GardenCatalog.formatTime(seconds)
	seconds = math.max(0, math.ceil(tonumber(seconds) or 0))
	return string.format("%d:%02d", math.floor(seconds / 60), seconds % 60)
end

local function cleanMutations(raw)
	local result = {}
	if type(raw) == "table" then
		for _, id in raw do
			if type(id) == "string" and mutationById[id] and not table.find(result, id) and #result < 4 then
				table.insert(result, id)
			end
		end
	end
	return result
end

function GardenCatalog.sanitizeSave(raw)
	local clean = { seeds = {}, basket = {}, beds = {}, selected = "" }
	if type(raw) ~= "table" then
		return clean
	end
	if type(raw.seeds) == "table" then
		for id, count in raw.seeds do
			if cropById[id] and type(count) == "number" and count >= 1 and count == math.floor(count) then
				clean.seeds[id] = math.min(count, GardenCatalog.SEED_MAX)
			end
		end
	end
	if type(raw.basket) == "table" then
		for _, entry in raw.basket do
			if type(entry) == "table" and cropById[entry.c] and #clean.basket < GardenCatalog.BASKET_MAX then
				local crop = cropById[entry.c]
				local weight = tonumber(entry.w)
				if not weight or weight ~= weight or weight < crop.weight[1] * 0.9 or weight > crop.weight[2] * 1.1 then
					weight = GardenCatalog.averageWeight(crop)
				end
				table.insert(clean.basket, { c = entry.c, w = weight, m = cleanMutations(entry.m) })
			end
		end
	end
	if type(raw.beds) == "table" then
		local seen = {}
		for _, entry in raw.beds do
			if type(entry) == "table" and cropById[entry.c] and type(entry.i) == "number" and entry.i >= 1 and entry.i <= GardenCatalog.BED_COUNT and entry.i == math.floor(entry.i) and not seen[entry.i] then
				seen[entry.i] = true
				local crop = cropById[entry.c]
				local weight = tonumber(entry.w)
				if not weight or weight ~= weight or weight < crop.weight[1] * 0.9 or weight > crop.weight[2] * 1.1 then
					weight = GardenCatalog.averageWeight(crop)
				end
				local progress = tonumber(entry.p) or 0
				if progress ~= progress then
					progress = 0
				end
				table.insert(clean.beds, {
					i = entry.i,
					c = entry.c,
					p = math.clamp(progress, 0, 1),
					s = tonumber(entry.s) or 0,
					w = weight,
					m = cleanMutations(entry.m),
					g = entry.g == true,
				})
			end
		end
	end
	if type(raw.selected) == "string" and cropById[raw.selected] then
		clean.selected = raw.selected
	end
	return clean
end

return GardenCatalog
