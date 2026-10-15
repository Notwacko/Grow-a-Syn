local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Link = require(script.Parent.Link)
local Guard = require(script.Parent.Guard)
local Notify = require(script.Parent.Notify)
local Economy = require(script.Parent.Economy)
local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))

local ProgressionFallback = {}

local STAGES = {
	"Ashkenazi Reform",
	"Ashkenazi Conservative",
	"Ashkenazi Orthodox",
	"Ashkenazi Ultra Orthodox",
	"Ashkenazi Hasidic",
	"Ashkenazi Haredi",
}

local DENOMINATIONS = {
	{
		id = "ashkenazi",
		name = "Ashkenazi",
		blurb = "Warm, choir-filled services and a classic hall.",
		model = "ashkenazi_T2",
		stages = STAGES,
	},
}

local TIER_COST = { [2] = 2500, [3] = 10000, [4] = 40000, [5] = 150000, [6] = 600000, [7] = 2500000 }
local INCOME_MULT = { 1, 1.5, 2, 3, 4.5, 6.5, 10 }

local REMOTES = {
	RF_GetCatalog = "RemoteFunction",
	RF_GetInventory = "RemoteFunction",
	RF_Buy = "RemoteFunction",
	RF_Merge = "RemoteFunction",
	RF_Equip = "RemoteFunction",
	RF_Unequip = "RemoteFunction",
	RF_ChooseDenomination = "RemoteFunction",
	RF_UpgradeBuilding = "RemoteFunction",
	RE_InventoryChanged = "RemoteEvent",
}

local function active()
	return Workspace:GetAttribute("ProgressionOnline") ~= true
end

local function known(id)
	for _, den in DENOMINATIONS do
		if den.id == id then
			return true
		end
	end
	return false
end

local function tierOf(player)
	return math.clamp(math.floor(tonumber(player:GetAttribute("Tier")) or 1), 1, Constants.MAX_TIER)
end

local function fail(reason)
	return { ok = false, reason = reason }
end

local function catalog()
	local upgrades = {}
	for tier = 2, Constants.MAX_TIER do
		upgrades[tier] = { cost = TIER_COST[tier], requirement = "Needs land tier " .. (tier - 1) }
	end
	return {
		items = {},
		buildings = {},
		packs = {},
		boosts = {},
		denominations = DENOMINATIONS,
		upgrades = upgrades,
	}
end

local function setTier(player, tier)
	player:SetAttribute("Tier", tier)
	player:SetAttribute("IncomeMult", INCOME_MULT[tier] or 1)
end

local function chooseDenomination(player, id)
	if not active() then
		return fail("busy")
	end
	if not Guard.isPlayer(player) or not Guard.isString(id, 32) or not known(id) then
		return fail("invalid")
	end
	if not Guard.allow(player, "Progression", 0.5) then
		return fail("busy")
	end
	local current = player:GetAttribute("Denomination")
	if type(current) == "string" and current ~= "" then
		return fail("locked")
	end
	if player:GetAttribute("HasMinyan") ~= true then
		return fail("requirements_not_met")
	end
	player:SetAttribute("Denomination", id)
	setTier(player, 2)
	Notify.send(player, "success", "Welcome to the " .. STAGES[1] .. " stage!")
	return { ok = true }
end

local function upgradeBuilding(player)
	if not active() then
		return fail("busy")
	end
	if not Guard.isPlayer(player) then
		return fail("invalid")
	end
	if not Guard.allow(player, "Progression", 0.5) then
		return fail("busy")
	end
	local denomination = player:GetAttribute("Denomination")
	if type(denomination) ~= "string" or denomination == "" then
		return fail("requirements_not_met")
	end
	local tier = tierOf(player)
	if tier >= Constants.MAX_TIER then
		return fail("locked")
	end
	local target = tier + 1
	if (player:GetAttribute("LandTier") or 1) < target - 1 then
		Notify.send(player, "error", "Expand your land to tier " .. (target - 1) .. " first")
		return fail("requirements_not_met")
	end
	local cost = TIER_COST[target]
	if not Economy.spend(player, cost, "upgrade_tier_" .. target) then
		return fail("not_enough_money")
	end
	setTier(player, target)
	Notify.send(player, "success", "Your synagogue grew into " .. STAGES[target - 1] .. "!")
	return { ok = true }
end

function ProgressionFallback.serialize(player)
	local denomination = player:GetAttribute("Denomination")
	if type(denomination) ~= "string" or not known(denomination) then
		denomination = ""
	end
	return { denomination = denomination, tier = tierOf(player) }
end

function ProgressionFallback.applySaved(player, saved)
	if not active() then
		return
	end
	if type(saved) == "table" and type(saved.denomination) == "string" and known(saved.denomination) then
		player:SetAttribute("Denomination", saved.denomination)
		setTier(player, math.clamp(math.floor(tonumber(saved.tier) or 2), 2, Constants.MAX_TIER))
	else
		player:SetAttribute("Denomination", "")
		setTier(player, 1)
	end
end

function ProgressionFallback.start()
	local folder = Link.folder(ReplicatedStorage, "Remotes")
	local created = {}
	for name, className in REMOTES do
		if not folder:FindFirstChild(name) then
			local remote = Link.get(ReplicatedStorage, "Remotes", name, className)
			remote:SetAttribute("CoreFallback", true)
			created[name] = remote
		end
	end
	local function bind(name, callback)
		local remote = created[name]
		if remote and remote:IsA("RemoteFunction") then
			remote.OnServerInvoke = callback
		end
	end
	bind("RF_GetCatalog", catalog)
	bind("RF_GetInventory", function()
		return { items = {} }
	end)
	bind("RF_Buy", function()
		return fail("locked")
	end)
	bind("RF_Merge", function()
		return fail("locked")
	end)
	bind("RF_Equip", function()
		return fail("locked")
	end)
	bind("RF_Unequip", function()
		return fail("locked")
	end)
	bind("RF_ChooseDenomination", chooseDenomination)
	bind("RF_UpgradeBuilding", upgradeBuilding)
end

return ProgressionFallback
