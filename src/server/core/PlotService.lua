local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Link = require(script.Parent.Link)
local Config = require(script.Parent.Config)
local Guard = require(script.Parent.Guard)
local Notify = require(script.Parent.Notify)
local Economy = require(script.Parent.Economy)
local Fx = require(script.Parent.Fx)
local Format = require(script.Parent.Format)
local Props = require(script.Parent.Props)
local Procedural = require(script.Parent.Procedural)
local Signal = require(script.Parent.Signal)
local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))

local PlotService = {}

PlotService.Claimed = Signal.new()
PlotService.Released = Signal.new()

local place = Procedural.place

local plots = {}
local ownerPlot = {}
local readyPlayers = {}
local animateNext = {}
local landConnections = {}

local FLAG_COLORS = {
	[2] = Color3.fromRGB(255, 107, 107),
	[3] = Color3.fromRGB(255, 154, 72),
	[4] = Color3.fromRGB(255, 205, 66),
	[5] = Color3.fromRGB(94, 214, 130),
	[6] = Color3.fromRGB(86, 156, 255),
}

local BASE_DECOR = {
	{ "lamp", -9, 3, 0 },
	{ "lamp", 9, 3, 0 },
	{ "flowers", -14, 9, 0 },
	{ "flowers", 14, 9, 0 },
	{ "tree", -40, 88, 0 },
	{ "tree", 40, 88, 0 },
	{ "tree", -42, 62, 0 },
	{ "tree", 42, 62, 0 },
	{ "tree", -38, 34, 0 },
	{ "tree", 38, 34, 0 },
}

local function orchard()
	local list = {}
	for row, z in { 150, 164, 178 } do
		local offset = (row % 2 == 0) and 8 or 0
		for x = -64, 60, 16 do
			table.insert(list, { "tree", x + offset, z, 0 })
		end
	end
	table.insert(list, { "lamp", -74, 144, 0 })
	table.insert(list, { "lamp", 74, 144, 0 })
	table.insert(list, { "bench", -60, 186, 180 })
	table.insert(list, { "bench", 60, 186, 180 })
	return list
end

local EXTENSION_DECOR = {
	[2] = {
		{ "tree", -34, 128, 0 },
		{ "tree", 34, 128, 0 },
		{ "tree", 0, 134, 0 },
		{ "tree", -18, 118, 0 },
		{ "tree", 18, 118, 0 },
		{ "flowers", -26, 106, 0 },
		{ "flowers", 26, 106, 0 },
		{ "lamp", -44, 108, 0 },
		{ "lamp", 44, 108, 0 },
	},
	[3] = {
		{ "bench", -70, 30, -90 },
		{ "bench", -70, 70, -90 },
		{ "lamp", -62, 10, 0 },
		{ "lamp", -62, 100, 0 },
		{ "tree", -72, 112, 0 },
		{ "tree", -72, 126, 0 },
		{ "flowers", -66, 50, 0 },
	},
	[4] = {
		{ "bench", 70, 30, 90 },
		{ "bench", 70, 70, 90 },
		{ "lamp", 62, 10, 0 },
		{ "lamp", 62, 100, 0 },
		{ "tree", 72, 112, 0 },
		{ "tree", 72, 126, 0 },
		{ "flowers", 66, 50, 0 },
	},
	[5] = orchard(),
	[6] = {
		{ "fountain", 0, 216, 0 },
		{ "flowers", -24, 200, 0 },
		{ "flowers", 24, 200, 0 },
		{ "flowers", -24, 232, 0 },
		{ "flowers", 24, 232, 0 },
		{ "lamp", -70, 196, 0 },
		{ "lamp", 70, 196, 0 },
		{ "lamp", -70, 234, 0 },
		{ "lamp", 70, 234, 0 },
		{ "tree", -70, 215, 0 },
		{ "tree", 70, 215, 0 },
		{ "tree", -52, 232, 0 },
		{ "tree", 52, 232, 0 },
		{ "bench", -44, 214, -90 },
		{ "bench", 44, 214, 90 },
	},
}

