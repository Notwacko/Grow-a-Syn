local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local core = script.Parent.Parent
local Config = require(core.Config)
local Guard = require(core.Guard)
local Assets = require(core.Assets)
local Format = require(core.Format)
local Procedural = require(core.Procedural)
local GardenService = require(core.GardenService)
local Catalog = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GardenCatalog"))

local Shuk = {
	name = "Shuk",
	order = 40,
}

local place = Procedural.place
local SMOOTH = Enum.Material.SmoothPlastic

local WOOD = Color3.fromRGB(150, 104, 62)
local WOOD_DARK = Color3.fromRGB(110, 74, 44)
local WOOD_LIGHT = Color3.fromRGB(214, 170, 112)
local BLUE = Color3.fromRGB(60, 124, 226)
local WHITE = Color3.fromRGB(250, 248, 240)
local GOLD = Color3.fromRGB(255, 214, 80)
local SEED_COLORS = {
	wheat = Color3.fromRGB(238, 192, 62),
	barley = Color3.fromRGB(224, 200, 130),
	grapes = Color3.fromRGB(110, 54, 150),
	figs = Color3.fromRGB(116, 58, 104),
	olives = Color3.fromRGB(124, 154, 70),
	pomegranate = Color3.fromRGB(200, 48, 64),
	dates = Color3.fromRGB(178, 96, 40),
}

local function text(parent, name, content, y, height, color, thickness)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.Position = UDim2.fromScale(0, y)
	label.Size = UDim2.fromScale(1, height)
	label.Font = Enum.Font.FredokaOne
	label.Text = content
	label.TextScaled = true
	label.TextColor3 = color
	label.Parent = parent
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = thickness or 3
	stroke.Color = Color3.fromRGB(30, 30, 50)
	stroke.Parent = label
	return label
end

local function board(parent, name, size, cframe, color)
	local part = place(parent, name, size, cframe, color, SMOOTH, { CanCollide = false })
	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Front
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 40
	gui.Parent = part
	return part, gui
end

local function awning(parent, frame, width, y, depth)
	local stripes = 8
	local each = width / stripes
	for index = 1, stripes do
		local x = -width / 2 + (index - 0.5) * each
		place(parent, "Awning", Vector3.new(each, 0.6, depth), frame * CFrame.new(x, y, 0.4) * CFrame.Angles(math.rad(-8), 0, 0), index % 2 == 0 and BLUE or WHITE, SMOOTH, { CanCollide = false })
	end
end

local function posts(parent, frame, width, height)
	for _, x in { -width / 2 + 0.6, width / 2 - 0.6 } do
		for _, z in { -2.2, 3.2 } do
			place(parent, "Post", Vector3.new(0.9, height, 0.9), frame * CFrame.new(x, height / 2, z), WOOD_DARK, SMOOTH, { CanCollide = false })
		end
	end
end

local function near(who, part, distance)
	if not Guard.nearPart(who, part, distance) then
		Guard.flag(who, "Shuk", "too far from stall")
		return false
	end
	return true
end

