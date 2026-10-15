local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Guard = require(script.Parent.Guard)
local Notify = require(script.Parent.Notify)
local Economy = require(script.Parent.Economy)
local Signal = require(script.Parent.Signal)
local GameService = require(script.Parent.GameService)
local PlayerState = require(script.Parent.PlayerState)
local OutfitBuilder = require(script.Parent.OutfitBuilder)
local CosmeticFx = require(script.Parent.CosmeticFx)
local CosmeticCatalog = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("CosmeticCatalog"))

local WardrobeService = {}

WardrobeService.Changed = Signal.new()

local function data(player)
	return PlayerState.get(player, "wardrobe", { owned = {}, equipped = {} })
end

local function available(item)
	if item.effect then
		return CosmeticFx.has(item.effect)
	end
	return OutfitBuilder.modelExists(item.model)
end

local function entitled(player, item)
	if item.patron then
		return player:GetAttribute("Pass_patron") == true
	end
	if item.premium and player:GetAttribute("Pass_premium_wardrobe") == true then
		return true
	end
	return false
end

function WardrobeService.owns(player, item)
	if not item.money and not item.robux and not item.patron then
		return true
	end
	return data(player).owned[item.id] == true or entitled(player, item)
end

function WardrobeService.grant(player, id)
	local item = CosmeticCatalog.get(id)
	if not item then
		return false
	end
	local wardrobe = table.clone(data(player))
	wardrobe.owned = table.clone(wardrobe.owned)
	wardrobe.owned[id] = true
	PlayerState.set(player, "wardrobe", wardrobe)
	GameService.push(player, "wardrobe")
	GameService.send(player, "cosmetic", { id = id, name = item.name, rarity = item.rarity, slot = item.slot })
	return true
end

function WardrobeService.entries(player)
	local wardrobe = data(player)
	local entries = {}
	local effect
	for slot, id in wardrobe.equipped do
		local item = CosmeticCatalog.get(id)
		if item and WardrobeService.owns(player, item) and available(item) then
			if item.effect then
				effect = item.effect
			else
				table.insert(entries, {
					slot = slot,
					id = "cos_" .. item.id,
					spec = { model = item.model, colors = item.colors or {} },
				})
			end
		end
	end
	return entries, effect
end

function WardrobeService.snapshot(player)
	local wardrobe = data(player)
	local items = {}
	for _, item in CosmeticCatalog.list do
		if available(item) then
			table.insert(items, {
				id = item.id,
				name = item.name,
				slot = item.slot,
				rarity = item.rarity,
				money = item.money,
				robux = item.robux,
				premium = item.premium == true,
				patron = item.patron == true,
				owned = WardrobeService.owns(player, item),
				equipped = wardrobe.equipped[item.slot] == item.id,
			})
		end
	end
	local owned, total = 0, 0
	for _, item in items do
		total += 1
		if item.owned then
			owned += 1
		end
	end
	local outfit = require(script.Parent.CosmeticsService).describe(player)
	return {
		items = items,
		equipped = table.clone(wardrobe.equipped),
		owned = owned,
		total = total,
		slots = CosmeticCatalog.SLOTS,
		outfit = outfit,
	}
end

WardrobeService.actions = {}

function WardrobeService.actions.buy(player, payload)
	local id = payload.id
	if not Guard.isString(id, 32) then
		return { ok = false, reason = "invalid" }
	end
	local item = CosmeticCatalog.get(id)
	if not item or not item.money or not available(item) then
		return { ok = false, reason = "invalid" }
	end
	if WardrobeService.owns(player, item) then
		return { ok = false, reason = "locked" }
	end
	if not Economy.spend(player, item.money, "cosmetic_" .. id) then
		Notify.send(player, "error", "Not enough money")
		return { ok = false, reason = "not_enough_money" }
	end
	WardrobeService.grant(player, id)
	local wardrobe = table.clone(data(player))
	wardrobe.equipped = table.clone(wardrobe.equipped)
	wardrobe.equipped[item.slot] = id
	PlayerState.set(player, "wardrobe", wardrobe)
	WardrobeService.Changed:Fire(player)
	return { ok = true }
end

function WardrobeService.actions.equip(player, payload)
	local id = payload.id
	if not Guard.isString(id, 32) or not Guard.allow(player, "Wardrobe", 0.25) then
		return { ok = false, reason = "invalid" }
	end
	local item = CosmeticCatalog.get(id)
	if not item or not available(item) or not WardrobeService.owns(player, item) then
		return { ok = false, reason = "locked" }
	end
	local wardrobe = table.clone(data(player))
	wardrobe.equipped = table.clone(wardrobe.equipped)
	wardrobe.equipped[item.slot] = id
	PlayerState.set(player, "wardrobe", wardrobe)
	WardrobeService.Changed:Fire(player)
	return { ok = true }
end

function WardrobeService.actions.unequip(player, payload)
	local slot = payload.slot
	if not Guard.isString(slot, 16) or not CosmeticCatalog.slot(slot) or not Guard.allow(player, "Wardrobe", 0.25) then
		return { ok = false, reason = "invalid" }
	end
	local wardrobe = table.clone(data(player))
	wardrobe.equipped = table.clone(wardrobe.equipped)
	wardrobe.equipped[slot] = nil
	PlayerState.set(player, "wardrobe", wardrobe)
	WardrobeService.Changed:Fire(player)
	return { ok = true }
end

function WardrobeService.actions.outfit(player)
	if not Guard.allow(player, "Wardrobe", 0.25) then
		return { ok = false, reason = "busy" }
	end
	require(script.Parent.CosmeticsService).cycleOutfit(player)
	return { ok = true }
end

function WardrobeService.actions.style(player)
	if not Guard.allow(player, "Wardrobe", 0.25) then
		return { ok = false, reason = "busy" }
	end
	require(script.Parent.CosmeticsService).toggleStyle(player)
	return { ok = true }
end

function WardrobeService.init(player)
	WardrobeService.Changed:Fire(player)
end

return WardrobeService
