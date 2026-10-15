local TweenService = game:GetService("TweenService")

local Util = {}

local SUFFIXES = { "", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc" }

function Util.short(value)
	if type(value) ~= "number" or value ~= value then
		return "0"
	end
	if value < 1000 then
		return tostring(math.floor(value))
	end
	local index = math.min(math.floor(math.log10(value) / 3 + 1e-9), #SUFFIXES - 1)
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

function Util.mult(value)
	if type(value) ~= "number" or value ~= value then
		return "1"
	end
	if value >= 1000 then
		return Util.short(value)
	end
	local text = string.format(value >= 100 and "%.0f" or (value >= 10 and "%.1f" or "%.2f"), value)
	if string.find(text, ".", 1, true) then
		text = string.gsub(text, "0+$", "")
		text = string.gsub(text, "%.$", "")
	end
	return text
end

function Util.commas(value)
	local text = tostring(math.floor(value))
	local result = string.reverse(text)
	result = string.gsub(result, "(%d%d%d)", "%1,")
	result = string.reverse(result)
	return (string.gsub(result, "^,", ""))
end

function Util.clock(seconds)
	seconds = math.max(0, math.floor(seconds))
	local h = math.floor(seconds / 3600)
	local m = math.floor(seconds % 3600 / 60)
	local s = seconds % 60
	if h > 0 then
		return string.format("%d:%02d:%02d", h, m, s)
	end
	return string.format("%d:%02d", m, s)
end

function Util.words(seconds)
	seconds = math.max(0, math.floor(seconds))
	if seconds >= 86400 then
		return string.format("%dd %dh", seconds // 86400, seconds % 86400 // 3600)
	elseif seconds >= 3600 then
		return string.format("%dh %dm", seconds // 3600, seconds % 3600 // 60)
	elseif seconds >= 60 then
		return string.format("%dm", seconds // 60)
	end
	return string.format("%ds", seconds)
end

function Util.minutes(minutes)
	if minutes >= 120 and minutes % 60 == 0 then
		return string.format("%d hours", minutes // 60)
	elseif minutes >= 60 then
		return string.format("%.1f hours", minutes / 60)
	end
	return string.format("%d min", minutes)
end

function Util.tween(object, props, duration, style, direction)
	local tween = TweenService:Create(object, TweenInfo.new(duration or 0.2, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out), props)
	tween:Play()
	return tween
end

function Util.clone(list)
	local copy = {}
	for key, value in list do
		copy[key] = value
	end
	return copy
end

function Util.sortedKeys(map)
	local keys = {}
	for key in map do
		table.insert(keys, key)
	end
	table.sort(keys)
	return keys
end

return Util
