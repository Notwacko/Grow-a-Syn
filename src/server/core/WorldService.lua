local Workspace = game:GetService("Workspace")

local Config = require(script.Parent.Config)
local Procedural = require(script.Parent.Procedural)
local Props = require(script.Parent.Props)

local WorldService = {}

local place = Procedural.place

local function cylinderAt(parent, name, diameter, height, position, color, material)
	return Procedural.cylinder(parent, name, diameter, height, CFrame.new(position), color, material)
end

local function buildGround(world)
	local half = Config.GROUND_SIZE / 2
	place(world, "Ground", Vector3.new(Config.GROUND_SIZE, 1, Config.GROUND_SIZE), CFrame.new(0, Config.GROUND_Y - 0.5, 0), Config.COLORS.grass, Enum.Material.Plastic, {
		TopSurface = Enum.SurfaceType.Studs,
	})
	local wallHeight = 300
	local invisible = { Transparency = 1, CanQuery = false, CastShadow = false }
	place(world, "WallN", Vector3.new(Config.GROUND_SIZE, wallHeight, 4), CFrame.new(0, wallHeight / 2, -half), Color3.new(1, 1, 1), nil, invisible)
	place(world, "WallS", Vector3.new(Config.GROUND_SIZE, wallHeight, 4), CFrame.new(0, wallHeight / 2, half), Color3.new(1, 1, 1), nil, invisible)
	place(world, "WallE", Vector3.new(4, wallHeight, Config.GROUND_SIZE), CFrame.new(half, wallHeight / 2, 0), Color3.new(1, 1, 1), nil, invisible)
	place(world, "WallW", Vector3.new(4, wallHeight, Config.GROUND_SIZE), CFrame.new(-half, wallHeight / 2, 0), Color3.new(1, 1, 1), nil, invisible)
end

local function buildPlaza(world)
	local radius = Config.PLAZA_RADIUS
	local plaza = Props.place(world, "plaza", CFrame.new(0, 0, 0), "plaza")
	if plaza then
		plaza.Name = "Plaza"
	else
		local rings = {
			{ radius * 2, Config.COLORS.plaza },
			{ radius * 1.7, Color3.fromRGB(190, 224, 255) },
			{ radius * 1.35, Config.COLORS.plaza },
			{ radius * 0.9, Color3.fromRGB(255, 226, 150) },
			{ radius * 0.6, Config.COLORS.plaza },
		}
		for index, ring in rings do
			cylinderAt(world, "PlazaRing" .. index, ring[1], 0.4 + index * 0.02, Vector3.new(0, 0.2 + index * 0.01, 0), ring[2], Enum.Material.SmoothPlastic)
		end
	end
	cylinderAt(world, "PlazaFloor", radius * 2, 0.5, Vector3.new(0, 0.25, 0), Config.COLORS.plaza, Enum.Material.SmoothPlastic).Transparency = plaza and 1 or 0
	local fountain = Props.make("fountain")
	fountain:PivotTo(CFrame.new(0, 0.5, 0))
	fountain.Parent = world

	for index = 1, 8 do
		local angle = (index - 1) * math.pi / 4 + math.pi / 8
		local direction = Vector3.new(math.cos(angle), 0, math.sin(angle))
		Props.place(world, "lamp", CFrame.new(direction * (radius - 12) + Vector3.new(0, 0.5, 0)))
		Props.place(world, "tree", CFrame.new(direction * (radius + 8)) * CFrame.Angles(0, index, 0))
		local benchPosition = direction * (radius * 0.55)
		Props.place(world, "bench", CFrame.lookAt(benchPosition + Vector3.new(0, 0.5, 0), Vector3.new(0, 0.5, 0)))
		Props.place(world, "flowers", CFrame.lookAt(direction * (radius * 0.38) + Vector3.new(0, 0.5, 0), Vector3.new(0, 0.5, 0)))
		local outer = Vector3.new(math.cos(angle + 0.2), 0, math.sin(angle + 0.2)) * (radius + 3)
		Props.place(world, "bush", CFrame.new(outer) * CFrame.Angles(0, index * 1.7, 0), "bush")
	end
end

