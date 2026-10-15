local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Guard = require(script.Parent.Guard)
local Notify = require(script.Parent.Notify)
local Economy = require(script.Parent.Economy)
local Signal = require(script.Parent.Signal)
local Catalog = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("UpgradeCatalog"))

local UpgradeService = {}

UpgradeService.Changed = Signal.new()

local levels = {}

local function attributeName(id)
	return "Upg_" .. id
end

function UpgradeService.init(player, saved)
	local own = {}
	for _, definition in Catalog.list do
		local value = type(saved) == "table" and saved[definition.id] or 0
		if not Guard.isInteger(value, 0, definition.maxLevel) then
			value = 0
		end
		own[definition.id] = value
		player:SetAttribute(attributeName(definition.id), value)
	end
	levels[player] = own
	player:SetAttribute("BonusPerSecond", 0)
end

function UpgradeService.level(player, id)
	local own = levels[player]
	return own and own[id] or 0
end

function UpgradeService.levelsOf(player)
	return levels[player] or {}
end

function UpgradeService.serialize(player)
	return table.clone(levels[player] or {})
end

function UpgradeService.arrivalBonus(player)
	return Catalog.arrivalBonus(levels[player])
end

function UpgradeService.tip(player)
	local tier = math.clamp(tonumber(player:GetAttribute("Tier")) or 1, 1, 7)
	return Catalog.tip(levels[player], tier)
end

function UpgradeService.bonusPerSecond(player)
	if player:GetAttribute("HasMinyan") ~= true then
		return 0
	end
	local congregation = tonumber(player:GetAttribute("Congregation")) or 0
	return Catalog.duesPerSecond(levels[player], congregation)
end

function UpgradeService.purchase(player, id)
	if not Guard.isPlayer(player) or not Guard.isString(id, 40) then
		return false, "invalid"
	end
	local definition = Catalog.get(id)
	local own = levels[player]
	if not definition or not own then
		return false, "invalid"
	end
	if (player:GetAttribute("PlotId") or 0) <= 0 then
		Notify.send(player, "error", "Claim a plot first")
		return false, "locked"
	end
	local level = own[id]
	local cost = Catalog.cost(definition, level)
	if not cost then
		Notify.send(player, "info", definition.name .. " is fully upgraded")
		return false, "locked"
	end
	if not Economy.spend(player, cost, "upgrade_" .. id) then
		Notify.send(player, "error", "Not enough money for " .. definition.name)
		return false, "not_enough_money"
	end
	own[id] = level + 1
	player:SetAttribute(attributeName(id), level + 1)
	Notify.send(player, "success", definition.name .. " is now level " .. (level + 1))
	UpgradeService.Changed:Fire(player, id, level + 1)
	return true
end

function UpgradeService.forget(player)
	levels[player] = nil
end

return UpgradeService
