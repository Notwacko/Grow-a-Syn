local Players = game:GetService("Players")

local Balance = require(script.Parent.Balance)
local InventoryService = require(script.Parent.InventoryService)

local EffectsService = {}

function EffectsService.recompute(player)
	local data = InventoryService.get(player)
	if not data or not player.Parent then
		return
	end
	local equipped = InventoryService.equipped(player)
	player:SetAttribute("IncomeMult", Balance.incomeMult(data.Tier, equipped))
	player:SetAttribute("WelcomeBonus", Balance.welcomeBonus(data.Tier, equipped))
	player:SetAttribute("TorahCount", InventoryService.count(player, "torah"))
end

local function checkBoosts()
	local now = os.time()
	for _, player in ipairs(Players:GetPlayers()) do
		local data = InventoryService.get(player)
		if data and data.BoostEndsAt > 0 and data.BoostEndsAt <= now then
			InventoryService.setBoost(player, 1, 0)
		end
	end
end

function EffectsService.init()
	InventoryService.onChanged(EffectsService.recompute)
	task.spawn(function()
		while true do
			task.wait(1)
			checkBoosts()
		end
	end)
end

return EffectsService
