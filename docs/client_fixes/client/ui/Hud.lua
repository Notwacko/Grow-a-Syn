local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Theme = require(script.Parent.Theme)
local Ui = require(script.Parent.Ui)
local Util = require(script.Parent.Util)
local Store = require(script.Parent.Store)
local Sfx = require(script.Parent.Sfx)
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Balance = require(Shared:WaitForChild("Balance"))
local Constants = require(Shared:WaitForChild("Constants"))

local Hud = {}

local STEP = Constants.TUTORIAL

function Hud.start(root, actions)
	local hud = { buttons = {}, dots = {} }
	local touch = Ui.touch
	local buttonSize = touch and 58 or 68

	local moneyPill = Ui.frame(root, {
		name = "MoneyPill",
		size = UDim2.fromOffset(286, 62),
		position = UDim2.fromOffset(16, 12),
		color = Theme.ink,
		transparency = 0,
		radius = 31,
		stroke = 4,
		z = 3,
	})
	Ui.gradient(moneyPill, { Color3.fromRGB(52, 66, 112), Color3.fromRGB(30, 42, 74) }, 90)
	Ui.image(moneyPill, { image = "coins", size = UDim2.fromOffset(52, 52), position = UDim2.new(0, 6, 0.5, 0), anchor = Vector2.new(0, 0.5), z = 5 })
	local moneyLabel = Ui.label(moneyPill, {
		name = "Money",
		text = "0",
		textSize = 36,
		size = UDim2.new(1, -78, 1, 0),
		position = UDim2.fromOffset(66, 0),
		xalign = Enum.TextXAlignment.Left,
		color = Theme.gold[1],
		stroke = 3,
		fit = true,
		z = 5,
	})
	local rateLabel = Ui.label(root, {
		name = "Rate",
		text = "",
		textSize = 20,
		size = UDim2.fromOffset(280, 24),
		position = UDim2.fromOffset(30, 78),
		xalign = Enum.TextXAlignment.Left,
		color = Theme.green[1],
		stroke = 3,
		z = 3,
	})
	rateLabel.Font = Theme.titleFont

	local chipRow = Ui.frame(root, {
		name = "Chips",
		size = UDim2.fromOffset(380, 34),
		position = UDim2.fromOffset(316, 28),
		z = 3,
	})
	Ui.make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, chipRow)
	hud.chips = {}
	local function chip(key, icon, palette)
		local pill = Ui.frame(chipRow, {
			name = key,
			size = UDim2.fromOffset(122, 32),
			color = Color3.new(1, 1, 1),
			transparency = 0,
			radius = 16,
			stroke = 3,
			visible = false,
			z = 4,
		})
		Ui.gradient(pill, palette, 90)
		Ui.image(pill, { image = icon, size = UDim2.fromOffset(24, 24), position = UDim2.new(0, 5, 0.5, 0), anchor = Vector2.new(0, 0.5), z = 6 })
		local label = Ui.label(pill, { text = "", textSize = 18, size = UDim2.new(1, -36, 1, 0), position = UDim2.fromOffset(32, 0), stroke = 2.5, fit = true, z = 6 })
		hud.chips[key] = { pill = pill, label = label }
	end
	chip("festival", "bolt", Theme.orange)
	chip("lamp", "seed", Theme.green)
	chip("event", "sun", Theme.gold)
	chip("friends", "heart", Theme.red)

	local function makeButton(parent, key, props)
		local button = Ui.iconButton(parent, {
			name = key,
			icon = props.icon,
			palette = props.palette,
			size = buttonSize,
			label = not touch and props.label or nil,
			order = props.order,
			onClick = props.onClick,
		})
		hud.buttons[key] = button
		return button
	end

	local leftRail = Ui.frame(root, {
		name = "LeftRail",
		size = UDim2.fromOffset(buttonSize + 12, 420),
		position = UDim2.fromOffset(16, touch and 118 or 150),
		z = 3,
	})
	Ui.make("UIListLayout", { Padding = UDim.new(0, touch and 10 or 28), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Left }, leftRail)
	makeButton(leftRail, "shop", { icon = "shop", palette = Theme.red, label = "Shop", order = 1, onClick = function() actions.open("shop") end })
	makeButton(leftRail, "items", { icon = "backpack", palette = Theme.orange, label = "Items", order = 2, onClick = function() actions.open("items") end })
	makeButton(leftRail, "pets", { icon = "paw", palette = Theme.green, label = "Pets", order = 3, onClick = function() actions.open("pets") end })
	makeButton(leftRail, "wardrobe", { icon = "wardrobe", palette = Theme.purple, label = "Style", order = 4, onClick = function() actions.open("wardrobe") end })

	local rightRail = Ui.frame(root, {
		name = "RightRail",
		size = UDim2.fromOffset(buttonSize + 12, 560),
		position = UDim2.new(1, -(buttonSize + 28), 0, 12),
		z = 3,
	})
	Ui.make("UIListLayout", { Padding = UDim.new(0, touch and 10 or 28), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Center }, rightRail)
	makeButton(rightRail, "quests", { icon = "quest", palette = Theme.blue, label = "Quests", order = 1, onClick = function() actions.open("quests") end })
	makeButton(rightRail, "daily", { icon = "gift", palette = Theme.gold, label = "Daily", order = 2, onClick = function() actions.popup("daily") end })
	makeButton(rightRail, "wheel", { icon = "wheel", palette = Theme.teal, label = "Wheel", order = 3, onClick = function() actions.popup("wheel") end })
	makeButton(rightRail, "book", { icon = "book", palette = Theme.purple, label = "Book", order = 4, onClick = function() actions.open("book") end })
	makeButton(rightRail, "store", { icon = "gem", palette = Theme.navy, label = "Store", order = 5, onClick = function() actions.open("store") end })

	local function dot(key, color)
		local button = hud.buttons[key]
		local badge, text = Ui.badge(button.root, { size = 24, text = "", color = color or Theme.red[1], position = UDim2.new(1, 2, 0, 0) })
		badge.Visible = false
		hud.dots[key] = { badge = badge, text = text }
	end
	for _, key in { "shop", "items", "pets", "wardrobe", "quests", "daily", "wheel", "book", "store" } do
		dot(key)
	end

	function hud.setDot(key, value)
		local entry = hud.dots[key]
		if not entry then
			return
		end
		if value == nil or value == false or value == 0 then
			entry.badge.Visible = false
		else
			entry.badge.Visible = true
			entry.text.Text = type(value) == "number" and tostring(value) or "!"
			if type(value) ~= "number" then
				entry.text.Text = "!"
			end
		end
	end

	local bottom = Ui.frame(root, {
		name = "Bottom",
		size = UDim2.fromOffset(800, 120),
		position = UDim2.new(0.5, 0, 1, -8),
		anchor = Vector2.new(0.5, 1),
		z = 3,
	})
	local congBar = Ui.bar(bottom, {
		name = "Congregation",
		size = UDim2.fromOffset(300, 40),
		position = UDim2.new(0.5, 0, 1, -4),
		anchor = Vector2.new(0.5, 1),
		palette = Theme.green,
		height = 40,
		textSize = 22,
	})
	local landButton = Ui.button(bottom, {
		name = "Land",
		palette = Theme.teal,
		size = UDim2.fromOffset(240, touch and 52 or 60),
		position = UDim2.new(0.5, -166, 1, -2),
		anchor = Vector2.new(1, 1),
		icon = "land",
		iconSize = 36,
		text = "Land",
		textSize = 22,
		onClick = function()
			actions.land()
		end,
	})
	local upgradeButton = Ui.button(bottom, {
		name = "Upgrade",
		palette = Theme.green,
		size = UDim2.fromOffset(240, touch and 52 or 60),
		position = UDim2.new(0.5, 166, 1, -2),
		anchor = Vector2.new(0, 1),
		icon = "upgrade",
		iconSize = 36,
		text = "Upgrade",
		textSize = 22,
		onClick = function()
			actions.upgrade()
		end,
	})
	local goalBar = Ui.bar(bottom, {
		name = "Goal",
		size = UDim2.fromOffset(240, 18),
		position = UDim2.new(0.5, 166, 1, -70),
		anchor = Vector2.new(0, 1),
		height = 18,
		palette = Theme.gold,
		text = "",
	})
	goalBar.root.Visible = false
	local legacyButton = Ui.button(bottom, {
		name = "Legacy",
		palette = Theme.gold,
		size = UDim2.fromOffset(230, 52),
		position = UDim2.new(0.5, 0, 1, -62),
		anchor = Vector2.new(0.5, 1),
		icon = "legacy",
		iconSize = 36,
		text = "Begin Legacy",
		textSize = 22,
		visible = false,
		onClick = function()
			actions.open("legacy")
		end,
	})
	hud.legacyButton = legacyButton
	local stopLegacyPulse

	local function updateMoney(value)
		local current = tonumber(moneyLabel:GetAttribute("Shown")) or 0
		moneyLabel:SetAttribute("Shown", value)
		if math.abs(value - current) > 0.5 then
			if value > current and value - current > math.max(current * 0.001, 1) then
				Ui.pop(moneyPill, 1.04)
			end
			Ui.count(moneyLabel, current, value, Util.short, 0.4)
		else
			moneyLabel.Text = Util.short(value)
		end
		hud.refreshButtons()
	end

	local function updateRate()
		local rate = Store.attr("MoneyPerSecond", 0)
		rateLabel.Text = rate > 0 and string.format("+%s / sec", Util.short(rate)) or ""
	end

	local function updateCongregation()
		local count = Store.attr("Congregation", 0)
		local max = Store.attr("MaxCongregation", 12)
		local hasMinyan = Store.attr("HasMinyan", false)
		if not hasMinyan then
			congBar.set(count / Constants.MINYAN_SIZE, string.format("Minyan %d / %d", count, Constants.MINYAN_SIZE))
			congBar.setPalette(Theme.orange)
		else
			congBar.set(count / max, string.format("Congregation %d / %d", count, max))
			congBar.setPalette(Theme.green)
		end
	end

	function hud.refreshButtons()
		local money = Store.attr("Money", 0)
		local done = Store.attr("TutorialStep", 0) >= STEP.DONE
		local hasPlot = Store.attr("PlotId", 0) > 0
		local landTier = Store.attr("LandTier", 1)
		local landCost = Balance.landCost(landTier)
		landButton.root.Visible = done and hasPlot and landCost ~= nil
		if landCost then
			landButton.setText("Land " .. Util.short(landCost))
			landButton.setPalette(money >= landCost and Theme.teal or Theme.gray)
			hud.landReady = money >= landCost
		end
		local tier = Store.attr("Tier", 1)
		local denomination = Store.attr("Denomination", "")
		local hasMinyan = Store.attr("HasMinyan", false)
		local showUpgrade = done and hasPlot
		upgradeButton.root.Visible = showUpgrade and tier < Constants.MAX_TIER
		goalBar.root.Visible = false
		if showUpgrade and tier < Constants.MAX_TIER then
			if denomination == "" then
				upgradeButton.setText("Choose Faith")
				upgradeButton.setPalette(Theme.purple)
			else
				local cost = Balance.tierCost(tier + 1)
				local landOk = landTier >= tier
				upgradeButton.setText("Upgrade " .. Util.short(cost or 0))
				upgradeButton.setPalette((money >= (cost or math.huge) and landOk) and Theme.green or Theme.gray)
				goalBar.root.Visible = true
				goalBar.set(money / math.max(cost or 1, 1), landOk and (Util.short(money) .. " / " .. Util.short(cost or 0)) or "Needs more land")
			end
		end
		local legacy = Store.get("legacy")
		local showLegacy = done and legacy ~= nil and legacy.unlocked and legacy.gain >= 1
		legacyButton.root.Visible = showLegacy == true
		if showLegacy and not stopLegacyPulse then
			stopLegacyPulse = Ui.pulse(legacyButton.root, 1.06)
		elseif not showLegacy and stopLegacyPulse then
			stopLegacyPulse()
			stopLegacyPulse = nil
		end
		if showLegacy then
			legacyButton.setText("Legacy +" .. Util.short(legacy.gain))
		end
	end

	local function updateVisibility()
		local step = Store.attr("TutorialStep", 0)
		local early = step < STEP.BUY
		hud.buttons.pets.root.Visible = step >= STEP.DONE
		hud.buttons.wardrobe.root.Visible = step >= STEP.DONE
		hud.buttons.quests.root.Visible = step >= STEP.DONE
		hud.buttons.daily.root.Visible = step >= STEP.DONE
		hud.buttons.wheel.root.Visible = step >= STEP.DONE
		hud.buttons.book.root.Visible = step >= STEP.DONE
		hud.buttons.store.root.Visible = step >= STEP.DONE
		hud.buttons.items.root.Visible = step >= STEP.BUY
		hud.buttons.shop.root.Visible = step >= STEP.BUY
		congBar.root.Visible = step >= STEP.GREET
		rateLabel.Visible = step >= STEP.MINYAN
		hud.refreshButtons()
		return early
	end

	function hud.updateTimers()
		local now = Store.now()
		local boosts = Store.get("boosts")
		local festival = boosts and boosts.festivalEnds or 0
		local lamp = boosts and boosts.lampEnds or 0
		local function setChip(key, remaining, prefix)
			local entry = hud.chips[key]
			entry.pill.Visible = remaining > 0
			if remaining > 0 then
				entry.label.Text = prefix .. " " .. Util.clock(remaining)
			end
		end
		setChip("festival", festival - now, "x2")
		setChip("lamp", lamp - now, "Grow")
		local friends = Store.attr("FriendsBonus", 0)
		hud.chips.friends.pill.Visible = friends > 0
		if friends > 0 then
			hud.chips.friends.label.Text = "Friends +" .. math.floor(friends * 100 + 0.5) .. "%"
		end
		local eventMult = Store.world("EventMult", 1)
		hud.chips.event.pill.Visible = eventMult > 1
		if eventMult > 1 then
			hud.chips.event.label.Text = "Event x" .. tostring(eventMult)
		end
	end

	Store.onAttr("Money", updateMoney)
	Store.onAttr("MoneyPerSecond", updateRate)
	for _, name in { "Congregation", "MaxCongregation", "HasMinyan" } do
		Store.onAttr(name, updateCongregation)
	end
	for _, name in { "TutorialStep", "Tier", "Denomination", "LandTier", "PlotId" } do
		Store.onAttr(name, updateVisibility)
	end
	Store.on("legacy", hud.refreshButtons)
	Store.on("boosts", hud.updateTimers)

	local function updateDots()
		local quests = Store.get("quests")
		if quests then
			local ready = 0
			for _, list in { quests.daily, quests.weekly } do
				for _, entry in list do
					if entry.prog >= entry.goal and not entry.claimed then
						ready += 1
					end
				end
			end
			hud.setDot("quests", ready)
		end
		local daily = Store.get("daily")
		hud.setDot("daily", daily and daily.canClaim and Store.now() >= (daily.nextAt or 0) or false)
		local spin = Store.get("spin")
		hud.setDot("wheel", spin and spin.canSpin and Store.now() >= (spin.nextAt or 0) or false)
		local collection = Store.get("collection")
		if collection then
			local ready = 0
			for _, milestone in collection.milestones do
				if milestone.ready and not milestone.claimed then
					ready += 1
				end
			end
			hud.setDot("book", ready)
		end
	end
	Store.sectionChanged:connect(function()
		updateDots()
	end)

	task.spawn(function()
		while root.Parent do
			task.wait(1)
			hud.updateTimers()
			updateDots()
			local epochAt = Store.attr("ShopRestockAt", 0)
			local seen = hud.shopSeenEpoch or Store.attr("ShopEpoch", 0)
			if Store.attr("ShopEpoch", 0) ~= seen and Store.attr("TutorialStep", 0) >= STEP.BUY then
				hud.setDot("shop", true)
			end
			rateLabel.Visible = rateLabel.Visible
			epochAt = epochAt
		end
	end)

	function hud.markShopSeen()
		hud.shopSeenEpoch = Store.attr("ShopEpoch", 0)
		hud.setDot("shop", false)
	end

	function hud.highlight(key, on)
		local button = hud.buttons[key]
		if not button then
			return
		end
		hud.pulses = hud.pulses or {}
		if on and not hud.pulses[key] then
			hud.pulses[key] = Ui.pulse(button.root, 1.1, 0.45)
		elseif not on and hud.pulses[key] then
			hud.pulses[key]()
			hud.pulses[key] = nil
		end
	end

	function hud.setVisible(value)
		for _, child in root:GetChildren() do
			if child:IsA("GuiObject") then
				child.Visible = value
			end
		end
		if value then
			updateVisibility()
			hud.updateTimers()
		end
	end

	hud.root = root
	hud.moneyPill = moneyPill
	hud.landButton = landButton
	hud.upgradeButton = upgradeButton
	hud.congBar = congBar
	moneyLabel.Text = Util.short(Store.attr("Money", 0))
	moneyLabel:SetAttribute("Shown", Store.attr("Money", 0))
	updateRate()
	updateCongregation()
	updateVisibility()
	hud.updateTimers()
	return hud
end

return Hud
