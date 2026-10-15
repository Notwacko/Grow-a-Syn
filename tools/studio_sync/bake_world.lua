local ServerScriptService = game:GetService("ServerScriptService")

local core = ServerScriptService.Server.core

local steps = {
	{ "LightingService", "start" },
	{ "WorldService", "build" },
	{ "PlotService", "build" },
}

local report = {}

for _, step in steps do
	local ok, err = pcall(function()
		require(core[step[1]])[step[2]]()
	end)
	table.insert(report, step[1] .. (ok and " ok" or (" FAILED " .. tostring(err))))
end

for _, name in { "Meadow", "Motes", "PlotBeacons", "Balloons", "Shuk" } do
	local ok, err = pcall(function()
		require(core.ambient[name]).build()
	end)
	table.insert(report, name .. (ok and " ok" or (" FAILED " .. tostring(err))))
end

return report
