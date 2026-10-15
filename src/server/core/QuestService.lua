local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Guard = require(script.Parent.Guard)
local Notify = require(script.Parent.Notify)
local Economy = require(script.Parent.Economy)
local GameService = require(script.Parent.GameService)
local PlayerState = require(script.Parent.PlayerState)
local ItemService = require(script.Parent.ItemService)
local UpgradeService = require(script.Parent.UpgradeService)
local CongregationService = require(script.Parent.CongregationService)
local Rewards = require(script.Parent.Rewards)
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Balance = require(Shared:WaitForChild("Balance"))
local Constants = require(Shared:WaitForChild("Constants"))
local QuestCatalog = require(Shared:WaitForChild("QuestCatalog"))

local QuestService = {}

local function entryFor(definition, mps)
	local goal = definition.goal
	if definition.kind == "earn" then
		goal = Balance.incomeMinutes(mps, definition.minutes)
	end
	return { id = definition.id, goal = goal, prog = 0, claimed = false }
end

local function pickFrom(random, list, avoid)
	local candidates = {}
	for _, quest in list do
		if not avoid[quest.kind] then
			table.insert(candidates, quest)
		end
	end
	if #candidates == 0 then
		candidates = list
	end
	return candidates[random:NextInteger(1, #candidates)]
end

local function generate(player, state, now)
	local mps = tonumber(player:GetAttribute("MoneyPerSecond")) or 0
	local dayId = QuestCatalog.dayId(now)
	local weekId = QuestCatalog.weekId(now)
	if state.day ~= dayId then
		local random = Random.new(player.UserId % 100000 * 1000 + dayId)
		local used = {}
		local list = {}
		for _, tierName in { "easy", "medium", "hard" } do
			local quest = pickFrom(random, QuestCatalog.daily[tierName], used)
			used[quest.kind] = true
			table.insert(list, entryFor(quest, mps))
		end
		state.day = dayId
		state.d = list
		state.dbonus = false
	end
	if state.week ~= weekId then
		local list = {}
		for _, quest in QuestCatalog.weekly do
			table.insert(list, entryFor(quest, mps))
		end
		state.week = weekId
		state.w = list
		state.wbonus = false
	end
end

local function stateOf(player)
	local saved = PlayerState.get(player, "quests", nil)
	if saved then
		return saved
	end
	return { day = 0, d = {}, dbonus = false, week = 0, w = {}, wbonus = false }
end

local function ensure(player)
	local state = table.clone(stateOf(player))
	local before = state.day .. ":" .. state.week
	generate(player, state, os.time())
	if before ~= state.day .. ":" .. state.week then
		PlayerState.set(player, "quests", state)
		GameService.push(player, "quests")
	end
	return state
end

local function claimEntry(player, state, scope, index, silent)
	local list = state[scope]
	local entry = list and list[index]
	if not entry or entry.claimed or entry.prog < entry.goal then
		return false
	end
	entry.claimed = true
	local minutes = scope == "d" and QuestCatalog.DAILY_REWARD_MINUTES or QuestCatalog.WEEKLY_REWARD_MINUTES
	local amount = Rewards.grantMinutes(player, minutes, "quest")
	local allDone = true
	for _, other in list do
		if not other.claimed then
			allDone = false
		end
	end
	local bonusKey = scope == "d" and "dbonus" or "wbonus"
	local bonusAmount, item
	if allDone and not state[bonusKey] then
		state[bonusKey] = true
		if scope == "d" then
			bonusAmount = Rewards.grantMinutes(player, QuestCatalog.DAILY_BONUS_MINUTES, "quest_bonus")
		else
			bonusAmount = Rewards.grantMinutes(player, QuestCatalog.WEEKLY_REWARD_MINUTES, "quest_bonus")
			item = QuestCatalog.WEEKLY_BONUS_ITEM
			Rewards.grantItem(player, item, { silent = true })
		end
	end
	if not silent then
		GameService.send(player, "reward", { title = scope == "d" and "Daily Quest" or "Weekly Goal", money = amount + (bonusAmount or 0), item = item })
	else
		Notify.send(player, "success", "Quest reward collected for you")
	end
	return true
end

function QuestService.event(player, kind, amount)
	if (player:GetAttribute("TutorialStep") or 0) < Constants.TUTORIAL.DONE then
		return
	end
	if not Guard.isNumber(amount) or amount <= 0 then
		return
	end
	local state = table.clone(stateOf(player))
	if not state.d or #state.d == 0 then
		state = ensure(player)
		state = table.clone(state)
	end
	local changed = false
	local auto = player:GetAttribute("Pass_helping_hands") == true
	for _, scope in { "d", "w" } do
		local list = {}
		for index, entry in state[scope] or {} do
			local copy = table.clone(entry)
			local definition = QuestCatalog.get(entry.id)
			if definition and definition.kind == kind and not copy.claimed and copy.prog < copy.goal then
				copy.prog = math.min(copy.goal, copy.prog + amount)
				changed = true
			end
			list[index] = copy
		end
		state[scope] = list
	end
	if changed then
		if auto then
			for _, scope in { "d", "w" } do
				for index, entry in state[scope] do
					if entry.prog >= entry.goal and not entry.claimed then
						claimEntry(player, state, scope, index, true)
					end
				end
			end
		end
		PlayerState.set(player, "quests", state)
		GameService.push(player, "quests")
	end
end

function QuestService.snapshot(player)
	local state = ensure(player)
	local function describe(list, scope)
		local out = {}
		for index, entry in list or {} do
			local definition = QuestCatalog.get(entry.id)
			table.insert(out, {
				index = index,
				text = definition and definition.text or entry.id,
				kind = definition and definition.kind or "arrive",
				goal = entry.goal,
				prog = entry.prog,
				claimed = entry.claimed,
				minutes = scope == "d" and QuestCatalog.DAILY_REWARD_MINUTES or QuestCatalog.WEEKLY_REWARD_MINUTES,
			})
		end
		return out
	end
	local now = os.time()
	return {
		daily = describe(state.d, "d"),
		weekly = describe(state.w, "w"),
		dailyBonus = state.dbonus,
		weeklyBonus = state.wbonus,
		dailyBonusMinutes = QuestCatalog.DAILY_BONUS_MINUTES,
		weeklyItem = QuestCatalog.WEEKLY_BONUS_ITEM,
		dayEnds = (QuestCatalog.dayId(now) + 1) * 86400,
		weekEnds = (QuestCatalog.weekId(now) * 7 - 3 + 7) * 86400,
	}
end

QuestService.actions = {}

function QuestService.actions.claim(player, payload)
	local scope = payload.scope
	local index = payload.index
	if (scope ~= "d" and scope ~= "w") or not Guard.isInteger(index, 1, 8) then
		return { ok = false, reason = "invalid" }
	end
	local state = table.clone(ensure(player))
	local list = {}
	for key, entry in state[scope] do
		list[key] = table.clone(entry)
	end
	state[scope] = list
	if not claimEntry(player, state, scope, index, false) then
		return { ok = false, reason = "locked" }
	end
	PlayerState.set(player, "quests", state)
	return { ok = true }
end

function QuestService.init(player)
	ensure(player)
end

function QuestService.start()
	CongregationService.Arrived:Connect(function(player)
		QuestService.event(player, "arrive", 1)
	end)
	ItemService.Bought:Connect(function(player, _, _, kind)
		if kind == "buy" then
			QuestService.event(player, "buy", 1)
		end
	end)
	ItemService.Merged:Connect(function(player)
		QuestService.event(player, "merge", 1)
	end)
	ItemService.Matured:Connect(function(player)
		QuestService.event(player, "mature", 1)
	end)
	UpgradeService.Changed:Connect(function(player, _, level)
		if level and level > 0 then
			QuestService.event(player, "upgrade", 1)
		end
	end)
	local buffer = {}
	Economy.Earned:Connect(function(player, amount, reason)
		if reason == "income" or reason == "tip" or reason == "offline" then
			buffer[player] = (buffer[player] or 0) + amount
		end
	end)
	task.spawn(function()
		while true do
			task.wait(5)
			for player, amount in buffer do
				buffer[player] = nil
				if player.Parent then
					QuestService.event(player, "earn", amount)
				end
			end
		end
	end)
end

return QuestService
