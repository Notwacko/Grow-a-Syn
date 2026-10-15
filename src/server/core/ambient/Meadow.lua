local Workspace = game:GetService("Workspace")

local core = script.Parent.Parent
local Config = require(core.Config)
local Props = require(core.Props)
local Procedural = require(core.Procedural)

local Meadow = {
	name = "Meadow",
	order = 5,
}

local place = Procedural.place

local FLOWER_COLORS = {
	Color3.fromRGB(255, 99, 132),
	Color3.fromRGB(255, 205, 66),
	Color3.fromRGB(176, 124, 255),
	Color3.fromRGB(255, 255, 255),
	Color3.fromRGB(86, 176, 255),
	Color3.fromRGB(255, 154, 72),
}

local STEM = Color3.fromRGB(52, 160, 56)
local ROCK = Color3.fromRGB(168, 172, 184)
local SOFT = { CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false }

local CLUSTERS = 150
local PER_CLUSTER = 6
local ROCKS = 70
local TREES = 70

local function blocked(point, frames)
	if Vector3.new(point.X, 0, point.Z).Magnitude < Config.PLAZA_RADIUS + 16 then
		return true
	end
	local pathLength = Config.PLOT_FRONT_RADIUS - Config.PLAZA_RADIUS + 14
	for _, frame in frames do
		local rel = frame:PointToObjectSpace(point)
		if math.abs(rel.X) < 104 and rel.Z > -26 and rel.Z < 266 then
			return true
		end
		if math.abs(rel.X) < 16 and rel.Z <= 0 and rel.Z > -pathLength then
			return true
		end
	end
	return false
end

function Meadow.build()
	if not Workspace:FindFirstChild("World") then
		return
	end
	local old = Workspace:FindFirstChild("Meadow")
	if old then
		old:Destroy()
	end
	local rng = Random.new(20261014)
	local frames = {}
	for index = 1, 8 do
		frames[index] = Config.plotFrame(index)
	end
	local half = Config.GROUND_SIZE / 2 - 50
	local container = Instance.new("Folder")
	container.Name = "Meadow"

	local function sample(minRadial)
		for _ = 1, 40 do
			local point = Vector3.new(rng:NextNumber(-half, half), Config.GROUND_Y, rng:NextNumber(-half, half))
			if Vector3.new(point.X, 0, point.Z).Magnitude >= minRadial and not blocked(point, frames) then
				return point
			end
		end
		return nil
	end

	local wildflowers = Props.has("wildflower")
	for _ = 1, wildflowers and 110 or CLUSTERS do
		local center = sample(0)
		if center and wildflowers then
			local patch = Props.make("wildflower", "wildflower")
			if patch then
				patch:ScaleTo(patch:GetScale() * rng:NextNumber(0.9, 1.5))
				patch:PivotTo(CFrame.new(center) * CFrame.Angles(0, rng:NextNumber(0, 6.28), 0))
				patch.Parent = container
			end
		elseif center then
			for _ = 1, PER_CLUSTER do
				local x = center.X + rng:NextNumber(-7, 7)
				local z = center.Z + rng:NextNumber(-7, 7)
				local height = rng:NextNumber(2.2, 4)
				place(container, "Stem", Vector3.new(0.4, height, 0.4), CFrame.new(x, height / 2, z), STEM, nil, SOFT)
				place(container, "Bloom", Vector3.new(1.7, 1.3, 1.7), CFrame.new(x, height + 0.3, z) * CFrame.Angles(0, rng:NextNumber(0, 6.28), 0), FLOWER_COLORS[rng:NextInteger(1, #FLOWER_COLORS)], nil, SOFT)
			end
		end
	end

	for index = 1, ROCKS do
		local point = sample(0)
		if point then
			local rock = Props.make("rock", "rock")
			local bush = nil
			if rock and index % 3 == 0 then
				rock:Destroy()
				rock = nil
				bush = Props.make("bush", "bush")
			end
			local model = rock or bush
			if model then
				model:ScaleTo(model:GetScale() * rng:NextNumber(0.8, 1.6))
				model:PivotTo(CFrame.new(point) * CFrame.Angles(0, rng:NextNumber(0, 6.28), 0))
				model.Parent = container
			else
				local size = Vector3.new(rng:NextNumber(2, 5), rng:NextNumber(1.4, 3), rng:NextNumber(2, 5))
				place(container, "Rock", size, CFrame.new(point.X, size.Y / 2 - 0.3, point.Z) * CFrame.Angles(rng:NextNumber(-0.3, 0.3), rng:NextNumber(0, 6.28), rng:NextNumber(-0.3, 0.3)), ROCK, nil, SOFT)
			end
		end
	end

	for _ = 1, TREES do
		local point = sample(150)
		if point then
			local tree = Props.make("tree")
			if tree then
				tree:ScaleTo(tree:GetScale() * rng:NextNumber(0.95, 1.8))
				tree:PivotTo(CFrame.new(point) * CFrame.Angles(0, rng:NextNumber(0, 6.28), 0))
				tree.Parent = container
			end
		end
	end

	container.Parent = Workspace
end

return Meadow
