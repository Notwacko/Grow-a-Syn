local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local Link = require(script.Parent.Link)
local Config = require(script.Parent.Config)
local Guard = require(script.Parent.Guard)
local Notify = require(script.Parent.Notify)
local Economy = require(script.Parent.Economy)
local Fx = require(script.Parent.Fx)
local Format = require(script.Parent.Format)
local Signal = require(script.Parent.Signal)
local Procedural = require(script.Parent.Procedural)
local Plants = require(script.Parent.garden.Plants)
local Weather = require(script.Parent.garden.Weather)
local Catalog = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GardenCatalog"))
local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))

local GardenService = {}

GardenService.StockChanged = Signal.new()
GardenService.Changed = Signal.new()

local place = Procedural.place

local states = {}
local stock = {}
local nextRestock = 0
local rng = Random.new()
local started = false

local WOOD = Color3.fromRGB(150, 104, 62)
local SOIL = Color3.fromRGB(94, 64, 44)
local GOLD = Color3.fromRGB(255, 214, 80)
local WEATHER_ROLL_SECONDS = 5

local function rarityColor(crop)
	local rarity = Catalog.rarity(crop.rarity)
	local c = rarity and rarity.color or { 255, 255, 255 }
	return Color3.fromRGB(c[1], c[2], c[3])
end

local function mutationNames(ids)
	local names = {}
	for _, id in ids do
		local mutation = Catalog.mutation(id)
		if mutation then
			table.insert(names, mutation.name)
		end
	end
	return table.concat(names, " ")
end

local function frameOf(plot)
	local land = plot.Land
	return land.CFrame * CFrame.new(0, land.Size.Y / 2, -land.Size.Z / 2)
end

---------------------------------------------------------------- stock

local function publishStock()
	for _, crop in Catalog.crops do
		Workspace:SetAttribute("Stock_" .. crop.id, stock[crop.id] or 0)
	end
	Workspace:SetAttribute("GardenRestockAt", nextRestock)
	GardenService.StockChanged:Fire()
end

local function restock(announce)
	stock = Catalog.rollStock(rng)
	nextRestock = Workspace:GetServerTimeNow() + Catalog.RESTOCK_SECONDS
	publishStock()
	if announce then
		for _, player in Players:GetPlayers() do
			Notify.send(player, "info", "The Shuk has new seeds!")
		end
	end
end

function GardenService.stockOf(cropId)
	return stock[cropId] or 0
end

function GardenService.secondsToRestock()
	return math.max(0, nextRestock - Workspace:GetServerTimeNow())
end

function GardenService.forceRestock()
	restock(true)
end

---------------------------------------------------------------- attributes and tools

local function basketValue(state)
	local total = 0
	for _, entry in state.basket do
		total += Catalog.value(Catalog.crop(entry.c), entry.w, entry.m)
	end
	return total
end

local function totalSeeds(state)
	local total = 0
	for _, count in state.seeds do
		total += count
	end
	return total
end

local function seedName(state)
	local crop = state.selected ~= "" and state.seeds[state.selected] and state.seeds[state.selected] > 0 and Catalog.crop(state.selected)
	return crop and crop.name or nil
end

local function bestSeed(state)
	if state.selected ~= "" and (state.seeds[state.selected] or 0) > 0 then
		return state.selected
	end
	local best
	for _, crop in Catalog.crops do
		if (state.seeds[crop.id] or 0) > 0 then
			best = crop.id
		end
	end
	return best
end

local function makeTool(state, crop)
	local tool = Instance.new("Tool")
	tool.Name = crop.name .. " Seeds"
	tool.CanBeDropped = false
	tool.RequiresHandle = true
	tool.ToolTip = "Click near an empty garden bed to plant"
	tool:SetAttribute("CropId", crop.id)
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.9, 1.3, 0.3)
	handle.Color = Color3.fromRGB(246, 238, 214)
	handle.Material = Enum.Material.SmoothPlastic
	handle.CanCollide = false
	handle.Massless = true
	handle.Parent = tool
	local stripe = Instance.new("Part")
	stripe.Name = "Label"
	stripe.Size = Vector3.new(0.7, 0.6, 0.34)
	stripe.Color = rarityColor(crop)
	stripe.Material = Enum.Material.SmoothPlastic
	stripe.CanCollide = false
	stripe.Massless = true
	stripe.CFrame = handle.CFrame
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = handle
	weld.Part1 = stripe
	weld.Parent = stripe
	stripe.Parent = tool
	tool.Grip = CFrame.new(0, -0.3, 0) * CFrame.Angles(0, 0, math.rad(-20))
	tool.Equipped:Connect(function()
		if state.selected ~= crop.id then
			state.selected = crop.id
			GardenService.refreshPrompts(state)
		end
	end)
	tool.Activated:Connect(function()
		GardenService.plantNearest(state.player, crop.id)
	end)
	return tool