local function buildSeedShop(root, frame)
	local model = Instance.new("Model")
	model.Name = "SeedShop"
	local width = 34
	place(model, "Counter", Vector3.new(width - 2, 3.6, 4.4), frame * CFrame.new(0, 1.8, -0.2), WOOD)
	place(model, "CounterTop", Vector3.new(width - 1, 0.5, 5), frame * CFrame.new(0, 3.85, -0.2), WOOD_LIGHT)
	place(model, "BackWall", Vector3.new(width - 2, 9, 0.8), frame * CFrame.new(0, 4.5, 3.3), WOOD_DARK)
	posts(model, frame, width, 13)
	awning(model, frame, width, 13.2, 8.5)
	local _, gui = board(model, "Sign", Vector3.new(26, 7.4, 0.6), frame * CFrame.new(0, 18.2, -0.4), Color3.fromRGB(34, 74, 150))
	text(gui, "Title", "THE SHUK: SEEDS", 0.02, 0.4, Color3.new(1, 1, 1), 5)
	local restockLabel = text(gui, "Restock", "Restock in 5:00", 0.44, 0.27, GOLD, 4)
	local weatherLabel = text(gui, "Weather", "Weather: Clear skies", 0.72, 0.24, Color3.fromRGB(190, 255, 200), 3)
	place(model, "SignTrim", Vector3.new(27, 0.6, 0.9), frame * CFrame.new(0, 22.1, -0.4), GOLD, SMOOTH, { CanCollide = false })
	local crates = {}
	local count = #Catalog.crops
	local pitch = 4.5
	for index, crop in Catalog.crops do
		local x = (index - (count + 1) / 2) * pitch
		local cframe = frame * CFrame.new(x, 4.9, -0.4)
		local crate = place(model, "Crate_" .. crop.id, Vector3.new(3.6, 1.8, 2.8), cframe, WOOD_DARK, SMOOTH, { CanCollide = false })
		place(model, "CrateFill", Vector3.new(3.1, 0.4, 2.3), cframe * CFrame.new(0, 0.9, 0), SEED_COLORS[crop.id] or WHITE, SMOOTH, { CanCollide = false })
		for k = 1, 5 do
			Procedural.ball(model, "Seed", 0.7, cframe * CFrame.new(-1.2 + (k - 1) * 0.6, 1.3, (k % 2 - 0.5) * 0.7), SEED_COLORS[crop.id] or WHITE)
		end
		local rarity = Catalog.rarity(crop.rarity)
		local rc = rarity.color
		local billboard = Instance.new("BillboardGui")
		billboard.Size = UDim2.new(4.3, 0, 2.7, 0)
		billboard.StudsOffset = Vector3.new(0, 3.2, 0)
		billboard.MaxDistance = 60
		billboard.LightInfluence = 0
		billboard.Adornee = crate
		billboard.Parent = crate
		text(billboard, "Name", crop.name, 0, 0.42, Color3.fromRGB(rc[1], rc[2], rc[3]), 3)
		text(billboard, "Price", "$" .. Format.short(crop.seedCost), 0.42, 0.3, GOLD, 2.5)
		text(billboard, "Stock", "x0", 0.72, 0.28, Color3.new(1, 1, 1), 2.5)
		local prompt = Instance.new("ProximityPrompt")
		prompt.ObjectText = crop.name .. " seeds"
		prompt.ActionText = "Buy $" .. Format.short(crop.seedCost)
		prompt.HoldDuration = 0.2
		prompt.MaxActivationDistance = 7
		prompt.RequiresLineOfSight = false
		prompt.Parent = crate
		prompt.Triggered:Connect(function(who)
			if near(who, crate, 22) then
				GardenService.buySeed(who, crop.id)
			end
		end)
		crates[crop.id] = { prompt = prompt, billboard = billboard, crate = crate }
	end
	for _, part in model:GetChildren() do
		if part:IsA("BasePart") and part.Name == "Counter" then
			part.CanCollide = true
		end
	end
	model.Parent = root
	local function refresh()
		for id, entry in crates do
			local crop = Catalog.crop(id)
			local left = GardenService.stockOf(id)
			entry.billboard.Stock.Text = left > 0 and ("x" .. left .. " left") or "SOLD OUT"
			entry.billboard.Stock.TextColor3 = left > 0 and Color3.new(1, 1, 1) or Color3.fromRGB(255, 120, 120)
			entry.prompt.Enabled = left > 0
			entry.prompt.ObjectText = crop.name .. " seeds (" .. left .. " left)"
		end
	end
	GardenService.StockChanged:Connect(refresh)
	refresh()
	task.spawn(function()
		while model.Parent do
			restockLabel.Text = "Restock in " .. Catalog.formatTime(GardenService.secondsToRestock())
			local weather = Catalog.weatherEntry(Workspace:GetAttribute("Weather") or "clear")
			local endsAt = Workspace:GetAttribute("WeatherEndsAt") or 0
			local left = endsAt - Workspace:GetServerTimeNow()
			if weather.id ~= "clear" and left > 0 then
				weatherLabel.Text = weather.name .. "  " .. Catalog.formatTime(left)
				weatherLabel.TextColor3 = weather.id == "rain" and Color3.fromRGB(150, 200, 255) or Color3.fromRGB(255, 226, 120)
			else
				weatherLabel.Text = "Weather: Clear skies"
				weatherLabel.TextColor3 = Color3.fromRGB(190, 255, 200)
			end
			task.wait(1)
		end
	end)
