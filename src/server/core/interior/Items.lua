local ReplicatedStorage = game:GetService("ReplicatedStorage")

local core = script.Parent.Parent
local Config = require(core.Config)
local Assets = require(core.Assets)
local Fx = require(core.Fx)
local ItemService = require(core.ItemService)
local Shared = ReplicatedStorage:WaitForChild("Shared")
local ItemCatalog = require(Shared:WaitForChild("ItemCatalog"))
local ItemSkin = require(Shared:WaitForChild("ItemSkin"))

local Items = {
	name = "Items",
	order = 25,
}

local GROW_MIN = 0.55
local STARTER_WIDTH = 30
local WIDTH_SPAN = 124
local HALL_BOOST = {
	ark = 1,
	chandelier = 0.9,
	holiday_decor = 0.9,
	ornament = 0.7,
	menorah = 0.6,
	siddur = 0.3,
	kiddush_cup = 0.3,
}
local TORAH_BOOST = 0.35
local SIDE_WALL = 8
local DOOR_WALL = -5

local states = {}

local function growScale(growth)
	local eased = growth * growth * (3 - 2 * growth)
	return GROW_MIN + (1 - GROW_MIN) * eased
end

local function slotFrame(floor, slot, category)
	local localPosition = floor.CFrame:PointToObjectSpace(slot.Position)
	local yaw = 0
	if category == "ornament" or category == "holiday_decor" then
		if localPosition.X > SIDE_WALL then
			yaw = math.pi / 2
		elseif localPosition.X < -SIDE_WALL then
			yaw = -math.pi / 2
		elseif localPosition.Z < DOOR_WALL then
			yaw = math.pi
		end
	end
	local lift = 0
	if category == "holiday_decor" and localPosition.Y < 3 then
		lift = 7
	end
	return slot.CFrame * CFrame.Angles(0, yaw, 0) + slot.CFrame.UpVector * lift
end

local function buildLabel(model, entry)
	local anchor = Instance.new("Part")
	anchor.Name = "LabelAnchor"
	anchor.Size = Vector3.one * 0.2
	anchor.Transparency = 1
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.CastShadow = false
	anchor.Parent = model
	local gui = Instance.new("BillboardGui")
	gui.Name = "ItemSign"
	gui.Size = UDim2.fromOffset(160, 40)
	gui.MaxDistance = 10
	gui.LightInfluence = 0
	gui.Adornee = anchor
	gui.Parent = anchor
	local function label(name, y, height, color, thickness)
		local text = Instance.new("TextLabel")
		text.Name = name
		text.BackgroundTransparency = 1
		text.Position = UDim2.fromScale(0, y)
		text.Size = UDim2.fromScale(1, height)
		text.Font = Enum.Font.FredokaOne
		text.TextScaled = true
		text.TextColor3 = color
		text.Parent = gui
		local stroke = Instance.new("UIStroke")
		stroke.Thickness = thickness
		stroke.Color = Color3.fromRGB(30, 30, 50)
		stroke.Parent = text
		return text
	end
	label("Title", 0, 0.58, Color3.new(1, 1, 1), 2.5)
	label("Status", 0.58, 0.42, Color3.fromRGB(190, 255, 200), 2)
	return anchor, gui
end

local function paintLabel(gui, entry, info, growth)
	local rarity = ItemCatalog.rarity(info.rarity)
	local title = gui:FindFirstChild("Title")
	local status = gui:FindFirstChild("Status")
	title.Text = ItemCatalog.displayName(info, entry.mutation)
	title.TextColor3 = rarity.color
	local bonus = ItemCatalog.bonusOf(info, growth, entry.mutation)
	if growth < 1 then
		status.Text = string.format("Growing %d%%  +%d%%", math.floor(growth * 100), math.floor(bonus * 100 + 0.5))
		status.TextColor3 = Color3.fromRGB(255, 233, 150)
	else
		status.Text = string.format("Grown  +%d%% income", math.floor(bonus * 100 + 0.5))
		status.TextColor3 = Color3.fromRGB(190, 255, 200)
	end
end

local function apply(record, entry)
	local info = record.info
	local growth = entry.growth
	record.entry = entry
	local scale = record.base * growScale(growth)
	record.model:ScaleTo(scale)
	local reach = record.height * scale + 1.2
	if record.hanging then
		record.anchor.Position = record.frame.Position - Vector3.new(0, reach, 0)
	else
		record.anchor.Position = record.frame.Position + Vector3.new(0, reach, 0)
	end
	paintLabel(record.gui, entry, info, growth)
end

local function sizeFactor(category, sizing)
	if category == "torah" then
		return math.max(1, math.min(1 + sizing.hall * TORAH_BOOST, sizing.torahLimit))
	end
	return 1 + sizing.hall * (HALL_BOOST[category] or 0)
end

