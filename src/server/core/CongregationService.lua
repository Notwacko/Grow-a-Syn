local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Config = require(script.Parent.Config)
local Assets = require(script.Parent.Assets)
local Guard = require(script.Parent.Guard)
local Notify = require(script.Parent.Notify)
local Economy = require(script.Parent.Economy)
local Fx = require(script.Parent.Fx)
local Income = require(script.Parent.Income)
local Procedural = require(script.Parent.Procedural)
local BuildingService = require(script.Parent.BuildingService)
local Signal = require(script.Parent.Signal)
local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))

local CongregationService = {}

CongregationService.Greeted = Signal.new()

local states = {}
local walkers = {}
local idlers = {}
local rng = Random.new()
local moveAccumulator = 0
local providers = {}

local GOLD = Color3.fromRGB(255, 214, 80)

local function readNumber(value, default)
	if Guard.isNumber(value) and value >= 0 then
		return value
	end
	return default
end

local function pick(list)
	return list[rng:NextInteger(1, #list)]
end

local function faceCFrame(position, direction, yawOffset)
	local flat = Vector3.new(direction.X, 0, direction.Z)
	if flat.Magnitude < 0.01 then
		flat = Vector3.new(0, 0, -1)
	end
	return CFrame.lookAt(position, position + flat.Unit) * CFrame.Angles(0, yawOffset, 0)
end

local function prepareReal(model)
	Assets.setPassive(model)
	local boxCFrame, boxSize = model:GetBoundingBox()
	local root = Procedural.marker(model, "Root", Vector3.new(1, 0.2, 1), CFrame.new(boxCFrame.Position.X, boxCFrame.Position.Y - boxSize.Y / 2 + 0.1, boxCFrame.Position.Z))
	root.Anchored = true
	model.PrimaryPart = root
	local head = model:FindFirstChild("Head", true)
	if head and head:IsA("BasePart") and not head:FindFirstChildOfClass("Decal") then
		local face = Instance.new("Decal")
		face.Name = "face"
		face.Texture = "rbxasset://textures/face.png"
		face.Face = Enum.NormalId.Front
		face.Parent = head
	end
end

local function pickVariant()
	local total = 0
	for _, weight in Config.VARIANT_WEIGHTS do
		total += weight
	end
	local roll = rng:NextNumber() * total
	for variant, weight in Config.VARIANT_WEIGHTS do
		roll -= weight
		if roll <= 0 then
			return variant
		end
	end
	return 1
end

local function luminance(color)
	return 0.299 * color.R + 0.587 * color.G + 0.114 * color.B
end

local function tint(model)
	local top = pick(Config.CLOTH_TOP_COLORS)
	local bottom = pick(Config.CLOTH_BOTTOM_COLORS)
	local kippah = pick(Config.KIPPAH_COLORS)
	local recolorHair = rng:NextNumber() < 0.7
	local hair = pick(Config.HAIR_COLORS)
	local dropTallit = rng:NextNumber() < 0.3
	local removable = {}
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			local name = part.Name
			if string.sub(name, 1, 5) == "Cloth" then
				part.Color = string.find(name, "Bottom") and bottom or top
			elseif string.sub(name, 1, 6) == "Kippah" then
				part.Color = kippah
			elseif string.sub(name, 1, 4) == "Hair" and recolorHair and luminance(part.Color) < 0.45 then
				part.Color = hair
			elseif string.sub(name, 1, 6) == "Tallit" and dropTallit then
				table.insert(removable, part)
			end
		end
	end
	for _, part in removable do
		part:Destroy()
	end
end

local function shadeParts(model)
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.CastShadow = Config.CONGREGANT_SHADOWS
		end
	end
end

local function createModel(variant)
	local source = Assets.get("congregant_" .. variant)
	local model
	if source then
		if source:IsA("Model") then
			model = source
		else
			model = Instance.new("Model")
			source.Parent = model
		end
		prepareReal(model)
	else
		model = Procedural.congregant(variant)
		Assets.setPassive(model)
	end
	model.Name = "Congregant"
	model:SetAttribute("Congregant", true)
	tint(model)
	shadeParts(model)
	local scale = (model:GetAttribute("BaseScale") or 1) * rng:NextNumber(0.92, 1.08)
	model:ScaleTo(model:GetScale() * scale)
	local yaw = math.rad(model:GetAttribute("FaceYaw") or 0)
	return model, Config.CONGREGANT_HIP * scale, yaw
end

local function newEntry(state)
	state.nextId += 1
	local entry = {
		id = state.nextId,
		variant = pickVariant(),
		status = "new",
		hip = Config.CONGREGANT_HIP,
		yaw = 0,
		speed = Config.WALK_SPEED * rng:NextNumber(Config.WALK_SPEED_RANGE[1], Config.WALK_SPEED_RANGE[2]),
		seatYaw = math.rad(rng:NextNumber(-8, 8)),
	}
	state.entries[entry.id] = entry
	return entry
end

local function attachModel(state, entry, variant)
	local model, hip, yaw = createModel(variant or entry.variant)
	entry.model = model
	entry.hip = hip
	entry.yaw = yaw
	model:SetAttribute("OwnerUserId", state.player.UserId)
	CollectionService:AddTag(model, "Congregant")
	model.Parent = state.folder
	state.models += 1
	return model
end

local function removeEntry(state, entry)
	if entry.status == "walking" then
		state.walking -= 1
	elseif entry.status == "seated" then
		state.count -= 1
	end
	if entry.model then
		entry.model:Destroy()
		entry.model = nil
		state.models -= 1
	end
	if entry.seatIndex and state.seatOwner[entry.seatIndex] == entry then
		state.seatOwner[entry.seatIndex] = nil
	end
	walkers[entry] = nil
	idlers[entry] = nil
	state.entries[entry.id] = nil
end

local function setCongregation(state)
	local player = state.player
	if player.Parent ~= Players then
		return
	end
	if player:GetAttribute("Congregation") ~= state.count then
		player:SetAttribute("Congregation", state.count)
	end
	if state.count >= Constants.MINYAN_SIZE and player:GetAttribute("HasMinyan") ~= true then
		player:SetAttribute("HasMinyan", true)
	end
end

local function budget(state)
	local active = 0
	for _, other in states do
		if other.plot then
			active += 1
		end
	end
	local per = math.floor(Config.TOTAL_CONGREGANT_CAP / math.max(active, 1))
	return math.clamp(per, Config.MIN_VISIBLE_PER_PLOT, Constants.SEATS_PER_TIER[Constants.MAX_TIER])
end

local function pickSeat(state, info)
	local free = {}
	for index = 1, info.seatCount do
		if not state.seatOwner[index] then
			table.insert(free, index)
		end
	end
	if #free == 0 then
		return nil
	end
	return free[rng:NextInteger(1, #free)]
end

local function seatPosition(info, seatIndex, hip)
	local seat = info.seats[seatIndex]
	local position = seat.Position
	return Vector3.new(position.X, position.Y - hip, position.Z)
end

local function seatInstant(state, entry)
	local info = state.info
	if entry.model and entry.seatIndex and info.seats[entry.seatIndex] then
		entry.model:PivotTo(faceCFrame(seatPosition(info, entry.seatIndex, entry.hip), info.forward, entry.yaw) * CFrame.Angles(0, entry.seatYaw, 0))
	end
end

local function buildPath(info, from, entry)
	local doorPosition = info.door.Position
	local floorY = info.floorTopY
	local doorPoint = Vector3.new(doorPosition.X, floorY, doorPosition.Z)
	local forward = info.forward
	local seat = info.seats[entry.seatIndex].Position
	local depth = Vector3.new(seat.X - doorPosition.X, 0, seat.Z - doorPosition.Z):Dot(forward)
	local points = { from, doorPoint - forward * 7, doorPoint }
	if depth > 7 then
		table.insert(points, doorPoint + forward * 4)
	end
	if depth > 3 then
		local gap = math.max(depth - 2.4, 2)
		table.insert(points, doorPoint + forward * gap)
		table.insert(points, Vector3.new(seat.X, floorY, seat.Z) - forward * 2.4)
	end
	table.insert(points, seatPosition(info, entry.seatIndex, entry.hip))
	return points
end

local function startWalk(state, entry)
	local info = state.info
	local from = entry.model:GetPivot().Position
	local points = buildPath(info, from, entry)
	walkers[entry] = {
		state = state,
		points = points,
		index = 2,
		position = from,
		speed = entry.speed,
		direction = Vector3.new(0, 0, -1),
	}
end

local function providerValue(name, player)
	local provider = providers[name]
	if not provider then
		return 0
	end
	local ok, value = pcall(provider, player)
	if ok and Guard.isNumber(value) then
		return value
	end
	return 0
end

local function giveTip(state, position)
	local tip = providerValue("tip", state.player)
	if tip > 0 then
		Economy.grant(state.player, tip, "tip")
		Fx.floatText(position + Vector3.new(0, 5.5, 0), "+" .. tip, GOLD)
	end
end

local function arrive(state, entry)
	local info = state.info
	walkers[entry] = nil
	if not info or not entry.seatIndex or not info.seats[entry.seatIndex] then
		return
	end
	entry.status = "seated"
	state.walking -= 1
	state.count += 1
	seatInstant(state, entry)
	local seat = info.seats[entry.seatIndex].Position
	Fx.sparkle(seat + Vector3.new(0, 2.5, 0))
	giveTip(state, seat)
	setCongregation(state)
end

local function stepWalkers(dt)
	if next(walkers) == nil and next(idlers) == nil then
		moveAccumulator = 0
		return
	end
	moveAccumulator += dt
	if moveAccumulator < Config.MOVE_STEP then
		return
	end
	dt = moveAccumulator
	moveAccumulator = 0
	local now = os.clock()
	for entry, walk in walkers do
		local model = entry.model
		if not model or not model.Parent then
			walkers[entry] = nil
		else
			local remaining = walk.speed * dt
			while remaining > 0 and walk.index <= #walk.points do
				local target = walk.points[walk.index]
				local delta = target - walk.position
				local distance = delta.Magnitude
				if distance <= remaining then
					walk.position = target
					remaining -= distance
					walk.index += 1
				else
					walk.position += delta.Unit * remaining
					remaining = 0
				end
				if distance > 0.05 then
					walk.direction = Vector3.new(delta.X, 0, delta.Z)
				end
			end
			if walk.index > #walk.points then
				arrive(walk.state, entry)
			else
				local bob = math.abs(math.sin(now * 11 + entry.id)) * 0.35
				model:PivotTo(faceCFrame(walk.position + Vector3.new(0, bob, 0), walk.direction, entry.yaw))
			end
		end
	end
	for entry, idle in idlers do
		local model = entry.model
		if not model or not model.Parent then
			idlers[entry] = nil
		else
			local hop = math.max(0, math.sin(now * 3 + entry.id * 1.7)) * 0.5
			model:PivotTo(idle.base * CFrame.new(0, hop, 0))
		end
	end
end

local function arrivalInterval(player)
	local welcome = readNumber(player:GetAttribute("WelcomeBonus"), 0) + providerValue("arrivalBonus", player)
	local base = Income.arrivalInterval(
		welcome,
		player:GetAttribute("HasMinyan") == true,
		Config.ARRIVAL_BASE_INTERVAL,
		Config.ARRIVAL_MIN_INTERVAL,
		Config.ARRIVAL_MAX_INTERVAL,
		Config.TUTORIAL_ARRIVAL_INTERVAL
	)
	local jitter = 1 + (rng:NextNumber() * 2 - 1) * Config.ARRIVAL_JITTER
	return base * jitter
end

local function spawnArrival(state)
	local info = state.info
	local seatIndex = pickSeat(state, info)
	if not seatIndex then
		return
	end
	local entry = newEntry(state)
	entry.seatIndex = seatIndex
	state.seatOwner[seatIndex] = entry
	if state.models < budget(state) then
		attachModel(state, entry)
		local spawn = state.plot.NpcSpawn
		local from = Vector3.new(spawn.Position.X, spawn.Position.Y - spawn.Size.Y / 2, spawn.Position.Z)
		entry.model:PivotTo(CFrame.new(from))
		entry.status = "walking"
		state.walking += 1
		startWalk(state, entry)
	else
		entry.status = "seated"
		state.count += 1
		giveTip(state, info.seats[seatIndex].Position)
		setCongregation(state)
	end
end

local function addSeatedInstant(state)
	local info = state.info
	local seatIndex = pickSeat(state, info)
	if not seatIndex then
		return false
	end
	local entry = newEntry(state)
	entry.seatIndex = seatIndex
	state.seatOwner[seatIndex] = entry
	entry.status = "seated"
	state.count += 1
	if state.models < budget(state) then
		attachModel(state, entry)
		seatInstant(state, entry)
	end
	return true
end

local function processArrival(state, now)
	local player = state.player
	if state.restoreTarget then
		local target = math.min(state.restoreTarget, state.info.seatCount)
		if state.count + state.walking < target or now < state.restoreGrace then
			return
		end
	end
	local step = player:GetAttribute("TutorialStep") or 0
	local hasMinyan = player:GetAttribute("HasMinyan") == true
	if step < Constants.TUTORIAL.BUY and not hasMinyan then
		return
	end
	local info = state.info
	local allowed = info.seatCount
	if not hasMinyan and step < Constants.TUTORIAL.MINYAN then
		allowed = math.min(allowed, Constants.MINYAN_SIZE - 1)
	end
	if state.count + state.walking >= allowed then
		state.nextArrival = now + 1
		return
	end
	if now >= state.nextArrival then
		spawnArrival(state)
		state.nextArrival = now + arrivalInterval(player)
	end
end

local function reconcile(state)
	local info = state.info
	local cap = budget(state)
	if state.models > cap then
		for _, entry in state.entries do
			if state.models <= cap then
				break
			end
			if entry.status == "seated" and entry.model then
				entry.model:Destroy()
				entry.model = nil
				state.models -= 1
			end
		end
	end
	local promoted = 0
	for _, entry in state.entries do
		if state.models >= cap or promoted >= Config.RECONCILE_SPAWN_PER_TICK then
			break
		end
		if entry.status == "seated" and not entry.model then
			attachModel(state, entry)
			seatInstant(state, entry)
			promoted += 1
		end
	end
	if state.restoreTarget then
		local target = math.min(state.restoreTarget, info.seatCount)
		if state.count >= state.restoreTarget or os.clock() > state.restoreUntil then
			state.restoreTarget = nil
		else
			local added = 0
			while state.count + state.walking < target and added < Config.RECONCILE_SPAWN_PER_TICK do
				if not addSeatedInstant(state) then
					break
				end
				added += 1
			end
			setCongregation(state)
		end
	end
end

local function greet(state, entry, who)
	if who ~= state.player then
		Notify.send(who, "info", "That guest is visiting another synagogue")
		return
	end
	if entry.greeted or states[who] ~= state or not entry.model then
		return
	end
	if not Guard.allow(who, "Greet", Config.COOLDOWNS.Greet) then
		return
	end
	if not Guard.nearPart(who, entry.model.PrimaryPart, Config.GREET_DISTANCE * 2.5) then
		Guard.flag(who, "Greet", "too far from guest")
		return
	end
	if who:GetAttribute("TutorialStep") ~= Constants.TUTORIAL.GREET then
		return
	end
	local info = BuildingService.getInfo(who)
	if not info then
		Notify.send(who, "info", "Your building is not ready yet")
		return
	end
	state.info = info
	local seatIndex = pickSeat(state, info)
	if not seatIndex then
		return
	end
	entry.greeted = true
	idlers[entry] = nil
	local greetPoint = entry.model.PrimaryPart:FindFirstChild("GreetPoint")
	if greetPoint then
		greetPoint:Destroy()
	end
	entry.seatIndex = seatIndex
	state.seatOwner[seatIndex] = entry
	entry.status = "walking"
	state.walking += 1
	local head = entry.model:GetPivot().Position + Vector3.new(0, 6.5, 0)
	Economy.grant(who, Constants.GREET_REWARD, "greet")
	Fx.floatText(head, "+" .. Constants.GREET_REWARD, GOLD)
	Fx.sparkle(head - Vector3.new(0, 2, 0))
	Fx.sound(head, Config.SOUNDS.ping, 0.7, 0.9 + state.greetCount * 0.2)
	startWalk(state, entry)
	state.greetCount += 1
	CongregationService.Greeted:Fire(who, state.greetCount)
end

function CongregationService.spawnGuests(player)
	local state = states[player]
	if not state or state.guestsSpawned or not state.plot then
		return
	end
	state.guestsSpawned = true
	local spawn = state.plot.NpcSpawn
	local pad = state.plot.ClaimPad
	local info = BuildingService.getInfo(player)
	local feet, facing, lateral
	if info then
		local door = info.door.Position
		feet = Vector3.new(door.X, info.floorTopY, door.Z) - info.forward * 10
		facing = -info.forward
		lateral = info.forward:Cross(Vector3.yAxis)
	else
		feet = Vector3.new(spawn.Position.X, spawn.Position.Y - spawn.Size.Y / 2, spawn.Position.Z)
		facing = Vector3.new(pad.Position.X - feet.X, 0, pad.Position.Z - feet.Z)
		lateral = spawn.CFrame.RightVector
	end
	local startVariant = rng:NextInteger(1, Config.CONGREGANT_VARIANTS)
	for index = 1, Constants.TUTORIAL_GREETERS do
		local entry = newEntry(state)
		entry.variant = ((startVariant + index * 2) % Config.CONGREGANT_VARIANTS) + 1
		local model, hip, yaw = createModel(entry.variant)
		entry.model = model
		entry.hip = hip
		entry.yaw = yaw
		entry.status = "waiting"
		model:SetAttribute("OwnerUserId", player.UserId)
		CollectionService:AddTag(model, "Congregant")
		model.Parent = state.folder
		state.models += 1
		local position = feet + lateral * ((index - 2) * 4.4)
		local base = faceCFrame(position, facing, yaw)
		model:PivotTo(base)
		idlers[entry] = { base = base }
		local attachment = Instance.new("Attachment")
		attachment.Name = "GreetPoint"
		attachment.Position = Vector3.new(0, 3.5 * (hip / Config.CONGREGANT_HIP), 0)
		attachment.Parent = model.PrimaryPart
		local prompt = Instance.new("ProximityPrompt")
		prompt.Name = "GreetPrompt"
		prompt.ActionText = "Greet"
		prompt.ObjectText = "Welcome"
		prompt.HoldDuration = 0
		prompt.MaxActivationDistance = Config.GREET_DISTANCE
		prompt.RequiresLineOfSight = false
		prompt.Parent = attachment
		local marker = Instance.new("BillboardGui")
		marker.Name = "GreetMarker"
		marker.Size = UDim2.fromOffset(54, 54)
		marker.StudsOffsetWorldSpace = Vector3.new(0, 3.4, 0)
		marker.AlwaysOnTop = true
		marker.LightInfluence = 0
		marker.MaxDistance = 260
		marker.Parent = attachment
		local mark = Instance.new("TextLabel")
		mark.BackgroundTransparency = 1
		mark.Size = UDim2.fromScale(1, 1)
		mark.Font = Enum.Font.FredokaOne
		mark.Text = "!"
		mark.TextScaled = true
		mark.TextColor3 = GOLD
		mark.Parent = marker
		local outline = Instance.new("UIStroke")
		outline.Thickness = 3.5
		outline.Color = Color3.fromRGB(30, 30, 50)
		outline.Parent = mark
		TweenService:Create(marker, TweenInfo.new(0.55, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
			StudsOffsetWorldSpace = Vector3.new(0, 4.6, 0),
		}):Play()
		prompt.Triggered:Connect(function(who)
			greet(state, entry, who)
		end)
	end
end

function CongregationService.onSwapped(player, plot, info, isSwap)
	local state = states[player]
	if not state then
		return
	end
	state.info = info
	if not isSwap then
		return
	end
	local list = {}
	for _, entry in state.entries do
		if entry.seatIndex then
			table.insert(list, entry)
		end
	end
	state.seatOwner = {}
	local order = {}
	for index = 1, info.seatCount do
		table.insert(order, index)
	end
	for index = #order, 2, -1 do
		local other = rng:NextInteger(1, index)
		order[index], order[other] = order[other], order[index]
	end
	for index, entry in list do
		walkers[entry] = nil
		local seatIndex = order[index]
		if seatIndex then
			entry.seatIndex = seatIndex
			state.seatOwner[seatIndex] = entry
			if entry.status == "walking" then
				entry.status = "seated"
				state.walking -= 1
				state.count += 1
			end
			if entry.model then
				seatInstant(state, entry)
			end
		else
			removeEntry(state, entry)
		end
	end
	for _, entry in state.entries do
		if entry.model and entry.status == "seated" and rng:NextNumber() < 0.25 then
			Fx.puff(entry.model:GetPivot().Position + Vector3.new(0, 1, 0))
		end
	end
	setCongregation(state)
end

function CongregationService.init(player, restoreTarget)
	states[player] = {
		player = player,
		entries = {},
		seatOwner = {},
		count = 0,
		walking = 0,
		models = 0,
		nextId = 0,
		greetCount = 0,
		guestsSpawned = false,
		nextArrival = math.huge,
		lastReconcile = 0,
		restoreTarget = (restoreTarget and restoreTarget > 0) and restoreTarget or nil,
		restoreUntil = math.huge,
		restoreGrace = math.huge,
	}
end

function CongregationService.onClaimed(player, plot)
	local state = states[player]
	if not state then
		return
	end
	state.plot = plot
	state.folder = plot:FindFirstChild("Congregants")
	state.info = BuildingService.getInfo(player)
	state.nextArrival = os.clock() + arrivalInterval(player)
	state.restoreUntil = os.clock() + 45
	state.restoreGrace = os.clock() + 8
end

function CongregationService.clear(player)
	local state = states[player]
	if not state then
		return
	end
	for _, entry in state.entries do
		walkers[entry] = nil
		idlers[entry] = nil
		if entry.model then
			entry.model:Destroy()
		end
	end
	state.entries = {}
	state.seatOwner = {}
	state.plot = nil
	state.info = nil
	state.folder = nil
	state.models = 0
	state.walking = 0
	state.guestsSpawned = false
	state.nextArrival = math.huge
end

function CongregationService.forget(player)
	CongregationService.clear(player)
	states[player] = nil
end

function CongregationService.savedCount(player)
	local state = states[player]
	if not state then
		return readNumber(player:GetAttribute("Congregation"), 0)
	end
	local current = state.count + state.walking
	return math.max(current, state.restoreTarget or 0)
end

function CongregationService.setProviders(newProviders)
	providers = newProviders or {}
end

function CongregationService.greetCount(player)
	local state = states[player]
	return state and state.greetCount or 0
end

local function publishStats()
	local models, seated = 0, 0
	for _, state in states do
		models += state.models
		seated += state.count
	end
	local workspaceRoot = game:GetService("Workspace")
	if workspaceRoot:GetAttribute("CongregantModels") ~= models then
		workspaceRoot:SetAttribute("CongregantModels", models)
	end
	if workspaceRoot:GetAttribute("CongregantsSeated") ~= seated then
		workspaceRoot:SetAttribute("CongregantsSeated", seated)
	end
end

function CongregationService.start()
	RunService.Heartbeat:Connect(function(dt)
		local ok, err = pcall(stepWalkers, dt)
		if not ok then
			warn("[Congregation] movement failed: " .. tostring(err))
		end
	end)
	local lastStats = 0
	task.spawn(function()
		while true do
			task.wait(0.25)
			local now = os.clock()
			if now - lastStats >= 1 then
				lastStats = now
				publishStats()
			end
			for _, state in states do
				if state.plot and state.info and state.folder then
					local ok, err = pcall(function()
						processArrival(state, now)
						if now - state.lastReconcile >= Config.RECONCILE_INTERVAL then
							state.lastReconcile = now
							reconcile(state)
						end
					end)
					if not ok then
						warn("[Congregation] update failed: " .. tostring(err))
					end
				end
			end
		end
	end)
end

return CongregationService
