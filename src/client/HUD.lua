-- Left icon stack, right boost stack, top ladder + money, bottom progress + quick buttons.
local TweenService = game:GetService("TweenService")

local Theme = require(script.Parent.Theme)
local C = require(script.Parent.Components)
local Net = require(script.Parent.Net)
local Format = require(script.Parent.Format)
local Sound = require(script.Parent.Sound)
local Contract = require(script.Parent.Contract)
local FloatingNumbers = require(script.Parent.FloatingNumbers)

local Color, Space = Theme.Color, Theme.Space

local HUD = {}

local SIDE_MARGIN = Space.S
local STACK_TOP = 88
local BOTTOM_RESERVED = 140

function HUD.new(ctx, hooks)
	local layer = ctx.layers.hud
	local catalog = Net.getCatalog()
	local self = { targets = {} }

	---------------------------------------------------------------- top: ladder + pills
	local top = C.new("Frame", {
		Name = "Top",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, Space.S),
		Size = UDim2.new(1, -(Space.Touch + Space.S) * 2 - Space.S * 2, 0, Space.XL + Space.XS + Space.XXL),
	}, layer)
	C.new("UISizeConstraint", { MaxSize = Vector2.new(400, 1000) }, top)
	local ladder = C.segmentedBar(top, { size = UDim2.new(1, 0, 0, Space.XL) })
	local pills = C.row(top, {
		position = UDim2.fromOffset(0, Space.XL + Space.XS),
		size = UDim2.new(1, 0, 0, Space.XXL),
		alignX = Enum.HorizontalAlignment.Center,
		name = "Pills",
	})
	local moneyPill = C.pill(pills, { text = "💰 0", color = Color.Green, order = 1, textSize = "M" })
	local stagePill = C.pill(pills, { text = "", color = Color.Purple, order = 2, textSize = "S" })
	self.targets.Money = moneyPill.Root
	self.moneyPill = moneyPill

	---------------------------------------------------------------- left stack
	local left = C.new("Frame", {
		Name = "LeftStack",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(SIDE_MARGIN, STACK_TOP),
		AutomaticSize = Enum.AutomaticSize.XY,
		Size = UDim2.new(),
	}, layer)
	local grid = C.new("UIGridLayout", {
		CellSize = UDim2.fromOffset(Space.Touch + Space.S, Space.Touch + Space.XS + Space.L),
		CellPadding = UDim2.fromOffset(Space.XS, Space.XS),
		FillDirection = Enum.FillDirection.Vertical,
		SortOrder = Enum.SortOrder.LayoutOrder,
		FillDirectionMaxCells = 4,
	}, left)
	local shopBtn = C.iconButton(left, { icon = "🛒", label = "Shop", color = Color.Red, order = 1, name = "Shop", onClick = function() hooks.openShop() end })
	local itemsBtn = C.iconButton(left, { icon = "🎒", label = "Items", color = Color.Yellow, order = 2, name = "Items", onClick = function() hooks.openInventory() end })
	local landBtn = C.iconButton(left, { icon = "🌳", label = "Land", color = Color.Green, order = 3, name = "Land", onClick = function() hooks.openLand() end })
	local upgradeBtn = C.iconButton(left, { icon = "⬆", label = "Upgrade", color = Color.Purple, order = 4, name = "Upgrade", visible = false, onClick = function() hooks.openUpgrade() end })
	self.targets.Shop = shopBtn.Root

	local function relayout()
		local design = ctx.designSize()
		local cell = Space.Touch + Space.XS + Space.L + Space.XS
		local fit = math.floor((design.Y - STACK_TOP - BOTTOM_RESERVED) / cell)
		grid.FillDirectionMaxCells = math.clamp(fit, 2, 4)
	end
	ctx.onResize(relayout)
	relayout()

	---------------------------------------------------------------- right stack: boosts
	local right = C.new("Frame", {
		Name = "RightStack",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -SIDE_MARGIN, 0, STACK_TOP),
		AutomaticSize = Enum.AutomaticSize.XY,
		Size = UDim2.new(),
	}, layer)
	C.new("UIListLayout", {
		Padding = UDim.new(0, Space.XS),
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
	}, right)
	local boostButtons = {}
	local boostColors = { Color.Orange, Color.Red, Color.Purple }
	for i, boost in catalog.boosts do
		if i > 3 then
			break
		end
		local b = C.boostButton(right, {
			label = "x" .. tostring(boost.mult),
			price = boost.robux,
			free = boost.free,
			color = boostColors[i],
			order = i,
			name = "Boost" .. i,
			onClick = function()
				hooks.openShop("Boosts")
			end,
		})
		boostButtons[i] = { ui = b, boost = boost }
	end

	local countdownRunning = false
	local function refreshBoosts()
		local endsAt = Net.attr("BoostEndsAt", 0)
		local mult = Net.attr("BoostMult", 1)
		local remaining = endsAt - workspace:GetServerTimeNow()
		for _, entry in boostButtons do
			local active = remaining > 0 and entry.boost.mult == mult
			entry.ui:setTimer(active and Format.clock(remaining) or "")
		end
		if remaining > 0 and not countdownRunning then
			countdownRunning = true
			task.spawn(function()
				while Net.attr("BoostEndsAt", 0) - workspace:GetServerTimeNow() > 0 do
					task.wait(1)
					refreshBoosts()
				end
				countdownRunning = false
				refreshBoosts()
			end)
		end
	end
	Net.onAttr("BoostEndsAt", refreshBoosts)
	Net.onAttr("BoostMult", refreshBoosts)
	refreshBoosts()

	---------------------------------------------------------------- bottom
	local bottom = C.new("Frame", {
		Name = "Bottom",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -Space.S),
		Size = UDim2.new(1, -(Space.Touch + Space.S) * 2 - Space.S * 2, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
	}, layer)
	C.new("UISizeConstraint", { MaxSize = Vector2.new(400, 1000) }, bottom)
	C.new("UIListLayout", {
		Padding = UDim.new(0, Space.XS),
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
	}, bottom)
	local stats = C.text(bottom, { text = "", size = "S", sizeU = UDim2.new(1, 0, 0, Space.XL), order = 1, name = "Stats" })
	local bar = C.progressBar(bottom, { size = UDim2.new(1, 0, 0, Space.XXL), color = Color.Green, name = "CongregationBar" })
	bar.Root.LayoutOrder = 2
	self.targets.Congregation = bar.Root
	local quick = C.row(bottom, { size = UDim2.new(1, 0, 0, Space.Touch + Space.XS), order = 3, alignX = Enum.HorizontalAlignment.Center, name = "Quick" })
	C.quickButton(quick, { icon = "🛍", color = Color.Red, order = 1, onClick = function() hooks.openShop("Buildings") end })
	C.quickButton(quick, { icon = "🧩", color = Color.Yellow, order = 2, onClick = function() hooks.openInventory(true) end })
	C.quickButton(quick, { icon = "⚡", color = Color.Blue, order = 3, onClick = function() hooks.openShop("Boosts") end })
	local pickerQuick = C.quickButton(quick, { icon = "🕍", color = Color.Purple, order = 4, onClick = function() hooks.openPicker() end })

	---------------------------------------------------------------- attribute bindings
	local shown = Instance.new("NumberValue")
	shown.Value = Net.attr("Money", 0)
	local function paintMoney(value)
		moneyPill:setText("💰 " .. Format.short(value))
	end
	shown.Changed:Connect(paintMoney)
	paintMoney(shown.Value)
	local lastMoney = shown.Value
	Net.onAttr("Money", function(value)
		value = value or 0
		TweenService:Create(shown, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Value = value }):Play()
		if value > lastMoney then
			FloatingNumbers.spawn("+" .. Format.short(value - lastMoney))
		end
		lastMoney = value
	end)

	local function refreshBar()
		local n = Net.attr("Congregation", 0)
		local max = Net.attr("MaxCongregation", 12)
		if Net.attr("HasMinyan", false) then
			bar:set(n, max, ("👥 %d / %d"):format(n, max), Color.Green)
		else
			bar:set(n, Contract.MINYAN, ("👥 %d / %d  Minyan"):format(n, Contract.MINYAN), Color.Orange)
		end
		stats.Text = ("💰 %s/s    🪑 %d seats"):format(Format.short(Net.attr("MoneyPerSecond", 0)), max)
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

	local stopPulse
	local function refreshLadder()
		local denId = Net.attr("Denomination", "")
		local den = catalog.denById[denId]
		local has = den ~= nil
		ladder.Root.Visible = has
		stagePill.Root.Visible = has
		upgradeBtn.Root.Visible = denId ~= ""
		if has then
			local index = math.clamp(Net.attr("Tier", 1) - 1, 0, #den.stages)
			ladder:setCurrent(index > 0 and index or nil)
			stagePill:setText(index > 0 and den.stages[index] or den.name)
		end
		-- gently pulse the denomination shortcut while a minyan is waiting for a choice
		local waiting = Net.attr("HasMinyan", false) and denId == ""
		if waiting and not stopPulse then
			stopPulse = C.pulse(pickerQuick.Root, 1.1)
		elseif not waiting and stopPulse then
			stopPulse()
			stopPulse = nil
		end
	end
	for _, name in { "Denomination", "Tier", "HasMinyan" } do
		Net.onAttr(name, refreshLadder)
	end
	refreshLadder()

	return self
end

return HUD
