local PetCatalog = {}

PetCatalog.BASE_SLOTS = 2
PetCatalog.EGG_BASE_COST = 3000
PetCatalog.MAX_LEVEL = 10
PetCatalog.LEVEL_STEP = 0.12
PetCatalog.PITY = { epic = 20, legendary = 80 }

PetCatalog.RARITIES = {
	{ id = "common", name = "Common", weight = 55 },
	{ id = "uncommon", name = "Uncommon", weight = 28 },
	{ id = "rare", name = "Rare", weight = 11 },
	{ id = "epic", name = "Epic", weight = 5 },
	{ id = "legendary", name = "Legendary", weight = 1 },
}

PetCatalog.list = {
	{ id = "cat", name = "Kitty", rarity = "common", bonus = 0.04, blurb = "Naps in the sunny windows" },
	{ id = "lamb", name = "Little Lamb", rarity = "common", bonus = 0.04, blurb = "Soft, gentle and curious" },
	{ id = "puppy", name = "Puppy", rarity = "common", bonus = 0.05, blurb = "Greets everyone at the door" },
	{ id = "dove", name = "Dove", rarity = "uncommon", bonus = 0.08, blurb = "Brings good news from afar" },
	{ id = "hedgehog", name = "Hedgehog", rarity = "uncommon", bonus = 0.08, blurb = "Tiny, spiky and sweet" },
	{ id = "fox", name = "Clever Fox", rarity = "rare", bonus = 0.15, blurb = "Always finds the best seats" },
	{ id = "lion_cub", name = "Lion Cub", rarity = "epic", bonus = 0.35, blurb = "Brave, bold and fluffy" },
	{ id = "peacock", name = "Peacock", rarity = "legendary", bonus = 0.8, blurb = "Shows off a dazzling tail" },
}

local byId = {}
local rarityIndex = {}
for index, rarity in PetCatalog.RARITIES do
	rarityIndex[rarity.id] = index
end
for _, pet in PetCatalog.list do
	byId[pet.id] = pet
end

function PetCatalog.get(id)
	return byId[id]
end

function PetCatalog.rarityIndex(id)
	return rarityIndex[id]
end

function PetCatalog.level(count)
	return math.clamp(math.floor(tonumber(count) or 1), 1, PetCatalog.MAX_LEVEL)
end

function PetCatalog.bonusOf(id, count)
	local pet = byId[id]
	if not pet then
		return 0
	end
	return pet.bonus * (1 + PetCatalog.LEVEL_STEP * (PetCatalog.level(count) - 1))
end

function PetCatalog.eggCost(priceScale)
	return math.floor(PetCatalog.EGG_BASE_COST * (priceScale or 1) + 0.5)
end

function PetCatalog.oddsTable()
	local total = 0
	for _, rarity in PetCatalog.RARITIES do
		total += rarity.weight
	end
	local rows = {}
	for _, rarity in PetCatalog.RARITIES do
		table.insert(rows, { id = rarity.id, name = rarity.name, percent = rarity.weight / total * 100 })
	end
	return rows
end

function PetCatalog.roll(random, minimumRarity)
	local pool = {}
	local total = 0
	for index, rarity in PetCatalog.RARITIES do
		if index >= (minimumRarity or 1) then
			table.insert(pool, rarity)
			total += rarity.weight
		end
	end
	local roll = random:NextNumber() * total
	local chosen = pool[#pool]
	for _, rarity in pool do
		roll -= rarity.weight
		if roll <= 0 then
			chosen = rarity
			break
		end
	end
	local candidates = {}
	for _, pet in PetCatalog.list do
		if pet.rarity == chosen.id then
			table.insert(candidates, pet)
		end
	end
	return candidates[random:NextInteger(1, #candidates)]
end

return PetCatalog
