local Players = game:GetService("Players")

local Config = require(script.Parent.Config)
local OutfitBuilder = require(script.Parent.OutfitBuilder)

local NpcAvatar = {}

NpcAvatar.available = false

local WALK_ID = "rbxassetid://507777826"
local IDLE_ID = "rbxassetid://507766388"
local WAVE_ID = "rbxassetid://507770239"
local SEAT_ROOT_OFFSET = 0.35
local KID_SCALE = 0.72

local BODIES = {
	{ key = "m1", gender = "m", height = 1, width = 1, bodyType = 0, proportion = 0 },
	{ key = "m2", gender = "m", height = 1.05, width = 0.92, bodyType = 0, proportion = 0 },
	{ key = "m3", gender = "m", height = 0.94, width = 1, bodyType = 0.1, proportion = 0 },
	{ key = "f1", gender = "f", height = 0.95, width = 0.9, bodyType = 0.5, proportion = 0 },
	{ key = "f2", gender = "f", height = 1, width = 0.85, bodyType = 0.35, proportion = 0.3 },
	{ key = "f3", gender = "f", height = 0.92, width = 0.95, bodyType = 0.6, proportion = 0 },
}

local SKIN = {
	Color3.fromRGB(255, 224, 196),
	Color3.fromRGB(245, 205, 168),
	Color3.fromRGB(232, 186, 140),
	Color3.fromRGB(214, 160, 108),
	Color3.fromRGB(184, 126, 84),
	Color3.fromRGB(150, 100, 68),
	Color3.fromRGB(112, 72, 48),
	Color3.fromRGB(86, 56, 40),
}
local SKIN_WEIGHTS = { 16, 20, 20, 16, 12, 8, 5, 3 }

local HAIR = {
	Color3.fromRGB(30, 22, 18),
	Color3.fromRGB(60, 40, 30),
	Color3.fromRGB(110, 70, 40),
	Color3.fromRGB(160, 100, 50),
	Color3.fromRGB(205, 160, 90),
	Color3.fromRGB(170, 70, 40),
	Color3.fromRGB(170, 170, 176),
}

local SHIRTS = {
	Color3.fromRGB(255, 255, 255),
	Color3.fromRGB(150, 196, 255),
	Color3.fromRGB(255, 140, 140),
	Color3.fromRGB(255, 214, 110),
	Color3.fromRGB(130, 220, 160),
	Color3.fromRGB(196, 160, 255),
	Color3.fromRGB(255, 176, 110),
	Color3.fromRGB(110, 210, 214),
	Color3.fromRGB(244, 232, 200),
	Color3.fromRGB(240, 170, 200),
}

local DARK_SHIRTS = {
	Color3.fromRGB(255, 255, 255),
	Color3.fromRGB(226, 232, 244),
	Color3.fromRGB(190, 210, 240),
}

local PANTS = Config.CLOTH_BOTTOM_COLORS

local BLAZERS = {
	Color3.fromRGB(112, 116, 128),
	Color3.fromRGB(70, 90, 140),
	Color3.fromRGB(96, 70, 90),
	Color3.fromRGB(70, 110, 96),
	Color3.fromRGB(150, 120, 90),
}

local SKIRTS = {
	Color3.fromRGB(36, 54, 108),
	Color3.fromRGB(26, 26, 32),
	Color3.fromRGB(112, 116, 128),
	Color3.fromRGB(110, 60, 84),
	Color3.fromRGB(60, 100, 90),
	Color3.fromRGB(150, 110, 80),
}

local SCARVES = {
	{ Color3.fromRGB(80, 140, 235), Color3.fromRGB(120, 196, 255) },
	{ Color3.fromRGB(196, 80, 110), Color3.fromRGB(255, 170, 190) },
	{ Color3.fromRGB(48, 50, 62), Color3.fromRGB(26, 26, 32) },
	{ Color3.fromRGB(244, 232, 200), Color3.fromRGB(240, 190, 64) },
	{ Color3.fromRGB(110, 170, 130), Color3.fromRGB(190, 230, 200) },
	{ Color3.fromRGB(150, 110, 200), Color3.fromRGB(220, 200, 250) },
}

local TALLIT_STRIPES = {
	Color3.fromRGB(26, 26, 32),
	Color3.fromRGB(70, 120, 220),
	Color3.fromRGB(120, 196, 255),
	Color3.fromRGB(240, 190, 64),
	Color3.fromRGB(110, 70, 150),
}

local templates = {}
local motion = setmetatable({}, { __mode = "k" })

