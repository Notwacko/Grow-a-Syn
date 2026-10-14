local Players = game:GetService("Players")

local Guard = {}

local lastCall = {}
local strikes = {}

function Guard.isPlayer(value)
	return typeof(value) == "Instance" and value:IsA("Player") and value.Parent == Players
end

function Guard.isNumber(value)
	return type(value) == "number" and value == value and value ~= math.huge and value ~= -math.huge
end

function Guard.isInteger(value, min, max)
	if not Guard.isNumber(value) or value % 1 ~= 0 then
		return false
	end
	return value >= min and value <= max
end

function Guard.isString(value, maxLength)
	return type(value) == "string" and #value <= maxLength
end

function Guard.allow(player, key, interval)
	local now = os.clock()
	local bucket = lastCall[player]
	if not bucket then
		bucket = {}
		lastCall[player] = bucket
	end
	local last = bucket[key]
	if last and now - last < interval then
		return false
	end
	bucket[key] = now
	return true
end

function Guard.flag(player, reason, detail)
	local count = (strikes[player] or 0) + 1
	strikes[player] = count
	if count <= 5 or count % 25 == 0 then
		warn(string.format("[Guard] %s (%d) %s %s (strike %d)", player.Name, player.UserId, reason, detail or "", count))
	end
end

function Guard.strikes(player)
	return strikes[player] or 0
end

function Guard.release(player)
	lastCall[player] = nil
	strikes[player] = nil
end

function Guard.connect(remote, key, interval, handler)
	return remote.OnServerEvent:Connect(function(player, ...)
		if not Guard.isPlayer(player) then
			return
		end
		if not Guard.allow(player, key, interval) then
			Guard.flag(player, key, "rate limited")
			return
		end
		local ok, err = pcall(handler, player, ...)
		if not ok then
			warn(string.format("[Guard] handler %s failed: %s", key, tostring(err)))
		end
	end)
end

function Guard.nearPart(player, part, distance)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or not part or not part.Parent then
		return false
	end
	return (root.Position - part.Position).Magnitude <= distance
end

return Guard
