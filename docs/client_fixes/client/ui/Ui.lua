local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Theme = require(script.Parent.Theme)
local Util = require(script.Parent.Util)
local Sfx = require(script.Parent.Sfx)
local Icons = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Icons"))

local Ui = {}

Ui.touch = (UserInputService.TouchEnabled and not UserInputService.MouseEnabled) or workspace:GetAttribute("ForceTouchUi") == true

function Ui.make(className, props, parent)
	local object = Instance.new(className)
	for key, value in props or {} do
		object[key] = value
	end
	object.Parent = parent
	return object
end

function Ui.corner(object, radius)
	return Ui.make("UICorner", { CornerRadius = UDim.new(0, radius or Theme.radius.button) }, object)
end

function Ui.stroke(object, color, thickness, transparency)
	return Ui.make("UIStroke", {
		Color = color or Theme.ink,
		Thickness = thickness or 3,
		Transparency = transparency or 0,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		LineJoinMode = Enum.LineJoinMode.Round,
	}, object)
end

function Ui.textStroke(object, thickness, color)
	return Ui.make("UIStroke", {
		Color = color or Theme.ink,
		Thickness = thickness or 2,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
		LineJoinMode = Enum.LineJoinMode.Round,
	}, object)
end

function Ui.gradient(object, pair, rotation)
	return Ui.make("UIGradient", {
		Color = ColorSequence.new(pair[1], pair[2]),
		Rotation = rotation or 90,
	}, object)
end

function Ui.padding(object, left, top, right, bottom)
	return Ui.make("UIPadding", {
		PaddingLeft = UDim.new(0, left or 0),
		PaddingTop = UDim.new(0, top or left or 0),
		PaddingRight = UDim.new(0, right or left or 0),
		PaddingBottom = UDim.new(0, bottom or top or left or 0),
	}, object)
end

function Ui.frame(parent, props)
	props = props or {}
	local object = Ui.make("Frame", {
		Name = props.name or "Frame",
		BackgroundTransparency = props.transparency or 1,
		BackgroundColor3 = props.color or Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		Size = props.size or UDim2.fromScale(1, 1),
		Position = props.position or UDim2.new(),
		AnchorPoint = props.anchor or Vector2.zero,
		ZIndex = props.z or 1,
		ClipsDescendants = props.clip or false,
		LayoutOrder = props.order or 0,
		Visible = props.visible ~= false,
	}, parent)
	if props.radius then
		Ui.corner(object, props.radius)
	end
	if props.stroke then
		Ui.stroke(object, props.strokeColor, props.stroke)
	end
	return object
end

function Ui.label(parent, props)
	props = props or {}
	local object = Ui.make("TextLabel", {
		Name = props.name or "Label",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = props.size or UDim2.fromScale(1, 1),
		Position = props.position or UDim2.new(),
		AnchorPoint = props.anchor or Vector2.zero,
		Text = props.text or "",
		TextColor3 = props.color or Theme.white,
		Font = props.font or Theme.titleFont,
		TextSize = props.textSize or 20,
		TextXAlignment = props.xalign or Enum.TextXAlignment.Center,
		TextYAlignment = props.yalign or Enum.TextYAlignment.Center,
		TextWrapped = props.wrap or false,
		RichText = props.rich or false,
		ZIndex = props.z or 2,
		LayoutOrder = props.order or 0,
		TextTruncate = props.truncate and Enum.TextTruncate.AtEnd or Enum.TextTruncate.None,
		Visible = props.visible ~= false,
	}, parent)
	if props.fit then
		object.TextScaled = true
		Ui.make("UITextSizeConstraint", { MaxTextSize = props.textSize or 20, MinTextSize = props.minSize or 8 }, object)
	end
	if props.stroke ~= false and (props.stroke or props.color == nil or props.color == Theme.white) then
		Ui.textStroke(object, props.stroke == true and 2 or props.stroke or 2, props.strokeColor)
	end
	return object
end

