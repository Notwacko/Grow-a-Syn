local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Guard = require(script.Parent.Guard)
local Notify = require(script.Parent.Notify)
local Economy = require(script.Parent.Economy)
local GameService = require(script.Parent.GameService)
local PlayerState = require(script.Parent.PlayerState)
local IncomeService = require(script.Parent.IncomeService)
local Shared = ReplicatedStorage:WaitForChild("Shared")
local PetCatalog = require(Shared:WaitForChild("PetCatalog"))
local Balance = require(Shared:WaitForChild("Balance"))

local PetService = {}

local random = Random.new()

local function data(player)
	return PlayerState.get(player, "pets", { owned = {}, equipped = {}, eggs = 0, pityEpic = 0, pityLegendary = 0 })
end

local function slotsOf(player)
	local slots = PetCatalog.BASE_SLOTS
	if player:GetAttribute("Pass_pet_lover") == true then
		slots += 1
	end
	return slots
end

local function bonusMultiplier(player)
	if player:GetAttribute("Pass_pet_lover") == true then
		return 1.1
	end
	return 1
end

local function publish(player, pets)
	local ids = {}
	for _, id in pets.equipped do
		table.insert(ids, id)
	end
	local text = table.concat(ids, ",")
	if player:GetAttribute("PetsEquipped") ~= text then
		player:SetAttribute("PetsEquipped", text)
	end
end

function PetService.bonus(player)
	local pets = data(player)
	local total = 0
	for _, id in pets.equipped do
		total += PetCatalog.bonusOf(id, pets.owned[id])
	end
	return total * bonusMultiplier(player)
end

function PetService.eggCost(player)
	return PetCatalog.eggCost(Balance.priceScale(player:GetAttribute("Tier")))
end

function PetService.snapshot(player)
	local pets = data(player)
	local owned = {}
	for id, count in pets.owned do
		table.insert(owned, { id = id, count = count, level = PetCatalog.level(count), bonus = PetCatalog.bonusOf(id, count) * bonusMultiplier(player) })
	end
	table.sort(owned, function(a, b)
		local petA, petB = PetCatalog.get(a.id), PetCatalog.get(b.id)
		local ra, rb = PetCatalog.rarityIndex(petA.rarity), PetCatalog.rarityIndex(petB.rarity)
		if ra ~= rb then
			return ra > rb
		end
		return a.id < b.id
	end)
	return {
		owned = owned,
		equipped = table.clone(pets.equipped),
		slots = slotsOf(player),
		eggCost = PetService.eggCost(player),
		eggs = pets.eggs,
		bonus = PetService.bonus(player),
		odds = PetCatalog.oddsTable(),
		pity = { epic = PetCatalog.PITY.epic - pets.pityEpic, legendary = PetCatalog.PITY.legendary - pets.pityLegendary },
	}
end

function PetService.grant(player, petId, silent)
	local pet = PetCatalog.get(petId)
	if not pet then
		return false
	end
	local pets = table.clone(data(player))
	pets.owned = table.clone(pets.owned)
	pets.owned[petId] = (pets.owned[petId] or 0) + 1
	pets.equipped = table.clone(pets.equipped)
	if #pets.equipped < slotsOf(player) and not table.find(pets.equipped, petId) then
		table.insert(pets.equipped, petId)
	end
	PlayerState.set(player, "pets", pets)
	publish(player, pets)
	if not silent then
		GameService.send(player, "pet", { id = petId, name = pet.name, rarity = pet.rarity, count = pets.owned[petId] })
	end
	return true
end

PetService.actions = {}

function PetService.actions.hatch(player)
	if not Guard.allow(player, "Hatch", 1.2) then
		return { ok = false, reason = "busy" }
	end
	if (player:GetAttribute("TutorialStep") or 0) < 6 then
		return { ok = false, reason = "locked" }
	end
	local cost = PetService.eggCost(player)
	if not Economy.spend(player, cost, "pet_egg") then
		Notify.send(player, "error", "Not enough money for an egg")
		return { ok = false, reason = "not_enough_money" }
	end
	local pets = table.clone(data(player))
	pets.eggs += 1
	pets.pityEpic += 1
	pets.pityLegendary += 1
	local minimum = 1
	if pets.pityLegendary >= PetCatalog.PITY.legendary then
		minimum = PetCatalog.rarityIndex("legendary")
	elseif pets.pityEpic >= PetCatalog.PITY.epic then
		minimum = PetCatalog.rarityIndex("epic")
	end
	local pet = PetCatalog.roll(random, minimum)
	local index = PetCatalog.rarityIndex(pet.rarity)
	if index >= PetCatalog.rarityIndex("legendary") then
		pets.pityLegendary = 0
		pets.pityEpic = 0
	elseif index >= PetCatalog.rarityIndex("epic") then
		pets.pityEpic = 0
	end
	PlayerState.set(player, "pets", pets)
	PetService.grant(player, pet.id, false)
	return { ok = true, id = pet.id }
end

function PetService.actions.equip(player, payload)
	local id = payload.id
	if not Guard.isString(id, 24) then
		return { ok = false, reason = "invalid" }
	end
	local pets = table.clone(data(player))
	if not pets.owned[id] then
		return { ok = false, reason = "invalid" }
	end
	pets.equipped = table.clone(pets.equipped)
	if table.find(pets.equipped, id) then
		return { ok = true }
	end
	if #pets.equipped >= slotsOf(player) then
		Notify.send(player, "info", "All pet slots are full")
		return { ok = false, reason = "locked" }
	end
	table.insert(pets.equipped, id)
	PlayerState.set(player, "pets", pets)
	publish(player, pets)
	return { ok = true }
end

function PetService.actions.unequip(player, payload)
	local id = payload.id
	if not Guard.isString(id, 24) then
		return { ok = false, reason = "invalid" }
	end
	local pets = table.clone(data(player))
	pets.equipped = table.clone(pets.equipped)
	local index = table.find(pets.equipped, id)
	if not index then
		return { ok = false, reason = "invalid" }
	end
	table.remove(pets.equipped, index)
	PlayerState.set(player, "pets", pets)
	publish(player, pets)
	return { ok = true }
end

function PetService.init(player)
	local pets = data(player)
	local valid = {}
	for _, id in pets.equipped do
		if pets.owned[id] and PetCatalog.get(id) and #valid < slotsOf(player) then
			table.insert(valid, id)
		end
	end
	if #valid ~= #pets.equipped then
		local copy = table.clone(pets)
		copy.equipped = valid
		PlayerState.set(player, "pets", copy)
		pets = copy
	end
	publish(player, pets)
end

function PetService.start()
	IncomeService.register("pets", function(player)
		return 1 + PetService.bonus(player)
	end)
end

return PetService
