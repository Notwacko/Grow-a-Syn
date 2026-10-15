local Players = game:GetService("Players")

local core = script.Parent.Parent
local Config = require(core.Config)
local Fx = require(core.Fx)

local Celebrate = {
	name = "Celebrate",
	order = 50,
}

local lastTier = {}

Players.PlayerRemoving:Connect(function(player)
	lastTier[player] = nil
end)

function Celebrate.build(context)
	local player = context.player
	local tier = math.clamp(tonumber(player:GetAttribute("Tier")) or 1, 1, 7)
	local previous = lastTier[player]
	lastTier[player] = tier
	if not previous or tier <= previous then
		return
	end
	local info = context.info
	local color = Config.TIER_COLORS[tier]
	local door = info.door.Position
	local front = Vector3.new(door.X, 1, door.Z) + info.floor.CFrame.LookVector * 30
	local center = info.floor.Position
	task.delay(0.6, function()
		if not context.folder.Parent then
			return
		end
		Fx.confetti(center + Vector3.new(0, 14, 0), 2)
		Fx.ring(Vector3.new(center.X, info.floorTopY + 0.5, center.Z), color, 70)
		Fx.floatText(front + Vector3.new(0, 18, 0), "TIER " .. tier .. "!", color)
		Fx.sound(front, Config.SOUNDS.victory, 0.9, 1)
		Fx.fireworkShow(front, 5 + tier * 2, 50)
	end)
end

return Celebrate
