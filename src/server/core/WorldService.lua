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
	local fountain = Props.make("fountain")
	fountain:PivotTo(CFrame.new(0, 0.5, 0))
	fountain.Parent = world

	for index = 1, 8 do
		local angle = (index - 1) * math.pi / 4 + math.pi / 8
		local direction = Vector3.new(math.cos(angle), 0, math.sin(angle))
		Props.place(world, "lamp", CFrame.new(direction * (radius - 12)))
		Props.place(world, "tree", CFrame.new(direction * (radius + 8)) * CFrame.Angles(0, index, 0))
		local benchPosition = direction * (radius * 0.55)
		Props.place(world, "bench", CFrame.lookAt(benchPosition, Vector3.zero))
		Props.place(world, "flowers", CFrame.lookAt(direction * (radius * 0.38), Vector3.zero))
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
		place(world, "Path" .. index, Vector3.new(Config.PATH_WIDTH, 0.3, length), CFrame.lookAt(Vector3.new(center.X, 0.15, center.Z), Vector3.new(0, 0.15, 0)), Config.COLORS.path, Enum.Material.SmoothPlastic)
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
		local position = Vector3.new(math.cos(angle) * 26, 0.75, math.sin(angle) * 26)
		local spawn = Instance.new("SpawnLocation")
		spawn.Name = "PlazaSpawn" .. index
		spawn.Size = Vector3.new(7, 0.6, 7)
		spawn.CFrame = CFrame.new(position)
		spawn.Anchored = true
		spawn.Neutral = true
		spawn.Duration = 0
		spawn.Material = Enum.Material.Neon
		spawn.Color = Color3.fromRGB(80, 190, 255)
		spawn.Transparency = 0.25
		spawn.TopSurface = Enum.SurfaceType.Smooth
		spawn.Parent = folder
		for _, child in spawn:GetChildren() do
			if child:IsA("Decal") then
				child:Destroy()
			end
		end
	end
end

local function buildSign(world)
	local position = Vector3.new(0, 0, -(Config.PLAZA_RADIUS - 22))
	local frame = CFrame.lookAt(position, Vector3.zero)
	local sign = Instance.new("Model")
	sign.Name = "WelcomeSign"
	place(sign, "PostL", Vector3.new(2.5, 18, 2.5), frame * CFrame.new(-17, 9, 0), Config.COLORS.woodDark)
	place(sign, "PostR", Vector3.new(2.5, 18, 2.5), frame * CFrame.new(17, 9, 0), Config.COLORS.woodDark)
	local board = place(sign, "Board", Vector3.new(38, 9, 1.4), frame * CFrame.new(0, 17, 0), Color3.fromRGB(86, 156, 255))
	place(sign, "Trim", Vector3.new(40, 1.2, 1.8), frame * CFrame.new(0, 21.6, 0), Config.COLORS.gold)
	place(sign, "TrimBottom", Vector3.new(40, 1.2, 1.8), frame * CFrame.new(0, 12.4, 0), Config.COLORS.gold)
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 50
	gui.Parent = board
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.FredokaOne
	label.Text = "GROW A SYNAGOGUE"
	label.TextScaled = true
	label.TextColor3 = Color3.new(1, 1, 1)
	label.Parent = gui
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 6
	stroke.Color = Color3.fromRGB(30, 30, 60)
	stroke.Parent = label
	local backGui = gui:Clone()
	backGui.Face = Enum.NormalId.Back
	backGui.Parent = board
	sign.Parent = world
end

function WorldService.build()
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
