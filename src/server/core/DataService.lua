local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(script.Parent.Config)
local Guard = require(script.Parent.Guard)
local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))
local UpgradeCatalog = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("UpgradeCatalog"))
local OutfitCatalog = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("OutfitCatalog"))

local DataService = {}

local STORE_NAME = "GrowASyn_Core_v1"
local SCHEMA_VERSION = 1

local states = {}
local congregationProvider = nil
local upgradeProvider = nil
local cosmeticsProvider = nil
local progressProvider = nil
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
		upgrades = {},
		cosmetics = { outfit = OutfitCatalog.AUTO, style = "classic" },
		progress = { denomination = "", tier = 1 },
	}
end

local function cleanProgress(raw)
	local result = { denomination = "", tier = 1 }
	if type(raw) == "table" then
		if raw.denomination == "ashkenazi" then
			result.denomination = raw.denomination
		end
		if Guard.isInteger(raw.tier, 1, Constants.MAX_TIER) then
			result.tier = raw.tier
		end
	end
	return result
end

local function cleanCosmetics(raw)
	local result = { outfit = OutfitCatalog.AUTO, style = "classic" }
	if type(raw) == "table" then
		if OutfitCatalog.validSelection(raw.outfit) then
			result.outfit = raw.outfit
		end
		if OutfitCatalog.validStyle(raw.style) then
			result.style = raw.style
		end
	end
	return result
end

local function cleanUpgrades(raw)
	local result = {}
	for _, definition in UpgradeCatalog.list do
		local value = type(raw) == "table" and raw[definition.id] or 0
		if not Guard.isInteger(value, 0, definition.maxLevel) then
			value = 0
		end
		result[definition.id] = value
	end
	return result
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
	data.upgrades = cleanUpgrades(raw.upgrades)
	data.cosmetics = cleanCosmetics(raw.cosmetics)
	data.progress = cleanProgress(raw.progress)
	return data
end

local function snapshotOf(data)
	local levels = {}
	for _, definition in UpgradeCatalog.list do
		table.insert(levels, tostring(data.upgrades and data.upgrades[definition.id] or 0))
	end
	local cosmetics = data.cosmetics or {}
	local progress = data.progress or {}
	return string.format("%.2f|%d|%d|%d|%s|%s|%s|%s|%s", data.money, data.landTier, data.tutorialStep, data.congregation, table.concat(levels, ","), tostring(cosmetics.outfit), tostring(cosmetics.style), tostring(progress.denomination), tostring(progress.tier))
end

function DataService.setCongregationProvider(provider)
	congregationProvider = provider
end

function DataService.setUpgradeProvider(provider)
	upgradeProvider = provider
end

function DataService.setCosmeticsProvider(provider)
	cosmeticsProvider = provider
end

function DataService.setProgressProvider(provider)
	progressProvider = provider
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
		upgrades = cleanUpgrades(upgradeProvider and upgradeProvider(player) or nil),
		cosmetics = cleanCosmetics(cosmeticsProvider and cosmeticsProvider(player) or nil),
		progress = cleanProgress(progressProvider and progressProvider(player) or nil),
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
			return DataStoreService:GetDataStore(STORE_NAME):GetAsync(storeKey(player))
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
			DataStoreService:GetDataStore(STORE_NAME):UpdateAsync(storeKey(player), function(old)
				local merged = type(old) == "table" and old or {}
				merged.v = SCHEMA_VERSION
				merged.money = data.money
				merged.landTier = data.landTier
				merged.tutorialStep = data.tutorialStep
				merged.congregation = data.congregation
				merged.upgrades = data.upgrades
				merged.cosmetics = data.cosmetics
				merged.progress = data.progress
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
					DataService.save(player, false)
					pending -= 1
				end)
			end
		end
		local deadline = os.clock() + 25
		while os.clock() < deadline do
			local busy = pending > 0
			for _, state in states do
				if state.saving then
					busy = true
				end
			end
			if not busy then
				break
			end
			task.wait(0.1)
		end
	end)
end

return DataService
