local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SerializationService = game:GetService("SerializationService")

local ALPHABET = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local chars = {}
for i = 1, 64 do
	chars[i - 1] = string.sub(ALPHABET, i, i)
end

local function encode(buf)
	local length = buffer.len(buf)
	local out = {}
	for i = 0, length - 1, 3 do
		local b1 = buffer.readu8(buf, i)
		local b2 = i + 1 < length and buffer.readu8(buf, i + 1) or 0
		local b3 = i + 2 < length and buffer.readu8(buf, i + 2) or 0
		local n = b1 * 65536 + b2 * 256 + b3
		table.insert(out, chars[bit32.rshift(n, 18) % 64])
		table.insert(out, chars[bit32.rshift(n, 12) % 64])
		table.insert(out, i + 1 < length and chars[bit32.rshift(n, 6) % 64] or "=")
		table.insert(out, i + 2 < length and chars[n % 64] or "=")
	end
	return table.concat(out)
end

local previous = HttpService.HttpEnabled
HttpService.HttpEnabled = true
local report = {}
for _, name in NAMES do
	local model = ReplicatedStorage.Models.core:FindFirstChild(name)
	if model then
		local ok, result = pcall(function()
			local data = SerializationService:SerializeInstancesAsync({ model })
			local body = encode(data)
			return HttpService:PostAsync("http://127.0.0.1:8767/save/" .. name .. ".rbxm", body, Enum.HttpContentType.TextPlain)
		end)
		report[name] = ok and ("saved " .. tostring(result)) or ("FAILED " .. tostring(result))
	else
		report[name] = "MISSING"
	end
end
HttpService.HttpEnabled = previous
return report
