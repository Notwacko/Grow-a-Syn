local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local Link = require(script.Parent.Parent.Link)

if not RunService:IsStudio() then
	return
end

task.wait(8)

if workspace:GetAttribute("CoreOnline") == true then
	return
end

warn("[DevMockCore] CoreOnline is not set, standing in for core")

local spend = Link.get(ServerStorage, "Bridge", "SpendMoney", "BindableFunction")
local grant = Link.get(ServerStorage, "Bridge", "GrantMoney", "BindableEvent")

spend.OnInvoke = function(player, amount, reason)
	if typeof(player) ~= "Instance" or not player:IsA("Player") or type(amount) ~= "number" or amount < 0 then
		return false
	end
	local money = player:GetAttribute("Money") or 0
	if money < amount then
		return false
	end
	player:SetAttribute("Money", money - amount)
	return true
end

grant.Event:Connect(function(player, amount, reason)
	if typeof(player) ~= "Instance" or not player:IsA("Player") or type(amount) ~= "number" or amount < 0 then
		return
	end
	player:SetAttribute("Money", (player:GetAttribute("Money") or 0) + amount)
end)

workspace:WaitForChild("Plots", 3)

local function setup(player)
	player:SetAttribute("Money", 1000)
	player:SetAttribute("PlotId", 1)
	player:SetAttribute("LandTier", 6)
	player:SetAttribute("Congregation", 12)
	player:SetAttribute("HasMinyan", true)
end

Players.PlayerAdded:Connect(setup)
for _, player in ipairs(Players:GetPlayers()) do
	setup(player)
end

workspace:SetAttribute("CoreOnline", true)
