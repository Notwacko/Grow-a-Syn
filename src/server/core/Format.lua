local Format = {}

local SUFFIXES = { "", "K", "M", "B", "T", "Qa" }

function Format.short(value)
	if type(value) ~= "number" or value ~= value then
		return "0"
	end
	if value < 1000 then
		return tostring(math.floor(value))
	end
	local index = math.min(math.floor(math.log10(value) / 3), #SUFFIXES - 1)
	local scaled = value / (10 ^ (index * 3))
	local pattern = "%.2f"
	if scaled >= 100 then
		pattern = "%.0f"
	elseif scaled >= 10 then
		pattern = "%.1f"
	end
	local text = string.format(pattern, scaled)
	if string.find(text, ".", 1, true) then
		text = string.gsub(text, "0+$", "")
		text = string.gsub(text, "%.$", "")
	end
	return text .. SUFFIXES[index + 1]
end

return Format
