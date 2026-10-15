local AmbientService = {}

local modules = {}

local function run(module, hook, ...)
	local callback = module[hook]
	if type(callback) ~= "function" then
		return
	end
	local ok, err = pcall(callback, ...)
	if not ok then
		warn(string.format("[Ambient] %s.%s failed: %s", tostring(module.name), hook, tostring(err)))
	end
end

function AmbientService.start()
	local folder = script.Parent:WaitForChild("ambient")
	for _, child in folder:GetChildren() do
		if child:IsA("ModuleScript") then
			local ok, module = pcall(require, child)
			if ok and type(module) == "table" then
				module.name = module.name or child.Name
				table.insert(modules, module)
			else
				warn("[Ambient] could not load " .. child.Name .. ": " .. tostring(module))
			end
		end
	end
	table.sort(modules, function(a, b)
		return (a.order or 100) < (b.order or 100)
	end)
	for _, module in modules do
		run(module, "build")
	end
end

function AmbientService.names()
	local names = {}
	for _, module in modules do
		table.insert(names, module.name)
	end
	return names
end

return AmbientService
