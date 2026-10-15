local Players = game:GetService("Players")

local Balance = require(script.Parent.Balance)

local Guard = {}

local locks = {}
local lastCall = {}

function Guard.run(player, key, fn, ...)
	local now = os.clock()
	local calls = lastCall[player]
	if not calls then
		calls = {}
		lastCall[player] = calls
	end
	if calls[key] and now - calls[key] < Balance.RemoteCooldown then
		return { ok = false, reason = "busy" }
	end
	calls[key] = now
	if locks[player] then
		return { ok = false, reason = "busy" }
	end
	locks[player] = true
	local success, result = pcall(fn, ...)
	locks[player] = nil
	if not success then
		warn("[Progression] " .. key .. " failed: " .. tostring(result))
		return { ok = false, reason = "invalid" }
	end
	if type(result) ~= "table" then
		return { ok = false, reason = "invalid" }
	end
	return result
end

function Guard.isString(v, maxLen)
	return type(v) == "string" and #v > 0 and #v <= (maxLen or 64)
end

Players.PlayerRemoving:Connect(function(player)
	locks[player] = nil
	lastCall[player] = nil
end)

return Guard
