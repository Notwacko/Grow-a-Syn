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
	Lighting.ClockTime = 14
	Lighting.GeographicLatitude = 25
	Lighting.Brightness = 3
	Lighting.Ambient = Color3.fromRGB(140, 150, 176)
	Lighting.OutdoorAmbient = Color3.fromRGB(165, 175, 196)
	Lighting.ColorShift_Top = Color3.fromRGB(255, 244, 214)
	Lighting.EnvironmentDiffuseScale = 0.6
	Lighting.EnvironmentSpecularScale = 0.4
	Lighting.ExposureCompensation = 0.1
	Lighting.GlobalShadows = true
	Lighting.ShadowSoftness = 0.25
	Lighting.FogEnd = 100000
	Lighting.FogStart = 0

	local atmosphere = ensure(Lighting, "Atmosphere", "Atmosphere")
	atmosphere.Density = 0.28
	atmosphere.Offset = 0.2
	atmosphere.Color = Color3.fromRGB(199, 224, 255)
	atmosphere.Decay = Color3.fromRGB(120, 180, 255)
	atmosphere.Glare = 0.2
	atmosphere.Haze = 1.4

	local bloom = ensure(Lighting, "BloomEffect", "Bloom")
	bloom.Intensity = 0.4
	bloom.Size = 28
	bloom.Threshold = 1

	local color = ensure(Lighting, "ColorCorrectionEffect", "ColorCorrection")
	color.Brightness = 0.03
	color.Contrast = 0.15
	color.Saturation = 0.28
	color.TintColor = Color3.fromRGB(255, 250, 242)

	local rays = ensure(Lighting, "SunRaysEffect", "SunRays")
	rays.Intensity = 0.08
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
