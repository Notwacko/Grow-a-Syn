local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ui = script.Parent.Parent.ui
local Theme = require(ui.Theme)
local Ui = require(ui.Ui)
local Util = require(ui.Util)
local Store = require(ui.Store)
local ItemView = require(ui.ItemView)
local Sfx = require(ui.Sfx)
local ItemCatalog = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ItemCatalog"))

local PanelBook = {}

function PanelBook.new(container, ctx, menu)
	local panel = {}
	local running = false

	local header = Ui.frame(container, { name = "Header", size = UDim2.new(1, 0, 0, 62), z = 4 })
	local bar = Ui.bar(header, { size = UDim2.new(1, -240, 0, 38), position = UDim2.fromOffset(4, 4), height = 38, palette = Theme.purple, text = "0 / 48", textSize = 22 })
	local bonusPill, bonusLabel = Ui.pill(header, { size = UDim2.fromOffset(220, 46), position = UDim2.new(1, -4, 0, 0), anchor = Vector2.new(1, 0), icon = "bolt", text = "+0% income", height = 46, textSize = 22 })
	local hint = Ui.label(header, { text = "Discover every item to earn permanent income bonuses.", textSize = 16, color = Theme.inkSoft, stroke = false, size = UDim2.new(1, -240, 0, 20), position = UDim2.fromOffset(4, 44), xalign = Enum.TextXAlignment.Left, z = 4 })
	hint.Font = Theme.bodyFont

	local milestones = Ui.frame(container, { name = "Milestones", size = UDim2.new(1, 0, 0, 96), position = UDim2.fromOffset(0, 66), z = 4 })
	Ui.make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }, milestones)
	local scroll = Ui.scroll(container, { size = UDim2.new(1, 0, 1, -168), position = UDim2.fromOffset(0, 166), gap = 10, pad = 4 })

	local function milestoneCard(entry, order)
		local card = Ui.card(milestones, { size = UDim2.fromOffset(170, 90), order = order, strokeColor = entry.claimed and Theme.green[2] or (entry.ready and Theme.gold[2] or Theme.ink), stroke = entry.ready and not entry.claimed and 4 or 3 })
		Ui.label(card, { text = entry.percent .. "%", textSize = 26, color = Theme.ink, stroke = false, size = UDim2.new(0, 60, 0, 34), position = UDim2.fromOffset(8, 6), z = 4 })
		local rewardText = Util.minutes(entry.minutes) .. " income" .. (entry.itemName and ("\n+ " .. entry.itemName) or "")
		local label = Ui.label(card, { text = rewardText, textSize = 13, color = Theme.inkSoft, stroke = false, size = UDim2.new(1, -76, 0, 40), position = UDim2.fromOffset(70, 6), wrap = true, fit = true, z = 4 })
		label.Font = Theme.bodyFont
		local button = Ui.button(card, {
			palette = entry.claimed and Theme.gray or (entry.ready and Theme.green or Theme.gray),
			size = UDim2.new(1, -16, 0, 34),
			position = UDim2.new(0.5, 0, 1, -6),
			anchor = Vector2.new(0.5, 1),
			text = entry.claimed and "Claimed" or (entry.ready and "Claim" or "Locked"),
			textSize = 18,
			enabled = entry.ready and not entry.claimed,
		})
		button.click(function()
			button.setEnabled(false)
			local result = Store.call("collection.claim", { percent = entry.percent })
			if result.ok then
				Sfx.play("coin")
			else
				ctx.explain(result)
			end
		end)
	end

	function panel.refresh()
		local data = Store.get("collection")
		if not data then
			return
		end
		local found = {}
		for _, id in data.found do
			found[id] = true
		end
		bar.set(#data.found / data.total, string.format("%d / %d discovered", #data.found, data.total))
		bonusLabel.Text = string.format("+%s%% income", Util.short(data.bonus * 100))
		Ui.clear(milestones)
		for index, entry in data.milestones do
			milestoneCard(entry, index)
		end
		Ui.clear(scroll)
		for index, category in ItemCatalog.CATEGORIES do
			local row = Ui.card(scroll, { size = UDim2.new(1, -12, 0, 106), order = index, color = Theme.cardBase })
			Ui.image(row, { image = "item_" .. category.id, size = UDim2.fromOffset(46, 46), position = UDim2.fromOffset(10, 10), z = 4 })
			local title = Ui.label(row, { text = category.name, textSize = 17, color = Theme.ink, stroke = false, size = UDim2.fromOffset(110, 40), position = UDim2.fromOffset(0, 58), wrap = true, fit = true, z = 4 })
			if category.id == "torah" then
				title.Text = "Sefer Torah"
				local sub = Ui.label(row, { text = "Dedicated", textSize = 14, color = Theme.gold[2], stroke = false, size = UDim2.fromOffset(110, 18), position = UDim2.fromOffset(0, 84), z = 4 })
				sub.Font = Theme.bodyFont
			end
			local slots = Ui.frame(row, { size = UDim2.new(1, -130, 1, -12), position = UDim2.fromOffset(122, 6), z = 4 })
			Ui.make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }, slots)
			for rarityIndex, rarityId in Theme.rarityOrder do
				local id = category.id .. "_" .. rarityId
				local info = ItemCatalog.item(id)
				local unlocked = found[id] == true
				local color = Theme.rarityColor(rarityId)
				local cell = Ui.frame(slots, { size = UDim2.fromOffset(82, 90), color = unlocked and Theme.cream or Theme.cream2, transparency = 0, radius = 12, stroke = 3, order = rarityIndex, z = 5 })
				cell.UIStroke.Color = unlocked and color or Theme.disabled
				local icon = Ui.image(cell, { image = "item_" .. category.id, size = UDim2.fromOffset(56, 56), position = UDim2.new(0.5, 0, 0, 6), anchor = Vector2.new(0.5, 0), z = 6 })
				if not unlocked then
					icon.ImageColor3 = Color3.new(0, 0, 0)
					icon.ImageTransparency = 0.6
				end
				local name = Ui.label(cell, { text = unlocked and Theme.rarity[rarityId].name or "???", textSize = 13, color = unlocked and color or Theme.muted, stroke = false, size = UDim2.new(1, -4, 0, 16), position = UDim2.fromOffset(2, 64), fit = true, z = 6 })
				name.Font = Theme.titleFont
				if unlocked then
					ItemView.pips(cell, rarityId, { position = UDim2.new(0, 0, 1, -10), frame = UDim2.new(1, 0, 0, 7), size = 6, z = 7 })
				end
				local hit = Ui.make("TextButton", { Text = "", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 12 }, cell)
				hit.Activated:Connect(function()
					ctx.toast(unlocked and "info" or "info", unlocked and (info.name .. " discovered") or ("Find the " .. info.name .. " to unlock this"))
				end)
			end
		end
	end

	Store.on("collection", function()
		if running then
			panel.refresh()
		end
	end)

	function panel.show()
		running = true
		panel.refresh()
	end

	function panel.hide()
		running = false
	end

	return panel
end

return PanelBook