local function frameOf(plot)
	local land = plot.Land
	return land.CFrame * CFrame.new(0, land.Size.Y / 2, -land.Size.Z / 2)
end

local function stripes(parent, frame, x1, x2, z1, z2, yOffset)
	local width = x2 - x1
	local count = math.floor((z2 - z1) / 10)
	for i = 0, count - 1 do
		if i % 2 == 1 then
			place(parent, "LawnStripe", Vector3.new(width, 0.12, 10), frame * CFrame.new((x1 + x2) / 2, 0.06 + yOffset, z1 + i * 10 + 5), Config.COLORS.grassLight, Enum.Material.Plastic, {
				TopSurface = Enum.SurfaceType.Studs,
				CanCollide = false,
			})
		end
	end
end

local function placeDecor(parent, frame, list, delayStep)
	local models = {}
	for index, item in list do
		local kind, x, z, yaw = item[1], item[2], item[3], item[4]
		local jitter = (kind == "tree") and (((index * 37) % 40) - 20) or 0
		local cframe = frame * CFrame.new(x, 0, z) * CFrame.Angles(0, math.rad(yaw + jitter), 0)
		local model = Props.make(kind)
		if model then
			model:SetAttribute("DecorX", x)
			model:SetAttribute("DecorZ", z)
			model:PivotTo(cframe)
			if delayStep then
				task.delay((index - 1) * delayStep, function()
					if parent:IsDescendantOf(Workspace) then
						model.Parent = parent
						Fx.sparkle(cframe.Position + Vector3.new(0, 3, 0))
					else
						model:Destroy()
					end
				end)
			else
				model.Parent = parent
			end
			table.insert(models, model)
		end
	end
	return models
end

local FENCE_SEGMENT = 8

local function railFence(folder, frame, ax, az, bx, bz)
	local a = Vector3.new(ax, 0, az)
	local b = Vector3.new(bx, 0, bz)
	local length = (b - a).Magnitude
	if length < 1 then
		return
	end
	local mid = (a + b) / 2
	local direction = (b - a).Unit
	local cframe = frame * CFrame.lookAt(mid, mid + direction)
	local count = math.max(1, math.round(length / FENCE_SEGMENT))
	local spacing = length / count
	local wall = place(folder, "FenceWall", Vector3.new(0.6, 4, length), cframe * CFrame.new(0, 2, 0), Config.COLORS.wood, nil, { Transparency = 1, CanQuery = false, CastShadow = false })
	wall.Name = "FenceWall"
	if Props.has("fence") then
		local lookAlong = CFrame.lookAt(Vector3.zero, direction)
		local across = lookAlong * CFrame.Angles(0, math.pi / 2, 0)
		for i = 0, count - 1 do
			local point = a:Lerp(b, (i + 0.5) / count)
			local segment = Props.make("fence")
			segment:ScaleTo(segment:GetScale() * spacing / FENCE_SEGMENT)
			segment:PivotTo(frame * CFrame.new(point) * across)
			segment.Parent = folder
		end
	else
		place(folder, "RailLow", Vector3.new(0.5, 0.6, length), cframe * CFrame.new(0, 1.3, 0), Config.COLORS.wood)
		place(folder, "RailHigh", Vector3.new(0.5, 0.6, length), cframe * CFrame.new(0, 2.8, 0), Config.COLORS.wood)
		for i = 0, count do
			local point = a:Lerp(b, i / count)
			place(folder, "Post", Vector3.new(0.9, 4, 0.9), frame * CFrame.new(point.X, 2, point.Z), Config.COLORS.wood)
		end
	end
end

