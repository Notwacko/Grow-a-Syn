local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local CM_TO_STUDS = 0.01

local OUTFIT = {
	"ofit_tallit_royal", "ofit_tallit_gold", "ofit_tallit_rainbow", "ofit_tallit_stone", "ofit_tallit_stars",
	"ofit_kippah_rainbowknit", "ofit_kippah_goldvelvet", "ofit_kippah_starry", "ofit_kippah_stripes", "ofit_kippah_emerald", "ofit_kippah_purple",
	"ofit_cape_royal", "ofit_cape_gold", "ofit_cape_starry", "ofit_wings_dove", "ofit_wings_gold",
	"ofit_pack_satchel", "ofit_pack_challah", "ofit_pack_candles",
	"ofit_hat_flowers", "ofit_hat_crown", "ofit_hat_sunhat", "ofit_glasses_gold", "ofit_bowtie_blue",
	"ofit_hair_short", "ofit_hair_long", "ofit_hair_bun", "ofit_hair_curly", "ofit_hair_pony",
}
local PETS = { "pet_cat", "pet_lamb", "pet_puppy", "pet_dove", "pet_fox", "pet_hedgehog", "pet_lion_cub", "pet_peacock" }
local MARKERS = { Origin = true }

local function parseName(name)
	local label, hex = string.match(name, "^(.-)__(%x%x%x%x%x%x)%.?%d*$")
	if label then
		return label, hex
	end
	return string.match(name, "^(.-)%.%d+$") or name, nil
end

local function colorFromHex(hex)
	return Color3.fromRGB(tonumber(string.sub(hex, 1, 2), 16), tonumber(string.sub(hex, 3, 4), 16), tonumber(string.sub(hex, 5, 6), 16))
end

local coreFolder = ReplicatedStorage.Models.core
local report = {}

local function parts(model)
	local list = {}
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			table.insert(list, d)
		end
	end
	return list
end

local function colorize(model)
	local count = 0
	for _, part in parts(model) do
		local label, hex = parseName(part.Name)
		if hex then
			part.Color = colorFromHex(hex)
			count += 1
		end
		part.Name = label
		part.Anchored = true
		part.CanCollide = false
		part.CanTouch = false
		part.CanQuery = false
		part.Material = Enum.Material.SmoothPlastic
		if string.find(label, "Glow", 1, true) then
			part.Material = Enum.Material.Neon
			part.CastShadow = false
		end
		if MARKERS[label] then
			part.Transparency = 1
			part.CastShadow = false
		end
	end
	return count
end

local function file(model, name)
	local existing = coreFolder:FindFirstChild(name)
	if existing then
		existing:Destroy()
	end
	model.Parent = coreFolder
end

for _, name in OUTFIT do
	local model = Workspace:FindFirstChild(name)
	if model then
		local colored = colorize(model)
		model:ScaleTo(model:GetScale() * CM_TO_STUDS)
		local origin = model:FindFirstChild("Origin", true)
		if origin then
			local count = 0
			for _, part in parts(model) do
				if part ~= origin and not MARKERS[part.Name] then
					local body, suffix = string.match(part.Name, "^([^.]+)%.(.+)$")
					if body then
						part:SetAttribute("Body", body)
						part:SetAttribute("Key", suffix)
						part:SetAttribute("Offset", origin.CFrame:PointToObjectSpace(part.Position))
						count += 1
					else
						part:Destroy()
					end
				end
			end
			model.WorldPivot = origin.CFrame
			origin:Destroy()
			report[name] = string.format("colored=%d attached=%d", colored, count)
		else
			report[name] = "NO ORIGIN"
		end
		file(model, name)
	else
		report[name] = "NOT IMPORTED"
	end
end

for _, name in PETS do
	local model = Workspace:FindFirstChild(name)
	if model then
		local colored = colorize(model)
		model:ScaleTo(model:GetScale() * CM_TO_STUDS)
		model.PrimaryPart = nil
		local cf, size = model:GetBoundingBox()
		model.WorldPivot = CFrame.new(cf.Position - Vector3.new(0, size.Y / 2, 0))
		model:SetAttribute("PetHeight", size.Y)
		file(model, name)
		report[name] = string.format("colored=%d size=%.2f,%.2f,%.2f", colored, size.X, size.Y, size.Z)
	else
		report[name] = "NOT IMPORTED"
	end
end

return report
