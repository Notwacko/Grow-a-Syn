local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ui = script.Parent.Parent.ui
local Theme = require(ui.Theme)
local Ui = require(ui.Ui)
local Util = require(ui.Util)
local Store = require(ui.Store)
local ItemView = require(ui.ItemView)
local Sfx = require(ui.Sfx)
local PetCatalog = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("PetCatalog"))

local PanelPets = {}

function PanelPets.new(container, ctx, menu)
	local panel = {}
	local hatching = false
	local oddsOpen = false

	local leftWidth = Ui.touch and 260 or 330
	local left = Ui.frame(container, { name = "Left", size = UDim2.new(0, leftWidth, 1, 0), z = 3 })
	local right = Ui.frame(container, { name = "Right", size = UDim2.new(1, -(leftWidth + 14), 1, 0), position = UDim2.fromOffset(leftWidth + 14, 0), z = 3 })

	local eggCard = Ui.card(left, { size = UDim2.new(1, 0, 0, 430), color = Theme.cream2, strokeColor = Theme.green[2], stroke = 4 })
	local eggTitle = Ui.label(eggCard, { text = "Mystery Egg", textSize = 30, color = Theme.ink, stroke = false, size = UDim2.new(1, 0, 0, 40), position = UDim2.fromOffset(0, 10), z = 5 })
	local eggHolder = Ui.frame(eggCard, { size = UDim2.fromOffset(190, 190), position = UDim2.new(0.5, 0, 0, 56), anchor = Vector2.new(0.5, 0), z = 4 })
	ItemView.glow(eggHolder, Theme.green[1], 170)
	local egg = Ui.image(eggHolder, { image = "egg", size = UDim2.fromOffset(170, 170), position = UDim2.fromScale(0.5, 0.5), anchor = Vector2.new(0.5, 0.5), z = 6 })
	local hatch = Ui.button(eggCard, {
		palette = Theme.green,
		size = UDim2.new(1, -40, 0, 64),
		position = UDim2.new(0.5, 0, 0, 262),
		anchor = Vector2.new(0.5, 0),
		icon = "coin",
		iconSize = 36,
		text = "Hatch",
		textSize = 30,
	})
	local pityLabel = Ui.label(eggCard, {
		text = "",
		textSize = 16,
		color = Theme.inkSoft,
		stroke = false,
		size = UDim2.new(1, -24, 0, 40),
		position = UDim2.fromOffset(12, 340),
		wrap = true,
		z = 5,
	})
	pityLabel.Font = Theme.bodyFont
	local oddsButton = Ui.button(eggCard, {
		palette = Theme.blue,
		size = UDim2.fromOffset(130, 40),
		position = UDim2.new(0.5, 0, 1, -8),
		anchor = Vector2.new(0.5, 1),
		text = "Odds",
		textSize = 20,
	})
	local oddsBox = Ui.frame(eggCard, { size = UDim2.new(1, -16, 1, -16), position = UDim2.fromOffset(8, 8), color = Theme.cream, transparency = 0, radius = 14, stroke = 3, visible = false, z = 20 })
	local oddsText = Ui.label(oddsBox, { text = "", textSize = 20, color = Theme.ink, stroke = false, size = UDim2.new(1, -20, 1, -70), position = UDim2.fromOffset(10, 10), wrap = true, yalign = Enum.TextYAlignment.Top, z = 21 })
	oddsText.Font = Theme.bodyFont
	local oddsBack = Ui.button(oddsBox, { palette = Theme.blue, size = UDim2.fromOffset(130, 44), position = UDim2.new(0.5, 0, 1, -8), anchor = Vector2.new(0.5, 1), text = "Back", textSize = 22, z = 22 })
	oddsBack.click(function()
		oddsBox.Visible = false
	end)

	local slotCard = Ui.card(left, { size = UDim2.new(1, 0, 0, 120), position = UDim2.fromOffset(0, 440), color = Theme.cream2 })
	Ui.label(slotCard, { text = "Following you", textSize = 20, color = Theme.ink, stroke = false, size = UDim2.new(1, 0, 0, 26), position = UDim2.fromOffset(0, 4), z = 5 })
	local slotRow = Ui.frame(slotCard, { size = UDim2.new(1, -16, 0, 70), position = UDim2.fromOffset(8, 36), z = 4 })
	Ui.make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 10), VerticalAlignment = Enum.VerticalAlignment.Center }, slotRow)

	local bonusPill, bonusLabel = Ui.pill(right, {
		size = UDim2.fromOffset(300, 46),
		position = UDim2.fromOffset(4, 0),
		icon = "heart",
		text = "Pet bonus +0%",
		height = 46,
		textSize = 22,
	})
	local scroll = Ui.scroll(right, { size = UDim2.new(1, 0, 1, -56), position = UDim2.fromOffset(0, 54), grid = { cell = UDim2.fromOffset(178, 232), pad = UDim2.fromOffset(10, 10) }, pad = 4 })

	local function state()
		return Store.get("pets")
	end

	local function isEquipped(id)
		local data = state()
		return data and table.find(data.equipped, id) ~= nil
	end

	function panel.refresh()
		local data = state()
		if not data then
			return
		end
		bonusLabel.Text = string.format("Pet bonus +%s%%", Util.short(data.bonus * 100))
		hatch.setText(Util.short(data.eggCost))
		hatch.setPalette(Store.attr("Money", 0) >= data.eggCost and Theme.green or Theme.red)
		pityLabel.Text = string.format("Epic pet guaranteed within %d eggs, Legendary within %d.", data.pity.epic, data.pity.legendary)
		local lines = {}
		for _, odd in data.odds do
			table.insert(lines, string.format("%s: %.0f%%", odd.name, odd.percent))
		end
		oddsText.Text = "Egg odds\n" .. table.concat(lines, "\n") .. "\n\nHatching only uses in-game money."
		Ui.clear(slotRow)
		for index = 1, data.slots do
			local slot = Ui.frame(slotRow, { size = UDim2.fromOffset(66, 66), color = Theme.cardBase, transparency = 0, radius = 14, stroke = 3, order = index, z = 5 })
			local id = data.equipped[index]
			if id then
				Ui.image(slot, { image = "pet_" .. id, size = UDim2.new(1, -6, 1, -6), position = UDim2.fromOffset(3, 3), z = 6 })
				slot.UIStroke.Color = Theme.green[2]
			else
				Ui.label(slot, { text = "+", textSize = 34, color = Theme.muted, stroke = false, size = UDim2.fromScale(1, 1), z = 6 })
			end
		end
		Ui.clear(scroll)
		local owned = {}
		for _, entry in data.owned do
			owned[entry.id] = entry
		end
		for index, pet in PetCatalog.list do
			local entry = owned[pet.id]
			local color = Theme.rarityColor(pet.rarity)
			local card = Ui.card(scroll, { size = UDim2.fromOffset(178, 232), order = index, strokeColor = entry and color or Theme.disabled, stroke = entry and (Theme.rarity[pet.rarity].stroke) or 3 })
			ItemView.glow(card, color, 110, UDim2.new(0.5, 0, 0, 78))
			local icon = Ui.image(card, { image = "pet_" .. pet.id, size = UDim2.fromOffset(120, 120), position = UDim2.new(0.5, 0, 0, 78), anchor = Vector2.new(0.5, 0.5), z = 5 })
			if not entry then
				icon.ImageColor3 = Color3.new(0, 0, 0)
				icon.ImageTransparency = 0.55
			end
			ItemView.rarityTag(card, pet.rarity, { size = UDim2.new(1, -16, 0, 22), position = UDim2.fromOffset(8, 6) })
			local name = Ui.label(card, { text = entry and pet.name or "???", textSize = 20, color = Theme.ink, stroke = false, size = UDim2.new(1, -8, 0, 28), position = UDim2.fromOffset(4, 142), fit = true, z = 5 })
			local sub = Ui.label(card, {
				text = entry and string.format("Lv %d  +%s%%", entry.level, Util.short(entry.bonus * 100)) or "Hatch to find",
				textSize = 15,
				color = Theme.inkSoft,
				stroke = false,
				size = UDim2.new(1, -8, 0, 20),
				position = UDim2.fromOffset(4, 164),
				fit = true,
				z = 5,
			})
			sub.Font = Theme.bodyFont
			if entry then
				local equipped = isEquipped(pet.id)
				local button = Ui.button(card, {
					palette = equipped and Theme.orange or Theme.green,
					size = UDim2.new(1, -20, 0, 34),
					position = UDim2.new(0.5, 0, 1, -6),
					anchor = Vector2.new(0.5, 1),
					text = equipped and "Put Away" or "Take Along",
					textSize = 16,
				})
				button.click(function()
					local result = Store.call(equipped and "pets.unequip" or "pets.equip", { id = pet.id })
					ctx.explain(result)
				end)
			end
		end
	end

	hatch.click(function()
		if hatching then
			return
		end
		local data = state()
		if data and Store.attr("Money", 0) < data.eggCost then
			ctx.toast("error", "Not enough money for an egg yet")
			Ui.shake(eggCard, 6)
			return
		end
		hatching = true
		hatch.setEnabled(false)
		task.spawn(function()
			for step = 1, 8 do
				egg.Rotation = (step % 2 == 0 and 1 or -1) * (6 + step * 2)
				Sfx.play("tick", 1 + step * 0.05)
				task.wait(0.08)
			end
			egg.Rotation = 0
		end)
		local result = Store.call("pets.hatch")
		task.wait(0.7)
		hatching = false
		hatch.setEnabled(true)
		if not result.ok then
			ctx.explain(result)
		end
	end)

	oddsButton.click(function()
		oddsBox.Visible = true
	end)

	Store.on("pets", function()
		if container.Visible then
			panel.refresh()
		end
	end)
	Store.onAttr("Money", function()
		local data = state()
		if container.Visible and data then
			hatch.setPalette(Store.attr("Money", 0) >= data.eggCost and Theme.green or Theme.red)
		end
	end)

	function panel.show()
		oddsBox.Visible = false
		panel.refresh()
	end

	return panel
end

return PanelPets
