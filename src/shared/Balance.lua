local Balance = {}

Balance.TIER_MULT = { 1, 3, 9, 27, 81, 243, 729 }
Balance.MAX_TIER = 7
Balance.TIER_BASE_COST = 5000
Balance.TIER_COST_GROWTH = 24
Balance.LAND_COSTS = { 30000, 720000, 17000000, 400000000, 10000000000 }
Balance.PRICE_GROWTH = 4

Balance.COST_CEILING = 9e17
Balance.UPGRADE_GROWTH = 1.15
Balance.UPGRADE_SOFT_LEVEL = 25
Balance.UPGRADE_SOFT_FACTOR = 0.25

Balance.MAX_STAR = 10
Balance.STAR_STEPS = { 4, 4, 4, 4, 4, 3.5, 3.5, 3.5, 3.2, 3.2 }

Balance.LEGACY_UNLOCK_TIER = 4
Balance.LEGACY_POINT_UNIT = 5e7
Balance.LEGACY_POINT_SCALE = 4
Balance.LEGACY_PER_POINT = 0.2
Balance.LEGACY_START_MONEY_PER_POINT = 1000
Balance.LEGACY_HEIRLOOM_BASE = 2
Balance.LEGACY_HEIRLOOM_MAX = 8

Balance.OFFLINE_RATE = 0.25
Balance.OFFLINE_BASE_HOURS = 4
Balance.OFFLINE_HOURS_PER_TIER = 1
Balance.OFFLINE_PATRON_HOURS = 12
Balance.OFFLINE_MIN_SECONDS = 120

Balance.DAILY_WINDOW = 36 * 3600
Balance.DAILY_MINUTES = { 10, 15, 20, 30, 45, 60, 90 }
Balance.DAILY_MAX_FREEZES = 2
Balance.DAILY_PATRON_FREEZES = 3
Balance.DAILY_DROP = 3
Balance.DAILY_FLOOR_MPS = 10

Balance.COLLECTION_STEP = 5
Balance.COLLECTION_CAP = 0.2

Balance.RATES = {
	MIN = 1,
}

function Balance.tierMult(tier)
	tier = math.clamp(math.floor(tonumber(tier) or 1), 1, Balance.MAX_TIER)
	return Balance.TIER_MULT[tier]
end

function Balance.tierCost(tier)
	if tier < 2 or tier > Balance.MAX_TIER then
		return nil
	end
	return math.floor(Balance.TIER_BASE_COST * Balance.TIER_COST_GROWTH ^ (tier - 2) + 0.5)
end

function Balance.landCost(landTier)
	return Balance.LAND_COSTS[landTier]
end

function Balance.priceScale(tier)
	tier = math.clamp(math.floor(tonumber(tier) or 1), 1, Balance.MAX_TIER)
	return Balance.PRICE_GROWTH ^ (tier - 1)
end

function Balance.upgradeCost(baseCost, level)
	return math.floor(baseCost * Balance.UPGRADE_GROWTH ^ level + 0.5)
end

function Balance.upgradeTotal(perLevel, level)
	level = math.max(0, math.floor(level or 0))
	local soft = Balance.UPGRADE_SOFT_LEVEL
	if level <= soft then
		return perLevel * level
	end
	return perLevel * soft + perLevel * Balance.UPGRADE_SOFT_FACTOR * (level - soft)
end

function Balance.starMult(star)
	star = math.clamp(math.floor(tonumber(star) or 0), 0, Balance.MAX_STAR)
	local value = 1
	for index = 1, star do
		value *= Balance.STAR_STEPS[index]
	end
	return value
end

function Balance.legacyPoints(earnings)
	earnings = math.max(0, tonumber(earnings) or 0)
	return math.floor(Balance.LEGACY_POINT_SCALE * math.sqrt(earnings / Balance.LEGACY_POINT_UNIT))
end

function Balance.legacyMult(totalPoints)
	return 1 + Balance.LEGACY_PER_POINT * math.max(0, tonumber(totalPoints) or 0)
end

function Balance.heirloomSlots(totalPoints)
	local extra = math.floor(math.max(0, tonumber(totalPoints) or 0) / 10)
	return math.min(Balance.LEGACY_HEIRLOOM_BASE + extra, Balance.LEGACY_HEIRLOOM_MAX)
end

function Balance.offlineCapSeconds(tier, patron)
	if patron then
		return Balance.OFFLINE_PATRON_HOURS * 3600
	end
	return (Balance.OFFLINE_BASE_HOURS + Balance.OFFLINE_HOURS_PER_TIER * math.max(0, (tier or 1) - 1)) * 3600
end

function Balance.offlineEarnings(perSecond, seconds, tier, patron)
	if seconds < Balance.OFFLINE_MIN_SECONDS or perSecond <= 0 then
		return 0, 0
	end
	local counted = math.min(seconds, Balance.offlineCapSeconds(tier, patron))
	local amount = perSecond * counted * Balance.OFFLINE_RATE * (patron and 2 or 1)
	return math.floor(amount), counted
end

function Balance.dailyMinutes(day)
	day = math.max(1, math.floor(day or 1))
	local index = (day - 1) % #Balance.DAILY_MINUTES + 1
	local cycle = math.floor((day - 1) / #Balance.DAILY_MINUTES)
	return Balance.DAILY_MINUTES[index] * (1 + 0.1 * math.min(cycle, 10))
end

function Balance.dailyBase(perSecond)
	return math.max(perSecond or 0, Balance.DAILY_FLOOR_MPS)
end

function Balance.collectionBonus(percent)
	local steps = math.floor(math.max(0, percent) / Balance.COLLECTION_STEP)
	return math.min(steps * 0.01, Balance.COLLECTION_CAP)
end

function Balance.incomeMinutes(perSecond, minutes)
	return math.floor(Balance.dailyBase(perSecond) * 60 * minutes)
end

return Balance
