local Assets = require(script.Parent.Assets)

local OutfitBuilder = {}

local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

local C = {
	black = rgb(26, 26, 32),
	charcoal = rgb(48, 50, 62),
	gray = rgb(112, 116, 128),
	navy = rgb(36, 54, 108),
	white = rgb(246, 246, 250),
	silver = rgb(200, 204, 216),
	gold = rgb(240, 190, 64),
	fur = rgb(110, 68, 42),
	furDark = rgb(84, 50, 32),
	velvet = rgb(20, 18, 26),
	hair = rgb(84, 56, 38),
	blue = rgb(70, 120, 220),
	sky = rgb(120, 196, 255),
	red = rgb(236, 84, 84),
	yellow = rgb(255, 214, 80),
	green = rgb(92, 204, 130),
	purple = rgb(160, 120, 235),
	cream = rgb(244, 232, 200),
	plum = rgb(70, 40, 96),
}

local BLOCK = Enum.PartType.Block
local BALL = Enum.PartType.Ball
local CYLINDER = Enum.PartType.Cylinder
local FABRIC = Enum.Material.Fabric
local SMOOTH = Enum.Material.SmoothPlastic

local function block(part, width, height, depth, x, y, z, color, material)
	return { part = part, shape = BLOCK, size = Vector3.new(width, height, depth), offset = CFrame.new(x, y, z), color = color, material = material or FABRIC }
end

local function ball(part, diameter, x, y, z, color, material)
	return { part = part, shape = BALL, size = Vector3.one * diameter, offset = CFrame.new(x, y, z), color = color, material = material or FABRIC }
end

local function disc(part, diameter, height, x, y, z, color, material)
	return { part = part, shape = CYLINDER, size = Vector3.new(height, diameter, diameter), offset = CFrame.new(x, y, z) * CFrame.Angles(0, 0, math.pi / 2), color = color, material = material or FABRIC }
end

local function both(make)
	local list = {}
	for _, side in { "Left", "Right" } do
		for _, spec in make(side, side == "Left" and -1 or 1) do
			table.insert(list, spec)
		end
	end
	return list
end

local function merge(...)
	local list = {}
	for _, group in { ... } do
		for _, spec in group do
			table.insert(list, spec)
		end
	end
	return list
end

local function sleeves(color)
	return both(function(side)
		return {
			block(side .. "UpperArm", 1.1, 1.3, 1.1, 0, 0, 0, color),
			block(side .. "LowerArm", 1.08, 1.02, 1.08, 0, 0.05, 0, color),
		}
	end)
end

local function jacket(color, shirtWidth, shirtHeight)
	shirtHeight = shirtHeight or 1.4
	return merge({
		block("UpperTorso", 2.1, 1.76, 1.1, 0, 0, 0, color),
		block("UpperTorso", shirtWidth, shirtHeight, 0.05, 0, 0.82 - shirtHeight / 2, -0.56, C.white, SMOOTH),
	}, sleeves(color))
end

local function longCoat(color, hemColor, stripes)
	local specs = merge(jacket(color, 0.44, 0.38), {
		block("UpperTorso", 1.06, 1.55, 1.26, -0.54, -1.62, 0, color),
		block("UpperTorso", 1.06, 1.55, 1.26, 0.54, -1.62, 0, color),
		block("UpperTorso", 2.2, 0.1, 1.32, 0, -2.4, 0, hemColor),
	})
	if stripes then
		for _, x in { -0.9, -0.58, -0.26, 0.26, 0.58, 0.9 } do
			table.insert(specs, block("UpperTorso", 0.07, 1.5, 1.29, x, -1.62, 0, stripes, SMOOTH))
		end
		table.insert(specs, block("UpperTorso", 2.14, 0.16, 1.14, 0, 0.85, 0, hemColor, SMOOTH))
	end
	return specs
end

local function gartel(color)
	return {
		block("LowerTorso", 2.3, 0.3, 1.32, 0, 0.12, 0, color, SMOOTH),
		block("LowerTorso", 0.34, 0.34, 0.12, 0.5, 0.08, -0.7, color, SMOOTH),
		block("LowerTorso", 2.32, 0.05, 1.34, 0, 0.26, 0, C.silver, SMOOTH),
	}
end

local function skirt(color)
	return {
		disc("LowerTorso", 2.2, 0.8, 0, -0.1, 0, color),
		disc("LowerTorso", 2.56, 0.95, 0, -0.95, 0, color),
	}
end

local function kippah(base, middle, top)
	return {
		disc("Head", 1.02, 0.1, 0, 0.65, 0, base),
		disc("Head", 0.76, 0.09, 0, 0.74, 0, middle or base),
		disc("Head", 0.46, 0.08, 0, 0.82, 0, top or middle or base),
	}
end

