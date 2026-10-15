local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Economy = require(script.Parent.Economy)
local ItemService = require(script.Parent.ItemService)
local Balance = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Balance"))

local Rewards = {}

function Rewards.minutesAmount(player, minutes)
	return Balance.incomeMinutes(tonumber(player:GetAttribute("MoneyPerSecond")) or 0, minutes)
end

function Rewards.grantMinutes(player, minutes, reason)
	local amount = Rewards.minutesAmount(player, minutes)
	Economy.grant(player, amount, reason or "reward")
	return amount
end

function Rewards.grantItem(player, itemId, options)
	return ItemService.grantItem(player, itemId, options)
end

return Rewards
