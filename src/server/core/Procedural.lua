local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(script.Parent.Config)
local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))

local Procedural = {}

local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

local function place(parent, name, size, cframe, color, material, extra)
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Material = material or Enum.Material.SmoothPlastic
	part.Color = color
	part.Size = size
	part.CFrame = cframe
	if extra then
		for key, value in extra do
			part[key] = value
		end
	end
	part.Parent = parent
	return part
end

local function cylinder(parent, name, diameter, height, cframe, color, material)
	return place(parent, name, Vector3.new(height, diameter, diameter), cframe * CFrame.Angles(0, 0, math.pi / 2), color, material, {
		Shape = Enum.PartType.Cylinder,
	})
end

local function ball(parent, name, diameter, cframe, color, material)
	return place(parent, name, Vector3.one * diameter, cframe, color, material, {
		Shape = Enum.PartType.Ball,
	})
end

local function marker(parent, name, size, cframe)
	return place(parent, name, size, cframe, rgb(255, 255, 255), Enum.Material.SmoothPlastic, {
		Transparency = 1,
		CanCollide = false,
		CanQuery = false,
		CanTouch = false,
		CastShadow = false,
	})
end

local function newModel(name)
	local model = Instance.new("Model")
	model.Name = name
	return model
end

Procedural.place = place
Procedural.cylinder = cylinder
Procedural.ball = ball
Procedural.marker = marker

function Procedural.tree()
	local model = newModel("prop_tree")
	place(model, "Trunk", Vector3.new(1.8, 5, 1.8), CFrame.new(0, 2.5, 0), Config.COLORS.woodDark)
	place(model, "LeavesLow", Vector3.new(8, 4, 8), CFrame.new(0, 6.5, 0), rgb(66, 196, 60))
	place(model, "LeavesMid", Vector3.new(6, 3.4, 6), CFrame.new(0, 9.7, 0) * CFrame.Angles(0, math.rad(20), 0), rgb(84, 214, 70))
	place(model, "LeavesTop", Vector3.new(3.6, 3, 3.6), CFrame.new(0, 12.4, 0) * CFrame.Angles(0, math.rad(40), 0), rgb(110, 230, 86))
	model.WorldPivot = CFrame.new()
	return model, 8
end

function Procedural.fence()
	local model = newModel("prop_fence")
	place(model, "PostA", Vector3.new(0.9, 4, 0.9), CFrame.new(-3.6, 2, 0), Config.COLORS.wood)
	place(model, "PostB", Vector3.new(0.9, 4, 0.9), CFrame.new(3.6, 2, 0), Config.COLORS.wood)
	place(model, "RailLow", Vector3.new(8, 0.6, 0.5), CFrame.new(0, 1.3, 0), Config.COLORS.wood)
	place(model, "RailHigh", Vector3.new(8, 0.6, 0.5), CFrame.new(0, 2.8, 0), Config.COLORS.wood)
	model.WorldPivot = CFrame.new()
	return model, 8
end

function Procedural.bench()
	local model = newModel("prop_bench")
	place(model, "Seat", Vector3.new(6, 0.5, 1.8), CFrame.new(0, 1.7, 0), Config.COLORS.wood)
	place(model, "Back", Vector3.new(6, 1.6, 0.4), CFrame.new(0, 2.9, 0.8), Config.COLORS.wood)
	place(model, "LegA", Vector3.new(0.6, 1.5, 1.6), CFrame.new(-2.5, 0.75, 0), Config.COLORS.dark)
	place(model, "LegB", Vector3.new(0.6, 1.5, 1.6), CFrame.new(2.5, 0.75, 0), Config.COLORS.dark)
	model.WorldPivot = CFrame.new()
	return model, 6
end

function Procedural.lamp()
	local model = newModel("prop_lamp")
	place(model, "Base", Vector3.new(2, 0.8, 2), CFrame.new(0, 0.4, 0), Config.COLORS.dark)
	place(model, "Pole", Vector3.new(0.7, 9, 0.7), CFrame.new(0, 4.8, 0), Config.COLORS.dark)
	local bulb = place(model, "Glow", Vector3.new(2.2, 2.2, 2.2), CFrame.new(0, 10.2, 0), rgb(255, 233, 160), Enum.Material.Neon)
	place(model, "Cap", Vector3.new(3, 0.6, 3), CFrame.new(0, 11.6, 0), Config.COLORS.dark)
	local light = Instance.new("PointLight")
	light.Range = 24
	light.Brightness = 1.4
	light.Color = rgb(255, 226, 150)
	light.Parent = bulb
	model.WorldPivot = CFrame.new()
	return model, 4
