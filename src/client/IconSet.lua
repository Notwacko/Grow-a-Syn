-- Icon asset ids from the shared Icons module (owned by the lead). Falls back to {} when it is absent (mock mode, older builds).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ok, icons = pcall(function()
	local shared = ReplicatedStorage:WaitForChild("Shared", 2)
	local module = shared and shared:WaitForChild("Icons", 2)
	return module and require(module)
end)

return ok and type(icons) == "table" and icons or {}
