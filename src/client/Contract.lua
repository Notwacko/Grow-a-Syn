-- Names the client depends on. Everything marked ASSUMED is not in the repo contract text and must be
-- confirmed with A (world/Money) and B (items/progression). Change names here, nowhere else.
local Contract = {}

Contract.REMOTES_FOLDER = "Remotes" -- A: Link.get(ReplicatedStorage, "Remotes", ...)

-- A (from A's Constants.REMOTES / ContractCheck)
Contract.Events = {
	Notify = "RE_Notify", -- (kind: "info"|"success"|"error", text)
	ClaimPlot = "RE_ClaimPlot",
	ExpandLand = "RE_ExpandLand",
	AdvanceTutorial = "RE_AdvanceTutorial",
	MinyanReached = "RE_MinyanReached",
	-- B (names from A's ContractCheck; payloads ASSUMED)
	InventoryChanged = "RE_InventoryChanged",
}

Contract.Functions = {
	GetCatalog = "RF_GetCatalog",
	GetInventory = "RF_GetInventory",
	Buy = "RF_Buy", -- (offerId) ASSUMED -> true | false, reason | {ok=, reason=}
	Merge = "RF_Merge", -- (uidA, uidB, uidC) ASSUMED
	Equip = "RF_Equip", -- (uid, slotName) ASSUMED
	Unequip = "RF_Unequip", -- (uid) ASSUMED
	ChooseDenomination = "RF_ChooseDenomination", -- (denominationId) ASSUMED
	UpgradeBuilding = "RF_UpgradeBuilding", -- () ASSUMED
}

-- Player attributes (A writes the first group, B the second)
Contract.Attr = {
	Money = "Money",
	MoneyPerSecond = "MoneyPerSecond",
	Congregation = "Congregation",
	MaxCongregation = "MaxCongregation",
	PlotId = "PlotId",
	LandTier = "LandTier",
	TutorialStep = "TutorialStep",
	DataLoaded = "DataLoaded", -- A: set once the saved profile is applied
	HasMinyan = "HasMinyan",
	Denomination = "Denomination",
	Tier = "Tier",
	BoostMult = "BoostMult",
	BoostEndsAt = "BoostEndsAt", -- ASSUMED: workspace:GetServerTimeNow() based epoch seconds
}

Contract.Step = { Welcome = 0, ClaimPlot = 1, Greet = 2, Buy = 3, Minyan = 4, Denomination = 5, Done = 6 }
Contract.MINYAN = 10
Contract.MAX_TIER = 7

-- ASSUMED catalog shape returned by RF_GetCatalog:
-- {
--   items = { {id, name, category, rarity, price, model, mergesTo?, robux?} },
--   buildings = { {id, name, price, model, robux?} },
--   packs = { {id, name, money, robux} },
--   boosts = { {id, name, mult, duration (seconds), robux, free?} },
--   denominations = { {id, name, blurb, model, stages = { six stage names, tier 2..7 }} },
--   rarityColors = { common = Color3, ... } (optional)
-- }
-- ASSUMED inventory shape from RF_GetInventory: { {uid, id, slot?} }

-- Mirrors A's Constants.SLOT_COUNTS (category -> slot names)
Contract.SlotsByCategory = {
	ark = { "Slot_Ark" },
	torah = { "Slot_Torah1", "Slot_Torah2", "Slot_Torah3", "Slot_Torah4", "Slot_Torah5", "Slot_Torah6" },
	ornament = { "Slot_Ornament1", "Slot_Ornament2", "Slot_Ornament3", "Slot_Ornament4", "Slot_Ornament5", "Slot_Ornament6" },
	siddur = { "Slot_Siddur1", "Slot_Siddur2", "Slot_Siddur3", "Slot_Siddur4" },
	menorah = { "Slot_Menorah" },
	kiddush_cup = { "Slot_Kiddush1", "Slot_Kiddush2" },
	chandelier = { "Slot_Chandelier1", "Slot_Chandelier2" },
	holiday_decor = { "Slot_HolidayDecor1", "Slot_HolidayDecor2", "Slot_HolidayDecor3", "Slot_HolidayDecor4" },
}

-- Mirrors A's Config (LAND_COSTS[tier] pays for tier -> tier+1, LAND_BOUNDS) and Constants.SEATS_PER_TIER
Contract.LAND_COSTS = { 750, 4000, 20000, 100000, 500000 }
Contract.MAX_LAND_TIER = 6
Contract.CLAIM_DISTANCE = 26
Contract.LAND_BOUNDS = {
	{ x1 = -50, x2 = 50, z1 = 0, z2 = 100 },
	{ x1 = -50, x2 = 50, z1 = 0, z2 = 140 },
	{ x1 = -80, x2 = 50, z1 = 0, z2 = 140 },
	{ x1 = -80, x2 = 80, z1 = 0, z2 = 140 },
	{ x1 = -80, x2 = 80, z1 = 0, z2 = 190 },
	{ x1 = -80, x2 = 80, z1 = 0, z2 = 240 },
}
Contract.SEATS_PER_TIER = { 12, 20, 30, 42, 56, 72, 100 }
-- ASSUMED: catalog.upgrades[targetTier] = { cost = number, requirement = "short text" } (optional)

Contract.CategoryNames = {
	torah = "Sefer Torah",
	ark = "Aron Kodesh",
	siddur = "Siddur",
	menorah = "Menorah",
	kiddush_cup = "Kiddush Cup",
	chandelier = "Chandelier",
	ornament = "Ornament",
	holiday_decor = "Holiday",
}

Contract.CategoryIcons = {
	torah = "📜",
	ark = "🚪",
	siddur = "📖",
	menorah = "🕎",
	kiddush_cup = "🍷",
	chandelier = "💡",
	ornament = "✨",
	holiday_decor = "🎉",
}

-- Fixed friendly messages for every reason code (A's ERROR_CODES plus a catch-all)
Contract.Reasons = {
	not_enough_money = "Not enough money yet. Keep welcoming people!",
	requirements_not_met = "You are not ready for that yet.",
	invalid = "That did not work. Please try again.",
	locked = "That is locked for now.",
	busy = "One moment, still working on it.",
	offline = "Cannot reach the server. Try again soon.",
	default = "Something went wrong. Please try again.",
}

return Contract
