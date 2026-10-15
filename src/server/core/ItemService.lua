local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Link = require(script.Parent.Link)
local Guard = require(script.Parent.Guard)
local Notify = require(script.Parent.Notify)
local Economy = require(script.Parent.Economy)
local Signal = require(script.Parent.Signal)
local PlayerState = require(script.Parent.PlayerState)
local BuildingService = require(script.Parent.BuildingService)
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Constants = require(Shared:WaitForChild("Constants"))
local ItemCatalog = require(Shared:WaitForChild("ItemCatalog"))
local Balance = require(Shared:WaitForChild("Balance"))

local ItemService = {}

ItemService.Changed = Signal.new()
ItemService.Grew = Signal.new()
ItemService.Matured = Signal.new()
ItemService.Restocked = Signal.new()
ItemService.Bought = Signal.new()
ItemService.Merged = Signal.new()

local TICK_SECONDS = 2
local ACTION_COOLDOWN = 0.15
local OFFLINE_GROWTH_CAP = 48 * 3600

local inventories = {}
local shops = {}
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

local function rateOf(player)
	local rate = tonumber(player:GetAttribute("GrowthRate")) or 1
	if rate ~= rate then
		rate = 1
	end
	return math.clamp(rate, 0.1, 50)
end

local function growSeconds(entry)
	local info = ItemCatalog.item(entry.id)
	return info and info.grow or 0
end

local function accrue(player, entry)
	if entry.slot and entry.since then
		local info = ItemCatalog.item(entry.id)
		local stamp = now()
		local elapsed = math.max(stamp - entry.since, 0)
		entry.grown = math.min(entry.grown + elapsed * rateOf(player), info and info.grow or entry.grown)
		entry.since = stamp
	end
end

local function grownOf(player, entry)
	local info = ItemCatalog.item(entry.id)
	local total = entry.grown
	if entry.slot and entry.since then
		total += math.max(now() - entry.since, 0) * rateOf(player)
	end
	return math.min(total, info and info.grow or total)
end

local function growthOf(player, entry)
	return ItemCatalog.growth(ItemCatalog.item(entry.id), grownOf(player, entry))
end

local function stopGrowing(player, entry)
	accrue(player, entry)
	entry.since = nil
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

local function updateTorahCount(player)
	local inventory = inventories[player]
	local count = 0
	if inventory then
		for _, entry in inventory.items do
			local info = ItemCatalog.item(entry.id)
			if info and info.category == "torah" then
				count += 1
			end
		end
	end
	if Guard.isPlayer(player) and player:GetAttribute("TorahCount") ~= count then
		player:SetAttribute("TorahCount", count)
	end
end

local function notifyChanged(player, kind, uid)
	updateTorahCount(player)
	if changedRemote and Guard.isPlayer(player) then
		changedRemote:FireClient(player)
	end
	ItemService.Changed:Fire(player, kind, uid)
end

local function fail(reason)
	return { ok = false, reason = reason }
end

local function rollMutation(player)
	local catalysts = PlayerState.get(player, "catalysts", 0)
	if catalysts > 0 then
		PlayerState.add(player, "catalysts", -1)
		local pool = {}
		local total = 0
		for _, mutation in ItemCatalog.MUTATIONS do
			if mutation.mult >= 3 then
				table.insert(pool, mutation)
				total += mutation.chance
			end
		end
		local roll = random:NextNumber() * total
		for _, mutation in pool do
			roll -= mutation.chance
			if roll <= 0 then
				return mutation.id
			end
		end
		return pool[1].id
	end
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

local function shopOf(player)
	local shop = shops[player]
	if not shop then
		shop = { epoch = -1, bought = {} }
		shops[player] = shop
	end
	local seconds = player:GetAttribute("Pass_swift_delivery") == true and ItemCatalog.PATRON_RESTOCK_SECONDS or ItemCatalog.RESTOCK_SECONDS
	local epoch = ItemCatalog.epochOf(now(), seconds)
	if shop.epoch ~= epoch or shop.seconds ~= seconds then
		local first = shop.epoch < 0
		shop.epoch = epoch
		shop.seconds = seconds
		shop.bought = {}
		shop.stock = ItemCatalog.stockFor(epoch)
		player:SetAttribute("ShopEpoch", epoch)
		player:SetAttribute("ShopRestockAt", (epoch + 1) * seconds)
		player:SetAttribute("ShopRestockSeconds", seconds)
		if not first then
			ItemService.Restocked:Fire(player, epoch)
		end
	end
	return shop
