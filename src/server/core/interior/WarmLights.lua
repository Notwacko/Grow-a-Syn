local core = script.Parent.Parent
local UpgradeService = require(core.UpgradeService)

local WarmLights = {
	name = "WarmLights",
	order = 30,
}

local WARM = Color3.fromRGB(255, 214, 150)
local BASE_BRIGHTNESS = 1.4

local function totalLevels(player)
	local total = 0
	for _, level in UpgradeService.levelsOf(player) do
		total += level
	end
	return total
end

local function tune(context)
	local folder = context.warmLights
	if not folder then
		return
	end
	local brightness = BASE_BRIGHTNESS + totalLevels(context.player) * 0.08
	for _, part in folder:GetChildren() do
		local light = part:FindFirstChildOfClass("PointLight")
		if light then
			light.Brightness = brightness
		end
	end
end

function WarmLights.build(context)
	local bounds = context.interiorBounds
	if not bounds then
		return
	end
	local info = context.info
	local frame = info.floor.CFrame
	local walkLocal = info.floorTopY - frame.Position.Y
	local depth = bounds.zBack - bounds.zFront
	local width = bounds.maxX - bounds.minX
	local count = math.clamp(math.floor(depth / 24) + 1, 2, 5)
	local folder = Instance.new("Folder")
	folder.Name = "WarmLights"
	folder.Parent = context.folder
	for index = 1, count do
		local z = bounds.zFront + depth * (index - 0.5) / count
		local part = Instance.new("Part")
		part.Name = "Lamp" .. index
		part.Size = Vector3.one * 0.4
		part.Transparency = 1
		part.Anchored = true
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.CastShadow = false
		part.CFrame = frame * CFrame.new((bounds.minX + bounds.maxX) / 2, walkLocal + 9, z)
		part.Parent = folder
		local light = Instance.new("PointLight")
		light.Color = WARM
		light.Range = math.clamp(width * 0.6, 24, 44)
		light.Shadows = false
		light.Parent = part
	end
	context.warmLights = folder
	tune(context)
end

function WarmLights.onUpgradeChanged(context)
	tune(context)
end

return WarmLights
