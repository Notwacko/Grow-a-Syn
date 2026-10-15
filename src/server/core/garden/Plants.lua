local core = script.Parent.Parent
local Procedural = require(core.Procedural)

local Plants = {}

local place = Procedural.place
local cylinder = Procedural.cylinder
local ball = Procedural.ball

local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

local LEAF = rgb(76, 168, 66)
local LEAF_DARK = rgb(56, 138, 56)
local WOOD = rgb(128, 90, 56)
local STAGE_SCALE = { 0.22, 0.45, 0.75, 1 }
local RAINBOW = { rgb(255, 82, 82), rgb(255, 177, 66), rgb(255, 241, 87), rgb(88, 214, 141), rgb(80, 160, 255), rgb(180, 120, 255) }

local function fruit(model, kind, diameter, position, color, material)
	local part = ball(model, "Fruit", diameter, CFrame.new(position), color, material or Enum.Material.SmoothPlastic)
	part:SetAttribute("Base", color)
	return part
end

local function fruitBlock(model, size, cframe, color)
	local part = place(model, "Fruit", size, cframe, color, Enum.Material.SmoothPlastic)
	part:SetAttribute("Base", color)
	return part
end

local builders = {}

function builders.wheat(model)
	for index = 1, 9 do
		local angle = index * math.rad(40)
		local radius = 0.3 + (index % 3) * 0.24
		local x, z = math.cos(angle) * radius, math.sin(angle) * radius
		local lean = CFrame.Angles(math.cos(angle) * 0.08, 0, -math.sin(angle) * 0.08)
		cylinder(model, "Stalk", 0.15, 3, CFrame.new(x, 1.5, z) * lean, rgb(222, 196, 96))
		fruitBlock(model, Vector3.new(0.34, 1.1, 0.34), CFrame.new(x * 1.05, 3.5, z * 1.05) * lean, rgb(238, 192, 62))
	end
	for index = 1, 4 do
		local angle = index * math.rad(90) + 0.4
		place(model, "Leaf", Vector3.new(0.18, 1.6, 0.5), CFrame.new(math.cos(angle) * 0.7, 0.8, math.sin(angle) * 0.7) * CFrame.Angles(0, -angle, math.rad(25)), LEAF)
	end
end

function builders.barley(model)
	for index = 1, 8 do
		local angle = index * math.rad(45) + 0.2
		local radius = 0.3 + (index % 2) * 0.35
		local x, z = math.cos(angle) * radius, math.sin(angle) * radius
		cylinder(model, "Stalk", 0.13, 2.7, CFrame.new(x, 1.35, z), rgb(204, 190, 120))
		fruitBlock(model, Vector3.new(0.3, 1.2, 0.3), CFrame.new(x, 3.25, z), rgb(224, 200, 130))
		for side = -1, 1, 2 do
			place(model, "Whisker", Vector3.new(0.05, 1, 0.05), CFrame.new(x + side * 0.16, 3.9, z) * CFrame.Angles(0, 0, side * -0.3), rgb(226, 214, 150))
		end
	end
	for index = 1, 4 do
		local angle = index * math.rad(90)
		place(model, "Leaf", Vector3.new(0.16, 1.5, 0.45), CFrame.new(math.cos(angle) * 0.75, 0.75, math.sin(angle) * 0.75) * CFrame.Angles(0, -angle, math.rad(22)), LEAF_DARK)
	end
end

function builders.grapes(model)
	for _, x in { -1.9, 1.9 } do
		place(model, "Post", Vector3.new(0.4, 4.6, 0.4), CFrame.new(x, 2.3, 0), WOOD)
	end
	place(model, "Crossbar", Vector3.new(4.4, 0.32, 0.32), CFrame.new(0, 4.4, 0), WOOD)
	cylinder(model, "Vine", 0.28, 4.2, CFrame.new(0, 2.1, 0), rgb(110, 96, 60))
	for index = 1, 7 do
		local x = -1.8 + (index - 1) * 0.6
		place(model, "Leaf", Vector3.new(1, 0.08, 1), CFrame.new(x, 4.55 + (index % 2) * 0.15, (index % 3 - 1) * 0.3) * CFrame.Angles(0.2, index, 0.15), index % 2 == 0 and LEAF or LEAF_DARK)
	end
	local layout = { { 0, 0 }, { -0.26, 0.45 }, { 0.26, 0.45 }, { -0.5, 0.9 }, { 0, 0.9 }, { 0.5, 0.9 }, { 0, 1.35 } }
	for _, cx in { -1.2, 0, 1.2 } do
		for _, offset in layout do
			fruit(model, "grape", 0.52, Vector3.new(cx + offset[1], 3.9 - offset[2], (offset[1] * 7) % 0.3), rgb(110, 54, 150))
		end
	end