end

function ItemService.restockAt(player)
	shopOf(player)
	return player:GetAttribute("ShopRestockAt") or 0
end

function ItemService.priceFor(player, info)
	return math.floor(info.price * Balance.priceScale(player:GetAttribute("Tier")) + 0.5)
end

function ItemService.stockLeft(player, id)
	local shop = shopOf(player)
	return math.max((shop.stock[id] or 0) - (shop.bought[id] or 0), 0)
end

function ItemService.catalogItems(player)
	local shop = shopOf(player)
	local items = {}
	for _, entry in ItemCatalog.list do
		table.insert(items, {
			id = entry.id,
			name = entry.name,
			category = entry.category,
			rarity = entry.rarity,
			price = ItemService.priceFor(player, entry),
			model = entry.model,
			mergesTo = entry.mergesTo,
			stock = math.max((shop.stock[entry.id] or 0) - (shop.bought[entry.id] or 0), 0),
			bonus = entry.bonus,
			grow = entry.grow,
		})
	end
	return items
end

function ItemService.init(player, saved)
	local inventory = { items = {}, counter = 0 }
	for _, entry in ItemCatalog.cleanSaved(saved) do
		local number = tonumber(string.sub(entry.uid, 2))
		if number and number > inventory.counter then
			inventory.counter = number
		end
		local info = ItemCatalog.item(entry.id)
		if entry.slot and (not Constants.slotCategory(entry.slot) or Constants.slotCategory(entry.slot) ~= info.category) then
			entry.slot = nil
		end
		if entry.slot and occupant(inventory, entry.slot) then
			entry.slot = nil
		end
		if entry.slot then
			if entry.since then
				local elapsed = math.clamp(now() - entry.since, 0, OFFLINE_GROWTH_CAP)
				entry.grown = math.min(entry.grown + elapsed, info.grow)
			end
			entry.since = now()
		else
			entry.since = nil
		end
		table.insert(inventory.items, entry)
	end
	inventories[player] = inventory
	updateTorahCount(player)
	shopOf(player)
end

function ItemService.serialize(player)
	local inventory = inventories[player]
	local result = {}
	if not inventory then
		return result
	end
	for _, entry in inventory.items do
		accrue(player, entry)
		table.insert(result, {
			uid = entry.uid,
			id = entry.id,
			slot = entry.slot,
			grown = entry.grown,
			since = entry.since,
			mut = entry.mut,
			star = entry.star,
		})
	end
	return result
end

local function describe(player, entry)
	return {
		uid = entry.uid,
		id = entry.id,
		slot = entry.slot,
		growth = growthOf(player, entry),
		mutation = (entry.mut and entry.mut ~= "none") and entry.mut or nil,
		star = entry.star or 0,
	}
end

function ItemService.clientInventory(player)
	local inventory = inventoryOf(player)
	local items = {}
	for _, entry in inventory.items do
		table.insert(items, describe(player, entry))
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
			table.insert(list, describe(player, entry))
		end
	end
	return list
end

function ItemService.all(player)
	local inventory = inventories[player]
	local list = {}
	if inventory then
		for _, entry in inventory.items do
			table.insert(list, entry)
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
			total += ItemCatalog.bonusOf(ItemCatalog.item(entry.id), growthOf(player, entry), mutation, entry.star)
		end
	end
	return total
end

function ItemService.count(player)
	local inventory = inventories[player]
	return inventory and #inventory.items or 0
end

function ItemService.owned(player, id)
	local inventory = inventories[player]
	if not inventory then
		return false
	end
	for _, entry in inventory.items do
		if entry.id == id then
			return true
		end
	end
	return false
end

local function place(player, inventory, entry, slotName)
	local info = ItemCatalog.item(entry.id)
	if not info or Constants.slotCategory(slotName) ~= info.category or not slotExists(player, slotName) then
		return false
	end
	local other = occupant(inventory, slotName, entry)
	if other then
		stopGrowing(player, other)
		other.slot = nil
	end
	entry.slot = slotName
	entry.since = now()
	return true
