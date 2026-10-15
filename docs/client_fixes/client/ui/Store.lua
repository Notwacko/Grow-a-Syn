local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(script.Parent.Signal)

local Store = {}

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")

Store.player = player
Store.sections = {}
Store.events = Signal.new()
Store.sectionChanged = Signal.new()
Store.inventoryChanged = Signal.new()
Store.notify = Signal.new()
Store.minyan = Signal.new()
Store.ready = false

local gameFunction
local catalogCache
local inventoryCache

function Store.attr(name, default)
	local value = player:GetAttribute(name)
	if value == nil then
		return default
	end
	return value
end

function Store.onAttr(name, callback)
	local connection = player:GetAttributeChangedSignal(name):Connect(function()
		callback(player:GetAttribute(name))
	end)
	return function()
		connection:Disconnect()
	end
end

function Store.world(name, default)
	local value = workspace:GetAttribute(name)
	if value == nil then
		return default
	end
	return value
end

function Store.onWorld(name, callback)
	local connection = workspace:GetAttributeChangedSignal(name):Connect(function()
		callback(workspace:GetAttribute(name))
	end)
	return function()
		connection:Disconnect()
	end
end

function Store.now()
	return workspace:GetServerTimeNow()
end

function Store.get(section)
	return Store.sections[section]
end

function Store.on(section, callback)
	return Store.sectionChanged:connect(function(name, value)
		if name == section then
			callback(value)
		end
	end)
end

function Store.call(action, payload)
	if not gameFunction then
		return { ok = false, reason = "offline" }
	end
	local ok, result = pcall(gameFunction.InvokeServer, gameFunction, action, payload or {})
	if not ok or type(result) ~= "table" then
		return { ok = false, reason = "offline" }
	end
	return result
end

function Store.sync()
	local result = Store.call("sync")
	if result.ok and result.sections then
		for name, value in result.sections do
			Store.sections[name] = value
			Store.sectionChanged:fire(name, value)
		end
	end
	return result.ok
end

function Store.refreshCatalog()
	local rf = remotes:FindFirstChild("RF_GetCatalog")
	if not rf then
		return nil
	end
	local ok, result = pcall(rf.InvokeServer, rf)
	if ok and type(result) == "table" then
		catalogCache = result
	end
	return catalogCache
end

function Store.catalog()
	return catalogCache or Store.refreshCatalog()
end

function Store.refreshInventory(silent)
	local rf = remotes:FindFirstChild("RF_GetInventory")
	if not rf then
		return nil
	end
	local ok, result = pcall(rf.InvokeServer, rf)
	if ok and type(result) == "table" then
		inventoryCache = result
		if not silent then
			Store.inventoryChanged:fire(result)
		end
	end
	return inventoryCache
end

function Store.inventory()
	return inventoryCache or Store.refreshInventory()
end

function Store.remote(name, ...)
	local remote = remotes:FindFirstChild(name)
	if not remote then
		return { ok = false, reason = "offline" }
	end
	if remote:IsA("RemoteFunction") then
		local ok, result = pcall(remote.InvokeServer, remote, ...)
		if ok and type(result) == "table" then
			return result
		end
		return { ok = false, reason = "offline" }
	end
	remote:FireServer(...)
	return { ok = true }
end

function Store.init()
	gameFunction = remotes:WaitForChild("RF_Game", 20)
	local gameEvent = remotes:WaitForChild("RE_Game", 20)
	if gameEvent then
		gameEvent.OnClientEvent:Connect(function(kind, a, b)
			if kind == "section" then
				Store.sections[a] = b
				Store.sectionChanged:fire(a, b)
			else
				Store.events:fire(kind, a)
			end
		end)
	end
	local notify = remotes:WaitForChild("RE_Notify", 10)
	if notify then
		notify.OnClientEvent:Connect(function(kind, text)
			Store.notify:fire(kind, text)
		end)
	end
	local minyan = remotes:FindFirstChild("RE_MinyanReached")
	if minyan then
		minyan.OnClientEvent:Connect(function()
			Store.minyan:fire()
		end)
	end
	local changed = remotes:WaitForChild("RE_InventoryChanged", 10)
	if changed then
		changed.OnClientEvent:Connect(function()
			Store.refreshInventory()
		end)
	end
	local started = os.clock()
	while not player:GetAttribute("DataLoaded") do
		task.wait(0.2)
		if not player.Parent then
			return
		end
		if os.clock() - started > 30 then
			break
		end
	end
	Store.sync()
	Store.refreshCatalog()
	Store.refreshInventory()
	Store.ready = true
end

return Store