local function brimmedHat(brim, crown, band, color)
	return {
		disc("Head", brim, 0.1, 0, 0.62, 0, color),
		disc("Head", crown + 0.08, 0.22, 0, 0.75, 0, band),
		disc("Head", crown, 0.66, 0, 1.0, 0, color),
		disc("Head", crown - 0.4, 0.08, 0, 1.36, 0, C.charcoal),
	}
end

local function headScarf(color, accent)
	return {
		disc("Head", 1.34, 0.5, 0, 0.4, 0, color),
		disc("Head", 1.0, 0.2, 0, 0.72, 0, accent or color),
		ball("Head", 0.42, 0, 0.28, 0.7, accent or color),
		block("Head", 0.34, 0.62, 0.12, 0.14, -0.08, 0.68, color),
	}
end

local function hairShort(color)
	return {
		block("Head", 1.32, 0.44, 1.32, 0, 0.5, 0.06, color, SMOOTH),
		block("Head", 1.32, 0.2, 0.2, 0, 0.36, -0.62, color, SMOOTH),
		block("Head", 1.32, 0.86, 0.24, 0, 0.1, 0.64, color, SMOOTH),
		block("Head", 0.2, 0.62, 1.0, -0.62, 0.2, 0.1, color, SMOOTH),
		block("Head", 0.2, 0.62, 1.0, 0.62, 0.2, 0.1, color, SMOOTH),
	}
end

local function hairLong(color)
	return merge(hairShort(color), {
		block("Head", 1.44, 1.9, 0.34, 0, -0.45, 0.72, color, SMOOTH),
		block("Head", 0.26, 1.2, 0.9, -0.66, -0.2, 0.2, color, SMOOTH),
		block("Head", 0.26, 1.2, 0.9, 0.66, -0.2, 0.2, color, SMOOTH),
	})
end

local function hairBun(color)
	return merge(hairShort(color), {
		ball("Head", 0.62, 0, 0.88, 0.42, color, SMOOTH),
	})
end

local function hairCurly(color)
	return {
		ball("Head", 0.78, -0.42, 0.52, 0, color, SMOOTH),
		ball("Head", 0.78, 0.42, 0.52, 0, color, SMOOTH),
		ball("Head", 0.86, 0, 0.66, 0.1, color, SMOOTH),
		ball("Head", 0.7, -0.52, 0.2, 0.42, color, SMOOTH),
		ball("Head", 0.7, 0.52, 0.2, 0.42, color, SMOOTH),
		ball("Head", 0.82, 0, 0.1, 0.6, color, SMOOTH),
		ball("Head", 0.7, 0, 0.55, -0.4, color, SMOOTH),
	}
end

local library = {
	hair_short = hairShort(C.hair),
	hair_long = hairLong(C.hair),
	hair_bun = hairBun(C.hair),
	hair_curly = hairCurly(C.hair),
	kippah_rainbow = kippah(C.red, C.yellow, C.blue),
	kippah_navy = kippah(C.navy, C.navy, rgb(60, 82, 150)),
	kippah_knit = kippah(rgb(238, 232, 214), rgb(70, 120, 220), rgb(236, 84, 84)),
	kippah_velvet = kippah(C.velvet, C.velvet, rgb(40, 38, 52)),

	fedora_black = brimmedHat(2.5, 1.44, C.gray, C.black),
	hat_black_wide = brimmedHat(2.9, 1.56, C.charcoal, C.black),
	hat_modest = brimmedHat(1.9, 1.3, C.gray, C.charcoal),
	shtreimel = {
		disc("Head", 2.62, 0.55, 0, 0.86, 0, C.fur),
		disc("Head", 2.3, 0.36, 0, 1.28, 0, C.furDark),
		disc("Head", 1.5, 0.1, 0, 1.5, 0, C.velvet, SMOOTH),
	},
	tichel_blue = headScarf(rgb(80, 140, 235), C.sky),
	tichel_black = headScarf(C.charcoal, C.black),
	tichel_silk = headScarf(C.cream, C.gold),

	beard = {
		block("Head", 0.9, 0.36, 0.3, 0, -0.45, -0.5, C.hair),
		block("Head", 0.7, 0.26, 0.3, 0, -0.7, -0.46, C.hair),
		block("Head", 0.16, 0.5, 0.46, -0.55, -0.22, -0.34, C.hair),
		block("Head", 0.16, 0.5, 0.46, 0.55, -0.22, -0.34, C.hair),
	},
	peyot = both(function(_, sign)
		return {
			disc("Head", 0.13, 0.7, sign * 0.62, -0.02, -0.15, C.hair),
			disc("Head", 0.13, 0.28, sign * 0.6, -0.48, -0.15, C.hair),
		}
	end),

	blazer_gray = jacket(C.gray, 0.9),
	jacket_navy = jacket(C.navy, 0.62),
	jacket_black = jacket(C.black, 0.5),
	jacket_velvet = jacket(C.plum, 0.5),
	tie_blue = {
		block("UpperTorso", 0.2, 1.0, 0.06, 0, 0.2, -0.6, C.blue, SMOOTH),
	},
	kapote_black = longCoat(C.black, C.black, nil),
	bekishe_silk = longCoat(rgb(30, 28, 44), C.gold, C.silver),

	gartel_black = gartel(rgb(52, 52, 66)),
	gartel_white = gartel(C.white),
	tzitzit = both(function(_, sign)
		local specs = {}
		for k = 0, 2 do
			table.insert(specs, disc("LowerTorso", 0.05, 0.85, sign * 1.03, -0.55, -0.3 + k * 0.14, C.white, SMOOTH))
		end
		return specs
	end),
	socks_white = both(function(side)
		return { disc(side .. "LowerLeg", 1.06, 0.78, 0, -0.26, 0, C.white) }
	end),

	skirt_gray = skirt(C.gray),
	skirt_navy = skirt(C.navy),
	skirt_black = skirt(C.black),
}

