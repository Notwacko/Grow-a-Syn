local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Fx = {}

local folder
local alive = 0
local Config = require(script.Parent.Config)

local RAINBOW = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 82, 82)),
	ColorSequenceKeypoint.new(0.2, Color3.fromRGB(255, 177, 66)),
	ColorSequenceKeypoint.new(0.4, Color3.fromRGB(255, 241, 87)),
	ColorSequenceKeypoint.new(0.6, Color3.fromRGB(88, 214, 141)),
	ColorSequenceKeypoint.new(0.8, Color3.fromRGB(80, 160, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 120, 255)),
})

local GOLD = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 226, 110)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 190, 40)),
})

local DUST = ColorSequence.new(Color3.fromRGB(235, 225, 200))

local FADE = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0),
	NumberSequenceKeypoint.new(0.7, 0),
	NumberSequenceKeypoint.new(1, 1),
})

local function fxFolder()
	if folder and folder.Parent then
		return folder
	end
	folder = Workspace:FindFirstChild("CoreFx")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "CoreFx"
		folder.Parent = Workspace
	end
	return folder
end

local function anchorPart(position, lifetime)
	local part = Instance.new("Part")
	part.Name = "Fx"
	part.Size = Vector3.new(0.2, 0.2, 0.2)
	part.Transparency = 1
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Position = position
	part.Parent = fxFolder()
	Debris:AddItem(part, lifetime)
	alive += 1
	part.Destroying:Connect(function()
		alive -= 1
	end)
	return part
end

local function burst(position, config)
	local part = anchorPart(position, config.lifetime + 1.5)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Enabled = false
	emitter.Rate = config.rate
	emitter.Lifetime = NumberRange.new(config.lifetime * 0.6, config.lifetime)
	emitter.Speed = NumberRange.new(config.speedMin, config.speedMax)
	emitter.SpreadAngle = Vector2.new(config.spread, config.spread)
	emitter.Acceleration = Vector3.new(0, config.gravity, 0)
	emitter.Size = NumberSequence.new(config.size)
	emitter.Color = config.color
	emitter.LightEmission = config.glow
	emitter.Rotation = NumberRange.new(0, 360)
	emitter.RotSpeed = NumberRange.new(-240, 240)
	emitter.Transparency = FADE
	emitter.EmissionDirection = Enum.NormalId.Top
	emitter.Parent = part
	emitter.Enabled = true
	task.delay(config.duration, function()
		if emitter.Parent then
			emitter.Enabled = false
		end
	end)
end

function Fx.sparkle(position)
	if alive >= Config.MAX_FX_PARTS then
		return
	end
	burst(position, {
		rate = 140,
		duration = 0.15,
		lifetime = 1,
		speedMin = 6,
		speedMax = 14,
		spread = 180,
		gravity = -6,
		size = 0.9,
		color = GOLD,
		glow = 1,
	})
end

function Fx.confetti(position, power)
	power = power or 1
	burst(position, {
		rate = 260 * power,
		duration = 0.4,
		lifetime = 2.4,
		speedMin = 28 * power,
		speedMax = 60 * power,
		spread = 55,
		gravity = -46,
		size = 0.8,
		color = RAINBOW,
		glow = 0.2,
	})
end

function Fx.puff(position)
	if alive >= Config.MAX_FX_PARTS then
		return
	end
	burst(position, {
		rate = 90,
		duration = 0.2,
		lifetime = 1.1,
		speedMin = 4,
		speedMax = 12,
		spread = 180,
		gravity = 1,
		size = 2.2,
		color = DUST,
		glow = 0,
	})
end

function Fx.ring(position, color, radius)
	local part = Instance.new("Part")
	part.Name = "FxRing"
	part.Shape = Enum.PartType.Cylinder
	part.Size = Vector3.new(0.4, 2, 2)
	part.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.pi / 2)
	part.Color = color or Color3.fromRGB(255, 226, 110)
	part.Material = Enum.Material.Neon
	part.Transparency = 0.2
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Parent = fxFolder()
	Debris:AddItem(part, 1.2)
	local size = (radius or 30) * 2
	TweenService:Create(part, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(0.4, size, size),
		Transparency = 1,
	}):Play()
end

local FIREWORK_COLORS = {
	Color3.fromRGB(255, 82, 82),
	Color3.fromRGB(255, 205, 66),
	Color3.fromRGB(94, 226, 130),
	Color3.fromRGB(86, 176, 255),
	Color3.fromRGB(190, 130, 255),
	Color3.fromRGB(255, 154, 72),
}

function Fx.sound(position, soundId, volume, pitch)
	local part = anchorPart(position, 3)
	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = volume or 0.6
	sound.PlaybackSpeed = pitch or 1
	sound.RollOffMode = Enum.RollOffMode.InverseTapered
	sound.RollOffMinDistance = 20
	sound.RollOffMaxDistance = 160
	sound.Parent = part
	sound:Play()
end

local function flash(position, color)
	local part = anchorPart(position, 1)
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = 70
	light.Brightness = 4.5
	light.Shadows = false
	light.Parent = part
	TweenService:Create(light, TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Brightness = 0,
		Range = 20,
	}):Play()
end

