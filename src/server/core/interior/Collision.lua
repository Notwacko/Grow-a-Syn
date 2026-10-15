local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local Collision = {
	name = "Collision",
	order = 10,
}

local THICKNESS = 1.2
local HEIGHT = 16
local DOOR_GAP = 3.8
local SIDE_MARGIN = 1.6
local BACK_MARGIN = 2.4
local CAMERA_HEIGHT = 14

local function wall(folder, frame, name, center, size)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = frame * CFrame.new(center)
	part.Anchored = true
	part.Transparency = 1
	part.CanCollide = true
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Parent = folder
	return part
end

local function evict(context, parts)
	local characters = {}
	for _, player in Players:GetPlayers() do
		if player.Character then
			table.insert(characters, player.Character)
		end
	end
	if #characters == 0 then
		return
	end
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = characters
	local info = context.info
	local outside = info.door.Position + info.floor.CFrame.LookVector * 9 + Vector3.new(0, 4, 0)
	for _, part in parts do
		for _, hit in Workspace:GetPartBoundsInBox(part.CFrame, part.Size + Vector3.new(1, 1, 1), params) do
			for _, character in characters do
				if hit:IsDescendantOf(character) then
					character:PivotTo(CFrame.new(outside))
				end
			end
		end
	end
end

function Collision.build(context)
	local info = context.info
	local floor = info.floor
	local frame = floor.CFrame
	local door = frame:PointToObjectSpace(info.door.Position)
	local minX = door.X - DOOR_GAP - 2
	local maxX = door.X + DOOR_GAP + 2
	local maxZ = door.Z
	local function consider(part)
		local point = frame:PointToObjectSpace(part.Position)
		minX = math.min(minX, point.X)
		maxX = math.max(maxX, point.X)
		maxZ = math.max(maxZ, point.Z)
	end
	for _, seat in info.seats do
		consider(seat)
	end
	local slots = context.model:FindFirstChild("Slots")
	if slots then
		for _, slot in slots:GetChildren() do
			if slot:IsA("BasePart") then
				consider(slot)
			end
		end
	end
	minX -= SIDE_MARGIN
	maxX += SIDE_MARGIN
	local zFront = door.Z
	local zBack = maxZ + BACK_MARGIN
	local depth = zBack - zFront
	local floorTopLocal = floor.Size.Y / 2
	local walkLocal = info.floorTopY - frame.Position.Y
	local centerY = walkLocal + HEIGHT / 2
	local folder = Instance.new("Folder")
	folder.Name = "Collision"
	folder.Parent = context.folder
	local walls = {}
	table.insert(walls, wall(folder, frame, "WallLeft", Vector3.new(minX - THICKNESS / 2, centerY, (zFront + zBack) / 2), Vector3.new(THICKNESS, HEIGHT, depth + THICKNESS * 2)))
	table.insert(walls, wall(folder, frame, "WallRight", Vector3.new(maxX + THICKNESS / 2, centerY, (zFront + zBack) / 2), Vector3.new(THICKNESS, HEIGHT, depth + THICKNESS * 2)))
	table.insert(walls, wall(folder, frame, "WallBack", Vector3.new((minX + maxX) / 2, centerY, zBack + THICKNESS / 2), Vector3.new(maxX - minX + THICKNESS * 2, HEIGHT, THICKNESS)))
	local leftWidth = (door.X - DOOR_GAP) - minX
	if leftWidth > 0.5 then
		table.insert(walls, wall(folder, frame, "WallFrontLeft", Vector3.new(minX + leftWidth / 2, centerY, zFront), Vector3.new(leftWidth, HEIGHT, THICKNESS)))
	end
	local rightWidth = maxX - (door.X + DOOR_GAP)
	if rightWidth > 0.5 then
		table.insert(walls, wall(folder, frame, "WallFrontRight", Vector3.new(maxX - rightWidth / 2, centerY, zFront), Vector3.new(rightWidth, HEIGHT, THICKNESS)))
	end
	local deck = walkLocal - floorTopLocal
	if deck > 0.2 then
		wall(folder, frame, "Deck", Vector3.new((minX + maxX) / 2, floorTopLocal + deck / 2, (zFront + zBack) / 2), Vector3.new(maxX - minX, deck, depth))
	end
	local box = Instance.new("Part")
	box.Name = "CameraBox"
	box.Size = Vector3.new(maxX - minX, CAMERA_HEIGHT, depth)
	box.CFrame = frame * CFrame.new((minX + maxX) / 2, walkLocal + CAMERA_HEIGHT / 2, (zFront + zBack) / 2)
	box.Anchored = true
	box.Transparency = 1
	box.CanCollide = false
	box.CanQuery = false
	box.CanTouch = false
	box.CastShadow = false
	box.Parent = folder
	CollectionService:AddTag(box, "InteriorCameraBox")
	context.interiorBounds = { minX = minX, maxX = maxX, zFront = zFront, zBack = zBack }
	evict(context, walls)
end

return Collision
