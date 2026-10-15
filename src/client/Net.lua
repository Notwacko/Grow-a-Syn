-- The only module that talks to remotes. Falls back to a mock (canned data + local attributes) when the
-- server's RF_GetCatalog does not appear within 10 seconds, so the whole UI can be tested alone.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Contract = require(script.Parent.Contract)

local player = Players.LocalPlayer

local function newSignal()
	local signal = { handlers = {} }
	function signal:connect(fn)
		table.insert(self.handlers, fn)
		return {
			Disconnect = function()
				local i = table.find(self.handlers, fn)
				if i then
					table.remove(self.handlers, i)
				end
			end,
		}
	end
	function signal:fire(...)
		for _, fn in table.clone(self.handlers) do
			task.spawn(fn, ...)
		end
	end
	return signal
end

local Net = {
	isMock = false,
	Notified = newSignal(), -- (kind, text)
	MinyanReached = newSignal(),
	InventoryChanged = newSignal(),
}

local remotes = {}
local catalog, inventory
local mock -- set in mock mode

-- ASSUMED result forms: true | false, reason | {ok=bool, reason=string, ...}
local function interpret(ok, a, b)
	if not ok then
		return { ok = false, reason = "offline" }
	end
	if type(a) == "table" then
		if a.ok ~= nil then
			return a
		end
		return { ok = true, data = a }
	end
	if a == true then
		return { ok = true, data = b }
	end
	return { ok = false, reason = type(b) == "string" and b or (type(a) == "string" and a or "invalid") }
end

local function invoke(name, ...)
	local rf = remotes[name]
	if not rf then
		return { ok = false, reason = "offline" }
	end
	return interpret(pcall(function(...)
		return rf:InvokeServer(...)
	end, ...))
end

local function fire(name, ...)
	local re = remotes[name]
	if re then
		re:FireServer(...)
	end
end

local function normalizeCatalog(raw)
	raw = type(raw) == "table" and raw or {}
	if raw.ok and raw.data then
		raw = raw.data
	end
	for _, key in { "items", "buildings", "packs", "boosts", "denominations" } do
		raw[key] = raw[key] or {}
	end
	raw.byId = {}
	for _, key in { "items", "buildings", "packs", "boosts" } do
		for _, entry in raw[key] do
			raw.byId[entry.id] = entry
		end
	end
	raw.denById = {}
	for _, den in raw.denominations do
		raw.denById[den.id] = den
	end
	return raw
end

local function bindReal(folder)
	for _, name in Contract.Events do
		remotes[name] = folder:WaitForChild(name, 5)
	end
	for _, name in Contract.Functions do
		remotes[name] = folder:WaitForChild(name, 5)
	end
	local notify = remotes[Contract.Events.Notify]
	if notify then
		notify.OnClientEvent:Connect(function(kind, text)
			Net.Notified:fire(kind, text)
		end)
	end
	local minyan = remotes[Contract.Events.MinyanReached]
	if minyan then
		minyan.OnClientEvent:Connect(function()
			Net.MinyanReached:fire()
		end)
	end
	local changed = remotes[Contract.Events.InventoryChanged]
	if changed then
		changed.OnClientEvent:Connect(function()
			inventory = nil
			Net.InventoryChanged:fire()
		end)
	end
end

function Net.init()
	if Net.ready then
		return
	end
	local folder = ReplicatedStorage:FindFirstChild(Contract.REMOTES_FOLDER)
		or ReplicatedStorage:WaitForChild(Contract.REMOTES_FOLDER, 10)
	local getCatalog = folder and (folder:FindFirstChild(Contract.Functions.GetCatalog) or folder:WaitForChild(Contract.Functions.GetCatalog, 10))
	if folder and getCatalog then
		bindReal(folder)
	else
		Net.isMock = true
		mock = require(script.Parent.MockNet)(Net, newSignal)
	end
	Net.ready = true
end

function Net.getCatalog()
	if catalog then
		return catalog
	end
	if Net.isMock then
		catalog = normalizeCatalog(mock.catalog())
	else
		local res = invoke(Contract.Functions.GetCatalog)
		catalog = normalizeCatalog(res.ok and (res.data or res) or nil)
	end
	return catalog
end

function Net.getInventory()
	if inventory then
		return inventory
	end
	if Net.isMock then
		inventory = mock.inventory()
	else
		local res = invoke(Contract.Functions.GetInventory)
		local list = res.ok and (res.data or res.items) or {}
		inventory = type(list) == "table" and (list.items or list) or {}
	end
	return inventory
end

local function afterChange(res)
	if res.ok then
		inventory = nil
		Net.InventoryChanged:fire()
	end
	return res
end

function Net.buy(offerId)
	if Net.isMock then
		return afterChange(mock.buy(offerId))
	end
	return afterChange(invoke(Contract.Functions.Buy, offerId))
end

function Net.merge(uids)
	if Net.isMock then
		return afterChange(mock.merge(uids))
	end
	return afterChange(invoke(Contract.Functions.Merge, table.unpack(uids)))
end

function Net.equip(uid, slot)
	if Net.isMock then
		return afterChange(mock.equip(uid, slot))
	end
	return afterChange(invoke(Contract.Functions.Equip, uid, slot))
end

function Net.unequip(uid)
	if Net.isMock then
		return afterChange(mock.unequip(uid))
	end
	return afterChange(invoke(Contract.Functions.Unequip, uid))
end

function Net.chooseDenomination(id)
	if Net.isMock then
		return mock.chooseDenomination(id)
	end
	return invoke(Contract.Functions.ChooseDenomination, id)
end

function Net.upgradeBuilding()
	if Net.isMock then
		return mock.upgradeBuilding()
	end
	return invoke(Contract.Functions.UpgradeBuilding)
end

function Net.expandLand()
	if Net.isMock then
		return mock.expandLand()
	end
	fire(Contract.Events.ExpandLand)
	return { ok = true }
end

function Net.advanceTutorial()
	if Net.isMock then
		mock.advanceTutorial()
		return
	end
	fire(Contract.Events.AdvanceTutorial)
end

function Net.attr(name, default)
	local value = player:GetAttribute(name)
	if value == nil then
		return default
	end
	return value
end

function Net.onAttr(name, callback)
	return player:GetAttributeChangedSignal(name):Connect(function()
		callback(player:GetAttribute(name))
	end)
end

return Net