end

function builders.figs(model)
	cylinder(model, "Trunk", 0.8, 2.4, CFrame.new(0, 1.2, 0), WOOD)
	for _, spec in { { 0, 3.7, 0, 3.4 }, { -1.2, 3.2, 0.5, 2.6 }, { 1.1, 3.3, -0.5, 2.7 }, { 0.2, 4.4, 0.3, 2.2 } } do
		ball(model, "Canopy", spec[4], CFrame.new(spec[1], spec[2], spec[3]), LEAF)
	end
	local spots = { { 2.1, 2.6, 0.7 }, { -2.3, 2.5, 0.2 }, { 0.5, 2.3, 2.2 }, { -0.8, 2.4, -2.1 }, { 1.6, 2.7, -1.6 }, { -1.5, 2.6, 1.8 }, { 0.2, 2.2, -0.1 } }
	for _, spot in spots do
		fruit(model, "fig", 0.8, Vector3.new(spot[1], spot[2], spot[3]), rgb(116, 58, 104))
	end
end

function builders.olives(model)
	cylinder(model, "Trunk", 0.6, 2.6, CFrame.new(-0.2, 1.3, 0) * CFrame.Angles(0, 0, 0.1), rgb(128, 108, 88))
	cylinder(model, "Trunk", 0.5, 2.4, CFrame.new(0.35, 1.3, 0.1) * CFrame.Angles(0, 0, -0.15), rgb(120, 100, 82))
	for _, spec in { { 0, 3.8, 0, 2.8 }, { -1.3, 3.4, 0.4, 2.4 }, { 1.2, 3.5, -0.3, 2.5 }, { 0.1, 4.6, 0.2, 2 } } do
		ball(model, "Canopy", spec[4], CFrame.new(spec[1], spec[2], spec[3]), rgb(150, 178, 128))
	end
	local rng = Random.new(7)
	for index = 1, 16 do
		local angle = index * 0.85
		local radius = 1.55 + rng:NextNumber() * 0.5
		local color = index % 3 == 0 and rgb(48, 52, 44) or rgb(124, 154, 70)
		fruit(model, "olive", 0.46, Vector3.new(math.cos(angle) * radius, 3.0 + rng:NextNumber() * 1.3, math.sin(angle) * radius), color)
	end
end

function builders.pomegranate(model)
	cylinder(model, "Trunk", 0.5, 1.2, CFrame.new(0, 0.6, 0), WOOD)
	for _, spec in { { 0, 2.0, 0, 2.6 }, { -1.1, 1.7, 0.5, 2 }, { 1.0, 1.8, -0.4, 2.1 }, { 0.1, 2.9, 0.1, 1.7 } } do
		ball(model, "Canopy", spec[4], CFrame.new(spec[1], spec[2], spec[3]), rgb(70, 142, 60))
	end
	for _, spot in { { 1.3, 1.5, 0.7 }, { -1.4, 1.4, 0.1 }, { 0.3, 1.3, 1.5 }, { -0.5, 2.5, 1.0 }, { 0.9, 2.6, -0.9 } } do
		fruit(model, "pomegranate", 1.0, Vector3.new(spot[1], spot[2], spot[3]), rgb(200, 48, 64))
		fruitBlock(model, Vector3.new(0.34, 0.2, 0.34), CFrame.new(spot[1], spot[2] + 0.55, spot[3]), rgb(150, 30, 46))
	end
end

