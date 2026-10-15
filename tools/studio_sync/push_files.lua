local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local FILES = {
	{ "src/server/core/interior/Items.lua", ServerScriptService.Server.core.interior },
}

local previous = HttpService.HttpEnabled
HttpService.HttpEnabled = true
local report = {}
for _, file in FILES do
	local name = string.match(file[1], "([^/]+)%.lua$")
	local ok, source = pcall(HttpService.GetAsync, HttpService, "http://127.0.0.1:8765/" .. file[1], true)
	local target = file[2]:FindFirstChild(name)
	if ok and target then
		target.Source = source
		table.insert(report, name .. " updated")
	else
		table.insert(report, name .. " FAILED " .. tostring(source))
	end
end
HttpService.HttpEnabled = previous
return report
