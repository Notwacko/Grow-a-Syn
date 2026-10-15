local Assets = require(script.Parent.Assets)
local Procedural = require(script.Parent.Procedural)

local Props = {}

local builders = {
	tree = Procedural.tree,
	fence = Procedural.fence,
	bench = Procedural.bench,
	lamp = Procedural.lamp,
	flowers = Procedural.flowerBed,
	fountain = Procedural.fountain,
}

local VARIANTS = {
	tree = { "tree", "tree", "tree3", "tree", "tree2", "tree", "tree3", "tree", "tree", "tree3" },
}

local counters = {}

local function spray(anchor)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "Spray"
	emitter.Rate = 70
	emitter.Lifetime = NumberRange.new(1.3, 1.9)
	emitter.Speed = NumberRange.new(13, 17)
	emitter.SpreadAngle = Vector2.new(16, 16)
	emitter.Acceleration = Vector3.new(0, -30, 0)
	emitter.Size = NumberSequence.new(0.8)
	emitter.Color = ColorSequence.new(Color3.fromRGB(190, 235, 255))
	emitter.LightEmission = 0.6
	emitter.EmissionDirection = Enum.NormalId.Top
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Parent = anchor
end

local function finish(kind, model)
	if kind == "fountain" then
		local anchor = model:FindFirstChild("SprayAnchor", true)
		if anchor and not anchor:FindFirstChild("Spray") then
			spray(anchor)
		end
	end
end

local function pick(kind)
	local list = VARIANTS[kind]
	if not list then
		return kind
	end
	local index = (counters[kind] or 0) % #list + 1
	counters[kind] = index
	return list[index]
end

function Props.make(kind, variant)
	local name = variant or pick(kind)
	local real = Assets.get("prop_" .. name)
	if real then
		local model = real
		if not real:IsA("Model") then
			model = Instance.new("Model")
			model.Name = real.Name
			real.Parent = model
		end
		Assets.setPassive(model)
		Assets.groundPivot(model)
		finish(kind, model)
		return model
	end
	local builder = builders[kind]
	if not builder then
		return nil
	end
	local model = builder()
	if kind == "fence" then
		Assets.anchorAll(model)
	else
		Assets.setPassive(model)
	end
	return model
end

function Props.place(parent, kind, cframe, variant)
	local model = Props.make(kind, variant)
	if not model then
		return nil
	end
	model:PivotTo(cframe)
	model.Parent = parent
	return model
end

function Props.has(kind)
	local real = Assets.get("prop_" .. kind)
	if real then
		real:Destroy()
		return true
	end
	return false
end

Props.hasRealFence = function()
	return Props.has("fence")
end

return Props
