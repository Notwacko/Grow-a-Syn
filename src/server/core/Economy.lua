local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local Link = require(script.Parent.Link)
local Config = require(script.Parent.Config)
local Guard = require(script.Parent.Guard)
local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))

local Economy = {}

local active = {}
local pendingGrants = {}
local tickStarted = false

local function round2(value)
	return math.floor(value * 100 + 0.5) / 100
end

local function clampMoney(value)
	return round2(math.clamp(value, 0, Constants.MONEY_MAX))
end

local function readNumber(value, default)
	if Guard.isNumber(value) and value >= 0 then
		return value
	end
	return default
end

local function setAttribute(instance, name, value)
	if instance:GetAttribute(name) ~= value then
		instance:SetAttribute(name, value)
	end
end

function Economy.initPlayer(player)
	for name, value in Constants.CORE_ATTRIBUTES do
		player:SetAttribute(name, value)
	end
end

function Economy.applyData(player, data)
	player:SetAttribute("Money", clampMoney(data.money))
	player:SetAttribute("LandTier", math.clamp(data.landTier, 1, Constants.MAX_LAND_TIER))
	player:SetAttribute("TutorialStep", math.clamp(data.tutorialStep, 0, Constants.TUTORIAL.DONE))
	player:SetAttribute("HasMinyan", data.congregation >= Constants.MINYAN_SIZE)
end

function Economy.getMoney(player)
	return readNumber(player:GetAttribute("Money"), 0)
end

function Economy.spend(player, amount, reason)
	if not Guard.isPlayer(player) or not active[player] then
		return false
	end
	if not Guard.isNumber(amount) or amount < 0 or amount > Constants.MONEY_MAX then
		Guard.flag(player, "Spend", "bad amount " .. tostring(amount) .. " " .. tostring(reason))
		return false
	end
	local money = Economy.getMoney(player)
	if money < amount then
		return false
	end
	player:SetAttribute("Money", clampMoney(money - amount))
	return true
end

function Economy.grant(player, amount, reason)
	if not Guard.isPlayer(player) then
		return false
	end
	if not Guard.isNumber(amount) or amount < 0 or amount > Constants.MONEY_MAX then
		Guard.flag(player, "Grant", "bad amount " .. tostring(amount) .. " " .. tostring(reason))
		return false
	end
	if not active[player] then
		pendingGrants[player] = (pendingGrants[player] or 0) + amount
		return true
	end
	player:SetAttribute("Money", clampMoney(Economy.getMoney(player) + amount))
	return true
end

function Economy.setActive(player, value)
	active[player] = value or nil
	if value then
		local pending = pendingGrants[player]
		pendingGrants[player] = nil
		if pending and pending > 0 then
			player:SetAttribute("Money", clampMoney(Economy.getMoney(player) + pending))
		end
	end
end

function Economy.release(player)
	active[player] = nil
	pendingGrants[player] = nil
end

function Economy.setEventMult(value)
	if not Guard.isNumber(value) then
		return false
	end
	Workspace:SetAttribute("EventMult", math.clamp(value, 0, Config.EVENT_MULT_MAX))
	return true
end

function Economy.getEventMult()
	return readNumber(Workspace:GetAttribute("EventMult"), 1)
end

function Economy.incomePerSecond(player)
	if player:GetAttribute("HasMinyan") ~= true then
		return 0
	end
	local congregation = readNumber(player:GetAttribute("Congregation"), 0)
	local incomeMult = readNumber(player:GetAttribute("IncomeMult"), 1)
	local boostMult = readNumber(player:GetAttribute("BoostMult"), 1)
	local eventMult = Economy.getEventMult()
	return math.clamp(congregation * incomeMult * boostMult * eventMult, 0, 1e12)
end

local function tickPlayer(player, dt)
	local perSecond = Economy.incomePerSecond(player)
	setAttribute(player, "MoneyPerSecond", round2(perSecond))
	if perSecond > 0 then
		player:SetAttribute("Money", clampMoney(Economy.getMoney(player) + perSecond * dt))
	end
end

local function startTick()
	if tickStarted then
		return
	end
	tickStarted = true
	task.spawn(function()
		local last = os.clock()
		while true do
			task.wait(Config.INCOME_TICK)
			local now = os.clock()
			local dt = math.clamp(now - last, 0, 2)
			last = now
			for _, player in Players:GetPlayers() do
				if active[player] then
					local ok, err = pcall(tickPlayer, player, dt)
					if not ok then
						warn("[Economy] tick failed: " .. tostring(err))
					end
				end
			end
		end
	end)
end

function Economy.bind()
	Workspace:SetAttribute("EventMult", 1)
	local spend = Link.get(ServerStorage, "Bridge", Constants.BRIDGE.SpendMoney, "BindableFunction")
	local grant = Link.get(ServerStorage, "Bridge", Constants.BRIDGE.GrantMoney, "BindableEvent")
	spend.OnInvoke = function(player, amount, reason)
		return Economy.spend(player, amount, reason)
	end
	grant.Event:Connect(function(player, amount, reason)
		Economy.grant(player, amount, reason)
	end)
	startTick()
end

return Economy
