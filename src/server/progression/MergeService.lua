local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Balance = require(script.Parent.Balance)
local Guard = require(script.Parent.Guard)
local InventoryService = require(script.Parent.InventoryService)
local Link = require(script.Parent.Link)

local MergeService = {}

function MergeService.merge(player, uids)
	if type(uids) ~= "table" or #uids ~= 3 then
		return { ok = false, reason = "invalid" }
	end
	if not InventoryService.get(player) then
		return { ok = false, reason = "offline" }
	end
	local seen = {}
	local items = {}
	for i = 1, 3 do
		local uid = uids[i]
		if not Guard.isString(uid) or seen[uid] then
			return { ok = false, reason = "invalid" }
		end
		seen[uid] = true
		local item = InventoryService.find(player, uid)
		if not item then
			return { ok = false, reason = "invalid" }
		end
		table.insert(items, item)
	end
	local category = items[1].category
	local rarity = items[1].rarity
	for _, item in ipairs(items) do
		if item.category ~= category or item.rarity ~= rarity then
			return { ok = false, reason = "invalid" }
		end
		if item.slot then
			return { ok = false, reason = "requirements_not_met" }
		end
	end
	local nextRarity = Balance.nextRarity(rarity)
	if not nextRarity then
		return { ok = false, reason = "requirements_not_met" }
	end
	InventoryService.consumeForMerge(player, { uids[1], uids[2], uids[3] })
	local newItem = InventoryService.addItem(player, category, nextRarity)
	InventoryService.changed(player)
	return { ok = true, uid = newItem and newItem.uid }
end

function MergeService.init()
	local remote = Link.get(ReplicatedStorage, "Remotes", "RF_Merge", "RemoteFunction")
	remote.OnServerInvoke = function(player, uids)
		return Guard.run(player, "merge", MergeService.merge, player, uids)
	end
end

return MergeService