end

local function buildSellStand(root, frame)
	local model = Instance.new("Model")
	model.Name = "SellStand"
	local width = 20
	local counter = place(model, "Counter", Vector3.new(width - 2, 3.6, 4.4), frame * CFrame.new(0, 1.8, -0.2), WOOD)
	place(model, "CounterTop", Vector3.new(width - 1, 0.5, 5), frame * CFrame.new(0, 3.85, -0.2), WOOD_LIGHT)
	place(model, "BackWall", Vector3.new(width - 2, 9, 0.8), frame * CFrame.new(0, 4.5, 3.3), WOOD_DARK)
	posts(model, frame, width, 13)
	awning(model, frame, width, 13.2, 8.5)
	local _, gui = board(model, "Sign", Vector3.new(17, 6, 0.6), frame * CFrame.new(0, 17.4, -0.4), Color3.fromRGB(176, 60, 70))
	text(gui, "Title", "SELL YOUR HARVEST", 0.04, 0.5, Color3.new(1, 1, 1), 5)
	text(gui, "Sub", "Fresh fruit, fair prices", 0.56, 0.36, GOLD, 4)
	place(model, "SignTrim", Vector3.new(18, 0.6, 0.9), frame * CFrame.new(0, 20.6, -0.4), GOLD, SMOOTH, { CanCollide = false })
	for index = 1, 3 do
		place(model, "Basket", Vector3.new(2.6, 1.4, 2.2), frame * CFrame.new(-6 + (index - 1) * 6, 4.8, -0.4), Color3.fromRGB(190, 142, 82), SMOOTH, { CanCollide = false })
		Procedural.ball(model, "Produce", 1.2, frame * CFrame.new(-6 + (index - 1) * 6 - 0.4, 5.6, -0.4), index == 1 and Color3.fromRGB(200, 48, 64) or (index == 2 and Color3.fromRGB(110, 54, 150) or Color3.fromRGB(238, 192, 62)))
		Procedural.ball(model, "Produce", 1.1, frame * CFrame.new(-6 + (index - 1) * 6 + 0.5, 5.5, -0.2), Color3.fromRGB(120, 170, 70))
	end
	local coins = place(model, "Coins", Vector3.new(2.4, 0.3, 2.4), frame * CFrame.new(6.6, 4.25, -0.3), GOLD, Enum.Material.Metal, { Shape = Enum.PartType.Cylinder, CanCollide = false })
	coins.CFrame = frame * CFrame.new(6.6, 4.2, -0.3) * CFrame.Angles(0, 0, math.pi / 2)
	local merchant = Assets.get("congregant_3")
	if merchant then
		local model2 = merchant
		if not merchant:IsA("Model") then
			model2 = Instance.new("Model")
			merchant.Parent = model2
		end
		model2.Name = "Merchant"
		Assets.setPassive(model2)
		Assets.groundPivot(model2)
		model2:PivotTo(frame * CFrame.new(0, 0.1, 1.8) * CFrame.Angles(0, 0, 0))
		model2.Parent = model
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.ObjectText = "Merchant"
	prompt.ActionText = "Sell harvest"
	prompt.HoldDuration = 0.4
	prompt.MaxActivationDistance = 9
	prompt.RequiresLineOfSight = false
	prompt.Parent = counter
	prompt.Triggered:Connect(function(who)
		if near(who, counter, 24) and Guard.allow(who, "GardenSell", Config.COOLDOWNS.GardenBuy) then
			GardenService.sell(who)
		end
	end)
	model.Parent = root
end

function Shuk.build()
	local old = Workspace:FindFirstChild("Shuk")
	if old then
		old:Destroy()
	end
	local root = Instance.new("Folder")
	root.Name = "Shuk"
	local radius = 66
	local function frameAt(degrees)
		local angle = math.rad(degrees)
		local position = Vector3.new(math.cos(angle) * radius, 0.45, math.sin(angle) * radius)
		return CFrame.lookAt(position, Vector3.new(0, 0.45, 0))
	end
	buildSeedShop(root, frameAt(22.5))
	buildSellStand(root, frameAt(337.5))
	root.Parent = Workspace
end

return Shuk
