local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ui = script.Parent.Parent.ui
local Theme = require(ui.Theme)
local Ui = require(ui.Ui)
local Util = require(ui.Util)
local Store = require(ui.Store)
local ItemView = require(ui.ItemView)
local Sfx = require(ui.Sfx)
local ItemCatalog = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ItemCatalog"))

local PanelLegacy = {}

function PanelLegacy.new(container, ctx, menu)
	local panel = {}
	local running = false
	local chosen = {}
	local confirmUntil = 0

	local scroll = Ui.scroll(container, { gap = 10, pad = 6 })

	local function card(height, order, props)
		props = props or {}
		return Ui.card(scroll, { size = UDim2.new(1, -12, 0, height), order = order, color = props.color, strokeColor = props.strokeColor, stroke = props.stroke })
	end

	local function text(parent, content, props)
		local label = Ui.label(parent, {
			text = content,
			textSize = props.size or 19,
			color = props.color or Theme.ink,
			stroke = false,
			size = props.frame or UDim2.new(1, -24, 0, 30),
			position = props.position or UDim2.fromOffset(12, 0),
			wrap = true,
			xalign = props.xalign or Enum.TextXAlignment.Left,
			yalign = props.yalign,
			z = 5,
		})
		label.Font = props.font or Theme.bodyFont
		return label
	end

	function panel.refresh()
		local data = Store.get("legacy")
		if not data then
			return
		end
		Ui.clear(scroll)
		local hero = card(150, 1, { color = Theme.cream2, strokeColor = Theme.gold[2], stroke = 5 })
		Ui.image(hero, { image = "legacy", size = UDim2.fromOffset(120, 120), position = UDim2.fromOffset(14, 14), z = 5 })
		text(hero, "Legacy", { size = 38, font = Theme.titleFont, frame = UDim2.new(1, -170, 0, 46), position = UDim2.fromOffset(150, 10) })
		text(hero, string.format("Legacy Points: %s     Income bonus: x%s     Legacies: %d", Util.short(data.points), Util.mult(data.mult), data.resets), { size = 20, frame = UDim2.new(1, -170, 0, 28), position = UDim2.fromOffset(150, 58) })
		text(hero, "Pass your synagogue to the next generation. You start over smaller, but every Legacy Point makes all your future income bigger, forever.", { size = 17, frame = UDim2.new(1, -170, 0, 56), position = UDim2.fromOffset(150, 86), color = Theme.inkSoft })

		if not data.unlocked then
			local locked = card(110, 2)
			text(locked, string.format("Reach stage %d (Ashkenazi Orthodox) to unlock Legacy.", data.unlockTier - 1), { size = 24, frame = UDim2.new(1, -24, 1, 0), position = UDim2.fromOffset(12, 0), font = Theme.titleFont, xalign = Enum.TextXAlignment.Center })
			return
		end

		local now = card(150, 2)
		text(now, "If you begin your Legacy right now:", { size = 22, font = Theme.titleFont, frame = UDim2.new(1, -24, 0, 30), position = UDim2.fromOffset(12, 8) })
		text(now, string.format("+%s Legacy Points  (income x%s becomes x%s)", Util.short(data.gain), Util.mult(data.mult), Util.mult(data.nextMult)), { size = 24, color = Theme.green[2], font = Theme.titleFont, frame = UDim2.new(1, -24, 0, 34), position = UDim2.fromOffset(12, 44) })
		if data.boost then
			text(now, "Legacy Boost is active: +25% points!", { size = 18, color = Theme.purple[2], frame = UDim2.new(1, -24, 0, 24), position = UDim2.fromOffset(12, 80) })
		end
		local bar = Ui.bar(now, { size = UDim2.new(1, -24, 0, 28), position = UDim2.new(0, 12, 1, -40), height = 28, palette = Theme.gold, text = "Earn more this run for extra points" })
		local fraction = math.clamp(data.run / math.max(data.nextPointAt, 1), 0, 1)
		bar.fill.Size = UDim2.fromScale(fraction, 1)
		bar.label.Text = string.format("Next point at %s earned this run", Util.short(data.nextPointAt))

		local heir = card(210, 3)
		text(heir, string.format("Heirlooms: choose up to %d items to keep (%d chosen). Torah scrolls are always kept.", data.heirloomSlots, #chosen), { size = 19, font = Theme.titleFont, frame = UDim2.new(1, -24, 0, 30), position = UDim2.fromOffset(12, 6) })
		local list = Ui.scroll(heir, { horizontal = true, size = UDim2.new(1, -16, 0, 150), position = UDim2.fromOffset(8, 46), gap = 8, pad = 4 })
		local inventory = Store.inventory()
		local items = {}
		for _, entry in inventory and inventory.items or {} do
			local info = ItemCatalog.item(entry.id)
			if info and info.category ~= "torah" then
				table.insert(items, { entry = entry, info = info })
			end
		end
		table.sort(items, function(a, b)
			return ItemCatalog.bonusOf(a.info, 1, a.entry.mutation, a.entry.star) > ItemCatalog.bonusOf(b.info, 1, b.entry.mutation, b.entry.star)
		end)
		for index, data2 in items do
			if index > 40 then
				break
			end
			local entry, info = data2.entry, data2.info
			local picked = table.find(chosen, entry.uid) ~= nil
			local cell = Ui.card(list, { size = UDim2.fromOffset(110, 138), order = index, strokeColor = picked and Theme.gold[1] or Theme.rarityColor(info.rarity), stroke = picked and 5 or 3 })
			Ui.image(cell, { image = ItemView.icon(info), size = UDim2.fromOffset(70, 70), position = UDim2.new(0.5, 0, 0, 8), anchor = Vector2.new(0.5, 0), z = 5 })
			Ui.label(cell, { text = ItemView.name(info, entry.mutation, entry.star), textSize = 13, color = Theme.ink, stroke = false, size = UDim2.new(1, -6, 0, 40), position = UDim2.fromOffset(3, 82), wrap = true, fit = true, z = 5 })
			if picked then
				local badge = Ui.frame(cell, { size = UDim2.fromOffset(60, 20), position = UDim2.new(0.5, 0, 1, -20), anchor = Vector2.new(0.5, 0), color = Theme.gold[2], transparency = 0, radius = 10, stroke = 2, z = 8 })
				Ui.label(badge, { text = "Keeping", textSize = 13, size = UDim2.fromScale(1, 1), fit = true, stroke = 2, z = 9 })
			end
			local hit = Ui.make("TextButton", { Text = "", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 12 }, cell)
			hit.Activated:Connect(function()
				Sfx.play("click")
				local at = table.find(chosen, entry.uid)
				if at then
					table.remove(chosen, at)
				elseif #chosen < data.heirloomSlots then
					table.insert(chosen, entry.uid)
				else
					ctx.toast("info", "All heirloom slots are used")
				end
				panel.refresh()
			end)
		end
		if #items == 0 then
			Ui.label(list, { text = "No items to keep yet", textSize = 20, color = Theme.inkSoft, stroke = false, size = UDim2.fromOffset(300, 120), z = 5 })
		end

		local info = card(168, 4)
		text(info, "What happens", { size = 22, font = Theme.titleFont, frame = UDim2.new(1, -24, 0, 28), position = UDim2.fromOffset(12, 6) })
		text(info, "Resets: money (you get a head start), building stage, land, station levels, items and congregation.\nStays: Torah scrolls, heirlooms, your Collection Book, Style, pets, passes and Legacy Points.", { size = 18, frame = UDim2.new(1, -24, 0, 120), position = UDim2.fromOffset(12, 38), yalign = Enum.TextYAlignment.Top })

		local actionRow = Ui.frame(scroll, { size = UDim2.new(1, -12, 0, 80), order = 5, z = 3 })
		local ready = data.gain >= 1
		local armed = os.clock() < confirmUntil
		local begin = Ui.button(actionRow, {
			palette = armed and Theme.red or (ready and Theme.gold or Theme.gray),
			size = UDim2.fromOffset(420, 70),
			position = UDim2.fromScale(0.5, 0.5),
			anchor = Vector2.new(0.5, 0.5),
			text = armed and "Tap again to confirm" or (ready and "Begin Legacy" or "Not enough yet"),
			textSize = 32,
			enabled = ready,
		})
		begin.click(function()
			if os.clock() > confirmUntil then
				confirmUntil = os.clock() + 6
				panel.refresh()
				task.delay(6.1, function()
					if running then
						panel.refresh()
					end
				end)
				return
			end
			confirmUntil = 0
			local keep = {}
			for _, uid in chosen do
				table.insert(keep, uid)
			end
			chosen = {}
			local result = Store.call("legacy.confirm", { keep = keep })
			if result.ok then
				Sfx.play("win")
				menu.close()
			else
				ctx.explain(result)
				panel.refresh()
			end
		end)
	end

	Store.on("legacy", function()
		if running then
			panel.refresh()
		end
	end)

	function panel.show()
		running = true
		chosen = {}
		confirmUntil = 0
		Store.refreshInventory(true)
		Store.call("legacy.info")
		panel.refresh()
		task.spawn(function()
			while running and container.Parent do
				task.wait(3)
				if running then
					Store.call("legacy.info")
				end
			end
		end)
	end

	function panel.hide()
		running = false
	end

	return panel
end

return PanelLegacy
