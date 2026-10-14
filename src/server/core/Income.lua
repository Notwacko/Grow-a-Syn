local Income = {}

function Income.perSecond(hasMinyan, congregation, incomeMult, boostMult, eventMult)
	if not hasMinyan then
		return 0
	end
	local value = congregation * incomeMult * boostMult * eventMult
	if value ~= value then
		return 0
	end
	return math.clamp(value, 0, 1e12)
end

function Income.arrivalInterval(welcomeBonus, hasMinyan, base, minInterval, maxInterval, tutorialInterval)
	local interval = math.clamp(base / (1 + welcomeBonus), minInterval, maxInterval)
	if not hasMinyan then
		interval = math.min(interval, tutorialInterval)
	end
	return interval
end

return Income