end

local function addEntry(player, id, star, mutation)
	local inventory = inventoryOf(player)
	local entry = { uid = newUid(inventory), id = id, grown = 0, star = star or 0, mut = mutation }
	table.insert(inventory.items, entry)
	local info = ItemCatalog.item(id)
	local slotName = freeSlot(player, inventory, info.category)
	local placed = slotName ~= nil and place(player, inventory, entry, slotName)
	return entry, placed
end

function ItemService.grantItem(player, id, options)
	options = options or {}
	if not Guard.isPlayer(player) or not ItemCatalog.item(id) then
		return nil
	end
	local inventory = inventoryOf(player)
	if #inventory.items >= ItemCatalog.MAX_ITEMS then
		return nil
	end
	local entry, placed = addEntry(player, id, options.star, options.mutation)
	if options.grown then
		entry.grown = math.min(options.grown, growSeconds(entry))
	end
	if not options.silent then
		local info = ItemCatalog.item(id)
		Notify.send(player, "success", (placed and info.name .. " was placed in your synagogue!") or (info.name .. " is in your bag"))
	end
	notifyChanged(player, "grant", entry.uid)
	ItemService.Bought:Fire(player, id, entry.uid, "grant")
	return entry
end

function ItemService.completeGrowth(player, seconds)
	local inventory = inventories[player]
	if not inventory then
		return 0
	end
	local count = 0
	for _, entry in inventory.items do
		if entry.slot then
			accrue(player, entry)
			local before = entry.grown
			entry.grown = math.min(entry.grown + seconds, growSeconds(entry))
			if entry.grown > before then
				count += 1
			end
		end
	end
	if count > 0 then
		notifyChanged(player, "grow", nil)
	end
	return count
end

function ItemService.resetForLegacy(player, keepUids)
	local inventory = inventoryOf(player)
	local kept = {}
	for _, entry in inventory.items do
		local info = ItemCatalog.item(entry.id)
		if (info and info.category == "torah") or keepUids[entry.uid] then
			accrue(player, entry)
			if entry.slot then
				entry.since = now()
			end
			table.insert(kept, entry)
		end
	end
	inventory.items = kept
	notifyChanged(player, "legacy", nil)
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
	local shop = shopOf(player)
	if ItemService.stockLeft(player, offerId) <= 0 then
		Notify.send(player, "info", "Sold out. The shelves restock soon")
		return fail("locked")
	end
	local inventory = inventoryOf(player)
	if #inventory.items >= ItemCatalog.MAX_ITEMS then
		Notify.send(player, "error", "Your storage is full")
		return fail("locked")
	end
	local price = ItemService.priceFor(player, info)
	if not Economy.spend(player, price, "item_" .. offerId) then
		return fail("not_enough_money")
	end
	shop.bought[offerId] = (shop.bought[offerId] or 0) + 1
	local entry, placed = addEntry(player, offerId, 0, nil)
	if placed then
		Notify.send(player, "success", info.name .. " is growing in your synagogue!")
	else
		Notify.send(player, "success", info.name .. " is in your bag. Place it from Items")
	end
	if purchasedEvent then
		purchasedEvent:Fire(player, offerId)
	end
	ItemService.Bought:Fire(player, offerId, entry.uid, "buy")
	notifyChanged(player, "buy", entry.uid)
	return { ok = true, uid = entry.uid, stock = ItemService.stockLeft(player, offerId), price = price }
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
		stopGrowing(player, entry)
		entry.slot = nil
	end
	notifyChanged(player, "unequip", uid)
	return { ok = true }
end

