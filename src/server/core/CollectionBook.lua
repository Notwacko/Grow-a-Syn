local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Guard = require(script.Parent.Guard)
local Notify = require(script.Parent.Notify)
local GameService = require(script.Parent.GameService)
local PlayerState = require(script.Parent.PlayerState)
local ItemService = require(script.Parent.ItemService)
local IncomeService = require(script.Parent.IncomeService)
local Rewards = require(script.Parent.Rewards)
local Shared = ReplicatedStorage:WaitForChild("Shared")
local ItemCatalog = require(Shared:WaitForChild("ItemCatalog"))
local Balance = require(Shared:WaitForChild("Balance"))

local CollectionBook = {}

local MILESTONES = {
	{ percent = 10, minutes = 30 },
	{ percent = 25, minutes = 90, item = "ornament_rare" },
	{ percent = 50, minutes = 240, item = "kiddush_cup_epic" },
	{ percent = 75, minutes = 480, item = "chandelier_legendary" },
	{ percent = 100, minutes = 1200, item = "ark_legendary" },
}

local function foundSet(player)
	return PlayerState.get(player, "collection", { found = {}, claimed = {} })
end

local function total()
	return #ItemCatalog.list
end

local function count(data)
	local n = 0
	for _ in data.found do
		n += 1
	end
	return n
end

function CollectionBook.percent(player)
	local data = foundSet(player)
	return count(data) / total() * 100
end

function CollectionBook.bonus(player)
	return Balance.collectionBonus(CollectionBook.percent(player))
end

function CollectionBook.discover(player, itemId)
	if not ItemCatalog.item(itemId) then
		return false
	end
	local data = foundSet(player)
	if data.found[itemId] then
		return false
	end
	local copy = { found = table.clone(data.found), claimed = table.clone(data.claimed) }
	copy.found[itemId] = true
	PlayerState.set(player, "collection", copy)
	local info = ItemCatalog.item(itemId)
	GameService.send(player, "discover", { id = itemId, name = info.name, rarity = info.rarity, count = count(copy), total = total() })
	GameService.push(player, "collection")
	return true
end

function CollectionBook.snapshot(player)
	local data = foundSet(player)
	local found = {}
	for id in data.found do
		table.insert(found, id)
	end
	table.sort(found)
	local percent = count(data) / total() * 100
	local milestones = {}
	for _, milestone in MILESTONES do
		table.insert(milestones, {
			percent = milestone.percent,
			minutes = milestone.minutes,
			item = milestone.item,
			itemName = milestone.item and ItemCatalog.item(milestone.item).name or nil,
			claimed = data.claimed[tostring(milestone.percent)] == true,
			ready = percent >= milestone.percent,
		})
	end
	return {
		found = found,
		total = total(),
		percent = percent,
		bonus = Balance.collectionBonus(percent),
		milestones = milestones,
	}
end

CollectionBook.actions = {}

function CollectionBook.actions.claim(player, payload)
	local target = payload.percent
	if not Guard.isInteger(target, 1, 100) then
		return { ok = false, reason = "invalid" }
	end
	local data = foundSet(player)
	local percent = count(data) / total() * 100
	for _, milestone in MILESTONES do
		if milestone.percent == target then
			if data.claimed[tostring(target)] or percent < target then
				return { ok = false, reason = "locked" }
			end
			local copy = { found = data.found, claimed = table.clone(data.claimed) }
			copy.claimed[tostring(target)] = true
			PlayerState.set(player, "collection", copy)
			local amount = Rewards.grantMinutes(player, milestone.minutes, "collection")
			if milestone.item then
				Rewards.grantItem(player, milestone.item, { silent = true })
			end
			Notify.send(player, "success", "Collection reward collected!")
			GameService.send(player, "reward", { title = "Collection " .. target .. "%", money = amount, item = milestone.item })
			return { ok = true }
		end
	end
	return { ok = false, reason = "invalid" }
end

function CollectionBook.init(player)
	for _, entry in ItemService.all(player) do
		CollectionBook.discover(player, entry.id)
	end
end

function CollectionBook.start()
	IncomeService.register("collection", function(player)
		return 1 + CollectionBook.bonus(player)
	end)
	ItemService.Bought:Connect(function(player, itemId)
		CollectionBook.discover(player, itemId)
	end)
	ItemService.Merged:Connect(function(player, _, itemId)
		CollectionBook.discover(player, itemId)
	end)
end

return CollectionBook
