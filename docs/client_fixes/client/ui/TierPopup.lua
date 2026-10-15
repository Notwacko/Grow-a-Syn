local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Util = require(script.Parent.Util)
local Store = require(script.Parent.Store)
local Reveal = require(script.Parent.Reveal)
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Balance = require(Shared:WaitForChild("Balance"))
local Constants = require(Shared:WaitForChild("Constants"))

local TierPopup = {}

local RARITY_BY_TIER = { "common", "uncommon", "rare", "epic", "epic", "legendary", "mythical" }

function TierPopup.start()
	local last = Store.attr("Tier", 1)
	local ready = false
	task.delay(3, function()
		ready = true
		last = Store.attr("Tier", 1)
	end)
	Store.onAttr("Tier", function(tier)
		if not ready or tier == nil then
			return
		end
		if tier > last and tier >= 2 then
			local catalog = Store.catalog()
			local stages = catalog and catalog.denominations and catalog.denominations[1] and (catalog.denominations[1].stages or catalog.denominations[1].stageNames)
			local stageName = stages and stages[tier - 1] or ("Stage " .. (tier - 1))
			Reveal.push({
				title = "New Stage!",
				name = stageName,
				sub = string.format("Seats: %d     Income: x%s", Constants.seatsForTier(tier), Util.short(Balance.tierMult(tier))),
				icon = "synagogue",
				rarity = RARITY_BY_TIER[tier] or "epic",
				button = "Wonderful!",
			})
		end
		last = tier
	end)
end

return TierPopup
