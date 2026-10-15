-- Building upgrade: current stage > next stage, seats result, cost and requirement. Calls RF_UpgradeBuilding.
local Theme = require(script.Parent.Theme)
local C = require(script.Parent.Components)
local Net = require(script.Parent.Net)
local Format = require(script.Parent.Format)
local Sound = require(script.Parent.Sound)
local Contract = require(script.Parent.Contract)

local Color, Space = Theme.Color, Theme.Space

local BuildingUpgradeUI = {}

function BuildingUpgradeUI.new(ctx)
	local self = { IsOpen = false }
	local popup

	local function stageName(den, tier)
		return den and den.stages[tier - 1] or ("Tier " .. tier)
	end

	function self:Open()
		if self.IsOpen then
			return
		end
		local catalog = Net.getCatalog()
		local denId = Net.attr("Denomination", "")
		if denId == "" then
			ctx.toast("Choose a denomination first.", "info")
			return
		end
		self.IsOpen = true
		popup = C.popup(ctx.layers.window, {
			title = "Upgrade Building",
			color = Color.Purple,
			size = UDim2.new(1, -Space.XL * 2, 0, 300),
			maxSize = Vector2.new(440, 300),
			onClose = function()
				self.IsOpen = false
			end,
		})
		local body = popup.Body
		local den = catalog.denById[denId]
		local tier = Net.attr("Tier", 1)
		if tier >= Contract.MAX_TIER then
			C.text(body, { text = stageName(den, tier), size = "L", color = Color.Yellow, sizeU = UDim2.new(1, 0, 0, Space.XXL) })
			C.text(body, { text = "Your synagogue has reached its grandest form!", size = "S", wrap = true, sizeU = UDim2.new(1, 0, 0, Space.XXL), position = UDim2.fromOffset(0, Space.XXL + Space.S) })
			return
		end
		local nextTier = tier + 1
		local info = catalog.upgrades[nextTier] or {}
		local money = Net.attr("Money", 0)
		C.text(body, { text = stageName(den, tier) .. "  >  " .. stageName(den, nextTier), size = "M", wrap = true, sizeU = UDim2.new(1, 0, 0, Space.XXL + Space.S) })
		C.text(body, {
			text = ("Seats  %d > %d"):format(Contract.SEATS_PER_TIER[tier], Contract.SEATS_PER_TIER[nextTier]),
			size = "M",
			color = Color.Green,
			sizeU = UDim2.new(1, 0, 0, Space.XL),
			position = UDim2.fromOffset(0, Space.XXL + Space.M),
		})
		C.text(body, {
			text = "More money every second!",
			size = "S",
			color = Color.Green,
			sizeU = UDim2.new(1, 0, 0, Space.XL),
			position = UDim2.fromOffset(0, Space.XXL + Space.M + Space.XL),
		})
		C.text(body, {
			text = info.cost and ("💰 Cost: " .. Format.short(info.cost)) or "💰 Cost: set by the server",
			size = "M",
			color = (not info.cost or money >= info.cost) and Color.Yellow or Color.Red,
			sizeU = UDim2.new(1, 0, 0, Space.XL),
			position = UDim2.fromOffset(0, Space.XXL + Space.M + Space.XL * 2),
		})
		C.text(body, {
			text = info.requirement and ("Needs: " .. info.requirement) or "",
			size = "S",
			wrap = true,
			sizeU = UDim2.new(1, 0, 0, Space.XL),
			position = UDim2.fromOffset(0, Space.XXL + Space.M + Space.XL * 3),
		})
		local go
		go = C.button(body, {
			text = "Upgrade!",
			color = Color.Green,
			size = UDim2.fromOffset(180, Space.Tab),
			anchor = Vector2.new(0.5, 1),
			position = UDim2.new(0.5, 0, 1, 0),
			onClick = function()
				go:setEnabled(false)
				local res = Net.upgradeBuilding()
				if res.ok then
					Sound.play("upgrade")
					popup:Close() -- the tier popup celebrates when the Tier attribute changes
				else
					Sound.play("error")
					ctx.toast(Contract.Reasons[res.reason] or Contract.Reasons.default, "error")
					if popup and not popup.closed then
						go:setEnabled(true)
					end
				end
			end,
		})
	end

	function self:Close()
		if popup and not popup.closed then
			popup:Close()
		end
	end

	return self
end

return BuildingUpgradeUI
