local core = script.Parent.Parent
local Config = require(core.Config)
local Fx = require(core.Fx)

local Beacon = {
	name = "Beacon",
	order = 40,
}

function Beacon.build(context)
	local tier = math.clamp(tonumber(context.player:GetAttribute("Tier")) or 1, 1, 7)
	local frame, size = context.model:GetBoundingBox()
	local base = Vector3.new(frame.Position.X, frame.Position.Y + size.Y / 2, frame.Position.Z)
	local height = 70 + tier * 24
	local thickness = 0.8 + tier * 0.15
	context.beacon = Fx.beacon(base, height, Config.TIER_COLORS[tier], thickness)
end

function Beacon.destroy(context)
	if context.beacon then
		context.beacon:Destroy()
		context.beacon = nil
	end
end

return Beacon
