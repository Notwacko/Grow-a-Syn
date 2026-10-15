-- Shop: tabs for Buildings, each item category, Money packs and Boosts. Buying goes through Net.buy (RF_Buy).
local Theme = require(script.Parent.Theme)
local C = require(script.Parent.Components)
local Net = require(script.Parent.Net)
local Format = require(script.Parent.Format)
local Sound = require(script.Parent.Sound)
local Contract = require(script.Parent.Contract)

local Color, Space = Theme.Color, Theme.Space

local ShopUI = {}

local CATEGORY_ORDER = { "torah", "ark", "siddur", "menorah", "kiddush_cup", "chandelier", "ornament", "holiday_decor" }
local CARD_SIZE = UDim2.fromOffset(128, 192)

function ShopUI.new(ctx)
	local self = { IsOpen = false }
	local popup, grid, tabRow, moneyConn
	local tabButtons, buyButtons = {}, {}
	local currentTab
	local busy = false

	local function tabsFor(catalog)
		local tabs = { { key = "Buildings", text = "🏠 Buildings" } }
		local present = {}
		for _, item in catalog.items do
			present[item.category] = true
		end
		for _, category in CATEGORY_ORDER do
			if present[category] then
				table.insert(tabs, { key = category, text = Contract.CategoryIcons[category] .. " " .. Contract.CategoryNames[category] })
			end
		end
		table.insert(tabs, { key = "Money", text = "💰 Money" })
		table.insert(tabs, { key = "Boosts", text = "⚡ Boosts" })
		return tabs
	end

	local function offersFor(catalog, tab)
		if tab == "Buildings" then
			return catalog.buildings, "building"
		elseif tab == "Money" then
			return catalog.packs, "pack"
		elseif tab == "Boosts" then
			return catalog.boosts, "boost"
		end
		local list = {}
		for _, item in catalog.items do
			if item.category == tab then
				table.insert(list, item)
			end
		end
		return list, "item"
	end

	local function paintAffordability()
		local money = Net.attr("Money", 0)
		for _, entry in buyButtons do
			if entry.price then
				entry.ui:setColor(money >= entry.price and Color.Green or Color.Grey)
			end
		end
	end

	local function tryBuy(offer, ui)
		if busy then
			return
		end
		busy = true
		ui:setEnabled(false)
		local res = Net.buy(offer.id)
		busy = false
		if res.ok then
			Sound.play("buy")
			ctx.toast("Purchased " .. offer.name .. "!", "success")
		else
			Sound.play("error")
			ctx.toast(Contract.Reasons[res.reason] or Contract.Reasons.default, "error")
		end
		if popup and not popup.closed then
			ui:setEnabled(true)
			paintAffordability()
		end
	end

	local function buildCard(catalog, offer, kind, order)
		local accent = kind == "item" and Theme.rarityColor(offer.rarity, catalog) or Color.Blue
		local card = C.card(grid, { order = order, accent = accent, name = offer.id })
		local frame = card.Frame
		if kind == "boost" then
			C.text(frame, { text = "x" .. tostring(offer.mult), size = "XL", color = Color.Orange, sizeU = UDim2.new(1, 0, 0, 80), position = UDim2.fromOffset(0, Space.S) })
			C.text(frame, { text = Format.duration(offer.duration), size = "S", sizeU = UDim2.new(1, 0, 0, Space.L), position = UDim2.fromOffset(0, 72) })
		elseif kind == "pack" then
			C.text(frame, { text = "💰", size = "XL", sizeU = UDim2.new(1, 0, 0, 56), position = UDim2.fromOffset(0, Space.S) })
			C.text(frame, { text = "+" .. Format.short(offer.money), size = "M", color = Color.Yellow, sizeU = UDim2.new(1, 0, 0, Space.XL), position = UDim2.fromOffset(0, 60) })
		else
			C.modelView(frame, offer.model, { size = UDim2.new(1, -Space.S, 0, 80), position = UDim2.fromOffset(Space.XS, Space.XS) })
			if kind == "item" and offer.rarity then
				local tag = C.pill(frame, { text = offer.rarity, color = accent, textSize = "XS" })
				tag.Root.Size = UDim2.fromOffset(0, Space.XL)
				tag.Root.Position = UDim2.fromOffset(Space.XS, Space.XS)
				tag.Root.ZIndex = 4
			end
		end
		local name = offer.name
		if kind == "boost" or kind == "pack" then
			name = kind == "boost" and (offer.name .. " Boost") or offer.name
		end
		C.text(frame, { text = name, size = "S", wrap = true, sizeU = UDim2.new(1, -Space.S, 0, 40), position = UDim2.fromOffset(Space.XS, 84) })
		local robux = offer.robux
		local isRobuxOnly = (kind == "boost" or kind == "pack")
		local label, price
		if isRobuxOnly or (robux and not offer.price) then
			label = (offer.free and "FREE") or ("R$ " .. tostring(robux))
		else
			label = "💰 " .. Format.short(offer.price or 0)
			price = offer.price
		end
		local ui
		ui = C.button(frame, {
			text = label,
			textSize = "S",
			color = (price == nil) and (offer.free and Color.Green or Color.Blue) or Color.Green,
			size = UDim2.new(1, -Space.S * 2, 0, Space.Tab),
			anchor = Vector2.new(0.5, 1),
			position = UDim2.new(0.5, 0, 1, -Space.S),
			onClick = function()
				tryBuy(offer, ui)
			end,
		})
		table.insert(buyButtons, { ui = ui, price = price })
		if robux and price then
			local badge = C.pill(frame, { text = "R$ " .. tostring(robux), color = Color.Blue, textSize = "XS" })
			badge.Root.Size = UDim2.fromOffset(0, Space.XL)
			badge.Root.AnchorPoint = Vector2.new(1, 0)
			badge.Root.Position = UDim2.new(1, -Space.XS, 0, Space.XS)
			badge.Root.ZIndex = 4
		end
	end

	local function showTab(tab)
		currentTab = tab
		for key, ui in tabButtons do
			ui:setColor(key == tab and Color.Yellow or Color.Blue)
		end
		for _, child in grid:GetChildren() do
			if child:IsA("Frame") then
				child:Destroy()
			end
		end
		buyButtons = {}
		local catalog = Net.getCatalog()
		local offers, kind = offersFor(catalog, tab)
		for i, offer in offers do
			buildCard(catalog, offer, kind, i)
		end
		if #offers == 0 then
			C.text(grid, { text = "Nothing here yet", size = "M", sizeU = UDim2.new(1, 0, 0, Space.XXL) })
		end
		paintAffordability()
		grid.CanvasPosition = Vector2.zero
	end

	function self:Open(tab)
		if self.IsOpen then
			if tab and tab ~= currentTab then
				showTab(tab)
			end
			return
		end
		self.IsOpen = true
		popup = C.popup(ctx.layers.window, {
			title = "Shop",
			color = Color.Red,
			onClose = function()
				self.IsOpen = false
				if moneyConn then
					moneyConn:Disconnect()
					moneyConn = nil
				end
			end,
		})
		local catalog = Net.getCatalog()
		local tabRowScroll = C.scroll(popup.Body, { horizontal = true, size = UDim2.new(1, 0, 0, Space.Tab + Space.S), name = "Tabs" })
		C.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, Space.S), SortOrder = Enum.SortOrder.LayoutOrder }, tabRowScroll)
		tabButtons = {}
		for i, t in tabsFor(catalog) do
			tabButtons[t.key] = C.button(tabRowScroll, {
				text = t.text,
				textSize = "S",
				size = UDim2.fromOffset(Space.Touch * 2 + Space.S, Space.Tab),
				order = i,
				onClick = function()
					showTab(t.key)
				end,
			})
		end
		grid = C.grid(popup.Body, CARD_SIZE, { position = UDim2.fromOffset(0, Space.Tab + Space.M), size = UDim2.new(1, 0, 1, -Space.Tab - Space.M) })
		moneyConn = Net.onAttr("Money", paintAffordability)
		showTab(tab or "Buildings")
	end

	function self:Close()
		if popup and not popup.closed then
			popup:Close()
		end
	end

	return self
end

return ShopUI
