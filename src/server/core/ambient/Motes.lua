local Workspace = game:GetService("Workspace")

local core = script.Parent.Parent
local Config = require(core.Config)

local Motes = {
	name = "Motes",
	order = 10,
}

local FADE = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 1),
	NumberSequenceKeypoint.new(0.2, 0.15),
	NumberSequenceKeypoint.new(0.8, 0.2),
	NumberSequenceKeypoint.new(1, 1),
})

local GLOW = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 244, 200)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 218, 120)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 230, 255)),
})

local function cloud(parent, name, position, size, rate)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Position = position
	part.Transparency = 1
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Parent = parent
	local emitter = Instance.new("ParticleEmitter")
	emitter.Shape = Enum.ParticleEmitterShape.Box
	emitter.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
	emitter.Rate = rate
	emitter.Lifetime = NumberRange.new(6, 9)
	emitter.Speed = NumberRange.new(0.4, 1.6)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Acceleration = Vector3.new(0, 0.5, 0)
	emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(0.5, 0.8), NumberSequenceKeypoint.new(1, 0.4) })
	emitter.Color = GLOW
	emitter.LightEmission = 1
	emitter.Transparency = FADE
	emitter.Rotation = NumberRange.new(0, 360)
	emitter.RotSpeed = NumberRange.new(-40, 40)
	emitter.Parent = part
end

function Motes.build()
	local container = Instance.new("Folder")
	container.Name = "CoreMotes"
	cloud(container, "Plaza", Vector3.new(0, 16, 0), Vector3.new(Config.PLAZA_RADIUS * 2, 26, Config.PLAZA_RADIUS * 2), 34)
	local plots = Workspace:FindFirstChild("Plots")
	if plots then
		for _, plot in plots:GetChildren() do
			local land = plot:FindFirstChild("Land")
			if land then
				cloud(container, plot.Name, land.Position + Vector3.new(0, 14, 0), Vector3.new(land.Size.X, 22, land.Size.Z), 14)
			end
		end
	end
	container.Parent = Workspace
end

return Motes
