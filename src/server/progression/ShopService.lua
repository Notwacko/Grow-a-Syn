local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Catalog = require(script.Parent.Catalog)
local DenominationService = require(script.Parent.DenominationService)
local Guard = require(script.Parent.Guard)
local InventoryService = require(script.Parent.InventoryService)
local Link = require(script.Parent.Link)
local Products = require(script.Parent.Products)

local ShopService = {}

local offerByProduct = {}
local notify
local purchased

local function buyWithMoney(player, offer)
	local data = InventoryService.get(player)
	if (offer.minTier or 1) > data.Tier then
		return { ok = false, reason = "requirements_not_met" }
	end
	if not InventoryService.hasRoom(player, 1) then
		return { ok = false, reason = "requirements_not_met" }
	end
	if workspace:GetAttribute("CoreOnline") ~= true then
		return { ok = false, reason = "offline" }
	end
	if (player:GetAttribute("Money") or 0) < offer.priceMoney then
		return { ok = false, reason = "not_enough_money" }
	end
	local spend = Link.get(ServerStorage, "Bridge", "SpendMoney", "BindableFunction")
	local paid = spend:Invoke(player, offer.priceMoney, offer.id)
	if paid ~= true then
		return { ok = false, reason = "not_enough_money" }
	end
	if not InventoryService.get(player) or not InventoryService.addItem(player, offer.category, offer.rarity) then
		return { ok = false, reason = "offline" }
	end
	InventoryService.changed(player)
	return { ok = true }
end

function ShopService.buy(player, offerId)
	if not Guard.isString(offerId) then
		return { ok = false, reason = "invalid" }
	end
	local offer = Catalog.offer(offerId)
	if not offer then
		return { ok = false, reason = "invalid" }
	end
	if not InventoryService.get(player) then
		return { ok = false, reason = "offline" }
	end
	if offer.priceRobux then
		local productId = Products[offer.id] or 0
		if productId <= 0 then
			return { ok = false, reason = "offline" }
		end
		if offer.kind == "item" and not InventoryService.hasRoom(player, 1) then
			return { ok = false, reason = "requirements_not_met" }
		end
		MarketplaceService:PromptProductPurchase(player, productId)
		return { ok = true, pending = true }
	end
	local result
	if offer.kind == "building" then
		result = DenominationService.upgrade(player, offer.tier)
	elseif offer.kind == "item" and offer.priceMoney then
		result = buyWithMoney(player, offer)
	else
		return { ok = false, reason = "invalid" }
	end
	if result.ok then
		purchased:Fire(player, offer.id)
	end
	return result
end

local function grantRobuxOffer(player, offer)
	if offer.kind == "item" then
		return InventoryService.addItem(player, offer.category, offer.rarity) ~= nil
	elseif offer.kind == "money_pack" then
		if workspace:GetAttribute("CoreOnline") ~= true then
			return false
		end
		local grant = Link.get(ServerStorage, "Bridge", "GrantMoney", "BindableEvent")
		grant:Fire(player, offer.amount, offer.id)
		return true
	elseif offer.kind == "boost" then
		local data = InventoryService.get(player)
		local now = os.time()
		local start = (data.BoostEndsAt > now and data.BoostMult == offer.multiplier) and data.BoostEndsAt or now
		InventoryService.setBoost(player, offer.multiplier, start + offer.durationSeconds)
		return true
	end
	return false
end

local function processReceipt(receipt)
	local offer = offerByProduct[receipt.ProductId]
	if not offer then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local player = Players:GetPlayerByUserId(receipt.PlayerId)
	if not player or not InventoryService.get(player) then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local purchaseId = tostring(receipt.PurchaseId)
	if InventoryService.hasReceipt(player, purchaseId) then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	if not grantRobuxOffer(player, offer) then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	InventoryService.addReceipt(player, purchaseId)
	InventoryService.changed(player)
	purchased:Fire(player, offer.id)
	notify:FireClient(player, "success", "Purchase complete: " .. offer.name)
	if not InventoryService.save(player) then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

function ShopService.init()
	notify = Link.get(ReplicatedStorage, "Remotes", "RE_Notify", "RemoteEvent")
	purchased = Link.get(ServerStorage, "Bridge", "Purchased", "BindableEvent")

	for offerId, productId in pairs(Products) do
		local offer = Catalog.offer(offerId)
		if offer and productId > 0 then
			offerByProduct[productId] = offer
		end
	end

	local getCatalog = Link.get(ReplicatedStorage, "Remotes", "RF_GetCatalog", "RemoteFunction")
	getCatalog.OnServerInvoke = function()
		return Catalog.public(Products)
	end

	local buyRemote = Link.get(ReplicatedStorage, "Remotes", "RF_Buy", "RemoteFunction")
	buyRemote.OnServerInvoke = function(player, offerId)
		return Guard.run(player, "buy", ShopService.buy, player, offerId)
	end

	MarketplaceService.ProcessReceipt = processReceipt
end

return ShopService
