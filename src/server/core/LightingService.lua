local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local LightingService = {}

local function ensure(parent, className, name)
	local existing = parent:FindFirstChildOfClass(className)
	if existing then
		return existing
	end
	local instance = Instance.new(className)
	instance.Name = name
	instance.Parent = parent
	return instance
end

function LightingService.start()
	Lighting.ClockTime = 15
	Lighting.GeographicLatitude = 25
	Lighting.Brightness = 2.4
	Lighting.Ambient = Color3.fromRGB(98, 108, 136)
	Lighting.OutdoorAmbient = Color3.fromRGB(124, 136, 162)
	Lighting.ColorShift_Top = Color3.fromRGB(255, 240, 214)
	Lighting.EnvironmentDiffuseScale = 0.5
	Lighting.EnvironmentSpecularScale = 0.3
	Lighting.ExposureCompensation = -0.2
	Lighting.GlobalShadows = true
	Lighting.ShadowSoftness = 0.35
	Lighting.FogEnd = 100000
	Lighting.FogStart = 0

	local atmosphere = ensure(Lighting, "Atmosphere", "Atmosphere")
	atmosphere.Density = 0.22
	atmosphere.Offset = 0.15
	atmosphere.Color = Color3.fromRGB(199, 224, 255)
	atmosphere.Decay = Color3.fromRGB(120, 180, 255)
	atmosphere.Glare = 0.1
	atmosphere.Haze = 0.9

	local bloom = ensure(Lighting, "BloomEffect", "Bloom")
	bloom.Intensity = 0.2
	bloom.Size = 18
	bloom.Threshold = 1.5

	local color = ensure(Lighting, "ColorCorrectionEffect", "ColorCorrection")
	color.Brightness = 0
	color.Contrast = 0.12
	color.Saturation = 0.18
	color.TintColor = Color3.fromRGB(255, 250, 244)

	local rays = ensure(Lighting, "SunRaysEffect", "SunRays")
	rays.Intensity = 0.04
	rays.Spread = 0.6

	local sky = ensure(Lighting, "Sky", "Sky")
	sky.StarCount = 0
	sky.SunAngularSize = 18
	sky.MoonAngularSize = 8

	local clouds = ensure(Workspace.Terrain, "Clouds", "Clouds")
	clouds.Cover = 0.55
	clouds.Density = 0.45
	clouds.Color = Color3.fromRGB(255, 255, 255)
end

return LightingService
