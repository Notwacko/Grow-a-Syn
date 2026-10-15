local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local core = script.Parent.Parent
local Procedural = require(core.Procedural)

local Balloons = {
	name = "Balloons",
	order = 30,
}

local place = Procedural.place

local COUNT = 14
local STEP = 1 / 15

local COLORS = {
	Color3.fromRGB(255, 82, 82),
	Color3.fromRGB(255, 177, 66),
	Color3.fromRGB(255, 232, 80),
	Color3.fromRGB(88, 214, 141),
	Color3.fromRGB(80, 160, 255),
	Color3.fromRGB(180, 120, 255),
}

local SOFT = { CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false }

function Balloons.build()
	local container = Instance.new("Folder")
	container.Name = "CoreBalloons"
	local rng = Random.new(31415)
	local items = {}
	for index = 1, COUNT do
		local size = rng:NextNumber(20, 30)
		local color = COLORS[(index - 1) % #COLORS + 1]
		local item = {
			size = size,
			angle = rng:NextNumber(0, math.pi * 2),
			radius = rng:NextNumber(110, 430),
			height = rng:NextNumber(110, 200),
			speed = rng:NextNumber(0.012, 0.03) * (index % 2 == 0 and 1 or -1),
			phase = rng:NextNumber(0, 6.28),
		}
		item.body = place(container, "Balloon", Vector3.one * size, CFrame.new(), color, Enum.Material.SmoothPlastic, { Shape = Enum.PartType.Ball, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false })
		item.knot = place(container, "Knot", Vector3.new(2.4, 2.8, 2.4), CFrame.new(), color, nil, SOFT)
		item.cord = place(container, "Cord", Vector3.new(0.3, size * 0.9, 0.3), CFrame.new(), Color3.fromRGB(245, 245, 250), nil, SOFT)
		items[index] = item
	end
	container.Parent = Workspace

	local parts = table.create(COUNT * 3)
	local frames = table.create(COUNT * 3)
	local accumulator = 0
	RunService.Heartbeat:Connect(function(dt)
		accumulator += dt
		if accumulator < STEP then
			return
		end
		local elapsed = accumulator
		accumulator = 0
		local now = os.clock()
		for index, item in items do
			item.angle += item.speed * elapsed
			local sway = math.sin(now * 0.8 + item.phase)
			local center = Vector3.new(math.cos(item.angle) * item.radius, item.height + sway * 3, math.sin(item.angle) * item.radius)
			local tilt = CFrame.Angles(sway * 0.05, 0, math.cos(now * 0.6 + item.phase) * 0.05)
			local slot = (index - 1) * 3
			parts[slot + 1] = item.body
			frames[slot + 1] = CFrame.new(center) * tilt
			parts[slot + 2] = item.knot
			frames[slot + 2] = CFrame.new(center - Vector3.new(0, item.size / 2 + 1, 0)) * tilt
			parts[slot + 3] = item.cord
			frames[slot + 3] = CFrame.new(center - Vector3.new(0, item.size / 2 + 2.4 + item.size * 0.45, 0)) * tilt
		end
		Workspace:BulkMoveTo(parts, frames, Enum.BulkMoveMode.FireCFrameChanged)
	end)
end

return Balloons
