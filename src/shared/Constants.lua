local Constants = {}

Constants.GAME_NAME = "Grow a Synagogue"

Constants.RARITIES = { "common", "uncommon", "rare", "epic", "legendary", "mythical" }

Constants.CATEGORIES = {
	"torah",
	"ark",
	"siddur",
	"menorah",
	"kiddush_cup",
	"chandelier",
	"ornament",
	"holiday_decor",
}

Constants.DENOMINATIONS = { "ashkenazi", "sephardic", "mizrahi" }

Constants.ASHKENAZI_STAGES = {
	[2] = "Ashkenazi Reform",
	[3] = "Ashkenazi Conservative",
	[4] = "Ashkenazi Orthodox",
	[5] = "Ashkenazi Ultra Orthodox",
	[6] = "Ashkenazi Hasidic",
	[7] = "Ashkenazi Haredi",
}

Constants.MAX_TIER = 7
Constants.MAX_LAND_TIER = 6
Constants.SEATS_PER_TIER = { 12, 20, 30, 42, 56, 72, 100 }
Constants.MINYAN_SIZE = 10
Constants.PLOT_COUNT = 8
Constants.START_MONEY = 100
Constants.MONEY_MAX = 1e15
Constants.GREET_REWARD = 10
Constants.TUTORIAL_GREETERS = 3

Constants.BUILDING_STARTER = "starter"

Constants.SLOT_PREFIX_CATEGORY = {
	Slot_Ark = "ark",
	Slot_Torah = "torah",
	Slot_Ornament = "ornament",
	Slot_Siddur = "siddur",
	Slot_Menorah = "menorah",
	Slot_Kiddush = "kiddush_cup",
	Slot_Chandelier = "chandelier",
	Slot_HolidayDecor = "holiday_decor",
}

Constants.SLOT_COUNTS = {
	{ prefix = "Slot_Ark", count = 1 },
	{ prefix = "Slot_Torah", count = 6 },
	{ prefix = "Slot_Ornament", count = 6 },
	{ prefix = "Slot_Siddur", count = 4 },
	{ prefix = "Slot_Menorah", count = 1 },
	{ prefix = "Slot_Kiddush", count = 2 },
	{ prefix = "Slot_Chandelier", count = 2 },
	{ prefix = "Slot_HolidayDecor", count = 4 },
}

local slotNames = {}
for _, group in Constants.SLOT_COUNTS do
	if group.count == 1 then
		table.insert(slotNames, group.prefix)
	else
		for i = 1, group.count do
			table.insert(slotNames, group.prefix .. i)
		end
	end
end
Constants.SLOT_NAMES = slotNames

Constants.TUTORIAL = {
	WELCOME = 0,
	CLAIM_PLOT = 1,
	GREET = 2,
	BUY = 3,
	MINYAN = 4,
	DENOMINATION = 5,
	DONE = 6,
}

Constants.CORE_ATTRIBUTES = {
	Money = 100,
	MoneyPerSecond = 0,
	Congregation = 0,
	MaxCongregation = 12,
	PlotId = 0,
	LandTier = 1,
	TutorialStep = 0,
	HasMinyan = false,
}

Constants.PROGRESSION_ATTRIBUTES = {
	Denomination = "",
	Tier = 1,
	IncomeMult = 1,
	WelcomeBonus = 0,
	TorahCount = 0,
	BoostMult = 1,
	BoostEndsAt = 0,
}

Constants.WORKSPACE_ATTRIBUTES = {
	EventMult = 1,
	CoreOnline = false,
	ProgressionOnline = false,
}

Constants.REMOTES = {
	Notify = "RE_Notify",
	ClaimPlot = "RE_ClaimPlot",
	ExpandLand = "RE_ExpandLand",
	AdvanceTutorial = "RE_AdvanceTutorial",
	MinyanReached = "RE_MinyanReached",
}

Constants.BRIDGE = {
	SpendMoney = "SpendMoney",
	GrantMoney = "GrantMoney",
	Purchased = "Purchased",
}

Constants.ERROR_CODES = {
	"not_enough_money",
	"requirements_not_met",
	"invalid",
	"locked",
	"busy",
	"offline",
}

function Constants.buildingName(denomination, tier)
	if type(tier) ~= "number" or tier <= 1 or type(denomination) ~= "string" or denomination == "" then
		return Constants.BUILDING_STARTER
	end
	if not table.find(Constants.DENOMINATIONS, denomination) then
		return Constants.BUILDING_STARTER
	end
	tier = math.clamp(math.floor(tier), 1, Constants.MAX_TIER)
	if tier <= 1 then
		return Constants.BUILDING_STARTER
	end
	return denomination .. "_T" .. tier
end

function Constants.seatsForTier(tier)
	tier = math.clamp(math.floor(tonumber(tier) or 1), 1, Constants.MAX_TIER)
	return Constants.SEATS_PER_TIER[tier]
end

function Constants.slotCategory(slotName)
	for prefix, category in Constants.SLOT_PREFIX_CATEGORY do
		if slotName == prefix then
			return category
		end
		if string.sub(slotName, 1, #prefix) == prefix and tonumber(string.sub(slotName, #prefix + 1)) then
			return category
		end
	end
	return nil
end

return Constants
