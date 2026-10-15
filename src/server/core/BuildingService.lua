local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(script.Parent.Config)
local Assets = require(script.Parent.Assets)
local Fx = require(script.Parent.Fx)
local Procedural = require(script.Parent.Procedural)
local PlotService = require(script.Parent.PlotService)
local Signal = require(script.Parent.Signal)
local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))

local BuildingService = {}

BuildingService.Swapped = Signal.new()

local states = {}
local warnedNames = {}

local function warnOnce(key, message)
	if not warnedNames[key] then
		warnedNames[key] = true
		warn("[BuildingService] " .. message)
	end
end

local function seatNumber(part)
	return tonumber(string.match(part.Name, "^Seat(%d+)$"))
end

local function collectSeats(model)
	local seats = {}
	local folder = model:FindFirstChild("Seats", true)
	if folder then
		for _, child in folder:GetDescendants() do
			if child:IsA("BasePart") and seatNumber(child) then
				table.insert(seats, child)
			end
		end
	end
	table.sort(seats, function(a, b)
		return seatNumber(a) < seatNumber(b)
	end)
	return seats
end

local function toModel(instance)
	if instance:IsA("Model") then
		return instance
	end
	return nil
end

local function validate(model)
	local problems = {}
	local floor = model:FindFirstChild("Floor", true)
	if not (floor and floor:IsA("BasePart")) then
		table.insert(problems, "Floor")
	end
	local door = model:FindFirstChild("Door", true)
	if not (door and door:IsA("BasePart")) then
		table.insert(problems, "Door")
	end
	if #collectSeats(model) == 0 then
		table.insert(problems, "Seats")
	end
	return #problems == 0, problems
end

local function hardenMarkers(model)
	local function harden(part)
		part.Transparency = 1
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.CastShadow = false
		part.Anchored = true
	end
	for _, name in { "Seats", "Slots" } do
		local folder = model:FindFirstChild(name, true)
		if folder then
			for _, child in folder:GetDescendants() do
				if child:IsA("BasePart") then
					harden(child)
				end
			end
		end
	end
	local door = model:FindFirstChild("Door", true)
	if door and door:IsA("BasePart") then
		harden(door)
	end
end

