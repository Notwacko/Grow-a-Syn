local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ItemService = require(script.Parent.ItemService)
local PlayerState = require(script.Parent.PlayerState)
local CollectionBook = require(script.Parent.CollectionBook)
local QuestCatalog = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("QuestCatalog"))

local LeaderboardService = {}

local WRITE_INTERVAL = 150
local READ_INTERVAL = 100
local TOP_COUNT = 10

local BOARDS = {
	{ id = "collectors", title = "Top Collectors", unit = "points" },
	{ id = "congregations", title = "Biggest Congregations", unit = "people" },
}

local cache = {}
local names = {}
local lastWrite = {}

local function weekKey(id)
	return "GrowASyn_Board_" .. id .. "_" .. QuestCatalog.weekId(os.time())
end

local function scoreOf(player, id)
	if id == "collectors" then
		local stars = 0
		for _, entry in ItemService.all(player) do
			stars += entry.star or 0
		end
		local found = 0
		local snapshot = CollectionBook.snapshot(player)
		found = #snapshot.found
		return found * 100 + stars * 20
	end
	return math.max(0, math.floor(tonumber(player:GetAttribute("Congregation")) or 0))
end

local function nameOf(userId)
	if names[userId] then
		return names[userId]
	end
	local player = Players:GetPlayerByUserId(userId)
	if player then
		names[userId] = player.DisplayName
		return names[userId]
	end
	local ok, name = pcall(Players.GetNameFromUserIdAsync, Players, userId)
	names[userId] = ok and name or "Player"
	return names[userId]
end

local function write(player)
	if not PlayerState.ready(player) or (player:GetAttribute("TutorialStep") or 0) < 6 then
		return
	end
	for _, board in BOARDS do
		local score = scoreOf(player, board.id)
		if score > 0 then
			pcall(function()
				DataStoreService:GetOrderedDataStore(weekKey(board.id)):SetAsync(tostring(player.UserId), score)
			end)
		end
	end
end

local function read()
	for _, board in BOARDS do
		local ok, pages = pcall(function()
			return DataStoreService:GetOrderedDataStore(weekKey(board.id)):GetSortedAsync(false, TOP_COUNT)
		end)
		if ok and pages then
			local ok2, page = pcall(function()
				return pages:GetCurrentPage()
			end)
			if ok2 then
				local entries = {}
				for rank, item in page do
					local userId = tonumber(item.key)
					if userId then
						table.insert(entries, { rank = rank, userId = userId, name = nameOf(userId), score = item.value })
					end
				end
				cache[board.id] = entries
			end
		end
	end
end

function LeaderboardService.snapshot(player)
	local boards = {}
	for _, board in BOARDS do
		table.insert(boards, {
			id = board.id,
			title = board.title,
			unit = board.unit,
			entries = cache[board.id] or {},
			mine = scoreOf(player, board.id),
		})
	end
	local weekId = QuestCatalog.weekId(os.time())
	return { boards = boards, resetsAt = (weekId * 7 - 3 + 7) * 86400, now = os.time() }
end

LeaderboardService.actions = {}

function LeaderboardService.actions.refresh()
	return { ok = true }
end

function LeaderboardService.start()
	task.spawn(function()
		while true do
			task.wait(WRITE_INTERVAL)
			for _, player in Players:GetPlayers() do
				local now = os.clock()
				if not lastWrite[player] or now - lastWrite[player] >= WRITE_INTERVAL - 1 then
					lastWrite[player] = now
					task.spawn(write, player)
					task.wait(1)
				end
			end
		end
	end)
	task.spawn(function()
		task.wait(8)
		while true do
			read()
			task.wait(READ_INTERVAL)
		end
	end)
end

return LeaderboardService
