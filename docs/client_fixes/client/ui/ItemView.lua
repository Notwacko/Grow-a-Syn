local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Theme = require(script.Parent.Theme)
local Ui = require(script.Parent.Ui)
local ItemCatalog = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ItemCatalog"))

local ItemView = {}

ItemView.MUTATION_COLORS = {
	polished = Color3.fromRGB(214, 226, 255),
	gilded = Color3.fromRGB(255, 214, 80),
	radiant = Color3.fromRGB(255, 255, 255),
	luminous = Color3.fromRGB(120, 255, 240),
	ancient = Color3.fromRGB(96, 214, 196),
}

function ItemView.info(id)
	return ItemCatalog.item(id)
end

function ItemView.icon(info)
	return "item_" .. info.category
end

function ItemView.name(info, mutation, star)
	return ItemCatalog.displayName(info, mutation, star)
end

function ItemView.pips(parent, rarityId, props)
	props = props or {}
	local entry = Theme.rarity[rarityId] or Theme.rarity.common
	local size = props.size or 10
	local row = Ui.frame(parent, {
		name = "Pips",
		size = props.frame or UDim2.new(1, 0, 0, size),
		position = props.position,
		anchor = props.anchor,
		z = props.z or 6,
	})
	Ui.make("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = props.align or Enum.HorizontalAlignment.Center,
		Padding = UDim.new(0, 3),
		VerticalAlignment = Enum.VerticalAlignment.Center,
	}, row)
	local color = Theme.rarityColor(rarityId)
	for index = 1, entry.pips do
		local pip = Ui.frame(row, {
			name = "Pip" .. index,
			size = UDim2.fromOffset(size, size),
			color = color,
			transparency = 0,
			radius = 999,
			stroke = 2,
			order = index,
			z = props.z or 6,
		})
		pip.Rotation = 45
		pip.UICorner.CornerRadius = UDim.new(0, 2)
	end
	return row
end

function ItemView.rarityTag(parent, rarityId, props)
	props = props or {}
	local color = Theme.rarityColor(rarityId)
	local entry = Theme.rarity[rarityId] or Theme.rarity.common
	local tag = Ui.frame(parent, {
		name = "RarityTag",
		size = props.size or UDim2.new(1, 0, 0, 24),
		position = props.position,
		anchor = props.anchor,
		color = color,
		transparency = 0,
		radius = 12,
		z = props.z or 5,
	})
	Ui.gradient(tag, { Theme.tint(color, 0.25), Theme.shade(color, 0.1) }, 90)
	local label = Ui.label(tag, { text = entry.name, textSize = 15, size = UDim2.new(1, -8, 1, 0), position = UDim2.fromOffset(4, 0), stroke = 2, fit = true, z = 6 })
	return tag, label
end

function ItemView.glow(parent, color, size, position)
	local glow = Ui.frame(parent, {
		name = "Glow",
		size = UDim2.fromOffset(size, size),
		position = position or UDim2.fromScale(0.5, 0.5),
		anchor = Vector2.new(0.5, 0.5),
		color = color,
		transparency = 0.72,
		radius = 999,
		z = 3,
	})
	return glow
end

function ItemView.mutationBadge(parent, mutation)
	local color = ItemView.MUTATION_COLORS[mutation]
	if not color then
		return nil
	end
	local badge = Ui.frame(parent, {
		name = "Mutation",
		size = UDim2.fromOffset(78, 20),
		position = UDim2.new(0.5, 0, 0, 32),
		anchor = Vector2.new(0.5, 0),
		color = color,
		transparency = 0,
		radius = 10,
		stroke = 2,
		z = 8,
	})
	local text = string.upper(string.sub(mutation, 1, 1)) .. string.sub(mutation, 2)
	Ui.label(badge, { text = text, textSize = 13, color = Theme.ink, stroke = false, size = UDim2.fromScale(1, 1), fit = true, z = 9 })
	return badge
end

return ItemView