local function buildFence(plot, frame, tier)
	local old = plot:FindFirstChild("Fence")
	if old then
		old:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = "Fence"
	local bounds = Config.LAND_BOUNDS[math.clamp(tier, 1, Constants.MAX_LAND_TIER)]
	local gate = 8
	railFence(folder, frame, bounds.x1, 0, -gate, 0)
	railFence(folder, frame, gate, 0, bounds.x2, 0)
	railFence(folder, frame, bounds.x1, bounds.z2, bounds.x2, bounds.z2)
	railFence(folder, frame, bounds.x1, 0, bounds.x1, bounds.z2)
	railFence(folder, frame, bounds.x2, 0, bounds.x2, bounds.z2)
	for _, side in { -1, 1 } do
		local pillar = Props.place(folder, "gate_pillar", frame * CFrame.new(side * gate, 0, 0), "gate_pillar")
		if not pillar then
			place(folder, "GatePillar", Vector3.new(2.2, 7, 2.2), frame * CFrame.new(side * gate, 3.5, 0), Config.COLORS.stone)
			place(folder, "GateCap", Vector3.new(3, 0.8, 3), frame * CFrame.new(side * gate, 7.4, 0), Config.COLORS.gold, Enum.Material.Neon)
		else
			local block = place(folder, "GateBlock", Vector3.new(2.6, 7, 2.6), frame * CFrame.new(side * gate, 3.5, 0), Config.COLORS.stone, nil, { Transparency = 1, CanQuery = false, CastShadow = false })
			block.Name = "GateBlock"
		end
	end
	folder.Parent = plot
end

local function buildSign(pad, index)
	local gui = Instance.new("BillboardGui")
	gui.Name = "PlotSign"
	gui.Size = UDim2.fromOffset(170, 62)
	gui.StudsOffset = Vector3.new(0, 7, 0)
	gui.MaxDistance = 130
	gui.LightInfluence = 0
	gui.Adornee = pad
	gui.Parent = pad
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.BackgroundTransparency = 1
	title.Size = UDim2.fromScale(1, 0.62)
	title.Font = Enum.Font.FredokaOne
	title.TextScaled = true
	title.TextColor3 = Color3.new(1, 1, 1)
	title.Text = "FREE PLOT"
	title.Parent = gui
	local titleStroke = Instance.new("UIStroke")
	titleStroke.Thickness = 3
	titleStroke.Color = Color3.fromRGB(30, 30, 50)
	titleStroke.Parent = title
	local sub = Instance.new("TextLabel")
	sub.Name = "Sub"
	sub.BackgroundTransparency = 1
	sub.Position = UDim2.fromScale(0, 0.62)
	sub.Size = UDim2.fromScale(1, 0.38)
	sub.Font = Enum.Font.FredokaOne
	sub.TextScaled = true
	sub.TextColor3 = Color3.fromRGB(255, 226, 110)
	sub.Text = "PLOT " .. index
	sub.Parent = gui
	local subStroke = Instance.new("UIStroke")
	subStroke.Thickness = 2
	subStroke.Color = Color3.fromRGB(30, 30, 50)
	subStroke.Parent = sub
end

local function refreshPad(plot)
	local pad = plot:FindFirstChild("ClaimPad")
	if not pad then
		return
	end
	local prompt = pad:FindFirstChildOfClass("ProximityPrompt")
	local sign = pad:FindFirstChild("PlotSign")
	local title = sign and sign:FindFirstChild("Title")
	local sub = sign and sign:FindFirstChild("Sub")
	local index = plot:GetAttribute("PlotIndex") or 0
	local ownerId = plot:GetAttribute("OwnerUserId") or 0
	local owner = ownerId ~= 0 and Players:GetPlayerByUserId(ownerId) or nil
	if owner then
		local tier = owner:GetAttribute("LandTier") or 1
		pad.Color = Config.COLORS.padOwned
		if prompt then
			if tier >= Constants.MAX_LAND_TIER then
				prompt.ActionText = "Land fully expanded"
				prompt.ObjectText = owner.DisplayName
				prompt.Enabled = false
			else
				prompt.ActionText = "Expand Land"
				prompt.ObjectText = "Cost " .. Format.short(Config.LAND_COSTS[tier])
				prompt.HoldDuration = 0.6
				prompt.Enabled = true
			end
		end
		if title then
			title.Text = owner.DisplayName .. "'s Synagogue"
		end
		if sub then
			sub.Text = "LAND " .. tier .. "/" .. Constants.MAX_LAND_TIER
		end
	else
		pad.Color = Config.COLORS.padFree
		if prompt then
			prompt.ActionText = "Claim Plot"
			prompt.ObjectText = "Plot " .. index
			prompt.HoldDuration = 0.4
			prompt.Enabled = true
		end
		if title then
			title.Text = "FREE PLOT"
		end
		if sub then
			sub.Text = "PLOT " .. index
		end
	end
