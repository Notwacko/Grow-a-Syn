local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local DOOR_HEIGHT = 9
local STARTER_SCALE = 1.2
local TALLIT_NECK_OFFSET = 0.99

local NAMES = {
	"starter", "ashkenazi_T2", "ashkenazi_T3", "ashkenazi_T4", "ashkenazi_T5", "ashkenazi_T6", "ashkenazi_T7",
	"congregant_1", "congregant_2", "congregant_3", "congregant_4", "congregant_5", "congregant_6",
	"kippah", "tallit", "prop_tree", "prop_fence", "prop_bench", "prop_lamp",
}

local report = {}

local function note(name, text)
	report[name] = report[name] or {}
	table.insert(report[name], text)
end

local function parseName(name)
	local label, hex = string.match(name, "^(.-)__(%x%x%x%x%x%x)%.?%d*$")
	if label then
		return label, hex
	end
	return name, nil
end

local function colorFromHex(hex)
	return Color3.fromRGB(tonumber(string.sub(hex, 1, 2), 16), tonumber(string.sub(hex, 3, 4), 16), tonumber(string.sub(hex, 5, 6), 16))
end

local function allParts(root)
	local parts = {}
	for _, descendant in root:GetDescendants() do
		if descendant:IsA("BasePart") then
			table.insert(parts, descendant)
		end
	end
	return parts
end

local function isMarker(name)
	return name == "Door" or string.match(name, "^Seat%d+$") ~= nil or string.sub(name, 1, 5) == "Slot_"
end

local function colorize(root)
	local count = 0
	for _, part in allParts(root) do
		local label, hex = parseName(part.Name)
		if hex then
			part.Color = colorFromHex(hex)
			part.Name = label
			count += 1
		end
		part.Material = Enum.Material.SmoothPlastic
		if string.sub(part.Name, 1, 5) == "Glass" then
			part.Material = Enum.Material.Glass
			part.Transparency = 0.5
			part.CanQuery = false
		elseif string.sub(part.Name, 1, 4) == "Glow" then
			part.Material = Enum.Material.Neon
		end
	end
	return count
end

local function makeFolder(model, name)
	local folder = model:FindFirstChild(name)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = name
		folder.Parent = model
	end
	return folder
end

local function fixBuilding(name, model)
	for _, part in allParts(model) do
		part.Anchored = true
	end
	local floor = model:FindFirstChild("Floor", true)
	local door = model:FindFirstChild("Door", true)
	if not floor or not door then
		note(name, "ERROR missing Floor or Door")
		return
	end
	for _, part in allParts(model) do
		part.CanCollide = part == floor
		part.CanTouch = false
	end
	if floor:IsA("MeshPart") then
		floor.CollisionFidelity = Enum.CollisionFidelity.Box
	end
	local seats = makeFolder(model, "Seats")
	local slots = makeFolder(model, "Slots")
	local seatCount, slotCount = 0, 0
	for _, part in allParts(model) do
		if isMarker(part.Name) then
			part.Transparency = 1
			part.CanCollide = false
			part.CanQuery = false
			part.CanTouch = false
			part.CastShadow = false
			if string.match(part.Name, "^Seat%d+$") then
				part.Parent = seats
				seatCount += 1
			elseif string.sub(part.Name, 1, 5) == "Slot_" then
				part.Parent = slots
				slotCount += 1
			end
		end
	end
	model.PrimaryPart = floor
	floor.PivotOffset = CFrame.new()
	local factor = DOOR_HEIGHT / math.max(door.Size.X, door.Size.Y, door.Size.Z)
	if name == "starter" then
		factor *= STARTER_SCALE
	end
	model:ScaleTo(model:GetScale() * factor)
	note(name, string.format("seats=%d slots=%d floor=%s doorH=%.2f", seatCount, slotCount, tostring(floor.Size), math.max(door.Size.X, door.Size.Y, door.Size.Z)))
end

local function buildAccessory(name, model, attachmentName)
	local handle = model:FindFirstChild("Handle", true)
	if not handle then
		note(name, "ERROR no Handle")
		return nil
	end
	local accessory = Instance.new("Accessory")
	accessory.Name = name
	accessory.AccessoryType = attachmentName == "HatAttachment" and Enum.AccessoryType.Hat or Enum.AccessoryType.Neck
	local others = {}
	for _, part in allParts(model) do
		if part ~= handle then
			table.insert(others, part)
		end
	end
	handle.Parent = accessory
	handle.Anchored = false
	handle.CanCollide = false
	handle.Massless = true
	for _, part in others do
		part.Parent = accessory
		part.Anchored = false
		part.CanCollide = false
		part.Massless = true
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = handle
		weld.Part1 = part
		weld.Parent = handle
	end
	local attachment = Instance.new("Attachment")
	attachment.Name = attachmentName
	if attachmentName == "HatAttachment" then
		attachment.Position = Vector3.new(0, -handle.Size.Y / 2, 0)
	else
		attachment.Position = Vector3.new(0, TALLIT_NECK_OFFSET, 0)
	end
	attachment.Parent = handle
	note(name, string.format("accessory parts=%d handle=%s", #others + 1, tostring(handle.Size)))
	return accessory
end

local modelsRoot = ReplicatedStorage:FindFirstChild("Models") or Instance.new("Folder")
modelsRoot.Name = "Models"
modelsRoot.Parent = ReplicatedStorage
local coreFolder = modelsRoot:FindFirstChild("core") or Instance.new("Folder")
coreFolder.Name = "core"
coreFolder.Parent = modelsRoot

local CM_TO_STUDS = 0.01

for _, name in NAMES do
	local model = Workspace:FindFirstChild(name)
	if not model then
		note(name, "NOT FOUND in Workspace")
	else
		local colored = colorize(model)
		note(name, "colored=" .. colored)
		local result = model
		if name == "starter" or string.match(name, "^ashkenazi_T%d$") then
			fixBuilding(name, model)
		elseif string.match(name, "^congregant_%d$") then
			for _, part in allParts(model) do
				part.Anchored = true
				part.CanCollide = false
			end
			model:ScaleTo(model:GetScale() * CM_TO_STUDS)
			local _, size = model:GetBoundingBox()
			note(name, string.format("height=%.2f", size.Y))
		elseif name == "kippah" then
			model:ScaleTo(model:GetScale() * CM_TO_STUDS)
			result = buildAccessory(name, model, "HatAttachment")
		elseif name == "tallit" then
			model:ScaleTo(model:GetScale() * CM_TO_STUDS)
			result = buildAccessory(name, model, "NeckAttachment")
		else
			local biggest, volume = nil, 0
			for _, part in allParts(model) do
				part.Anchored = true
				local v = part.Size.X * part.Size.Y * part.Size.Z
				if v > volume then
					biggest, volume = part, v
				end
			end
			model.PrimaryPart = biggest
			model:ScaleTo(model:GetScale() * CM_TO_STUDS)
			local _, size = model:GetBoundingBox()
			note(name, string.format("size=%s", tostring(size)))
		end
		if result then
			local existing = coreFolder:FindFirstChild(name)
			if existing then
				existing:Destroy()
			end
			if result ~= model then
				model:Destroy()
			end
			result.Parent = coreFolder
		end
	end
end

local flat = {}
for name, lines in report do
	flat[name] = table.concat(lines, " | ")
end
return flat
