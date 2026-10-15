local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local Config = require(script.Parent.Config)
local Notify = require(script.Parent.Notify)
local Economy = require(script.Parent.Economy)
local Signal = require(script.Parent.Signal)

local EventService = {}

EventService.Started = Signal.new()
EventService.Ended = Signal.new()

local running = false
local token = 0

local EVENT = {
	name = "Shabbat Shalom",
	mult = 2,
	clock = 17.3,
	tint = Color3.fromRGB(255, 226, 190),
	ambient = Color3.fromRGB(150, 128, 120),
}

local function announce(text)
	for _, player in Players:GetPlayers() do
		if (player:GetAttribute("PlotId") or 0) > 0 then
			Notify.send(player, "success", text)
		end
	end
end

local function tween(instance, seconds, props)
	TweenService:Create(instance, TweenInfo.new(seconds, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), props):Play()
end

local function correction()
	return Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
end

function EventService.isRunning()
	return running
end

function EventService.trigger(duration)
	if running then
		return false
	end
	running = true
	token += 1
	local mine = token
	duration = duration or Config.EVENT_DURATION
	local savedClock = Lighting.ClockTime
	local savedAmbient = Lighting.OutdoorAmbient
	local effect = correction()
	local savedTint = effect and effect.TintColor or Color3.new(1, 1, 1)
	Economy.setEventMult(EVENT.mult)
	Workspace:SetAttribute("EventName", EVENT.name)
	Workspace:SetAttribute("EventEndsAt", os.time() + duration)
	tween(Lighting, 6, { ClockTime = EVENT.clock, OutdoorAmbient = EVENT.ambient })
	if effect then
		tween(effect, 6, { TintColor = EVENT.tint })
	end
	announce(EVENT.name .. "! Everyone earns x" .. EVENT.mult .. " for " .. math.floor(duration / 60 + 0.5) .. " minutes")
	EventService.Started:Fire(EVENT.name)
	task.delay(duration, function()
		if token ~= mine then
			return
		end
		Economy.setEventMult(1)
		Workspace:SetAttribute("EventName", "")
		Workspace:SetAttribute("EventEndsAt", 0)
		tween(Lighting, 6, { ClockTime = savedClock, OutdoorAmbient = savedAmbient })
		if effect then
			tween(effect, 6, { TintColor = savedTint })
		end
		announce("Shabbat is over. See you next time!")
		running = false
		EventService.Ended:Fire(EVENT.name)
	end)
	return true
end

function EventService.start()
	Workspace:SetAttribute("EventName", "")
	Workspace:SetAttribute("EventEndsAt", 0)
	task.spawn(function()
		task.wait(Config.EVENT_FIRST_DELAY)
		while true do
			if #Players:GetPlayers() > 0 then
				EventService.trigger(Config.EVENT_DURATION)
			end
			task.wait(Config.EVENT_INTERVAL)
		end
	end)
end

return EventService
