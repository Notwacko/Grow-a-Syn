local Theme = require(script.Parent.Theme)
local Ui = require(script.Parent.Ui)
local Util = require(script.Parent.Util)
local Store = require(script.Parent.Store)
local Sfx = require(script.Parent.Sfx)

local Toasts = {}

local COLORS = {
	info = Theme.blue,
	success = Theme.green,
	error = Theme.red,
	gold = Theme.gold,
}

local ICONS = {
	info = "star",
	success = "star",
	error = "lock",
	gold = "coin",
}

local holder
local active = {}
local recent = {}

local function relayout()
	for index, entry in active do
		local target = UDim2.new(0.5, 0, 0, (index - 1) * 62)
		Util.tween(entry.frame, { Position = target }, 0.2)
	end
end

function Toasts.show(kind, text, duration)
	kind = COLORS[kind] and kind or "info"
	local now = os.clock()
	if recent[text] and now - recent[text] < 1.5 then
		return
	end
	recent[text] = now
	local palette = COLORS[kind]
	local frame = Ui.frame(holder, {
		name = "Toast",
		size = UDim2.fromOffset(380, 54),
		position = UDim2.new(0.5, 0, 0, -70),
		anchor = Vector2.new(0.5, 0),
		color = Color3.new(1, 1, 1),
		transparency = 0,
		radius = 27,
		stroke = 3,
		z = 5,
	})
	Ui.gradient(frame, palette, 90)
	Ui.frame(frame, {
		name = "Shine",
		size = UDim2.new(1, -16, 0.4, 0),
		position = UDim2.fromOffset(8, 4),
		transparency = 0.82,
		radius = 12,
		z = 6,
	})
	local icon = Ui.image(frame, {
		image = ICONS[kind],
		size = UDim2.fromOffset(34, 34),
		position = UDim2.new(0, 12, 0.5, 0),
		anchor = Vector2.new(0, 0.5),
		z = 7,
	})
	local label = Ui.label(frame, {
		text = text,
		textSize = 19,
		size = UDim2.new(1, -62, 1, -8),
		position = UDim2.fromOffset(52, 4),
		xalign = Enum.TextXAlignment.Left,
		fit = true,
		stroke = 2.5,
		z = 7,
	})
	label.Font = Theme.bodyFont
	local entry = { frame = frame }
	table.insert(active, 1, entry)
	while #active > 3 do
		local old = table.remove(active)
		old.frame:Destroy()
	end
	relayout()
	if kind == "error" then
		Sfx.play("error")
	end
	task.delay(duration or 3, function()
		local index = table.find(active, entry)
		if index then
			table.remove(active, index)
			relayout()
		end
		Util.tween(frame, { Position = frame.Position - UDim2.fromOffset(0, 40) }, 0.25)
		Util.tween(frame, { BackgroundTransparency = 1 }, 0.25)
		task.delay(0.28, function()
			frame:Destroy()
		end)
	end)
end

function Toasts.start(root)
	holder = Ui.frame(root, {
		name = "Toasts",
		size = UDim2.new(1, 0, 0, 220),
		position = UDim2.fromOffset(0, 8),
		z = 50,
	})
	Store.notify:connect(function(kind, text)
		Toasts.show(kind, text)
	end)
end

return Toasts
