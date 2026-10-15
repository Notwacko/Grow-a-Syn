-- Component builders in the chunky candy style. Interactive elements get hover/press states; popups bounce in.
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local Theme = require(script.Parent.Theme)
local Sound = require(script.Parent.Sound)
local ModelLookup = require(script.Parent.ModelLookup)

local T = Theme
local Color, Space, Radius, Stroke = T.Color, T.Space, T.Radius, T.Stroke

local C = {}

local function new(class, props, parent)
	local inst = Instance.new(class)
	for k, v in props do
		inst[k] = v
	end
	inst.Parent = parent
	return inst
end

local function corner(parent, radius)
	return new("UICorner", { CornerRadius = UDim.new(0, radius) }, parent)
end

local function outline(parent, thickness)
	return new("UIStroke", { Thickness = thickness or Stroke.Thick, Color = Color.Ink, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, parent)
end

local function gradient(parent, color)
	return new("UIGradient", { Rotation = 90, Color = ColorSequence.new(T.light(color), T.dark(color)) }, parent)
end


local function addShadow(holder, radius)
	local s = new("Frame", {
		Name = "Shadow",
		BackgroundColor3 = Color.Ink,
		BackgroundTransparency = T.Shadow.Transparency,
		Size = UDim2.fromScale(1, 1),
		Position = UDim2.fromOffset(0, T.Shadow.Offset),
		ZIndex = 0,
	}, holder)
	corner(s, radius)
	return s
end

function C.tween(inst, seconds, props, style, direction)
	local tween = TweenService:Create(inst, TweenInfo.new(seconds, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out), props)
	tween:Play()
	return tween
end

-- White text with a dark outline. size is a Theme.TextSize key.
function C.text(parent, o)
	local size = T.TextSize[o.size or "M"]
	local label = new("TextLabel", {
		Name = o.name or "Text",
		BackgroundTransparency = 1,
		Font = T.Font,
		Text = o.text or "",
		TextSize = size,
		TextColor3 = o.color or Color.White,
		TextWrapped = o.wrap or false,
		TextXAlignment = o.alignX or Enum.TextXAlignment.Center,
		TextYAlignment = o.alignY or Enum.TextYAlignment.Center,
		Size = o.sizeU or UDim2.fromScale(1, 1),
		Position = o.position or UDim2.new(),
		AnchorPoint = o.anchor or Vector2.zero,
		ZIndex = o.z or 2,
		LayoutOrder = o.order or 0,
	}, parent)
	new("UIStroke", {
		Thickness = size >= T.TextSize.L and Stroke.Thick or Stroke.Thin,
		Color = Color.Ink,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
	}, label)
	return label
end

-- Chunky button: gradient, thick outline, inner shine, hover 1.06 / press 0.92 squash.
function C.button(parent, o)
	local color = o.color or Color.Blue
	local radius = o.radius or Radius.M
	local holder = new("Frame", {
		Name = o.name or "Button",
		BackgroundTransparency = 1,
		Size = o.size or UDim2.fromOffset(Space.Touch, Space.Touch),
		Position = o.position or UDim2.new(),
		AnchorPoint = o.anchor or Vector2.zero,
		LayoutOrder = o.order or 0,
		ZIndex = o.z or 1,
	}, parent)
	addShadow(holder, radius)
	local hit = new("TextButton", {
		Name = "Hit",
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = Color.White,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),
		ZIndex = 1,
	}, holder)
	corner(hit, radius)
	outline(hit)
	local grad = gradient(hit, color)
	new("Frame", {
		Name = "Shine",
		BackgroundColor3 = Color.White,
		BackgroundTransparency = 0.6,
		Size = UDim2.new(1, -Space.M * 2, 0, Space.S),
		Position = UDim2.fromOffset(Space.M, Space.XS),
		ZIndex = 2,
	}, hit)
	corner(hit.Shine, Radius.S)
	local squash = new("UIScale", { Name = "Squash", Scale = 1 }, hit)
	local label = C.text(hit, { text = o.text or o.icon or "", size = o.textSize or (o.icon and "L" or "M"), z = 3 })
	if o.image then
		label.Text = ""
		new("ImageLabel", { Name = "Icon", BackgroundTransparency = 1, Image = o.image, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.82, 0.82), ScaleType = Enum.ScaleType.Fit, ZIndex = 3 }, hit)
	end

	local self = { Root = holder, Hit = hit, Label = label, enabled = true }
	local hovering = false

	local function setScale(scale, seconds)
		C.tween(squash, seconds or 0.08, { Scale = scale })
	end
	hit.MouseEnter:Connect(function()
		hovering = true
		if self.enabled then
			setScale(1.06)
		end
	end)
	hit.MouseLeave:Connect(function()
		hovering = false
		setScale(1)
	end)
	hit.MouseButton1Down:Connect(function()
		if self.enabled then
			setScale(0.92, 0.06)
		end
	end)
	hit.MouseButton1Up:Connect(function()
		setScale(hovering and 1.06 or 1)
	end)
	hit.Activated:Connect(function()
		if self.enabled and o.onClick then
			Sound.play("click")
			o.onClick()
		end
	end)

	function self:setEnabled(enabled)
		self.enabled = enabled
		grad.Color = ColorSequence.new(T.light(enabled and color or Color.Grey), T.dark(enabled and color or Color.Grey))
		label.TextTransparency = enabled and 0 or 0.35
	end
	function self:setColor(newColor)
		color = newColor
		grad.Color = ColorSequence.new(T.light(newColor), T.dark(newColor))
	end
	function self:setText(text)
		label.Text = text
	end
	return self