function Ui.image(parent, props)
	props = props or {}
	local image = props.image
	if image and Icons[image] then
		image = Icons[image]
	end
	local object = Ui.make("ImageLabel", {
		Name = props.name or "Image",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Image = image or "",
		ImageColor3 = props.color or Color3.new(1, 1, 1),
		ScaleType = props.scale or Enum.ScaleType.Fit,
		Size = props.size or UDim2.fromScale(1, 1),
		Position = props.position or UDim2.new(),
		AnchorPoint = props.anchor or Vector2.zero,
		ZIndex = props.z or 2,
		LayoutOrder = props.order or 0,
		Visible = props.visible ~= false,
	}, parent)
	return object
end

function Ui.shake(object, amount)
	amount = amount or 6
	local origin = object.Position
	task.spawn(function()
		for index = 1, 6 do
			local offset = (index % 2 == 0 and 1 or -1) * amount * (1 - index / 8)
			object.Position = origin + UDim2.fromOffset(offset, 0)
			task.wait(0.04)
		end
		object.Position = origin
	end)
end

function Ui.scaler(object)
	local scale = object:FindFirstChild("PopScale")
	if not scale then
		scale = Ui.make("UIScale", { Name = "PopScale" }, object)
	end
	return scale
end

function Ui.pop(object, amount)
	local scale = Ui.scaler(object)
	scale.Scale = amount or 1.18
	Util.tween(scale, { Scale = 1 }, 0.28, Enum.EasingStyle.Back)
end

function Ui.pulse(object, amount, period)
	local scale = Ui.scaler(object)
	local tween = TweenService:Create(scale, TweenInfo.new(period or 0.55, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Scale = amount or 1.07 })
	tween:Play()
	return function()
		tween:Cancel()
		scale.Scale = 1
	end
end

function Ui.count(label, from, to, format, duration)
	format = format or Util.short
	duration = duration or 0.6
	local token = (label:GetAttribute("CountToken") or 0) + 1
	label:SetAttribute("CountToken", token)
	task.spawn(function()
		local started = os.clock()
		while label.Parent and label:GetAttribute("CountToken") == token do
			local t = math.clamp((os.clock() - started) / duration, 0, 1)
			local eased = 1 - (1 - t) ^ 3
			label.Text = format(from + (to - from) * eased)
			if t >= 1 then
				break
			end
			RunService.RenderStepped:Wait()
		end
		if label.Parent and label:GetAttribute("CountToken") == token then
			label.Text = format(to)
		end
	end)
end

function Ui.badge(parent, props)
	props = props or {}
	local badge = Ui.frame(parent, {
		name = "Badge",
		size = UDim2.fromOffset(props.size or 26, props.size or 26),
		position = props.position or UDim2.new(1, -4, 0, 4),
		anchor = Vector2.new(1, 0),
		color = props.color or Theme.red[1],
		transparency = 0,
		radius = 999,
		stroke = 3,
		z = 12,
	})
	badge.Parent = parent
	local text = Ui.label(badge, { text = props.text or "", textSize = (props.size or 26) * 0.58, z = 13, stroke = 2, fit = true })
	text.Size = UDim2.new(1, -4, 1, -2)
	text.Position = UDim2.fromOffset(2, 1)
	return badge, text
end

