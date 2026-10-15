local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Balance = require(script.Parent.Balance)
local Catalog = require(script.Parent.Catalog)
local Link = require(script.Parent.Link)

local InventoryService = {}

local STORE_NAME = "GrowASyn_Progression_v1"
local MAX_RECEIPTS = 100
local LOCK_SECONDS = 150
local LOCK_WAITS = 6
local LOCK_WAIT_SECONDS = 5

local profiles = {}
local changedListeners = {}
local loadedListeners = {}
local store
local memoryOnly = false
local remoteChanged

local function key(player)
	return "Player_" .. player.UserId
end

local function defaultData()
	return {
		Items = {},
		Denomination = "",
		Tier = 1,
		NextUid = 1,
		Milestones = {},
		Receipts = {},
		ReceiptOrder = {},
		BoostMult = 1,
		BoostEndsAt = 0,
	}
end

local function sanitize(raw)
	local data = defaultData()
	if type(raw) ~= "table" then
		return data
	end
	if type(raw.NextUid) == "number" then
		data.NextUid = math.max(1, math.floor(raw.NextUid))
	end
	if type(raw.Denomination) == "string" and Catalog.denomination(raw.Denomination) then
		data.Denomination = raw.Denomination
	end
	if type(raw.Tier) == "number" then
		data.Tier = math.clamp(math.floor(raw.Tier), 1, Balance.MaxTier)
	end
	if data.Denomination == "" then
		data.Tier = 1
	elseif data.Tier < 2 then
		data.Tier = 2
	end
	local usedSlots = {}
	local usedUids = {}
	if type(raw.Items) == "table" then
		for _, item in ipairs(raw.Items) do
			if
				type(item) == "table"
				and type(item.uid) == "string"
				and not usedUids[item.uid]
				and Catalog.category(item.category)
				and Catalog.rarity(item.rarity)
			then
				usedUids[item.uid] = true
				local slot = nil
				if type(item.slot) == "string" and Catalog.isValidSlot(item.category, item.slot) and not usedSlots[item.slot] then
					slot = item.slot
					usedSlots[slot] = true
				end
				table.insert(data.Items, { uid = item.uid, category = item.category, rarity = item.rarity, slot = slot })
			end
		end
	end
	if type(raw.Milestones) == "table" then
		for k, v in pairs(raw.Milestones) do
			if type(k) == "string" and v == true then
				data.Milestones[k] = true
			end
		end
	end
	if type(raw.ReceiptOrder) == "table" then
		for _, id in ipairs(raw.ReceiptOrder) do
			if type(id) == "string" and not data.Receipts[id] then
				data.Receipts[id] = true
				table.insert(data.ReceiptOrder, id)
			end
		end
	end
	if type(raw.BoostMult) == "number" and type(raw.BoostEndsAt) == "number" and raw.BoostEndsAt > os.time() then
		data.BoostMult = raw.BoostMult
		data.BoostEndsAt = raw.BoostEndsAt
	end
	return data
end

local function serialize(data)
	local items = {}
	for _, item in ipairs(data.Items) do
		table.insert(items, { uid = item.uid, category = item.category, rarity = item.rarity, slot = item.slot })
	end
	local milestones = {}
	for k in pairs(data.Milestones) do
		milestones[k] = true
	end
	return {
		Items = items,
		Denomination = data.Denomination,
		Tier = data.Tier,
		NextUid = data.NextUid,
		Milestones = milestones,
		ReceiptOrder = table.clone(data.ReceiptOrder),
		BoostMult = data.BoostMult,
		BoostEndsAt = data.BoostEndsAt,
	}
end

local function isApiAccessError(err)
	local text = string.lower(tostring(err))
	return string.find(text, "api", 1, true) ~= nil or string.find(text, "publish", 1, true) ~= nil
end

local function writeAttributes(player, data)
	player:SetAttribute("Denomination", data.Denomination)
	player:SetAttribute("Tier", data.Tier)
	player:SetAttribute("BoostMult", data.BoostMult)
	player:SetAttribute("BoostEndsAt", data.BoostEndsAt)
end

local function claim(player, steal)
	local result, waiting = nil, false
	store:UpdateAsync(key(player), function(old)
		waiting = false
		if
			not steal
			and type(old) == "table"
			and type(old.ActiveJob) == "string"
			and old.ActiveJob ~= game.JobId
			and type(old.ActiveAt) == "number"
			and os.time() - old.ActiveAt < LOCK_SECONDS
		then
			waiting = true
			return nil
		end
		local data = type(old) == "table" and old or {}
		data.ActiveJob = game.JobId
		data.ActiveAt = os.time()
		result = data
		return data
	end)
	return result, waiting
