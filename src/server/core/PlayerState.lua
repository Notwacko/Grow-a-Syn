local Guard = require(script.Parent.Guard)
local Signal = require(script.Parent.Signal)

local PlayerState = {}

PlayerState.Changed = Signal.new()

local states = {}
local serializeHooks = {}

function PlayerState.onSerialize(callback)
	table.insert(serializeHooks, callback)
end

local function clean(value, depth)
	local kind = type(value)
	if kind == "number" then
		if value ~= value or value == math.huge or value == -math.huge then
			return 0
		end
		return value
	elseif kind == "string" then
		return string.sub(value, 1, 200)
	elseif kind == "boolean" then
		return value
	elseif kind == "table" and depth < 4 then
		local copy = {}
		local count = 0
		for key, inner in value do
			count += 1
			if count > 400 then
				break
			end
			local keyType = type(key)
			if keyType == "string" or keyType == "number" then
				local cleaned = clean(inner, depth + 1)
				if cleaned ~= nil then
					copy[key] = cleaned
				end
			end
		end
		return copy
	end
	return nil
end

function PlayerState.init(player, saved)
	local data = {}
	if type(saved) == "table" then
		for key, value in saved do
			if type(key) == "string" and #key <= 40 then
				local cleaned = clean(value, 0)
				if cleaned ~= nil then
					data[key] = cleaned
				end
			end
		end
	end
	states[player] = data
end

function PlayerState.ready(player)
	return states[player] ~= nil
end

function PlayerState.get(player, key, default)
	local data = states[player]
	if not data then
		return default
	end
	local value = data[key]
	if value == nil then
		return default
	end
	return value
end

function PlayerState.set(player, key, value)
	local data = states[player]
	if not data or not Guard.isPlayer(player) then
		return
	end
	local cleaned = clean(value, 0)
	if data[key] ~= cleaned or type(cleaned) == "table" then
		data[key] = cleaned
		PlayerState.Changed:Fire(player, key, cleaned)
	end
end

function PlayerState.add(player, key, delta)
	local current = PlayerState.get(player, key, 0)
	if type(current) ~= "number" then
		current = 0
	end
	local value = current + delta
	PlayerState.set(player, key, value)
	return value
end

function PlayerState.serialize(player)
	local data = states[player]
	if not data then
		return {}
	end
	for _, hook in serializeHooks do
		pcall(hook, player)
	end
	return clean(data, 0) or {}
end

function PlayerState.forget(player)
	states[player] = nil
end

return PlayerState