end

local function ensurePad(plot, index, frame)
	local pad = plot:FindFirstChild("ClaimPad")
	if not pad then
		pad = place(plot, "ClaimPad", Vector3.new(0.6, 11, 11), frame * CFrame.new(Config.CLAIM_PAD_LOCAL + Vector3.new(0, 0.4, 0)) * CFrame.Angles(0, 0, math.pi / 2), Config.COLORS.padFree, Enum.Material.Neon, {
			Shape = Enum.PartType.Cylinder,
			CanCollide = false,
		})
	end
	if not pad:FindFirstChildOfClass("ProximityPrompt") then
		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Claim Plot"
		prompt.ObjectText = "Plot " .. index
		prompt.HoldDuration = 0.4
		prompt.MaxActivationDistance = 14
		prompt.RequiresLineOfSight = false
		prompt.Parent = pad
	end
	if not pad:FindFirstChild("PlotSign") then
		buildSign(pad, index)
	end
	if not plot:FindFirstChild("PadRing") then
		local ring = Props.place(plot, "padring", frame * CFrame.new(Config.CLAIM_PAD_LOCAL.X, 0.5, Config.CLAIM_PAD_LOCAL.Z), "padring")
		if ring then
			ring.Name = "PadRing"
		end
	end
	local prompt = pad:FindFirstChildOfClass("ProximityPrompt")
	prompt.Triggered:Connect(function(player)
		PlotService.padTriggered(player, index)
	end)
end

local function ensureStructure(plot, index)
	local land = plot:FindFirstChild("Land")
	if not land then
		warn("[PlotService] " .. plot.Name .. " has no Land part, skipped")
		return false
	end
	local frame = frameOf(plot)
	plot.PrimaryPart = land
	if plot:GetAttribute("OwnerUserId") == nil then
		plot:SetAttribute("OwnerUserId", 0)
	end
	if plot:GetAttribute("BuildingVersion") == nil then
		plot:SetAttribute("BuildingVersion", 0)
	end
	plot:SetAttribute("PlotIndex", index)
	ensurePad(plot, index, frame)
	if not plot:FindFirstChild("NpcSpawn") then
		place(plot, "NpcSpawn", Vector3.new(3, 0.2, 3), frame * CFrame.new(Config.NPC_SPAWN_LOCAL + Vector3.new(0, 0.1, 0)), Color3.new(1, 1, 1), nil, {
			Transparency = 1,
			CanCollide = false,
			CanQuery = false,
			CanTouch = false,
		})
	end
	if not plot:FindFirstChild("BuildingAnchor") then
		place(plot, "BuildingAnchor", Vector3.new(2, 0.2, 2), frame * CFrame.new(Config.BUILDING_ANCHOR_LOCAL + Vector3.new(0, 0.1, 0)), Color3.new(1, 1, 1), nil, {
			Transparency = 1,
			CanCollide = false,
			CanQuery = false,
			CanTouch = false,
		})
	end
	if not plot:FindFirstChild("PlotSpawn") then
		place(plot, "PlotSpawn", Vector3.new(2, 0.2, 2), frame * CFrame.new(Config.PLOT_SPAWN_LOCAL + Vector3.new(0, 0.1, 0)), Color3.new(1, 1, 1), nil, {
			Transparency = 1,
			CanCollide = false,
			CanQuery = false,
			CanTouch = false,
		})
	end
	local building = plot:FindFirstChild("Building")
	if not building then
		building = Instance.new("Model")
		building.Name = "Building"
		building.Parent = plot
	end
	if not plot:FindFirstChild("Congregants") then
		local folder = Instance.new("Folder")
		folder.Name = "Congregants"
		folder.Parent = plot
	end
	return true
