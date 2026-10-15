local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Guard = require(script.Parent.Guard)
local Notify = require(script.Parent.Notify)
local GameService = require(script.Parent.GameService)
local PlayerState = require(script.Parent.PlayerState)
local ItemService = require(script.Parent.ItemService)
local BoostService = require(script.Parent.BoostService)
local PetService = require(script.Parent.PetService)
local WardrobeService = require(script.Parent.WardrobeService)
local Rewards = require(script.Parent.Rewards)
local DataService = require(script.Parent.DataService)
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Monetization = require(Shared:WaitForChild("Monetization"))
local ItemCatalog = require(Shared:WaitForChild("ItemCatalog"))
local PetCatalog = require(Shared:WaitForChild("PetCatalog"))
local CosmeticCatalog = require(Shared:WaitForChild("CosmeticCatalog"))

local MonetizationService = {}

local INTENT_TTL = 900
local RECEIPT_LIMIT = 80
local priceCache = {}

local function devFree()
	return RunService:IsStudio() and Workspace:GetAttribute("DevFreeStore") == true
end

local function owns(player, key)
	return player:GetAttribute(Monetization.PASS_ATTRIBUTE_PREFIX .. key) == true
end

local function starterAvailable(player)
	if PlayerState.get(player, "starterBought", false) == true then
		return false, 0
	end
	local joined = PlayerState.get(player, "joined", os.time())
	local ends = joined + Monetization.STARTER_WINDOW
	return os.time() < ends, ends
end

local function loadPrice(assetId, infoType)
	if assetId == 0 or priceCache[assetId] ~= nil then
		return
	end
	priceCache[assetId] = false
	local ok, info = pcall(MarketplaceService.GetProductInfo, MarketplaceService, assetId, infoType)
	if ok and type(info) == "table" and type(info.PriceInRobux) == "number" then
		priceCache[assetId] = info.PriceInRobux
	end
end

local function priceOf(entry, infoType)
	if entry.id ~= 0 then
		loadPrice(entry.id, infoType)
		local cached = priceCache[entry.id]
		if cached then
			return cached
		end
	end
	return entry.robux
end

local function rarityIndexOfPet(id)
	local pet = PetCatalog.get(id)
	return pet and PetCatalog.rarityIndex(pet.rarity) or nil
end

local function validateTarget(player, product, target)
	if product.kind == "order" then
		if Guard.isString(target, 24) and ItemCatalog.category(target) then
			return true
		end
		return false
	elseif product.kind == "pet" then
		local index = Guard.isString(target, 24) and rarityIndexOfPet(target)
		return index ~= nil and index ~= false and index <= PetCatalog.rarityIndex(product.rarity)
	elseif product.kind == "cosmetic" then
		local item = Guard.isString(target, 32) and CosmeticCatalog.get(target)
		if not item or item.robux ~= product.tierPrice or item.patron then
			return false
		end
		return not WardrobeService.owns(player, item)
	elseif product.kind == "starter" then
		return (starterAvailable(player))
	end
	return true
end

local function fallbackTarget(player, product)
	if product.kind == "order" then
		return "ornament"
	elseif product.kind == "pet" then
		for _, pet in PetCatalog.list do
			if PetCatalog.rarityIndex(pet.rarity) <= PetCatalog.rarityIndex(product.rarity) then
				return pet.id
			end
		end
	elseif product.kind == "cosmetic" then
		for _, item in CosmeticCatalog.list do
			if item.robux == product.tierPrice and not item.patron and not WardrobeService.owns(player, item) then
				return item.id
			end
		end
	end
	return nil
end

local function grant(player, product, target)
	local kind = product.kind
	if kind == "money" then
		Rewards.grantMinutes(player, product.minutes, "purchase")
	elseif kind == "boost" then
		BoostService.add(player, product.boost, product.seconds)
	elseif kind == "complete" then
		ItemService.completeGrowth(player, product.seconds)
	elseif kind == "order" then
		target = target or fallbackTarget(player, product)
		ItemService.grantItem(player, target .. "_" .. product.rarity, { silent = false })
	elseif kind == "legacy" then
		PlayerState.set(player, "legacyBoost", true)
	elseif kind == "pet" then
		target = target or fallbackTarget(player, product)
		if target then
			PetService.grant(player, target, false)
		end
	elseif kind == "cosmetic" then
		target = target or fallbackTarget(player, product)
		if target then
			WardrobeService.grant(player, target)
		else
			Rewards.grantMinutes(player, product.robux * 4, "purchase_fallback")
		end
	elseif kind == "starter" then
		PlayerState.set(player, "starterBought", true)
		Rewards.grantMinutes(player, product.minutes, "purchase")
		ItemService.grantItem(player, product.item, { silent = true })
		WardrobeService.grant(player, "kip_black_gold")
	end
	GameService.send(player, "purchase", { key = product.key, name = product.name })
	GameService.push(player, "store")
end

local function takeIntent(player, product)
	local intent = PlayerState.get(player, "intent", nil)
	if type(intent) == "table" and intent.key == product.key and (tonumber(intent.exp) or 0) > os.time() then
		return intent.target
	end
	return nil
end

