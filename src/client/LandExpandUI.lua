-- Expand Land: shows cost, requirement and result. Fires RE_ExpandLand (server checks money and distance).
local Players = game:GetService("Players")

local Theme = require(script.Parent.Theme)
local C = require(script.Parent.Components)
local Net = require(script.Parent.Net)
local Format = require(script.Parent.Format)
local Sound = require(script.Parent.Sound)
local Contract = require(script.Parent.Contract)

local Color, Space = Theme.Color, Theme.Space
local player = Players.LocalPlayer

local LandExpandUI = {}

local function size(tier)
	local b = Contract.LAND_BOUNDS[tier]
	return b and ("%d x %d"):format(b.x2 - b.x1, b.z2 - b.z1) or "?"
end

-- studs between the player and their own claim pad (nil when unknown)
local function padDistance()
	local plots = workspace:FindFirstChild("Plots")
	local plot = plots and plots:FindFirstChild("Plot" .. tostring(Net.attr("PlotId", 0)))
	local pad = plot and plot:FindFirstChild("ClaimPad")
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if pad and root then
		return (pad.Position - root.Position).Magnitude
	end
	return nil
end

function LandExpandUI.new(ctx)
	local self = { IsOpen = false }
	local popup, running

	local lastSignature
	local function build()
		local tier = Net.attr("LandTier", 1)
		local maxed = tier >= Contract.MAX_LAND_TIER
		local cost = Contract.LAND_COSTS[tier]
		local money = Net.attr("Money", 0)
		local hasPlot = Net.attr("PlotId", 0) > 0
		local distance = padDistance()
		local nearPad = Net.isMock or (distance ~= nil and distance <= Contract.CLAIM_DISTANCE)
		-- only rebuild when something the player can see changes (keeps the button from flickering mid-press)
		local signature = table.concat({ tier, tostring(cost and money >= cost), tostring(nearPad), tostring(hasPlot), distance and math.floor(distance / 4) or -1 }, "|")
		if signature == lastSignature then
			return
		end
		lastSignature = signature
		local body = popup.Body
		for _, child in body:GetChildren() do
			if not child:IsA("UIPadding") then
				child:Destroy()
			end
		end

		C.text(body, { text = "Land " .. tier .. " of " .. Contract.MAX_LAND_TIER, size = "M", sizeU = UDim2.new(1, 0, 0, Space.XL) })
		C.text(body, {
			text = maxed and ("Fully expanded!  " .. size(tier)) or (size(tier) .. "  >  " .. size(tier + 1)),
			size = "L",
			color = Color.Green,
			sizeU = UDim2.new(1, 0, 0, Space.XXL + Space.S),
			position = UDim2.fromOffset(0, Space.XL),
		})
		if not maxed then
			C.text(body, {
				text = "💰 Cost: " .. Format.short(cost),
				size = "M",
				color = money >= cost and Color.Yellow or Color.Red,
				sizeU = UDim2.new(1, 0, 0, Space.XL),
				position = UDim2.fromOffset(0, Space.XL + Space.XXL + Space.S),
			})
			local requirement
			if not hasPlot then
				requirement = "Claim a plot first"
			elseif not nearPad then
				requirement = "Walk to your glowing pad" .. (distance and (" (" .. math.floor(distance) .. " studs away)") or "")
			else
				requirement = "✔ You are at your pad"
			end
			C.text(body, {
				text = requirement,
				size = "S",
				wrap = true,
				sizeU = UDim2.new(1, 0, 0, Space.XL),
				position = UDim2.fromOffset(0, Space.XL + Space.XXL + Space.S + Space.XL),
			})
		end
		local go
		go = C.button(body, {
			text = maxed and "Done" or "Expand!",
			color = Color.Green,
			size = UDim2.fromOffset(180, Space.Tab),
			anchor = Vector2.new(0.5, 1),
			position = UDim2.new(0.5, 0, 1, 0),
			onClick = function()
				if maxed then
					popup:Close()
					return
				end
				go:setEnabled(false)
				Sound.play("expand")
				Net.expandLand()
			end,
		})
		go:setEnabled(maxed or (hasPlot and nearPad and money >= cost))
	end

	local lastTier
	function self:Open()
		if self.IsOpen then
			return
		end
		self.IsOpen = true
		popup = C.popup(ctx.layers.window, {
			title = "Expand Land",
			color = Color.Green,
			size = UDim2.new(1, -Space.XL * 2, 0, 280),
			maxSize = Vector2.new(440, 280),
			onClose = function()
				self.IsOpen = false
				running = false
			end,
		})
		lastTier = Net.attr("LandTier", 1)
		lastSignature = nil
		build()
		running = true
		task.spawn(function()
			while running and popup and not popup.closed do
				task.wait(0.5)
				if popup.closed then
					break
				end
				local tier = Net.attr("LandTier", 1)
				if tier ~= lastTier then
					lastTier = tier
					C.sparkleBurst(popup.Root, UDim2.fromScale(0.5, 0.45), 20)
					ctx.toast("Your land grew!", "success")
				end
				build()
			end
		end)
	end

	function self:Close()
		if popup and not popup.closed then
			popup:Close()
		end
	end

	return self
end

return LandExpandUI