end

local function buildBaseDecor(plot, frame)
	local old = plot:FindFirstChild("Decor")
	if old then
		old:Destroy()
	end
	local decor = Instance.new("Folder")
	decor.Name = "Decor"
	place(decor, "Path", Vector3.new(7, 0.2, 50), frame * CFrame.new(0, 0.1, 25), Config.COLORS.path, Enum.Material.SmoothPlastic, { CanCollide = false })
	placeDecor(decor, frame, BASE_DECOR, nil)
	decor.Parent = plot
end

local function createPlot(index)
	local frame = Config.plotFrame(index)
	local plot = Instance.new("Model")
	plot.Name = "Plot" .. index
	local size = Config.BASE_LAND
	local land = place(plot, "Land", Vector3.new(size.width, 1, size.depth), frame * CFrame.new(0, -0.5, size.depth / 2), Config.COLORS.plot, Enum.Material.Plastic, {
		TopSurface = Enum.SurfaceType.Studs,
	})
	stripes(plot, frame, -size.width / 2, size.width / 2, 0, size.depth, 0)
	plot.PrimaryPart = land
	return plot
end

local function clearFolder(folder)
	if folder then
		for _, child in folder:GetChildren() do
			child:Destroy()
		end
	end
end

local function extensionFolder(plot)
	local folder = plot:FindFirstChild("Expansion")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Expansion"
		folder.Parent = plot
	end
	return folder
end

