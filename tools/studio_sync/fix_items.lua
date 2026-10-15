local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local NAMES = { "torah", "ark", "siddur", "menorah", "kiddush_cup", "chandelier", "ornament", "holiday_decor" }
local PIVOT = { chandelier = "top", holiday_decor = "top", ornament = "center" }
local CM_TO_STUDS = 0.01

local function parseName(name)
	local label, hex = string.match(name, "^(.-)__(%x%x%x%x%x%x)%.?%d*$")
	if label then
		return label, hex
	end
	return name, nil
end

local function colorFromHex(hex)
	return Color3.fromRGB(tonumber(string.sub(hex, 1, 2), 16), tonumber(string.sub(hex, 3, 4), 16), tonumber(string.sub(hex, 5, 6), 16))
end

local modelsRoot = ReplicatedStorage:FindFirstChild("Models") or Instance.new("Folder")
modelsRoot.Name = "Models"
modelsRoot.Parent = ReplicatedStorage
local coreFolder = modelsRoot:FindFirstChild("core") or Instance.new("Folder")
coreFolder.Name = "core"
coreFolder.Parent = modelsRoot

local report = {}

for _, name in NAMES do
	local model = Workspace:FindFirstChild(name)
	if not model then
		report[name] = "NOT FOUND"
	else
		local colored = 0
		for _, part in model:GetDescendants() do
			if part:IsA("BasePart") then
				local label, hex = parseName(part.Name)
				if hex then
					part.Color = colorFromHex(hex)
					part.Name = label
					colored += 1
				end
				part.Anchored = true
				part.CanCollide = false
				part.CanTouch = false
				part.CanQuery = false
				part.Material = Enum.Material.SmoothPlastic
				if part.Name == "Glow" then
					part.Material = Enum.Material.Neon
					part.CastShadow = false
				end
			end
		end
		model.PrimaryPart = nil
		model:ScaleTo(model:GetScale() * CM_TO_STUDS)
		model.WorldPivot = CFrame.new(model:GetPivot().Position)
		local cf, size = model:GetBoundingBox()
		local mode = PIVOT[name] or "bottom"
		local offset = 0
		if mode == "bottom" then
			offset = -size.Y / 2
		elseif mode == "top" then
			offset = size.Y / 2
		end
		model.WorldPivot = CFrame.new(cf.Position + Vector3.new(0, offset, 0))
		local existing = coreFolder:FindFirstChild(name)
		if existing then
			existing:Destroy()
		end
		model.Parent = coreFolder
		report[name] = string.format("colored=%d size=%s pivot=%s", colored, tostring(size), mode)
	end
end

return report
