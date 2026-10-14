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

function Props.make(kind)
	local real = Assets.get("prop_" .. kind)
	if real then
		local model = real
		if not real:IsA("Model") then
			model = Instance.new("Model")
			model.Name = real.Name
			real.Parent = model
		end
		Assets.setPassive(model)
		Assets.groundPivot(model)
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

function Props.place(parent, kind, cframe)
	local model = Props.make(kind)
	if not model then
		return nil
	end
	model:PivotTo(cframe)
	model.Parent = parent
	return model
end

function Props.hasRealFence()
	local fence = Assets.get("prop_fence")
	if fence then
		fence:Destroy()
		return true
	end
	return false
end

return Props