end

function C.iconButton(parent, o)
	local cell = new("Frame", {
		Name = o.name or "IconButton",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(Space.Touch + Space.S, Space.Touch + Space.XS + Space.L),
		LayoutOrder = o.order or 0,
		Visible = o.visible ~= false,
	}, parent)
	local button = C.button(cell, {
		icon = o.icon,
		color = o.color,
		onClick = o.onClick,
		position = UDim2.new(0.5, 0, 0, 0),
		anchor = Vector2.new(0.5, 0),
	})
	C.text(cell, {
		text = o.label or "",
		size = "S",
		sizeU = UDim2.new(1, 0, 0, Space.L),
		position = UDim2.fromOffset(0, Space.Touch + Space.XS),
	})
	return { Root = cell, Button = button }
end

function C.quickButton(parent, o)
	o.size = UDim2.fromOffset(Space.Touch, Space.Touch)
	return C.button(parent, o)
end

-- Boost: big "x2" label, countdown inside, Robux badge (or Free tag) underneath.
function C.boostButton(parent, o)
	local cell = new("Frame", {
		Name = o.name or "BoostButton",
		BackgroundTransparency = 1,
		Size = UDim2.fromOffset(Space.Touch + Space.S, Space.Touch + Space.XS + Space.XL),
		LayoutOrder = o.order or 0,
	}, parent)
	local button = C.button(cell, {
		text = o.label or "x2",
		textSize = "L",
		color = o.color or Color.Orange,
		onClick = o.onClick,
		position = UDim2.new(0.5, 0, 0, 0),
		anchor = Vector2.new(0.5, 0),
	})
	local timer = C.text(button.Hit, {
		text = "",
		size = "XS",
		sizeU = UDim2.new(1, 0, 0, Space.L),
		position = UDim2.new(0, 0, 1, -Space.L - Space.XS),
		z = 4,
	})
	button.Label.Position = UDim2.fromOffset(0, -Space.XS)
	local badge = new("Frame", {
		Name = "Badge",
		BackgroundColor3 = o.free and Color.Green or Color.Blue,
		Size = UDim2.new(1, -Space.S, 0, Space.XL),
		Position = UDim2.new(0.5, 0, 0, Space.Touch + Space.XS),
		AnchorPoint = Vector2.new(0.5, 0),
	}, cell)
	corner(badge, Radius.S)
	outline(badge, Stroke.Thin)
	local badgeText = C.text(badge, { text = o.free and "FREE" or ("R$ " .. tostring(o.price or "")), size = "S" })
	return {
		Root = cell,
		Button = button,
		setTimer = function(_, text)
			timer.Text = text or ""
		end,
		setBadge = function(_, text)
			badgeText.Text = text
		end,
	}
end

function C.panel(parent, o)
	o = o or {}
	local holder = new("Frame", {
		Name = o.name or "Panel",
		BackgroundTransparency = 1,
		Size = o.size or UDim2.fromScale(1, 1),
		Position = o.position or UDim2.new(),
		AnchorPoint = o.anchor or Vector2.zero,
		LayoutOrder = o.order or 0,
	}, parent)
	addShadow(holder, o.radius or Radius.M)
	local frame = new("Frame", {
		Name = "Frame",
		BackgroundColor3 = o.color or Color.Panel,
		Size = UDim2.new(1, 0, 1, -T.Shadow.Offset),
		ClipsDescendants = o.clip or false,
	}, holder)
	corner(frame, o.radius or Radius.M)
	outline(frame)
	return { Root = holder, Frame = frame }
