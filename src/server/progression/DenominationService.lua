local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Balance = require(script.Parent.Balance)
local Catalog = require(script.Parent.Catalog)
local Guard = require(script.Parent.Guard)
local InventoryService = require(script.Parent.InventoryService)
local Link = require(script.Parent.Link)

local DenominationService = {}

local notify

local function grantMilestone(player, milestone)
	local data = InventoryService.get(player)
	local rarity = Balance.TorahMilestones[milestone]
	if not data or not rarity or data.Milestones[milestone] then
		return
	end
	if not InventoryService.addItem(player, "torah", rarity) then
		return
	end
	data.Milestones[milestone] = true
	InventoryService.changed(player)
	notify:FireClient(player, "success", "You received a " .. Catalog.rarity(rarity).name .. " Sefer Torah!")
end

local function checkMinyan(player)
	if player:GetAttribute("HasMinyan") == true then
		grantMilestone(player, "minyan")
	end
end

function DenominationService.choose(player, denominationId)
	if not Guard.isString(denominationId) or not Catalog.denomination(denominationId) then
		return { ok = false, reason = "invalid" }
	end
	local data = InventoryService.get(player)
	if not data then
		return { ok = false, reason = "offline" }
	end
	if player:GetAttribute("HasMinyan") ~= true or data.Denomination ~= "" then
		return { ok = false, reason = "requirements_not_met" }
	end
	InventoryService.setDenomination(player, denominationId)
	InventoryService.setTier(player, 2)
	InventoryService.changed(player)
	grantMilestone(player, "tier2")
	return { ok = true }
end

function DenominationService.upgrade(player, expectedTier)
	local data = InventoryService.get(player)
	if not data then
		return { ok = false, reason = "offline" }
	end
	local newTier = data.Tier + 1
	if expectedTier and expectedTier ~= newTier then
		return { ok = false, reason = "requirements_not_met" }
	end
	if data.Denomination == "" or newTier > Balance.MaxTier then
		return { ok = false, reason = "requirements_not_met" }
	end
	if (player:GetAttribute("LandTier") or 1) < newTier - 1 then
		return { ok = false, reason = "requirements_not_met" }
	end
	local cost = Balance.UpgradeCost[newTier]
	if cost > 0 then
		if workspace:GetAttribute("CoreOnline") ~= true then
			return { ok = false, reason = "offline" }
		end
		if (player:GetAttribute("Money") or 0) < cost then
			return { ok = false, reason = "not_enough_money" }
		end
		local spend = Link.get(ServerStorage, "Bridge", "SpendMoney", "BindableFunction")
		local paid = spend:Invoke(player, cost, "building_t" .. newTier)
		if paid ~= true then
			return { ok = false, reason = "not_enough_money" }
		end
		if not InventoryService.get(player) then
			return { ok = false, reason = "offline" }
		end
	end
	InventoryService.setTier(player, newTier)
	InventoryService.changed(player)
	grantMilestone(player, "tier" .. newTier)
	return { ok = true }
end

local function watchPlayer(player)
	player:GetAttributeChangedSignal("HasMinyan"):Connect(function()
		checkMinyan(player)
	end)
end

function DenominationService.init()
	notify = Link.get(ReplicatedStorage, "Remotes", "RE_Notify", "RemoteEvent")

	local chooseRemote = Link.get(ReplicatedStorage, "Remotes", "RF_ChooseDenomination", "RemoteFunction")
	chooseRemote.OnServerInvoke = function(player, denominationId)
		return Guard.run(player, "choose", DenominationService.choose, player, denominationId)
	end

	local upgradeRemote = Link.get(ReplicatedStorage, "Remotes", "RF_UpgradeBuilding", "RemoteFunction")
	upgradeRemote.OnServerInvoke = function(player)
		return Guard.run(player, "upgrade", DenominationService.upgrade, player, nil)
	end

	Players.PlayerAdded:Connect(watchPlayer)
	for _, player in ipairs(Players:GetPlayers()) do
		watchPlayer(player)
	end
	InventoryService.onLoaded(checkMinyan)
end

return DenominationService