function Ui.button(parent, props)
	props = props or {}
	local palette = props.palette or Theme.green
	local lip = props.lip or 5
	local radius = props.radius or Theme.radius.button
	local root = Ui.frame(parent, {
		name = props.name or "Button",
		size = props.size or UDim2.fromOffset(160, 56),
		position = props.position,
		anchor = props.anchor,
		z = props.z or 3,
		order = props.order,
		visible = props.visible,
	})
	local lipFrame = Ui.frame(root, {
		name = "Lip",
		size = UDim2.new(1, 0, 1, -lip),
		position = UDim2.fromOffset(0, lip),
		color = Theme.shade(palette[2], 0.35),
		transparency = 0,
		radius = radius,
		z = 1,
	})
	local lipStroke = Ui.stroke(lipFrame, Theme.ink, props.stroke or 3)
	local face = Ui.make("TextButton", {
		Name = "Face",
		AutoButtonColor = false,
		Text = "",
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, -lip),
		ZIndex = 2,
	}, root)
	Ui.corner(face, radius)
	local faceStroke = Ui.stroke(face, Theme.ink, props.stroke or 3)
	local gradient = Ui.gradient(face, palette, 90)
	local shine = Ui.frame(face, {
		name = "Shine",
		size = UDim2.new(1, -10, 0.42, 0),
		position = UDim2.fromOffset(5, 4),
		color = Color3.new(1, 1, 1),
		transparency = 0.8,
		radius = math.max(radius - 4, 4),
		z = 3,
	})
	local hasIcon = props.icon ~= nil
	local icon
	if hasIcon then
		icon = Ui.image(face, {
			image = props.icon,
			size = UDim2.fromOffset(props.iconSize or 34, props.iconSize or 34),
			position = props.text and UDim2.new(0, 10, 0.5, 0) or UDim2.fromScale(0.5, 0.5),
			anchor = props.text and Vector2.new(0, 0.5) or Vector2.new(0.5, 0.5),
			z = 5,
		})
	end
	local label
	if props.text then
		label = Ui.label(face, {
			text = props.text,
			textSize = props.textSize or 24,
			size = UDim2.new(1, hasIcon and -((props.iconSize or 34) + 18) or -12, 1, 0),
			position = UDim2.new(0, hasIcon and ((props.iconSize or 34) + 12) or 6, 0, 0),
			font = props.font,
			stroke = props.textStroke or 2.5,
			fit = true,
			z = 5,
		})
	end
	local pressScale = Ui.make("UIScale", { Name = "ButtonScale" }, root)
	local button = {
		root = root,
		face = face,
		label = label,
		icon = icon,
		palette = palette,
		enabled = true,
		busy = false,
	}
	local function paint()
		if button.enabled then
			gradient.Color = ColorSequence.new(button.palette[1], button.palette[2])
			lipFrame.BackgroundColor3 = Theme.shade(button.palette[2], 0.35)
			shine.BackgroundTransparency = 0.8
		else
			gradient.Color = ColorSequence.new(Theme.disabled, Theme.shade(Theme.disabled, 0.15))
			lipFrame.BackgroundColor3 = Theme.shade(Theme.disabled, 0.4)
			shine.BackgroundTransparency = 0.9
		end
	end
	function button.setPalette(newPalette)
		button.palette = newPalette
		paint()
	end
	function button.setEnabled(value)
		button.enabled = value
		paint()
	end
	function button.setText(text)
		if label then
			label.Text = text
		end
	end
	function button.setIcon(name)
		if icon then
			icon.Image = Icons[name] or name
		end
	end
	function button.click(callback)
		button.callback = callback
	end
	face.MouseButton1Down:Connect(function()
		Util.tween(face, { Position = UDim2.fromOffset(0, lip * 0.7) }, 0.06)
		Util.tween(pressScale, { Scale = 0.96 }, 0.06)
	end)
	local function release()
		Util.tween(face, { Position = UDim2.fromOffset(0, 0) }, 0.16, Enum.EasingStyle.Back)
		Util.tween(pressScale, { Scale = 1 }, 0.16, Enum.EasingStyle.Back)
	end
	face.MouseButton1Up:Connect(release)
	face.MouseLeave:Connect(function()
		release()
	end)
	if not Ui.touch then
		face.MouseEnter:Connect(function()
			if button.enabled then
				Util.tween(pressScale, { Scale = 1.04 }, 0.12)
			end
		end)
		face.MouseLeave:Connect(function()
			Util.tween(pressScale, { Scale = 1 }, 0.12)
		end)
	end
	face.Activated:Connect(function()
		if not button.enabled then
			Sfx.play("error")
			Ui.shake(face, 4)
			if button.onDisabled then
				button.onDisabled()
			end
			return
		end
		Sfx.play("click")
		if button.callback then
			button.callback()
		end
	end)
	if props.onClick then
		button.callback = props.onClick
	end
	if props.enabled == false then
		button.enabled = false
	end
	paint()
	return button
