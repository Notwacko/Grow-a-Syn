local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = require(script.Parent.Assets)
local Signal = require(script.Parent.Signal)
local Notify = require(script.Parent.Notify)
local OutfitBuilder = require(script.Parent.OutfitBuilder)
local Catalog = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("OutfitCatalog"))

local CosmeticsService = {}

CosmeticsService.Changed = Signal.new()

local states = {}

local function tierOf(player)
	return math.clamp(math.floor(tonumber(player:GetAttribute("Tier")) or 1), 1, 7)
end

local function addGear(humanoid, pieceId, definition)
	local accessory = Assets.get(definition.gear)
	if not accessory then
		return
	end
	if not accessory:IsA("Accessory") then
		accessory:Destroy()
		return
	end
	for name, color in definition.colors do
		local part = accessory:FindFirstChild(name)
		if part and part:IsA("BasePart") then
			part.Color = color
		end
	end
	accessory:SetAttribute("CoreGear", pieceId)
	humanoid:AddAccessory(accessory)
end

local function wear(player, character)
	local state = states[player]
	if not state then
		return
	end
	state.token += 1
	local token = state.token
	local humanoid = character:WaitForChild("Humanoid", 10)
	if not humanoid then
		return
	end
	local deadline = os.clock() + 10
	while character.Parent and not player:HasAppearanceLoaded() and os.clock() < deadline do
		task.wait(0.2)
	end
	if state.token ~= token or not character.Parent or humanoid.Health <= 0 then
		return
	end
	local outfit = Catalog.resolve(state.outfit, tierOf(player))
	for _, child in character:GetChildren() do
		if child:IsA("Accessory") and child:GetAttribute("CoreGear") then
			child:Destroy()
		end
	end
	local custom = {}
	for _, id in Catalog.pieces(outfit, state.style) do
		local gear = OutfitBuilder.gearFor(id)
		if gear then
			addGear(humanoid, id, gear)
		elseif OutfitBuilder.has(id) then
			table.insert(custom, id)
		end
	end
	OutfitBuilder.apply(character, custom)
	player:SetAttribute("Outfit", outfit.id)
	player:SetAttribute("OutfitStyle", state.style)
end

local function rewear(player)
	if player.Character then
		task.spawn(wear, player, player.Character)
	end
	CosmeticsService.Changed:Fire(player)
end

function CosmeticsService.watch(player)
	local state = { token = 0, outfit = Catalog.AUTO, style = "classic", connections = {} }
	states[player] = state
	table.insert(state.connections, player.CharacterAdded:Connect(function(character)
		task.spawn(wear, player, character)
	end))
	table.insert(state.connections, player:GetAttributeChangedSignal("Tier"):Connect(function()
		rewear(player)
	end))
	if player.Character then
		task.spawn(wear, player, player.Character)
	end
end

function CosmeticsService.init(player, saved)
	local state = states[player]
	if not state then
		return
	end
	if type(saved) == "table" then
		if Catalog.validSelection(saved.outfit) then
			state.outfit = saved.outfit
		end
		if Catalog.validStyle(saved.style) then
			state.style = saved.style
		end
	end
	rewear(player)
end

function CosmeticsService.serialize(player)
	local state = states[player]
	if not state then
		return { outfit = Catalog.AUTO, style = "classic" }
	end
	return { outfit = state.outfit, style = state.style }
end

function CosmeticsService.describe(player)
	local state = states[player]
	local outfit = Catalog.resolve(state and state.outfit or Catalog.AUTO, tierOf(player))
	return {
		name = outfit.name,
		blurb = outfit.blurb,
		auto = not state or state.outfit == Catalog.AUTO,
		style = state and state.style or "classic",
	}
end

function CosmeticsService.cycleOutfit(player)
	local state = states[player]
	if not state then
		return
	end
	state.outfit = Catalog.nextSelection(state.outfit)
	rewear(player)
	local info = CosmeticsService.describe(player)
	Notify.send(player, "info", (info.auto and "Outfit: Auto, " or "Outfit: ") .. info.name)
end

function CosmeticsService.toggleStyle(player)
	local state = states[player]
	if not state then
		return
	end
	state.style = state.style == "classic" and "modest" or "classic"
	rewear(player)
	Notify.send(player, "info", state.style == "modest" and "Style: modest dress" or "Style: classic")
end

function CosmeticsService.forget(player)
	local state = states[player]
	if state then
		for _, connection in state.connections do
			connection:Disconnect()
		end
		states[player] = nil
	end
end

return CosmeticsService
