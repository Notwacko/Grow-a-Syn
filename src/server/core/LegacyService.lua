local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Guard = require(script.Parent.Guard)
local Notify = require(script.Parent.Notify)
local Economy = require(script.Parent.Economy)
local GameService = require(script.Parent.GameService)
local PlayerState = require(script.Parent.PlayerState)
local ItemService = require(script.Parent.ItemService)
local UpgradeService = require(script.Parent.UpgradeService)
local CongregationService = require(script.Parent.CongregationService)
local ProgressionFallback = require(script.Parent.ProgressionFallback)
local DataService = require(script.Parent.DataService)
local IncomeService = require(script.Parent.IncomeService)
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Balance = require(Shared:WaitForChild("Balance"))
local ItemCatalog = require(Shared:WaitForChild("ItemCatalog"))
local Constants = require(Shared:WaitForChild("Constants"))

local LegacyService = {}

local BOOST_FACTOR = 1.25
local runEarned = {}

local function data(player)
	return PlayerState.get(player, "legacy", { points = 0, resets = 0, lifetime = 0 })
end

local function computeGain(player)
	local legacy = data(player)
	local run = runEarned[player] or 0
	local total = Balance.legacyPoints(legacy.lifetime + run)
	local gain = math.max(0, total - legacy.points)
	if gain > 0 and PlayerState.get(player, "legacyBoost", false) == true then
		gain = math.floor(gain * BOOST_FACTOR)
	end
	return gain, run
end

function LegacyService.points(player)
	return data(player).points
end

function LegacyService.mult(player)
	return Balance.legacyMult(data(player).points)
end

function LegacyService.snapshot(player)
	local legacy = data(player)
	local gain, run = computeGain(player)
	local tier = tonumber(player:GetAttribute("Tier")) or 1
	return {
		unlocked = tier >= Balance.LEGACY_UNLOCK_TIER,
		unlockTier = Balance.LEGACY_UNLOCK_TIER,
		points = legacy.points,
		resets = legacy.resets,
		mult = Balance.legacyMult(legacy.points),
		nextMult = Balance.legacyMult(legacy.points + gain),
		gain = gain,
		run = run,
		boost = PlayerState.get(player, "legacyBoost", false) == true,
		heirloomSlots = Balance.heirloomSlots(legacy.points + gain),
		startMoney = Constants.START_MONEY + (legacy.points + gain) * Balance.LEGACY_START_MONEY_PER_POINT,
		nextPointAt = Balance.LEGACY_POINT_UNIT * ((legacy.points + gain + 1) / Balance.LEGACY_POINT_SCALE) ^ 2,
	}
end

LegacyService.actions = {}

function LegacyService.actions.info()
	return { ok = true }
end

function LegacyService.actions.confirm(player, payload)
	if not Guard.allow(player, "Legacy", 3) then
		return { ok = false, reason = "busy" }
	end
	local tier = tonumber(player:GetAttribute("Tier")) or 1
	if tier < Balance.LEGACY_UNLOCK_TIER then
		return { ok = false, reason = "locked" }
	end
	local gain = computeGain(player)
	if gain < 1 then
		Notify.send(player, "info", "Earn a little more before your Legacy")
		return { ok = false, reason = "requirements_not_met" }
	end
	local legacy = data(player)
	local slots = Balance.heirloomSlots(legacy.points + gain)
	local keep = {}
	local picked = 0
	if type(payload.keep) == "table" then
		local owned = {}
		for _, entry in ItemService.all(player) do
			owned[entry.uid] = entry
		end
		for _, uid in payload.keep do
			if picked >= slots then
				break
			end
			if Guard.isString(uid, 24) and owned[uid] and not keep[uid] then
				local info = ItemCatalog.item(owned[uid].id)
				if info and info.category ~= "torah" then
					keep[uid] = true
					picked += 1
				end
			end
		end
	end
	local run = runEarned[player] or 0
	local newPoints = legacy.points + gain
	CongregationService.reset(player)
	ItemService.resetForLegacy(player, keep)
	UpgradeService.reset(player)
	runEarned[player] = 0
	PlayerState.set(player, "legacy", {
		points = newPoints,
		resets = legacy.resets + 1,
		lifetime = legacy.lifetime + run,
	})
	PlayerState.set(player, "legacyBoost", false)
	Economy.setMoney(player, Constants.START_MONEY + newPoints * Balance.LEGACY_START_MONEY_PER_POINT)
	player:SetAttribute("LandTier", 1)
	ProgressionFallback.resetTier(player)
	IncomeService.refresh(player)
	Notify.send(player, "success", "Your Legacy begins anew!")
	GameService.send(player, "legacy_done", { gain = gain, points = newPoints, mult = Balance.legacyMult(newPoints), resets = legacy.resets + 1 })
	task.spawn(DataService.save, player, true)
	return { ok = true }
end

function LegacyService.init(player)
	local saved = PlayerState.get(player, "legacyRun", 0)
	runEarned[player] = type(saved) == "number" and saved or 0
end

function LegacyService.forget(player)
	runEarned[player] = nil
end

function LegacyService.start()
	Economy.Earned:Connect(function(player, amount, reason)
		if runEarned[player] ~= nil then
			runEarned[player] += amount
		end
	end)
	PlayerState.onSerialize(function(player)
		if runEarned[player] ~= nil then
			PlayerState.set(player, "legacyRun", runEarned[player])
		end
	end)
	IncomeService.register("legacy", function(player)
		return LegacyService.mult(player)
	end)
end

return LegacyService
