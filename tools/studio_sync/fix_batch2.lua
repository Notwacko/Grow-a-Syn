local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local CM_TO_STUDS = 0.01

local PROPS = { "fountain", "tree", "tree2", "tree3", "bush", "rock", "bench", "lamp", "fence", "flowers", "sign", "gate_pillar", "padring", "balloon", "flag", "spawnpad", "plaza" }
local STATIONS = { "welcome", "kiddush", "desk", "mirror" }
local OUTFIT = {
	"kippah", "kippah_knit", "hat_fedora", "hat_wide", "hat_modest", "shtreimel", "tichel", "beard", "peyot", "jacket_closed",
	"jacket_open", "tie", "coat_long", "gartel", "tzitzit", "socks", "skirt_long", "tallit",
}
local MARKERS = { Origin = true, SprayAnchor = true, Top = true, CrownSpot = true, Pip1 = true, Pip2 = true, Pip3 = true, Pip4 = true, Pip5 = true }

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
		if string.sub(label, 1, 4) == "Glow" or string.find(label, ".Glow", 1, true) then
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

local function bottomPivot(model)
	model.PrimaryPart = nil
	local cf, size = model:GetBoundingBox()
	model.WorldPivot = CFrame.new(cf.Position - Vector3.new(0, size.Y / 2, 0))
	return size
end

local function file(model, name)
	local existing = coreFolder:FindFirstChild(name)
	if existing then
		existing:Destroy()
	end
	model.Parent = coreFolder
end

for _, short in PROPS do
	local name = "prop_" .. short
	local model = Workspace:FindFirstChild(name)
	if model then
		local colored = colorize(model)
		model:ScaleTo(model:GetScale() * CM_TO_STUDS)
		local size = bottomPivot(model)
		file(model, name)
		report[name] = string.format("colored=%d size=%.1f,%.1f,%.1f", colored, size.X, size.Y, size.Z)
	end
end

for _, short in STATIONS do
	local name = "station_" .. short
	local model = Workspace:FindFirstChild(name)
	if model then
		local colored = colorize(model)
		model:ScaleTo(model:GetScale() * CM_TO_STUDS)
		local size = bottomPivot(model)
		file(model, name)
		report[name] = string.format("colored=%d size=%.1f,%.1f,%.1f", colored, size.X, size.Y, size.Z)
	end
end

for _, short in OUTFIT do
	local name = "ofit_" .. short
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
	end
end

return report
