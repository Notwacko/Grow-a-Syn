local ReplicatedStorage = game:GetService("ReplicatedStorage")

local core = script.Parent.Parent
local Config = require(core.Config)
local Guard = require(core.Guard)
local Notify = require(core.Notify)
local Fx = require(core.Fx)
local Format = require(core.Format)
local Procedural = require(core.Procedural)
local UpgradeService = require(core.UpgradeService)
local Catalog = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("UpgradeCatalog"))

local UpgradeStations = {
	name = "UpgradeStations",
	order = 20,
}

local LATERALS = { -5, 5, -9.8, 9.8 }
local DEPTH_INSIDE = 3.6
local GOLD = Color3.fromRGB(255, 214, 80)
local PIP_OFF = Color3.fromRGB(96, 96, 112)

local place = Procedural.place

local function colorOf(definition)
	local c = definition.color
	return Color3.fromRGB(c[1], c[2], c[3])
end

local function decorate(model, definition, cf, color)
	local id = definition.id
	if id == "welcome_table" then
		Procedural.ball(model, "Bell", 0.9, cf * CFrame.new(-1.2, 3.25, -0.1), GOLD, Enum.Material.Metal)
		place(model, "Card", Vector3.new(1.5, 0.9, 0.12), cf * CFrame.new(0.9, 3.25, -0.3) * CFrame.Angles(-0.35, 0, 0), Color3.new(1, 1, 1))
		place(model, "CardStripe", Vector3.new(1.5, 0.2, 0.14), cf * CFrame.new(0.9, 3.4, -0.31) * CFrame.Angles(-0.35, 0, 0), color)
	elseif id == "kiddush_table" then
		Procedural.cylinder(model, "CupA", 0.7, 0.9, cf * CFrame.new(-1.2, 3.25, -0.3), Color3.fromRGB(214, 214, 224), Enum.Material.Metal)
		Procedural.cylinder(model, "CupB", 0.7, 0.9, cf * CFrame.new(-0.3, 3.25, -0.5), Color3.fromRGB(214, 214, 224), Enum.Material.Metal)
		Procedural.cylinder(model, "Loaf", 1.7, 0.6, cf * CFrame.new(1.1, 3.1, -0.2), Color3.fromRGB(226, 170, 92))
		Procedural.cylinder(model, "LoafGlaze", 1.3, 0.2, cf * CFrame.new(1.1, 3.45, -0.2), Color3.fromRGB(244, 204, 130))
	else
		place(model, "Ledger", Vector3.new(1.6, 0.3, 1.1), cf * CFrame.new(-0.9, 3.0, -0.3), Color3.fromRGB(40, 110, 70))
		place(model, "LedgerPages", Vector3.new(1.4, 0.22, 0.95), cf * CFrame.new(-0.9, 3.2, -0.3), Color3.fromRGB(250, 244, 226))
		Procedural.cylinder(model, "Pen", 0.18, 1.1, cf * CFrame.new(0.8, 2.95, -0.4) * CFrame.Angles(0, 0.6, 0), Color3.fromRGB(40, 40, 58))
		place(model, "Stamp", Vector3.new(0.8, 0.5, 0.8), cf * CFrame.new(1.3, 3.05, 0.3), color)
	end
end

local function buildGui(top, definition, lateral)
	local gui = Instance.new("BillboardGui")
	gui.Name = "StationSign"
	gui.Size = UDim2.fromOffset(200, 80)
	gui.StudsOffset = Vector3.new(0, math.abs(lateral) > 7 and 6.6 or 4.4, 0)
	gui.MaxDistance = 14
	gui.LightInfluence = 0
	gui.Adornee = top
	gui.Parent = top
	local function label(name, y, height, size, color)
		local text = Instance.new("TextLabel")
		text.Name = name
		text.BackgroundTransparency = 1
		text.Position = UDim2.fromScale(0, y)
		text.Size = UDim2.fromScale(1, height)
		text.Font = Enum.Font.FredokaOne
		text.TextScaled = true
		text.TextColor3 = color
		text.Parent = gui
		local stroke = Instance.new("UIStroke")
		stroke.Thickness = size
		stroke.Color = Color3.fromRGB(30, 30, 50)
		stroke.Parent = text
		return text
	end
	label("Title", 0, 0.42, 3.5, Color3.new(1, 1, 1)).Text = definition.name
	label("Level", 0.42, 0.3, 3, GOLD)
	label("Cost", 0.72, 0.28, 2.5, Color3.fromRGB(190, 255, 200))
	return gui
