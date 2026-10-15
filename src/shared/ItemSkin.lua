local ItemCatalog = require(script.Parent.ItemCatalog)

local ItemSkin = {}

local METAL_LABELS = { Trim = true, Gold = true, Silver = true }

local BRONZE = Color3.fromRGB(176, 128, 70)
local GILD = Color3.fromRGB(255, 214, 80)

local function parts(model)
	local list = {}
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			table.insert(list, descendant)
		end
	end
	return list
end

local function largest(list)
	local best, volume = nil, -1
	for _, part in list do
		local size = part.Size.X * part.Size.Y * part.Size.Z
		if size > volume then
			best, volume = part, size
		end
	end
	return best
end

local function sparkle(host, color, rate, size)
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "SkinSparkle"
	emitter.Rate = rate
	emitter.Lifetime = NumberRange.new(0.9, 1.6)
	emitter.Speed = NumberRange.new(0.4, 1.6)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Acceleration = Vector3.new(0, 0.8, 0)
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.3, size),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.Color = ColorSequence.new(color, Color3.new(1, 1, 1))
	emitter.LightEmission = 1
	emitter.Transparency = NumberSequence.new(0.1)
	emitter.Rotation = NumberRange.new(0, 360)
	emitter.RotSpeed = NumberRange.new(-90, 90)
	emitter.Parent = host
end

local function glow(host, color, brightness, range)
	local light = Instance.new("PointLight")
	light.Name = "SkinLight"
	light.Color = color
	light.Brightness = brightness
	light.Range = range
	light.Shadows = false
	light.Parent = host
end

function ItemSkin.apply(model, rarityId, mutationId, withEffects)
	local rarity = ItemCatalog.rarity(rarityId)
	if not rarity then
		return
	end
	local index = ItemCatalog.rarityIndex(rarityId)
	local mutation = mutationId and ItemCatalog.mutation(mutationId)
	local list = parts(model)
	local host = largest(list)
	for _, part in list do
		if part.Name == "Accent" and index > 1 then
			part.Color = rarity.color
		end
		if METAL_LABELS[part.Name] then
			if index >= 3 then
				part.Reflectance = 0.08 + 0.02 * index
			end
			if index >= 6 and part.Name ~= "Silver" then
				part.Material = Enum.Material.Neon
			end
		end
	end
	if mutation then
		for _, part in list do
			if mutation.id == "gilded" then
				if METAL_LABELS[part.Name] then
					part.Color = GILD
					part.Reflectance = 0.3
				end
			elseif mutation.id == "radiant" then
				if part.Name ~= "Glow" then
					part.Color = part.Color:Lerp(Color3.new(1, 1, 1), 0.35)
				end
				if part.Name == "Accent" then
					part.Material = Enum.Material.Neon
				end
			elseif mutation.id == "ancient" then
				if part.Name == "Accent" then
					part.Color = mutation.color
				elseif METAL_LABELS[part.Name] then
					part.Color = BRONZE
					part.Reflectance = 0.05
				end
			end
		end
	end
	if not withEffects or not host then
		return
	end
	if index >= 4 then
		glow(host, rarity.color, 0.5 + 0.1 * index, 6 + index)
	end
	if index >= 5 then
		sparkle(host, rarity.color, index * 2, 0.35)
	end
	if mutation then
		sparkle(host, mutation.color, 7, 0.4)
		glow(host, mutation.color, 1.1, 9)
	end
end

return ItemSkin
