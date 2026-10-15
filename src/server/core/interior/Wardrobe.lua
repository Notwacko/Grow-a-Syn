local core = script.Parent.Parent
local Config = require(core.Config)
local Guard = require(core.Guard)
local Notify = require(core.Notify)
local Fx = require(core.Fx)
local Procedural = require(core.Procedural)
local Assets = require(core.Assets)
local CosmeticsService = require(core.CosmeticsService)

local Wardrobe = {
	name = "Wardrobe",
	order = 25,
}

local LATERAL = 9.8
local DEPTH_INSIDE = 3.6
local GOLD = Color3.fromRGB(255, 214, 80)

local place = Procedural.place

local function buildGui(top)
	local gui = Instance.new("BillboardGui")
	gui.Name = "StationSign"
	gui.Size = UDim2.fromOffset(200, 80)
	gui.StudsOffset = Vector3.new(0, 6.2, 0)
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
	label("Title", 0, 0.42, 3.5, Color3.new(1, 1, 1)).Text = "Wardrobe"
	label("Level", 0.42, 0.3, 3, GOLD)
	label("Cost", 0.72, 0.28, 2.5, Color3.fromRGB(190, 255, 200))
	return gui
end

local function makePrompt(parent, key, offset)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ObjectText = "Wardrobe"
	prompt.KeyboardKeyCode = key
	prompt.HoldDuration = 0.3
	prompt.MaxActivationDistance = 4.6
	prompt.RequiresLineOfSight = false
	prompt.UIOffset = offset
	prompt.Parent = parent
	return prompt
end

local function refresh(station, player)
	local info = CosmeticsService.describe(player)
	local gui = station.glass:FindFirstChild("StationSign")
	if gui then
		gui.Level.Text = info.name .. (info.auto and " (auto)" or "")
		gui.Cost.Text = info.style == "modest" and "Modest dress" or "Classic dress"
	end
	station.outfitPrompt.ActionText = "Next outfit"
	station.stylePrompt.ActionText = info.style == "modest" and "Style: modest" or "Style: classic"
end

function Wardrobe.build(context)
	local info = context.info
	local frame = info.floor.CFrame
	local door = frame:PointToObjectSpace(info.door.Position)
	local worldPosition = (frame * CFrame.new(door.X + LATERAL, 0, door.Z + DEPTH_INSIDE)).Position
	local base = Vector3.new(worldPosition.X, info.floorTopY, worldPosition.Z)
	local cf = CFrame.lookAt(base, base + frame.LookVector)
	local model, glass
	local source = Assets.get("station_mirror")
	if source and source:IsA("Model") then
		model = source
		model.Name = "Station_wardrobe"
		Assets.setPassive(model)
		model:PivotTo(cf)
		glass = model:FindFirstChild("Top", true)
		place(model, "Base", Vector3.new(3.4, 0.7, 2.0), cf * CFrame.new(0, 0.35, 0.2), Config.COLORS.woodDark, nil, {
			Transparency = 1,
			CanQuery = false,
			CastShadow = false,
		})
	end
	if not glass or not glass:IsA("BasePart") then
		if model then
			model:Destroy()
		end
		model = Instance.new("Model")
		model.Name = "Station_wardrobe"
		place(model, "Base", Vector3.new(3.4, 0.7, 2.0), cf * CFrame.new(0, 0.35, 0.2), Config.COLORS.woodDark)
		place(model, "Frame", Vector3.new(3.2, 7.2, 0.4), cf * CFrame.new(0, 4.3, 0.95), Config.COLORS.wood)
		glass = place(model, "Glass", Vector3.new(2.7, 6.4, 0.15), cf * CFrame.new(0, 4.3, 0.68), Color3.fromRGB(200, 236, 255), Enum.Material.Glass, {
			Transparency = 0.3,
			Reflectance = 0.3,
		})
		place(model, "Crest", Vector3.new(3.5, 0.5, 0.7), cf * CFrame.new(0, 8.1, 0.95), Config.COLORS.gold)
		Procedural.ball(model, "Jewel", 0.9, cf * CFrame.new(0, 8.7, 0.95), GOLD, Enum.Material.Neon)
	end
	glass.Transparency = glass.Name == "Glass" and glass.Transparency or 1
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.CanCollide = part.Name == "Base"
		end
	end
	local outfitPrompt = makePrompt(glass, Enum.KeyCode.E, Vector2.new(0, 0))
	local stylePrompt = makePrompt(glass, Enum.KeyCode.F, Vector2.new(0, -72))
	buildGui(glass)
	local station = { model = model, glass = glass, outfitPrompt = outfitPrompt, stylePrompt = stylePrompt }
	local function allowed(who)
		if who ~= context.player then
			Notify.send(who, "info", "That belongs to another synagogue")
			return false
		end
		if not Guard.allow(who, "Cosmetics", Config.COOLDOWNS.Cosmetics) then
			return false
		end
		if not Guard.nearPart(who, glass, 14) then
			Guard.flag(who, "Cosmetics", "too far from wardrobe")
			return false
		end
		return true
	end
	outfitPrompt.Triggered:Connect(function(who)
		if allowed(who) then
			CosmeticsService.cycleOutfit(who)
			Fx.sparkle(glass.Position + Vector3.new(0, 2, 0))
			Fx.sound(glass.Position, Config.SOUNDS.pop, 0.6, 1.1)
		end
	end)
	stylePrompt.Triggered:Connect(function(who)
		if allowed(who) then
			CosmeticsService.toggleStyle(who)
			Fx.sparkle(glass.Position + Vector3.new(0, 2, 0))
			Fx.sound(glass.Position, Config.SOUNDS.pop, 0.6, 0.9)
		end
	end)
	context.wardrobe = station
	context.wardrobeConnection = CosmeticsService.Changed:Connect(function(player)
		if player == context.player and station.glass.Parent then
			refresh(station, player)
		end
	end)
	model.Parent = context.folder
	refresh(station, context.player)
end

function Wardrobe.destroy(context)
	if context.wardrobeConnection then
		context.wardrobeConnection.Disconnect()
		context.wardrobeConnection = nil
	end
	context.wardrobe = nil
end

return Wardrobe
