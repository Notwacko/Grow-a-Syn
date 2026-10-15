local ui = script.Parent.Parent.ui
local Theme = require(ui.Theme)
local Ui = require(ui.Ui)
local Util = require(ui.Util)
local Store = require(ui.Store)

local PanelBoard = {}

local MEDALS = { Theme.gold, Theme.gray, Theme.orange }

function PanelBoard.new(container, ctx, menu)
	local panel = {}
	local running = false
	local resetLabel = Ui.label(container, { text = "", textSize = 20, color = Theme.inkSoft, stroke = false, size = UDim2.new(1, 0, 0, 30), position = UDim2.fromOffset(0, 0), z = 4 })
	resetLabel.Font = Theme.bodyFont
	local columns = Ui.frame(container, { size = UDim2.new(1, 0, 1, -36), position = UDim2.fromOffset(0, 36), z = 3 })
	Ui.make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 14), HorizontalAlignment = Enum.HorizontalAlignment.Center }, columns)

	function panel.refresh()
		local data = Store.get("leaderboard")
		if not data then
			return
		end
		Ui.clear(columns)
		resetLabel.Text = "Weekly boards reset in " .. Util.words(data.resetsAt - Store.now())
		for index, board in data.boards do
			local card = Ui.card(columns, { size = UDim2.new(0.5, -8, 1, 0), order = index, color = Theme.cream2 })
			Ui.label(card, { text = board.title, textSize = 28, color = Theme.ink, stroke = false, size = UDim2.new(1, 0, 0, 44), position = UDim2.fromOffset(0, 6), z = 5 })
			local list = Ui.scroll(card, { size = UDim2.new(1, -16, 1, -112), position = UDim2.fromOffset(8, 52), gap = 6, pad = 2 })
			if #board.entries == 0 then
				Ui.label(list, { text = "No scores yet this week.\nBe the first!", textSize = 22, color = Theme.inkSoft, stroke = false, size = UDim2.new(1, 0, 0, 100), wrap = true, z = 5 })
			end
			for rank, entry in board.entries do
				local mine = entry.userId == Store.player.UserId
				local row = Ui.frame(list, { size = UDim2.new(1, -8, 0, 44), color = mine and Theme.gold[1] or Theme.cardBase, transparency = 0, radius = 12, stroke = 3, order = rank, z = 5 })
				local medal = MEDALS[rank]
				local badge = Ui.frame(row, { size = UDim2.fromOffset(34, 34), position = UDim2.new(0, 6, 0.5, 0), anchor = Vector2.new(0, 0.5), color = medal and medal[1] or Theme.cream2, transparency = 0, radius = 17, stroke = 2, z = 6 })
				Ui.label(badge, { text = tostring(rank), textSize = 20, size = UDim2.fromScale(1, 1), color = medal and Theme.white or Theme.ink, stroke = medal and 2 or false, z = 7 })
				local name = Ui.label(row, { text = entry.name, textSize = 20, color = Theme.ink, stroke = false, size = UDim2.new(1, -150, 1, 0), position = UDim2.fromOffset(48, 0), xalign = Enum.TextXAlignment.Left, fit = true, z = 6 })
				name.Font = Theme.titleFont
				local score = Ui.label(row, { text = Util.short(entry.score), textSize = 22, color = Theme.ink, stroke = false, size = UDim2.fromOffset(90, 44), position = UDim2.new(1, -96, 0, 0), xalign = Enum.TextXAlignment.Right, fit = true, z = 6 })
				score.Font = Theme.titleFont
			end
			local mineRow = Ui.frame(card, { size = UDim2.new(1, -20, 0, 46), position = UDim2.new(0, 10, 1, -54), color = Theme.ink, transparency = 0, radius = 14, z = 5 })
			Ui.label(mineRow, { text = "You: " .. Util.short(board.mine) .. " " .. board.unit, textSize = 22, size = UDim2.new(1, -10, 1, 0), position = UDim2.fromOffset(5, 0), fit = true, z = 6 })
		end
	end

	Store.on("leaderboard", function()
		if running then
			panel.refresh()
		end
	end)

	function panel.show()
		running = true
		Store.call("leaderboard.refresh")
		panel.refresh()
	end

	function panel.hide()
		running = false
	end

	return panel
end

return PanelBoard