end

-- Card with a rarity-colored outline.
function C.card(parent, o)
	local card = C.panel(parent, { size = o.size, order = o.order, name = o.name or "Card", color = o.color })
	if o.accent then
		card.Frame.UIStroke.Color = o.accent
	end
	return card
end

function C.pill(parent, o)
	local frame = new("Frame", {
		Name = o.name or "Pill",
		BackgroundColor3 = o.color or Color.Panel,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, Space.XXL),
		LayoutOrder = o.order or 0,
	}, parent)
	corner(frame, Radius.L)
	outline(frame)
	new("UIPadding", { PaddingLeft = UDim.new(0, o.image and Space.S or Space.M), PaddingRight = UDim.new(0, Space.M) }, frame)
	if o.image then
		new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, Space.XS), SortOrder = Enum.SortOrder.LayoutOrder }, frame)
		new("ImageLabel", { Name = "Icon", BackgroundTransparency = 1, Image = o.image, Size = UDim2.fromOffset(Space.XL + Space.XS, Space.XL + Space.XS), ScaleType = Enum.ScaleType.Fit, LayoutOrder = 0 }, frame)
	end
	local label = C.text(frame, { text = o.text or "", size = o.textSize or "M", sizeU = UDim2.fromScale(0, 1), order = 1 })
	label.AutomaticSize = Enum.AutomaticSize.X
	return { Root = frame, Label = label, setText = function(_, text) label.Text = text end }
end

function C.progressBar(parent, o)
	local track = new("Frame", {
		Name = o.name or "ProgressBar",
		BackgroundColor3 = Color.Ink,
		BackgroundTransparency = 0.25,
		Size = o.size or UDim2.new(1, 0, 0, Space.XXL),
		Position = o.position or UDim2.new(),
		AnchorPoint = o.anchor or Vector2.zero,
		ClipsDescendants = true,
	}, parent)
	corner(track, Radius.L)
	outline(track)
	local fill = new("Frame", { Name = "Fill", BackgroundColor3 = Color.White, Size = UDim2.fromScale(0, 1) }, track)
	corner(fill, Radius.L)
	local grad = gradient(fill, o.color or Color.Green)
	local label = C.text(track, { text = "", size = "M", z = 3 })
	local self = { Root = track, Label = label }
	function self:set(value, max, text, color)
		C.tween(fill, 0.25, { Size = UDim2.fromScale(math.clamp(value / math.max(max, 1), 0, 1), 1) })
		label.Text = text or ""
		if color then
			grad.Color = ColorSequence.new(T.light(color), T.dark(color))
		end
	end
	return self
end

