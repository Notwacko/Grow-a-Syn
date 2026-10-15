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

local library = {
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

function OutfitBuilder.gearFor(pieceId)
	return GEAR[pieceId]
end

function OutfitBuilder.has(pieceId)
	return library[pieceId] ~= nil or GEAR[pieceId] ~= nil
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
	for _, id in pieceIds do
		local specs = library[id]
		if specs then
			for _, spec in specs do
				local body = character:FindFirstChild(spec.part)
				if body and body:IsA("BasePart") then
					local part = Instance.new("Part")
					part.Name = id
					part.Shape = spec.shape
					part.Size = spec.size * scale
					part.Color = spec.color
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