end

function Ui.iconButton(parent, props)
	props = props or {}
	local size = props.size or 64
	local button = Ui.button(parent, {
		name = props.name,
		palette = props.palette or Theme.blue,
		size = UDim2.fromOffset(size, size + 6),
		icon = props.icon,
		iconSize = size - 18,
		radius = 18,
		position = props.position,
		anchor = props.anchor,
		order = props.order,
		onClick = props.onClick,
		z = props.z,
	})
	if props.label then
		local text = Ui.label(button.root, {
			text = props.label,
			textSize = 15,
			size = UDim2.new(1, 8, 0, 18),
			position = UDim2.new(0, -4, 1, 2),
			font = Theme.titleFont,
			stroke = 3,
			z = 8,
		})
		button.caption = text
	end
	return button
end

function Ui.bar(parent, props)
	props = props or {}
	local height = props.height or 28
	local root = Ui.frame(parent, {
		name = props.name or "Bar",
		size = props.size or UDim2.new(1, 0, 0, height),
		position = props.position,
		anchor = props.anchor,
		color = Theme.ink,
		transparency = 0,
		radius = height / 2,
		stroke = 3,
		z = props.z or 2,
		order = props.order,
		clip = true,
	})
	local fill = Ui.frame(root, {
		name = "Fill",
		size = UDim2.fromScale(0, 1),
		color = Color3.new(1, 1, 1),
		transparency = 0,
		radius = height / 2,
		z = 3,
	})
	local palette = props.palette or Theme.green
	local gradient = Ui.gradient(fill, palette, 90)
	Ui.frame(fill, {
		name = "Shine",
		size = UDim2.new(1, -8, 0.4, 0),
		position = UDim2.fromOffset(4, 3),
		color = Color3.new(1, 1, 1),
		transparency = 0.75,
		radius = height / 4,
		z = 4,
	})
	local label = Ui.label(root, {
		text = props.text or "",
		textSize = props.textSize or math.floor(height * 0.62),
		z = 6,
		stroke = 2.5,
		fit = true,
	})
	local bar = { root = root, fill = fill, label = label }
	function bar.set(fraction, text)
		fraction = math.clamp(fraction, 0, 1)
		Util.tween(fill, { Size = UDim2.fromScale(fraction, 1) }, 0.35)
		if text then
			label.Text = text
		end
	end
	function bar.setPalette(newPalette)
		gradient.Color = ColorSequence.new(newPalette[1], newPalette[2])
	end
	return bar
end

function Ui.scroll(parent, props)
	props = props or {}
	local scroll = Ui.make("ScrollingFrame", {
		Name = props.name or "Scroll",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = props.size or UDim2.fromScale(1, 1),
		Position = props.position or UDim2.new(),
		AnchorPoint = props.anchor or Vector2.zero,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = props.thick or 6,
		ScrollBarImageColor3 = Theme.inkSoft,
		ScrollingDirection = props.horizontal and Enum.ScrollingDirection.X or Enum.ScrollingDirection.Y,
		ElasticBehavior = Enum.ElasticBehavior.WhenScrollable,
		VerticalScrollBarInset = Enum.ScrollBarInset.None,
		ZIndex = props.z or 2,
		ClipsDescendants = true,
	}, parent)
	if props.horizontal then
		scroll.AutomaticCanvasSize = Enum.AutomaticSize.X
	end
	local layout
	if props.grid then
		layout = Ui.make("UIGridLayout", {
			CellSize = props.grid.cell,
			CellPadding = props.grid.pad or UDim2.fromOffset(10, 10),
			SortOrder = Enum.SortOrder.LayoutOrder,
			HorizontalAlignment = props.grid.align or Enum.HorizontalAlignment.Center,
		}, scroll)
	else
		layout = Ui.make("UIListLayout", {
			Padding = UDim.new(0, props.gap or 8),
			SortOrder = Enum.SortOrder.LayoutOrder,
			FillDirection = props.horizontal and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical,
			HorizontalAlignment = props.align or Enum.HorizontalAlignment.Center,
		}, scroll)
	end
	Ui.padding(scroll, props.pad or 6, props.pad or 6, props.pad or 6, props.pad or 6)
	return scroll, layout
