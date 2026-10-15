local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Guard = require(script.Parent.Guard)
local Notify = require(script.Parent.Notify)
local GameService = require(script.Parent.GameService)
local PlayerState = require(script.Parent.PlayerState)
local Rewards = require(script.Parent.Rewards)
local Balance = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Balance"))

local DailyService = {}

local COOLDOWN = 20 * 3600
local WEEK_ITEM = "kiddush_cup_rare"

local function data(player)
	return PlayerState.get(player, "daily", { streak = 0, nextAt = 0, deadline = 0, freezes = 0, best = 0 })
end

local function maxFreezes(player)
	if player:GetAttribute("Pass_patron") == true then
		return Balance.DAILY_PATRON_FREEZES
	end
	return Balance.DAILY_MAX_FREEZES
end

local function evaluate(player)
	local daily = table.clone(data(player))
	local now = os.time()
	local note
	if daily.deadline > 0 and now > daily.deadline then
		if daily.freezes > 0 then
			daily.freezes -= 1
			note = "freeze"
		else
			daily.streak = math.max(0, daily.streak - Balance.DAILY_DROP)
			note = "drop"
		end
		daily.nextAt = now
		daily.deadline = now + Balance.DAILY_WINDOW
		PlayerState.set(player, "daily", daily)
	end
	return note
end

function DailyService.snapshot(player)
	local daily = data(player)
	local now = os.time()
	local cycleStart = math.floor(daily.streak / 7) * 7
	local today = daily.streak % 7 + 1
	local rewards = {}
	for index = 1, 7 do
		table.insert(rewards, {
			minutes = Balance.dailyMinutes(cycleStart + index),
			item = index == 7 and WEEK_ITEM or nil,
			freeze = index == 7,
		})
	end
	return {
		streak = daily.streak,
		best = daily.best,
		canClaim = now >= daily.nextAt,
		nextAt = daily.nextAt,
		deadline = daily.deadline,
		freezes = daily.freezes,
		maxFreezes = maxFreezes(player),
		today = today,
		rewards = rewards,
		now = now,
	}
end

DailyService.actions = {}

function DailyService.actions.claim(player)
	if not Guard.allow(player, "Daily", 1) then
		return { ok = false, reason = "busy" }
	end
	local daily = table.clone(data(player))
	local now = os.time()
	if now < daily.nextAt then
		return { ok = false, reason = "locked" }
	end
	daily.streak += 1
	daily.best = math.max(daily.best, daily.streak)
	daily.nextAt = now + COOLDOWN
	daily.deadline = now + Balance.DAILY_WINDOW
	local day = (daily.streak - 1) % 7 + 1
	local minutes = Balance.dailyMinutes(daily.streak)
	local gotFreeze = false
	if day == 7 and daily.freezes < maxFreezes(player) then
		daily.freezes += 1
		gotFreeze = true
	end
	PlayerState.set(player, "daily", daily)
	local amount = Rewards.grantMinutes(player, minutes, "daily")
	local item
	if day == 7 then
		item = WEEK_ITEM
		Rewards.grantItem(player, item, { silent = true })
	end
	Notify.send(player, "success", "Day " .. daily.streak .. " streak!")
	GameService.send(player, "reward", { title = "Daily Reward", money = amount, item = item, freeze = gotFreeze, streak = daily.streak })
	return { ok = true }
end

function DailyService.init(player)
	local note = evaluate(player)
	if note == "freeze" then
		Notify.send(player, "info", "A streak freeze protected your streak")
	elseif note == "drop" then
		Notify.send(player, "info", "Your streak slipped. Welcome back!")
	end
end

return DailyService
