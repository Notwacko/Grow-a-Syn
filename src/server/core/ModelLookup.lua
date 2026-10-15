local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ModelLookup = {}

function ModelLookup.get(name)
    local models = ReplicatedStorage:FindFirstChild("Models")
    local found = models and models:FindFirstChild(name, true)
    if found then
        return found:Clone()
    end
    local placeholder = Instance.new("Part")
    placeholder.Name = "Placeholder_" .. name
    placeholder.Size = Vector3.new(4, 4, 4)
    placeholder.Anchored = true
    placeholder.BrickColor = BrickColor.new("Bright violet")
    placeholder.Material = Enum.Material.SmoothPlastic
    return placeholder
end

return ModelLookup
