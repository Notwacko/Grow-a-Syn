local UpgradeCatalog = {}

UpgradeCatalog.list = {
	{
		id = "welcome_table",
		name = "Welcome Table",
		blurb = "Friendly greeters bring people in faster",
		effect = "arrival_speed",
		perLevel = 0.25,
		baseCost = 400,
		growth = 4,
		maxLevel = 5,
		color = { 86, 156, 255 },
	},
	{
		id = "kiddush_table",
		name = "Kiddush Table",
		blurb = "Refreshments earn a gift from each new arrival",
		effect = "arrival_tip",
		perLevel = 3,
		baseCost = 600,
		growth = 4,
		maxLevel = 5,
		color = { 255, 154, 72 },
	},
	{
		id = "membership_desk",
		name = "Membership Desk",
		blurb = "Members chip in every second",
		effect = "dues",
		perLevel = 0.15,
		baseCost = 900,
		growth = 4,
		maxLevel = 5,
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
	return math.floor(definition.baseCost * definition.growth ^ level + 0.5)
end

local function levelOf(levels, id)
	local value = levels and levels[id]
	if type(value) ~= "number" then
		return 0
	end
	return value
end

local function effectTotal(levels, effect)
	local total = 0
	for _, definition in UpgradeCatalog.list do
		if definition.effect == effect then
			total += definition.perLevel * levelOf(levels, definition.id)
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
	return math.floor(base * (1 + (tier or 1) * 0.5) + 0.5)
end

function UpgradeCatalog.duesPerSecond(levels, congregation)
	return effectTotal(levels, "dues") * math.max(0, congregation or 0)
end

return UpgradeCatalog
