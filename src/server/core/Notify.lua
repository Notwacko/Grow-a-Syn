local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Link = require(script.Parent.Link)

local Notify = {}

local KINDS = { info = true, success = true, error = true }
local lastText = {}

local remote = Link.get(ReplicatedStorage, "Remotes", "RE_Notify", "RemoteEvent")

function Notify.send(player, kind, text)
	if typeof(player) ~= "Instance" or not player:IsA("Player") or player.Parent ~= Players then
		return
	end
	if type(text) ~= "string" or text == "" then
		return
	end
	if not KINDS[kind] then
		kind = "info"
	end
	local now = os.clock()
	local last = lastText[player]
	if last and last.text == text and now - last.at < 1 then
		return
	end
	lastText[player] = { text = text, at = now }
	remote:FireClient(player, kind, string.sub(text, 1, 120))
end

function Notify.release(player)
	lastText[player] = nil
end

return Notify
