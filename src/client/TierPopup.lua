-- Big popup with a sparkle burst when the building reaches a new tier. Old/new values come from attributes.
local Net = require(script.Parent.Net)
local Theme = require(script.Parent.Theme)
local C = require(script.Parent.Components)
local Format = require(script.Parent.Format)
local Sound = require(script.Parent.Sound)

local Color, Space = Theme.Color, Theme.Space

local TierPopup = {}

function TierPopup.watch(ctx)
	local catalog = Net.getCatalog()
	local stable = { seats = Net.attr("MaxCongregation", 12), mps = Net.attr("MoneyPerSecond", 0) }
	local lastTier = Net.attr("Tier", 1)
	Net.onAttr("Tier", function(tier)
		tier = tier or 1
		local before = lastTier
		lastTier = tier
		if tier <= before then
			stable = { seats = Net.attr("MaxCongregation", 12), mps = Net.attr("MoneyPerSecond", 0) }
			return
		end
		task.delay(0.6, function() -- let MaxCongregation / MoneyPerSecond settle
			local seats = Net.attr("MaxCongregation", stable.seats)
			local mps = Net.attr("MoneyPerSecond", stable.mps)
			local den = catalog.denById[Net.attr("Denomination", "")]
			local name = den and den.stages[tier - 1] or ("Tier " .. tier)
			local popup = C.popup(ctx.layers.popup, {
				title = "NEW TIER!",
				color = Color.Orange,
				size = UDim2.new(1, -Space.XL * 2, 0, 240),
				maxSize = Vector2.new(420, 240),
			})
			C.text(popup.Body, { text = name, size = "L", sizeU = UDim2.new(1, 0, 0, Space.XXL) })
			C.text(popup.Body, {
				text = ("Seats  %d > %d"):format(stable.seats, seats),
				size = "M",
				color = Color.Yellow,
				sizeU = UDim2.new(1, 0, 0, Space.XL),
				position = UDim2.fromOffset(0, Space.XXL + Space.S),
			})
			C.text(popup.Body, {
				text = ("Money per second  %s > %s"):format(Format.short(stable.mps), Format.short(mps)),
				size = "M",
				color = Color.Green,
				sizeU = UDim2.new(1, 0, 0, Space.XL),
				position = UDim2.fromOffset(0, Space.XXL + Space.S + Space.XL + Space.XS),
			})
			C.button(popup.Body, {
				text = "Awesome!",
				color = Color.Green,
				size = UDim2.fromOffset(160, Space.Tab),
				anchor = Vector2.new(0.5, 1),
				position = UDim2.new(0.5, 0, 1, 0),
				onClick = function()
					popup:Close()
				end,
			})
			Sound.play("tier")
			task.delay(0.15, function()
				if not popup.closed then
					C.sparkleBurst(popup.Root, UDim2.fromScale(0.5, 0.4), 24)
				end
			end)
			stable = { seats = seats, mps = mps }
		end)
	end)
end

return TierPopup
