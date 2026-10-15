local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

for _, name in { "World", "Plots", "Meadow", "CoreMotes", "CoreBalloons", "CoreBeacons", "Shuk", "CoreFx" } do
	local old = Workspace:FindFirstChild(name)
	if old then
		old:Destroy()
	end
end

local server = ServerScriptService.Server
local stale = server:FindFirstChild("core_bake")
if stale then
	stale:Destroy()
end
local core = server.core:Clone()
core.Name = "core_bake"
core.Parent = server

local report = {}
for _, step in { { "LightingService", "start" }, { "WorldService", "build" }, { "PlotService", "build" } } do
	local ok, err = pcall(function()
		require(core[step[1]])[step[2]]()
	end)
	table.insert(report, step[1] .. (ok and " ok" or (" FAILED " .. tostring(err))))
end
for _, name in { "Meadow", "Motes", "PlotBeacons", "Balloons" } do
	local module = core.ambient:FindFirstChild(name)
	if module then
		local ok, err = pcall(function()
			require(module).build()
		end)
		table.insert(report, name .. (ok and " ok" or (" FAILED " .. tostring(err))))
	end
end
core:Destroy()
return report