local function mergeGroup(player, inventory, chosen)
	local first = chosen[1]
	local result = ItemCatalog.mergeResult(first.id, first.star or 0)
	if not result then
		return nil
	end
	local slotName
	local bestMutation
	local bestMult = 0
	for _, entry in chosen do
		if entry.slot and not slotName then
			slotName = entry.slot
		end
		local mutation = ItemCatalog.mutation(entry.mut)
		if mutation and mutation.mult > bestMult then
			bestMult = mutation.mult
			bestMutation = mutation.id
		end
	end
	for _, entry in chosen do
		local _, index = findItem(inventory, entry.uid)
		table.remove(inventory.items, index)
	end
	local keepMutation = (result.id == first.id) and bestMutation or nil
	local merged = { uid = newUid(inventory), id = result.id, grown = 0, star = result.star, mut = keepMutation }
	table.insert(inventory.items, merged)
	if slotName then
		place(player, inventory, merged, slotName)
	else
		local free = freeSlot(player, inventory, ItemCatalog.item(result.id).category)
		if free then
			place(player, inventory, merged, free)
		end
	end
	return merged
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
	local chosen, seen = {}, {}
	for _, uid in uids do
		if not Guard.isString(uid, 24) or seen[uid] then
			return fail("invalid")
		end
		seen[uid] = true
		local entry = findItem(inventory, uid)
		if not entry then
			return fail("invalid")
		end
		if chosen[1] and (entry.id ~= chosen[1].id or (entry.star or 0) ~= (chosen[1].star or 0)) then
			return fail("invalid")
		end
		table.insert(chosen, entry)
	end
	for _, entry in chosen do
		accrue(player, entry)
	end
	local merged = mergeGroup(player, inventory, chosen)
	if not merged then
		return fail("requirements_not_met")
	end
	local info = ItemCatalog.item(merged.id)
	Notify.send(player, "success", "Merged into " .. ItemCatalog.displayName(info, merged.mut, merged.star) .. "!")
	ItemService.Merged:Fire(player, merged.uid, merged.id, merged.star)
	notifyChanged(player, "merge", merged.uid)
	return { ok = true, uid = merged.uid }
end

function ItemService.mergeAll(player)
	if not Guard.isPlayer(player) or not Guard.allow(player, "ItemAction", 0.4) then
		return fail("busy")
	end
	local inventory = inventoryOf(player)
	local groups = {}
	for _, entry in inventory.items do
		if ItemCatalog.mergeResult(entry.id, entry.star or 0) then
			local key = entry.id .. ":" .. (entry.star or 0)
			groups[key] = groups[key] or {}
			table.insert(groups[key], entry)
		end
	end
	local merges = 0
	for _, group in groups do
		table.sort(group, function(a, b)
			if (a.slot ~= nil) ~= (b.slot ~= nil) then
				return a.slot == nil
			end
			return a.uid < b.uid
		end)
		while #group >= ItemCatalog.MERGE_COUNT and merges < 40 do
			local chosen = { table.remove(group, 1), table.remove(group, 1), table.remove(group, 1) }
			for _, entry in chosen do
				accrue(player, entry)
			end
			if mergeGroup(player, inventory, chosen) then
				merges += 1
			end
		end
	end
	if merges == 0 then
		return fail("requirements_not_met")
	end
	Notify.send(player, "success", "Merged " .. merges .. " times!")
	notifyChanged(player, "merge", nil)
	return { ok = true, merges = merges }
end

local function tickPlayer(player)
	local inventory = inventories[player]
	if not inventory then
		return
	end
	shopOf(player)
	local growing = false
	for _, entry in inventory.items do
		if entry.slot then
			local info = ItemCatalog.item(entry.id)
			accrue(player, entry)
			if entry.grown >= info.grow then
				if not entry.mut then
					entry.mut = rollMutation(player)
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
	shops[player] = nil
end

ItemService.actions = {}

function ItemService.snapshot(player)
	return { count = ItemService.count(player), max = ItemCatalog.MAX_ITEMS, mergeAll = player:GetAttribute("Pass_quick_merge") == true }
end

function ItemService.actions.mergeAll(player)
	if player:GetAttribute("Pass_quick_merge") ~= true then
		return fail("locked")
	end
	return ItemService.mergeAll(player)
end

function ItemService.start()
	changedRemote = Link.get(ReplicatedStorage, "Remotes", "RE_InventoryChanged", "RemoteEvent")
	purchasedEvent = Link.get(ServerStorage, "Bridge", Constants.BRIDGE.Purchased, "BindableEvent")
	task.spawn(function()
		while true do
			task.wait(TICK_SECONDS)
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
