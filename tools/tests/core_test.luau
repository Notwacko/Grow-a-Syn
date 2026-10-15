local Income = require("../../src/server/core/Income")
local Format = require("../../src/server/core/Format")
local Constants = require("../../src/shared/Constants")
local Upgrades = require("../../src/shared/UpgradeCatalog")
local Outfits = require("../../src/shared/OutfitCatalog")

local function stubRandom(seed)
	local state = (seed * 1103515245 + 12345) % 2147483648
	local function nextState()
		state = (state * 1103515245 + 12345) % 2147483648
		return state
	end
	return {
		NextNumber = function()
			return nextState() / 2147483648
		end,
		NextInteger = function(_, low, high)
			return low + nextState() % (high - low + 1)
		end,
	}
end
local Items = require("../../src/shared/ItemCatalog")
local Balance = require("../../src/shared/Balance")
local Quests = require("../../src/shared/QuestCatalog")
local Pets = require("../../src/shared/PetCatalog")

local failures = 0
local function check(label, condition)
	if not condition then
		failures += 1
		print("FAIL: " .. label)
	end
end
local function near(a, b)
	return math.abs(a - b) < 1e-9
end

check("no minyan means no income", Income.perSecond(false, 12, 1, 1, 1) == 0)
check("base income", near(Income.perSecond(true, 10, 1, 1, 1), 10))
check("income uses every multiplier", near(Income.perSecond(true, 10, 2, 3, 1.5), 90))
check("shabbat double income", near(Income.perSecond(true, 10, 1, 1, 2), 2 * Income.perSecond(true, 10, 1, 1, 1)))
check("event mult 0 stops income", Income.perSecond(true, 10, 1, 1, 0) == 0)
check("event mult stacks with boost", near(Income.perSecond(true, 100, 5, 2, 2), 2000))
check("nan is safe", Income.perSecond(true, 0 / 0, 1, 1, 1) == 0)
check("income clamps", Income.perSecond(true, 1e20, 1, 1, 1) == 1e12)

check("default arrival interval", near(Income.arrivalInterval(0, true, 10, 1.5, 10, 3), 10))
check("tutorial arrival is faster", near(Income.arrivalInterval(0, false, 10, 1.5, 10, 3), 3))
check("welcome bonus speeds arrivals", near(Income.arrivalInterval(1, true, 10, 1.5, 10, 3), 5))
check("arrival floor", near(Income.arrivalInterval(100, true, 10, 1.5, 10, 3), 1.5))

check("format small", Format.short(999) == "999")
check("format K", Format.short(1200) == "1.2K")
check("format round K", Format.short(4000) == "4K")
check("format M", Format.short(3400000) == "3.4M")
check("format large", Format.short(500000) == "500K")
check("format 100K", Format.short(100000) == "100K")

