local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Guard = require(script.Parent.Guard)
local Notify = require(script.Parent.Notify)
local Economy = require(script.Parent.Economy)
local PlayerState = require(script.Parent.PlayerState)
local Balance = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Balance"))

local OfflineService = {}

local MAX_AWAY = 48 * 3600

local function patron(player)
	return player:GetAttribute("Pass_patron") == true
end

local function pending(player)
	return PlayerState.get(player, "offlinePending", nil)
end

function OfflineService.snapshot(player)
	local entry = pending(player)
	if not entry then
		return { amount = 0, seconds = 0 }
	end
	local amount, counted = Balance.offlineEarnings(entry.mps, entry.seconds, entry.tier, patron(player))
	return {
		amount = amount,
		seconds = counted,
		away = entry.seconds,
		patron = patron(player),
		capHours = Balance.offlineCapSeconds(entry.tier, patron(player)) / 3600,
	}
end

OfflineService.actions = {}

function OfflineService.actions.claim(player)
	if not Guard.allow(player, "Offline", 1) then
		return { ok = false, reason = "busy" }
	end
	local entry = pending(player)
	if not entry then
		return { ok = false, reason = "locked" }
	end
	local amount = Balance.offlineEarnings(entry.mps, entry.seconds, entry.tier, patron(player))
	PlayerState.set(player, "offlinePending", nil)
	if amount > 0 then
		Economy.grant(player, amount, "offline")
		Notify.send(player, "success", "Welcome back! Collected your earnings")
	end
	return { ok = true, amount = amount }
end

function OfflineService.init(player)
	local seen = PlayerState.get(player, "offlineSeen", 0)
	local mps = PlayerState.get(player, "offlineMps", 0)
	local tier = PlayerState.get(player, "offlineTier", 1)
	local now = os.time()
	if type(seen) == "number" and seen > 0 and mps > 0 then
		local away = math.clamp(now - seen, 0, MAX_AWAY)
		if away >= Balance.OFFLINE_MIN_SECONDS then
			local existing = pending(player)
			local seconds = away
			local best = mps
			if existing then
				seconds = math.min(existing.seconds + away, MAX_AWAY)
				best = math.max(existing.mps, mps)
			end
			PlayerState.set(player, "offlinePending", { seconds = seconds, mps = best, tier = tier })
		end
	end
end

function OfflineService.start()
	PlayerState.onSerialize(function(player)
		PlayerState.set(player, "offlineSeen", os.time())
		local mps = tonumber(player:GetAttribute("MoneyPerSecond")) or 0
		if mps > 0 then
			PlayerState.set(player, "offlineMps", mps)
		end
		PlayerState.set(player, "offlineTier", tonumber(player:GetAttribute("Tier")) or 1)
	end)
end

return OfflineService
