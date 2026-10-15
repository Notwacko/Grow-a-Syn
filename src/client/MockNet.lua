-- Canned catalog/inventory/responses and locally set attributes. Only used when the server is absent.
local Players = game:GetService("Players")

local player = Players.LocalPlayer

local ASH = {
	"Ashkenazi Reform",
	"Ashkenazi Conservative",
	"Ashkenazi Orthodox",
	"Ashkenazi Ultra Orthodox",
	"Ashkenazi Hasidic",
	"Ashkenazi Haredi",
}

local function placeholderStages(prefix)
	local stages = {}
	for i = 1, 6 do
		stages[i] = prefix .. " Stage " .. i .. (i == 6 and " (Final)" or "")
	end
	return stages
end

local ITEMS = {
	{ id = "torah_basic", name = "Sefer Torah", category = "torah", rarity = "rare", price = 500, model = "torah_basic", mergesTo = "torah_gold" },
	{ id = "torah_gold", name = "Gilded Sefer Torah", category = "torah", rarity = "epic", price = 2500, model = "torah_gold" },
	{ id = "ark_oak", name = "Oak Aron Kodesh", category = "ark", rarity = "uncommon", price = 300, model = "ark_oak", mergesTo = "ark_gold" },
	{ id = "ark_gold", name = "Golden Aron Kodesh", category = "ark", rarity = "legendary", price = 5000, model = "ark_gold" },
	{ id = "siddur_a", name = "Siddur", category = "siddur", rarity = "common", price = 50, model = "siddur_a", mergesTo = "siddur_b" },
	{ id = "siddur_b", name = "Leather Siddur", category = "siddur", rarity = "uncommon", price = 150, model = "siddur_b" },
	{ id = "menorah_a", name = "Brass Menorah", category = "menorah", rarity = "uncommon", price = 200, model = "menorah_a" },
	{ id = "kiddush_a", name = "Kiddush Cup", category = "kiddush_cup", rarity = "common", price = 80, model = "kiddush_a" },
	{ id = "chandelier_a", name = "Chandelier", category = "chandelier", rarity = "rare", price = 900, model = "chandelier_a" },
	{ id = "ornament_a", name = "Star Ornament", category = "ornament", rarity = "common", price = 40, model = "ornament_a", mergesTo = "ornament_b" },
	{ id = "ornament_b", name = "Crystal Ornament", category = "ornament", rarity = "rare", price = 400, model = "ornament_b" },
	{ id = "holiday_a", name = "Festive Banner", category = "holiday_decor", rarity = "mythical", price = 9000, model = "holiday_a", robux = 199 },
}

local CATALOG = {
	items = ITEMS,
	buildings = {
		{ id = "bld_bench", name = "Extra Pews", price = 250, model = "prop_bench" },
		{ id = "bld_lamp", name = "Lamp Posts", price = 400, model = "prop_lamp" },
		{ id = "bld_tree", name = "Garden Trees", price = 600, model = "prop_tree" },
	},
	packs = {
		{ id = "pack_s", name = "Pouch of Money", money = 5000, robux = 49 },
		{ id = "pack_m", name = "Chest of Money", money = 60000, robux = 199 },
		{ id = "pack_l", name = "Vault of Money", money = 1200000, robux = 799 },
	},
	boosts = {
		{ id = "boost_2x", name = "Money", mult = 2, duration = 600, robux = 49, free = true },
		{ id = "boost_4x", name = "Money", mult = 4, duration = 600, robux = 149 },
		{ id = "boost_8x", name = "Money", mult = 8, duration = 1800, robux = 399 },
	},
	denominations = {
		{ id = "ashkenazi", name = "Ashkenazi", blurb = "Warm, choir-filled services and a classic hall.", model = "ashkenazi_T2", stages = ASH },
		{ id = "sephardic", name = "Sephardic", blurb = "Rich colors, carved wood and a proud central bimah.", model = "sephardic_T2", stages = placeholderStages("Sephardic") },
		{ id = "mizrahi", name = "Mizrahi", blurb = "Courtyards, tilework and ancient melodies.", model = "mizrahi_T2", stages = placeholderStages("Mizrahi") },
	},
}

