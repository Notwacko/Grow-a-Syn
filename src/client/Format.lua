local Format = {}

local SUFFIXES = { "", "K", "M", "B", "T", "Qa" }

function Format.short(n)
	n = tonumber(n) or 0
	local sign = n < 0 and "-" or ""
	n = math.abs(n)
	if n < 1000 then
		return sign .. tostring(math.floor(n))
	end
	local i = 1
	while n >= 1000 and i < #SUFFIXES do
		n /= 1000
		i += 1
	end
	local v = math.floor(n * 10) / 10
	local text = v == math.floor(v) and tostring(math.floor(v)) or string.format("%.1f", v)
	return sign .. text .. SUFFIXES[i]
end

function Format.clock(seconds)
	seconds = math.max(0, math.floor(seconds))
	return string.format("%d:%02d", seconds // 60, seconds % 60)
end

function Format.duration(seconds)
	seconds = math.floor(seconds or 0)
	if seconds >= 3600 then
		return (seconds // 3600) .. " hr"
	end
	return math.max(1, seconds // 60) .. " min"
end

return Format
