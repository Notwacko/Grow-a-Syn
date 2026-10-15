local Guard = require(script.Parent.Guard)
local PlayerState = require(script.Parent.PlayerState)

local SettingsService = {}

local KEYS = { sfx = true, colorblind = true, pets = true }

function SettingsService.snapshot(player)
	return table.clone(PlayerState.get(player, "settings", {}))
end

SettingsService.actions = {}

function SettingsService.actions.set(player, payload)
	local key = payload.key
	local value = payload.value
	if not Guard.isString(key, 16) or not KEYS[key] or type(value) ~= "boolean" then
		return { ok = false, reason = "invalid" }
	end
	local settings = table.clone(PlayerState.get(player, "settings", {}))
	settings[key] = value
	PlayerState.set(player, "settings", settings)
	return { ok = true }
end

return SettingsService
