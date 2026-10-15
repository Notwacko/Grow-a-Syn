local Selection = game:GetService("Selection")
local ChangeHistoryService = game:GetService("ChangeHistoryService")

local DOOR_HEIGHT = 9
local TALLIT_NECK_OFFSET = 0.99
local SCALE_OVERRIDE = nil

local function say(text)
	print("[ImportFixer] " .. text)
end

local function parseName(name)
	local label, hex = string.match(name, "^(.-)__(%x%x%x%x%x%x)$")
	if label then
		return label, hex
	end
	return name, nil
end

local function colorFromHex(hex)
	local r = tonumber(string.sub(hex, 1, 2), 16)
	local g = tonumber(string.sub(hex, 3, 4), 16)
	local b = tonumber(string.sub(hex, 5, 6), 16)
	return Color3.fromRGB(r, g, b)
end

local function isMarker(name)
	return name == "Door" or string.match(name, "^Seat%d+$") ~= nil or string.sub(name, 1, 5) == "Slot_"
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

local function fixBuilding(model)
	for _, part in allParts(model) do
		part.Anchored = true
	end
	local floor = model:FindFirstChild("Floor", true)
	local door = model:FindFirstChild("Door", true)
	if not floor or not door then
		say("ERROR: the model needs parts named Floor and Door")
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
	local factor = SCALE_OVERRIDE
	if not factor then
		local doorHeight = math.max(door.Size.X, door.Size.Y, door.Size.Z)
		factor = DOOR_HEIGHT / doorHeight
	end
	if math.abs(factor - 1) > 0.02 then
		model:ScaleTo(model:GetScale() * factor)
		say(string.format("scaled model by %.3f so the Door is %d studs tall", factor, DOOR_HEIGHT))
	end
	say(string.format("building ready: %d seats, %d slots (26 expected), floor %s, door %s", seatCount, slotCount, floor.Name, door.Name))
end

local function fixCongregant(model)
	for _, part in allParts(model) do
		part.Anchored = true
		part.CanCollide = false
	end
	local _, size = model:GetBoundingBox()
	say(string.format("congregant height %.2f studs (expected about 5.5, child 4.3). If wrong set SCALE_OVERRIDE at the top and rerun", size.Y))
	if SCALE_OVERRIDE then
		model:ScaleTo(model:GetScale() * SCALE_OVERRIDE)
	end
end

local function fixProp(model)
	local biggest, area = nil, 0
	for _, part in allParts(model) do
		part.Anchored = true
		local volume = part.Size.X * part.Size.Y * part.Size.Z
		if volume > area then
			biggest, area = part, volume
		end
	end
	model.PrimaryPart = biggest
	local _, size = model:GetBoundingBox()
	say(string.format("prop size %.1f x %.1f x %.1f studs", size.X, size.Y, size.Z))
end

local function buildAccessory(model, attachmentName)
	local handle = model:FindFirstChild("Handle", true)
	if not handle then
		say("ERROR: the accessory needs a part named Handle")
		return nil
	end
	local accessory = Instance.new("Accessory")
	accessory.Name = model.Name
	accessory.AccessoryType = attachmentName == "HatAttachment" and Enum.AccessoryType.Hat or Enum.AccessoryType.Neck
	handle.Parent = accessory
	handle.Anchored = false
	handle.CanCollide = false
	handle.Massless = true
	for _, part in allParts(model) do
		if part ~= handle then
			part.Parent = accessory
			part.Anchored = false
			part.CanCollide = false
			part.Massless = true
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = handle
			weld.Part1 = part
			weld.Parent = handle
		end
	end
	local attachment = Instance.new("Attachment")
	attachment.Name = attachmentName
	if attachmentName == "HatAttachment" then
		attachment.Position = Vector3.new(0, -handle.Size.Y / 2, 0)
	else
		attachment.Position = Vector3.new(0, TALLIT_NECK_OFFSET, 0)
	end
	attachment.Parent = handle
	accessory.Parent = model.Parent
	model:Destroy()
	return accessory
end

local function process(model)
	local name = model.Name
	local colored = colorize(model)
	say(string.format("%s: colored %d parts", name, colored))
	local result = model
	if name == "starter" or string.match(name, "^%a+_T%d$") then
		fixBuilding(model)
	elseif string.match(name, "^congregant_%d$") then
		fixCongregant(model)
	elseif name == "kippah" then
		result = buildAccessory(model, "HatAttachment")
	elseif name == "tallit" then
		result = buildAccessory(model, "NeckAttachment")
	elseif string.sub(name, 1, 5) == "prop_" then
		fixProp(model)
	else
		say("Unknown model name " .. name .. ". Rename it exactly as in the contract (starter, ashkenazi_T2, congregant_1, kippah, tallit, prop_tree...)")
	end
	return result
end

local selected = Selection:Get()
local models = {}
for _, item in selected do
	if item:IsA("Model") then
		table.insert(models, item)
	end
end
if #models == 0 then
	say("Select one or more imported models (Models in the Explorer) and run this again")
	return
end

local recording = ChangeHistoryService:TryBeginRecording("ImportFixer")
local results = {}
for _, model in models do
	local name = model.Name
	local result = process(model)
	if result then
		table.insert(results, result)
	end
	say("Done with " .. name .. ". Right click it, Save to File, save as src/models/core/" .. name .. ".rbxm")
end
Selection:Set(results)
if recording then
	ChangeHistoryService:FinishRecording(recording, Enum.FinishRecordingOperation.Commit)
end
