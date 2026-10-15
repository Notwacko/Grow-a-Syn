local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local core = script.Parent.Parent
local Notify = require(core.Notify)
local Catalog = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GardenCatalog"))

local Weather = {}

local rng = Random.new()
local current = Catalog.weatherEntry("clear")
local rainParts = {}
local base
local started = false

function Weather.current()
	return current
end

function Weather.speed()
	return current.speed or 1
end

local function captureBase()
	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	local bloom = Lighting:FindFirstChildOfClass("BloomEffect")
	local rays = Lighting:FindFirstChildOfClass("SunRaysEffect")
	local clouds = Workspace.Terrain:FindFirstChildOfClass("Clouds")
	base = {
		brightness = Lighting.Brightness,
		ambient = Lighting.Ambient,
		outdoor = Lighting.OutdoorAmbient,
		colorShift = Lighting.ColorShift_Top,
		density = atmosphere and atmosphere.Density or 0.22,
		bloom = bloom and bloom.Intensity or 0.2,
		rays = rays and rays.Intensity or 0.04,
		cover = clouds and clouds.Cover or 0.55,
	}
end

local function tweenLook(target)
	local info = TweenInfo.new(4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
	TweenService:Create(Lighting, info, {
		Brightness = target.brightness,
		Ambient = target.ambient,
		OutdoorAmbient = target.outdoor,
		ColorShift_Top = target.colorShift,
	}):Play()
	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	if atmosphere then
		TweenService:Create(atmosphere, info, { Density = target.density }):Play()
	end
	local bloom = Lighting:FindFirstChildOfClass("BloomEffect")
	if bloom then
		TweenService:Create(bloom, info, { Intensity = target.bloom }):Play()
	end
	local rays = Lighting:FindFirstChildOfClass("SunRaysEffect")
	if rays then
		TweenService:Create(rays, info, { Intensity = target.rays }):Play()
	end
	local clouds = Workspace.Terrain:FindFirstChildOfClass("Clouds")
	if clouds then
		TweenService:Create(clouds, info, { Cover = target.cover }):Play()
	end
end

local function lookFor(entry)
	if not base then
		return nil
	end
	if entry.id == "rain" then
		return {
			brightness = base.brightness * 0.62,
			ambient = Color3.fromRGB(72, 84, 112),
			outdoor = Color3.fromRGB(92, 106, 134),
			colorShift = Color3.fromRGB(210, 222, 245),
			density = 0.4,
			bloom = base.bloom,
			rays = 0,
			cover = 0.95,
		}
	elseif entry.id == "sunny" then
		return {
			brightness = base.brightness * 1.18,
			ambient = base.ambient,
			outdoor = base.outdoor,
			colorShift = Color3.fromRGB(255, 226, 170),
			density = base.density,
			bloom = base.bloom + 0.18,
			rays = 0.14,
			cover = 0.3,
		}
	end
	return {
		brightness = base.brightness,
		ambient = base.ambient,
		outdoor = base.outdoor,
		colorShift = base.colorShift,
		density = base.density,
		bloom = base.bloom,
		rays = base.rays,
		cover = base.cover,
	}
end

local function removeRain(player)
	local part = rainParts[player]
	if part then
		part:Destroy()
		rainParts[player] = nil
	end
end

local function attachRain(player)
	removeRain(player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or current.id ~= "rain" then
		return
	end
	local part = Instance.new("Part")
	part.Name = "RainCloud"
	part.Size = Vector3.new(60, 1, 60)
	part.Transparency = 1
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Massless = true
	part.CFrame = root.CFrame * CFrame.new(0, 40, 0)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = part
	weld.Parent = part
	local emitter = Instance.new("ParticleEmitter")
	emitter.Shape = Enum.ParticleEmitterShape.Box
	emitter.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
	emitter.EmissionDirection = Enum.NormalId.Bottom
	emitter.Rate = 340
	emitter.Lifetime = NumberRange.new(0.85, 1)
	emitter.Speed = NumberRange.new(56, 64)
	emitter.SpreadAngle = Vector2.new(2, 2)
	emitter.Orientation = Enum.ParticleOrientation.VelocityParallel
	emitter.Size = NumberSequence.new(0.4)
	emitter.Squash = NumberSequence.new(2)
	emitter.Color = ColorSequence.new(Color3.fromRGB(190, 220, 255))
	emitter.LightEmission = 0.3
	emitter.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 0.6) })
	emitter.Parent = part
	part.Parent = character
	rainParts[player] = part
end

local function announce(entry)
	local text
	if entry.id == "rain" then
		text = "It is raining! Plants grow faster and can turn Wet"
	elseif entry.id == "sunny" then
		text = "The sun is out! Plants grow faster and can turn Sunlit"
	else
		text = "The sky is clear again"
	end
	for _, player in Players:GetPlayers() do
		Notify.send(player, "info", text)
	end
end

local function setWeather(entry, duration)
	current = entry
	Workspace:SetAttribute("Weather", entry.id)
	Workspace:SetAttribute("WeatherEndsAt", duration and (Workspace:GetServerTimeNow() + duration) or 0)
	local look = lookFor(entry)
	if look then
		tweenLook(look)
	end
	for _, player in Players:GetPlayers() do
		if entry.id == "rain" then
			attachRain(player)
		else
			removeRain(player)
		end
	end
	announce(entry)
end

function Weather.trigger(id, duration)
	local entry = Catalog.weatherEntry(id)
	setWeather(entry, duration or (entry.duration and rng:NextInteger(entry.duration[1], entry.duration[2]) or nil))
end

function Weather.start()
	if started then
		return
	end
	started = true
	captureBase()
	Workspace:SetAttribute("Weather", "clear")
	Workspace:SetAttribute("WeatherEndsAt", 0)
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function()
			task.wait(1)
			attachRain(player)
		end)
	end)
	for _, player in Players:GetPlayers() do
		player.CharacterAdded:Connect(function()
			task.wait(1)
			attachRain(player)
		end)
	end
	Players.PlayerRemoving:Connect(removeRain)
	Workspace:GetAttributeChangedSignal("ForceWeather"):Connect(function()
		local id = Workspace:GetAttribute("ForceWeather")
		if type(id) == "string" and id ~= "" then
			Workspace:SetAttribute("ForceWeather", "")
			Weather.trigger(id, 60)
		end
	end)
	task.spawn(function()
		while true do
			task.wait(rng:NextInteger(Catalog.WEATHER_GAP[1], Catalog.WEATHER_GAP[2]))
			local entry = Catalog.pickWeather(rng)
			local duration = rng:NextInteger(entry.duration[1], entry.duration[2])
			setWeather(entry, duration)
			task.wait(duration)
			setWeather(Catalog.weatherEntry("clear"), nil)
		end
	end)
end

return Weather