end

function Ui.clear(container)
	for _, child in container:GetChildren() do
		if not child:IsA("UILayout") and not child:IsA("UIPadding") and not child:IsA("UIScale") and not child:IsA("UISizeConstraint") then
			child:Destroy()
		end
	end
end

function Ui.card(parent, props)
	props = props or {}
	local card = Ui.frame(parent, {
		name = props.name or "Card",
		size = props.size or UDim2.fromOffset(200, 240),
		position = props.position,
		anchor = props.anchor,
		color = props.color or Theme.cardBase,
		transparency = 0,
		radius = props.radius or Theme.radius.card,
		order = props.order,
		z = props.z or 2,
		clip = props.clip,
	})
	local stroke = Ui.stroke(card, props.strokeColor or Theme.ink, props.stroke or 3)
	card:SetAttribute("StrokeName", stroke.Name)
	return card, stroke
end

function Ui.pill(parent, props)
	props = props or {}
	local pill = Ui.frame(parent, {
		name = props.name or "Pill",
		size = props.size or UDim2.fromOffset(200, 48),
		position = props.position,
		anchor = props.anchor,
		color = props.color or Theme.ink,
		transparency = 0,
		radius = 999,
		stroke = 3,
		strokeColor = props.strokeColor,
		z = props.z or 2,
		order = props.order,
	})
	local icon
	local textOffset = 14
	if props.icon then
		icon = Ui.image(pill, {
			image = props.icon,
			size = UDim2.fromOffset((props.height or 48) - 6, (props.height or 48) - 6),
			position = UDim2.new(0, 2, 0.5, 0),
			anchor = Vector2.new(0, 0.5),
			z = 4,
		})
		textOffset = (props.height or 48) - 2
	end
	local label = Ui.label(pill, {
		text = props.text or "",
		textSize = props.textSize or 26,
		size = UDim2.new(1, -(textOffset + 10), 1, 0),
		position = UDim2.fromOffset(textOffset, 0),
		xalign = props.xalign or Enum.TextXAlignment.Left,
		stroke = 2.5,
		fit = true,
		z = 4,
	})
	return pill, label, icon
end