function MonetizationService.snapshot(player)
	local passes = {}
	for _, pass in Monetization.passes do
		table.insert(passes, {
			key = pass.key,
			name = pass.name,
			blurb = pass.blurb,
			robux = priceOf(pass, Enum.InfoType.GamePass),
			owned = owns(player, pass.key),
			available = pass.id ~= 0 or devFree(),
		})
	end
	local products = {}
	for _, product in Monetization.products do
		table.insert(products, {
			key = product.key,
			name = product.name,
			blurb = product.blurb,
			robux = priceOf(product, Enum.InfoType.Product),
			kind = product.kind,
			rarity = product.rarity,
			tierPrice = product.tierPrice,
			available = product.id ~= 0 or devFree(),
		})
	end
	local available, ends = starterAvailable(player)
	return {
		passes = passes,
		products = products,
		starter = { available = available, endsAt = ends },
		joined = PlayerState.get(player, "joined", os.time()),
		now = os.time(),
	}
end

MonetizationService.actions = {}

function MonetizationService.actions.buyPass(player, payload)
	local key = payload.key
	local pass = Guard.isString(key, 32) and Monetization.pass(key)
	if not pass then
		return { ok = false, reason = "invalid" }
	end
	if not Guard.allow(player, "Purchase", 1.5) then
		return { ok = false, reason = "busy" }
	end
	if owns(player, key) then
		return { ok = false, reason = "locked" }
	end
	if pass.id == 0 then
		if devFree() then
			player:SetAttribute(Monetization.PASS_ATTRIBUTE_PREFIX .. key, true)
			Notify.send(player, "success", pass.name .. " unlocked (test mode)")
			return { ok = true }
		end
		return { ok = false, reason = "offline" }
	end
	local ok = pcall(MarketplaceService.PromptGamePassPurchase, MarketplaceService, player, pass.id)
	return { ok = ok, pending = true }
end

function MonetizationService.actions.buyProduct(player, payload)
	local key = payload.key
	local product = Guard.isString(key, 32) and Monetization.product(key)
	if not product then
		return { ok = false, reason = "invalid" }
	end
	if not Guard.allow(player, "Purchase", 1.5) then
		return { ok = false, reason = "busy" }
	end
	local target = payload.target
	if not validateTarget(player, product, target) then
		return { ok = false, reason = "invalid" }
	end
	if product.kind ~= "order" and product.kind ~= "pet" and product.kind ~= "cosmetic" then
		target = nil
	end
	if product.id == 0 then
		if devFree() then
			grant(player, product, target)
			return { ok = true }
		end
		return { ok = false, reason = "offline" }
	end
	PlayerState.set(player, "intent", { key = product.key, target = target or "", exp = os.time() + INTENT_TTL })
	local ok = pcall(MarketplaceService.PromptProductPurchase, MarketplaceService, player, product.id)
	return { ok = ok, pending = true }
end

local function processReceipt(info)
	local player = Players:GetPlayerByUserId(info.PlayerId)
	if not player or not PlayerState.ready(player) then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local product = Monetization.productByAssetId(info.ProductId)
	if not product then
		warn("[Monetization] receipt for unknown product " .. tostring(info.ProductId))
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local purchaseId = tostring(info.PurchaseId)
	local receipts = PlayerState.get(player, "receipts", {})
	if table.find(receipts, purchaseId) then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	local target = takeIntent(player, product)
	if target == "" then
		target = nil
	end
	local ok, err = pcall(grant, player, product, target)
	if not ok then
		warn("[Monetization] grant failed: " .. tostring(err))
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local updated = table.clone(receipts)
	table.insert(updated, purchaseId)
	while #updated > RECEIPT_LIMIT do
		table.remove(updated, 1)
	end
	PlayerState.set(player, "receipts", updated)
	PlayerState.set(player, "intent", nil)
	local saved = false
	local saveOk = pcall(function()
		saved = DataService.save(player, true)
	end)
	if not saveOk or not saved then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

function MonetizationService.init(player)
	if PlayerState.get(player, "joined", 0) == 0 then
		PlayerState.set(player, "joined", os.time())
	end
	task.spawn(function()
		for _, pass in Monetization.passes do
			if pass.id ~= 0 and player.Parent then
				local ok, owned = pcall(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, player.UserId, pass.id)
				if ok and owned then
					player:SetAttribute(Monetization.PASS_ATTRIBUTE_PREFIX .. pass.key, true)
				end
			end
		end
		player:SetAttribute("PassesLoaded", true)
		GameService.push(player, "store")
	end)
end

function MonetizationService.start()
	MarketplaceService.ProcessReceipt = processReceipt
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
		if not purchased then
			return
		end
		local pass = Monetization.passByAssetId(passId)
		if pass and Guard.isPlayer(player) then
			player:SetAttribute(Monetization.PASS_ATTRIBUTE_PREFIX .. pass.key, true)
			Notify.send(player, "success", pass.name .. " unlocked. Thank you!")
			GameService.send(player, "purchase", { key = pass.key, name = pass.name, pass = true })
			GameService.push(player, "store")
		end
	end)
	for _, pass in Monetization.passes do
		if pass.id ~= 0 then
			task.spawn(loadPrice, pass.id, Enum.InfoType.GamePass)
		end
	end
	for _, product in Monetization.products do
		if product.id ~= 0 then
			task.spawn(loadPrice, product.id, Enum.InfoType.Product)
		end
	end
end

return MonetizationService
