local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ui = script.Parent.Parent.ui
local Theme = require(ui.Theme)
local Ui = require(ui.Ui)
local Util = require(ui.Util)
local Store = require(ui.Store)
local Sfx = require(ui.Sfx)
local Shared = ReplicatedStorage:WaitForChild("Shared")
local ItemCatalog = require(Shared:WaitForChild("ItemCatalog"))
local PetCatalog = require(Shared:WaitForChild("PetCatalog"))

local PanelStore = {}

local PASS_ICONS = {
	double_income = "pass_double_income",
	patron = "pass_patron",
	rapid_growth = "pass_rapid_growth",
	helping_hands = "pass_helping_hands",
	swift_delivery = "pass_swift_delivery",
	quick_merge = "pass_quick_merge",
	premium_wardrobe = "pass_golden_wardrobe",
	pet_lover = "pass_pet_lover",
}

local PRODUCT_ICONS = {
	bundle_s = "product_basket_s",
	bundle_m = "product_basket_m",
	bundle_l = "product_basket_l",
	growth_lamp = "product_growth_lamp",
	festival_boost = "product_festival_boost",
	complete_s = "product_complete_now",
	complete_m = "product_complete_now",
	complete_l = "product_complete_now",
	order_rare = "product_special_order",
	order_epic = "product_special_order",
	order_legendary = "product_special_order",
	legacy_boost = "product_legacy_boost",
	pet_pick_1 = "product_special_pet",
	pet_pick_2 = "product_special_pet",
	pet_pick_3 = "product_special_pet",
	starter_pack = "product_starter_pack",
}

local RARITY_COLORS = { rare = "rare", epic = "epic", legendary = "legendary", uncommon = "uncommon" }