local GEAR = {
	gear_kippah = { gear = "kippah", colors = {} },
	gear_tallit = { gear = "tallit", colors = {} },
	tallit_sky = { gear = "tallit", colors = { Stripe = C.sky } },
	tallit_classic = { gear = "tallit", colors = { Stripe = C.black } },
	tallit_gold = { gear = "tallit", colors = { Stripe = C.gold } },
}

local REFERENCE_HEIGHT = {
	Head = 1.202,
	UpperTorso = 1.901,
	LowerTorso = 0.632,
	LeftUpperArm = 1.213,
	RightUpperArm = 1.213,
	LeftLowerArm = 1.161,
	RightLowerArm = 1.161,
	LeftLowerLeg = 1.263,
	RightLowerLeg = 1.263,
}

local NAVY = rgb(47, 62, 122)
local MODEL_PIECES = {
	gear_kippah = { model = "ofit_kippah", colors = { Base = NAVY, Mid = NAVY, Top = rgb(74, 94, 168) } },
	kippah_rainbow = { model = "ofit_kippah", colors = { Base = C.red, Mid = C.yellow, Top = C.blue } },
	kippah_navy = { model = "ofit_kippah", colors = { Base = C.navy, Mid = C.navy, Top = rgb(60, 82, 150) } },
	kippah_velvet = { model = "ofit_kippah", colors = { Base = C.velvet, Mid = C.velvet, Top = rgb(44, 40, 58) } },
	kippah_knit = { model = "ofit_kippah_knit", colors = {} },
	fedora_black = { model = "ofit_hat_fedora", colors = {} },
	hat_black_wide = { model = "ofit_hat_wide", colors = {} },
	hat_modest = { model = "ofit_hat_modest", colors = { Hat = C.charcoal, Band = C.gray } },
	shtreimel = { model = "ofit_shtreimel", colors = {} },
	tichel_blue = { model = "ofit_tichel", colors = {} },
	tichel_black = { model = "ofit_tichel", colors = { Cloth = C.charcoal, Accent = C.black } },
	tichel_silk = { model = "ofit_tichel", colors = { Cloth = C.cream, Accent = C.gold } },
	hair_short = { model = "ofit_hair_short", colors = { Hair = C.hair } },
	hair_long = { model = "ofit_hair_long", colors = { Hair = C.hair } },
	hair_bun = { model = "ofit_hair_bun", colors = { Hair = C.hair } },
	hair_curly = { model = "ofit_hair_curly", colors = { Hair = C.hair } },
	hair_pony = { model = "ofit_hair_pony", colors = { Hair = C.hair } },
	beard = { model = "ofit_beard", colors = { Hair = C.hair } },
	peyot = { model = "ofit_peyot", colors = { Hair = C.hair } },
	blazer_gray = { model = "ofit_jacket_open", colors = { Cloth = C.gray, ClothDark = rgb(88, 92, 106) } },
	jacket_navy = { model = "ofit_jacket_closed", colors = {} },
	jacket_black = { model = "ofit_jacket_closed", colors = { Cloth = C.black, ClothDark = rgb(14, 14, 20) } },
	jacket_velvet = { model = "ofit_jacket_closed", colors = { Cloth = C.plum, ClothDark = rgb(52, 28, 72) } },
	tie_blue = { model = "ofit_tie", colors = {} },
	kapote_black = { model = "ofit_coat_long", colors = { Cloth = C.black, ClothDark = rgb(14, 14, 20) }, hide = { Stripe = true, Accent = true } },
	bekishe_silk = { model = "ofit_coat_long", colors = { Cloth = rgb(30, 28, 44), ClothDark = rgb(20, 18, 32) } },
	gartel_black = { model = "ofit_gartel", colors = { Belt = rgb(52, 52, 66) } },
	gartel_white = { model = "ofit_gartel", colors = { Belt = C.white } },
	tzitzit = { model = "ofit_tzitzit", colors = {} },
	socks_white = { model = "ofit_socks", colors = {} },
	skirt_gray = { model = "ofit_skirt_long", colors = { Cloth = C.gray } },
	skirt_navy = { model = "ofit_skirt_long", colors = {} },
	skirt_black = { model = "ofit_skirt_long", colors = { Cloth = C.black, Band = C.charcoal } },
	gear_tallit = { model = "ofit_tallit", colors = {} },
	tallit_sky = { model = "ofit_tallit", colors = { Stripe = C.sky } },
	tallit_classic = { model = "ofit_tallit", colors = { Stripe = C.black } },
	tallit_gold = { model = "ofit_tallit", colors = { Stripe = C.gold } },
}

