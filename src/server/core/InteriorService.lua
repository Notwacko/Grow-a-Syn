local StarterPlayer = game:GetService("StarterPlayer")

local InteriorService = {}

local modules = {}
local contexts = {}

local function run(module, hook, ...)
	local callback = module[hook]
	if type(callback) ~= "function" then
		return
	end
	local ok, err = pcall(callback, ...)
	if not ok then
		warn(string.format("[Interior] %s.%s failed: %s", tostring(module.name), hook, tostring(err)))
	end
end

function InteriorService.start()
	local folder = script.Parent:WaitForChild("interior")
	for _, child in folder:GetChildren() do
		if child:IsA("ModuleScript") then
			local ok, module = pcall(require, child)
			if ok and type(module) == "table" then
				module.name = module.name or child.Name
				table.insert(modules, module)
			else
				warn("[Interior] could not load " .. child.Name .. ": " .. tostring(module))
			end
		end
	end
	table.sort(modules, function(a, b)
		return (a.order or 100) < (b.order or 100)
	end)
	StarterPlayer.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Invisicam
	StarterPlayer.CameraMaxZoomDistance = 350
end

function InteriorService.names()
	local names = {}
	for _, module in modules do
		table.insert(names, module.name)
	end
	return names
end

function InteriorService.clear(player)
	local context = contexts[player]
	contexts[player] = nil
	if not context then
		return
	end
	for _, module in modules do
		run(module, "destroy", context)
	end
	if context.folder and context.folder.Parent then
		context.folder:Destroy()
	end
end

function InteriorService.onSwapped(player, plot, info)
	InteriorService.clear(player)
	local folder = Instance.new("Folder")
	folder.Name = "Interior"
	folder.Parent = info.model
	local context = { player = player, plot = plot, info = info, model = info.model, folder = folder }
	contexts[player] = context
	for _, module in modules do
		run(module, "build", context)
	end
end

function InteriorService.onUpgradeChanged(player, id, level)
	local context = contexts[player]
	if not context then
		return
	end
	for _, module in modules do
		run(module, "onUpgradeChanged", context, id, level)
	end
end

function InteriorService.getContext(player)
	return contexts[player]
end

return InteriorService
