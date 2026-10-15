local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Guard = require(script.Parent.Guard)
local GameService = require(script.Parent.GameService)
local PlayerState = require(script.Parent.PlayerState)
local BoostService = require(script.Parent.BoostService)
local Rewards = require(script.Parent.Rewards)
local QuestService = require(script.Parent.QuestService)
local ItemCatalog = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ItemCatalog"))

local SpinService = {}

local COOLDOWN = 20 * 3600
local random = Random.new()

local PRIZES = {
	m10 = { weight = 40, kind = "minutes", minutes = 10, label = "10 min", color = { 86, 156, 255 } },
	m30 = { weight = 25, kind = "minutes", minutes = 30, label = "30 min", color = { 94, 214, 130 } },
	h1 = { weight = 15, kind = "minutes", minutes = 60, label = "1 hour", color = { 255, 154, 72 } },
	lamp = { weight = 10, kind = "boost", seconds = 900, label = "Growth Lamp", color = { 255, 214, 80 } },
	h2 = { weight = 6, kind = "minutes", minutes = 120, label = "2 hours", color = { 176, 124, 255 } },
	voucher = { weight = 3.5, kind = "voucher", label = "Rare Item", color = { 47, 128, 237 } },
	dew = { weight = 0.5, kind = "dew", label = "Golden Dew", color = { 255, 61, 154 } },
}

local SEGMENTS = { "m10", "m30", "h1", "lamp", "m10", "m30", "h2", "voucher", "m10", "dew" }

local function data(player)
	return PlayerState.get(player, "spin", { nextAt = 0, count = 0 })
end

local function pickPrize()
	local total = 0
	for _, prize in PRIZES do
		total += prize.weight
	end
	local roll = random:NextNumber() * total
	for id, prize in PRIZES do
		roll -= prize.weight
		if roll <= 0 then
			return id
		end
	end
	return "m10"
end

function SpinService.snapshot(player)
	local spin = data(player)
	local segments = {}
	for index, id in SEGMENTS do
		local prize = PRIZES[id]
		table.insert(segments, { index = index, id = id, label = prize.label, color = prize.color })
	end
	local total = 0
	for _, prize in PRIZES do
		total += prize.weight
	end
	local odds = {}
	for id, prize in PRIZES do
		table.insert(odds, { id = id, label = prize.label, percent = prize.weight / total * 100 })
	end
	table.sort(odds, function(a, b)
		return a.percent > b.percent
	end)
	return {
		canSpin = os.time() >= spin.nextAt,
		nextAt = spin.nextAt,
		count = spin.count,
		segments = segments,
		odds = odds,
		now = os.time(),
	}
end

local function award(player, prizeId)
	local prize = PRIZES[prizeId]
	if not prize then
		return nil
	end
	local result = { title = "Lucky Wheel", label = prize.label }
	if prize.kind == "minutes" then
		result.money = Rewards.grantMinutes(player, prize.minutes, "spin")
	elseif prize.kind == "boost" then
		BoostService.add(player, "lamp", prize.seconds)
		result.boost = "Growth Lamp for 15 minutes"
	elseif prize.kind == "voucher" then
		local categories = ItemCatalog.CATEGORIES
		local category = categories[random:NextInteger(1, #categories)]
		Rewards.grantItem(player, category.id .. "_rare", { silent = true })
		result.item = category.id .. "_rare"
	else
		PlayerState.add(player, "catalysts", 1)
		result.boost = "Golden Dew: your next item to finish growing becomes special"
	end
	return result
end

local function collect(player)
	local prizeId = PlayerState.get(player, "spinPending", nil)
	if not prizeId then
		return nil
	end
	PlayerState.set(player, "spinPending", nil)
	local result = award(player, prizeId)
	if result then
		QuestService.event(player, "spin", 1)
		GameService.send(player, "reward", result)
	end
	return result
end

SpinService.actions = {}

function SpinService.actions.spin(player)
	if not Guard.allow(player, "Spin", 2) then
		return { ok = false, reason = "busy" }
	end
	if PlayerState.get(player, "spinPending", nil) then
		return { ok = false, reason = "busy" }
	end
	local spin = table.clone(data(player))
	local now = os.time()
	if now < spin.nextAt then
		return { ok = false, reason = "locked" }
	end
	local prizeId = pickPrize()
	local candidates = {}
	for index, id in SEGMENTS do
		if id == prizeId then
			table.insert(candidates, index)
		end
	end
	local segment = candidates[random:NextInteger(1, #candidates)]
	spin.nextAt = now + COOLDOWN
	spin.count += 1
	PlayerState.set(player, "spin", spin)
	PlayerState.set(player, "spinPending", prizeId)
	task.delay(10, function()
		if player.Parent then
			collect(player)
		end
	end)
	return { ok = true, segment = segment, prize = prizeId, nextAt = spin.nextAt }
end

function SpinService.actions.collect(player)
	return { ok = collect(player) ~= nil }
end

function SpinService.init(player)
	local dew = PlayerState.get(player, "catalysts", 0)
	player:SetAttribute("GoldenDew", dew)
	if PlayerState.get(player, "spinPending", nil) then
		task.delay(3, function()
			if player.Parent then
				collect(player)
			end
		end)
	end
end

function SpinService.start()
	PlayerState.Changed:Connect(function(player, key, value)
		if key == "catalysts" then
			player:SetAttribute("GoldenDew", value)
		end
	end)
end

return SpinService