local function buildPaths(world)
	local start = Config.PLAZA_RADIUS - 6
	for index = 1, 8 do
		local frame = Config.plotFrame(index)
		local origin = frame.Position
		local inward = Vector3.new(-origin.X, 0, -origin.Z).Unit
		local length = (Vector3.new(origin.X, 0, origin.Z).Magnitude - start)
		local center = Vector3.new(origin.X, 0, origin.Z) + inward * (length / 2)
		local pathFrame = CFrame.lookAt(Vector3.new(center.X, 0.15, center.Z), Vector3.new(0, 0.15, 0))
		local pathPart = place(world, "Path" .. index, Vector3.new(Config.PATH_WIDTH, 0.3, length), pathFrame, Config.COLORS.path, Enum.Material.SmoothPlastic)
		if Props.has("pathtile") then
			pathPart.Transparency = 1
			local tiles = math.max(1, math.round(length / 10))
			local spacing = length / tiles
			local pathModels = Instance.new("Folder")
			pathModels.Name = "PathTiles" .. index
			pathModels.Parent = world
			for tile = 1, tiles do
				local point = Vector3.new(origin.X, 0, origin.Z) + inward * (length - spacing * (tile - 0.5))
				local model = Props.make("pathtile", "pathtile")
				if model then
					model:ScaleTo(model:GetScale() * spacing / 10)
					model:PivotTo(CFrame.lookAt(point, point + inward))
					model.Parent = pathModels
				end
			end
		end
		for step = 1, math.floor(length / 45) do
			local point = Vector3.new(origin.X, 0, origin.Z) + inward * (step * 45 - 10)
			local side = Vector3.new(-inward.Z, 0, inward.X) * (Config.PATH_WIDTH / 2 + 2.5)
			Props.place(world, "lamp", CFrame.new(point + side))
			Props.place(world, "lamp", CFrame.new(point - side))
		end
	end
end

local function buildSpawns(world)
	local folder = Instance.new("Folder")
	folder.Name = "Spawns"
	folder.Parent = world
	for index = 1, 6 do
		local angle = (index - 1) * math.pi / 3
		local position = Vector3.new(math.cos(angle) * 26, 0.5, math.sin(angle) * 26)
		local spawn = Instance.new("SpawnLocation")
		spawn.Name = "PlazaSpawn" .. index
		spawn.Size = Vector3.new(7, 0.6, 7)
		spawn.CFrame = CFrame.new(position + Vector3.new(0, 0.3, 0))
		spawn.Anchored = true
		spawn.Neutral = true
		spawn.Duration = 0
		spawn.Material = Enum.Material.Neon
		spawn.Color = Color3.fromRGB(80, 190, 255)
		spawn.TopSurface = Enum.SurfaceType.Smooth
		for _, child in spawn:GetChildren() do
			if child:IsA("Decal") then
				child:Destroy()
			end
		end
		local pad = Props.place(folder, "spawnpad", CFrame.new(position), "spawnpad")
		spawn.Transparency = pad and 1 or 0.25
		spawn.Parent = folder
	end
end

local function addSignText(board)
	for _, face in { Enum.NormalId.Front, Enum.NormalId.Back } do
		local gui = Instance.new("SurfaceGui")
		gui.Face = face
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 50
		gui.Parent = board
		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.AnchorPoint = Vector2.new(0.5, 0.5)
		label.Position = UDim2.fromScale(0.5, 0.5)
		label.Size = UDim2.fromScale(0.74, 0.74)
		label.Font = Enum.Font.FredokaOne
		label.Text = "GROW A SYNAGOGUE"
		label.TextScaled = true
		label.TextColor3 = Color3.new(1, 1, 1)
		label.Parent = gui
		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 6
		stroke.Color = Color3.fromRGB(30, 30, 60)
		stroke.Parent = label
	end
end

local function buildSign(world)
	local position = Vector3.new(0, 0.5, -(Config.PLAZA_RADIUS - 22))
	local frame = CFrame.lookAt(position, Vector3.new(0, 0.5, 0))
	local model = Props.place(world, "sign", frame, "sign")
	if model then
		model.Name = "WelcomeSign"
		local board = model:FindFirstChild("Board", true)
		if board and board:IsA("BasePart") then
			addSignText(board)
		end
		return
	end
	local sign = Instance.new("Model")
	sign.Name = "WelcomeSign"
	place(sign, "PostL", Vector3.new(2.5, 18, 2.5), frame * CFrame.new(-17, 9, 0), Config.COLORS.woodDark)
	place(sign, "PostR", Vector3.new(2.5, 18, 2.5), frame * CFrame.new(17, 9, 0), Config.COLORS.woodDark)
	local board = place(sign, "Board", Vector3.new(38, 9, 1.4), frame * CFrame.new(0, 17, 0), Color3.fromRGB(86, 156, 255))
	place(sign, "Trim", Vector3.new(40, 1.2, 1.8), frame * CFrame.new(0, 21.6, 0), Config.COLORS.gold)
	place(sign, "TrimBottom", Vector3.new(40, 1.2, 1.8), frame * CFrame.new(0, 12.4, 0), Config.COLORS.gold)
	addSignText(board)
	sign.Parent = world
end

function WorldService.build()
	for _, name in { "Baseplate", "SpawnLocation" } do
		local leftover = Workspace:FindFirstChild(name)
		if leftover and leftover:IsA("BasePart") then
			leftover:Destroy()
		end
	end
	local world = Workspace:FindFirstChild("World")
	if world then
		world:Destroy()
	end
	world = Instance.new("Folder")
	world.Name = "World"
	buildGround(world)
	buildPlaza(world)
	buildPaths(world)
	buildSpawns(world)
	buildSign(world)
	world.Parent = Workspace
end

return WorldService
