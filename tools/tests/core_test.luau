local Income = require("../../src/server/core/Income")
local Format = require("../../src/server/core/Format")
local Constants = require("../../src/shared/Constants")
local Upgrades = require("../../src/shared/UpgradeCatalog")
local Outfits = require("../../src/shared/OutfitCatalog")
local Garden = require("../../src/shared/GardenCatalog")

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
check("cost grows 4x", Upgrades.cost(welcome, 1) == 1600 and Upgrades.cost(welcome, 2) == 6400)
check("cost at max is nil", Upgrades.cost(welcome, 5) == nil)
local none = {}
check("no upgrades no bonus", Upgrades.arrivalBonus(none) == 0 and Upgrades.tip(none, 3) == 0 and Upgrades.duesPerSecond(none, 50) == 0)
local max = { welcome_table = 5, kiddush_table = 5, membership_desk = 5 }
check("arrival bonus at max", near(Upgrades.arrivalBonus(max), 1.25))
check("arrival interval with max welcome table", near(Income.arrivalInterval(Upgrades.arrivalBonus(max), true, 10, 1.5, 10, 3), 10 / 2.25))
check("tip scales with tier", Upgrades.tip({ kiddush_table = 1 }, 1) == 5 and Upgrades.tip({ kiddush_table = 1 }, 7) == 14)
check("dues scale with congregation", near(Upgrades.duesPerSecond({ membership_desk = 2 }, 40), 12))
check("bad levels are safe", Upgrades.arrivalBonus({ welcome_table = "x" }) == 0)

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

