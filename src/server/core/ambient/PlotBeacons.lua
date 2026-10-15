local Workspace = game:GetService("Workspace")

local core = script.Parent.Parent
local Fx = require(core.Fx)

local PlotBeacons = {
	name = "PlotBeacons",
	order = 20,
}

local FREE_COLOR = Color3.fromRGB(255, 214, 80)
local HEIGHT = 120

local function watch(plot)
	local pad = plot:FindFirstChild("ClaimPad")
	if not pad then
		return
	end
	local beacon
	local function sync()
		local free = (plot:GetAttribute("OwnerUserId") or 0) == 0
		if free and not beacon then
			local base = pad.Position + Vector3.new(0, pad.Size.Y / 2, 0)
			beacon = Fx.beacon(base, HEIGHT, FREE_COLOR, 1)
		elseif not free and beacon then
			beacon:Destroy()
			beacon = nil
		end
	end
	plot:GetAttributeChangedSignal("OwnerUserId"):Connect(sync)
	sync()
end

function PlotBeacons.build()
	Fx.beaconFolder():ClearAllChildren()
	local plots = Workspace:FindFirstChild("Plots")
	if not plots then
		return
	end
	for _, plot in plots:GetChildren() do
		watch(plot)
	end
end

return PlotBeacons
