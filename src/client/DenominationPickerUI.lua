-- One card per denomination: tier 2 building preview, blurb and the six-stage ladder. Confirm, then choose.
local Theme = require(script.Parent.Theme)
local C = require(script.Parent.Components)
local Net = require(script.Parent.Net)
local Sound = require(script.Parent.Sound)
local Contract = require(script.Parent.Contract)

local Color, Space = Theme.Color, Theme.Space

local Picker = {}

function Picker.new(ctx)
	local self = { IsOpen = false }
	local popup

	local function confirm(den)
		local dialog = C.popup(ctx.layers.popup, {
			title = "Choose " .. den.name .. "?",
			color = Color.Purple,
			closable = false,
			size = UDim2.new(1, -Space.XL * 2, 0, 200),
			maxSize = Vector2.new(380, 200),
		})
		C.text(dialog.Body, {
			text = "Your synagogue will follow the " .. den.name .. " path.",
			size = "S",
			wrap = true,
			sizeU = UDim2.new(1, 0, 0, 64),
		})
		local row = C.row(dialog.Body, { size = UDim2.new(1, 0, 0, Space.Tab), position = UDim2.new(0, 0, 1, -Space.Tab), alignX = Enum.HorizontalAlignment.Center, gap = Space.M })
		C.button(row, {
			text = "Not yet",
			color = Color.Grey,
			size = UDim2.fromOffset(136, Space.Tab),
			order = 1,
			onClick = function()
				dialog:Close()
			end,
		})
		local yes
		yes = C.button(row, {
			text = "Yes!",
			color = Color.Green,
			size = UDim2.fromOffset(136, Space.Tab),
			order = 2,
			onClick = function()
				yes:setEnabled(false)
				local res = Net.chooseDenomination(den.id)
				dialog:Close()
				if res.ok then
					Sound.play("minyan")
					ctx.toast("Welcome to the " .. den.name .. " path!", "success")
					self:Close()
				else
					Sound.play("error")
					ctx.toast(Contract.Reasons[res.reason] or Contract.Reasons.default, "error")
				end
			end,
		})
	end

	local function buildCard(parent, den, order)
		local card = C.card(parent, { size = UDim2.fromOffset(216, 336), order = order, accent = Color.Purple, name = den.id })
		local frame = card.Frame
		C.modelView(frame, den.model, { size = UDim2.new(1, -Space.S, 0, 96), position = UDim2.fromOffset(Space.XS, Space.XS) })
		C.text(frame, { text = den.name, size = "M", sizeU = UDim2.new(1, 0, 0, Space.XL), position = UDim2.fromOffset(0, 100) })
		C.text(frame, { text = den.blurb or "", size = "XS", wrap = true, sizeU = UDim2.new(1, -Space.M, 0, 32), position = UDim2.fromOffset(Space.S, 124) })
		for i, stage in den.stages do
			local final = i == #den.stages
			C.text(frame, {
				text = (final and "★ " or (i .. ". ")) .. stage,
				size = "XS",
				color = final and Color.Yellow or Color.White,
				alignX = Enum.TextXAlignment.Left,
				sizeU = UDim2.new(1, -Space.M, 0, Space.M + Space.XS),
				position = UDim2.fromOffset(Space.S, 160 + (i - 1) * (Space.M + Space.XS)),
			})
		end
		C.button(frame, {
			text = "Choose",
			color = Color.Green,
			size = UDim2.new(1, -Space.S * 2, 0, Space.Tab),
			anchor = Vector2.new(0.5, 1),
			position = UDim2.new(0.5, 0, 1, -Space.S),
			onClick = function()
				confirm(den)
			end,
		})
	end

	function self:Open()
		if self.IsOpen then
			return
		end
		if (Net.attr("Denomination", "") or "") ~= "" then
			ctx.toast("You already chose your denomination.", "info")
			return
		end
		self.IsOpen = true
		popup = C.popup(ctx.layers.window, {
			title = "Choose Your Denomination",
			color = Color.Purple,
			onClose = function()
				self.IsOpen = false
			end,
		})
		local scroll = C.scroll(popup.Body, { horizontal = true })
		C.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, Space.M), SortOrder = Enum.SortOrder.LayoutOrder }, scroll)
		for i, den in Net.getCatalog().denominations do
			buildCard(scroll, den, i)
		end
	end

	function self:Close()
		if popup and not popup.closed then
			popup:Close()
		end
	end

	return self
end

return Picker
