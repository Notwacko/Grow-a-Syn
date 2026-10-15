local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local Guard = require(script.Parent.Guard)
local PlayerState = require(script.Parent.PlayerState)

local BoostService = {}

local KINDS = { lamp = true, festival = true }
local MAX_REMAINING = 6 * 3600
local LAMP_RATE = 2
local RAPID_RATE = 1.5
local HELPING_WELCOME = 0.5

local function hasPass(player, key)
	return player:GetAttribute("Pass_" .. key) == true
end

local function setIfChanged(player, name, value)
	if player:GetAttribute(name) ~= value then
		player:SetAttribute(name, value)
	end
end

function BoostService.refresh(player)
	if not Guard.isPlayer(player) then
		return
	end
	local boosts = PlayerState.get(player, "boosts", {})
	local now = os.time()
	local festivalEnds = boosts.festival or 0
	local lampEnds = boosts.lamp or 0
	local festival = festivalEnds > now
	local lamp = lampEnds > now
	local fallback = Workspace:GetAttribute("ProgressionOnline") ~= true
	local mult = 1
	if hasPass(player, "double_income") then
		mult += 1
	end
	if hasPass(player, "patron") then
		mult += 0.5
	end
	if festival then
		mult += 1
	end
	local rate = 1
	if hasPass(player, "rapid_growth") then
		rate *= RAPID_RATE
	end
	if lamp then
		rate *= LAMP_RATE
	end
	if fallback then
		setIfChanged(player, "BoostMult", mult)
		setIfChanged(player, "BoostEndsAt", festival and festivalEnds or 0)
		setIfChanged(player, "WelcomeBonus", hasPass(player, "helping_hands") and HELPING_WELCOME or 0)
	end
	setIfChanged(player, "GrowthRate", rate)
	setIfChanged(player, "GrowthEndsAt", lamp and lampEnds or 0)
end

function BoostService.add(player, kind, seconds)
	if not KINDS[kind] or not Guard.isNumber(seconds) or seconds <= 0 then
		return false
	end
	local boosts = table.clone(PlayerState.get(player, "boosts", {}))
	local now = os.time()
	boosts[kind] = math.min(math.max(boosts[kind] or 0, now) + seconds, now + MAX_REMAINING)
	PlayerState.set(player, "boosts", boosts)
	BoostService.refresh(player)
	return true
end

function BoostService.snapshot(player)
	local boosts = PlayerState.get(player, "boosts", {})
	return {
		festivalEnds = boosts.festival or 0,
		lampEnds = boosts.lamp or 0,
		mult = player:GetAttribute("BoostMult") or 1,
		rate = player:GetAttribute("GrowthRate") or 1,
	}
end

BoostService.actions = {}

function BoostService.init(player)
	BoostService.refresh(player)
end

function BoostService.start()
	task.spawn(function()
		while true do
			task.wait(1)
			for _, player in Players:GetPlayers() do
				BoostService.refresh(player)
			end
		end
	end)
end

return BoostService
