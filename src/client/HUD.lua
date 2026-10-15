local TweenService = game:GetService("TweenService")

local Theme = require(script.Parent.Theme)
local C = require(script.Parent.Components)
local Net = require(script.Parent.Net)
local Format = require(script.Parent.Format)
local Sound = require(script.Parent.Sound)
local Contract = require(script.Parent.Contract)
local FloatingNumbers = require(script.Parent.FloatingNumbers)
local Icons = require(script.Parent.IconSet)

local Color, Space = Theme.Color, Theme.Space

local HUD = {}

local MARGIN = Space.S
local BUTTON = 48

function HUD.new(ctx, hooks)
	local layer = ctx.layers.hud
	local catalog = Net.getCatalog()
	local upgrades = catalog.upgrades or {}
	local self = { targets = {} }

	local topLeft = C.new("Frame", {
		Name = "MoneyBlock",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(MARGIN, MARGIN),
		AutomaticSize = Enum.AutomaticSize.XY,
		Size = UDim2.new(),
	}, layer)
	C.new("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, topLeft)
	local moneyPill = C.pill(topLeft, { text = "0", image = Icons.coin, color = Color.Green, order = 1, textSize = "M", name = "Money" })
	local rate = C.text(topLeft, { text = "", size = "XS", sizeU = UDim2.new(0, 140, 0, Space.L), order = 2, alignX = Enum.TextXAlignment.Left, name = "Rate" })
	self.targets.Money = moneyPill.Root
	local boostPill = C.pill(topLeft, { text = "", color = Color.Orange, order = 3, textSize = "S", name = "Boost" })
	boostPill.Root.Visible = false
	local function refreshBoost()
		local remaining = Net.attr("BoostEndsAt", 0) - workspace:GetServerTimeNow()
		if remaining > 0 then
			boostPill.Root.Visible = true
			boostPill:setText(("x%s  %s"):format(tostring(Net.attr("BoostMult", 2)), Format.clock(remaining)))
		else
			boostPill.Root.Visible = false
		end
	end
	local boostTimerRunning = false
	local function startBoostTimer()
		refreshBoost()
		if boostTimerRunning or not boostPill.Root.Visible then
			return
		end
		boostTimerRunning = true
		task.spawn(function()
			while boostPill.Root.Visible do
				task.wait(1)
				refreshBoost()
			end
			boostTimerRunning = false
		end)
	end
	Net.onAttr("BoostEndsAt", startBoostTimer)
	Net.onAttr("BoostMult", startBoostTimer)
	startBoostTimer()
	self.moneyPill = moneyPill

	local top = C.new("Frame", {
		Name = "Ladder",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, MARGIN),
		Size = UDim2.new(0, 280, 0, Space.L + Space.L),
	}, layer)
	local ladder = C.segmentedBar(top, { size = UDim2.new(1, 0, 0, Space.L) })
	local stageText = C.text(top, { text = "", size = "XS", sizeU = UDim2.new(1, 0, 0, Space.L), position = UDim2.fromOffset(0, Space.L), name = "Stage" })

	local left = C.new("Frame", {
		Name = "LeftStack",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(MARGIN, MARGIN + Space.XXL + Space.XL + Space.S),
		AutomaticSize = Enum.AutomaticSize.XY,
		Size = UDim2.new(),
	}, layer)
	C.new("UIListLayout", { Padding = UDim.new(0, Space.S), SortOrder = Enum.SortOrder.LayoutOrder }, left)
	local function iconButton(name, image, color, order, onClick, visible, fallback)
		local cell = C.new("Frame", {
			Name = name,
			BackgroundTransparency = 1,
			Size = UDim2.fromOffset(BUTTON, BUTTON + 4),
			LayoutOrder = order,
			Visible = visible ~= false,
		}, left)
		C.button(cell, { image = image, text = not image and fallback or nil, textSize = "S", color = color, size = UDim2.fromOffset(BUTTON, BUTTON), onClick = onClick, name = name })
		return cell
	end
	local shop = iconButton("Shop", Icons.shop, Color.Red, 1, function()
		hooks.openShop()
	end, true, "Shop")
	iconButton("Items", Icons.backpack, Color.Orange, 2, function()
		hooks.openInventory()
	end, true, "Items")
	local land = iconButton("Land", Icons.land, Color.Green, 3, function()
		hooks.openLand()
	end, true, "Land")
	local upgrade = iconButton("Upgrade", Icons.upgrade, Color.Purple, 4, function()
		hooks.openUpgrade()
	end, false, "Up")
	self.targets.Shop = shop
	self.targets.Land = land
	self.targets.Upgrade = upgrade

	local bottom = C.new("Frame", {
		Name = "Bottom",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -MARGIN),
		Size = UDim2.new(0, 300, 0, Space.XL + Space.XS),
	}, layer)
	local bar = C.progressBar(bottom, { size = UDim2.fromScale(1, 1), color = Color.Green, name = "CongregationBar" })
	bar.Label.Position = UDim2.fromOffset(Icons.people and Space.L or 0, 0)
	if Icons.people then
	C.new("ImageLabel", {
		Name = "People",
		BackgroundTransparency = 1,
		Image = Icons.people,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, Space.XS, 0.5, 0),
		Size = UDim2.fromOffset(Space.XL, Space.XL),
		ScaleType = Enum.ScaleType.Fit,
		ZIndex = 4,
	}, bar.Root)
	end
	self.targets.Congregation = bar.Root

	local shown = Instance.new("NumberValue")
	shown.Value = Net.attr("Money", 0)
	local function paintMoney(value)
		moneyPill:setText(Format.short(value))
	end
	shown.Changed:Connect(paintMoney)
	paintMoney(shown.Value)
	local lastMoney = shown.Value
	local pop = C.new("UIScale", { Name = "Pop", Scale = 1 }, moneyPill.Root)
	local pulses = {}
	local function setPulse(key, target, on)
		if on and not pulses[key] then
			pulses[key] = C.pulse(target, 1.1)
		elseif not on and pulses[key] then
			pulses[key]()
			pulses[key] = nil
		end
	end
	local function refreshAffordable()
		local money = Net.attr("Money", 0)
		local done = Net.attr("TutorialStep", 0) >= Contract.Step.Done
		local landCost = Contract.LAND_COSTS[Net.attr("LandTier", 1)]
		setPulse("land", land, done and Net.attr("PlotId", 0) > 0 and landCost ~= nil and money >= landCost)
		local info = upgrades[Net.attr("Tier", 1) + 1]
		local chosen = (Net.attr("Denomination", "") or "") ~= ""
		setPulse("upgrade", upgrade, done and chosen and info ~= nil and info.cost ~= nil and money >= info.cost)
	end
	Net.onAttr("Money", function(value)
		value = value or 0
		TweenService:Create(shown, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Value = value }):Play()
		if value > lastMoney then
			FloatingNumbers.spawn("+" .. Format.short(value - lastMoney))
			pop.Scale = 1.12
			C.tween(pop, 0.3, { Scale = 1 }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		end
		lastMoney = value
		refreshAffordable()
	end)
	for _, name in { "LandTier", "Tier", "TutorialStep", "Denomination", "PlotId" } do
		Net.onAttr(name, refreshAffordable)
	end
	refreshAffordable()

	local function refreshBar()
		local n = Net.attr("Congregation", 0)
		local max = Net.attr("MaxCongregation", 12)
		if Net.attr("HasMinyan", false) then
			bar:set(n, max, ("%d / %d"):format(n, max), Color.Green)
		else
			bar:set(n, Contract.MINYAN, ("%d / %d  minyan"):format(n, Contract.MINYAN), Color.Orange)
		end
		local perSecond = Net.attr("MoneyPerSecond", 0)
		rate.Text = perSecond > 0 and ("+%s per second"):format(Format.short(perSecond)) or ""
	end
	local lastN = Net.attr("Congregation", 0)
	for _, name in { "Congregation", "MaxCongregation", "HasMinyan", "MoneyPerSecond" } do
		Net.onAttr(name, function()
			local n = Net.attr("Congregation", 0)
			if name == "Congregation" and n > lastN then
				Sound.play("greet")
			end
			lastN = n
			refreshBar()
		end)
	end
	refreshBar()

	local function refreshLadder()
		local denId = Net.attr("Denomination", "")
		local den = catalog.denById[denId]
		local has = den ~= nil
		top.Visible = has
		upgrade.Visible = denId ~= ""
		if has then
			local index = math.clamp(Net.attr("Tier", 1) - 1, 0, #den.stages)
			ladder:setCurrent(index > 0 and index or nil)
			stageText.Text = index > 0 and den.stages[index] or den.name
		end
	end
	for _, name in { "Denomination", "Tier", "HasMinyan" } do
		Net.onAttr(name, refreshLadder)
	end
	refreshLadder()

	return self
end

return HUD
