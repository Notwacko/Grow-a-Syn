local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Balance = require(script.Parent.Balance)
local Catalog = require(script.Parent.Catalog)
local Guard = require(script.Parent.Guard)
local InventoryService = require(script.Parent.InventoryService)
local Link = require(script.Parent.Link)
local ModelLookup = require(script.Parent.ModelLookup)

local EquipService = {}

local FOLDER_NAME = "ProgressionItems"
local SPARKLE_TEXTURE = "rbxasset://textures/particles/sparkles_main.dds"

local plotConnections = {}
local placedFolders = {}

local function getPlot(player)
	local plotId = player:GetAttribute("PlotId") or 0
	if plotId <= 0 then
		return nil
	end
	local plots = workspace:FindFirstChild("Plots")
	local plot = plots and plots:FindFirstChild("Plot" .. plotId)
	if not plot then
		return nil
	end
	local owner = plot:GetAttribute("OwnerUserId") or 0
	if owner ~= 0 and owner ~= player.UserId then
		return nil
	end
	return plot
end

local function loadModel(category, rarity)
	local models = ReplicatedStorage:FindFirstChild("Models")
	local overrideName = category .. "_" .. rarity
	if models and models:FindFirstChild(overrideName, true) then
		return ModelLookup.get(overrideName)
	end
	return ModelLookup.get(category)
end

local function collectParts(root)
	local parts = {}
	if root:IsA("BasePart") then
		table.insert(parts, root)
	end
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("BasePart") then
			table.insert(parts, d)
		end
	end
	return parts
end

local function applySkin(root, rarity)
	local style = Balance.RaritySkin[rarity]
	local color = Catalog.rarity(rarity).color
	local parts = collectParts(root)
	local accents = {}
	for _, part in ipairs(parts) do
		part.Anchored = true
		part.CanCollide = false
		part.CanTouch = false
		if string.find(string.lower(part.Name), "accent", 1, true) then
			table.insert(accents, part)
		end
	end
	local targets = #accents > 0 and accents or parts
	for _, part in ipairs(targets) do
		part.Color = color
		part.Material = style.material
		if part:IsA("MeshPart") then
			part.TextureID = ""
		end
		for _, child in ipairs(part:GetChildren()) do
			if child:IsA("SurfaceAppearance") then
				child:Destroy()
			end
		end
	end
	local main = root:IsA("BasePart") and root or root.PrimaryPart or parts[1]
	if not main then
		return
	end
	if style.glow then
		local light = Instance.new("PointLight")
		light.Color = color
		light.Brightness = 1.5
		light.Range = style.glow
		light.Parent = main
	end
	if style.particles then
		local attachment = Instance.new("Attachment")
		attachment.Position = Vector3.new(0, main.Size.Y * 0.5, 0)
		attachment.Parent = main
		local emitter = Instance.new("ParticleEmitter")
		emitter.Texture = SPARKLE_TEXTURE
		emitter.Color = ColorSequence.new(color, Color3.new(1, 1, 1))
		emitter.LightEmission = 1
		emitter.Rate = style.particles
		emitter.Lifetime = NumberRange.new(1.5, 2.5)
		emitter.Speed = NumberRange.new(0.5, 1.5)
		emitter.SpreadAngle = Vector2.new(40, 40)
		emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 0) })
		emitter.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
		emitter.Parent = attachment
	end
end

local function clearPlaced(player)
	local folder = placedFolders[player]
	if folder then
		folder:Destroy()
		placedFolders[player] = nil
	end
end

function EquipService.placeAll(player)
	clearPlaced(player)
	local plot = getPlot(player)
	if not plot then
		return
	end
	local building = plot:FindFirstChild("Building")
	local slots = building and building:FindFirstChild("Slots", true)
	if not slots then
		return
	end
	local folder = Instance.new("Folder")
	folder.Name = FOLDER_NAME
	for _, item in ipairs(InventoryService.equipped(player)) do
		local slot = slots:FindFirstChild(item.slot)
		if slot and slot:IsA("BasePart") then
			local model = loadModel(item.category, item.rarity)
			model.Name = item.category .. "_" .. item.uid
			model:SetAttribute("ItemUid", item.uid)
			applySkin(model, item.rarity)
			if model:IsA("BasePart") then
				model.CFrame = slot.CFrame * CFrame.new(0, model.Size.Y * 0.5, 0)
			else
				model:PivotTo(slot.CFrame)
			end
			model.Parent = folder
		end
	end
	folder.Parent = plot
	placedFolders[player] = folder
end

local function watchPlot(player)
	if plotConnections[player] then
		plotConnections[player]:Disconnect()
		plotConnections[player] = nil
	end
	local plot = getPlot(player)
	if plot then
		plotConnections[player] = plot:GetAttributeChangedSignal("BuildingVersion"):Connect(function()
			task.defer(EquipService.placeAll, player)
		end)
	end
	EquipService.placeAll(player)
end

function EquipService.equip(player, uid, slotName)
	if not Guard.isString(uid) or not Guard.isString(slotName) then
		return { ok = false, reason = "invalid" }
	end
	if not InventoryService.get(player) then
		return { ok = false, reason = "offline" }
	end
	local item = InventoryService.find(player, uid)
	if not item or not Catalog.isValidSlot(item.category, slotName) then
		return { ok = false, reason = "invalid" }
	end
	for _, other in ipairs(InventoryService.equipped(player)) do
		if other.slot == slotName and other ~= item then
			other.slot = nil
		end
	end
	item.slot = slotName
	InventoryService.changed(player)
	EquipService.placeAll(player)
	return { ok = true }
end

function EquipService.unequip(player, uid)
	if not Guard.isString(uid) then
		return { ok = false, reason = "invalid" }
	end
	if not InventoryService.get(player) then
		return { ok = false, reason = "offline" }
	end
	local item = InventoryService.find(player, uid)
	if not item or not item.slot then
		return { ok = false, reason = "invalid" }
	end
	item.slot = nil
	InventoryService.changed(player)
	EquipService.placeAll(player)
	return { ok = true }
end

local function onPlayerAdded(player)
	player:GetAttributeChangedSignal("PlotId"):Connect(function()
		watchPlot(player)
	end)
end

function EquipService.init()
	local equipRemote = Link.get(ReplicatedStorage, "Remotes", "RF_Equip", "RemoteFunction")
	equipRemote.OnServerInvoke = function(player, uid, slotName)
		return Guard.run(player, "equip", EquipService.equip, player, uid, slotName)
	end

	local unequipRemote = Link.get(ReplicatedStorage, "Remotes", "RF_Unequip", "RemoteFunction")
	unequipRemote.OnServerInvoke = function(player, uid)
		return Guard.run(player, "unequip", EquipService.unequip, player, uid)
	end

	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in ipairs(Players:GetPlayers()) do
		onPlayerAdded(player)
	end
	InventoryService.onLoaded(watchPlot)

	Players.PlayerRemoving:Connect(function(player)
		if plotConnections[player] then
			plotConnections[player]:Disconnect()
			plotConnections[player] = nil
		end
		clearPlaced(player)
	end)
end

return EquipService