-- N rainbow segments; segments past the current one are dimmed, the current one is highlighted.
function C.segmentedBar(parent, o)
	local count = o.count or 6
	local root = new("Frame", {
		Name = o.name or "SegmentedBar",
		BackgroundTransparency = 1,
		Size = o.size or UDim2.new(1, 0, 0, Space.XL),
		Position = o.position or UDim2.new(),
		AnchorPoint = o.anchor or Vector2.zero,
	}, parent)
	local segments = {}
	for i = 1, count do
		local seg = new("Frame", {
			Name = "Seg" .. i,
			BackgroundColor3 = Color.White,
			Size = UDim2.new(1 / count, -Space.XS, 1, 0),
			Position = UDim2.new((i - 1) / count, Space.XS / 2, 0, 0),
		}, root)
		corner(seg, Radius.S)
		local line = outline(seg, Stroke.Thin)
		gradient(seg, Color[T.Rainbow[(i - 1) % #T.Rainbow + 1]])
		local label = C.text(seg, { text = tostring(i), size = "S" })
		segments[i] = { frame = seg, stroke = line, label = label }
	end
	local self = { Root = root }
	function self:setCurrent(index)
		for i, seg in segments do
			local reached = index ~= nil and i <= index
			seg.frame.BackgroundTransparency = reached and 0 or 0.55
			seg.label.TextTransparency = reached and 0 or 0.4
			local current = i == index
			seg.stroke.Color = current and Color.White or Color.Ink
			seg.stroke.Thickness = current and Stroke.Thick or Stroke.Thin
			seg.frame.ZIndex = current and 2 or 1
		end
	end
	self:setCurrent(nil)
	return self
end

local function bounceIn(target)
	local scale = new("UIScale", { Name = "Bounce", Scale = 0.5 }, target)
	C.tween(scale, 0.3, { Scale = 1 }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
end
C.bounceIn = bounceIn

-- Modal popup: dim overlay, bounce-in panel with a colored header and optional close button.
function C.popup(layer, o)
	local overlay = new("TextButton", {
		Name = o.name or "Popup",
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = Color.Ink,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ZIndex = o.z or 1,
	}, layer)
	C.tween(overlay, 0.2, { BackgroundTransparency = 0.45 })
	local holder = new("Frame", {
		Name = "Holder",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = o.size or UDim2.new(1, -Space.XL, 1, -Space.XL),
	}, overlay)
	new("UISizeConstraint", { MaxSize = o.maxSize or Vector2.new(640, 440) }, holder)
	addShadow(holder, Radius.L)
	local frame = new("Frame", { Name = "Frame", BackgroundColor3 = Color.Panel, Size = UDim2.new(1, 0, 1, -T.Shadow.Offset), ClipsDescendants = true }, holder)
	corner(frame, Radius.L)
	outline(frame)
	local headerHeight = o.title and Space.Tab or 0
	if o.title then
		local header = new("Frame", { Name = "Header", BackgroundColor3 = Color.White, Size = UDim2.new(1, 0, 0, headerHeight) }, frame)
		gradient(header, o.color or Color.Blue)
		C.text(header, { text = o.title, size = "L", sizeU = UDim2.new(1, -Space.Tab * 2, 1, 0), position = UDim2.fromOffset(Space.Tab, 0) })
	end
	local body = new("Frame", {
		Name = "Body",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, headerHeight),
		Size = UDim2.new(1, 0, 1, -headerHeight),
	}, frame)
	new("UIPadding", {
		PaddingLeft = UDim.new(0, Space.M),
		PaddingRight = UDim.new(0, Space.M),
		PaddingTop = UDim.new(0, Space.M),
		PaddingBottom = UDim.new(0, Space.M),
	}, body)
	local popup = { Root = overlay, Holder = holder, Frame = frame, Body = body, closed = false }
	function popup:Close()
		if self.closed then
			return
		end
		self.closed = true
		overlay:Destroy()
		if o.onClose then
			o.onClose()
		end
	end
	if o.closable ~= false then
		C.button(frame, {
			text = "X",
			color = Color.Red,
			size = UDim2.fromOffset(Space.Tab, Space.Tab),
			position = UDim2.new(1, -Space.Tab - Space.XS, 0, 0),
			textSize = "M",
			onClick = function()
				popup:Close()
			end,
		}).Root.ZIndex = 5
	end
	bounceIn(holder)
	return popup
end

-- Short message stack entry. layer must have a vertical UIListLayout.
function C.toast(layer, text, kind)
	local colors = { info = Color.Blue, success = Color.Green, error = Color.Red }
	for _, old in layer:GetChildren() do
		if old:IsA("Frame") and #layer:GetChildren() > 4 then
			old:Destroy()
			break
		end
	end
	local frame = new("Frame", {
		Name = "Toast",
		BackgroundColor3 = Color.White,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.fromScale(1, 0),
	}, layer)
	corner(frame, Radius.M)
	outline(frame)
	gradient(frame, colors[kind] or Color.Blue)
	new("UIPadding", {
		PaddingLeft = UDim.new(0, Space.M),
		PaddingRight = UDim.new(0, Space.M),
		PaddingTop = UDim.new(0, Space.S),
		PaddingBottom = UDim.new(0, Space.S),
	}, frame)
	local label = C.text(frame, { text = text, size = "S", wrap = true, sizeU = UDim2.fromScale(1, 0) })
	label.AutomaticSize = Enum.AutomaticSize.Y
	bounceIn(frame)
	task.delay(3, function()
		if frame.Parent then
			C.tween(frame, 0.3, { BackgroundTransparency = 1 })
			C.tween(label, 0.3, { TextTransparency = 1 })
			task.delay(0.3, function()
				frame:Destroy()
			end)
		end
	end)
	return frame
end

-- Square confetti burst (no font glyphs needed). pos is a UDim2 in the parent.
function C.sparkleBurst(parent, pos, count)
	local palette = { Color.Yellow, Color.Orange, Color.White, Color.Blue, Color.Red, Color.Green }
	count = count or 16
	for i = 1, count do
		local spark = new("Frame", {
			BackgroundColor3 = palette[(i - 1) % #palette + 1],
			Size = UDim2.fromOffset(Space.M, Space.M),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = pos,
			Rotation = 45,
			ZIndex = 50,
		}, parent)
		corner(spark, Stroke.Thick)
		local angle = math.rad(i / count * 360 + math.random(-12, 12))
		local dist = math.random(60, 130)
		C.tween(spark, 0.8, {
			Position = pos + UDim2.fromOffset(math.cos(angle) * dist, math.sin(angle) * dist),
			BackgroundTransparency = 1,
			Rotation = math.random(-180, 180),
		}, Enum.EasingStyle.Quart)
		Debris:AddItem(spark, 0.9)
	end
end

-- Gentle pulse on a gui object. Returns a stop function; call it when the object is hidden.
function C.pulse(target, amount)
	local scale = target:FindFirstChild("PulseScale") or new("UIScale", { Name = "PulseScale", Scale = 1 }, target)
	local tween = TweenService:Create(scale, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Scale = amount or 1.08 })
	tween:Play()
	return function()
		tween:Cancel()
		scale.Scale = 1
	end
end

-- ViewportFrame preview of a model from ReplicatedStorage.Models (placeholder cube when missing).
function C.modelView(parent, modelName, o)
	o = o or {}
	local view = new("ViewportFrame", {
		Name = "Preview",
		BackgroundTransparency = 1,
		Size = o.size or UDim2.fromScale(1, 1),
		Position = o.position or UDim2.new(),
		LightColor = Color.White,
		Ambient = Color3.fromRGB(170, 170, 170),
		ZIndex = o.z or 2,
	}, parent)
	local instance = ModelLookup.get(modelName)
	for _, d in instance:GetDescendants() do
		if d:IsA("LuaSourceContainer") then
			d:Destroy()
		end
	end
	local container = instance
	if not instance:IsA("Model") then
		container = Instance.new("Model")
		instance.Parent = container
	end
	container.Parent = view
	local cf, size = container:GetBoundingBox()
	local camera = new("Camera", {}, view)
	view.CurrentCamera = camera
	local radius = math.max(size.Magnitude / 2, 1)
	local distance = radius / math.tan(math.rad(camera.FieldOfView / 2)) * 1.05
	camera.CFrame = CFrame.lookAt(cf.Position + Vector3.new(0.6, 0.45, 1).Unit * distance, cf.Position)
	return view
end

function C.scroll(parent, o)
	o = o or {}
	local scroll = new("ScrollingFrame", {
		Name = o.name or "Scroll",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = o.size or UDim2.fromScale(1, 1),
		Position = o.position or UDim2.new(),
		ScrollBarThickness = Space.XS,
		ScrollBarImageColor3 = Color.Ink,
		AutomaticCanvasSize = o.horizontal and Enum.AutomaticSize.X or Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		ScrollingDirection = o.horizontal and Enum.ScrollingDirection.X or Enum.ScrollingDirection.Y,
	}, parent)
	return scroll
end

function C.grid(parent, cellSize, o)
	o = o or {}
	local scroll = C.scroll(parent, o)
	new("UIGridLayout", {
		CellSize = cellSize,
		CellPadding = UDim2.fromOffset(Space.S, Space.S),
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
	}, scroll)
	new("UIPadding", { PaddingTop = UDim.new(0, Space.XS), PaddingBottom = UDim.new(0, Space.S) }, scroll)
	return scroll
end

function C.row(parent, o)
	o = o or {}
	local frame = new("Frame", {
		Name = o.name or "Row",
		BackgroundTransparency = 1,
		Size = o.size or UDim2.new(1, 0, 0, Space.Tab),
		Position = o.position or UDim2.new(),
		LayoutOrder = o.order or 0,
	}, parent)
	new("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, o.gap or Space.S),
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		HorizontalAlignment = o.alignX or Enum.HorizontalAlignment.Left,
	}, frame)
	return frame
end

C.new = new
C.corner = corner
C.outline = outline
C.gradient = gradient

return C
