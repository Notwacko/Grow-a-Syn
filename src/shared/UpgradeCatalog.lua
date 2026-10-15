local Balance = require(script and script.Parent.Balance or "./Balance")

local UpgradeCatalog = {}

UpgradeCatalog.list = {
	{
		id = "welcome_table",
		name = "Welcome Table",
		blurb = "Friendly greeters bring people in faster",
		effect = "arrival_speed",
		perLevel = 0.05,
		baseCost = 400,
		maxLevel = math.huge,
		color = { 86, 156, 255 },
	},
	{
		id = "kiddush_table",
		name = "Kiddush Table",
		blurb = "Refreshments earn a gift from each new arrival",
		effect = "arrival_tip",
		perLevel = 10,
		baseCost = 600,
		maxLevel = math.huge,
		color = { 255, 154, 72 },
	},
	{
		id = "membership_desk",
		name = "Membership Desk",
		blurb = "Members support the synagogue, raising all income",
		effect = "income",
		perLevel = 0.04,
		baseCost = 900,
		maxLevel = math.huge,
		color = { 94, 214, 130 },
	},
}

local byId = {}
for index, definition in UpgradeCatalog.list do
	definition.order = index
	byId[definition.id] = definition
end

function UpgradeCatalog.get(id)
	return byId[id]
end

function UpgradeCatalog.cost(definition, level)
	if level >= definition.maxLevel then
		return nil
	end
	local value = Balance.upgradeCost(definition.baseCost, level)
	if value > Balance.COST_CEILING then
		return nil
	end
	return value
end

local function levelOf(levels, id)
	local value = levels and levels[id]
	if type(value) ~= "number" or value ~= value or value < 0 then
		return 0
	end
	return math.floor(value)
end

local function effectTotal(levels, effect)
	local total = 0
	for _, definition in UpgradeCatalog.list do
		if definition.effect == effect then
			total += Balance.upgradeTotal(definition.perLevel, levelOf(levels, definition.id))
		end
	end
	return total
end

function UpgradeCatalog.arrivalBonus(levels)
	return effectTotal(levels, "arrival_speed")
end

function UpgradeCatalog.tip(levels, tier)
	local base = effectTotal(levels, "arrival_tip")
	if base <= 0 then
		return 0
	end
	return math.floor(base * Balance.tierMult(tier) + 0.5)
end

function UpgradeCatalog.incomeMult(levels)
	return 1 + effectTotal(levels, "income")
end

function UpgradeCatalog.duesPerSecond()
	return 0
end

function UpgradeCatalog.describe(definition, level)
	local total = Balance.upgradeTotal(definition.perLevel, level)
	local nextTotal = Balance.upgradeTotal(definition.perLevel, level + 1)
	return total, nextTotal - total
end

return UpgradeCatalog