end

local function load(player)
	local profile = { loaded = false, failed = false, data = nil, saving = false, released = false }
	profiles[player] = profile
	if memoryOnly then
		profile.data = defaultData()
		profile.loaded = true
		return profile
	end
	local attempt = 0
	local lockWaits = 0
	while attempt < Balance.LoadRetries and player.Parent do
		local ok, result, waiting = pcall(claim, player, lockWaits >= LOCK_WAITS)
		if ok and waiting then
			lockWaits += 1
			task.wait(LOCK_WAIT_SECONDS)
		elseif ok then
			profile.data = sanitize(result)
			profile.loaded = true
			return profile
		else
			attempt += 1
			warn("[Progression] load attempt " .. attempt .. " failed for " .. player.UserId .. ": " .. tostring(result))
			if RunService:IsStudio() and isApiAccessError(result) then
				memoryOnly = true
				warn("[Progression] Studio API access is off, progression runs in memory only")
				profile.data = defaultData()
				profile.loaded = true
				return profile
			end
			task.wait(attempt * 2)
		end
	end
	profile.failed = true
	return profile
end

function InventoryService.save(player, release)
	local profile = profiles[player]
	if not profile or not profile.loaded or profile.failed or profile.released then
		return false
	end
	if memoryOnly then
		return true
	end
	while profile.saving do
		task.wait(0.1)
	end
	if profile.released then
		return false
	end
	profile.saving = true
	local payload = serialize(profile.data)
	payload.ActiveJob = not release and game.JobId or nil
	payload.ActiveAt = os.time()
	local saved = false
	for attempt = 1, Balance.SaveRetries do
		local lost = false
		local ok, err = pcall(function()
			store:UpdateAsync(key(player), function(old)
				if type(old) == "table" and type(old.ActiveJob) == "string" and old.ActiveJob ~= game.JobId then
					lost = true
					return nil
				end
				return payload
			end)
		end)
		if ok then
			if lost then
				profile.released = true
				warn("[Progression] another server owns the data for " .. player.UserId .. ", not overwriting")
			else
				saved = true
				if release then
					profile.released = true
				end
			end
			break
		end
		warn("[Progression] save attempt " .. attempt .. " failed for " .. player.UserId .. ": " .. tostring(err))
		if attempt < Balance.SaveRetries then
			task.wait(attempt)
		end
	end
	profile.saving = false
	return saved
end

function InventoryService.get(player)
	local profile = profiles[player]
	if profile and profile.loaded and not profile.failed then
		return profile.data
	end
	return nil
end

function InventoryService.snapshot(player)
	local data = InventoryService.get(player)
	local items = {}
	if data then
		for _, item in ipairs(data.Items) do
			table.insert(items, { uid = item.uid, id = item.category .. "_" .. item.rarity, category = item.category, rarity = item.rarity, slot = item.slot })
		end
	end
	return {
		items = items,
		denomination = data and data.Denomination or "",
		tier = data and data.Tier or 1,
		maxTier = Balance.MaxTier,
	}
end

function InventoryService.find(player, uid)
	local data = InventoryService.get(player)
	if not data then
		return nil
	end
	for i, item in ipairs(data.Items) do
		if item.uid == uid then
			return item, i
		end
	end
	return nil
end

function InventoryService.equipped(player)
	local data = InventoryService.get(player)
	local list = {}
	if data then
		for _, item in ipairs(data.Items) do
			if item.slot then
				table.insert(list, item)
			end
		end
	end
	return list
end

function InventoryService.count(player, category)
	local data = InventoryService.get(player)
	local n = 0
	if data then
		for _, item in ipairs(data.Items) do
			if item.category == category then
				n += 1
			end
		end
	end
	return n
end

function InventoryService.hasRoom(player, amount)
	local data = InventoryService.get(player)
	return data ~= nil and #data.Items + (amount or 1) <= Balance.MaxItems
end

function InventoryService.addItem(player, category, rarity)
	local data = InventoryService.get(player)
	if not data or not Catalog.category(category) or not Catalog.rarity(rarity) then
		return nil
	end
	local item = { uid = "u" .. data.NextUid, category = category, rarity = rarity, slot = nil }
	data.NextUid += 1
	table.insert(data.Items, item)
	return item
