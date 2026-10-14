local Config = {}

Config.GROUND_Y = 0
Config.GROUND_SIZE = 1500
Config.LAND_TOP_Y = 0.5
Config.PLAZA_RADIUS = 95
Config.PLOT_FRONT_RADIUS = 255
Config.PATH_WIDTH = 14

Config.BASE_LAND = { width = 100, depth = 100 }

Config.LAND_REGIONS = {
	[2] = { x1 = -50, x2 = 50, z1 = 100, z2 = 140 },
	[3] = { x1 = -80, x2 = -50, z1 = 0, z2 = 140 },
	[4] = { x1 = 50, x2 = 80, z1 = 0, z2 = 140 },
	[5] = { x1 = -80, x2 = 80, z1 = 140, z2 = 190 },
	[6] = { x1 = -80, x2 = 80, z1 = 190, z2 = 240 },
}

Config.LAND_BOUNDS = {
	[1] = { x1 = -50, x2 = 50, z1 = 0, z2 = 100 },
	[2] = { x1 = -50, x2 = 50, z1 = 0, z2 = 140 },
	[3] = { x1 = -80, x2 = 50, z1 = 0, z2 = 140 },
	[4] = { x1 = -80, x2 = 80, z1 = 0, z2 = 140 },
	[5] = { x1 = -80, x2 = 80, z1 = 0, z2 = 190 },
	[6] = { x1 = -80, x2 = 80, z1 = 0, z2 = 240 },
}

Config.LAND_COSTS = { 750, 4000, 20000, 100000, 500000 }

Config.CLAIM_PAD_LOCAL = Vector3.new(0, 0, 9)
Config.NPC_SPAWN_LOCAL = Vector3.new(-20, 0, 3)
Config.BUILDING_ANCHOR_LOCAL = Vector3.new(0, 0, 62)
Config.PLOT_SPAWN_LOCAL = Vector3.new(14, 0, 4)

Config.CLAIM_DISTANCE = 26
Config.GREET_DISTANCE = 14

Config.INCOME_TICK = 1
Config.AUTOSAVE_INTERVAL = 60
Config.SAVE_RETRIES = 3
Config.LOAD_RETRIES = 3

Config.ARRIVAL_BASE_INTERVAL = 10
Config.ARRIVAL_MIN_INTERVAL = 1.5
Config.ARRIVAL_MAX_INTERVAL = 10
Config.ARRIVAL_JITTER = 0.2
Config.TUTORIAL_ARRIVAL_INTERVAL = 3

Config.WALK_SPEED = 13
Config.TOTAL_CONGREGANT_CAP = 320
Config.MIN_VISIBLE_PER_PLOT = 12
Config.RECONCILE_INTERVAL = 1
Config.RECONCILE_SPAWN_PER_TICK = 4

Config.CONGREGANT_HEIGHT = 5.5
Config.CONGREGANT_HIP = 2.6
Config.CONGREGANT_VARIANTS = 6

Config.EVENT_MULT_MAX = 100

Config.COOLDOWNS = {
	ClaimPlot = 1,
	ExpandLand = 1.5,
	AdvanceTutorial = 1,
	Greet = 0.25,
}

Config.CLOTH_TOP_COLORS = {
	Color3.fromRGB(255, 255, 255),
	Color3.fromRGB(86, 156, 255),
	Color3.fromRGB(255, 107, 107),
	Color3.fromRGB(255, 205, 66),
	Color3.fromRGB(94, 214, 130),
	Color3.fromRGB(176, 124, 255),
	Color3.fromRGB(255, 154, 72),
	Color3.fromRGB(64, 196, 196),
}

Config.CLOTH_BOTTOM_COLORS = {
	Color3.fromRGB(38, 44, 66),
	Color3.fromRGB(58, 58, 64),
	Color3.fromRGB(92, 64, 51),
	Color3.fromRGB(46, 84, 140),
	Color3.fromRGB(110, 110, 120),
}

Config.COLORS = {
	grass = Color3.fromRGB(98, 214, 64),
	grassLight = Color3.fromRGB(128, 232, 84),
	plot = Color3.fromRGB(116, 226, 74),
	plaza = Color3.fromRGB(236, 226, 196),
	path = Color3.fromRGB(226, 205, 160),
	padFree = Color3.fromRGB(255, 196, 40),
	padOwned = Color3.fromRGB(94, 214, 130),
	water = Color3.fromRGB(80, 190, 255),
	wood = Color3.fromRGB(190, 132, 70),
	woodDark = Color3.fromRGB(139, 90, 43),
	leaf = Color3.fromRGB(76, 209, 55),
	stone = Color3.fromRGB(214, 214, 222),
	gold = Color3.fromRGB(255, 200, 50),
	dark = Color3.fromRGB(40, 40, 58),
}

function Config.plotFrame(index)
	local angle = (index - 1) * (math.pi * 2 / 8)
	local origin = Vector3.new(math.cos(angle) * Config.PLOT_FRONT_RADIUS, Config.LAND_TOP_Y, math.sin(angle) * Config.PLOT_FRONT_RADIUS)
	return CFrame.lookAt(origin, Vector3.new(0, Config.LAND_TOP_Y, 0))
end

return Config