local function fakeRng(values)
	local index = 0
	local rng = {}
	function rng:NextNumber()
		index += 1
		return values[(index - 1) % #values + 1]
	end
	function rng:NextInteger(a, b)
		return a + math.floor(self:NextNumber() * (b - a + 1))
	end
	return rng
end

local wheat = Garden.crop("wheat")
local dates = Garden.crop("dates")
check("seven species crops", #Garden.crops == 7 and Garden.crop("pomegranate") and Garden.crop("olives") and Garden.crop("figs") and Garden.crop("grapes") and Garden.crop("barley") and wheat and dates)
check("unknown crop is nil", Garden.crop("nope") == nil and Garden.mutation("nope") == nil)
check("crops get dearer and slower", (function()
	for index = 2, #Garden.crops do
		local a, b = Garden.crops[index - 1], Garden.crops[index]
		if b.seedCost <= a.seedCost or b.growSeconds <= a.growSeconds or b.sellBase <= a.sellBase then
			return false
		end
	end
	return true
end)())
check("every crop turns a profit", (function()
	for _, crop in Garden.crops do
		if crop.sellBase <= crop.seedCost then
			return false
		end
	end
	return true
end)())
check("bed count follows land tier", Garden.bedCount(1) == 6 and Garden.bedCount(2) == 9 and Garden.bedCount(5) == 18 and Garden.bedCount(6) == 18 and Garden.bedCount(nil) == 6)
check("bed positions are unique", (function()
	local seen = {}
	for index = 1, Garden.BED_COUNT do
		local x, z = Garden.bedPosition(index)
		local key = x .. "," .. z
		if seen[key] or not x or not z then
			return false
		end
		seen[key] = true
	end
	return true
end)())
check("average weight value is the base value", Garden.value(wheat, Garden.averageWeight(wheat), {}) == 50)
check("heavier fruit sells for more", Garden.value(wheat, 1.2, {}) > Garden.value(wheat, 0.4, {}))
check("wet doubles value", Garden.value(wheat, Garden.averageWeight(wheat), { "wet" }) == 100)
check("golden is ten times", Garden.value(wheat, Garden.averageWeight(wheat), { "golden" }) == 500)
check("rainbow beats golden, only the best variant counts", Garden.multiplier({ "golden", "rainbow" }) == 25)
check("weather adds to a variant", Garden.multiplier({ "golden", "wet" }) == 11 and Garden.multiplier({ "wet", "sunlit" }) == 3)
check("unknown mutation is ignored", Garden.multiplier({ "nope" }) == 1)
check("value of a missing crop is zero", Garden.value(nil, 1, {}) == 0)
check("rolled weight stays in range", (function()
	local rng = fakeRng({ 0, 0.5, 0.999 })
	for _ = 1, 6 do
		local w = Garden.rollWeight(rng, wheat)
		if w < wheat.weight[1] or w > wheat.weight[2] then
			return false
		end
	end
	return true
end)())
check("variant roll can hit rainbow, golden or nothing", Garden.rollVariant(fakeRng({ 0.001 })) == "rainbow" and Garden.rollVariant(fakeRng({ 0.5, 0.01 })) == "golden" and Garden.rollVariant(fakeRng({ 0.9 })) == nil)
check("restock always has wheat and rare seeds are not guaranteed", (function()
	local stock = Garden.rollStock(fakeRng({ 0.99 }))
	return stock.wheat > 0 and stock.dates == 0 and stock.pomegranate == 0
end)())
check("restock respects the ranges", (function()
	local stock = Garden.rollStock(fakeRng({ 0.1, 0.4, 0.9 }))
	for _, crop in Garden.crops do
		local count = stock[crop.id]
		if count ~= 0 and (count < crop.stock[1] or count > crop.stock[2]) then
			return false
		end
	end
	return true
end)())
check("stage thresholds", Garden.stageFor(0) == 0 and Garden.stageFor(0.2) == 1 and Garden.stageFor(0.49) == 1 and Garden.stageFor(0.5) == 2 and Garden.stageFor(0.99) == 2 and Garden.stageFor(1) == 3)
check("time format", Garden.formatTime(0) == "0:00" and Garden.formatTime(61) == "1:01" and Garden.formatTime(299.2) == "5:00" and Garden.formatTime(-4) == "0:00")
check("weather pick returns a real event", Garden.pickWeather(fakeRng({ 0.1 })).id == "rain" and Garden.pickWeather(fakeRng({ 0.95 })).id == "sunny")
check("unknown weather falls back to clear", Garden.weatherEntry("nope").id == "clear")

local clean = Garden.sanitizeSave({
	seeds = { wheat = 3, nope = 5, barley = -1, figs = 500, olives = 1.5 },
	basket = { { c = "wheat", w = 0.8, m = { "wet", "wet", "bogus" } }, { c = "ghost" }, { c = "dates", w = 999 } },
	beds = { { i = 2, c = "wheat", p = 0.4, w = 0.8 }, { i = 2, c = "barley" }, { i = 99, c = "wheat" }, { i = 3, c = "ghost" }, { i = 4, c = "figs", p = 7 } },
	selected = "figs",
})
check("save keeps good seeds and drops junk", clean.seeds.wheat == 3 and clean.seeds.nope == nil and clean.seeds.barley == nil and clean.seeds.olives == nil)
check("save caps seed counts", clean.seeds.figs == Garden.SEED_MAX)
check("save cleans the basket", #clean.basket == 2 and #clean.basket[1].m == 1 and clean.basket[1].m[1] == "wet")
check("bad weight falls back to average", clean.basket[2].c == "dates" and clean.basket[2].w == Garden.averageWeight(dates))
check("save drops duplicate and bad beds", #clean.beds == 2 and clean.beds[1].i == 2 and clean.beds[2].i == 4)
check("progress is clamped", clean.beds[2].p == 1)
check("selected seed survives", clean.selected == "figs")
check("garbage save is safe", #Garden.sanitizeSave("x").beds == 0 and Garden.sanitizeSave(nil).selected == "" and next(Garden.sanitizeSave({ seeds = 5 }).seeds) == nil)
check("basket is capped", (function()
	local big = {}
	for _ = 1, 200 do
		table.insert(big, { c = "wheat", w = 0.8 })
	end
	return #Garden.sanitizeSave({ basket = big }).basket == Garden.BASKET_MAX
end)())

if failures == 0 then
	print("all core tests passed")
else
	print(failures .. " failures")
end
