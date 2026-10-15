local Workspace = game:GetService("Workspace")

local StationLayout = {}

local DEPTHS = { 4.2, 6.2, 8.2, 10.2, 12.4, 15 }
local BOX = Vector3.new(5.0, 6.2, 4.2)
local GAP = 8.5
local MIN_INNER = 5.5
local MAX_OUTER = 17
local WALL_MARGIN = 3.2
local IGNORE = { Floor = true, Path = true, Carpet = true, Door = true }

local function blocked(context, frame, walkLocalY, lateral, depth, door)
	local center = frame * CFrame.new(door.X + lateral, walkLocalY + 3.9, door.Z + depth)
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { context.folder }
	local floorTop = context.info.floorTopY
	for _, part in Workspace:GetPartBoundsInBox(center, BOX, params) do
		if part:IsDescendantOf(context.model) and not IGNORE[part.Name] and part.Transparency < 0.95 then
			local top = part.Position.Y + math.abs(part.CFrame.UpVector.Y) * part.Size.Y / 2 + math.abs(part.CFrame.RightVector.Y) * part.Size.X / 2 + math.abs(part.CFrame.LookVector.Y) * part.Size.Z / 2
			if top > floorTop + 1.4 then
				return true
			end
		end
	end
	return false
end

function StationLayout.compute(context)
	if context.stationSlots then
		return context.stationSlots
	end
	local info = context.info
	local frame = info.floor.CFrame
	local door = frame:PointToObjectSpace(info.door.Position)
	local bounds = context.interiorBounds
	local halfWidth = 14
	if bounds then
		halfWidth = math.min(-bounds.minX, bounds.maxX) - WALL_MARGIN
	end
	local outer = math.clamp(halfWidth, MIN_INNER + GAP, MAX_OUTER)
	local inner = math.max(MIN_INNER, outer - GAP)
	local walkLocalY = info.floorTopY - frame.Position.Y
	local laterals = { -outer, -inner, inner, outer }
	local slots = {}
	for index, lateral in laterals do
		local chosen = DEPTHS[1]
		for _, depth in DEPTHS do
			chosen = depth
			if not blocked(context, frame, walkLocalY, lateral, depth, door) then
				break
			end
		end
		local world = (frame * CFrame.new(door.X + lateral, 0, door.Z + chosen)).Position
		local base = Vector3.new(world.X, info.floorTopY, world.Z)
		slots[index] = {
			lateral = lateral,
			depth = chosen,
			cframe = CFrame.lookAt(base, base + frame.LookVector),
		}
	end
	context.stationSlots = slots
	return slots
end

return StationLayout
