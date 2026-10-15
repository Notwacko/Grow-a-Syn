local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local Link = require(script.Parent.Link)
local Guard = require(script.Parent.Guard)
local Notify = require(script.Parent.Notify)
local Economy = require(script.Parent.Economy)
local Signal = require(script.Parent.Signal)
local BuildingService = require(script.Parent.BuildingService)
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(Shared:WaitForChild("Constants"))
local ItemCatalog = require(Shared:WaitForChild("ItemCatalog"))

local ItemService = {}

ItemService.Changed = Signal.new()
ItemService.Grew = Signal.new()
ItemService.Matured = Signal.new()
ItemService.Restocked = Signal.new()

local TICK_SECONDS = 2
local ACTION_COOLDOWN = 0.15

local inventories = {}
local stock = {}
local stockEpoch = -1
local random = Random.new()
local changedRemote
local purchasedEvent

local function now()
	return os.time()
end

local function inventoryOf(player)
	local inventory = inventories[player]
	if not inventory then
		inventory = { items = {}, counter = 0 }
		inventories[player] = inventory
	end
	return inventory
end

local function newUid(inventory)
	inventory.counter += 1
	return "i" .. inventory.counter
end

local function findItem(inventory, uid)
	for index, entry in inventory.items do
		if entry.uid == uid then
			return entry, index
		end
	end
	return nil, nil
end

local function grownOf(entry)
	local info = ItemCatalog.item(entry.id)
	local total = entry.grown + (entry.since and math.max(now() - entry.since, 0) or 0)
	return math.min(total, info and info.grow or total)
end

local function growthOf(entry)
	return ItemCatalog.growth(ItemCatalog.item(entry.id), grownOf(entry))
end

local function stopGrowing(entry)
	if entry.since then
		entry.grown = grownOf(entry)
		entry.since = nil
	end
end

local function occupant(inventory, slotName, ignore)
	for _, entry in inventory.items do
		if entry.slot == slotName and entry ~= ignore then
			return entry
		end
	end
	return nil
end

local function slotExists(player, slotName)
	local info = BuildingService.getInfo(player)
	if not info or not info.model.Parent then
		return false
	end
	local slots = info.model:FindFirstChild("Slots", true)
	local part = slots and slots:FindFirstChild(slotName)
	return part ~= nil and part:IsA("BasePart")
end

local function slotNamesFor(category)
	local names = {}
	for _, group in Constants.SLOT_COUNTS do
		if Constants.SLOT_PREFIX_CATEGORY[group.prefix] == category then
			if group.count == 1 then
				table.insert(names, group.prefix)
			else
				for index = 1, group.count do
					table.insert(names, group.prefix .. index)
				end
			end
		end
	end
	return names
end

local function freeSlot(player, inventory, category)
	for _, slotName in slotNamesFor(category) do
		if not occupant(inventory, slotName) and slotExists(player, slotName) then
			return slotName
		end
	end
	return nil
end

local function notifyChanged(player, kind, uid)
	if changedRemote and Guard.isPlayer(player) then
		changedRemote:FireClient(player)
	end
	ItemService.Changed:Fire(player, kind, uid)
end

local function fail(reason)
	return { ok = false, reason = reason }
end

local function rollMutation()
	local roll = random:NextNumber()
	local threshold = 0
	for index = #ItemCatalog.MUTATIONS, 1, -1 do
		local mutation = ItemCatalog.MUTATIONS[index]
		threshold += mutation.chance
		if roll < threshold then
			return mutation.id
		end
	end
	return "none"
end

local function refreshStock()
	local epoch = ItemCatalog.epochOf(now())
	if epoch ~= stockEpoch then
		local first = stockEpoch < 0
		stockEpoch = epoch
		stock = ItemCatalog.stockFor(epoch)
		Workspace:SetAttribute("ShopEpoch", epoch)
		Workspace:SetAttribute("ShopRestockAt", (epoch + 1) * ItemCatalog.RESTOCK_SECONDS)
		if not first then
			ItemService.Restocked:Fire(epoch)
		end
	end
end

function ItemService.stock()
	refreshStock()
	return stock
end

function ItemService.catalogItems()
	refreshStock()
	local items = {}
	for _, entry in ItemCatalog.list do
		table.insert(items, {
			id = entry.id,
			name = entry.name,
			category = entry.category,
			rarity = entry.rarity,
			price = entry.price,
			model = entry.model,
			mergesTo = entry.mergesTo,
			stock = stock[entry.id] or 0,
			bonus = entry.bonus,
			grow = entry.grow,
		})
	end
	return items
end

function ItemService.restockAt()
	refreshStock()
	return (stockEpoch + 1) * ItemCatalog.RESTOCK_SECONDS