function Ui.modal(parent, props)
	props = props or {}
	local modal = {}
	local root = Ui.frame(parent, { name = props.name or "Modal", z = props.z or 5, visible = false })
	local dim = Ui.make("TextButton", {
		Name = "Dim",
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = Color3.fromRGB(14, 20, 40),
		BackgroundTransparency = 0.45,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 1,
	}, root)
	local panel = Ui.frame(root, {
		name = "Panel",
		size = props.size or UDim2.fromScale(0.7, 0.8),
		position = UDim2.fromScale(0.5, 0.5),
		anchor = Vector2.new(0.5, 0.5),
		color = props.color or Theme.cream,
		transparency = 0,
		radius = Theme.radius.panel,
		z = 2,
	})
	Ui.stroke(panel, Theme.ink, 4)
	Ui.make("UISizeConstraint", { MaxSize = props.max or Vector2.new(1100, 720), MinSize = Vector2.new(320, 240) }, panel)
	local scale = Ui.make("UIScale", { Scale = 1 }, panel)
	local headerHeight = props.headerHeight or 62
	local header
	local title
	if props.title then
		header = Ui.frame(panel, {
			name = "Header",
			size = UDim2.new(1, 0, 0, headerHeight),
			color = Color3.new(1, 1, 1),
			transparency = 0,
			radius = Theme.radius.panel,
			z = 3,
		})
		Ui.gradient(header, props.headerPalette or Theme.blue, 90)
		Ui.frame(header, {
			name = "Cover",
			size = UDim2.new(1, 0, 0, Theme.radius.panel),
			position = UDim2.new(0, 0, 1, -Theme.radius.panel),
			color = (props.headerPalette or Theme.blue)[2],
			transparency = 0,
			z = 3,
		})
		title = Ui.label(header, {
			text = props.title,
			textSize = 34,
			size = UDim2.new(1, -150, 1, 0),
			position = UDim2.fromOffset(24, 0),
			xalign = Enum.TextXAlignment.Left,
			stroke = 3,
			fit = true,
			z = 5,
		})
	end
	local body = Ui.frame(panel, {
		name = "Body",
		size = UDim2.new(1, -24, 1, -(header and headerHeight or 0) - 20),
		position = UDim2.new(0, 12, 0, (header and headerHeight or 0) + 8),
		z = 3,
	})
	local closeButton = Ui.button(panel, {
		name = "Close",
		palette = Theme.red,
		size = UDim2.fromOffset(52, 56),
		position = UDim2.new(1, -8, 0, -14),
		anchor = Vector2.new(1, 0),
		icon = nil,
		text = "X",
		textSize = 28,
		radius = 26,
		z = 8,
	})
	modal.root = root
	modal.panel = panel
	modal.body = body
	modal.header = header
	modal.title = title
	modal.close = closeButton
	modal.open = false
	local busy = 0
	function modal.show()
		if modal.open then
			return
		end
		modal.open = true
		busy += 1
		root.Visible = true
		dim.BackgroundTransparency = 1
		Util.tween(dim, { BackgroundTransparency = 0.45 }, 0.2)
		scale.Scale = 0.85
		Util.tween(scale, { Scale = 1 }, 0.28, Enum.EasingStyle.Back)
		Sfx.play("open")
		if modal.onShow then
			modal.onShow()
		end
	end
	function modal.hide(silent)
		if not modal.open then
			return
		end
		modal.open = false
		busy += 1
		local token = busy
		Util.tween(scale, { Scale = 0.9 }, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		Util.tween(dim, { BackgroundTransparency = 1 }, 0.15)
		if not silent then
			Sfx.play("close")
		end
		task.delay(0.16, function()
			if token == busy then
				root.Visible = false
			end
		end)
		if modal.onHide then
			modal.onHide()
		end
	end
	closeButton.click(function()
		modal.hide()
	end)
	dim.Activated:Connect(function()
		if props.dismiss ~= false then
			modal.hide()
		end
	end)
	return modal
end

local BURST_ICONS = { "star", "coin", "heart" }

function Ui.burst(parent, props)
	props = props or {}
	local count = props.count or 14
	local origin = props.position or UDim2.fromScale(0.5, 0.5)
	for index = 1, count do
		local angle = (index / count) * math.pi * 2 + math.random() * 0.4
		local distance = (props.distance or 220) * (0.6 + math.random() * 0.6)
		local size = (props.size or 34) * (0.7 + math.random() * 0.6)
		local image = Ui.image(parent, {
			image = props.icon or BURST_ICONS[(index % #BURST_ICONS) + 1],
			size = UDim2.fromOffset(size, size),
			position = origin,
			anchor = Vector2.new(0.5, 0.5),
			z = props.z or 30,
		})
		image.Rotation = math.random(-40, 40)
		local target = origin + UDim2.fromOffset(math.cos(angle) * distance, math.sin(angle) * distance)
		Util.tween(image, { Position = target, Rotation = image.Rotation + math.random(-120, 120) }, 0.7, Enum.EasingStyle.Quart)
		task.delay(0.45, function()
			if image.Parent then
				Util.tween(image, { ImageTransparency = 1 }, 0.3)
			end
		end)
		task.delay(0.8, function()
			image:Destroy()
		end)
	end
end

function Ui.setRarity(card, stroke, rarityId, pips)
	local color = Theme.rarityColor(rarityId)
	local entry = Theme.rarity[rarityId] or Theme.rarity.common
	stroke.Color = color
	stroke.Thickness = entry.stroke
	return color, entry
end

return Ui
