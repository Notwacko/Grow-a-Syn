-- Client entry point: builds the ScreenGui (UIScale from viewport, safe areas), then the HUD and windows.
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Theme = require(script.Parent.Theme)
local C = require(script.Parent.Components)
local Net = require(script.Parent.Net)
local Sound = require(script.Parent.Sound)

local Space = Theme.Space

local gui = Instance.new("ScreenGui")
gui.Name = "GrowUI"
gui.ResetOnSpawn = false
gui.ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

-- UIScale: phones use 800x450 as the design reference (never below 0.9 so 56px buttons stay >= 48px); mouse + keyboard use 1280x720
local root = C.new("Frame", { Name = "Root", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1) }, gui)
local uiScale = C.new("UIScale", { Scale = 1 }, root)
local resizeCallbacks = {}

local function designSize()
	local a = gui.AbsoluteSize
	return Vector2.new(a.X / uiScale.Scale, a.Y / uiScale.Scale)
end

local function updateScale()
	local a = gui.AbsoluteSize
	local s
	if UserInputService.TouchEnabled then
		s = math.clamp(math.min(a.X / 800, a.Y / 450), 0.9, 1.5)
	else
		s = math.clamp(math.min(a.X / 1280, a.Y / 720), 0.62, 1)
	end
	uiScale.Scale = s
	root.Size = UDim2.fromScale(1 / s, 1 / s)
	for _, cb in resizeCallbacks do
		cb()
	end
end
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateScale)

local function layer(name, z)
	return C.new("Frame", { Name = name, BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = z }, root)
end

local ctx = {
	root = root,
	designSize = designSize,
	onResize = function(cb)
		table.insert(resizeCallbacks, cb)
	end,
	layers = { hud = layer("HUD", 1), window = layer("Windows", 10), popup = layer("Popups", 20), toast = nil, dev = layer("Dev", 40) },
}

local toastLayer = C.new("Frame", {
	Name = "Toasts",
	BackgroundTransparency = 1,
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 148),
	Size = UDim2.new(1, -(Space.Touch + Space.S) * 2 - Space.S * 2, 0, 0),
	AutomaticSize = Enum.AutomaticSize.Y,
	ZIndex = 30,
}, root)
C.new("UISizeConstraint", { MaxSize = Vector2.new(400, 1000) }, toastLayer)
C.new("UIListLayout", { Padding = UDim.new(0, Space.XS), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Center }, toastLayer)
ctx.layers.toast = toastLayer
ctx.toast = function(text, kind)
	C.toast(toastLayer, text, kind)
end

updateScale()

-- loading text while Net decides between the real server and mock mode (up to ~10 seconds)
local loading = C.text(root, { text = "Loading...", size = "L", z = 60 })
Net.init()
loading:Destroy()
updateScale()

local FloatingNumbers = require(script.Parent.FloatingNumbers)
FloatingNumbers.init(playerGui)

local Notifications = require(script.Parent.Notifications)
Notifications.init(ctx)

local ShopUI = require(script.Parent.ShopUI).new(ctx)
local InventoryUI = require(script.Parent.InventoryUI).new(ctx)
local PickerUI = require(script.Parent.DenominationPickerUI).new(ctx)
local LandUI = require(script.Parent.LandExpandUI).new(ctx)
local UpgradeUI = require(script.Parent.BuildingUpgradeUI).new(ctx)
local windows = { shop = ShopUI, inventory = InventoryUI, picker = PickerUI, land = LandUI, upgrade = UpgradeUI }

local function open(name, ...)
	for other, window in windows do
		if other ~= name then
			window:Close()
		end
	end
	windows[name]:Open(...)
end

local hooks = {
	openShop = function(tab)
		open("shop", tab)
	end,
	openInventory = function(merge)
		open("inventory", merge)
	end,
	openPicker = function()
		open("picker")
	end,
	openLand = function()
		open("land")
	end,
	openUpgrade = function()
		open("upgrade")
	end,
}

local HUD = require(script.Parent.HUD).new(ctx, hooks)
require(script.Parent.TierPopup).watch(ctx)
require(script.Parent.Tutorial).new(ctx, HUD, hooks)

-- MINYAN celebration: big text and a confetti burst (no overlay), then the denomination picker
local function celebrateMinyan()
	local label = C.text(ctx.layers.popup, { text = "MINYAN!", size = "XL", color = Theme.Color.Yellow, sizeU = UDim2.fromOffset(280, 64), anchor = Vector2.new(0.5, 0.5), position = UDim2.fromScale(0.5, 0.35), z = 5 })
	C.bounceIn(label)
	C.sparkleBurst(ctx.layers.popup, UDim2.fromScale(0.5, 0.35), 28)
	task.delay(1.8, function()
		label:Destroy()
	end)
end

Net.MinyanReached:connect(function()
	Sound.play("minyan")
	celebrateMinyan()
	if (Net.attr("Denomination", "") or "") == "" then
		hooks.openPicker()
	end
end)

if Net.isMock then
	require(script.Parent.Dev).new(ctx)
end

if Net.isMock then
	shared.GrowUI = { open = open, hooks = hooks, ctx = ctx, windows = windows } -- test handle (mock mode only)
end