end

function ItemService.init(player, saved)
	local inventory = { items = {}, counter = 0 }
	for _, entry in ItemCatalog.cleanSaved(saved) do
		local number = tonumber(string.sub(entry.uid, 2))
		if number and number > inventory.counter then
			inventory.counter = number
		end
		if entry.slot and not Constants.slotCategory(entry.slot) then
			entry.slot = nil
		end
		local info = ItemCatalog.item(entry.id)
		if entry.slot and Constants.slotCategory(entry.slot) ~= info.category then
			entry.slot = nil
		end
		if entry.slot then
			if occupant(inventory, entry.slot) then
				entry.slot = nil
			elseif not entry.since then
				entry.since = now()
			end
		end
		if not entry.slot then
			stopGrowing(entry)
		end
		table.insert(inventory.items, entry)
	end
	inventories[player] = inventory
end

function ItemService.serialize(player)
	local inventory = inventories[player]
	local result = {}
	if not inventory then
		return result
	end
	for _, entry in inventory.items do
		table.insert(result, {
			uid = entry.uid,
			id = entry.id,
			slot = entry.slot,
			grown = entry.grown,
			since = entry.since,
			mut = entry.mut,
		})
	end
	return result
end

function ItemService.clientInventory(player)
	local inventory = inventoryOf(player)
	local items = {}
	for _, entry in inventory.items do
		table.insert(items, {
			uid = entry.uid,
			id = entry.id,
			slot = entry.slot,
			growth = growthOf(entry),
			mutation = (entry.mut and entry.mut ~= "none") and entry.mut or nil,
		})
	end
	return { items = items }
end

function ItemService.placed(player)
	local inventory = inventories[player]
	local list = {}
	if not inventory then
		return list
	end
	for _, entry in inventory.items do
		if entry.slot then
			table.insert(list, {
				uid = entry.uid,
				id = entry.id,
				slot = entry.slot,
				growth = growthOf(entry),
				mutation = (entry.mut and entry.mut ~= "none") and entry.mut or nil,
			})
		end
	end
	return list
end

function ItemService.bonus(player)
	local inventory = inventories[player]
	if not inventory then
		return 0
	end
	local total = 0
	for _, entry in inventory.items do
		if entry.slot then
			local mutation = (entry.mut and entry.mut ~= "none") and entry.mut or nil
			total += ItemCatalog.bonusOf(ItemCatalog.item(entry.id), growthOf(entry), mutation)
		end
	end
	return total
end

local function place(player, inventory, entry, slotName)
	local info = ItemCatalog.item(entry.id)
	if not info or Constants.slotCategory(slotName) ~= info.category or not slotExists(player, slotName) then
		return false
	end
	local other = occupant(inventory, slotName, entry)
	if other then
		other.slot = nil
		stopGrowing(other)
	end
	entry.slot = slotName
	if not entry.since then
		entry.since = now()
	end
	return true
end

function ItemService.buy(player, offerId)
	if not Guard.isPlayer(player) or not Guard.isString(offerId, 48) then
		return fail("invalid")
	end
	if not Guard.allow(player, "Buy", ACTION_COOLDOWN) then
		return fail("busy")
	end
	local info = ItemCatalog.item(offerId)
	if not info then
		Guard.flag(player, "Buy", "unknown offer " .. offerId)
		return fail("invalid")
	end
	if (player:GetAttribute("PlotId") or 0) <= 0 then
		Notify.send(player, "error", "Claim a plot first")
		return fail("locked")
	end
	refreshStock()
	if (stock[offerId] or 0) <= 0 then
		Notify.send(player, "info", "Sold out. The shop restocks soon")
		return fail("locked")
	end
	local inventory = inventoryOf(player)
	if #inventory.items >= ItemCatalog.MAX_ITEMS then
		Notify.send(player, "error", "Your storage is full")
		return fail("locked")
	end
	if not Economy.spend(player, info.price, "item_" .. offerId) then
		return fail("not_enough_money")
	end
	stock[offerId] -= 1
	local entry = { uid = newUid(inventory), id = offerId, grown = 0 }
	table.insert(inventory.items, entry)
	local slotName = freeSlot(player, inventory, info.category)
	local placed = slotName ~= nil and place(player, inventory, entry, slotName)
	if placed then
		Notify.send(player, "success", info.name .. " is growing in your synagogue!")
	else
		Notify.send(player, "success", info.name .. " is in your bag. Place it from Items")
	end
	if purchasedEvent then
		purchasedEvent:Fire(player, offerId)
	end
	notifyChanged(player, "buy", entry.uid)
	return { ok = true, uid = entry.uid, stock = stock[offerId] }