local function spawn(buildingModel, floor, folder, entry, sizing)
	local info = ItemCatalog.item(entry.id)
	local category = info and ItemCatalog.category(info.category)
	if not info or not category then
		return nil
	end
	local slots = buildingModel:FindFirstChild("Slots", true)
	local slot = slots and slots:FindFirstChild(entry.slot)
	if not slot then
		return nil
	end
	local model = Assets.get(info.model)
	if not model or not model:IsA("Model") then
		return nil
	end
	model.Name = "Item_" .. entry.uid
	Assets.setPassive(model)
	ItemSkin.apply(model, info.rarity, entry.mutation, true)
	local native = model:GetScale()
	local extents = model:GetExtentsSize()
	local base = native * category.fit * sizeFactor(info.category, sizing) / math.max(extents.X, extents.Y, extents.Z, 0.01)
	model:ScaleTo(base)
	local frame = slotFrame(floor, slot, info.category)
	model:PivotTo(frame)
	model.Parent = folder
	local anchor, gui = buildLabel(model, entry)
	local record = {
		model = model,
		info = info,
		base = base,
		height = extents.Y / native,
		frame = frame,
		anchor = anchor,
		gui = gui,
		hanging = info.category == "chandelier" or info.category == "holiday_decor",
	}
	apply(record, entry)
	return record
end

local function popIn(record)
	local base = record.base * growScale(record.entry.growth)
	task.spawn(function()
		for step = 1, 8 do
			if not record.model.Parent then
				return
			end
			local t = step / 8
			local overshoot = 1 + math.sin(t * math.pi) * 0.18
			record.model:ScaleTo(math.max(base * t * overshoot, 0.05))
			task.wait(0.03)
		end
		if record.model.Parent then
			record.model:ScaleTo(base)
		end
	end)
	local position = record.frame.Position + Vector3.new(0, 2, 0)
	Fx.sparkle(position)
	Fx.sound(position, Config.SOUNDS.pop, 0.8, 1.15)
end

function Items.layout(buildingModel, floor, folder, entries)
	for _, child in folder:GetChildren() do
		child:Destroy()
	end
	local slots = buildingModel:FindFirstChild("Slots", true)
	local first = slots and slots:FindFirstChild("Slot_Torah1")
	local second = slots and slots:FindFirstChild("Slot_Torah2")
	local sizing = { hall = math.clamp((floor.Size.X - STARTER_WIDTH) / WIDTH_SPAN, 0, 1), torahLimit = 1 }
	if first and second then
		local spacing = math.abs(floor.CFrame:PointToObjectSpace(second.Position).Y - floor.CFrame:PointToObjectSpace(first.Position).Y)
		sizing.torahLimit = spacing / (ItemCatalog.category("torah").fit * 1.1)
	end
	local records = {}
	for _, entry in entries do
		local record = spawn(buildingModel, floor, folder, entry, sizing)
		if record then
			records[entry.uid] = record
		end
	end
	return records
end

local function populate(state, highlightUid)
	state.records = Items.layout(state.context.model, state.context.info.floor, state.folder, ItemService.placed(state.context.player))
	local record = highlightUid and state.records[highlightUid]
	if record then
		popIn(record)
	end
end

function Items.build(context)
	local folder = Instance.new("Folder")
	folder.Name = "Items"
	folder.Parent = context.folder
	local state = { context = context, folder = folder, records = {} }
	states[context.player] = state
	populate(state, nil)
end

function Items.destroy(context)
	if states[context.player] and states[context.player].context == context then
		states[context.player] = nil
	end
end

function Items.refresh(player, highlightUid)
	local state = states[player]
	if state and state.folder.Parent then
		populate(state, highlightUid)
	end
end

function Items.grow(player)
	local state = states[player]
	if not state or not state.folder.Parent then
		return
	end
	for _, entry in ItemService.placed(player) do
		local record = state.records[entry.uid]
		if record and record.model.Parent and (record.entry.growth ~= entry.growth or record.entry.mutation ~= entry.mutation) then
			apply(record, entry)
		end
	end
end

function Items.celebrate(player, uid, mutationId)
	local state = states[player]
	local record = state and state.records[uid]
	if not record or not record.model.Parent then
		return
	end
	Items.grow(player)
	local position = record.anchor.Position
	local mutation = mutationId and ItemCatalog.mutation(mutationId)
	if mutation then
		Fx.confetti(position, 0.9)
		Fx.ring(Vector3.new(position.X, record.frame.Position.Y, position.Z), mutation.color, 14)
		Fx.floatText(position + Vector3.new(0, 2, 0), mutation.name .. "!", mutation.color)
		Fx.sound(position, Config.SOUNDS.victory, 0.7, 1.1)
	else
		Fx.sparkle(position)
		Fx.sound(position, Config.SOUNDS.ping, 0.7, 1)
	end
end

ItemService.Changed:Connect(function(player, kind, uid)
	local highlight = (kind == "buy" or kind == "equip" or kind == "merge") and uid or nil
	Items.refresh(player, highlight)
end)

ItemService.Grew:Connect(function(player)
	Items.grow(player)
end)

ItemService.Matured:Connect(function(player, uid, _, mutationId)
	Items.celebrate(player, uid, mutationId)
end)

return Items
