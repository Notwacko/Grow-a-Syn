local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local core = script.Parent

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))
local Guard = require(core.Guard)
local Notify = require(core.Notify)
local Economy = require(core.Economy)
local DataService = require(core.DataService)
local LightingService = require(core.LightingService)
local WorldService = require(core.WorldService)
local PlotService = require(core.PlotService)
local BuildingService = require(core.BuildingService)
local CongregationService = require(core.CongregationService)
local TutorialService = require(core.TutorialService)
local UpgradeService = require(core.UpgradeService)
local InteriorService = require(core.InteriorService)
local AmbientService = require(core.AmbientService)
local PlayerFx = require(core.PlayerFx)
local StarterGear = require(core.StarterGear)

Workspace:SetAttribute("CoreOnline", false)

LightingService.start()
WorldService.build()
PlotService.build()
AmbientService.start()
Economy.bind()
TutorialService.bind()
CongregationService.start()
InteriorService.start()
Economy.setBonusProvider(UpgradeService.bonusPerSecond)
CongregationService.setProviders({
	arrivalBonus = UpgradeService.arrivalBonus,
	tip = UpgradeService.tip,
})
DataService.setCongregationProvider(CongregationService.savedCount)
DataService.setUpgradeProvider(UpgradeService.serialize)
DataService.start()

PlotService.Claimed:Connect(function(player)
	BuildingService.refresh(player, true)
end)
PlotService.Claimed:Connect(CongregationService.onClaimed)
PlotService.Claimed:Connect(TutorialService.onClaimed)
PlotService.Released:Connect(function(player)
	InteriorService.clear(player)
	CongregationService.clear(player)
	BuildingService.remove(player)
end)
BuildingService.Swapped:Connect(CongregationService.onSwapped)
BuildingService.Swapped:Connect(InteriorService.onSwapped)
UpgradeService.Changed:Connect(InteriorService.onUpgradeChanged)
CongregationService.Greeted:Connect(TutorialService.onGreeted)

local function onPlayerAdded(player)
	Economy.initPlayer(player)
	player:SetAttribute("DataLoaded", false)
	PlotService.watch(player)
	BuildingService.watch(player)
	StarterGear.watch(player)
	PlayerFx.watch(player)

	local loaded, data = DataService.load(player)
	if player.Parent ~= Players then
		DataService.release(player)
		return
	end
	if loaded then
		Economy.applyData(player, data)
		player:SetAttribute("DataLoaded", true)
	else
		data = nil
		task.delay(5, function()
			Notify.send(player, "error", "Saving is offline. Progress will not be saved this session")
		end)
	end
	local returning = (player:GetAttribute("TutorialStep") or 0) >= Constants.TUTORIAL.GREET
	CongregationService.init(player, data and data.congregation or 0)
	UpgradeService.init(player, data and data.upgrades or nil)
	TutorialService.init(player)
	Economy.setActive(player, true)
	PlotService.markReady(player)
	if returning then
		PlotService.autoClaim(player)
	end
end

local function onPlayerRemoving(player)
	DataService.capture(player)
	TutorialService.forget(player)
	PlotService.release(player)
	PlotService.forget(player)
	BuildingService.forget(player)
	CongregationService.forget(player)
	UpgradeService.forget(player)
	PlayerFx.forget(player)
	Economy.release(player)
	DataService.save(player, false)
	DataService.release(player)
	Guard.release(player)
	Notify.release(player)
end

Players.PlayerAdded:Connect(function(player)
	task.spawn(onPlayerAdded, player)
end)
Players.PlayerRemoving:Connect(function(player)
	task.spawn(onPlayerRemoving, player)
end)
for _, player in Players:GetPlayers() do
	task.spawn(onPlayerAdded, player)
end

Workspace:SetAttribute("CoreOnline", true)