local function repairSlots(model, name)
	local floor = model.PrimaryPart
	local slots = model:FindFirstChild("Slots", true)
	if not slots then
		slots = Instance.new("Folder")
		slots.Name = "Slots"
		slots.Parent = model
	end
	local missing = 0
	for index, slotName in Constants.SLOT_NAMES do
		if not slots:FindFirstChild(slotName, true) then
			missing += 1
			local angle = (index / #Constants.SLOT_NAMES) * math.pi * 2
			local offset = Vector3.new(math.cos(angle) * 6, floor.Size.Y / 2 + 1, math.sin(angle) * 6)
			Procedural.marker(slots, slotName, Vector3.new(1, 1, 1), floor.CFrame * CFrame.new(offset))
		end
	end
	if missing > 0 then
		warnOnce("slots_" .. name, string.format("%s is missing %d slot parts, defaults were created", name, missing))
	end
end

local function tierFromName(name)
	local tier = tonumber(string.match(name, "_T(%d)$"))
	return tier or 1
end

local function createBuilding(name, fallbackTier)
	local source = Assets.get(name)
	if source then
		local model = toModel(source)
		if model then
			local floor = model:FindFirstChild("Floor", true)
			if floor and floor:IsA("BasePart") and (not model.PrimaryPart or model.PrimaryPart.Name ~= "Floor") then
				model.PrimaryPart = floor
			end
			local ok, problems = validate(model)
			if ok then
				Assets.anchorAll(model)
				model.PrimaryPart.PivotOffset = CFrame.new()
				return model, false
			end
			warnOnce("invalid_" .. name, string.format("%s is missing required parts: %s. Using the procedural building instead", name, table.concat(problems, ", ")))
		else
			warnOnce("notmodel_" .. name, name .. " is not a Model. Using the procedural building instead")
		end
		source:Destroy()
	else
		warnOnce("missing_" .. name, name .. " not found in ReplicatedStorage.Models. Using the procedural building")
	end
	local tier = name == Constants.BUILDING_STARTER and 1 or tierFromName(name)
	if tier == 1 and name ~= Constants.BUILDING_STARTER then
		tier = fallbackTier
	end
	local model = Procedural.building(tier)
	return model, true
end

local function placeBuilding(plot, model)
	local anchor = plot.BuildingAnchor
	local floor = model.PrimaryPart
	local door = model:FindFirstChild("Door", true)
	local localDoor = floor.CFrame:PointToObjectSpace(door.Position)
	local flat = Vector3.new(localDoor.X, 0, localDoor.Z)
	local turn = CFrame.new()
	if flat.Magnitude > 1 then
		turn = CFrame.lookAt(Vector3.zero, flat.Unit)
	end
	local groundY = anchor.Position.Y - anchor.Size.Y / 2
	local position = Vector3.new(anchor.Position.X, groundY + floor.Size.Y / 2, anchor.Position.Z)
	model:PivotTo(CFrame.new(position) * anchor.CFrame.Rotation * turn:Inverse())
end

local function verticalHalfExtent(part)
	local cframe = part.CFrame
	local size = part.Size
	return math.abs(cframe.RightVector.Y) * size.X / 2 + math.abs(cframe.UpVector.Y) * size.Y / 2 + math.abs(cframe.LookVector.Y) * size.Z / 2
end

local function buildInfo(model)
	local floor = model.PrimaryPart
	local door = model:FindFirstChild("Door", true)
	local seats = collectSeats(model)
	local slots = model:FindFirstChild("Slots", true)
	local ark = slots and slots:FindFirstChild("Slot_Ark", true)
	local target = (ark and ark:IsA("BasePart")) and ark.Position or floor.Position
	local forward = Vector3.new(target.X - door.Position.X, 0, target.Z - door.Position.Z)
	if forward.Magnitude < 0.5 then
		forward = -door.CFrame.LookVector
	end
	return {
		model = model,
		floor = floor,
		door = door,
		seats = seats,
		seatCount = #seats,
		forward = forward.Unit,
		floorTopY = door.Position.Y - verticalHalfExtent(door),
	}
end

local function currentName(player)
	return Constants.buildingName(player:GetAttribute("Denomination"), player:GetAttribute("Tier"))
end

function BuildingService.getInfo(player)
	local state = states[player]
	return state and state.info or nil
end

function BuildingService.refresh(player, force)
	local plot = PlotService.getPlot(player)
	local state = states[player]
	if not plot or not state then
		return
	end
	local name = currentName(player)
	if not force and state.info and state.name == name and state.info.model.Parent then
		return
	end
	local tier = math.clamp(tonumber(player:GetAttribute("Tier")) or 1, 1, Constants.MAX_TIER)
	local landTier = player:GetAttribute("LandTier") or 1
	if tier - 1 > landTier then
		warn(string.format("[BuildingService] %s has Tier %d with LandTier %d", player.Name, tier, landTier))
	end
	local model, procedural = createBuilding(name, tier)
	if not model.PrimaryPart then
		model:Destroy()
		return
	end
	model.Name = name
	placeBuilding(plot, model)
	hardenMarkers(model)
	repairSlots(model, name)
	local previous = state.info
	model.Parent = plot.Building
	PlotService.clearFootprint(plot, model.PrimaryPart)
	if previous and previous.model then
		previous.model:Destroy()
	end
	local info = buildInfo(model)
	state.info = info
	state.name = name
	state.procedural = procedural
	player:SetAttribute("MaxCongregation", info.seatCount)
	plot:SetAttribute("BuildingVersion", (plot:GetAttribute("BuildingVersion") or 0) + 1)
	if previous then
		local center = info.floor.Position + Vector3.new(0, 6, 0)
		Fx.confetti(center, 1.4)
		Fx.ring(Vector3.new(center.X, info.floorTopY + 0.5, center.Z), Config.COLORS.gold, 40)
	end
	BuildingService.Swapped:Fire(player, plot, info, previous ~= nil)
end

function BuildingService.watch(player)
	local state = { token = 0, connections = {} }
	states[player] = state
	local function schedule()
		state.token += 1
		local token = state.token
		task.delay(0.15, function()
			if states[player] == state and state.token == token then
				BuildingService.refresh(player, false)
			end
		end)
	end
	table.insert(state.connections, player:GetAttributeChangedSignal("Denomination"):Connect(schedule))
	table.insert(state.connections, player:GetAttributeChangedSignal("Tier"):Connect(schedule))
end

function BuildingService.remove(player)
	local state = states[player]
	if state then
		state.info = nil
		state.name = nil
	end
end

function BuildingService.forget(player)
	local state = states[player]
	if state then
		for _, connection in state.connections do
			connection:Disconnect()
		end
		states[player] = nil
	end
end

return BuildingService