local function choose(random, list)
	return list[random:NextInteger(1, #list)]
end

local function weighted(random, entries)
	local total = 0
	for _, entry in entries do
		total += entry[1]
	end
	local roll = random:NextNumber() * total
	for _, entry in entries do
		roll -= entry[1]
		if roll <= 0 then
			return entry[2]
		end
	end
	return entries[#entries][2]
end

local function lighter(color, amount)
	return color:Lerp(Color3.new(1, 1, 1), amount)
end

local function kippahPiece(random, id)
	local base = choose(random, Config.KIPPAH_COLORS)
	return { id = id or "kippah_navy", colors = { Base = base, Mid = base, Top = lighter(base, 0.3) } }
end

local function tallitPiece(random)
	return { id = "gear_tallit", colors = { Stripe = choose(random, TALLIT_STRIPES) } }
end

local function jacketPiece(random, id, cloth)
	cloth = cloth or choose(random, BLAZERS)
	return { id = id, colors = { Cloth = cloth, ClothDark = cloth:Lerp(Color3.new(0, 0, 0), 0.25), Trim = cloth:Lerp(Color3.new(0, 0, 0), 0.4) } }
end

local function hairPiece(random, female)
	local color = choose(random, HAIR)
	local style
	if female then
		style = weighted(random, { { 4, "hair_long" }, { 3, "hair_bun" }, { 2, "hair_curly" }, { 2, "hair_short" } })
	else
		style = weighted(random, { { 5, "hair_short" }, { 2, "hair_curly" } })
	end
	return { id = style, color = color, colors = { Hair = color } }
end

local function hairy(id, color)
	return { id = id, color = color, colors = { Hair = color } }
end

local BLACK = Color3.fromRGB(26, 26, 32)

local function menProfile(random, kind)
	local profile = { gender = "m", pieces = {}, legs = choose(random, PANTS) }
	local pieces = profile.pieces
	if kind == "reform" then
		profile.shirt = choose(random, SHIRTS)
		table.insert(pieces, kippahPiece(random))
		table.insert(pieces, hairPiece(random, false))
		if random:NextNumber() < 0.45 then
			table.insert(pieces, jacketPiece(random, "blazer_gray"))
		end
		if random:NextNumber() < 0.4 then
			table.insert(pieces, tallitPiece(random))
		end
	elseif kind == "conservative" then
		profile.shirt = choose(random, DARK_SHIRTS)
		profile.legs = Color3.fromRGB(38, 44, 66)
		table.insert(pieces, kippahPiece(random))
		table.insert(pieces, hairPiece(random, false))
		table.insert(pieces, jacketPiece(random, "jacket_navy", choose(random, { Color3.fromRGB(36, 54, 108), Color3.fromRGB(58, 58, 70), Color3.fromRGB(70, 56, 52) })))
		table.insert(pieces, { id = "tie_blue", colors = { Tie = choose(random, { Color3.fromRGB(196, 60, 70), Color3.fromRGB(70, 120, 220), Color3.fromRGB(240, 190, 64), Color3.fromRGB(110, 70, 150) }) } })
		if random:NextNumber() < 0.5 then
			table.insert(pieces, { id = "tallit_classic", colors = { Stripe = choose(random, TALLIT_STRIPES) } })
		end
	elseif kind == "orthodox" then
		profile.shirt = choose(random, DARK_SHIRTS)
		profile.legs = Color3.fromRGB(30, 30, 38)
		local base = choose(random, { Color3.fromRGB(238, 232, 214), Color3.fromRGB(150, 196, 255), Color3.fromRGB(255, 190, 190), Color3.fromRGB(190, 230, 190), Color3.fromRGB(220, 200, 250) })
		table.insert(pieces, { id = "kippah_knit", colors = { Base = base, Mid = Color3.fromRGB(70, 120, 220), Top = Color3.fromRGB(236, 84, 84) } })
		table.insert(pieces, hairPiece(random, false))
		table.insert(pieces, { id = "tzitzit", colors = {} })
		if random:NextNumber() < 0.45 then
			table.insert(pieces, jacketPiece(random, "jacket_black", BLACK))
		end
		if random:NextNumber() < 0.3 then
			table.insert(pieces, hairy("beard", choose(random, HAIR)))
		end
	elseif kind == "blackhat" then
		profile.shirt = Color3.new(1, 1, 1)
		profile.legs = Color3.fromRGB(26, 26, 32)
		table.insert(pieces, { id = "fedora_black", colors = {} })
		table.insert(pieces, jacketPiece(random, "jacket_black", BLACK))
		table.insert(pieces, { id = "tzitzit", colors = {} })
		table.insert(pieces, hairy("beard", choose(random, HAIR)))
	else
		profile.shirt = Color3.new(1, 1, 1)
		profile.legs = Color3.fromRGB(26, 26, 32)
		local wide = random:NextNumber() < 0.7
		table.insert(pieces, wide and { id = "hat_black_wide", colors = {} } or { id = "shtreimel", colors = {} })
		table.insert(pieces, { id = "kapote_black", colors = {} })
		table.insert(pieces, { id = "gartel_black", colors = {} })
		table.insert(pieces, { id = "socks_white", colors = {} })
		table.insert(pieces, hairy("peyot", choose(random, HAIR)))
		table.insert(pieces, hairy("beard", choose(random, HAIR)))
	end
	return profile
end

local function womenProfile(random, kind)
	local profile = { gender = "f", pieces = {}, legs = choose(random, PANTS), shirt = choose(random, SHIRTS) }
	local pieces = profile.pieces
	if kind == "modern" then
		table.insert(pieces, hairPiece(random, true))
		if random:NextNumber() < 0.6 then
			local skirt = choose(random, SKIRTS)
			table.insert(pieces, { id = "skirt_navy", colors = { Cloth = skirt, Band = skirt:Lerp(Color3.new(0, 0, 0), 0.3) } })
		end
		if random:NextNumber() < 0.35 then
			table.insert(pieces, jacketPiece(random, "blazer_gray"))
		end
		if random:NextNumber() < 0.25 then
			table.insert(pieces, tallitPiece(random))
		end
	elseif kind == "modest" then
		local scarf = choose(random, SCARVES)
		table.insert(pieces, { id = "tichel_blue", colors = { Cloth = scarf[1], Accent = scarf[2] } })
		local skirt = choose(random, SKIRTS)
		table.insert(pieces, { id = "skirt_navy", colors = { Cloth = skirt, Band = skirt:Lerp(Color3.new(0, 0, 0), 0.3) } })
		table.insert(pieces, jacketPiece(random, "blazer_gray", choose(random, BLAZERS)))
	elseif kind == "hat" then
		table.insert(pieces, hairPiece(random, true))
		local hatColor = choose(random, { Color3.fromRGB(48, 50, 62), Color3.fromRGB(150, 70, 90), Color3.fromRGB(70, 90, 140), Color3.fromRGB(110, 116, 128) })
		table.insert(pieces, { id = "hat_modest", colors = { Hat = hatColor, Band = lighter(hatColor, 0.4) } })
		local skirt = choose(random, SKIRTS)
		table.insert(pieces, { id = "skirt_navy", colors = { Cloth = skirt, Band = skirt:Lerp(Color3.new(0, 0, 0), 0.3) } })
		table.insert(pieces, jacketPiece(random, "jacket_navy", choose(random, BLAZERS)))
	else
		profile.legs = Color3.fromRGB(26, 26, 32)
		table.insert(pieces, { id = "tichel_black", colors = {} })
		table.insert(pieces, { id = "skirt_black", colors = {} })
		table.insert(pieces, jacketPiece(random, "jacket_black", BLACK))
	end
	return profile
end

local MEN_WEIGHTS = {
	[1] = { { 40, "reform" }, { 30, "conservative" }, { 20, "orthodox" }, { 10, "blackhat" } },
	[2] = { { 60, "reform" }, { 25, "conservative" }, { 10, "orthodox" }, { 5, "blackhat" } },
	[3] = { { 25, "reform" }, { 50, "conservative" }, { 15, "orthodox" }, { 8, "blackhat" }, { 2, "hasidic" } },
	[4] = { { 5, "reform" }, { 20, "conservative" }, { 45, "orthodox" }, { 25, "blackhat" }, { 5, "hasidic" } },
	[5] = { { 20, "orthodox" }, { 50, "blackhat" }, { 30, "hasidic" } },
	[6] = { { 5, "orthodox" }, { 25, "blackhat" }, { 70, "hasidic" } },
	[7] = { { 15, "blackhat" }, { 85, "hasidic" } },
}

local WOMEN_WEIGHTS = {
	[1] = { { 55, "modern" }, { 25, "modest" }, { 20, "hat" } },
	[2] = { { 70, "modern" }, { 15, "modest" }, { 15, "hat" } },
	[3] = { { 50, "modern" }, { 25, "modest" }, { 25, "hat" } },
	[4] = { { 15, "modern" }, { 50, "modest" }, { 30, "hat" }, { 5, "hasidic" } },
	[5] = { { 5, "modern" }, { 55, "modest" }, { 25, "hat" }, { 15, "hasidic" } },
	[6] = { { 45, "modest" }, { 10, "hat" }, { 45, "hasidic" } },
	[7] = { { 30, "modest" }, { 70, "hasidic" } },
}

local function colorBody(model, skin, shirt, legs, longSleeves, shoes)
	local function paint(name, color)
		local part = model:FindFirstChild(name)
		if part and part:IsA("BasePart") then
			part.Color = color
		end
	end
	paint("Head", skin)
	paint("LeftHand", skin)
	paint("RightHand", skin)
	paint("UpperTorso", shirt)
	paint("LowerTorso", shirt)
	for _, side in { "Left", "Right" } do
		paint(side .. "UpperArm", shirt)
		paint(side .. "LowerArm", longSleeves and shirt or skin)
		paint(side .. "UpperLeg", legs)
		paint(side .. "LowerLeg", legs)
		paint(side .. "Foot", shoes)
	end
end

local function prepareTemplate(model)
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local root = model:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root then
		return false
	end
	pcall(function()
		humanoid.EvaluateStateMachine = false
	end)
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	humanoid.NameDisplayDistance = 0
	humanoid.HealthDisplayDistance = 0
	humanoid.BreakJointsOnDeath = false
	if not humanoid:FindFirstChildOfClass("Animator") then
		Instance.new("Animator").Parent = humanoid
	end
	local head = model:FindFirstChild("Head")
	if head and not head:FindFirstChildOfClass("Decal") then
		local face = Instance.new("Decal")
		face.Name = "face"
		face.Texture = "rbxasset://textures/face.png"
		face.Face = Enum.NormalId.Front
		face.Parent = head
	end
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			descendant.CanCollide = false
			descendant.CanTouch = false
			descendant.CanQuery = false
			descendant.Massless = true
			descendant.CastShadow = Config.CONGREGANT_SHADOWS
			descendant.Anchored = false
			descendant.Material = Enum.Material.SmoothPlastic
		end
	end
	root.Anchored = true
	model.PrimaryPart = root
	return true
end

local function feetDistance(model)
	local root = model.PrimaryPart
	local lowest = math.huge
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") and (part.Name == "LeftFoot" or part.Name == "RightFoot") then
			lowest = math.min(lowest, part.Position.Y - part.Size.Y / 2)
		end
	end
	return root.Position.Y - lowest
end

function NpcAvatar.prepare()
	if NpcAvatar.available then
		return true
	end
	local built = 0
	for _, body in BODIES do
		if not templates[body.key] then
			local ok, model = pcall(function()
				local description = Instance.new("HumanoidDescription")
				description.HeightScale = body.height
				description.WidthScale = body.width
				description.DepthScale = 1
				description.HeadScale = 1
				description.BodyTypeScale = body.bodyType
				description.ProportionScale = body.proportion
				return Players:CreateHumanoidModelFromDescription(description, Enum.HumanoidRigType.R15)
			end)
			if ok and model and prepareTemplate(model) then
				model.Name = "NpcTemplate_" .. body.key
				templates[body.key] = model
				built += 1
			else
				local reason = tostring(model)
				if ok and model then
					model:Destroy()
					reason = "rig missing humanoid"
				end
				warn("[NpcAvatar] could not build template " .. body.key .. ": " .. reason)
			end
		else
			built += 1
		end
	end
	NpcAvatar.available = built >= 2
	return NpcAvatar.available
end

local function templatesFor(gender)
	local list = {}
	for _, body in BODIES do
		if body.gender == gender and templates[body.key] then
			table.insert(list, templates[body.key])
		end
	end
	if #list == 0 then
		for _, template in templates do
			table.insert(list, template)
		end
	end
	return list
end

function NpcAvatar.create(tier, seed)
	if not NpcAvatar.available then
		return nil
	end
	local random = Random.new(seed or math.random(1, 2 ^ 30))
	tier = math.clamp(math.floor(tonumber(tier) or 1), 1, 7)
	local female = random:NextNumber() < 0.42
	local kid = random:NextNumber() < 0.14
	local profile
	if female then
		profile = womenProfile(random, weighted(random, WOMEN_WEIGHTS[tier]))
	else
		profile = menProfile(random, weighted(random, MEN_WEIGHTS[tier]))
	end
	local list = templatesFor(profile.gender)
	local model = choose(random, list):Clone()
	model.Name = "Congregant"
	local skin = weighted(random, (function()
		local entries = {}
		for index, color in SKIN do
			table.insert(entries, { SKIN_WEIGHTS[index], color })
		end
		return entries
	end)())
	local longSleeves = random:NextNumber() < 0.7
	colorBody(model, skin, profile.shirt, profile.legs, longSleeves, Color3.fromRGB(34, 34, 44))
	if kid then
		local pieces = {}
		for _, piece in profile.pieces do
			local id = type(piece) == "table" and piece.id or piece
			if id == "kippah_navy" or id == "kippah_knit" or string.sub(id, 1, 5) == "hair_" or id == "tichel_blue" or id == "skirt_navy" or id == "gear_tallit" then
				table.insert(pieces, piece)
			end
		end
		profile.pieces = pieces
	end
	OutfitBuilder.apply(model, profile.pieces)
	local scale = kid and KID_SCALE * random:NextNumber(0.95, 1.1) or random:NextNumber(0.96, 1.06)
	model:ScaleTo(scale)
	local root = model.PrimaryPart
	local down = feetDistance(model)
	root.PivotOffset = CFrame.new(0, -down, 0)
	local hip = down - SEAT_ROOT_OFFSET * scale
	local head = model:FindFirstChild("Head")
	local top = down + (head.Position.Y + head.Size.Y / 2 - root.Position.Y)
	return model, hip, 0, top
end

local function motorsOf(model)
	local motors = {}
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("Motor6D") then
			motors[descendant.Name] = descendant
		end
	end
	return motors
end

local function bend(motor, x)
	if motor then
		motor.C0 = motor.C0 * CFrame.Angles(x, 0, 0)
	end
end

function NpcAvatar.release(model)
	local info = motion[model]
	if info then
		for _, track in info.tracks do
			pcall(function()
				track:Stop(0)
				track:Destroy()
			end)
		end
		motion[model] = nil
	end
end

function NpcAvatar.sit(model)
	if not model or model:GetAttribute("Seated") then
		return
	end
	model:SetAttribute("Seated", true)
	NpcAvatar.release(model)
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if humanoid then
		local animator = humanoid:FindFirstChildOfClass("Animator")
		if animator then
			animator:Destroy()
		end
	end
	local motors = motorsOf(model)
	for _, side in { "Left", "Right" } do
		bend(motors[side .. "Hip"], math.pi / 2)
		bend(motors[side .. "Knee"], -math.pi / 2)
		bend(motors[side .. "Shoulder"], 0.45)
		bend(motors[side .. "Elbow"], 0.9)
	end
	if humanoid then
		humanoid:Destroy()
	end
end

local function loadTrack(model, id, looped, priority)
	local info = motion[model]
	if not info then
		info = { tracks = {} }
		motion[model] = info
	end
	if info.tracks[id] then
		return info.tracks[id]
	end
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		return nil
	end
	local animation = Instance.new("Animation")
	animation.AnimationId = id
	local ok, track = pcall(function()
		return animator:LoadAnimation(animation)
	end)
	animation:Destroy()
	if not ok or not track then
		return nil
	end
	track.Looped = looped
	track.Priority = priority or Enum.AnimationPriority.Core
	info.tracks[id] = track
	return track
end

function NpcAvatar.walk(model, speed)
	if not model or model:GetAttribute("Seated") then
		return false
	end
	local info = motion[model]
	if info then
		for id, track in info.tracks do
			if id ~= WALK_ID then
				pcall(function()
					track:Stop(0.15)
				end)
			end
		end
	end
	local track = loadTrack(model, WALK_ID, true, Enum.AnimationPriority.Movement)
	if not track then
		return false
	end
	if not track.IsPlaying then
		track:Play(0.15)
	end
	track:AdjustSpeed(math.clamp((speed or 13) / 14, 0.5, 1.6))
	return true
end

function NpcAvatar.wave(model)
	if not model or model:GetAttribute("Seated") then
		return false
	end
	local idle = loadTrack(model, IDLE_ID, true, Enum.AnimationPriority.Idle)
	if idle and not idle.IsPlaying then
		idle:Play(0.1)
	end
	local wave = loadTrack(model, WAVE_ID, true, Enum.AnimationPriority.Action)
	if wave and not wave.IsPlaying then
		wave:Play(0.1)
	end
	return wave ~= nil
end

function NpcAvatar.stopMotion(model)
	local info = motion[model]
	if info then
		for _, track in info.tracks do
			pcall(function()
				track:Stop(0.1)
			end)
		end
	end
end

return NpcAvatar