local function applyLand(plot, tier, animate)
	local frame = frameOf(plot)
	tier = math.clamp(tier, 1, Constants.MAX_LAND_TIER)
	local folder = extensionFolder(plot)
	local animatedTier = false
	for t = 2, Constants.MAX_LAND_TIER do
		local existing = folder:FindFirstChild("Ext" .. t)
		if t <= tier and not existing then
			local region = Config.LAND_REGIONS[t]
			local group = Instance.new("Folder")
			group.Name = "Ext" .. t
			local cx = (region.x1 + region.x2) / 2
			local cz = (region.z1 + region.z2) / 2
			local target = frame * CFrame.new(cx, -0.5, cz)
			local strip = place(group, "Land" .. t, Vector3.new(region.x2 - region.x1, 1, region.z2 - region.z1), target, Config.COLORS.plot, Enum.Material.Plastic, {
				TopSurface = Enum.SurfaceType.Studs,
			})
			stripes(group, frame, region.x1, region.x2, region.z1, region.z2, 0)
			local flagColor = FLAG_COLORS[t]
			local flagX, flagZ = cx, region.z2 - 4
			local flag = Props.place(group, "flag", frame * CFrame.new(flagX, 0, flagZ), "flag")
			if flag then
				for _, part in flag:GetDescendants() do
					if part:IsA("BasePart") and part.Name == "Accent" then
						part.Color = flagColor
					end
				end
			else
				place(group, "FlagPole", Vector3.new(0.6, 14, 0.6), frame * CFrame.new(flagX, 7, flagZ), Config.COLORS.woodDark)
				place(group, "Flag", Vector3.new(6, 3.4, 0.3), frame * CFrame.new(flagX + 3.2, 12, flagZ), flagColor, Enum.Material.SmoothPlastic, { CanCollide = false })
				place(group, "FlagTop", Vector3.new(1.2, 1.2, 1.2), frame * CFrame.new(flagX, 14.4, flagZ), Config.COLORS.gold, Enum.Material.Neon, { Shape = Enum.PartType.Ball, CanCollide = false })
			end
			local decorFolder = Instance.new("Folder")
			decorFolder.Name = "Decor"
			decorFolder.Parent = group
			if animate then
				strip.CFrame = target * CFrame.new(0, -14, 0)
				for _, child in group:GetChildren() do
					if child:IsA("BasePart") and child ~= strip then
						child.CFrame = child.CFrame * CFrame.new(0, -14, 0)
						TweenService:Create(child, TweenInfo.new(0.9, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
							CFrame = child.CFrame * CFrame.new(0, 14, 0),
						}):Play()
					elseif child:IsA("Model") then
						local final = child:GetPivot()
						child:PivotTo(final * CFrame.new(0, -14, 0))
						task.spawn(function()
							for step = 1, 18 do
								if not child.Parent then
									return
								end
								local t = step / 18
								local eased = 1 + 2.7 * (t - 1) ^ 3 + 1.7 * (t - 1) ^ 2
								child:PivotTo(final * CFrame.new(0, -14 * (1 - eased), 0))
								task.wait(0.05)
							end
							if child.Parent then
								child:PivotTo(final)
							end
						end)
					end
				end
				TweenService:Create(strip, TweenInfo.new(0.9, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { CFrame = target }):Play()
				local middle = (target * CFrame.new(0, 1, 0)).Position
				Fx.puff(middle)
				Fx.ring(middle, flagColor, 36)
				Fx.floatText(middle + Vector3.new(0, 9, 0), "LAND " .. t, flagColor)
				placeDecor(decorFolder, frame, EXTENSION_DECOR[t], 0.09)
				animatedTier = true
			else
				placeDecor(decorFolder, frame, EXTENSION_DECOR[t], nil)
			end
			group.Parent = folder
		elseif t > tier and existing then
			existing:Destroy()
		end
	end
	if animatedTier then
		task.delay(0.9, function()
			if plot.Parent then
				buildFence(plot, frame, tier)
			end
		end)
	else
		buildFence(plot, frame, tier)
	end
end

local function clearFootprint(plot, floor)
	local frame = frameOf(plot)
	local relative = frame:ToObjectSpace(floor.CFrame)
	local localCenter = relative.Position
	local right, up, look = relative.RightVector, relative.UpVector, relative.LookVector
	local sx, sy, sz = floor.Size.X / 2, floor.Size.Y / 2, floor.Size.Z / 2
	local halfX = math.abs(right.X) * sx + math.abs(up.X) * sy + math.abs(look.X) * sz + 3
	local halfZ = math.abs(right.Z) * sx + math.abs(up.Z) * sy + math.abs(look.Z) * sz + 3
	local function sweep(folder)
		for _, model in folder:GetChildren() do
			if model:IsA("Model") then
				local x = model:GetAttribute("DecorX")
				local z = model:GetAttribute("DecorZ")
				if x and z and math.abs(x - localCenter.X) < halfX and math.abs(z - localCenter.Z) < halfZ then
					model:Destroy()
				end
			end
		end
	end
	local decor = plot:FindFirstChild("Decor")
	if decor then
		sweep(decor)
	end
	local expansion = plot:FindFirstChild("Expansion")
	if expansion then
		for _, group in expansion:GetChildren() do
			local inner = group:FindFirstChild("Decor")
			if inner then
				sweep(inner)
			end
		end
	end
end

local function resetLand(plot)
	local frame = frameOf(plot)
	clearFolder(plot:FindFirstChild("Expansion"))
	buildFence(plot, frame, 1)
	buildBaseDecor(plot, frame)
end

function PlotService.clearFootprint(plot, floor)
	clearFootprint(plot, floor)
end

function PlotService.getPlot(player)
	local index = ownerPlot[player]
	return index and plots[index] or nil
end

function PlotService.getIndex(player)
	return ownerPlot[player]
end

function PlotService.getPlots()
	return plots
end

function PlotService.freePlotCount()
	local free = 0
	for _, plot in plots do
		if plot:GetAttribute("OwnerUserId") == 0 then
			free += 1
		end
	end
	return free
end

function PlotService.markReady(player)
	readyPlayers[player] = true
end

function PlotService.homeCFrame(player)
	local plot = PlotService.getPlot(player)
	if not plot then
		return nil
	end
	local spawn = plot:FindFirstChild("PlotSpawn")
	local pad = plot:FindFirstChild("ClaimPad")
	if not spawn then
		return nil
	end
	local lookAt = pad and Vector3.new(pad.Position.X, spawn.Position.Y, pad.Position.Z) or spawn.Position + spawn.CFrame.LookVector
	return CFrame.lookAt(spawn.Position + Vector3.new(0, 4, 0), lookAt + Vector3.new(0, 4, 0))
end

function PlotService.teleportHome(player)
	local character = player.Character
	local cframe = PlotService.homeCFrame(player)
	if not character or not cframe then
		return
	end
	local root = character:WaitForChild("HumanoidRootPart", 5)
	if root and character.Parent then
		character:PivotTo(cframe)
	end
end

function PlotService.claim(player, index, fromPrompt)
	if not Guard.isPlayer(player) then
		return false
	end
	if not readyPlayers[player] then
		Notify.send(player, "info", "Hold on, loading your synagogue...")
		return false
	end
	if ownerPlot[player] then
		Notify.send(player, "error", "You already have a plot")
		return false
	end
	local plot = plots[index]
	if not plot then
		return false
	end
	if plot:GetAttribute("OwnerUserId") ~= 0 then
		Notify.send(player, "error", "That plot is taken")
		return false
	end
	if fromPrompt and not Guard.nearPart(player, plot.ClaimPad, Config.CLAIM_DISTANCE) then
		return false
	end
	plot:SetAttribute("OwnerUserId", player.UserId)
	ownerPlot[player] = index
	player:SetAttribute("PlotId", index)
	refreshPad(plot)
	applyLand(plot, player:GetAttribute("LandTier") or 1, false)
	local pad = plot.ClaimPad
	Fx.confetti(pad.Position + Vector3.new(0, 3, 0), 0.8)
	Fx.ring(pad.Position + Vector3.new(0, 0.5, 0), Config.COLORS.gold, 18)
	if fromPrompt then
		Fx.sound(pad.Position, Config.SOUNDS.victory, 0.8, 1)
		Fx.fireworkShow(pad.Position + Vector3.new(0, 0, 0), 4, 42)
	end
	Notify.send(player, "success", "Plot claimed! Welcome to your synagogue")
	PlotService.Claimed:Fire(player, plot, index)
	return true
end

function PlotService.padTriggered(player, index)
	local plot = plots[index]
	if not plot or not Guard.isPlayer(player) then
		return
	end
	local ownerId = plot:GetAttribute("OwnerUserId")
	if ownerId == 0 then
		PlotService.claim(player, index, true)
	elseif ownerId == player.UserId then
		if not Guard.nearPart(player, plot.ClaimPad, Config.CLAIM_DISTANCE) then
			Guard.flag(player, "ExpandLand", "too far from pad")
			return
		end
		if Guard.allow(player, "ExpandLand", Config.COOLDOWNS.ExpandLand) then
			PlotService.expandLand(player)
		end
	else
		Notify.send(player, "info", "This synagogue belongs to another player")
	end
end

function PlotService.autoClaim(player)
	for index = 1, Constants.PLOT_COUNT do
		local plot = plots[index]
		if plot and plot:GetAttribute("OwnerUserId") == 0 then
			if PlotService.claim(player, index, false) then
				task.spawn(PlotService.teleportHome, player)
				return true
			end
		end
	end
	Notify.send(player, "info", "All plots are taken right now")
	return false
end

function PlotService.release(player)
	local index = ownerPlot[player]
	if not index then
		return
	end
	local plot = plots[index]
	PlotService.Released:Fire(player, plot, index)
	ownerPlot[player] = nil
	plot:SetAttribute("OwnerUserId", 0)
	clearFolder(plot:FindFirstChild("Building"))
	clearFolder(plot:FindFirstChild("Congregants"))
	resetLand(plot)
	refreshPad(plot)
	if player.Parent then
		player:SetAttribute("PlotId", 0)
	end
end

function PlotService.expandLand(player)
	local index = ownerPlot[player]
	if not index then
		Notify.send(player, "error", "Claim a plot first")
		return false
	end
	local tier = player:GetAttribute("LandTier") or 1
	if tier >= Constants.MAX_LAND_TIER then
		Notify.send(player, "info", "Your land is fully expanded")
		return false
	end
	local cost = Config.LAND_COSTS[tier]
	if not Economy.spend(player, cost, "land_expansion") then
		Notify.send(player, "error", "Not enough money to expand")
		return false
	end
	animateNext[player] = true
	player:SetAttribute("LandTier", tier + 1)
	local plot = plots[index]
	Fx.confetti(plot.ClaimPad.Position + Vector3.new(0, 4, 0), 1)
	Notify.send(player, "success", "Land expanded!")
	return true
end

function PlotService.watch(player)
	player.CharacterAdded:Connect(function()
		if ownerPlot[player] then
			task.defer(PlotService.teleportHome, player)
		end
	end)
	landConnections[player] = player:GetAttributeChangedSignal("LandTier"):Connect(function()
		local index = ownerPlot[player]
		if not index then
			return
		end
		local animate = animateNext[player] == true
		animateNext[player] = nil
		applyLand(plots[index], player:GetAttribute("LandTier") or 1, animate)
		refreshPad(plots[index])
	end)
end

function PlotService.forget(player)
	readyPlayers[player] = nil
	animateNext[player] = nil
	local connection = landConnections[player]
	if connection then
		connection:Disconnect()
		landConnections[player] = nil
	end
end

function PlotService.build()
	local folder = Workspace:FindFirstChild("Plots")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Plots"
		folder.Parent = Workspace
	end
	if #folder:GetChildren() == 0 then
		for index = 1, Constants.PLOT_COUNT do
			local plot = createPlot(index)
			plot.Parent = folder
			if ensureStructure(plot, index) then
				buildBaseDecor(plot, frameOf(plot))
				buildFence(plot, frameOf(plot), 1)
				plots[index] = plot
			end
		end
	else
		for index = 1, Constants.PLOT_COUNT do
			local plot = folder:FindFirstChild("Plot" .. index)
			if plot and plot:IsA("Model") and ensureStructure(plot, index) then
				plots[index] = plot
				plot:SetAttribute("OwnerUserId", 0)
				if not plot:FindFirstChild("Fence") then
					buildFence(plot, frameOf(plot), 1)
				end
			end
		end
	end
	local claim = Link.get(ReplicatedStorage, "Remotes", "RE_ClaimPlot", "RemoteEvent")
	local expand = Link.get(ReplicatedStorage, "Remotes", "RE_ExpandLand", "RemoteEvent")
	Guard.connect(claim, "ClaimPlot", Config.COOLDOWNS.ClaimPlot, function(player, plotId)
		if not Guard.isInteger(plotId, 1, Constants.PLOT_COUNT) then
			Guard.flag(player, "ClaimPlot", "bad plot id")
			return
		end
		local plot = plots[plotId]
		if plot and not Guard.nearPart(player, plot.ClaimPad, Config.CLAIM_DISTANCE) then
			Guard.flag(player, "ClaimPlot", "too far from pad")
			Notify.send(player, "error", "Walk closer to the claim pad")
			return
		end
		PlotService.claim(player, plotId, true)
	end)
	Guard.connect(expand, "ExpandLand", Config.COOLDOWNS.ExpandLand, function(player)
		PlotService.expandLand(player)
	end)
end

return PlotService