end

function ItemService.equip(player, uid, slotName)
	if not Guard.isPlayer(player) or not Guard.isString(uid, 24) or not Guard.isString(slotName, 32) then
		return fail("invalid")
	end
	if not Guard.allow(player, "ItemAction", ACTION_COOLDOWN) then
		return fail("busy")
	end
	local inventory = inventoryOf(player)
	local entry = findItem(inventory, uid)
	if not entry then
		return fail("invalid")
	end
	if not place(player, inventory, entry, slotName) then
		return fail("invalid")
	end
	notifyChanged(player, "equip", uid)
	return { ok = true }
end

function ItemService.unequip(player, uid)
	if not Guard.isPlayer(player) or not Guard.isString(uid, 24) then
		return fail("invalid")
	end
	if not Guard.allow(player, "ItemAction", ACTION_COOLDOWN) then
		return fail("busy")
	end
	local inventory = inventoryOf(player)
	local entry = findItem(inventory, uid)
	if not entry then
		return fail("invalid")
	end
	if entry.slot then
		entry.slot = nil
		stopGrowing(entry)
	end
	notifyChanged(player, "unequip", uid)
	return { ok = true }
end

function ItemService.merge(player, ...)
	if not Guard.isPlayer(player) then
		return fail("invalid")
	end
	local uids = { ... }
	if type(uids[1]) == "table" then
		uids = uids[1]
	end
	if #uids ~= ItemCatalog.MERGE_COUNT then
		return fail("invalid")
	end
	if not Guard.allow(player, "ItemAction", ACTION_COOLDOWN) then
		return fail("busy")
	end
	local inventory = inventoryOf(player)
	local chosen, seen, itemId = {}, {}, nil
	for _, uid in uids do
		if not Guard.isString(uid, 24) or seen[uid] then
			return fail("invalid")
		end
		seen[uid] = true
		local entry = findItem(inventory, uid)
		if not entry or (itemId and entry.id ~= itemId) then
			return fail("invalid")
		end
		itemId = entry.id
		table.insert(chosen, entry)
	end
	local info = ItemCatalog.item(itemId)
	if not info or not info.mergesTo then
		return fail("requirements_not_met")
	end
	local slotName
	for _, entry in chosen do
		if entry.slot and not slotName then
			slotName = entry.slot
		end
	end
	for _, entry in chosen do
		local _, index = findItem(inventory, entry.uid)
		table.remove(inventory.items, index)
	end
	local merged = { uid = newUid(inventory), id = info.mergesTo, grown = 0 }
	table.insert(inventory.items, merged)
	if slotName then
		place(player, inventory, merged, slotName)
	else
		local free = freeSlot(player, inventory, info.category)
		if free then
			place(player, inventory, merged, free)
		end
	end
	local result = ItemCatalog.item(info.mergesTo)
	Notify.send(player, "success", "Merged into a " .. result.name .. "!")
	notifyChanged(player, "merge", merged.uid)
	return { ok = true, uid = merged.uid }
end

local function tickPlayer(player)
	local inventory = inventories[player]
	if not inventory then
		return
	end
	local growing = false
	for _, entry in inventory.items do
		if entry.slot then
			local info = ItemCatalog.item(entry.id)
			local grown = grownOf(entry)
			if grown >= info.grow then
				if not entry.mut then
					entry.mut = rollMutation()
					local mutation = entry.mut ~= "none" and ItemCatalog.mutation(entry.mut) or nil
					if mutation then
						Notify.send(player, "success", "Wow! Your " .. info.name .. " became " .. mutation.name .. "!")
					else
						Notify.send(player, "info", "Your " .. info.name .. " is fully grown")
					end
					ItemService.Matured:Fire(player, entry.uid, entry.slot, mutation and mutation.id or nil)
					if changedRemote then
						changedRemote:FireClient(player)
					end
				end
			else
				growing = true
			end
		end
	end
	ItemService.Grew:Fire(player, growing)
end

function ItemService.forget(player)
	inventories[player] = nil
end

function ItemService.start()
	changedRemote = Link.get(ReplicatedStorage, "Remotes", "RE_InventoryChanged", "RemoteEvent")
	purchasedEvent = Link.get(ServerStorage, "Bridge", Constants.BRIDGE.Purchased, "BindableEvent")
	refreshStock()
	task.spawn(function()
		while true do
			task.wait(TICK_SECONDS)
			refreshStock()
			for _, player in Players:GetPlayers() do
				local ok, err = pcall(tickPlayer, player)
				if not ok then
					warn("[Items] tick failed: " .. tostring(err))
				end
			end
		end
	end)
end

return ItemService
