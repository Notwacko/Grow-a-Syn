local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Theme = require(script.Parent.Parent.ui.Theme)
local Ui = require(script.Parent.Parent.ui.Ui)
local Util = require(script.Parent.Parent.ui.Util)
local Store = require(script.Parent.Parent.ui.Store)
local ItemView = require(script.Parent.Parent.ui.ItemView)
local Sfx = require(script.Parent.Parent.ui.Sfx)
local ItemCatalog = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ItemCatalog"))

local PanelShop = {}

local RARITY_RANK = {}
for index, id in Theme.rarityOrder do
	RARITY_RANK[id] = index
end

function PanelShop.new(container, ctx, menu)
	local panel = {}
	local oddsOpen = false

	local header = Ui.frame(container, { name = "Header", size = UDim2.new(1, 0, 0, 56), z = 4 })
	local timerPill, timerLabel = Ui.pill(header, {
		size = UDim2.fromOffset(300, 46),
		position = UDim2.fromOffset(4, 4),
		icon = "clock",
		text = "Restocking...",
		height = 46,
		textSize = 22,
		color = Theme.ink,
	})
	local oddsButton = Ui.button(header, {
		palette = Theme.blue,
		size = UDim2.fromOffset(150, 48),
		position = UDim2.new(1, -4, 0, 4),
		anchor = Vector2.new(1, 0),
		text = "Odds",
		textSize = 22,
		icon = "puzzle",
		iconSize = 30,
	})
	local note = Ui.label(header, {
		text = "New items every few minutes. Rarer ones come around less often.",
		textSize = 16,
		size = UDim2.new(1, -490, 1, 0),
		position = UDim2.fromOffset(316, 0),
		xalign = Enum.TextXAlignment.Left,
		color = Theme.ink,
		stroke = false,
		wrap = true,
		z = 4,
	})
	note.Font = Theme.bodyFont

	local scroll = Ui.scroll(container, {
		name = "Offers",
		size = UDim2.new(1, 0, 1, -64),
		position = UDim2.fromOffset(0, 62),
		grid = { cell = UDim2.fromOffset(204, 292), pad = UDim2.fromOffset(12, 14) },
		pad = 8,
	})

	local odds = Ui.frame(container, {
		name = "Odds",
		size = UDim2.new(1, 0, 1, -60),
		position = UDim2.fromOffset(0, 60),
		color = Theme.cream,
		transparency = 0,
		radius = 16,
		visible = false,
		z = 20,
	})
	Ui.stroke(odds, Theme.ink, 4)
	local oddsScroll = Ui.scroll(odds, { size = UDim2.new(1, -16, 1, -16), position = UDim2.fromOffset(8, 8), gap = 6 })

	local function oddsRow(parent, left, right, color, order)
		local row = Ui.frame(parent, { size = UDim2.new(1, -8, 0, 36), color = Theme.cardBase, transparency = 0, radius = 10, stroke = 2, order = order, z = 21 })
		Ui.frame(row, { size = UDim2.fromOffset(10, 22), position = UDim2.new(0, 8, 0.5, 0), anchor = Vector2.new(0, 0.5), color = color or Theme.muted, transparency = 0, radius = 5, z = 22 })
		local l = Ui.label(row, { text = left, textSize = 20, color = Theme.ink, stroke = false, size = UDim2.new(0.6, 0, 1, 0), position = UDim2.fromOffset(28, 0), xalign = Enum.TextXAlignment.Left, z = 22 })
		l.Font = Theme.bodyFont
		local r = Ui.label(row, { text = right, textSize = 20, color = Theme.ink, stroke = false, size = UDim2.new(0.35, 0, 1, 0), position = UDim2.new(0.65, -8, 0, 0), xalign = Enum.TextXAlignment.Right, z = 22 })
		r.Font = Theme.bodyFont
	end

	local function title(parent, text, order)
		local t = Ui.label(parent, { text = text, textSize = 26, size = UDim2.new(1, -8, 0, 36), xalign = Enum.TextXAlignment.Left, order = order, color = Theme.ink, stroke = false, z = 21 })
		return t
	end

	local function buildOdds()
		Ui.clear(oddsScroll)
		local catalog = Store.catalog()
		local data = catalog and catalog.odds
		title(oddsScroll, "What can appear on the shelf", 1)
		local order = 2
		if data then
			for _, entry in data.rarities do
				oddsRow(oddsScroll, entry.name, string.format("%.1f%%", entry.percent), Theme.rarityColor(entry.id), order)
				order += 1
			end
			title(oddsScroll, "Growth bonus when a plant finishes growing", order)
			order += 1
			for _, entry in data.mutations do
				oddsRow(oddsScroll, entry.name .. "  (x" .. tostring(entry.mult) .. " income)", string.format("%.1f%%", entry.percent), ItemView.MUTATION_COLORS[entry.id], order)
				order += 1
			end
		end
		local pity = catalog and catalog.pity
		local noteText = pity and string.format("Fair play: a Rare or better is guaranteed every %d restocks, an Epic every %d and a Legendary every %d. A Simple Siddur is always on the shelf.", pity.rare, pity.epic, pity.legendary) or ""
		local n = Ui.label(oddsScroll, { text = noteText, textSize = 18, size = UDim2.new(1, -8, 0, 70), color = Theme.ink, stroke = false, wrap = true, order = order, z = 21 })
		n.Font = Theme.bodyFont
	end

	oddsButton.click(function()
		oddsOpen = not oddsOpen
		odds.Visible = oddsOpen
		oddsButton.setText(oddsOpen and "Back" or "Odds")
		if oddsOpen then
			buildOdds()
		end
	end)

	local entries = {}

	local function affordable(price)
		return Store.attr("Money", 0) >= price
	end

	function panel.paint()
		for _, entry in entries do
			if entry.item.stock > 0 then
				entry.button.setPalette(affordable(entry.item.price) and Theme.green or Theme.red)
			end
		end
	end

	local function buildCard(item, order, starterId)
		local rarity = item.rarity
		local color = Theme.rarityColor(rarity)
		local card, stroke = Ui.card(scroll, { size = UDim2.fromOffset(204, 292), order = order, strokeColor = color, stroke = (Theme.rarity[rarity] or Theme.rarity.common).stroke })
		local tagRow = Ui.frame(card, { size = UDim2.new(1, -12, 0, 24), position = UDim2.fromOffset(6, 6), z = 4 })
		ItemView.rarityTag(tagRow, rarity)
		ItemView.pips(card, rarity, { position = UDim2.fromOffset(0, 34), frame = UDim2.new(1, 0, 0, 12), size = 10 })
		local iconBox = Ui.frame(card, { size = UDim2.new(1, -16, 0, 120), position = UDim2.fromOffset(8, 50), z = 3 })
		ItemView.glow(iconBox, color, 100)
		Ui.image(iconBox, { image = ItemView.icon(item), size = UDim2.fromOffset(112, 112), position = UDim2.fromScale(0.5, 0.5), anchor = Vector2.new(0.5, 0.5), z = 5 })
		local nameLabel = Ui.label(card, {
			text = item.name,
			textSize = 20,
			color = Theme.ink,
			stroke = false,
			size = UDim2.new(1, -14, 0, 44),
			position = UDim2.fromOffset(7, 172),
			wrap = true,
			z = 5,
		})
		nameLabel.Font = Theme.titleFont
		local stockText = item.id == starterId and "Always in stock" or (item.stock > 0 and ("x" .. item.stock .. " left") or "Sold out")
		local stock = Ui.label(card, {
			text = stockText,
			textSize = 16,
			color = item.stock > 0 and Theme.inkSoft or Theme.red[2],
			stroke = false,
			size = UDim2.new(1, -14, 0, 18),
			position = UDim2.fromOffset(7, 216),
			z = 5,
		})
		stock.Font = Theme.bodyFont
		local soldOut = item.stock <= 0
		local can = affordable(item.price)
		local button = Ui.button(card, {
			palette = soldOut and Theme.gray or (can and Theme.green or Theme.red),
			size = UDim2.fromOffset(180, 46),
			position = UDim2.new(0.5, 0, 1, -6),
			anchor = Vector2.new(0.5, 1),
			icon = "coin",
			iconSize = 30,
			text = soldOut and "Sold out" or Util.short(item.price),
			textSize = 24,
			enabled = not soldOut,
		})
		entries[item.id] = { item = item, button = button }
		if item.id == starterId and Store.attr("TutorialStep", 0) == 3 then
			Ui.pulse(button.root, 1.08, 0.45)
		end
		button.click(function()
			if not affordable(item.price) then
				Sfx.play("error")
				Ui.shake(card, 6)
				ctx.toast("error", "Not enough money yet")
				return
			end
			button.setEnabled(false)
			local result = Store.remote("RF_Buy", item.id)
			if result.ok then
				Sfx.play("buy")
				Ui.pop(card, 1.06)
				Store.refreshCatalog()
				Store.refreshInventory()
				if RARITY_RANK[rarity] >= 3 then
					ctx.reveal.item({ id = item.id, name = item.name, rarity = rarity, category = item.category })
				end
				panel.refresh()
			else
				button.setEnabled(true)
				Sfx.play("error")
				ctx.explain(result)
			end
		end)
		return card
	end

	function panel.refresh()
		local catalog = Store.catalog()
		Ui.clear(scroll)
		entries = {}
		if not catalog then
			return
		end
		local items = {}
		for _, item in catalog.items do
			if item.stock > 0 or item.id == catalog.starterShelf then
				table.insert(items, item)
			end
		end
		table.sort(items, function(a, b)
			if a.id == catalog.starterShelf then
				return true
			elseif b.id == catalog.starterShelf then
				return false
			end
			if RARITY_RANK[a.rarity] ~= RARITY_RANK[b.rarity] then
				return RARITY_RANK[a.rarity] > RARITY_RANK[b.rarity]
			end
			return a.price < b.price
		end)
		for index, item in items do
			buildCard(item, index, catalog.starterShelf)
		end
	end

	local running = false
	function panel.show()
		oddsOpen = false
		odds.Visible = false
		oddsButton.setText("Odds")
		Store.refreshCatalog()
		panel.refresh()
		if ctx.hud then
			ctx.hud.markShopSeen()
		end
		running = true
		task.spawn(function()
			local refreshed = false
			while running and container.Parent do
				local remaining = Store.attr("ShopRestockAt", 0) - Store.now()
				if remaining > 0 then
					timerLabel.Text = "Restock in " .. Util.clock(remaining)
					refreshed = false
				else
					timerLabel.Text = "Restocking..."
					if not refreshed then
						refreshed = true
						task.delay(1.5, function()
							if running then
								Store.refreshCatalog()
								panel.refresh()
							end
						end)
					end
				end
				task.wait(0.5)
			end
		end)
	end

	function panel.hide()
		running = false
	end

	Store.inventoryChanged:connect(function()
		if running then
			Store.refreshCatalog()
			panel.refresh()
		end
	end)
	Store.onAttr("Money", function()
		if running then
			panel.paint()
		end
	end)

	return panel
end

return PanelShop
