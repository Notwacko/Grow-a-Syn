local Players = game:GetService("Players")
local Ui = require(script.Parent.Ui)

local Layers = {}

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local guis = {}
local scaleValue = 1
local listeners = {}

local function computeScale()
	local override = workspace:GetAttribute("UiScaleOverride")
	if type(override) == "number" then
		return override
	end
	local camera = workspace.CurrentCamera
	local size = camera and camera.ViewportSize or Vector2.new(1280, 720)
	if Ui.touch then
		return math.clamp(math.min(size.Y / 540, size.X / 960), 0.62, 1)
	end
	return math.clamp(math.min(size.Y / 1080, size.X / 1700), 0.55, 1.5)
end

local function apply()
	scaleValue = computeScale()
	for _, entry in guis do
		entry.scale.Scale = scaleValue
		entry.root.Size = UDim2.fromScale(1 / scaleValue, 1 / scaleValue)
	end
	for _, callback in listeners do
		task.spawn(callback, scaleValue)
	end
end

function Layers.make(name, order, insets)
	local gui = Ui.make("ScreenGui", {
		Name = name,
		ResetOnSpawn = false,
		DisplayOrder = order,
		IgnoreGuiInset = false,
		ScreenInsets = insets or Enum.ScreenInsets.CoreUISafeInsets,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}, playerGui)
	local root = Ui.frame(gui, { name = "Root", size = UDim2.fromScale(1, 1) })
	local scale = Ui.make("UIScale", { Scale = scaleValue }, root)
	guis[name] = { gui = gui, root = root, scale = scale }
	root.Size = UDim2.fromScale(1 / scaleValue, 1 / scaleValue)
	return root, gui
end

function Layers.onScale(callback)
	table.insert(listeners, callback)
end

function Layers.scale()
	return scaleValue
end

function Layers.start()
	scaleValue = computeScale()
	local function hook()
		local camera = workspace.CurrentCamera
		if camera then
			camera:GetPropertyChangedSignal("ViewportSize"):Connect(apply)
		end
	end
	hook()
	workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		hook()
		apply()
	end)
	apply()
end

function Layers.designSize(root)
	local absolute = root.AbsoluteSize
	return Vector2.new(absolute.X / scaleValue, absolute.Y / scaleValue)
end

return Layers