end

local function syncTools(state)
	local player = state.player
	local backpack = player:FindFirstChildOfClass("Backpack")
	if not backpack then
		return
	end
	for _, crop in Catalog.crops do
		local count = state.seeds[crop.id] or 0
		local tool = state.tools[crop.id]
		if tool and not tool.Parent then
			tool = nil
			state.tools[crop.id] = nil
		end
		if count > 0 then
			if not tool then
				tool = makeTool(state, crop)
				state.tools[crop.id] = tool
				tool.Parent = backpack
			end
			tool.Name = string.format("%s Seeds x%d", crop.name, count)
		elseif tool then
			tool:Destroy()
			state.tools[crop.id] = nil
		end
	end
end

local function publish(state)
	local player = state.player
	for _, crop in Catalog.crops do
		player:SetAttribute("Seed_" .. crop.id, state.seeds[crop.id] or 0)
	end
	player:SetAttribute("Seeds", totalSeeds(state))
	player:SetAttribute("BasketCount", #state.basket)
	player:SetAttribute("BasketValue", basketValue(state))
	player:SetAttribute("SelectedSeed", state.selected)
	syncTools(state)
	GardenService.refreshPrompts(state)
	GardenService.Changed:Fire(player)
end

---------------------------------------------------------------- beds

local function bedSign(bed)
	return bed.soil:FindFirstChild("BedSign")
end

local function setSign(bed, title, info, color, range)
	local gui = bedSign(bed)
	if not gui then
		return
	end
	gui.Enabled = title ~= nil
	gui.MaxDistance = range or 38
	if title then
		gui.Title.Text = title
		gui.Info.Text = info or ""
		gui.Info.TextColor3 = color or Color3.new(1, 1, 1)
	end
end

local function buildGui(soil)
	local gui = Instance.new("BillboardGui")
	gui.Name = "BedSign"
	gui.Size = UDim2.fromOffset(150, 56)
	gui.StudsOffset = Vector3.new(0, 6.4, 0)
	gui.MaxDistance = 38
	gui.LightInfluence = 0
	gui.Enabled = false
	gui.Adornee = soil
	gui.Parent = soil
	local function label(name, y, height, color)
		local text = Instance.new("TextLabel")
		text.Name = name
		text.BackgroundTransparency = 1
		text.Position = UDim2.fromScale(0, y)
		text.Size = UDim2.fromScale(1, height)
		text.Font = Enum.Font.FredokaOne
		text.TextScaled = true
		text.TextColor3 = color
		text.Parent = gui
		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 3
		stroke.Color = Color3.fromRGB(30, 30, 50)
		stroke.Parent = text
	end
	label("Title", 0, 0.5, Color3.new(1, 1, 1))
	label("Info", 0.5, 0.5, Color3.new(1, 1, 1))
end

local function buildBed(state, index, frame, folder)
	local x, z = Catalog.bedPosition(index)
	local base = frame * CFrame.new(x, 0, z)
	local model = Instance.new("Model")
	model.Name = "Bed" .. index
	model:SetAttribute("BedIndex", index)
	local size = Catalog.BED_SIZE
	for _, spec in {
		{ Vector3.new(size, 0.8, 0.6), CFrame.new(0, 0.4, -size / 2 + 0.3) },
		{ Vector3.new(size, 0.8, 0.6), CFrame.new(0, 0.4, size / 2 - 0.3) },
		{ Vector3.new(0.6, 0.8, size - 1.2), CFrame.new(-size / 2 + 0.3, 0.4, 0) },
		{ Vector3.new(0.6, 0.8, size - 1.2), CFrame.new(size / 2 - 0.3, 0.4, 0) },
	} do
		place(model, "Border", spec[1], base * spec[2], WOOD)
	end
	local soil = place(model, "Soil", Vector3.new(size - 1.2, 0.5, size - 1.2), base * CFrame.new(0, 0.35, 0), SOIL)
	local mound = place(model, "Mound", Vector3.one * 2.2, base * CFrame.new(0, 0.55, 0), Color3.fromRGB(120, 82, 54), nil, { Shape = Enum.PartType.Ball, Transparency = 1, CanCollide = false })
	local cover = place(model, "Cover", Vector3.new(size - 0.6, 0.2, size - 0.6), base * CFrame.new(0, 0.95, 0), Color3.fromRGB(150, 154, 168), nil, { Transparency = 1, CanCollide = false })
	for _, part in model:GetChildren() do
		if part:IsA("BasePart") and part ~= soil then
			part.CanCollide = false
		end
	end
	local prompt = Instance.new("ProximityPrompt")
	prompt.ObjectText = "Garden bed"
	prompt.ActionText = "Plant"
	prompt.HoldDuration = 0.3
	prompt.MaxActivationDistance = 8
	prompt.RequiresLineOfSight = false
	prompt.Parent = soil
	buildGui(soil)
	model.Parent = folder
	local bed = {
		index = index,
		model = model,
		soil = soil,
		mound = mound,
		cover = cover,
		prompt = prompt,
		base = base,
		crop = nil,
		progress = 0,
		weight = 1,
		mutations = {},
		ready = false,
		regrowing = false,
		locked = false,
		stage = -1,
		rollClock = 0,
	}
	prompt.Triggered:Connect(function(who)
		GardenService.bedTriggered(who, index)
	end)
	return bed
end

local function refreshBedPrompt(state, bed)
	local prompt = bed.prompt
	if bed.locked then
		prompt.Enabled = false
		return
	end
	if not bed.crop then
		prompt.Enabled = true
		local name = seedName(state)
		prompt.ActionText = name and ("Plant " .. name) or "Plant (need seeds)"
	elseif bed.ready then
		local crop = Catalog.crop(bed.crop)
		prompt.Enabled = true
		prompt.ActionText = "Harvest " .. crop.name
	else
		prompt.Enabled = false
	end
end

function GardenService.refreshPrompts(state)
	for _, bed in state.beds do
		refreshBedPrompt(state, bed)
	end
end

local function lockText(index)
	for tier = 1, 6 do
		if index <= Catalog.bedCount(tier) then
			return tier
		end
	end
	return 6
end

local function applyLock(state, bed)
	local count = Catalog.bedCount(state.player:GetAttribute("LandTier") or 1)
	local locked = bed.index > count
	bed.locked = locked
	bed.cover.Transparency = locked and 0.25 or 1
	if locked then
		setSign(bed, "Locked", "Land tier " .. lockText(bed.index), Color3.fromRGB(190, 195, 210), 12)
	elseif not bed.crop then
		setSign(bed, nil)
	end
	refreshBedPrompt(state, bed)
end

local function showPlant(bed, stage)
	if not bed.plant then
		return
	end
	if bed.stage ~= stage then
		bed.stage = stage
		Plants.setStage(bed.plant, stage)
		bed.mound.Transparency = stage == 0 and 0 or 1
	end
end

local function spawnPlant(bed)
	if bed.plant then
		bed.plant:Destroy()
	end
	local plant = Plants.make(bed.crop)
	if not plant then
		return
	end
	bed.plant = plant
	bed.stage = -1
	plant:PivotTo(bed.base * CFrame.new(0, 0.6, 0))
	Plants.applyMutations(plant, bed.mutations)
	plant.Parent = bed.model
end

local function clearBed(bed)
	if bed.plant then
		bed.plant:Destroy()
		bed.plant = nil
	end
	bed.crop = nil
	bed.progress = 0
	bed.ready = false
	bed.regrowing = false
	bed.mutations = {}
	bed.stage = -1
	bed.mound.Transparency = 1
end

local function freshFruit(bed, crop)
	bed.weight = Catalog.rollWeight(rng, crop)
	bed.mutations = {}
	local variant = Catalog.rollVariant(rng)
	if variant then
		table.insert(bed.mutations, variant)
	end
end

local function updateBedVisual(state, bed)
	local crop = Catalog.crop(bed.crop)
	if not crop then
		return
	end
	local stage = bed.ready and 3 or math.min(Catalog.stageFor(bed.progress), 2)
	if bed.regrowing and not bed.ready then
		stage = math.max(1, stage)
	end
	showPlant(bed, stage)
	if bed.ready then
		local tags = mutationNames(bed.mutations)
		local info = string.format("READY  %.2f kg%s", bed.weight, tags ~= "" and ("  " .. tags) or "")
		setSign(bed, crop.name, info, GOLD)
	else
		local duration = bed.regrowing and crop.regrowSeconds or crop.growSeconds
		local speed = Weather.speed()
		setSign(bed, crop.name, Catalog.formatTime((1 - bed.progress) * duration / speed), Color3.fromRGB(190, 255, 200))
	end
	refreshBedPrompt(state, bed)
end

---------------------------------------------------------------- actions

function GardenService.plant(player, bedIndex, cropId)
	local state = states[player]
	if not state or not state.active then
		return false
	end
	local bed = state.beds[bedIndex]
	if not bed or bed.locked or bed.crop then
		return false
	end
	local crop = Catalog.crop(cropId)
	if not crop or (state.seeds[cropId] or 0) <= 0 then
		return false
	end
	state.seeds[cropId] -= 1
	if state.seeds[cropId] <= 0 then
		state.seeds[cropId] = nil
	end
	bed.crop = cropId
	bed.progress = 0
	bed.ready = false
	bed.regrowing = false
	freshFruit(bed, crop)
	spawnPlant(bed)
	showPlant(bed, 0)
	updateBedVisual(state, bed)
	local position = bed.base.Position + Vector3.new(0, 1, 0)
	Fx.puff(position)
	Fx.sound(position, Config.SOUNDS.pop, 0.5, 1.2)
	publish(state)
	return true
end

function GardenService.bedTriggered(who, bedIndex)
	local state = states[who]
	if not state then
		return
	end
	local bed = state.beds[bedIndex]
	if not bed then
		return
	end
	if not Guard.allow(who, "Garden", Config.COOLDOWNS.Garden) then
		return
	end
	if not Guard.nearPart(who, bed.soil, 16) then
		Guard.flag(who, "Garden", "too far from bed")
		return
	end
	if bed.locked then
		return
	end
	if not bed.crop then
		local cropId = bestSeed(state)
		if not cropId then
			Notify.send(who, "info", "You have no seeds. Buy some at the Shuk in the plaza!")
			return
		end
		GardenService.plant(who, bedIndex, cropId)
	elseif bed.ready then
		GardenService.harvest(who, bedIndex)
	end
end

function GardenService.plantNearest(player, cropId)
	local state = states[player]
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not state or not root or not state.active then
		return
	end
	if not Guard.allow(player, "Garden", Config.COOLDOWNS.Garden) then
		return
	end
	local best, bestDistance
	for _, bed in state.beds do
		if not bed.locked and not bed.crop then
			local distance = (bed.soil.Position - root.Position).Magnitude
			if distance <= 14 and (not bestDistance or distance < bestDistance) then
				best, bestDistance = bed, distance
			end
		end
	end
	if best then
		GardenService.plant(player, best.index, cropId)
	end
end

function GardenService.harvest(player, bedIndex)
	local state = states[player]
	if not state or not state.active then
		return false
	end
	local bed = state.beds[bedIndex]
	if not bed or not bed.crop or not bed.ready then
		return false
	end
	if #state.basket >= Catalog.BASKET_MAX then
		Notify.send(player, "error", "Your basket is full. Sell at the Shuk!")
		return false
	end
	local crop = Catalog.crop(bed.crop)
	table.insert(state.basket, { c = bed.crop, w = bed.weight, m = table.clone(bed.mutations) })
	local value = Catalog.value(crop, bed.weight, bed.mutations)
	local position = bed.base.Position + Vector3.new(0, 4.5, 0)
	local tags = mutationNames(bed.mutations)
	local color = rarityColor(crop)
	if #bed.mutations > 0 then
		local mutation = Catalog.mutation(bed.mutations[#bed.mutations])
		color = Color3.fromRGB(mutation.color[1], mutation.color[2], mutation.color[3])
		Fx.confetti(position, 0.5)
	end
	Fx.floatText(position, (tags ~= "" and (tags .. " ") or "") .. crop.name .. " $" .. Format.short(value), color)
	Fx.sparkle(position - Vector3.new(0, 1.5, 0))
	Fx.sound(position, Config.SOUNDS.coin, 0.6, 1 + #bed.mutations * 0.2)
	if crop.regrowSeconds then
		bed.progress = 0
		bed.ready = false
		bed.regrowing = true
		freshFruit(bed, crop)
		Plants.applyMutations(bed.plant, bed.mutations)
		bed.stage = -1
		updateBedVisual(state, bed)
	else
		Fx.puff(bed.base.Position + Vector3.new(0, 1, 0))
		clearBed(bed)
		setSign(bed, nil)
		refreshBedPrompt(state, bed)
	end
	publish(state)
	return true
end

function GardenService.sell(player)
	local state = states[player]
	if not state then
		return 0
	end
	if #state.basket == 0 then
		Notify.send(player, "info", "Your basket is empty. Harvest ripe plants first!")
		return 0
	end
	local total = basketValue(state)
	local count = #state.basket
	state.basket = {}
	Economy.grant(player, total, "harvest_sale")
	Notify.send(player, "success", string.format("Sold %d fruit for $%s", count, Format.short(total)))
	publish(state)
	return total
end

function GardenService.buySeed(player, cropId)
	local state = states[player]
	local crop = Catalog.crop(cropId)
	if not state or not crop then
		return false
	end
	if not Guard.allow(player, "GardenBuy", Config.COOLDOWNS.GardenBuy) then
		return false
	end
	if (stock[cropId] or 0) <= 0 then
		Notify.send(player, "error", crop.name .. " seeds are sold out. Wait for the restock!")
		return false
	end
	if (state.seeds[cropId] or 0) >= Catalog.SEED_MAX then
		Notify.send(player, "error", "You cannot carry more " .. crop.name .. " seeds")
		return false
	end
	if not Economy.spend(player, crop.seedCost, "seed_" .. cropId) then
		Notify.send(player, "error", "Not enough money for " .. crop.name .. " seeds")
		return false
	end
	stock[cropId] -= 1
	state.seeds[cropId] = (state.seeds[cropId] or 0) + 1
	if state.selected == "" or (state.seeds[state.selected] or 0) <= 0 then
		state.selected = cropId
	end
	Notify.send(player, "success", string.format("%s seeds x%d", crop.name, state.seeds[cropId]))
	publishStock()
	publish(state)
	Link.get(ServerStorage, "Bridge", Constants.BRIDGE.Purchased, "BindableEvent"):Fire(player, "seed_" .. cropId)
	return true
end

---------------------------------------------------------------- tick

local function weatherRoll(state, bed, dt)
	local entry = Weather.current()
	if not entry.mutation then
		return
	end
	bed.rollClock += dt
	if bed.rollClock < WEATHER_ROLL_SECONDS then
		return
	end
	bed.rollClock = 0
	if table.find(bed.mutations, entry.mutation) then
		return
	end
	if rng:NextNumber() < entry.chance then
		table.insert(bed.mutations, entry.mutation)
		Plants.applyMutations(bed.plant, bed.mutations)
	end
end

local function tick(dt)
	local speed = Weather.speed()
	for _, state in states do
		if state.active then
			for _, bed in state.beds do
				if bed.crop and not bed.ready and bed.plant then
					local crop = Catalog.crop(bed.crop)
					local duration = bed.regrowing and crop.regrowSeconds or crop.growSeconds
					bed.progress = math.min(1, bed.progress + dt * speed / duration)
					weatherRoll(state, bed, dt)
					if bed.progress >= 1 then
						bed.ready = true
						local position = bed.base.Position + Vector3.new(0, 3, 0)
						Fx.sparkle(position)
						Fx.sound(position, Config.SOUNDS.ping, 0.35, 1.5)
					end
					updateBedVisual(state, bed)
				end
			end
		end
	end
end

---------------------------------------------------------------- lifecycle

local function newState(player)
	return {
		player = player,
		plot = nil,
		folder = nil,
		active = false,
		seeds = {},
		basket = {},
		selected = "",
		beds = {},
		tools = {},
		pendingBeds = {},
		connections = {},
	}
end

function GardenService.watch(player)
	local state = newState(player)
	states[player] = state
	table.insert(state.connections, player.CharacterAdded:Connect(function()
		task.spawn(function()
			player:WaitForChild("Backpack", 10)
			task.wait(0.6)
			if states[player] == state then
				syncTools(state)
			end
		end)
	end))
	table.insert(state.connections, player:GetAttributeChangedSignal("LandTier"):Connect(function()
		if state.active then
			for _, bed in state.beds do
				applyLock(state, bed)
			end
		end
	end))
end

function GardenService.init(player, saved)
	local state = states[player]
	if not state then
		return
	end
	local clean = Catalog.sanitizeSave(saved)
	state.seeds = clean.seeds
	state.basket = clean.basket
	state.selected = clean.selected
	state.pendingBeds = clean.beds
	if state.active then
		GardenService.restoreBeds(state)
	end
	publish(state)
end

function GardenService.restoreBeds(state)
	local now = os.time()
	for _, saved in state.pendingBeds do
		local bed = state.beds[saved.i]
		if bed and not bed.crop then
			local crop = Catalog.crop(saved.c)
			bed.crop = saved.c
			bed.regrowing = saved.g
			bed.weight = saved.w
			bed.mutations = saved.m
			local duration = bed.regrowing and crop.regrowSeconds or crop.growSeconds
			local away = saved.s > 0 and math.max(0, now - saved.s) or 0
			bed.progress = math.clamp(saved.p + away / duration, 0, 1)
			bed.ready = bed.progress >= 1
			spawnPlant(bed)
			updateBedVisual(state, bed)
		end
	end
	state.pendingBeds = {}
end

function GardenService.onClaimed(player, plot)
	local state = states[player]
	if not state then
		return
	end
	if state.folder then
		state.folder:Destroy()
	end
	state.plot = plot
	state.beds = {}
	local folder = Instance.new("Folder")
	folder.Name = "Garden"
	local frame = frameOf(plot)
	local decor = plot:FindFirstChild("Decor")
	if decor then
		for _, child in decor:GetChildren() do
			local dx, dz = child:GetAttribute("DecorX"), child:GetAttribute("DecorZ")
			if dx and dz and math.abs(dx) >= 15 and math.abs(dx) <= 47 and dz >= 4 and dz <= 38 and child.Name ~= "prop_lamp" then
				child:Destroy()
			end
		end
	end
	for index = 1, Catalog.BED_COUNT do
		state.beds[index] = buildBed(state, index, frame, folder)
	end
	folder.Parent = plot
	state.folder = folder
	state.active = true
	for _, bed in state.beds do
		applyLock(state, bed)
	end
	GardenService.restoreBeds(state)
	publish(state)
end

function GardenService.onReleased(player)
	local state = states[player]
	if not state then
		return
	end
	state.pendingBeds = {}
	for index, bed in state.beds do
		if bed.crop then
			table.insert(state.pendingBeds, { i = index, c = bed.crop, p = bed.progress, s = os.time(), w = bed.weight, m = table.clone(bed.mutations), g = bed.regrowing })
		end
	end
	state.active = false
	if state.folder then
		state.folder:Destroy()
		state.folder = nil
	end
	state.beds = {}
	state.plot = nil
end

function GardenService.serialize(player)
	local state = states[player]
	if not state then
		return Catalog.sanitizeSave(nil)
	end
	local beds = {}
	if state.active then
		for index, bed in state.beds do
			if bed.crop then
				table.insert(beds, { i = index, c = bed.crop, p = bed.progress, s = os.time(), w = bed.weight, m = table.clone(bed.mutations), g = bed.regrowing })
			end
		end
	else
		beds = state.pendingBeds
	end
	return Catalog.sanitizeSave({ seeds = state.seeds, basket = state.basket, beds = beds, selected = state.selected })
end

function GardenService.forget(player)
	local state = states[player]
	if state then
		for _, connection in state.connections do
			connection:Disconnect()
		end
		if state.folder then
			state.folder:Destroy()
		end
		states[player] = nil
	end
end

function GardenService.start()
	if started then
		return
	end
	started = true
	Weather.start()
	restock(false)
	Workspace:GetAttributeChangedSignal("ForceRestock"):Connect(function()
		if Workspace:GetAttribute("ForceRestock") == true then
			Workspace:SetAttribute("ForceRestock", false)
			restock(true)
		end
	end)
	task.spawn(function()
		local last = os.clock()
		while true do
			task.wait(1)
			local now = os.clock()
			local dt = now - last
			last = now
			if Workspace:GetServerTimeNow() >= nextRestock then
				restock(true)
			end
			tick(dt)
		end
	end)
end

return GardenService
