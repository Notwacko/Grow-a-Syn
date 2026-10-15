local Theme = require(script.Parent.Theme)
local Ui = require(script.Parent.Ui)
local Store = require(script.Parent.Store)
local Sfx = require(script.Parent.Sfx)

local Denomination = {}

function Denomination.start(root, ctx)
	local modal = Ui.modal(root, { name = "Denomination", title = "Choose Your Path", size = UDim2.new(0.8, 0, 0.7, 0), max = Vector2.new(860, 470), headerPalette = Theme.purple, dismiss = false })
	modal.close.root.Visible = false
	local body = modal.body
	local intro = Ui.label(body, {
		text = "You have a minyan! Choose the tradition your congregation will grow in. Each stage brings a bigger, more beautiful building.",
		textSize = 20,
		color = Theme.ink,
		stroke = false,
		size = UDim2.new(1, -20, 0, 56),
		position = UDim2.fromOffset(10, 0),
		wrap = true,
		z = 5,
	})
	intro.Font = Theme.bodyFont
	local list = Ui.scroll(body, { size = UDim2.new(1, 0, 1, -64), position = UDim2.fromOffset(0, 62), gap = 12 })

	local function build()
		Ui.clear(list)
		local catalog = Store.catalog()
		local denominations = catalog and catalog.denominations or {}
		for index, den in denominations do
			local card = Ui.card(list, { size = UDim2.new(1, -16, 0, 290), order = index, strokeColor = Theme.purple[2], stroke = 4 })
			Ui.image(card, { image = "synagogue", size = UDim2.fromOffset(110, 110), position = UDim2.fromOffset(16, 16), z = 4 })
			local name = Ui.label(card, { text = den.name, textSize = 36, color = Theme.ink, stroke = false, size = UDim2.new(1, -150, 0, 44), position = UDim2.fromOffset(140, 14), xalign = Enum.TextXAlignment.Left, z = 4 })
			local blurb = Ui.label(card, { text = den.blurb or "", textSize = 20, color = Theme.inkSoft, stroke = false, size = UDim2.new(1, -150, 0, 60), position = UDim2.fromOffset(140, 60), xalign = Enum.TextXAlignment.Left, wrap = true, z = 4 })
			blurb.Font = Theme.bodyFont
			local stages = Ui.frame(card, { name = "Stages", size = UDim2.new(1, -32, 0, 110), position = UDim2.fromOffset(16, 130), z = 4 })
			Ui.make("UIGridLayout", { CellSize = UDim2.new(0.333, -8, 0, 32), CellPadding = UDim2.fromOffset(8, 8), SortOrder = Enum.SortOrder.LayoutOrder }, stages)
			for stageIndex, stageName in den.stages or den.stageNames or {} do
				local pill = Ui.frame(stages, { size = UDim2.fromOffset(100, 32), color = Theme.cream2, transparency = 0, radius = 16, stroke = 2, order = stageIndex, z = 5 })
				Ui.label(pill, { text = stageIndex .. ". " .. stageName, textSize = 15, color = Theme.ink, stroke = false, size = UDim2.new(1, -8, 1, 0), position = UDim2.fromOffset(4, 0), fit = true, z = 6 })
			end
			local choose = Ui.button(card, {
				palette = Theme.purple,
				size = UDim2.fromOffset(300, 56),
				position = UDim2.new(0.5, 0, 1, -12),
				anchor = Vector2.new(0.5, 1),
				text = "Walk this path",
				textSize = 26,
			})
			choose.click(function()
				choose.setEnabled(false)
				local result = Store.remote("RF_ChooseDenomination", den.id)
				if result.ok then
					Sfx.play("win")
					modal.hide(true)
				else
					choose.setEnabled(true)
					ctx.explain(result)
				end
			end)
		end
	end

	local api = {}
	function api.show()
		if ctx.menu and ctx.menu.isOpen() then
			ctx.menu.close()
		end
		Store.refreshCatalog()
		build()
		modal.show()
	end
	function api.hide()
		modal.hide(true)
	end
	function api.isOpen()
		return modal.open
	end
	return api
end

return Denomination
