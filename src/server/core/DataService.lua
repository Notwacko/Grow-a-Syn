local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(script.Parent.Config)
local Guard = require(script.Parent.Guard)
local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))

local DataService = {}

local STORE_NAME = "GrowASyn_Core_v1"
local SCHEMA_VERSION = 1

local store = DataStoreService:GetDataStore(STORE_NAME)
local states = {}
local congregationProvider = nil
local warnedOffline = false

local function storeKey(player)
	return "Player_" .. player.UserId
end

local function defaultData()
	return {
		money = Constants.START_MONEY,
		landTier = 1,
		tutorialStep = 0,
		congregation = 0,
	}
end

local function sanitize(raw)
	local data = defaultData()
	if type(raw) ~= "table" then
		return data
	end
	if Guard.isNumber(raw.money) then
		data.money = math.clamp(raw.money, 0, Constants.MONEY_MAX)
	end
	if Guard.isInteger(raw.landTier, 1, Constants.MAX_LAND_TIER) then
		data.landTier = raw.landTier
	end
	if Guard.isInteger(raw.tutorialStep, 0, Constants.TUTORIAL.DONE) then
		data.tutorialStep = raw.tutorialStep
	end
	if Guard.isInteger(raw.congregation, 0, Constants.SEATS_PER_TIER[Constants.MAX_TIER]) then
		data.congregation = raw.congregation
	end
	if data.tutorialStep < Constants.TUTORIAL.BUY then
		data.congregation = 0
	end
	return data
end

local function snapshotOf(data)
	return string.format("%.2f|%d|%d|%d", data.money, data.landTier, data.tutorialStep, data.congregation)
end

function DataService.setCongregationProvider(provider)
	congregationProvider = provider
end

function DataService.collect(player)
	local congregation = player:GetAttribute("Congregation")
	if congregationProvider then
		local ok, value = pcall(congregationProvider, player)
		if ok and Guard.isNumber(value) then
			congregation = value
		end
	end
	return {
		money = math.floor((tonumber(player:GetAttribute("Money")) or 0) * 100 + 0.5) / 100,
		landTier = tonumber(player:GetAttribute("LandTier")) or 1,
		tutorialStep = tonumber(player:GetAttribute("TutorialStep")) or 0,
		congregation = math.floor(tonumber(congregation) or 0),
	}
end

function DataService.isLoaded(player)
	local state = states[player]
	return state ~= nil and state.loaded
end

function DataService.load(player)
	local state = { loaded = false, saving = false, snapshot = nil, final = nil }
	states[player] = state
	local success, result
	for attempt = 1, Config.LOAD_RETRIES do
		success, result = pcall(function()
			return store:GetAsync(storeKey(player))
		end)
		if success then
			break
		end
		warn(string.format("[Data] load attempt %d failed for %s: %s", attempt, player.Name, tostring(result)))
		if attempt < Config.LOAD_RETRIES then
			task.wait(attempt * 1.5)
		end
	end
	if not success then
		if not warnedOffline then
			warnedOffline = true
			warn("[Data] DataStore unavailable. In Studio enable Game Settings > Security > Enable Studio Access to API Services.")
		end
		return false, nil
	end
	local data = sanitize(result)
	state.loaded = true
	state.snapshot = snapshotOf(data)
	return true, data
end

function DataService.capture(player)
	local state = states[player]
	if state and state.loaded then
		state.final = DataService.collect(player)
	end
end

function DataService.save(player, force)
	local state = states[player]
	if not state or not state.loaded then
		return false
	end
	while state.saving do
		task.wait(0.1)
	end
	local data = state.final or DataService.collect(player)
	local snapshot = snapshotOf(data)
	if not force and snapshot == state.snapshot then
		return true
	end
	state.saving = true
	local saved = false
	for attempt = 1, Config.SAVE_RETRIES do
		local ok, err = pcall(function()
			store:UpdateAsync(storeKey(player), function(old)
				local merged = type(old) == "table" and old or {}
				merged.v = SCHEMA_VERSION
				merged.money = data.money
				merged.landTier = data.landTier
				merged.tutorialStep = data.tutorialStep
				merged.congregation = data.congregation
				merged.savedAt = os.time()
				return merged
			end)
		end)
		if ok then
			saved = true
			break
		end
		warn(string.format("[Data] save attempt %d failed for %s: %s", attempt, player.Name, tostring(err)))
		if attempt < Config.SAVE_RETRIES then
			task.wait(attempt * 1.5)
		end
	end
	state.saving = false
	if saved then
		state.snapshot = snapshot
	end
	return saved
end

function DataService.release(player)
	states[player] = nil
end

function DataService.start()
	task.spawn(function()
		while true do
			task.wait(Config.AUTOSAVE_INTERVAL)
			for _, player in Players:GetPlayers() do
				if DataService.isLoaded(player) then
					task.spawn(DataService.save, player, false)
					task.wait(0.3)
				end
			end
		end
	end)
	game:BindToClose(function()
		local pending = 0
		for _, player in Players:GetPlayers() do
			if DataService.isLoaded(player) then
				pending += 1
				task.spawn(function()
					DataService.save(player, true)
					pending -= 1
				end)
			end
		end
		local deadline = os.clock() + 25
		while pending > 0 and os.clock() < deadline do
			task.wait(0.1)
		end
	end)
end

return DataService
