local CosmeticFx = {}

local SPARKLE = "rbxasset://textures/particles/sparkles_main.dds"
local SOFT = "rbxasset://textures/particles/smoke_main.dds"

local function emitter(parent, props)
	local particle = Instance.new("ParticleEmitter")
	particle.Name = "CoreEffect"
	particle.Texture = props.texture or SPARKLE
	particle.Rate = props.rate or 8
	particle.Lifetime = props.lifetime or NumberRange.new(1, 1.6)
	particle.Speed = props.speed or NumberRange.new(0.5, 2)
	particle.SpreadAngle = props.spread or Vector2.new(180, 180)
	particle.Size = props.size or NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0) })
	particle.Color = props.color or ColorSequence.new(Color3.new(1, 1, 1))
	particle.LightEmission = props.emission or 0.8
	particle.Transparency = props.transparency or NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) })
	particle.Acceleration = props.acceleration or Vector3.zero
	particle.EmissionDirection = props.direction or Enum.NormalId.Top
	particle.RotSpeed = props.rotSpeed or NumberRange.new(-60, 60)
	particle.Rotation = NumberRange.new(0, 360)
	particle.Shape = props.shape or Enum.ParticleEmitterShape.Box
	particle.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
	particle.Parent = parent
	return particle
end

local function gradient(...)
	local colors = { ... }
	local keys = {}
	for index, color in colors do
		table.insert(keys, ColorSequenceKeypoint.new((index - 1) / math.max(#colors - 1, 1), color))
	end
	return ColorSequence.new(keys)
end

local BUILDERS = {}

function BUILDERS.sparkle(root)
	emitter(root, {
		rate = 10,
		color = gradient(Color3.fromRGB(255, 240, 160), Color3.fromRGB(255, 190, 60)),
		size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.7), NumberSequenceKeypoint.new(1, 0) }),
		speed = NumberRange.new(0.5, 1.5),
		acceleration = Vector3.new(0, 1.5, 0),
	})
end

function BUILDERS.stars(root)
	emitter(root, {
		rate = 14,
		color = gradient(Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 226, 120), Color3.fromRGB(150, 200, 255)),
		size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.9), NumberSequenceKeypoint.new(0.5, 0.6), NumberSequenceKeypoint.new(1, 0) }),
		lifetime = NumberRange.new(1.2, 2),
		speed = NumberRange.new(1, 3),
		acceleration = Vector3.new(0, 2, 0),
	})
end

function BUILDERS.hearts(root)
	emitter(root, {
		rate = 6,
		color = gradient(Color3.fromRGB(255, 130, 170), Color3.fromRGB(255, 80, 130)),
		size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(0.4, 1), NumberSequenceKeypoint.new(1, 0) }),
		lifetime = NumberRange.new(1.4, 2.2),
		speed = NumberRange.new(0.5, 1.2),
		acceleration = Vector3.new(0, 2.5, 0),
		texture = SOFT,
		emission = 0.4,
	})
end

function BUILDERS.snow(root)
	emitter(root, {
		rate = 16,
		color = gradient(Color3.new(1, 1, 1)),
		size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 0.2) }),
		lifetime = NumberRange.new(2, 3),
		speed = NumberRange.new(0, 0.5),
		acceleration = Vector3.new(0, -2, 0),
		texture = SOFT,
		emission = 0.2,
		shape = Enum.ParticleEmitterShape.Box,
	})
end

function BUILDERS.leaves(root)
	emitter(root, {
		rate = 5,
		color = gradient(Color3.fromRGB(120, 200, 80), Color3.fromRGB(240, 160, 50), Color3.fromRGB(200, 90, 40)),
		size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0.4) }),
		lifetime = NumberRange.new(2, 3),
		speed = NumberRange.new(0.3, 1),
		acceleration = Vector3.new(0, -1.6, 0),
		texture = SOFT,
		emission = 0,
		transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) }),
	})
end

function BUILDERS.confetti(root)
	emitter(root, {
		rate = 12,
		color = gradient(Color3.fromRGB(255, 80, 100), Color3.fromRGB(255, 214, 80), Color3.fromRGB(94, 214, 130), Color3.fromRGB(86, 156, 255), Color3.fromRGB(176, 124, 255)),
		size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 0.3) }),
		lifetime = NumberRange.new(1.6, 2.4),
		speed = NumberRange.new(2, 5),
		acceleration = Vector3.new(0, -5, 0),
		texture = SPARKLE,
		emission = 0.3,
		spread = Vector2.new(60, 60),
		transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.8, 0), NumberSequenceKeypoint.new(1, 1) }),
	})
end

function BUILDERS.glow(root)
	local light = Instance.new("PointLight")
	light.Name = "CoreEffect"
	light.Color = Color3.fromRGB(255, 214, 140)
	light.Range = 14
	light.Brightness = 1.4
	light.Shadows = false
	light.Parent = root
	emitter(root, {
		rate = 4,
		color = gradient(Color3.fromRGB(255, 226, 160)),
		size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 0) }),
		speed = NumberRange.new(0.2, 0.8),
	})
end

function BUILDERS.rainbow(root)
	local top = Instance.new("Attachment")
	top.Name = "CoreEffectTop"
	top.Position = Vector3.new(0, 0.9, 0)
	top.Parent = root
	local bottom = Instance.new("Attachment")
	bottom.Name = "CoreEffectBottom"
	bottom.Position = Vector3.new(0, -1.2, 0)
	bottom.Parent = root
	local trail = Instance.new("Trail")
	trail.Name = "CoreEffect"
	trail.Attachment0 = top
	trail.Attachment1 = bottom
	trail.Lifetime = 0.9
	trail.MinLength = 0.1
	trail.LightEmission = 0.6
	trail.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1) })
	trail.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 80, 80)),
		ColorSequenceKeypoint.new(0.2, Color3.fromRGB(255, 170, 60)),
		ColorSequenceKeypoint.new(0.4, Color3.fromRGB(255, 240, 80)),
		ColorSequenceKeypoint.new(0.6, Color3.fromRGB(90, 220, 120)),
		ColorSequenceKeypoint.new(0.8, Color3.fromRGB(80, 160, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 110, 255)),
	})
	trail.Parent = root
end

function CosmeticFx.clear(character)
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then
		return
	end
	for _, child in root:GetChildren() do
		if child.Name == "CoreEffect" or child.Name == "CoreEffectTop" or child.Name == "CoreEffectBottom" then
			child:Destroy()
		end
	end
end

function CosmeticFx.apply(character, effectId)
	CosmeticFx.clear(character)
	local root = character:FindFirstChild("HumanoidRootPart")
	local builder = effectId and BUILDERS[effectId]
	if root and builder then
		builder(root)
	end
end

function CosmeticFx.has(effectId)
	return BUILDERS[effectId] ~= nil
end

return CosmeticFx
