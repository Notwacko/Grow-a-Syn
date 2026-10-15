-- Seth: fill in the SoundIds ("rbxassetid://123"). Empty means silent.
local SoundService = game:GetService("SoundService")

local Sound = {}

Sound.IDS = {
	click = "",
	buy = "",
	merge = "",
	greet = "",
	minyan = "",
	tier = "",
	error = "",
}

local cache = {}

function Sound.play(name)
	local id = Sound.IDS[name]
	if not id or id == "" then
		return
	end
	local sound = cache[name]
	if not sound then
		sound = Instance.new("Sound")
		sound.Name = "UI_" .. name
		sound.SoundId = id
		sound.Volume = 0.6
		sound.Parent = SoundService
		cache[name] = sound
	end
	sound.TimePosition = 0
	sound:Play()
end

return Sound