function PanelStore.new(container, ctx, menu)
	local panel = {}
	local running = false
	local scroll = Ui.scroll(container, { gap = 12, pad = 6 })
	local picker = Ui.frame(container, { name = "Picker", size = UDim2.fromScale(1, 1), color = Theme.cream, transparency = 0, radius = 16, visible = false, z = 30 })
	Ui.stroke(picker, Theme.ink, 4)
	local pickerTitle = Ui.label(picker, { text = "", textSize = 30, color = Theme.ink, stroke = false, size = UDim2.new(1, -140, 0, 50), position = UDim2.fromOffset(14, 6), xalign = Enum.TextXAlignment.Left, z = 31 })
	local pickerBack = Ui.button(picker, { palette = Theme.red, size = UDim2.fromOffset(110, 46), position = UDim2.new(1, -10, 0, 8), anchor = Vector2.new(1, 0), text = "Back", textSize = 22, z = 32 })
	pickerBack.click(function()
		picker.Visible = false
	end)
	local pickerGrid = Ui.scroll(picker, { size = UDim2.new(1, -20, 1, -70), position = UDim2.fromOffset(10, 62), grid = { cell = UDim2.fromOffset(150, 170), pad = UDim2.fromOffset(10, 10) }, z = 31 })

	local function section(title, order)
		local label = Ui.label(scroll, { text = title, textSize = 30, size = UDim2.new(1, -12, 0, 42), xalign = Enum.TextXAlignment.Left, order = order, z = 4 })
		label.TextColor3 = Theme.ink
		local stroke = label:FindFirstChildOfClass("UIStroke")
		if stroke then
			stroke:Destroy()
		end
		return label
	end

	local function grid(order, cellHeight)
		local frame = Ui.frame(scroll, { size = UDim2.new(1, -12, 0, 10), order = order, z = 3 })
		frame.AutomaticSize = Enum.AutomaticSize.Y
		Ui.make("UIGridLayout", { CellSize = UDim2.fromOffset(212, cellHeight or 250), CellPadding = UDim2.fromOffset(10, 10), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Left }, frame)
		return frame
	end

	local function buyButton(card, entry, owned, handler)
		local available = entry.available
		local text
		local palette = Theme.purple
		if owned then
			text = "Owned"
			palette = Theme.green
		elseif not available then
			text = "Coming soon"
			palette = Theme.gray
		else
			text = "R$ " .. tostring(entry.robux)
		end
		local button = Ui.button(card, {
			palette = palette,
			size = UDim2.new(1, -20, 0, 46),
			position = UDim2.new(0.5, 0, 1, -8),
			anchor = Vector2.new(0.5, 1),
			text = text,
			textSize = 22,
			enabled = (not owned) and available,
		})
		button.click(handler)
		return button
	end

	local function productCard(parent, entry, order, handler)
		local card = Ui.card(parent, { size = UDim2.fromOffset(212, 250), order = order })
		Ui.image(card, { image = PRODUCT_ICONS[entry.key] or "product_cosmetic", size = UDim2.fromOffset(100, 100), position = UDim2.new(0.5, 0, 0, 8), anchor = Vector2.new(0.5, 0), z = 5 })
		Ui.label(card, { text = entry.name, textSize = 20, color = Theme.ink, stroke = false, size = UDim2.new(1, -12, 0, 48), position = UDim2.fromOffset(6, 110), wrap = true, fit = true, z = 5 })
		local blurb = Ui.label(card, { text = entry.blurb, textSize = 14, color = Theme.inkSoft, stroke = false, size = UDim2.new(1, -16, 0, 40), position = UDim2.fromOffset(8, 156), wrap = true, fit = true, z = 5 })
		blurb.Font = Theme.bodyFont
		buyButton(card, entry, false, handler)
		return card
	end

	local function openPicker(title, entries, onPick)
		pickerTitle.Text = title
		Ui.clear(pickerGrid)
		for index, entry in entries do
			local card = Ui.card(pickerGrid, { size = UDim2.fromOffset(150, 170), order = index, strokeColor = entry.color })
			Ui.image(card, { image = entry.icon, size = UDim2.fromOffset(90, 90), position = UDim2.new(0.5, 0, 0, 12), anchor = Vector2.new(0.5, 0), z = 5 })
			Ui.label(card, { text = entry.name, textSize = 18, color = Theme.ink, stroke = false, size = UDim2.new(1, -10, 0, 40), position = UDim2.fromOffset(5, 106), wrap = true, fit = true, z = 5 })
			local button = Ui.button(card, { palette = Theme.green, size = UDim2.new(1, -20, 0, 36), position = UDim2.new(0.5, 0, 1, -6), anchor = Vector2.new(0.5, 1), text = "Choose", textSize = 19 })
			button.click(function()
				picker.Visible = false
				onPick(entry.id)
			end)
		end
		picker.Visible = true
	end

	local function purchase(key, target)
		local result = Store.call("store.buyProduct", { key = key, target = target })
		if not result.ok then
			if result.reason == "offline" then
				ctx.toast("info", "This item is coming soon")
			else
				ctx.explain(result)
			end
		end
	end

	function panel.refresh()
		local data = Store.get("store")
		if not data then
			return
		end
		Ui.clear(scroll)
		local productsByKey = {}
		for _, product in data.products do
			productsByKey[product.key] = product
		end
		local order = 1
		local note = Ui.label(scroll, { text = "Everything here is optional and helps keep the game growing. Special Orders and Pet picks give exactly what you choose, no luck involved.", textSize = 17, color = Theme.inkSoft, stroke = false, size = UDim2.new(1, -12, 0, 48), wrap = true, order = order, z = 4 })
		note.Font = Theme.bodyFont
		order += 1
		if data.starter and data.starter.available and productsByKey.starter_pack then
			local entry = productsByKey.starter_pack
			local card = Ui.card(scroll, { size = UDim2.new(1, -12, 0, 130), order = order, color = Theme.cream2, strokeColor = Theme.gold[2], stroke = 5 })
			Ui.image(card, { image = "product_starter_pack", size = UDim2.fromOffset(104, 104), position = UDim2.fromOffset(12, 12), z = 5 })
			Ui.label(card, { text = entry.name, textSize = 30, color = Theme.ink, stroke = false, size = UDim2.new(1, -420, 0, 40), position = UDim2.fromOffset(130, 12), xalign = Enum.TextXAlignment.Left, fit = true, z = 5 })
			local blurb = Ui.label(card, { text = entry.blurb .. string.format("  (ends in %s)", Util.words((data.starter.endsAt or 0) - Store.now())), textSize = 17, color = Theme.inkSoft, stroke = false, size = UDim2.new(1, -420, 0, 70), position = UDim2.fromOffset(130, 54), xalign = Enum.TextXAlignment.Left, wrap = true, z = 5 })
			blurb.Font = Theme.bodyFont
			local button = Ui.button(card, { palette = entry.available and Theme.purple or Theme.gray, size = UDim2.fromOffset(190, 60), position = UDim2.new(1, -14, 0.5, 0), anchor = Vector2.new(1, 0.5), text = entry.available and ("R$ " .. entry.robux) or "Coming soon", textSize = 26, enabled = entry.available })
			button.click(function()
				purchase("starter_pack")
			end)
			order += 1
		end
		section("Game Passes", order)
		order += 1
		local passGrid = grid(order, 280)
		order += 1
		for index, pass in data.passes do
			local card = Ui.card(passGrid, { size = UDim2.fromOffset(212, 280), order = index, strokeColor = pass.owned and Theme.green[2] or Theme.ink })
			Ui.image(card, { image = PASS_ICONS[pass.key] or "product_cosmetic", size = UDim2.fromOffset(100, 100), position = UDim2.new(0.5, 0, 0, 8), anchor = Vector2.new(0.5, 0), z = 5 })
			Ui.label(card, { text = pass.name, textSize = 21, color = Theme.ink, stroke = false, size = UDim2.new(1, -12, 0, 30), position = UDim2.fromOffset(6, 110), fit = true, z = 5 })
			local blurb = Ui.label(card, { text = pass.blurb, textSize = 14, color = Theme.inkSoft, stroke = false, size = UDim2.new(1, -16, 0, 80), position = UDim2.fromOffset(8, 142), wrap = true, fit = true, z = 5 })
			blurb.Font = Theme.bodyFont
			buyButton(card, pass, pass.owned, function()
				local result = Store.call("store.buyPass", { key = pass.key })
				if not result.ok then
					if result.reason == "offline" then
						ctx.toast("info", "This pass is coming soon")
					else
						ctx.explain(result)
					end
				end
			end)
		end
		section("Boosts and Bundles", order)
		order += 1
		local boostGrid = grid(order)
		order += 1
		local boostIndex = 0
		for _, key in { "growth_lamp", "festival_boost", "bundle_s", "bundle_m", "bundle_l", "complete_s", "complete_m", "complete_l", "legacy_boost" } do
			local entry = productsByKey[key]
			if entry then
				boostIndex += 1
				productCard(boostGrid, entry, boostIndex, function()
					purchase(key)
				end)
			end
		end
		section("Special Orders", order)
		order += 1
		local orderGrid = grid(order)
		order += 1
		for index, key in { "order_rare", "order_epic", "order_legendary" } do
			local entry = productsByKey[key]
			if entry then
				productCard(orderGrid, entry, index, function()
					local entries = {}
					for _, category in ItemCatalog.CATEGORIES do
						table.insert(entries, { id = category.id, name = category.name, icon = "item_" .. category.id, color = Theme.rarityColor(entry.rarity) })
					end
					openPicker("Choose the item you want", entries, function(categoryId)
						purchase(key, categoryId)
					end)
				end)
			end
		end
		section("Pick a Pet", order)
		order += 1
		local petGrid = grid(order)
		order += 1
		for index, key in { "pet_pick_1", "pet_pick_2", "pet_pick_3" } do
			local entry = productsByKey[key]
			if entry then
				productCard(petGrid, entry, index, function()
					local limit = PetCatalog.rarityIndex(entry.rarity)
					local entries = {}
					for _, pet in PetCatalog.list do
						if PetCatalog.rarityIndex(pet.rarity) <= limit then
							table.insert(entries, { id = pet.id, name = pet.name, icon = "pet_" .. pet.id, color = Theme.rarityColor(pet.rarity) })
						end
					end
					openPicker("Choose your pet", entries, function(petId)
						purchase(key, petId)
					end)
				end)
			end
		end
		section("Cosmetics", order)
		order += 1
		local cosmetic = Ui.card(scroll, { size = UDim2.new(1, -12, 0, 90), order = order })
		Ui.image(cosmetic, { image = "wardrobe", size = UDim2.fromOffset(70, 70), position = UDim2.fromOffset(12, 10), z = 5 })
		local text = Ui.label(cosmetic, { text = "New kippot, tallitot, capes, wings, hats and effects are in the Style tab. Many can be bought with in-game money!", textSize = 19, color = Theme.inkSoft, stroke = false, size = UDim2.new(1, -330, 1, -10), position = UDim2.fromOffset(94, 5), wrap = true, xalign = Enum.TextXAlignment.Left, z = 5 })
		text.Font = Theme.bodyFont
		local open = Ui.button(cosmetic, { palette = Theme.purple, size = UDim2.fromOffset(190, 52), position = UDim2.new(1, -14, 0.5, 0), anchor = Vector2.new(1, 0.5), text = "Open Style", textSize = 22 })
		open.click(function()
			menu.select("wardrobe")
		end)
	end

	Store.on("store", function()
		if running then
			panel.refresh()
		end
	end)

	function panel.show()
		running = true
		picker.Visible = false
		panel.refresh()
	end

	function panel.hide()
		running = false
	end

	return panel
end

return PanelStore