local modelCache = {}

local function modelAvailable(name)
	local known = modelCache[name]
	if known == nil then
		local probe = Assets.get(name)
		known = probe ~= nil
		if probe then
			probe:Destroy()
		end
		modelCache[name] = known
	end
	return known
end

local function usesModel(pieceId)
	local spec = MODEL_PIECES[pieceId]
	return spec ~= nil and modelAvailable(spec.model)
end

function OutfitBuilder.modelExists(name)
	return modelAvailable(name)
end

function OutfitBuilder.gearFor(pieceId)
	if usesModel(pieceId) then
		return nil
	end
	return GEAR[pieceId]
end

function OutfitBuilder.has(pieceId)
	return library[pieceId] ~= nil or GEAR[pieceId] ~= nil or usesModel(pieceId)
end

local function attachModel(character, folder, pieceId, spec, overrides)
	local source = Assets.get(spec.model)
	if not source then
		return false
	end
	local attached = false
	for _, part in source:GetDescendants() do
		if part:IsA("BasePart") then
			local bodyName = part:GetAttribute("Body")
			local key = part:GetAttribute("Key")
			local offset = part:GetAttribute("Offset")
			local body = bodyName and character:FindFirstChild(bodyName)
			if body and body:IsA("BasePart") and typeof(offset) == "Vector3" and not (spec.hide and spec.hide[key]) then
				local factor = math.clamp(body.Size.Y / (REFERENCE_HEIGHT[bodyName] or body.Size.Y), 0.55, 1.8)
				local copy = part:Clone()
				copy.Name = pieceId
				copy.Size = part.Size * factor
				copy.Anchored = false
				copy.Massless = true
				copy.CanCollide = false
				copy.CanQuery = false
				copy.CanTouch = false
				copy.CastShadow = false
				local color = (overrides and overrides[key]) or spec.colors[key]
				if color then
					copy.Color = color
				end
				copy.CFrame = body.CFrame * CFrame.new(offset * factor)
				local weld = Instance.new("WeldConstraint")
				weld.Part0 = body
				weld.Part1 = copy
				weld.Parent = copy
				copy.Parent = folder
				attached = true
			end
		end
	end
	source:Destroy()
	return attached
end

function OutfitBuilder.apply(character, pieceIds)
	local old = character:FindFirstChild("CoreOutfit")
	if old then
		old:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = "CoreOutfit"
	local torso = character:FindFirstChild("UpperTorso")
	local scale = torso and math.clamp(torso.Size.Y / 1.698, 0.5, 2) or 1
	for _, entry in pieceIds do
		local id, overrides, tint, direct = entry, nil, nil, nil
		if type(entry) == "table" then
			id, overrides, tint, direct = entry.id, entry.colors, entry.color, entry.spec
		end
		local modelSpec = direct or MODEL_PIECES[id]
		local done = false
		if modelSpec and modelAvailable(modelSpec.model) then
			done = attachModel(character, folder, id, modelSpec, overrides)
		end
		local specs = library[id]
		if specs and not done then
			for _, spec in specs do
				local body = character:FindFirstChild(spec.part)
				if body and body:IsA("BasePart") then
					local part = Instance.new("Part")
					part.Name = id
					part.Shape = spec.shape
					part.Size = spec.size * scale
					part.Color = tint or spec.color
					part.Material = spec.material
					part.Massless = true
					part.CanCollide = false
					part.CanQuery = false
					part.CanTouch = false
					part.CastShadow = false
					part.TopSurface = Enum.SurfaceType.Smooth
					part.BottomSurface = Enum.SurfaceType.Smooth
					part.CFrame = body.CFrame * (CFrame.new(spec.offset.Position * scale) * spec.offset.Rotation)
					local weld = Instance.new("WeldConstraint")
					weld.Part0 = body
					weld.Part1 = part
					weld.Parent = part
					part.Parent = folder
				end
			end
		end
	end
	folder.Parent = character
	return folder
end

return OutfitBuilder
