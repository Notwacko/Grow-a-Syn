local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Link = require(script.Parent.Link)
local Guard = require(script.Parent.Guard)

local GameService = {}

local services = {}
local order = {}
local dirty = {}
local buckets = {}
local BUCKET_SIZE = 30
local BUCKET_REFILL = 20
local ACTION_INTERVAL = 0.12

local function takeToken(player)
	local now = os.clock()
	local bucket = buckets[player]
	if not bucket then
		bucket = { tokens = BUCKET_SIZE, at = now }
		buckets[player] = bucket
	end
	bucket.tokens = math.min(BUCKET_SIZE, bucket.tokens + (now - bucket.at) * BUCKET_REFILL)
	bucket.at = now
	if bucket.tokens < 1 then
		return false
	end
	bucket.tokens -= 1
	return true
end
local invoke
local event

local function fail(reason)
	return { ok = false, reason = reason }
end

function GameService.register(name, service)
	if not services[name] then
		table.insert(order, name)
	end
	services[name] = service
end

function GameService.get(name)
	return services[name]
end

local function snapshotOf(player, name)
	local service = services[name]
	if not service or not service.snapshot then
		return nil
	end
	local ok, value = pcall(service.snapshot, player)
	if not ok then
		warn("[Game] snapshot " .. name .. " failed: " .. tostring(value))
		return nil
	end
	return value
end

function GameService.push(player, name)
	if not Guard.isPlayer(player) then
		return
	end
	local bucket = dirty[player]
	if not bucket then
		bucket = {}
		dirty[player] = bucket
	end
	bucket[name] = true
end

function GameService.pushNow(player, name)
	if event and Guard.isPlayer(player) then
		local value = snapshotOf(player, name)
		if value ~= nil then
			event:FireClient(player, "section", name, value)
		end
	end
end

function GameService.send(player, kind, payload)
	if event and Guard.isPlayer(player) then
		event:FireClient(player, kind, payload)
	end
end

function GameService.initPlayer(player)
	for _, name in order do
		local service = services[name]
		if service and service.init then
			local ok, err = pcall(service.init, player)
			if not ok then
				warn("[Game] init " .. name .. " failed: " .. tostring(err))
			end
		end
	end
	for _, name in order do
		GameService.push(player, name)
	end
end

function GameService.forget(player)
	for _, name in order do
		local service = services[name]
		if service and service.forget then
			pcall(service.forget, player)
		end
	end
	dirty[player] = nil
	buckets[player] = nil
end

local function handle(player, action, payload)
	if not Guard.isPlayer(player) or not Guard.isString(action, 48) then
		return fail("invalid")
	end
	if payload ~= nil and type(payload) ~= "table" then
		return fail("invalid")
	end
	payload = payload or {}
	if not takeToken(player) then
		Guard.flag(player, "Game", "too many calls")
		return fail("busy")
	end
	if action == "sync" then
		local sections = {}
		for _, name in order do
			sections[name] = snapshotOf(player, name)
		end
		return { ok = true, sections = sections }
	end
	local serviceName, actionName = string.match(action, "^([%w_]+)%.([%w_]+)$")
	local service = serviceName and services[serviceName]
	local actionFunction = service and service.actions and service.actions[actionName]
	if not actionFunction then
		Guard.flag(player, "Game", "unknown action " .. action)
		return fail("invalid")
	end
	if not Guard.allow(player, "Game:" .. action, ACTION_INTERVAL) then
		return fail("busy")
	end
	local ok, result = pcall(actionFunction, player, payload)
	if not ok then
		warn("[Game] action " .. action .. " failed: " .. tostring(result))
		return fail("invalid")
	end
	GameService.push(player, serviceName)
	if type(result) ~= "table" then
		return { ok = result == true }
	end
	return result
end

function GameService.start()
	invoke = Link.get(ReplicatedStorage, "Remotes", "RF_Game", "RemoteFunction")
	event = Link.get(ReplicatedStorage, "Remotes", "RE_Game", "RemoteEvent")
	invoke.OnServerInvoke = handle
	task.spawn(function()
		while true do
			task.wait(0.25)
			for player, bucket in dirty do
				if player.Parent ~= Players then
					dirty[player] = nil
				else
					dirty[player] = nil
					for name in bucket do
						GameService.pushNow(player, name)
					end
				end
			end
		end
	end)
end

return GameService
