local ui = script.Parent.Parent.ui
local Theme = require(ui.Theme)
local Ui = require(ui.Ui)
local Store = require(ui.Store)
local Sfx = require(ui.Sfx)

local PanelSettings = {}

function PanelSettings.new(container, ctx, menu)
	local panel = {}
	local scroll = Ui.scroll(container, { gap = 10, pad = 6 })

	local function toggleRow(order, title, blurb, getter, setter)
		local row = Ui.card(scroll, { size = UDim2.new(1, -12, 0, 84), order = order })
		local label = Ui.label(row, { text = title, textSize = 26, color = Theme.ink, stroke = false, size = UDim2.new(1, -170, 0, 34), position = UDim2.fromOffset(16, 8), xalign = Enum.TextXAlignment.Left, fit = true, z = 4 })
		local sub = Ui.label(row, { text = blurb, textSize = 16, color = Theme.inkSoft, stroke = false, size = UDim2.new(1, -170, 0, 36), position = UDim2.fromOffset(16, 42), xalign = Enum.TextXAlignment.Left, wrap = true, z = 4 })
		sub.Font = Theme.bodyFont
		local switch = Ui.button(row, { palette = Theme.green, size = UDim2.fromOffset(120, 54), position = UDim2.new(1, -16, 0.5, -2), anchor = Vector2.new(1, 0.5), text = "On", textSize = 24 })
		local function paint()
			local on = getter()
			switch.setText(on and "On" or "Off")
			switch.setPalette(on and Theme.green or Theme.gray)
		end
		switch.click(function()
			setter(not getter())
			paint()
		end)
		paint()
	end

	local function setting(key, default)
		local data = Store.get("settings")
		if data and data[key] ~= nil then
			return data[key]
		end
		return default
	end

	local function save(key, value)
		Store.call("settings.set", { key = key, value = value })
	end

	function panel.build()
		Ui.clear(scroll)
		toggleRow(1, "Sound Effects", "Button clicks and reward sounds", function()
			return not Sfx.isMuted()
		end, function(value)
			Sfx.setMuted(not value)
			save("sfx", value)
		end)
		toggleRow(2, "Colorblind Friendly Colors", "Changes rarity colors so they are easier to tell apart", function()
			return Theme.useColorblind
		end, function(value)
			Theme.useColorblind = value
			save("colorblind", value)
			ctx.toast("info", value and "Colorblind colors on" or "Colorblind colors off")
		end)
		toggleRow(3, "Show Pets", "Turn off to hide pets and keep the game smooth", function()
			return setting("pets", true)
		end, function(value)
			save("pets", value)
			if ctx.setPetsVisible then
				ctx.setPetsVisible(value)
			end
		end)
		local about = Ui.card(scroll, { size = UDim2.new(1, -12, 0, 190), order = 10, color = Theme.cream2 })
		local title = Ui.label(about, { text = "Grow a Synagogue", textSize = 30, color = Theme.ink, stroke = false, size = UDim2.new(1, -24, 0, 40), position = UDim2.fromOffset(12, 8), xalign = Enum.TextXAlignment.Left, z = 4 })
		local text = Ui.label(about, {
			text = "Made with love by a Jewish team as a friendly, family-safe community game. We treat our traditions with respect: Torah scrolls can never be sold or thrown away, and nothing in the game involves free text chat from other players.\n\nHave an idea? Tell us in the game page comments!",
			textSize = 18,
			color = Theme.inkSoft,
			stroke = false,
			size = UDim2.new(1, -24, 0, 130),
			position = UDim2.fromOffset(12, 50),
			xalign = Enum.TextXAlignment.Left,
			yalign = Enum.TextYAlignment.Top,
			wrap = true,
			z = 4,
		})
		text.Font = Theme.bodyFont
		title.Font = Theme.titleFont
	end

	function panel.show()
		panel.build()
	end

	Store.on("settings", function()
		if container.Visible then
			panel.build()
		end
	end)

	return panel
end

return PanelSettings