return function(Net, newSignal)
	local mock = {}
	local nextUid = 100
	local inv = {}

	local function addItem(id)
		nextUid += 1
		table.insert(inv, { uid = "u" .. nextUid, id = id })
	end
	for _ = 1, 3 do
		addItem("siddur_a")
	end
	for _ = 1, 3 do
		addItem("ornament_a")
	end
	addItem("torah_basic")
	addItem("ark_oak")
	addItem("kiddush_a")

	local function byId(id)
		for _, it in ITEMS do
			if it.id == id then
				return it
			end
		end
	end

	local function setAttrs(t)
		for k, v in t do
			player:SetAttribute(k, v)
		end
	end
	setAttrs({
		Money = 1000,
		MoneyPerSecond = 5,
		Congregation = 3,
		MaxCongregation = 12,
		PlotId = 1,
		LandTier = 1,
		TutorialStep = 0,
		HasMinyan = false,
		Denomination = "",
		Tier = 1,
		BoostMult = 1,
		BoostEndsAt = 0,
	})

	function mock.catalog()
		return CATALOG
	end
	function mock.inventory()
		return table.clone(inv)
	end

	function mock.buy(id)
		task.wait(0.15)
		local offer
		for _, key in { "items", "buildings", "packs", "boosts" } do
			for _, entry in CATALOG[key] do
				if entry.id == id then
					offer = entry
					offer.kind = key
				end
			end
		end
		if not offer then
			return { ok = false, reason = "invalid" }
		end
		if offer.kind == "packs" then
			player:SetAttribute("Money", player:GetAttribute("Money") + offer.money)
		elseif offer.kind == "boosts" then
			player:SetAttribute("BoostMult", offer.mult)
			player:SetAttribute("BoostEndsAt", workspace:GetServerTimeNow() + offer.duration)
		else
			local money = player:GetAttribute("Money")
			if money < (offer.price or 0) then
				return { ok = false, reason = "not_enough_money" }
			end
			player:SetAttribute("Money", money - offer.price)
			if offer.kind == "items" then
				addItem(offer.id)
			end
		end
		if player:GetAttribute("TutorialStep") == 3 then
			player:SetAttribute("TutorialStep", 4)
		end
		return { ok = true }
	end

	function mock.merge(uids)
		task.wait(0.15)
		local id
		for _, uid in uids do
			for _, it in inv do
				if it.uid == uid then
					if id and id ~= it.id then
						return { ok = false, reason = "invalid" }
					end
					id = it.id
				end
			end
		end
		local info = id and byId(id)
		if #uids ~= 3 or not info or not info.mergesTo then
			return { ok = false, reason = "requirements_not_met" }
		end
		for _, uid in uids do
			for i, it in inv do
				if it.uid == uid then
					table.remove(inv, i)
					break
				end
			end
		end
		addItem(info.mergesTo)
		return { ok = true }
	end

	function mock.equip(uid, slot)
		for _, it in inv do
			if it.uid == uid then
				it.slot = slot
			end
		end
		return { ok = true }
	end
	function mock.unequip(uid)
		for _, it in inv do
			if it.uid == uid then
				it.slot = nil
			end
		end
		return { ok = true }
	end

	local SEATS = { 12, 20, 30, 42, 56, 72, 100 }
	local function setTier(tier)
		player:SetAttribute("MaxCongregation", SEATS[tier])
		player:SetAttribute("MoneyPerSecond", 5 + (tier - 1) * 13)
		player:SetAttribute("Tier", tier)
	end

	function mock.chooseDenomination(id)
		task.wait(0.2)
		player:SetAttribute("Denomination", id)
		setTier(2)
		if player:GetAttribute("TutorialStep") == 5 then
			player:SetAttribute("TutorialStep", 6)
		end
		return { ok = true }
	end

	function mock.upgradeBuilding()
		local tier = player:GetAttribute("Tier")
		if tier >= 7 then
			return { ok = false, reason = "locked" }
		end
		setTier(tier + 1)
		return { ok = true }
	end

	function mock.expandLand()
		player:SetAttribute("LandTier", math.min(6, player:GetAttribute("LandTier") + 1))
		return { ok = true }
	end

	-- cycles 0 .. 6 so a single tap walks the whole tutorial
	function mock.advanceTutorial()
		local step = player:GetAttribute("TutorialStep")
		if step == 5 and (player:GetAttribute("Denomination") or "") == "" then
			Net.MinyanReached:fire()
			return
		end
		local nextStep = (step + 1) % 7
		if nextStep == 4 then
			player:SetAttribute("Congregation", 3)
		elseif nextStep == 5 then
			player:SetAttribute("Congregation", 10)
			player:SetAttribute("HasMinyan", true)
			Net.MinyanReached:fire()
		elseif nextStep == 0 then
			setAttrs({ Congregation = 3, HasMinyan = false, Denomination = "", Tier = 1, MaxCongregation = 12 })
		end
		player:SetAttribute("TutorialStep", nextStep)
	end

	return mock
end
