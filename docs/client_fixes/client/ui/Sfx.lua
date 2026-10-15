local SoundService = game:GetService("SoundService")

local Sfx = {}

local IDS = {
	click = { "rbxasset://sounds/button.wav", 0.5, 1 },
	open = { "rbxasset://sounds/snap.mp3", 0.45, 1.1 },
	close = { "rbxasset://sounds/snap.mp3", 0.35, 0.85 },
	coin = { "rbxasset://sounds/kerplunk.wav", 0.5, 1.2 },
	buy = { "rbxasset://sounds/electronicpingshort.wav", 0.6, 1.1 },
	error = { "rbxasset://sounds/button.wav", 0.5, 0.6 },
	win = { "rbxasset://sounds/victory.wav", 0.6, 1 },
	pop = { "rbxasset://sounds/snap.mp3", 0.5, 1.3 },
	tick = { "rbxasset://sounds/button.wav", 0.25, 1.6 },
}

local muted = false
local group = Instance.new("SoundGroup")
group.Name = "GrowUiSfx"
group.Volume = 1
group.Parent = SoundService

function Sfx.setMuted(value)
	muted = value
end

function Sfx.isMuted()
	return muted
end

function Sfx.play(name, pitch)
	if muted then
		return
	end
	local entry = IDS[name] or IDS.click
	local sound = Instance.new("Sound")
	sound.SoundId = entry[1]
	sound.Volume = entry[2]
	sound.PlaybackSpeed = (pitch or 1) * entry[3]
	sound.SoundGroup = group
	sound.Parent = group
	sound.Ended:Connect(function()
		sound:Destroy()
	end)
	sound:Play()
	task.delay(4, function()
		if sound.Parent then
			sound:Destroy()
		end
	end)
end

return Sfx
