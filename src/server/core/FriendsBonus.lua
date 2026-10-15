local Players = game:GetService("Players")

local Guard = require(script.Parent.Guard)
local IncomeService = require(script.Parent.IncomeService)

local FriendsBonus = {}

local PER_FRIEND = 0.05
local MAX_FRIENDS = 5
local pairsCache = {}

local function friends(a, b)
	local key = a.UserId < b.UserId and (a.UserId .. ":" .. b.UserId) or (b.UserId .. ":" .. a.UserId)
	local cached = pairsCache[key]
	if cached ~= nil then
		return cached
	end
	local ok, result = pcall(a.IsFriendsWith, a, b.UserId)
	local value = ok and result == true
	if ok then
		pairsCache[key] = value
	end
	return value
end

local function refresh(player)
	if not Guard.isPlayer(player) then
		return
	end
	local count = 0
	for _, other in Players:GetPlayers() do
		if other ~= player and friends(player, other) then
			count += 1
		end
	end
	count = math.min(count, MAX_FRIENDS)
	if player:GetAttribute("FriendsCount") ~= count then
		player:SetAttribute("FriendsCount", count)
	end
	local bonus = count * PER_FRIEND
	if player:GetAttribute("FriendsBonus") ~= bonus then
		player:SetAttribute("FriendsBonus", bonus)
	end
end

local function refreshAll()
	for _, player in Players:GetPlayers() do
		task.spawn(refresh, player)
	end
end

function FriendsBonus.start()
	IncomeService.register("friends", function(player)
		return 1 + (tonumber(player:GetAttribute("FriendsBonus")) or 0)
	end)
	Players.PlayerAdded:Connect(function()
		task.delay(3, refreshAll)
	end)
	Players.PlayerRemoving:Connect(function(player)
		for key in pairsCache do
			if string.find(key, tostring(player.UserId), 1, true) then
				pairsCache[key] = nil
			end
		end
		task.delay(1, refreshAll)
	end)
	refreshAll()
end

return FriendsBonus