end

function InventoryService.consumeForMerge(player, uids)
	local data = InventoryService.get(player)
	if not data then
		return false
	end
	local remove = {}
	for _, uid in ipairs(uids) do
		remove[uid] = true
	end
	local kept = {}
	for _, item in ipairs(data.Items) do
		if not remove[item.uid] then
			table.insert(kept, item)
		end
	end
	data.Items = kept
	return true
end

function InventoryService.setDenomination(player, id)
	local data = InventoryService.get(player)
	data.Denomination = id
	player:SetAttribute("Denomination", id)
end

function InventoryService.setTier(player, tier)
	local data = InventoryService.get(player)
	data.Tier = tier
	player:SetAttribute("Tier", tier)
end

function InventoryService.setBoost(player, mult, endsAt)
	local data = InventoryService.get(player)
	data.BoostMult = mult
	data.BoostEndsAt = endsAt
	player:SetAttribute("BoostMult", mult)
	player:SetAttribute("BoostEndsAt", endsAt)
end

function InventoryService.hasReceipt(player, purchaseId)
	local data = InventoryService.get(player)
	return data ~= nil and data.Receipts[purchaseId] == true
end

function InventoryService.addReceipt(player, purchaseId)
	local data = InventoryService.get(player)
	data.Receipts[purchaseId] = true
	table.insert(data.ReceiptOrder, purchaseId)
	while #data.ReceiptOrder > MAX_RECEIPTS do
		local old = table.remove(data.ReceiptOrder, 1)
		data.Receipts[old] = nil
	end
end

function InventoryService.changed(player)
	if not player.Parent or not InventoryService.get(player) then
		return
	end
	for _, fn in ipairs(changedListeners) do
		task.spawn(fn, player)
	end
	remoteChanged:FireClient(player, InventoryService.snapshot(player))
end

function InventoryService.onChanged(fn)
	table.insert(changedListeners, fn)
end

function InventoryService.onLoaded(fn)
	table.insert(loadedListeners, fn)
end

local function onPlayerAdded(player)
	player:SetAttribute("Denomination", "")
	player:SetAttribute("Tier", 1)
	player:SetAttribute("IncomeMult", 1)
	player:SetAttribute("WelcomeBonus", 0)
	player:SetAttribute("TorahCount", 0)
	player:SetAttribute("BoostMult", 1)
	player:SetAttribute("BoostEndsAt", 0)
	local profile = load(player)
	if not player.Parent then
		if profile.loaded then
			profiles[player] = profile
			InventoryService.save(player, true)
		end
		profiles[player] = nil
		return
	end
	if profile.failed then
		local notify = Link.get(ReplicatedStorage, "Remotes", "RE_Notify", "RemoteEvent")
		notify:FireClient(player, "error", "Could not load your items. Please rejoin.")
		return
	end
	writeAttributes(player, profile.data)
	for _, fn in ipairs(loadedListeners) do
		task.spawn(fn, player)
	end
	InventoryService.changed(player)
end

local function onPlayerRemoving(player)
	local profile = profiles[player]
	if profile and profile.loaded then
		InventoryService.save(player, true)
	end
	profiles[player] = nil
end

function InventoryService.init()
	remoteChanged = Link.get(ReplicatedStorage, "Remotes", "RE_InventoryChanged", "RemoteEvent")
	local getInventory = Link.get(ReplicatedStorage, "Remotes", "RF_GetInventory", "RemoteFunction")
	getInventory.OnServerInvoke = function(player)
		return InventoryService.snapshot(player)
	end

	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(STORE_NAME)
	end)
	if ok then
		store = result
	else
		memoryOnly = true
		warn("[Progression] DataStore unavailable, progression runs in memory only: " .. tostring(result))
	end

	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(onPlayerAdded, player)
	end

	task.spawn(function()
		while true do
			task.wait(Balance.AutosaveSeconds)
			for player in pairs(profiles) do
				task.spawn(InventoryService.save, player)
			end
		end
	end)

	game:BindToClose(function()
		local pending = 0
		for player in pairs(profiles) do
			pending += 1
			task.spawn(function()
				InventoryService.save(player, true)
				pending -= 1
			end)
		end
		local started = os.clock()
		while pending > 0 and os.clock() - started < 25 do
			task.wait(0.1)
		end
	end)
end

return InventoryService