end

function Procedural.flowerBed(width)
	width = width or 6
	local model = newModel("prop_flowers")
	place(model, "Border", Vector3.new(width, 1, 3), CFrame.new(0, 0.5, 0), Config.COLORS.woodDark)
	place(model, "Soil", Vector3.new(width - 0.8, 0.3, 2.2), CFrame.new(0, 1.05, 0), rgb(96, 64, 44))
	local colors = { rgb(255, 99, 132), rgb(255, 205, 66), rgb(176, 124, 255), rgb(255, 255, 255), rgb(86, 156, 255) }
	local count = math.max(3, math.floor(width / 1.1))
	for i = 1, count do
		local x = -width / 2 + 0.9 + (i - 1) * ((width - 1.8) / (count - 1))
		local z = (i % 2 == 0) and 0.5 or -0.5
		place(model, "Stem", Vector3.new(0.25, 1, 0.25), CFrame.new(x, 1.6, z), rgb(60, 170, 60))
		place(model, "Bloom", Vector3.new(0.9, 0.7, 0.9), CFrame.new(x, 2.25, z), colors[(i - 1) % #colors + 1])
	end
	model.WorldPivot = CFrame.new()
	return model
end

function Procedural.fountain()
	local model = newModel("prop_fountain")
	cylinder(model, "Basin", 30, 2.6, CFrame.new(0, 1.3, 0), Config.COLORS.stone)
	cylinder(model, "BasinWater", 26, 2.4, CFrame.new(0, 1.55, 0), Config.COLORS.water, Enum.Material.SmoothPlastic)
	cylinder(model, "Pillar", 4, 8, CFrame.new(0, 5, 0), Config.COLORS.stone)
	cylinder(model, "Bowl", 11, 1.6, CFrame.new(0, 9.6, 0), Config.COLORS.stone)
	local top = cylinder(model, "BowlWater", 9.4, 1.4, CFrame.new(0, 9.8, 0), Config.COLORS.water)
	ball(model, "Crown", 3.2, CFrame.new(0, 11.8, 0), Config.COLORS.gold, Enum.Material.Neon)
	local spray = Instance.new("ParticleEmitter")
	spray.Rate = 60
	spray.Lifetime = NumberRange.new(1.2, 1.8)
	spray.Speed = NumberRange.new(14, 18)
	spray.SpreadAngle = Vector2.new(18, 18)
	spray.Acceleration = Vector3.new(0, -30, 0)
	spray.Size = NumberSequence.new(0.8)
	spray.Color = ColorSequence.new(rgb(190, 235, 255))
	spray.LightEmission = 0.6
	spray.EmissionDirection = Enum.NormalId.Top
	spray.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(1, 1),
	})
	spray.Parent = top
	model.WorldPivot = CFrame.new()
	return model
end

local PEOPLE = {
	{
		skin = rgb(234, 192, 154),
		hair = rgb(60, 40, 30),
		top = rgb(255, 255, 255),
		bottom = rgb(38, 44, 66),
		kippah = rgb(30, 30, 44),
		tallit = true,
		female = false,
		scale = 1,
	},
	{
		skin = rgb(241, 194, 125),
		hair = rgb(150, 82, 40),
		top = rgb(64, 196, 196),
		bottom = rgb(46, 84, 140),
		female = true,
		scale = 0.95,
	},
	{
		skin = rgb(141, 85, 36),
		hair = rgb(30, 24, 22),
		top = rgb(86, 156, 255),
		bottom = rgb(58, 58, 64),
		kippah = rgb(255, 205, 66),
		female = false,
		scale = 1.04,
	},
	{
		skin = rgb(198, 134, 66),
		hair = rgb(40, 30, 28),
		top = rgb(176, 124, 255),
		bottom = rgb(92, 64, 51),
		female = true,
		scale = 0.98,
	},
	{
		skin = rgb(255, 219, 172),
		hair = rgb(190, 190, 196),
		top = rgb(94, 214, 130),
		bottom = rgb(58, 58, 64),
		kippah = rgb(255, 255, 255),
		beard = rgb(190, 190, 196),
		female = false,
		scale = 1,
	},
	{
		skin = rgb(107, 68, 35),
		hair = rgb(24, 20, 20),
		top = rgb(255, 107, 107),
		bottom = rgb(46, 84, 140),
		kippah = rgb(86, 156, 255),
		female = false,
		scale = 0.78,
	},
}