check("26 slots", #Constants.SLOT_NAMES == 26)
check("seat tiers", Constants.seatsForTier(1) == 12 and Constants.seatsForTier(7) == 100)
check("building names", Constants.buildingName("ashkenazi", 4) == "ashkenazi_T4" and Constants.buildingName("", 4) == "starter")

local welcome = Upgrades.get("welcome_table")
local kiddush = Upgrades.get("kiddush_table")
local desk = Upgrades.get("membership_desk")
check("catalog has 3 upgrades", #Upgrades.list == 3 and welcome and kiddush and desk)
check("unknown upgrade is nil", Upgrades.get("nope") == nil)
check("cost level 0", Upgrades.cost(welcome, 0) == 400)
check("cost grows 15 percent a level", Upgrades.cost(welcome, 1) == 460 and Upgrades.cost(welcome, 2) == 529)
check("upgrades have no maximum", welcome.maxLevel == math.huge and Upgrades.cost(welcome, 500) == nil or Upgrades.cost(welcome, 120) ~= nil)
check("absurd levels cap out instead of overflowing", Upgrades.cost(welcome, 1000) == nil)
local none = {}
check("no upgrades no bonus", Upgrades.arrivalBonus(none) == 0 and Upgrades.tip(none, 3) == 0 and Upgrades.duesPerSecond(none, 50) == 0 and Upgrades.incomeMult(none) == 1)
local sample = { welcome_table = 10, kiddush_table = 10, membership_desk = 10 }
check("arrival bonus grows", near(Upgrades.arrivalBonus(sample), 0.5))
check("desk raises income", near(Upgrades.incomeMult(sample), 1.4))
check("soft cap slows late upgrades", near(Upgrades.incomeMult({ membership_desk = 25 }), 2) and near(Upgrades.incomeMult({ membership_desk = 125 }), 2 + 100 * 0.04 * 0.25))
check("tip scales with tier", Upgrades.tip({ kiddush_table = 1 }, 1) == 10 and Upgrades.tip({ kiddush_table = 1 }, 7) == 7290)
check("bad levels are safe", Upgrades.arrivalBonus({ welcome_table = "x" }) == 0 and Upgrades.arrivalBonus(nil) == 0)

check("tier multipliers triple each stage", Balance.tierMult(1) == 1 and Balance.tierMult(2) == 3 and Balance.tierMult(7) == 729)
check("tier costs grow 24x", Balance.tierCost(2) == 5000 and Balance.tierCost(3) == 120000 and Balance.tierCost(1) == nil and Balance.tierCost(8) == nil)
check("land costs rise steeply", Balance.landCost(1) == 30000 and Balance.landCost(5) == 10000000000 and Balance.landCost(6) == nil)
check("shop prices scale with the stage", Balance.priceScale(1) == 1 and Balance.priceScale(3) == 16)
check("star multipliers stack", near(Balance.starMult(0), 1) and near(Balance.starMult(2), 16) and near(Balance.starMult(99), Balance.starMult(10)))
check("legacy points need a lot of earnings", Balance.legacyPoints(0) == 0 and Balance.legacyPoints(5e7) == 4 and Balance.legacyPoints(2e9) > Balance.legacyPoints(5e8))
check("legacy multiplier is linear", near(Balance.legacyMult(0), 1) and near(Balance.legacyMult(10), 3))
check("heirloom slots are capped", Balance.heirloomSlots(0) == 2 and Balance.heirloomSlots(30) == 5 and Balance.heirloomSlots(10000) == 8)
check("offline earnings respect the cap and the minimum", (function()
	local small = Balance.offlineEarnings(100, 60, 1, false)
	local amount, counted = Balance.offlineEarnings(100, 10 * 3600, 1, false)
	local patronAmount = Balance.offlineEarnings(100, 10 * 3600, 1, true)
	return small == 0 and counted == 4 * 3600 and amount == 100 * 4 * 3600 * 0.25 and patronAmount > amount
end)())
check("daily rewards escalate and loop", Balance.dailyMinutes(1) == 10 and Balance.dailyMinutes(7) == 90 and Balance.dailyMinutes(8) == 11)
check("collection bonus caps at 20 percent", near(Balance.collectionBonus(0), 0) and near(Balance.collectionBonus(50), 0.1) and near(Balance.collectionBonus(100), 0.2) and near(Balance.collectionBonus(500), 0.2))
check("income minutes have a floor", Balance.incomeMinutes(0, 10) == 10 * 60 * 10 and Balance.incomeMinutes(1000, 1) == 60000)
check("quest days and weeks are stable", Quests.dayId(86400) == 1 and Quests.weekId(4 * 86400) == 1 and Quests.weekId(4 * 86400 - 1) == 0)
check("every quest has a text and a goal", (function()
	for _, group in Quests.daily do
		for _, quest in group do
			if not quest.text or not (quest.goal or quest.minutes) then
				return false
			end
		end
	end
	for _, quest in Quests.weekly do
		if not quest.text or not (quest.goal or quest.minutes) then
			return false
		end
	end
	return true
end)())
check("pet bonus grows with level and caps", Pets.bonusOf("cat", 1) == 0.04 and Pets.bonusOf("cat", 3) > Pets.bonusOf("cat", 2) and Pets.bonusOf("cat", 99) == Pets.bonusOf("cat", 10) and Pets.bonusOf("nope", 1) == 0)
check("pet rolls respect the minimum rarity", (function()
	local random = stubRandom(7)
	for _ = 1, 200 do
		local pet = Pets.roll(random, Pets.rarityIndex("epic"))
		if Pets.rarityIndex(pet.rarity) < Pets.rarityIndex("epic") then
			return false
		end
	end
	return true
end)())

check("7 outfits from starter to haredi", #Outfits.list == 7 and Outfits.list[1].id == "starter" and Outfits.list[7].id == "haredi")
check("outfit tiers are 1 to 7 in order", (function()
	for index, outfit in Outfits.list do
		if outfit.tier ~= index then
			return false
		end
	end
	return true
end)())
check("tier picks the matching outfit", Outfits.forTier(1).id == "starter" and Outfits.forTier(2).id == "reform" and Outfits.forTier(6).id == "hasidic" and Outfits.forTier(7).id == "haredi")
check("bad tier is safe", Outfits.forTier(nil).id == "starter" and Outfits.forTier(99).id == "haredi" and Outfits.forTier(-4).id == "starter")
check("auto follows the tier", Outfits.resolve("auto", 4).id == "orthodox")
check("explicit choice wins over the tier", Outfits.resolve("hasidic", 1).id == "hasidic")
check("unknown choice falls back to auto", Outfits.resolve("nope", 3).id == "conservative")
check("selection cycle walks every outfit then auto", (function()
	local selection = Outfits.AUTO
	for index = 1, #Outfits.list do
		selection = Outfits.nextSelection(selection)
		if selection ~= Outfits.list[index].id then
			return false
		end
	end
	return Outfits.nextSelection(selection) == Outfits.AUTO
end)())
check("styles validate", Outfits.validStyle("classic") and Outfits.validStyle("modest") and not Outfits.validStyle("x") and not Outfits.validStyle(nil))
check("selections validate", Outfits.validSelection("auto") and Outfits.validSelection("reform") and not Outfits.validSelection("x") and not Outfits.validSelection(5))
check("every outfit has both styles with pieces", (function()
	for _, outfit in Outfits.list do
		if #Outfits.pieces(outfit, "classic") == 0 or #Outfits.pieces(outfit, "modest") == 0 then
			return false
		end
	end
	return true
end)())
check("unknown style uses classic", Outfits.pieces(Outfits.list[2], "x") == Outfits.list[2].classic)

check("48 items from 8 categories and 6 rarities", #Items.list == 48)
check("first offer is a common siddur at 50", Items.item("siddur_common").price == 50 and Items.item("siddur_common").rarity == "common")
check("item models use the category name", Items.item("menorah_epic").model == "menorah")
check("prices grow with rarity", Items.item("ark_mythical").price > Items.item("ark_legendary").price and Items.item("ark_rare").price > Items.item("ark_uncommon").price)
check("merging is cheaper than buying the next rarity", Items.item("siddur_uncommon").price > 3 * Items.item("siddur_common").price)
check("merge chain ends at mythical then turns into stars", Items.item("siddur_common").mergesTo == "siddur_uncommon" and Items.item("siddur_mythical").mergesTo == nil and Items.item("siddur_mythical").starMerge == true)
check("merge results", (function()
	local rarity = Items.mergeResult("siddur_common", 0)
	local star = Items.mergeResult("siddur_mythical", 2)
	local capped = Items.mergeResult("siddur_mythical", Items.MAX_STAR)
	return rarity.id == "siddur_uncommon" and rarity.star == 0 and star.id == "siddur_mythical" and star.star == 3 and capped == nil and Items.mergeResult("nope", 0) == nil
end)())
check("torah scrolls can never be merged away", (function()
	for _, entry in Items.list do
		if entry.category == "torah" and (entry.mergesTo ~= nil or entry.starMerge ~= nil or Items.mergeResult(entry.id, 0) ~= nil) then
			return false
		end
	end
	return true
end)())
check("every category has a slot prefix", (function()
	for _, category in Items.CATEGORIES do
		local found = false
		for _, group in Constants.SLOT_COUNTS do
			if Constants.SLOT_PREFIX_CATEGORY[group.prefix] == category.id then
				found = true
			end
		end
		if not found then
			return false
		end
	end
	return true
end)())
check("growth is clamped", Items.growth(Items.item("siddur_common"), -5) == 0 and Items.growth(Items.item("siddur_common"), 9999) == 1 and near(Items.growth(Items.item("siddur_common"), 30), 0.5))
check("young items earn less", near(Items.maturityFactor(0), 0.4) and near(Items.maturityFactor(1), 1) and Items.maturityFactor(0.5) > Items.maturityFactor(0.2))
check("mutations multiply income", near(Items.bonusOf(Items.item("menorah_rare"), 1, "gilded"), Items.item("menorah_rare").bonus * 3) and near(Items.bonusOf(Items.item("menorah_rare"), 1, nil), Items.item("menorah_rare").bonus))
check("stars multiply income", near(Items.bonusOf(Items.item("menorah_rare"), 1, nil, 1), Items.item("menorah_rare").bonus * 4))
check("display name shows the mutation and stars", Items.displayName(Items.item("siddur_common"), "radiant") == "Radiant Simple Siddur" and Items.displayName(Items.item("siddur_common"), nil) == "Simple Siddur" and Items.displayName(Items.item("siddur_common"), nil, 3) == "Simple Siddur +3")
check("stock is the same on every server", (function()
	local a, b = Items.stockFor(5973453, stubRandom), Items.stockFor(5973453, stubRandom)
	for id, count in a do
		if b[id] ~= count then
			return false
		end
	end
	return true
end)())
check("the first siddur is always on the starter shelf", (function()
	for epoch = 1, 200 do
		if Items.stockFor(epoch, stubRandom)["siddur_common"] < Items.STARTER_SHELF.quantity then
			return false
		end
	end
	return true
end)())
check("pity gives a rare or better every few restocks", (function()
	local order = {}
	for index, rarity in Items.RARITIES do
		order[rarity.id] = index
	end
	for epoch = 6, 600, 6 do
		local best = 0
		for id, count in Items.stockFor(epoch, stubRandom) do
			if count > 0 then
				best = math.max(best, order[Items.item(id).rarity])
			end
		end
		if best < order.rare then
			return false
		end
	end
	return true
end)())
check("pity gives a legendary every sixty restocks", (function()
	local found = false
	for id, count in Items.stockFor(60, stubRandom) do
		if count > 0 and Items.item(id).rarity == "legendary" or (count > 0 and Items.item(id).rarity == "mythical") then
			found = true
		end
	end
	return found
end)())
check("rare items are rarer than common ones", (function()
	local common, mythical = 0, 0
	for epoch = 1, 300 do
		local stock = Items.stockFor(epoch, stubRandom)
		for _, category in Items.CATEGORIES do
			if (stock[category.id .. "_common"] or 0) > 0 then
				common += 1
			end
			if (stock[category.id .. "_mythical"] or 0) > 0 then
				mythical += 1
			end
		end
	end
	return common > mythical * 5
end)())
check("odds table sums to 100", (function()
	local rows = Items.oddsTable()
	local total = 0
	for _, row in rows do
		total += row.percent
	end
	return math.abs(total - 100) < 1e-6
end)())
check("restock epoch follows the restock length", Items.epochOf(0) == 0 and Items.epochOf(299) == 0 and Items.epochOf(300) == 1 and Items.epochOf(239, 240) == 0 and Items.epochOf(240, 240) == 1)
check("saved items are sanitized", (function()
	local cleaned = Items.cleanSaved({
		{ uid = "i1", id = "siddur_common", slot = "Slot_Siddur1", grown = 12, since = 1000, mut = "gilded" },
		{ uid = "i1", id = "siddur_common" },
		{ uid = "i2", id = "nope_common" },
		{ uid = "i3", id = "torah_common", grown = -5, mut = "bad" },
		"junk",
	})
	return #cleaned == 2 and cleaned[1].mut == "gilded" and cleaned[2].grown == 0 and cleaned[2].mut == nil and cleaned[1].star == 0
end)())
check("bad saved data is empty", #Items.cleanSaved(nil) == 0 and #Items.cleanSaved("x") == 0)

if failures == 0 then
	print("all core tests passed")
else
	print(failures .. " failures")
end
