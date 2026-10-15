local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")

local BASE = "http://127.0.0.1:8765/"
local previousHttp = HttpService.HttpEnabled
HttpService.HttpEnabled = true

local function fetch(path)
	return HttpService:GetAsync(BASE .. path, true)
end
local function split(text, separator)
	local parts = {}
	for part in string.gmatch(text, "[^" .. separator .. "]+") do
		table.insert(parts, part)
	end
	return parts
end
local function lines(text)
	local out = {}
	for line in string.gmatch(text, "[^\r\n]+") do
		table.insert(out, line)
	end
	return out
end
local function ensureFolder(parent, name)
	local existing = parent:FindFirstChild(name)
	if existing then
		return existing
	end
	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = parent
	return folder
end
local function rootFor(top)
	if top == "shared" then
		return ensureFolder(ReplicatedStorage, "Shared")
	elseif top == "server" then
		return ensureFolder(ServerScriptService, "Server")
	elseif top == "client" then
		return ensureFolder(StarterPlayer:WaitForChild("StarterPlayerScripts"), "Client")
	end
	return nil
end
local function classFor(fileName)
	if string.sub(fileName, -11) == ".server.lua" then
		return "Script", string.sub(fileName, 1, -12)
	elseif string.sub(fileName, -11) == ".client.lua" then
		return "LocalScript", string.sub(fileName, 1, -12)
	elseif string.sub(fileName, -4) == ".lua" then
		return "ModuleScript", string.sub(fileName, 1, -5)
	end
	return nil, nil
end

local created, changed = {}, {}
local ok, err = pcall(function()
	for _, filePath in lines(fetch("manifest.txt")) do
		local parts = split(filePath, "/")
		local className, name = classFor(parts[#parts])
		local container = className and rootFor(parts[2])
		if container then
			for index = 3, #parts - 1 do
				container = ensureFolder(container, parts[index])
			end
			local source = fetch(filePath)
			local existing = container:FindFirstChild(name)
			if existing and existing.ClassName ~= className then
				existing:Destroy()
				existing = nil
			end
			if existing then
				if existing.Source ~= source then
					existing.Source = source
					table.insert(changed, name)
				end
			else
				local script = Instance.new(className)
				script.Name = name
				script.Source = source
				script.Parent = container
				table.insert(created, name)
			end
		end
	end
end)
HttpService.HttpEnabled = previousHttp
return { ok = ok, error = ok and nil or tostring(err), created = created, changed = changed }
