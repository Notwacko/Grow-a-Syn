local RunService = game:GetService("RunService")

local Link = {}

function Link.folder(service, folderName)
	local f = service:FindFirstChild(folderName)
	if f then
		return f
	end
	if RunService:IsServer() then
		f = Instance.new("Folder")
		f.Name = folderName
		f.Parent = service
		return f
	end
	return service:WaitForChild(folderName, 10)
end

function Link.get(service, folderName, name, className)
	local f = Link.folder(service, folderName)
	if not f then
		return nil
	end
	local existing = f:FindFirstChild(name)
	if existing then
		return existing
	end
	if RunService:IsServer() then
		local obj = Instance.new(className)
		obj.Name = name
		obj.Parent = f
		return obj
	end
	return f:WaitForChild(name, 10)
end

return Link
