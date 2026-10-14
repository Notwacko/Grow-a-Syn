local Assets = require(script.Parent.Assets)

local StarterGear = {}

local GEAR = { "kippah", "tallit" }

local function give(player, character)
	local humanoid = character:WaitForChild("Humanoid", 10)
	if not humanoid then
		return
	end
	local deadline = os.clock() + 10
	while character.Parent and not player:HasAppearanceLoaded() and os.clock() < deadline do
		task.wait(0.2)
	end
	if not character.Parent or humanoid.Health <= 0 then
		return
	end
	for _, name in GEAR do
		for _, child in character:GetChildren() do
			if child:IsA("Accessory") and child:GetAttribute("CoreGear") == name then
				child:Destroy()
			end
		end
		local accessory = Assets.get(name)
		if accessory then
			if accessory:IsA("Accessory") then
				accessory:SetAttribute("CoreGear", name)
				humanoid:AddAccessory(accessory)
			else
				accessory:Destroy()
			end
		end
	end
end

function StarterGear.watch(player)
	player.CharacterAdded:Connect(function(character)
		task.spawn(give, player, character)
	end)
	if player.Character then
		task.spawn(give, player, player.Character)
	end
end

return StarterGear
