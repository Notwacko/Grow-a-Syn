local Theme = require(script.Parent.Theme)
local C = require(script.Parent.Components)
local Net = require(script.Parent.Net)
local Format = require(script.Parent.Format)

local Color, Space = Theme.Color, Theme.Space

local GardenHUD = {}

function GardenHUD.new(ctx)
	local layer = ctx.layers.hud
	local holder = C.new("Frame", {
		Name = "GardenInfo",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(Space.Touch + Space.S * 2 + Space.XS, 88),
		AutomaticSize = Enum.AutomaticSize.XY,
		Size = UDim2.new(),
	}, layer)
	C.new("UIListLayout", { Padding = UDim.new(0, Space.XS), SortOrder = Enum.SortOrder.LayoutOrder }, holder)
	local basket = C.pill(holder, { text = "", color = Color.Orange, order = 1, textSize = "S", name = "Basket" })
	local seeds = C.pill(holder, { text = "", color = Color.Green, order = 2, textSize = "S", name = "Seeds" })
	local weather = C.pill(holder, { text = "", color = Color.Blue, order = 3, textSize = "S", name = "Weather" })
	local restock = C.pill(holder, { text = "", color = Color.Purple, order = 4, textSize = "S", name = "Restock" })

	local function paint()
		local started = Net.attr("TutorialStep", 0) >= 1
		holder.Visible = started
		if not started then
			return
		end
		basket:setText(("🧺 %d  $%s"):format(Net.attr("BasketCount", 0), Format.short(Net.attr("BasketValue", 0))))
		seeds:setText(("🌱 %d seeds"):format(Net.attr("Seeds", 0)))
		local id = workspace:GetAttribute("Weather") or "clear"
		local left = (workspace:GetAttribute("WeatherEndsAt") or 0) - workspace:GetServerTimeNow()
		if id == "rain" and left > 0 then
			weather:setText("🌧 Rain  " .. Format.clock(left))
		elseif id == "sunny" and left > 0 then
			weather:setText("☀ Sunshine  " .. Format.clock(left))
		else
			weather:setText("⛅ Clear skies")
		end
		local untilRestock = (workspace:GetAttribute("GardenRestockAt") or 0) - workspace:GetServerTimeNow()
		restock:setText("🛒 Seeds restock  " .. Format.clock(math.max(0, untilRestock)))
	end

	for _, name in { "BasketCount", "BasketValue", "Seeds", "TutorialStep" } do
		Net.onAttr(name, paint)
	end
	workspace:GetAttributeChangedSignal("Weather"):Connect(paint)
	paint()
	task.spawn(function()
		while holder.Parent do
			task.wait(1)
			paint()
		end
	end)
	return { Root = holder }
end

return GardenHUD
