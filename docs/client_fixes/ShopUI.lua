local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Theme = require(script.Parent.Theme)
local C = require(script.Parent.Components)
local Net = require(script.Parent.Net)
local Format = require(script.Parent.Format)
local Sound = require(script.Parent.Sound)
local Contract = require(script.Parent.Contract)
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Icons = require(Shared:WaitForChild("Icons"))
local ItemCatalog = require(Shared:WaitForChild("ItemCatalog"))

local Color, Space = Theme.Color, Theme.Space

local ShopUI = {}

local CATEGORY_ORDER = { "siddur", "kiddush_cup", "ornament", "holiday_decor", "menorah", "torah", "chandelier", "ark" }
local CARD_SIZE = UDim2.fromOffset(132, 212)
local TAB = 52

local function clock(seconds)
	seconds = math.max(0, math.floor(seconds))
	return string.format("%d:%02d", seconds // 60, seconds % 60)
end

local function growText(seconds)
	if seconds >= 60 then
		return (seconds // 60) .. "m"
	end
	return seconds .. "s"
end

function ShopUI.new(ctx)
	local self = { IsOpen = false }
	local popup, grid, timerLabel, titleLabel, moneyConn
	local tabButtons, buyButtons = {}, {}
	local currentTab = "siddur"
	local busy = false
	local session = 0

	local function paintAffordability()
		local money = Net.attr("Money", 0)
		for _, entry in buyButtons do
			if entry.price and not entry.soldOut then
				entry.ui:setColor(money >= entry.price and Color.Green or Color.Grey)
			end
		end
	end

	local function categoryItems(catalog, category)
		local list = {}
		for _, item in catalog.items do
			if item.category == category then
				table.insert(list, item)
			end
		end
		return list
	end

	local function buildCard(catalog, offer, order)
		local accent = Theme.rarityColor(offer.rarity, catalog)
		local soldOut = (offer.stock or 0) <= 0
		local card = C.card(grid, { order = order, accent = accent, name = offer.id })
		local frame = card.Frame
		C.modelView(frame, offer.model, {
			size = UDim2.new(1, -Space.S, 0, 84),
			position = UDim2.fromOffset(Space.XS, Space.XS),
			rarity = offer.rarity,
		})
		local rarity = ItemCatalog.rarity(offer.rarity)
		local tag = C.pill(frame, { text = rarity and rarity.name or offer.rarity, color = accent, textSize = "XS" })
		tag.Root.Size = UDim2.fromOffset(0, Space.XL)
		tag.Root.Position = UDim2.fromOffset(Space.XS, Space.XS)
		tag.Root.ZIndex = 4
		if not soldOut then
			local stock = C.pill(frame, { text = "x" .. tostring(offer.stock), color = Color.Panel, textSize = "XS" })
			stock.Root.Size = UDim2.fromOffset(0, Space.XL)
			stock.Root.AnchorPoint = Vector2.new(1, 0)
			stock.Root.Position = UDim2.new(1, -Space.XS, 0, Space.XS)
			stock.Root.ZIndex = 4
		end
		C.text(frame, {
			text = offer.name,
			size = "S",
			wrap = true,
			sizeU = UDim2.new(1, -Space.S, 0, 40),
			position = UDim2.fromOffset(Space.XS, 88),
		})
		C.text(frame, {
			text = string.format("+%d%% income", math.floor((offer.bonus or 0) * 100 + 0.5)),
			size = "XS",
			color = Color.Green,
			sizeU = UDim2.new(1, 0, 0, Space.L),
			position = UDim2.fromOffset(0, 128),
		})
		C.text(frame, {
			text = "grows in " .. growText(offer.grow or 0),
			size = "XS",
			color = Color.Yellow,
			sizeU = UDim2.new(1, 0, 0, Space.L),
			position = UDim2.fromOffset(0, 143),
		})
		local ui
		ui = C.button(frame, {
			text = soldOut and "Sold out" or Format.short(offer.price or 0),
			textSize = "S",
			color = soldOut and Color.Grey or Color.Green,
			size = UDim2.new(1, -Space.S * 2, 0, 36),
			anchor = Vector2.new(0.5, 1),
			position = UDim2.new(0.5, 0, 1, -Space.S),
			onClick = function()
				if soldOut or busy then
					return
				end
				busy = true
				ui:setEnabled(false)
				local res = Net.buy(offer.id)
				busy = false
				if res.ok then
					Sound.play("buy")
				else
					Sound.play("error")
					if res.reason ~= "locked" then
						ctx.toast(Contract.Reasons[res.reason] or Contract.Reasons.default, "error")
					end
				end
				if popup and not popup.closed then
					Net.refreshCatalog()
					self:Show(currentTab)
				end
			end,
		})
		if soldOut then
			ui:setEnabled(false)
		else
			C.new("ImageLabel", {
				Name = "Coin",
				BackgroundTransparency = 1,
				Image = Icons.coin,
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, Space.S, 0.5, 0),
				Size = UDim2.fromOffset(Space.XL, Space.XL),
				ScaleType = Enum.ScaleType.Fit,
				ZIndex = 4,
			}, ui.Hit)
		end
		table.insert(buyButtons, { ui = ui, price = offer.price, soldOut = soldOut })
		if soldOut then
			frame.BackgroundTransparency = 0.25
		end
	end

	function self:Show(tab)
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
		titleLabel.Text = Contract.CategoryNames[tab] or tab
		for index, offer in categoryItems(catalog, tab) do
			buildCard(catalog, offer, index)
		end
		paintAffordability()
		grid.CanvasPosition = Vector2.zero
	end

	local function runTimer(mine)
		task.spawn(function()
			while session == mine and popup and not popup.closed do
				local restockAt = Workspace:GetAttribute("ShopRestockAt") or Net.getCatalog().restockAt or 0
				local remaining = restockAt - Workspace:GetServerTimeNow()
				timerLabel:setText("Restock in " .. clock(remaining))
				if remaining <= -1 then
					Net.refreshCatalog()
					if session == mine and popup and not popup.closed then
						self:Show(currentTab)
						ctx.toast("The shop restocked!", "info")
					end
				end
				task.wait(1)
			end
		end)
	end

	function self:Open(tab)
		if self.IsOpen then
			if tab and tab ~= currentTab then
				self:Show(tab)
			end
			return
		end
		self.IsOpen = true
		session += 1
		local mine = session
		Net.refreshCatalog()
		popup = C.popup(ctx.layers.window, {
			title = "Shop",
			color = Color.Red,
			maxSize = Vector2.new(700, 500),
			onClose = function()
				self.IsOpen = false
				if moneyConn then
					moneyConn:Disconnect()
					moneyConn = nil
				end
			end,
		})
		local top = C.new("Frame", { Name = "Top", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, TAB + Space.XS) }, popup.Body)
		local tabScroll = C.scroll(top, { horizontal = true, size = UDim2.new(1, 0, 1, 0), name = "Tabs" })
		C.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, Space.S), SortOrder = Enum.SortOrder.LayoutOrder }, tabScroll)
		tabButtons = {}
		local present = {}
		for _, item in Net.getCatalog().items do
			present[item.category] = true
		end
		local order = 0
		for _, category in CATEGORY_ORDER do
			if present[category] then
				order += 1
				tabButtons[category] = C.button(tabScroll, {
					image = Icons["item_" .. category],
					color = Color.Blue,
					size = UDim2.fromOffset(TAB + Space.S, TAB),
					order = order,
					name = category,
					onClick = function()
						self:Show(category)
					end,
				})
			end
		end
		local info = C.new("Frame", { Name = "Info", BackgroundTransparency = 1, Position = UDim2.fromOffset(0, TAB + Space.S), Size = UDim2.new(1, 0, 0, Space.XL) }, popup.Body)
		titleLabel = C.text(info, { text = "", size = "M", sizeU = UDim2.new(0.5, 0, 1, 0), alignX = Enum.TextXAlignment.Left })
		local pill = C.pill(info, { text = "", image = Icons.clock, color = Color.Panel, textSize = "S" })
		pill.Root.AnchorPoint = Vector2.new(1, 0.5)
		pill.Root.Position = UDim2.new(1, 0, 0.5, 0)
		timerLabel = pill
		local gridTop = TAB + Space.S + Space.XL + Space.S
		grid = C.grid(popup.Body, CARD_SIZE, { position = UDim2.fromOffset(0, gridTop), size = UDim2.new(1, 0, 1, -gridTop) })
		moneyConn = Net.onAttr("Money", paintAffordability)
		Net.shopSeenEpoch = Workspace:GetAttribute("ShopEpoch") or 0
		Net.ShopSeen:fire()
		runTimer(mine)
		local start = (tab and present[tab]) and tab or (present[currentTab] and currentTab or CATEGORY_ORDER[1])
		self:Show(start)
	end

	function self:Close()
		if popup and not popup.closed then
			popup:Close()
		end
	end

	return self
end

return ShopUI
