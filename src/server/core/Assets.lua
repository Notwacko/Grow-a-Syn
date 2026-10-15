local ModelLookup = require(script.Parent.ModelLookup)

local Assets = {}

local PLACEHOLDER_PREFIX = "Placeholder_"

local templates = {}
local missing = {}

function Assets.isPlaceholder(instance)
	return instance:IsA("BasePart") and string.sub(instance.Name, 1, #PLACEHOLDER_PREFIX) == PLACEHOLDER_PREFIX
end

function Assets.get(name)
	if missing[name] then
		return nil
	end
	local template = templates[name]
	if not template then
		local instance = ModelLookup.get(name)
		if Assets.isPlaceholder(instance) then
			instance:Destroy()
			missing[name] = true
			return nil
		end
		templates[name] = instance
		template = instance
	end
	return template:Clone()
end

function Assets.groundPivot(model)
	model.PrimaryPart = nil
	local boxCFrame, boxSize = model:GetBoundingBox()
	model.WorldPivot = CFrame.new(boxCFrame.Position - Vector3.new(0, boxSize.Y / 2, 0))
end

function Assets.anchorAll(instance)
	for _, descendant in instance:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
		end
	end
	if instance:IsA("BasePart") then
		instance.Anchored = true
	end
end

function Assets.setPassive(instance)
	local parts = instance:GetDescendants()
	table.insert(parts, instance)
	for _, part in parts do
		if part:IsA("BasePart") then
			part.Anchored = true
			part.CanCollide = false
			part.CanTouch = false
			part.CanQuery = false
			part.Massless = true
		end
	end
end

return Assets
