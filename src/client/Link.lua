-- Client side of the contract Link: wait for a shared folder/object that the server creates.
local Link = {}

function Link.folder(service, folderName)
	return service:FindFirstChild(folderName) or service:WaitForChild(folderName, 10)
end

function Link.get(service, folderName, name, className)
	local folder = Link.folder(service, folderName)
	if not folder then
		return nil
	end
	local found = folder:FindFirstChild(name) or folder:WaitForChild(name, 10)
	if found and className and not found:IsA(className) then
		return nil
	end
	return found
end

return Link
