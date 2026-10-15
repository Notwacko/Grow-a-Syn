local Monetization = {}

Monetization.passes = {
	{ key = "double_income", id = 0, robux = 249, name = "Double Income", blurb = "Earn +100% more money, forever.", boost = 1.0, order = 1 },
	{ key = "patron", id = 0, robux = 499, name = "Patron Pass", blurb = "+50% money, 12 hour offline earnings, double welcome back reward, 3 streak freezes, a golden cape and a Patron badge.", boost = 0.5, order = 2 },
	{ key = "rapid_growth", id = 0, robux = 299, name = "Rapid Growth", blurb = "Everything you place grows 50% faster.", order = 3 },
	{ key = "helping_hands", id = 0, robux = 149, name = "Helping Hands", blurb = "Guests arrive 50% faster and finished quests collect themselves.", order = 4 },
	{ key = "swift_delivery", id = 0, robux = 199, name = "Swift Delivery", blurb = "The shop restocks every 4 minutes instead of 5.", order = 5 },
	{ key = "quick_merge", id = 0, robux = 99, name = "Quick Merge", blurb = "Unlocks the Merge All button.", order = 6 },
	{ key = "premium_wardrobe", id = 0, robux = 799, name = "Premium Wardrobe", blurb = "Every premium cosmetic released so far, yours to wear.", order = 7 },
	{ key = "pet_lover", id = 0, robux = 199, name = "Pet Lover", blurb = "+1 pet slot and +10% pet bonus.", order = 8 },
}

Monetization.products = {
	{ key = "bundle_s", id = 0, robux = 49, kind = "money", minutes = 120, name = "Small Money Bundle", blurb = "2 hours of income, right now." },
	{ key = "bundle_m", id = 0, robux = 149, kind = "money", minutes = 480, name = "Medium Money Bundle", blurb = "8 hours of income, right now." },
	{ key = "bundle_l", id = 0, robux = 499, kind = "money", minutes = 2160, name = "Large Money Bundle", blurb = "36 hours of income, right now." },
	{ key = "growth_lamp", id = 0, robux = 39, kind = "boost", boost = "lamp", seconds = 1800, name = "Growth Lamp", blurb = "Everything grows 2x faster for 30 minutes." },
	{ key = "festival_boost", id = 0, robux = 59, kind = "boost", boost = "festival", seconds = 900, name = "Festival Boost", blurb = "+100% money for 15 minutes." },
	{ key = "complete_s", id = 0, robux = 19, kind = "complete", seconds = 900, name = "Grow 15 Minutes", blurb = "Skip 15 minutes of growth on everything you placed." },
	{ key = "complete_m", id = 0, robux = 49, kind = "complete", seconds = 3600, name = "Grow 1 Hour", blurb = "Skip 1 hour of growth on everything you placed." },
	{ key = "complete_l", id = 0, robux = 129, kind = "complete", seconds = 14400, name = "Grow 4 Hours", blurb = "Skip 4 hours of growth on everything you placed." },
	{ key = "order_rare", id = 0, robux = 99, kind = "order", rarity = "rare", name = "Special Order: Rare", blurb = "Pick any category and receive that item in Rare quality. No luck involved." },
	{ key = "order_epic", id = 0, robux = 299, kind = "order", rarity = "epic", name = "Special Order: Epic", blurb = "Pick any category and receive that item in Epic quality. No luck involved." },
	{ key = "order_legendary", id = 0, robux = 799, kind = "order", rarity = "legendary", name = "Special Order: Legendary", blurb = "Pick any category and receive that item in Legendary quality. No luck involved." },
	{ key = "legacy_boost", id = 0, robux = 199, kind = "legacy", name = "Legacy Boost", blurb = "+25% Legacy Points on your next Legacy." },
	{ key = "pet_pick_1", id = 0, robux = 149, kind = "pet", rarity = "uncommon", name = "Pick a Pet: Friendly", blurb = "Choose any Common or Uncommon pet. No luck involved." },
	{ key = "pet_pick_2", id = 0, robux = 399, kind = "pet", rarity = "rare", name = "Pick a Pet: Special", blurb = "Choose any Rare pet or below. No luck involved." },
	{ key = "pet_pick_3", id = 0, robux = 999, kind = "pet", rarity = "legendary", name = "Pick a Pet: Legendary", blurb = "Choose any pet in the game, including the Peacock." },
	{ key = "cosmetic_49", id = 0, robux = 49, kind = "cosmetic", tierPrice = 49, name = "Style Unlock", blurb = "Unlocks the style item you picked in the Style tab." },
	{ key = "cosmetic_99", id = 0, robux = 99, kind = "cosmetic", tierPrice = 99, name = "Style Unlock", blurb = "Unlocks the style item you picked in the Style tab." },
	{ key = "cosmetic_149", id = 0, robux = 149, kind = "cosmetic", tierPrice = 149, name = "Style Unlock", blurb = "Unlocks the style item you picked in the Style tab." },
	{ key = "cosmetic_249", id = 0, robux = 249, kind = "cosmetic", tierPrice = 249, name = "Style Unlock", blurb = "Unlocks the style item you picked in the Style tab." },
	{ key = "cosmetic_399", id = 0, robux = 399, kind = "cosmetic", tierPrice = 399, name = "Style Unlock", blurb = "Unlocks the style item you picked in the Style tab." },
	{ key = "cosmetic_799", id = 0, robux = 799, kind = "cosmetic", tierPrice = 799, name = "Style Unlock", blurb = "Unlocks the style item you picked in the Style tab." },
	{ key = "starter_pack", id = 0, robux = 149, kind = "starter", minutes = 240, item = "ornament_rare", name = "New Congregation Pack", blurb = "4 hours of income, a Rare ornament and a golden kippah. Available during your first week." },
}

Monetization.PASS_ATTRIBUTE_PREFIX = "Pass_"
Monetization.STARTER_WINDOW = 7 * 86400
Monetization.FIRST_OFFER_DELAY = 300
Monetization.OFFER_COOLDOWN = 900
Monetization.PENDING_TTL = 120

local passByKey = {}
for _, pass in Monetization.passes do
	passByKey[pass.key] = pass
end
local productByKey = {}
for _, product in Monetization.products do
	productByKey[product.key] = product
end

function Monetization.pass(key)
	return passByKey[key]
end

function Monetization.product(key)
	return productByKey[key]
end

function Monetization.passByAssetId(id)
	for _, pass in Monetization.passes do
		if pass.id == id and id ~= 0 then
			return pass
		end
	end
	return nil
end

function Monetization.productByAssetId(id)
	for _, product in Monetization.products do
		if product.id == id and id ~= 0 then
			return product
		end
	end
	return nil
end

return Monetization