function builders.dates(model)
	local height = 0
	for index = 1, 4 do
		local diameter = 0.95 - index * 0.07
		cylinder(model, "Trunk", diameter, 1.45, CFrame.new(index * 0.04, height + 0.72, 0) * CFrame.Angles(0, 0, -0.03 * index), rgb(132, 94, 58))
		height += 1.4
	end
	for index = 1, 8 do
		local angle = index * math.rad(45)
		place(model, "Frond", Vector3.new(0.4, 0.14, 4.4), CFrame.new(0.15, height + 0.2, 0) * CFrame.Angles(0, angle, 0) * CFrame.Angles(math.rad(-22), 0, 0) * CFrame.new(0, 0, -2.1), rgb(72, 152, 66))
	end
	for _, cx in { -0.7, 0.7 } do
		for index = 1, 7 do
			fruit(model, "date", 0.46, Vector3.new(cx + ((index * 37) % 5 - 2) * 0.11, height - 0.5 - (index % 4) * 0.28, ((index * 53) % 5 - 2) * 0.12), rgb(178, 96, 40))
		end
	end
end

function Plants.make(cropId)
	local builder = builders[cropId]
	if not builder then
		return nil
	end
	local model = Instance.new("Model")
	model.Name = "Plant_" .. cropId
	local root = place(model, "Root", Vector3.new(0.2, 0.2, 0.2), CFrame.new(), Color3.new(1, 1, 1), nil, { Transparency = 1 })
	model.PrimaryPart = root
	builder(model)
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.CanCollide = false
			part.CanQuery = false
			part.CanTouch = false
			part.CastShadow = false
			part.Massless = true
		end
	end
	local glow = Instance.new("ParticleEmitter")
	glow.Name = "RipeGlow"
	glow.Enabled = false
	glow.Rate = 5
	glow.Lifetime = NumberRange.new(1.2, 2)
	glow.Speed = NumberRange.new(1, 2.5)
	glow.SpreadAngle = Vector2.new(60, 60)
	glow.EmissionDirection = Enum.NormalId.Top
	glow.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0) })
	glow.Color = ColorSequence.new(rgb(255, 250, 200), rgb(255, 214, 80))
	glow.LightEmission = 1
	glow.Parent = root
	return model
end

function Plants.setStage(model, stage)
	stage = math.clamp(stage, 0, 3)
	model:ScaleTo(STAGE_SCALE[stage + 1])
	local ripe = stage >= 3
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") and part.Name == "Fruit" then
			part.Transparency = ripe and 0 or 1
		end
	end
	local glow = model.PrimaryPart and model.PrimaryPart:FindFirstChild("RipeGlow")
	if glow then
		glow.Enabled = ripe
	end
end

local function mutationEmitter(root, mutation, rate, color)
	local name = "Mut_" .. mutation
	if root:FindFirstChild(name) then
		return
	end
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = name
	emitter.Rate = rate
	emitter.Lifetime = NumberRange.new(1, 1.8)
	emitter.Speed = NumberRange.new(0.5, 2)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Acceleration = Vector3.new(0, mutation == "wet" and -3 or 1, 0)
	emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.45), NumberSequenceKeypoint.new(1, 0) })
	emitter.Color = ColorSequence.new(color)
	emitter.LightEmission = 0.8
	emitter.Parent = root
end

function Plants.applyMutations(model, mutationIds)
	local root = model.PrimaryPart
	local set = {}
	for _, id in mutationIds do
		set[id] = true
	end
	local index = 0
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") and part.Name == "Fruit" then
			index += 1
			if set.rainbow then
				part.Color = RAINBOW[index % #RAINBOW + 1]
				part.Material = Enum.Material.Neon
			elseif set.golden then
				part.Color = rgb(255, 200, 40)
				part.Material = Enum.Material.Neon
			else
				part.Color = part:GetAttribute("Base") or part.Color
				part.Material = Enum.Material.SmoothPlastic
			end
			part.Reflectance = set.wet and 0.3 or 0
		end
	end
	if set.golden and not set.rainbow then
		mutationEmitter(root, "golden", 8, rgb(255, 214, 80))
	end
	if set.rainbow then
		mutationEmitter(root, "rainbow", 12, rgb(255, 150, 220))
	end
	if set.wet then
		mutationEmitter(root, "wet", 5, rgb(120, 190, 255))
	end
	if set.sunlit then
		mutationEmitter(root, "sunlit", 4, rgb(255, 224, 120))
	end
end

function Plants.has(cropId)
	return builders[cropId] ~= nil
end

return Plants
