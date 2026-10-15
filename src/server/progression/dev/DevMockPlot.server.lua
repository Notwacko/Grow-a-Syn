local RunService = game:GetService("RunService")

if not RunService:IsStudio() then
	return
end

task.wait(8)

if workspace:GetAttribute("CoreOnline") == true or workspace:FindFirstChild("Plots") then
	return
end

local plots = Instance.new("Folder")
plots.Name = "Plots"

local plot = Instance.new("Model")
plot.Name = "Plot1"
plot:SetAttribute("OwnerUserId", 0)
plot:SetAttribute("BuildingVersion", 1)

local building = Instance.new("Model")
building.Name = "Building"

local floor = Instance.new("Part")
floor.Name = "Floor"
floor.Size = Vector3.new(40, 1, 40)
floor.Position = Vector3.new(0, 0.5, 60)
floor.Anchored = true
floor.Color = Color3.fromRGB(230, 210, 170)
floor.Parent = building
building.PrimaryPart = floor

local slots = Instance.new("Folder")
slots.Name = "Slots"
slots.Parent = building

local layout = {
	{ "Slot_Ark", 1, 0, 16 },
	{ "Slot_Torah", 6, -10, 12 },
	{ "Slot_Siddur", 4, -6, 0 },
	{ "Slot_Menorah", 1, 10, 12 },
	{ "Slot_Kiddush", 2, 10, 6 },
	{ "Slot_Chandelier", 2, -4, -6 },
	{ "Slot_Ornament", 6, -15, -12 },
	{ "Slot_HolidayDecor", 4, 6, -12 },
}

for _, row in ipairs(layout) do
	local prefix, count, x, z = row[1], row[2], row[3], row[4]
	for i = 1, count do
		local slot = Instance.new("Part")
		slot.Name = count == 1 and prefix or prefix .. i
		slot.Size = Vector3.new(2, 0.2, 2)
		slot.Anchored = true
		slot.CanCollide = false
		slot.Transparency = 0.7
		slot.CFrame = CFrame.new(x + (i - 1) * 4, 1.1, 60 + z)
		slot.Parent = slots
	end
end

building.Parent = plot
plot.Parent = plots
plots.Parent = workspace