function Fx.firework(position, color, height)
	if alive >= Config.MAX_FX_PARTS then
		return
	end
	color = color or FIREWORK_COLORS[math.random(#FIREWORK_COLORS)]
	height = height or 44
	local rocket = anchorPart(position, 3)
	rocket.Size = Vector3.new(1.6, 4, 1.6)
	rocket.Transparency = 0
	rocket.Color = color
	rocket.Material = Enum.Material.Neon
	local tail = Instance.new("ParticleEmitter")
	tail.Rate = 90
	tail.Lifetime = NumberRange.new(0.4, 0.7)
	tail.Speed = NumberRange.new(0, 2)
	tail.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 3), NumberSequenceKeypoint.new(1, 0) })
	tail.Color = ColorSequence.new(color, Color3.new(1, 1, 1))
	tail.LightEmission = 1
	tail.Parent = rocket
	Fx.sound(position, Config.SOUNDS.launch, 0.35, 1.2)
	local travel = 0.85 + math.random() * 0.2
	TweenService:Create(rocket, TweenInfo.new(travel, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = position + Vector3.new(0, height, 0),
	}):Play()
	task.delay(travel, function()
		if not rocket.Parent then
			return
		end
		local top = rocket.Position
		rocket:Destroy()
		burst(top, {
			rate = 1100,
			duration = 0.14,
			lifetime = 2.4,
			speedMin = 24,
			speedMax = 48,
			spread = 180,
			gravity = -18,
			size = 3.4,
			color = ColorSequence.new(color, Color3.new(1, 1, 1)),
			glow = 1,
		})
		burst(top, {
			rate = 400,
			duration = 0.1,
			lifetime = 1.4,
			speedMin = 8,
			speedMax = 20,
			spread = 180,
			gravity = -8,
			size = 2.2,
			color = GOLD,
			glow = 1,
		})
		flash(top, color)
		Fx.sound(top, Config.SOUNDS.pop, 0.7, 0.7)
	end)
end

function Fx.beaconFolder()
	local container = Workspace:FindFirstChild("CoreBeacons")
	if not container then
		container = Instance.new("Folder")
		container.Name = "CoreBeacons"
		container.Parent = Workspace
	end
	return container
end

function Fx.beacon(position, height, color, thickness)
	thickness = thickness or 1
	local model = Instance.new("Model")
	model.Name = "Beacon"
	local function glass(name, shape, size, cframe, transparency)
		local part = Instance.new("Part")
		part.Name = name
		part.Anchored = true
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.CastShadow = false
		part.Material = Enum.Material.Neon
		part.Color = color
		part.Shape = shape
		part.Size = size
		part.CFrame = cframe
		part.Transparency = transparency
		part.Parent = model
		return part
	end
	local upright = CFrame.new(position + Vector3.new(0, height / 2, 0)) * CFrame.Angles(0, 0, math.pi / 2)
	glass("Shaft", Enum.PartType.Cylinder, Vector3.new(height, 9 * thickness, 9 * thickness), upright, 0.74)
	glass("Core", Enum.PartType.Cylinder, Vector3.new(height, 2 * thickness, 2 * thickness), upright, 0.3)
	local star = glass("Star", Enum.PartType.Ball, Vector3.one * 8 * thickness, CFrame.new(position + Vector3.new(0, height + 3, 0)), 0.1)
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = 60
	light.Brightness = 2.5
	light.Shadows = false
	light.Parent = star
	local base = glass("Base", Enum.PartType.Ball, Vector3.one * 3, CFrame.new(position + Vector3.new(0, 1, 0)), 1)
	local rise = Instance.new("ParticleEmitter")
	rise.Rate = 8 + thickness * 4
	rise.Lifetime = NumberRange.new(6, 7)
	rise.Speed = NumberRange.new(height / 7, height / 6)
	rise.SpreadAngle = Vector2.new(4, 4)
	rise.EmissionDirection = Enum.NormalId.Top
	rise.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.4), NumberSequenceKeypoint.new(1, 0.3) })
	rise.Color = ColorSequence.new(Color3.new(1, 1, 1), color)
	rise.LightEmission = 1
	rise.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.15, 0.1),
		NumberSequenceKeypoint.new(0.85, 0.3),
		NumberSequenceKeypoint.new(1, 1),
	})
	rise.Parent = base
	model.Parent = Fx.beaconFolder()
	return model
end

function Fx.fireworkShow(center, count, height)
	for index = 1, count do
		task.delay((index - 1) * 0.32 + math.random() * 0.2, function()
			local offset = Vector3.new(math.random(-22, 22), 0, math.random(-22, 22))
			Fx.firework(center + offset, nil, (height or 46) + math.random(-8, 16))
		end)
	end
end

function Fx.floatText(position, text, color)
	local part = anchorPart(position, 2.2)
	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(190, 56)
	gui.AlwaysOnTop = true
	gui.LightInfluence = 0
	gui.MaxDistance = 220
	gui.Adornee = part
	gui.Parent = part
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.FredokaOne
	label.Text = text
	label.TextColor3 = color or Color3.new(1, 1, 1)
	label.TextSize = 38
	label.Parent = gui
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 3.5
	stroke.Color = Color3.fromRGB(30, 30, 50)
	stroke.Parent = label
	TweenService:Create(part, TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = position + Vector3.new(0, 6, 0),
	}):Play()
	local fade = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In, 0, false, 0.9)
	TweenService:Create(label, fade, { TextTransparency = 1 }):Play()
	TweenService:Create(stroke, fade, { Transparency = 1 }):Play()
end

return Fx
