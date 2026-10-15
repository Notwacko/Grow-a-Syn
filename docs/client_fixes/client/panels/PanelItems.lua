local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ui = script.Parent.Parent.ui
local Theme = require(ui.Theme)
local Ui = require(ui.Ui)
local Util = require(ui.Util)
local Store = require(ui.Store)
local ItemView = require(ui.ItemView)
local Sfx = require(ui.Sfx)
local Shared = ReplicatedStorage:WaitForChild("Shared")
local ItemCatalog = require(Shared:WaitForChild("ItemCatalog"))
local Constants = require(Shared:WaitForChild("Constants"))

local PanelItems = {}

local RARITY_RANK = {}
for index, id in Theme.rarityOrder do
	RARITY_RANK[id] = index
end

local function slotNames(category)
	local names = {}
	for _, group in Constants.SLOT_COUNTS do
		if Constants.SLOT_PREFIX_CATEGORY[group.prefix] == category then
			if group.count == 1 then
				table.insert(names, group.prefix)
			else
				for index = 1, group.count do
					table.insert(names, group.prefix .. index)
				end
			end
		end
	end
	return names
end

function PanelItems.new(container, ctx, menu)
	local panel = {}
	local filter = "all"
	local selected = nil
	local cards = {}
	local running = false
	local lastSignature = ""

	local header = Ui.frame(container, { name = "Header", size = UDim2.new(1, 0, 0, 54), z = 4 })
	local summary, summaryLabel = Ui.pill(header, {
		size = UDim2.fromOffset(330, 46),
		position = UDim2.fromOffset(4, 4),
		icon = "bolt",
		text = "Items bonus +0%",
		height = 46,
		textSize = 21,
	})
	local mergeAll = Ui.button(header, {
		palette = Theme.purple,
		size = UDim2.fromOffset(190, 48),
		position = UDim2.new(1, -4, 0, 4),
		anchor = Vector2.new(1, 0),
		icon = "puzzle",
		iconSize = 30,
		text = "Merge All",
		textSize = 22,
	})

	local chips = Ui.frame(container, { name = "Chips", size = UDim2.new(1, 0, 0, 54), position = UDim2.fromOffset(0, 58), z = 4 })
	Ui.make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Center }, chips)
	Ui.padding(chips, 4, 2, 4, 2)
	local chipButtons = {}
	local function addChip(id, icon, order)
		local button = Ui.button(chips, { palette = Theme.gray, size = UDim2.fromOffset(52, 50), icon = icon, iconSize = 36, radius = 16, order = order })
		button.click(function()
			filter = id
			panel.refresh()
		end)
		chipButtons[id] = button
	end
	local allChip = Ui.button(chips, { palette = Theme.blue, size = UDim2.fromOffset(64, 50), text = "All", textSize = 22, radius = 16, order = 0 })
	allChip.click(function()
		filter = "all"
		panel.refresh()
	end)
	chipButtons.all = allChip
	for index, category in ItemCatalog.CATEGORIES do
		addChip(category.id, "item_" .. category.id, index)
	end

	local detailWidth = Ui.touch and 236 or 300
	local cellWidth = Ui.touch and 118 or 132
	local listArea = Ui.frame(container, { name = "ListArea", size = UDim2.new(1, -(detailWidth + 16), 1, -118), position = UDim2.fromOffset(0, 116), z = 3 })
	local scroll = Ui.scroll(listArea, { grid = { cell = UDim2.fromOffset(cellWidth, 168), pad = UDim2.fromOffset(8, 10) }, pad = 4 })
	local emptyLabel = Ui.label(listArea, {
		text = "No items yet.\nVisit the Shop to buy your first one!",
		textSize = 26,
		color = Theme.inkSoft,
		stroke = false,
		size = UDim2.new(1, 0, 0, 100),
		position = UDim2.fromScale(0, 0.3),
		wrap = true,
		visible = false,
		z = 5,
	})

	local detail = Ui.card(container, { name = "Detail", size = UDim2.new(0, detailWidth, 1, -118), position = UDim2.new(1, -detailWidth, 0, 116), color = Theme.cream2, z = 3 })
	local detailHolder = Ui.frame(detail, { name = "Holder", z = 4 })

	local function inventoryItems()
		local inventory = Store.inventory()
		return inventory and inventory.items or {}
	end

	local function lookup(uid)
		for _, entry in inventoryItems() do
			if entry.uid == uid then
				return entry
			end
		end
		return nil
	end

	local function groupKey(entry)
		return entry.id .. ":" .. (entry.star or 0)
	end

	local function findMergeSet(entry)
		local key = groupKey(entry)
		local group = {}
		for _, other in inventoryItems() do
			if groupKey(other) == key then
				table.insert(group, other)
			end
		end
		if #group < ItemCatalog.MERGE_COUNT then
			return nil, #group
		end
		table.sort(group, function(a, b)
			if (a.slot ~= nil) ~= (b.slot ~= nil) then
				return a.slot == nil
			end
			return a.uid < b.uid
		end)
		return { group[1].uid, group[2].uid, group[3].uid }, #group
	end

	local function freeSlotFor(category)
		local used = {}
		for _, entry in inventoryItems() do
			if entry.slot then
				used[entry.slot] = true
			end
		end
		local names = slotNames(category)
		for _, name in names do
			if not used[name] then
				return name
			end
		end
		return names[1]
	end

	local function growthLeft(info, entry)
		local rate = Store.attr("GrowthRate", 1)
		local remaining = (1 - (entry.growth or 0)) * info.grow / math.max(rate, 0.1)
		return remaining
	end

	local function totalBonus()
		local total = 0
		for _, entry in inventoryItems() do
			if entry.slot then
				local info = ItemCatalog.item(entry.id)
				if info then
					total += ItemCatalog.bonusOf(info, entry.growth or 0, entry.mutation, entry.star)
				end
			end
		end
		return total
	end

	local function buildDetail()
		Ui.clear(detailHolder)
		local entry = selected and lookup(selected)
		if not entry then
			local hint = Ui.label(detailHolder, {
				text = "Tap an item to see what it does.\n\nPlace items in your synagogue to earn more money. Three of the same item merge into the next rarity!",
				textSize = 20,
				color = Theme.inkSoft,
				stroke = false,
				size = UDim2.new(1, -30, 1, -30),
				position = UDim2.fromOffset(15, 15),
				wrap = true,
				yalign = Enum.TextYAlignment.Top,
				z = 5,
			})
			hint.Font = Theme.bodyFont
			return
		end
		local info = ItemCatalog.item(entry.id)
		local color = Theme.rarityColor(info.rarity)
		detail.UIStroke.Color = color
		local glowBox = Ui.frame(detailHolder, { size = UDim2.new(1, -20, 0, 130), position = UDim2.fromOffset(10, 10), z = 4 })
		ItemView.glow(glowBox, color, 120)
		Ui.image(glowBox, { image = ItemView.icon(info), size = UDim2.fromOffset(124, 124), position = UDim2.fromScale(0.5, 0.5), anchor = Vector2.new(0.5, 0.5), z = 6 })
		local name = Ui.label(detailHolder, {
			text = ItemView.name(info, entry.mutation, entry.star),
			textSize = 24,
			color = Theme.ink,
			stroke = false,
			size = UDim2.new(1, -20, 0, 54),
			position = UDim2.fromOffset(10, 142),
			wrap = true,
			z = 5,
		})
		ItemView.rarityTag(detailHolder, info.rarity, { size = UDim2.fromOffset(110, 24), position = UDim2.new(0.5, 0, 0, 198), anchor = Vector2.new(0.5, 0) })
		local bonus = ItemCatalog.bonusOf(info, entry.growth or 0, entry.mutation, entry.star)
		local fullBonus = ItemCatalog.bonusOf(info, 1, entry.mutation, entry.star)
		local lines = {}
		table.insert(lines, entry.slot and string.format("Placed: +%s%% income", Util.short(bonus * 100)) or "In your bag (not earning)")
		if (entry.growth or 0) < 1 then
			table.insert(lines, string.format("Growing %d%%  |  %s left", math.floor((entry.growth or 0) * 100), Util.words(growthLeft(info, entry))))
			table.insert(lines, string.format("Fully grown: +%s%%", Util.short(fullBonus * 100)))
		else
			table.insert(lines, "Fully grown")
		end
		if entry.mutation then
			table.insert(lines, "Special: " .. string.upper(string.sub(entry.mutation, 1, 1)) .. string.sub(entry.mutation, 2))
		end
		if (entry.star or 0) > 0 then
			table.insert(lines, "Level " .. entry.star .. " star bonus")
		end
		local info1 = Ui.label(detailHolder, {
			text = table.concat(lines, "\n"),
			textSize = 17,
			color = Theme.ink,
			stroke = false,
			size = UDim2.new(1, -20, 0, 100),
			position = UDim2.fromOffset(10, 228),
			wrap = true,
			yalign = Enum.TextYAlignment.Top,
			z = 5,
		})
		info1.Font = Theme.bodyFont
		local place = Ui.button(detailHolder, {
			palette = entry.slot and Theme.orange or Theme.green,
			size = UDim2.new(1, -24, 0, 50),
			position = UDim2.new(0, 12, 1, -118),
			text = entry.slot and "Take Out" or "Place It",
			textSize = 24,
		})
		place.click(function()
			local result
			if entry.slot then
				result = Store.remote("RF_Unequip", entry.uid)
			else
				result = Store.remote("RF_Equip", entry.uid, freeSlotFor(info.category))
			end
			ctx.explain(result)
			Store.refreshInventory()
		end)
		local set, count = findMergeSet(entry)
		local mergeResult = ItemCatalog.mergeResult(entry.id, entry.star or 0)
		local merge = Ui.button(detailHolder, {
			palette = set and Theme.purple or Theme.gray,
			size = UDim2.new(1, -24, 0, 50),
			position = UDim2.new(0, 12, 1, -58),
			text = mergeResult and (set and "Merge x3" or string.format("Merge (%d/3)", count or 1)) or "Cannot merge",
			textSize = 24,
			icon = "puzzle",
			iconSize = 30,
		})
		merge.click(function()
			if not set or not mergeResult then
				Sfx.play("error")
				ctx.toast("info", info.category == "torah" and "Torah scrolls are sacred and stay as they are" or "You need 3 identical items to merge")
				return
			end
			local result = Store.remote("RF_Merge", set)
			if result.ok then
				Sfx.play("win")
			end
			ctx.explain(result)
			Store.refreshInventory()
			Store.refreshCatalog()
		end)
	end

	function panel.signature()
		local parts = { filter, tostring(selected) }
		for _, entry in inventoryItems() do
			table.insert(parts, entry.uid .. ":" .. tostring(entry.slot) .. ":" .. tostring(entry.mutation) .. ":" .. (entry.star or 0) .. ":" .. (((entry.growth or 0) >= 1) and 1 or 0))
		end
		return table.concat(parts, ",")
	end

	function panel.refresh()
		lastSignature = panel.signature()
		for id, button in chipButtons do
			button.setPalette(id == filter and Theme.blue or Theme.gray)
		end
		Ui.clear(scroll)
		cards = {}
		local items = {}
		for _, entry in inventoryItems() do
			local info = ItemCatalog.item(entry.id)
			if info and (filter == "all" or info.category == filter) then
				table.insert(items, { entry = entry, info = info })
			end
		end
		table.sort(items, function(a, b)
			if RARITY_RANK[a.info.rarity] ~= RARITY_RANK[b.info.rarity] then
				return RARITY_RANK[a.info.rarity] > RARITY_RANK[b.info.rarity]
			end
			if a.info.id ~= b.info.id then
				return a.info.id < b.info.id
			end
			return a.entry.uid < b.entry.uid
		end)
		emptyLabel.Visible = #items == 0
		local counts = {}
		for _, entry in inventoryItems() do
			counts[groupKey(entry)] = (counts[groupKey(entry)] or 0) + 1
		end
		for index, data in items do
			local entry, info = data.entry, data.info
			local color = Theme.rarityColor(info.rarity)
			local card, stroke = Ui.card(scroll, {
				size = UDim2.fromOffset(cellWidth, 168),
				order = index,
				strokeColor = selected == entry.uid and Theme.gold[1] or color,
				stroke = selected == entry.uid and 5 or (Theme.rarity[info.rarity] or Theme.rarity.common).stroke,
			})
			ItemView.glow(card, color, 76, UDim2.new(0.5, 0, 0, 52))
			Ui.image(card, { image = ItemView.icon(info), size = UDim2.fromOffset(80, 80), position = UDim2.new(0.5, 0, 0, 52), anchor = Vector2.new(0.5, 0.5), z = 5 })
			local name = Ui.label(card, {
				text = info.name,
				textSize = 15,
				color = Theme.ink,
				stroke = false,
				size = UDim2.new(1, -8, 0, 36),
				position = UDim2.fromOffset(4, 96),
				wrap = true,
				z = 5,
			})
			ItemView.pips(card, info.rarity, { position = UDim2.fromOffset(0, 8), frame = UDim2.new(1, 0, 0, 10), size = 8 })
			local progress = Ui.frame(card, { size = UDim2.new(1, -20, 0, 12), position = UDim2.new(0, 10, 1, -26), color = Theme.ink, transparency = 0, radius = 6, z = 5 })
			local fill = Ui.frame(progress, { size = UDim2.fromScale(math.clamp(entry.growth or 0, 0, 1), 1), color = (entry.growth or 0) >= 1 and Theme.gold[1] or Theme.green[1], transparency = 0, radius = 6, z = 6 })
			if entry.slot then
				local badge = Ui.frame(card, { size = UDim2.fromOffset(60, 20), position = UDim2.new(0, 6, 0, 28), color = Theme.green[2], transparency = 0, radius = 10, stroke = 2, z = 7 })
				Ui.label(badge, { text = "Placed", textSize = 13, size = UDim2.fromScale(1, 1), fit = true, stroke = 2, z = 8 })
			end
			if (entry.star or 0) > 0 then
				local star = Ui.frame(card, { size = UDim2.fromOffset(44, 22), position = UDim2.new(1, -6, 0, 28), anchor = Vector2.new(1, 0), color = Theme.gold[2], transparency = 0, radius = 11, stroke = 2, z = 7 })
				Ui.label(star, { text = "+" .. entry.star, textSize = 15, size = UDim2.fromScale(1, 1), fit = true, stroke = 2, z = 8 })
			end
			if entry.mutation then
				ItemView.mutationBadge(card, entry.mutation)
			end
			if (counts[groupKey(entry)] or 0) >= 3 and ItemCatalog.mergeResult(entry.id, entry.star or 0) then
				local ready = Ui.frame(card, { size = UDim2.fromOffset(26, 26), position = UDim2.new(1, -4, 1, -34), anchor = Vector2.new(1, 0), color = Theme.purple[1], transparency = 0, radius = 13, stroke = 2, z = 8 })
				Ui.image(ready, { image = "puzzle", size = UDim2.fromOffset(18, 18), position = UDim2.fromScale(0.5, 0.5), anchor = Vector2.new(0.5, 0.5), z = 9 })
			end
			local hit = Ui.make("TextButton", { Text = "", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 12 }, card)
			hit.Activated:Connect(function()
				Sfx.play("click")
				selected = entry.uid
				panel.refresh()
			end)
			cards[entry.uid] = { card = card, fill = fill }
		end
		buildDetail()
		summaryLabel.Text = string.format("Items bonus +%s%%", Util.short(totalBonus() * 100))
		local owned = Store.get("items") and Store.get("items").mergeAll
		mergeAll.setPalette(owned and Theme.purple or Theme.gray)
		mergeAll.setText(owned and "Merge All" or "Merge All (Pass)")
	end

	mergeAll.click(function()
		local state = Store.get("items")
		if not (state and state.mergeAll) then
			menu.select("store")
			ctx.toast("info", "Quick Merge is a game pass")
			return
		end
		local result = Store.call("items.mergeAll")
		if result.ok then
			Sfx.play("win")
			ctx.toast("success", "Merged " .. tostring(result.merges or "") .. " times!")
		else
			ctx.toast("info", "Nothing to merge yet")
		end
		Store.refreshInventory()
	end)

	function panel.show()
		running = true
		Store.refreshInventory()
		panel.refresh()
		task.spawn(function()
			while running and container.Parent do
				task.wait(2)
				if running then
					Store.refreshInventory(true)
					local signature = panel.signature()
					if signature ~= lastSignature then
						panel.refresh()
					else
						for _, entry in inventoryItems() do
							local shown = cards[entry.uid]
							if shown then
								shown.fill.Size = UDim2.fromScale(math.clamp(entry.growth or 0, 0, 1), 1)
							end
						end
					end
				end
			end
		end)
	end

	function panel.hide()
		running = false
	end

	Store.inventoryChanged:connect(function()
		if running then
			panel.refresh()
		end
	end)

	return panel
end

return PanelItems