end

local function refresh(station, definition, level)
	local gui = station.top:FindFirstChild("StationSign")
	local cost = Catalog.cost(definition, level)
	if gui then
		gui.Level.Text = "Level " .. level .. " / " .. definition.maxLevel
		gui.Cost.Text = cost and ("Upgrade: " .. Format.short(cost)) or "MAX LEVEL"
	end
	station.prompt.ObjectText = definition.name
	if cost then
		station.prompt.ActionText = "Upgrade " .. Format.short(cost)
		station.prompt.Enabled = true
	else
		station.prompt.ActionText = "Maxed out"
		station.prompt.Enabled = false
	end
	for index, pip in station.pips do
		pip.Color = index <= level and GOLD or PIP_OFF
		pip.Material = index <= level and Enum.Material.Neon or Enum.Material.SmoothPlastic
	end
end

local function trigger(context, definition, station, who)
	if who ~= context.player then
		Notify.send(who, "info", "That belongs to another synagogue")
		return
	end
	if not Guard.allow(who, "Upgrade", Config.COOLDOWNS.Upgrade) then
		return
	end
	if not Guard.nearPart(who, station.top, 14) then
		Guard.flag(who, "Upgrade", "too far from station")
		return
	end
	if UpgradeService.purchase(who, definition.id) then
		local position = station.top.Position
		Fx.confetti(position + Vector3.new(0, 3, 0), 0.6)
		Fx.floatText(position + Vector3.new(0, 7, 0), "LEVEL UP!", GOLD)
	end
end

local function buildStation(context, definition, lateral)
	local info = context.info
	local frame = info.floor.CFrame
	local door = frame:PointToObjectSpace(info.door.Position)
	local worldPosition = (frame * CFrame.new(door.X + lateral, 0, door.Z + DEPTH_INSIDE)).Position
	local base = Vector3.new(worldPosition.X, info.floorTopY, worldPosition.Z)
	local cf = CFrame.lookAt(base, base + frame.LookVector)
	local color = colorOf(definition)
	local model = Instance.new("Model")
	model.Name = "Station_" .. definition.id
	model:SetAttribute("UpgradeId", definition.id)
	place(model, "Base", Vector3.new(3.2, 2.4, 2.2), cf * CFrame.new(0, 1.2, 0), Config.COLORS.woodDark)
	local top = place(model, "Top", Vector3.new(3.6, 0.4, 2.6), cf * CFrame.new(0, 2.6, 0), color)
	place(model, "Riser", Vector3.new(3.2, 2.4, 0.35), cf * CFrame.new(0, 4.0, 1.0), color)
	local pips = {}
	for index = 1, definition.maxLevel do
		local offset = (index - (definition.maxLevel + 1) / 2) * 0.55
		pips[index] = place(model, "Pip" .. index, Vector3.new(0.45, 0.45, 0.2), cf * CFrame.new(offset, 4.7, 0.76), PIP_OFF, nil, { CanCollide = false })
	end
	decorate(model, definition, cf, color)
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.CanCollide = part.Name == "Base"
		end
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.HoldDuration = 0.5
	prompt.MaxActivationDistance = 4.2
	prompt.RequiresLineOfSight = false
	prompt.Parent = top
	buildGui(top, definition, lateral)
	local station = { model = model, top = top, prompt = prompt, pips = pips }
	prompt.Triggered:Connect(function(who)
		trigger(context, definition, station, who)
	end)
	model.Parent = context.folder
	refresh(station, definition, UpgradeService.level(context.player, definition.id))
	return station
end

function UpgradeStations.build(context)
	context.stations = {}
	for index, definition in Catalog.list do
		local lateral = LATERALS[index]
		if lateral then
			context.stations[definition.id] = buildStation(context, definition, lateral)
		end
	end
end

function UpgradeStations.onUpgradeChanged(context, id, level)
	local station = context.stations and context.stations[id]
	local definition = Catalog.get(id)
	if station and definition then
		refresh(station, definition, level)
	end
end

return UpgradeStations