function Procedural.congregant(variant)
	local spec = PEOPLE[((variant - 1) % #PEOPLE) + 1]
	local model = newModel("congregant_" .. variant)
	local root = marker(model, "Root", Vector3.new(1, 0.2, 1), CFrame.new(0, 0.1, 0))
	model.PrimaryPart = root
	if spec.female then
		place(model, "Cloth_Bottom", Vector3.new(2.3, 2.2, 1.5), CFrame.new(0, 1.5, 0), spec.bottom)
		place(model, "Legs", Vector3.new(1.6, 0.6, 0.9), CFrame.new(0, 0.5, 0), spec.skin)
	else
		place(model, "Cloth_Bottom", Vector3.new(0.95, 2.3, 1), CFrame.new(-0.52, 1.35, 0), spec.bottom)
		place(model, "Cloth_Bottom", Vector3.new(0.95, 2.3, 1), CFrame.new(0.52, 1.35, 0), spec.bottom)
	end
	place(model, "Shoes", Vector3.new(0.95, 0.4, 1.3), CFrame.new(-0.52, 0.2, -0.15), rgb(50, 40, 40))
	place(model, "Shoes", Vector3.new(0.95, 0.4, 1.3), CFrame.new(0.52, 0.2, -0.15), rgb(50, 40, 40))
	place(model, "Cloth_Top", Vector3.new(2.2, 1.6, 1.3), CFrame.new(0, 3.4, 0), spec.top)
	place(model, "Cloth_Top", Vector3.new(0.8, 1.5, 0.9), CFrame.new(-1.5, 3.45, 0), spec.top)
	place(model, "Cloth_Top", Vector3.new(0.8, 1.5, 0.9), CFrame.new(1.5, 3.45, 0), spec.top)
	place(model, "Hands", Vector3.new(0.7, 0.5, 0.8), CFrame.new(-1.5, 2.55, 0), spec.skin)
	place(model, "Hands", Vector3.new(0.7, 0.5, 0.8), CFrame.new(1.5, 2.55, 0), spec.skin)
	local head = place(model, "Head", Vector3.new(1.5, 1.4, 1.5), CFrame.new(0, 4.8, 0), spec.skin)
	local face = Instance.new("Decal")
	face.Name = "face"
	face.Texture = "rbxasset://textures/face.png"
	face.Face = Enum.NormalId.Front
	face.Parent = head
	place(model, "Hair", Vector3.new(1.62, 0.5, 1.62), CFrame.new(0, 5.4, 0.05), spec.hair)
	if spec.female then
		place(model, "Hair", Vector3.new(1.62, 1.6, 0.45), CFrame.new(0, 4.75, 0.72), spec.hair)
	end
	if spec.kippah then
		cylinder(model, "Kippah", 1.05, 0.3, CFrame.new(0, 5.62, 0), spec.kippah)
	end
	if spec.beard then
		place(model, "Beard", Vector3.new(1.2, 0.7, 0.3), CFrame.new(0, 4.35, -0.8), spec.beard)
	end
	if spec.tallit then
		place(model, "Tallit", Vector3.new(2.5, 0.35, 1.5), CFrame.new(0, 4.2, 0), rgb(255, 255, 255))
		place(model, "Tallit", Vector3.new(0.7, 1.7, 0.18), CFrame.new(-0.55, 3.4, -0.7), rgb(255, 255, 255))
		place(model, "Tallit", Vector3.new(0.7, 1.7, 0.18), CFrame.new(0.55, 3.4, -0.7), rgb(255, 255, 255))
		place(model, "TallitStripe", Vector3.new(2.52, 0.12, 1.52), CFrame.new(0, 4.24, 0), rgb(47, 111, 224))
		place(model, "TallitStripe", Vector3.new(0.72, 0.12, 0.2), CFrame.new(-0.55, 2.7, -0.7), rgb(47, 111, 224))
		place(model, "TallitStripe", Vector3.new(0.72, 0.12, 0.2), CFrame.new(0.55, 2.7, -0.7), rgb(47, 111, 224))
	end
	model:SetAttribute("BaseScale", spec.scale)
	model:SetAttribute("Procedural", true)
	return model
end

local STYLES = {
	[1] = { wall = rgb(246, 232, 200), roof = rgb(96, 132, 196), trim = rgb(255, 200, 50), curtain = rgb(60, 110, 220), floor = rgb(206, 190, 160) },
	[2] = { wall = rgb(255, 250, 240), roof = rgb(64, 196, 176), trim = rgb(255, 200, 50), curtain = rgb(52, 152, 219), floor = rgb(200, 210, 214) },
	[3] = { wall = rgb(250, 214, 160), roof = rgb(222, 100, 70), trim = rgb(255, 200, 50), curtain = rgb(155, 89, 182), floor = rgb(214, 190, 150) },
	[4] = { wall = rgb(232, 222, 206), roof = rgb(70, 90, 140), trim = rgb(255, 210, 70), curtain = rgb(192, 57, 43), floor = rgb(196, 184, 166) },
	[5] = { wall = rgb(196, 98, 74), roof = rgb(52, 62, 96), trim = rgb(255, 210, 70), curtain = rgb(44, 62, 130), floor = rgb(170, 150, 130) },
	[6] = { wall = rgb(132, 170, 240), roof = rgb(255, 196, 40), trim = rgb(255, 255, 255), curtain = rgb(142, 68, 173), floor = rgb(186, 196, 214) },
	[7] = { wall = rgb(255, 252, 245), roof = rgb(255, 205, 60), trim = rgb(255, 190, 40), curtain = rgb(41, 128, 185), floor = rgb(235, 228, 214) },
}

local LAYOUTS = {
	[1] = { rows = 3, perBench = 2 },
	[2] = { rows = 5, perBench = 2 },
	[3] = { rows = 5, perBench = 3 },
	[4] = { rows = 7, perBench = 3 },
	[5] = { rows = 7, perBench = 4 },
	[6] = { rows = 9, perBench = 4 },
	[7] = { rows = 10, perBench = 5 },
}

local SEAT_SPACING = 3
local ROW_SPACING = 5

local function addTower(parent, style, x, z, floorTop, height, size)
	place(parent, "Tower", Vector3.new(size, height, size), CFrame.new(x, floorTop + height / 2, z), style.wall)
	place(parent, "TowerBand", Vector3.new(size + 0.6, 0.9, size + 0.6), CFrame.new(x, floorTop + height - 3, z), style.trim)
	for i = 0, 2 do
		local s = size + 1 - i * 1.5
		place(parent, "TowerCap", Vector3.new(s, 1.5, s), CFrame.new(x, floorTop + height + 0.75 + i * 1.5, z), style.roof)
	end
	ball(parent, "TowerFinial", 1.6, CFrame.new(x, floorTop + height + 5.2, z), style.trim, Enum.Material.Neon)
end

function Procedural.building(tier)
	tier = math.clamp(math.floor(tier), 1, Constants.MAX_TIER)
	local style = STYLES[tier]
	local layout = LAYOUTS[tier]
	local seatCount = Constants.SEATS_PER_TIER[tier]
	local rows, perBench = layout.rows, layout.perBench

	local blockW = perBench * SEAT_SPACING + 1.5
	local aisle = 7
	local interiorW = 2 * blockW + aisle + 6
	local frontPad = 8 + tier
	local arkDepth = 15
	local interiorD = frontPad + rows * ROW_SPACING + arkDepth
	local wallT = 1.5
	local shellW = interiorW + 2 * wallT
	local shellD = interiorD + 2 * wallT
	local plazaD = 12 + tier * 1.5
	local floorW = shellW + 14
	local floorD = shellD + plazaD + 4
	local wallH = 11 + tier * 1.2
	local zf = -floorD / 2 + plazaD
	local zb = zf + shellD
	local zi0 = zf + wallT
	local zi1 = zb - wallT
	local top = 0.5

	local model = newModel("Synagogue")
	local visual = Instance.new("Folder")
	visual.Name = "Visual"
	visual.Parent = model
	local seats = Instance.new("Folder")
	seats.Name = "Seats"
	seats.Parent = model
	local slots = Instance.new("Folder")
	slots.Name = "Slots"
	slots.Parent = model

	local floor = place(model, "Floor", Vector3.new(floorW, 1, floorD), CFrame.new(0, 0, 0), style.floor)
	model.PrimaryPart = floor

	place(visual, "InteriorFloor", Vector3.new(interiorW, 0.2, interiorD), CFrame.new(0, top + 0.1, (zi0 + zi1) / 2), Config.COLORS.wood, Enum.Material.WoodPlanks)
	place(visual, "Aisle", Vector3.new(aisle, 0.1, interiorD - 2), CFrame.new(0, top + 0.25, (zi0 + zi1) / 2), style.curtain)
	place(visual, "Plaza", Vector3.new(floorW - 2, 0.2, plazaD - 1), CFrame.new(0, top + 0.1, -floorD / 2 + (plazaD - 1) / 2 + 0.5), rgb(244, 236, 214))

	local doorOpen = 8
	local segW = (shellW - doorOpen) / 2
	place(visual, "FrontWallL", Vector3.new(segW, wallH, wallT), CFrame.new(-(doorOpen / 2 + segW / 2), top + wallH / 2, zf + wallT / 2), style.wall)
	place(visual, "FrontWallR", Vector3.new(segW, wallH, wallT), CFrame.new(doorOpen / 2 + segW / 2, top + wallH / 2, zf + wallT / 2), style.wall)
	place(visual, "Lintel", Vector3.new(doorOpen, wallH - 10, wallT), CFrame.new(0, top + 10 + (wallH - 10) / 2, zf + wallT / 2), style.wall)
	place(visual, "BackWall", Vector3.new(shellW, wallH, wallT), CFrame.new(0, top + wallH / 2, zb - wallT / 2), style.wall)

	local pierCount = math.max(3, math.floor(shellD / 9) + 1)
	for _, side in { -1, 1 } do
		local x = side * (shellW / 2 - wallT / 2)
		place(visual, "WallBase", Vector3.new(wallT, 3, shellD), CFrame.new(x, top + 1.5, (zf + zb) / 2), style.wall)
		place(visual, "WallHeader", Vector3.new(wallT, 2.5, shellD), CFrame.new(x, top + wallH - 1.25, (zf + zb) / 2), style.wall)
		place(visual, "WindowGlass", Vector3.new(0.4, wallH - 5.5, shellD - 1), CFrame.new(x, top + 3 + (wallH - 5.5) / 2, (zf + zb) / 2), rgb(150, 215, 255), Enum.Material.Glass, { Transparency = 0.5 })
		for i = 0, pierCount - 1 do
			local z = zf + 0.7 + i * ((shellD - 1.4) / (pierCount - 1))
			place(visual, "Pier", Vector3.new(wallT + 0.5, wallH - 5.5, 1.4), CFrame.new(x, top + 3 + (wallH - 5.5) / 2, z), style.trim)
		end
	end

	local steps = 5 + math.floor(tier / 2)
	local stepH = 1.8
	local roofW = shellW + 3
	local roofD = shellD + 3
	for i = 0, steps - 1 do
		local w = roofW * (1 - i / steps)
		place(visual, "Roof", Vector3.new(w, stepH, roofD), CFrame.new(0, top + wallH + stepH * (i + 0.5), (zf + zb) / 2), style.roof)
	end
	local roofTop = top + wallH + stepH * steps
	place(visual, "RoofRidge", Vector3.new(1.2, 0.6, roofD + 0.4), CFrame.new(0, roofTop + 0.3, (zf + zb) / 2), style.trim)

	place(visual, "DoorTrimL", Vector3.new(1, 10.4, 1.8), CFrame.new(-(doorOpen / 2 - 0.5), top + 5.2, zf + wallT / 2), style.trim)
	place(visual, "DoorTrimR", Vector3.new(1, 10.4, 1.8), CFrame.new(doorOpen / 2 - 0.5, top + 5.2, zf + wallT / 2), style.trim)
	place(visual, "DoorTrimTop", Vector3.new(doorOpen, 1, 1.8), CFrame.new(0, top + 10.4, zf + wallT / 2), style.trim)
	place(visual, "DoorLeafL", Vector3.new(0.4, 9, 3.2), CFrame.new(-(doorOpen / 2 - 1.3), top + 4.5, zf + wallT + 1.6), Config.COLORS.woodDark)
	place(visual, "DoorLeafR", Vector3.new(0.4, 9, 3.2), CFrame.new(doorOpen / 2 - 1.3, top + 4.5, zf + wallT + 1.6), Config.COLORS.woodDark)
	place(visual, "Step", Vector3.new(doorOpen + 4, 0.6, 3), CFrame.new(0, top + 0.3, zf - 1.8), rgb(224, 216, 198))

	marker(model, "Door", Vector3.new(6, 9, 1), CFrame.new(0, top + 4.5, zf + wallT / 2)).Name = "Door"

	local arkZ = zi1 - 0.6
	place(visual, "ArkPanel", Vector3.new(10, wallH - 2.5, 0.3), CFrame.new(0, top + (wallH - 2.5) / 2 + 0.4, arkZ), style.curtain)
	place(visual, "ArkColumnL", Vector3.new(1.4, wallH - 2, 1.6), CFrame.new(-5.8, top + (wallH - 2) / 2, arkZ - 0.4), style.trim)
	place(visual, "ArkColumnR", Vector3.new(1.4, wallH - 2, 1.6), CFrame.new(5.8, top + (wallH - 2) / 2, arkZ - 0.4), style.trim)
	place(visual, "ArkArch", Vector3.new(13, 1.4, 1.6), CFrame.new(0, top + wallH - 2, arkZ - 0.4), style.trim)
	place(visual, "ArkStep1", Vector3.new(18, 0.6, 7), CFrame.new(0, top + 0.3, zi1 - 3.5), rgb(190, 150, 100))
	place(visual, "ArkStep2", Vector3.new(15, 1.2, 5), CFrame.new(0, top + 0.6, zi1 - 2.5), rgb(200, 160, 108))
	place(visual, "ArkStep3", Vector3.new(12, 1.8, 3.4), CFrame.new(0, top + 0.9, zi1 - 1.7), rgb(210, 170, 116))
	local platformTop = top + 1.8

	local bimahZ = zi1 - arkDepth + 1
	place(visual, "BimahPlatform", Vector3.new(9, 1.2, 5.5), CFrame.new(0, top + 0.6, bimahZ), rgb(200, 160, 108))
	place(visual, "Lectern", Vector3.new(2.6, 2.6, 1.6), CFrame.new(0, top + 1.2 + 1.3, bimahZ + 0.6), Config.COLORS.woodDark)
	place(visual, "LecternTop", Vector3.new(3, 0.3, 2), CFrame.new(0, top + 1.2 + 2.75, bimahZ + 0.4), style.trim)

	local seatIndex = 0
	local benchStart = zi0 + frontPad + 1.5
	local seatTop = top + 2.25
	local length = perBench * SEAT_SPACING
	for row = 1, rows do
		local z = benchStart + (row - 1) * ROW_SPACING
		for _, side in { -1, 1 } do
			local x = side * (aisle / 2 + 0.8 + length / 2)
			place(visual, "BenchBase", Vector3.new(length, 1.3, 1.5), CFrame.new(x, top + 0.65 + 0.2, z), Config.COLORS.woodDark)
			place(visual, "BenchSeat", Vector3.new(length, 0.5, 2), CFrame.new(x, top + 1.5 + 0.5, z), Config.COLORS.wood)
			place(visual, "BenchBack", Vector3.new(length, 2, 0.4), CFrame.new(x, top + 3, z - 1), Config.COLORS.woodDark)
			for k = 0, perBench - 1 do
				seatIndex += 1
				local sx = x - length / 2 + SEAT_SPACING / 2 + k * SEAT_SPACING
				marker(seats, "Seat" .. seatIndex, Vector3.new(2, 0.4, 2), CFrame.new(sx, seatTop, z))
			end
		end
	end

	local slotY = platformTop + 0.5
	local function slot(name, x, y, z)
		marker(slots, name, Vector3.new(1, 1, 1), CFrame.new(x, y, z))
	end
	slot("Slot_Ark", 0, slotY, zi1 - 2)
	for i = 1, 3 do
		slot("Slot_Torah" .. i, -(3.4 + i * 1.5) - 0.5, slotY, zi1 - 1.8)
		slot("Slot_Torah" .. (i + 3), 3.4 + i * 1.5 + 0.5, slotY, zi1 - 1.8)
	end
	for i = 1, 6 do
		local side = (i % 2 == 0) and 1 or -1
		local band = math.ceil(i / 2)
		slot("Slot_Ornament" .. i, side * (interiorW / 2 - 0.8), top + 5.5, zi0 + frontPad + band * ((interiorD - frontPad - arkDepth) / 4))
	end
	for i = 1, 4 do
		local side = (i % 2 == 0) and 1 or -1
		local row = math.ceil(i / 2)
		slot("Slot_Siddur" .. i, side * (aisle / 2 + 1.2), seatTop + 0.7, benchStart + (row - 1) * ROW_SPACING)
	end
	slot("Slot_Menorah", -(interiorW / 2 - 3.5), top + 1, zi1 - 5)
	place(visual, "KiddushTable", Vector3.new(4, 2.8, 2), CFrame.new(interiorW / 2 - 3.5, top + 1.4, zi1 - 5), Config.COLORS.woodDark)
	slot("Slot_Kiddush1", interiorW / 2 - 4.4, top + 3.3, zi1 - 5)
	slot("Slot_Kiddush2", interiorW / 2 - 2.6, top + 3.3, zi1 - 5)
	slot("Slot_Chandelier1", 0, top + wallH - 3, zi0 + interiorD * 0.35)
	slot("Slot_Chandelier2", 0, top + wallH - 3, zi0 + interiorD * 0.65)
	slot("Slot_HolidayDecor1", -(interiorW / 2 - 2), top + 6, zi0 + 3)
	slot("Slot_HolidayDecor2", interiorW / 2 - 2, top + 6, zi0 + 3)
	slot("Slot_HolidayDecor3", -(interiorW / 2 - 2), top + 6, (zi0 + zi1) / 2)
	slot("Slot_HolidayDecor4", interiorW / 2 - 2, top + 6, (zi0 + zi1) / 2)

	for _, side in { -1, 1 } do
		local x = side * (shellW / 2 + 3)
		place(visual, "Planter", Vector3.new(4, 1.6, 4), CFrame.new(x, top + 0.8 + 0.1, zf - 4), Config.COLORS.woodDark)
		place(visual, "PlanterBush", Vector3.new(3.2, 2.4, 3.2), CFrame.new(x, top + 2.6, zf - 4), Config.COLORS.leaf)
	end

	if tier >= 2 then
		local colX = { -(doorOpen / 2 + 2.5), doorOpen / 2 + 2.5 }
		if tier >= 3 then
			table.insert(colX, -(shellW / 2 - 1.5))
			table.insert(colX, shellW / 2 - 1.5)
		end
		for _, x in colX do
			place(visual, "Column", Vector3.new(1.5, wallH - 1, 1.5), CFrame.new(x, top + (wallH - 1) / 2, zf - 2.2), style.wall)
			place(visual, "ColumnCap", Vector3.new(2.2, 0.6, 2.2), CFrame.new(x, top + wallH - 0.7, zf - 2.2), style.trim)
		end
		place(visual, "PorticoRoof", Vector3.new(shellW - 1, 1, 4), CFrame.new(0, top + wallH - 0.1, zf - 2), style.roof)
	end
	if tier >= 3 then
		addTower(visual, style, -(shellW / 2 + 1), zf + 3, top, wallH + 4 + tier, 6)
	end
	if tier >= 5 then
		addTower(visual, style, shellW / 2 + 1, zf + 3, top, wallH + 4 + tier, 6)
	end
	if tier >= 7 then
		addTower(visual, style, -(shellW / 2 + 1), zb - 3, top, wallH + 8, 6)
		addTower(visual, style, shellW / 2 + 1, zb - 3, top, wallH + 8, 6)
	end
	if tier >= 4 then
		local dome = math.min(shellW * (0.3 + 0.05 * (tier - 4)), 26)
		cylinder(visual, "DomeDrum", dome * 0.8, 3, CFrame.new(0, roofTop + 1.5, (zf + zb) / 2), style.wall)
		ball(visual, "Dome", dome, CFrame.new(0, roofTop + 3 + dome * 0.18, (zf + zb) / 2), style.trim, Enum.Material.Neon)
		ball(visual, "DomeFinial", 1.4, CFrame.new(0, roofTop + 3 + dome * 0.6, (zf + zb) / 2), rgb(255, 255, 255), Enum.Material.Neon)
	end
	if tier >= 6 then
		for _, side in { -1, 1 } do
			place(visual, "GoldFence", Vector3.new(0.5, 2.4, plazaD - 3), CFrame.new(side * (floorW / 2 - 1), top + 1.2, -floorD / 2 + plazaD / 2), style.trim)
		end
	end

	return model, seatCount
end

return Procedural
