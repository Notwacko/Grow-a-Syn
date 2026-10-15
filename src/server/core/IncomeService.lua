local Workspace = game:GetService("Workspace")

local Guard = require(script.Parent.Guard)

local IncomeService = {}

local factors = {}
local order = {}

function IncomeService.register(name, callback)
	if not factors[name] then
		table.insert(order, name)
	end
	factors[name] = callback
end

function IncomeService.compute(player)
	local total = 1
	local parts = {}
	for _, name in order do
		local ok, value = pcall(factors[name], player)
		if not ok or not Guard.isNumber(value) or value < 0 then
			value = 1
		end
		parts[name] = value
		total *= value
	end
	return total, parts
end

function IncomeService.refresh(player)
	if not Guard.isPlayer(player) or Workspace:GetAttribute("ProgressionOnline") == true then
		return
	end
	local total = IncomeService.compute(player)
	total = math.clamp(total, 0, 1e12)
	local current = player:GetAttribute("IncomeMult")
	if type(current) ~= "number" or math.abs(current - total) > math.max(1e-6, total * 1e-6) then
		player:SetAttribute("IncomeMult", total)
	end
end

function IncomeService.breakdown(player)
	local total, parts = IncomeService.compute(player)
	return total, parts
end

return IncomeService
