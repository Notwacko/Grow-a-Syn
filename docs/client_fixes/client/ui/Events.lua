local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Theme = require(script.Parent.Theme)
local Util = require(script.Parent.Util)
local Store = require(script.Parent.Store)
local Reveal = require(script.Parent.Reveal)
local Toasts = require(script.Parent.Toasts)
local ItemCatalog = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ItemCatalog"))
local PetCatalog = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("PetCatalog"))
local CosmeticCatalog = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("CosmeticCatalog"))

local Events = {}

local function rewardSpec(payload)
	local item = payload.item and ItemCatalog.item(payload.item)
	local lines = {}
	local name = payload.label or ""
	if payload.money and payload.money > 0 then
		name = "+" .. Util.short(payload.money) .. " money"
	end
	if item then
		table.insert(lines, "You got a " .. item.name)
	end
	if payload.boost then
		table.insert(lines, payload.boost)
	end
	if payload.freeze then
		table.insert(lines, "Plus a streak freeze!")
	end
	if payload.streak then
		table.insert(lines, "Streak: day " .. payload.streak)
	end
	if name == "" and item then
		name = item.name
	end
	return {
		title = payload.title or "Reward",
		name = name,
		sub = table.concat(lines, "\n"),
		icon = item and ("item_" .. item.category) or (payload.money and "coins" or "gift"),
		rarity = item and item.rarity or (payload.money and "uncommon" or "rare"),
		noTag = item == nil,
		tall = #lines > 1,
	}
end

function Events.start(ctx)
	Store.events:connect(function(kind, payload)
		if kind == "reward" then
			Reveal.push(rewardSpec(payload))
		elseif kind == "discover" then
			Toasts.show("gold", string.format("New in your Collection: %s (%d/%d)", payload.name, payload.count, payload.total), 4)
		elseif kind == "pet" then
			local pet = PetCatalog.get(payload.id)
			Reveal.push({
				title = payload.count > 1 and "Pet Level Up!" or "New Pet!",
				name = payload.name,
				icon = "pet_" .. payload.id,
				rarity = payload.rarity,
				sub = pet and pet.blurb or "",
			})
		elseif kind == "cosmetic" then
			local item = CosmeticCatalog.get(payload.id)
			Reveal.push({
				title = "New Style!",
				name = payload.name,
				icon = item and item.model or "star",
				rarity = payload.rarity,
				sub = "Find it in your Style tab",
			})
		elseif kind == "purchase" then
			Toasts.show("success", "Thank you! " .. payload.name, 4)
		elseif kind == "legacy_done" then
			Reveal.push({
				title = "Legacy Begins!",
				name = "+" .. Util.short(payload.gain) .. " Legacy Points",
				icon = "legacy",
				rarity = "legendary",
				sub = string.format("Income now x%s forever", Util.mult(payload.mult)),
				tall = false,
			})
		elseif kind == "open" then
			if payload.panel then
				ctx.openTab(payload.panel)
			end
		end
	end)
end

return Events
