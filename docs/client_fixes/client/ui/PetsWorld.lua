local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local PetsWorld = {}

local MAX_PLAYERS = 12
local RANGE = 140
local OFFSETS = {
	Vector3.new(-3.4, 0, 3.8),
	Vector3.new(3.4, 0, 3.8),
	Vector3.new(0, 0, 7),
}

local follow = {}
local visible = true
local folder

local function findModel(id)
	local models = ReplicatedStorage:FindFirstChild("Models")
	return models and models:FindFirstChild("pet_" .. id, true)
end

local function parse(text)
	local list = {}
	if type(text) == "string" and text ~= "" then
		for id in string.gmatch(text, "[^,]+") do
			table.insert(list, id)
		end
	end
	return list
end

local function destroyEntry(key)
	local entry = follow[key]
	if entry then
		if entry.model then
			entry.model:Destroy()
		end
		follow[key] = nil
	end
end

local function groundY(character, root)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		return root.Position.Y - humanoid.HipHeight - root.Size.Y / 2
	end
	return root.Position.Y - 3
end

function PetsWorld.setVisible(value)
	visible = value
	if not value then
		for key in follow do
			destroyEntry(key)
		end
	end
end

function PetsWorld.start()
	folder = Instance.new("Folder")
	folder.Name = "ClientPets"
	folder.Parent = workspace
	local clock = 0
	RunService.RenderStepped:Connect(function(dt)
		if not visible then
			return
		end
		clock += dt
		local camera = workspace.CurrentCamera
		local cameraPosition = camera and camera.CFrame.Position or Vector3.zero
		local wanted = {}
		local candidates = {}
		for _, player in Players:GetPlayers() do
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if root and (root.Position - cameraPosition).Magnitude < RANGE then
				table.insert(candidates, { player = player, character = character, root = root, distance = (root.Position - cameraPosition).Magnitude })
			end
		end
		table.sort(candidates, function(a, b)
			return a.distance < b.distance
		end)
		for index, data in candidates do
			if index > MAX_PLAYERS then
				break
			end
			local ids = parse(data.player:GetAttribute("PetsEquipped"))
			for slot, id in ids do
				local key = data.player.UserId .. ":" .. slot
				wanted[key] = true
				local entry = follow[key]
				if entry and entry.id ~= id then
					destroyEntry(key)
					entry = nil
				end
				local offset = OFFSETS[slot] or OFFSETS[1]
				local goalCFrame = data.root.CFrame * CFrame.new(offset.X, 0, offset.Z)
				local ground = groundY(data.character, data.root)
				local target = Vector3.new(goalCFrame.Position.X, ground, goalCFrame.Position.Z)
				if not entry then
					local source = findModel(id)
					if source then
						local model = source:Clone()
						for _, part in model:GetDescendants() do
							if part:IsA("BasePart") then
								part.Anchored = true
								part.CanCollide = false
								part.CanQuery = false
								part.CanTouch = false
								part.CastShadow = false
							end
						end
						model:PivotTo(CFrame.new(target))
						model.Parent = folder
						entry = { id = id, model = model, position = target, yaw = 0, phase = math.random() * 6 }
						follow[key] = entry
					end
				end
				if entry and entry.model.Parent then
					local alpha = 1 - math.exp(-7 * dt)
					local previous = entry.position
					entry.position = previous:Lerp(target, alpha)
					local delta = entry.position - previous
					local speed = delta.Magnitude / math.max(dt, 1e-3)
					if speed > 0.6 then
						local desired = math.atan2(-delta.X, -delta.Z)
						local difference = (desired - entry.yaw + math.pi) % (2 * math.pi) - math.pi
						entry.yaw += difference * (1 - math.exp(-10 * dt))
					else
						local look = data.root.CFrame.LookVector
						local desired = math.atan2(-look.X, -look.Z)
						local difference = (desired - entry.yaw + math.pi) % (2 * math.pi) - math.pi
						entry.yaw += difference * (1 - math.exp(-4 * dt))
					end
					local hop = math.abs(math.sin(clock * 9 + entry.phase)) * math.clamp(speed / 10, 0, 1) * 0.5
					local idle = math.sin(clock * 2 + entry.phase) * 0.05
					entry.model:PivotTo(CFrame.new(entry.position + Vector3.new(0, hop + idle, 0)) * CFrame.Angles(0, entry.yaw, 0))
				end
			end
		end
		for key in follow do
			if not wanted[key] then
				destroyEntry(key)
			end
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		for slot = 1, 3 do
			destroyEntry(player.UserId .. ":" .. slot)
		end
	end)
end

return PetsWorld
