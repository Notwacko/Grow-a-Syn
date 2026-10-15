local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Theme = require(script.Parent.Theme)
local Ui = require(script.Parent.Ui)
local Store = require(script.Parent.Store)
local Sfx = require(script.Parent.Sfx)
local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))

local Menu = {}

local TABS = {
	{ id = "shop", title = "Shop", icon = "shop", palette = Theme.red, step = Constants.TUTORIAL.GREET },
	{ id = "items", title = "Your Items", icon = "backpack", palette = Theme.orange, step = Constants.TUTORIAL.BUY },
	{ id = "pets", title = "Pets", icon = "paw", palette = Theme.green, step = Constants.TUTORIAL.DONE },
	{ id = "wardrobe", title = "Style", icon = "wardrobe", palette = Theme.purple, step = Constants.TUTORIAL.DONE },
	{ id = "quests", title = "Quests", icon = "quest", palette = Theme.blue, step = Constants.TUTORIAL.DONE },
	{ id = "book", title = "Collection Book", icon = "book", palette = Theme.purple, step = Constants.TUTORIAL.DONE },
	{ id = "store", title = "Store", icon = "gem", palette = Theme.navy, step = Constants.TUTORIAL.DONE },
	{ id = "legacy", title = "Legacy", icon = "legacy", palette = Theme.gold, step = Constants.TUTORIAL.DONE, header = true },
	{ id = "board", title = "Leaderboards", icon = "trophy", palette = Theme.teal, step = Constants.TUTORIAL.DONE, header = true },
	{ id = "settings", title = "Settings", icon = "gear", palette = Theme.gray, step = 0, header = true },
}

local PANEL_MODULES = {
	shop = "PanelShop",
	items = "PanelItems",
	pets = "PanelPets",
	wardrobe = "PanelWardrobe",
	quests = "PanelQuests",
	book = "PanelBook",
	store = "PanelStore",
	legacy = "PanelLegacy",
	board = "PanelBoard",
	settings = "PanelSettings",
}

function Menu.start(root, ctx)
	local menu = { current = nil, panels = {}, tabButtons = {} }
	local modal = Ui.modal(root, {
		name = "Menu",
		title = "Shop",
		size = UDim2.new(0.88, 0, 0.9, 0),
		max = Vector2.new(1200, 800),
		z = 5,
	})
	modal.root.Visible = false
	local compact = Ui.touch
	local tabs = Ui.scroll(modal.body, {
		name = "Tabs",
		size = UDim2.new(0, compact and 92 or 108, 1, 0),
		gap = compact and 8 or 18,
		pad = 4,
		thick = 3,
	})
	tabs.ClipsDescendants = false
	local content = Ui.frame(modal.body, {
		name = "Content",
		size = UDim2.new(1, compact and -104 or -122, 1, 0),
		position = UDim2.fromOffset(compact and 104 or 122, 0),
		z = 3,
	})

	local headerSlot = 0
	for index, tab in TABS do
		if tab.header then
			headerSlot += 1
			local button = Ui.button(modal.panel, {
				name = "Header_" .. tab.id,
				palette = Theme.gray,
				size = UDim2.fromOffset(54, 58),
				position = UDim2.new(1, -(76 + headerSlot * 64), 0, 2),
				anchor = Vector2.new(1, 0),
				icon = tab.icon,
				iconSize = 40,
				radius = 18,
				z = 8,
				onClick = function()
					menu.select(tab.id)
				end,
			})
			local select = Ui.frame(button.root, { name = "Selected", size = UDim2.new(1, 8, 1, 4), position = UDim2.fromOffset(-4, -2), transparency = 1, radius = 20, stroke = 4, z = 9 })
			select.UIStroke.Color = Theme.gold[1]
			select.UIStroke.Transparency = 1
			local badge, badgeText = Ui.badge(button.root, { size = 24, position = UDim2.new(1, 4, 0, -4) })
			badge.Visible = false
			menu.tabButtons[tab.id] = { holder = button.root, button = button, select = select, tab = tab, badge = badge, badgeText = badgeText }
		else
			local buttonSize = compact and 62 or 78
			local holder = Ui.frame(tabs, { name = tab.id, size = UDim2.fromOffset(buttonSize + 12, buttonSize + 22), order = index, z = 3 })
			local button = Ui.button(holder, {
				palette = Theme.gray,
				size = UDim2.fromOffset(buttonSize, buttonSize),
				position = UDim2.fromOffset(6, 0),
				icon = tab.icon,
				iconSize = buttonSize - 22,
				radius = 20,
				onClick = function()
					menu.select(tab.id)
				end,
			})
			local caption = Ui.label(holder, {
				text = tab.title == "Collection Book" and "Book" or (tab.title == "Your Items" and "Items" or tab.title),
				textSize = 17,
				size = UDim2.new(1, 0, 0, 20),
				position = UDim2.new(0, 0, 1, -20),
				stroke = 3,
				fit = true,
				z = 6,
			})
			local select = Ui.frame(holder, {
				name = "Selected",
				size = UDim2.fromOffset(buttonSize + 8, buttonSize + 8),
				position = UDim2.fromOffset(2, -4),
				transparency = 1,
				radius = 22,
				stroke = 4,
				z = 2,
			})
			select.UIStroke.Color = Theme.gold[1]
			select.UIStroke.Transparency = 1
			local badge, badgeText = Ui.badge(holder, { size = 26, position = UDim2.new(1, -2, 0, 0) })
			badge.Visible = false
			menu.tabButtons[tab.id] = { holder = holder, button = button, select = select, tab = tab, badge = badge, badgeText = badgeText, caption = caption }
		end
	end

	local function visibleFor(tab)
		return Store.attr("TutorialStep", 0) >= tab.step
	end

	function menu.refreshTabs()
		for _, entry in menu.tabButtons do
			entry.holder.Visible = visibleFor(entry.tab)
		end
	end

	function menu.setBadge(id, value)
		local entry = menu.tabButtons[id]
		if not entry then
			return
		end
		if value and value ~= 0 and value ~= false then
			entry.badge.Visible = true
			entry.badgeText.Text = type(value) == "number" and tostring(value) or "!"
		else
			entry.badge.Visible = false
		end
	end

	local function loadPanel(id)
		if menu.panels[id] then
			return menu.panels[id]
		end
		local name = PANEL_MODULES[id]
		local container = Ui.frame(content, { name = id, size = UDim2.fromScale(1, 1), visible = false, z = 3 })
		local ok, module = pcall(function()
			return require(script.Parent.Parent.panels[name])
		end)
		local panel
		if ok then
			local built, result = pcall(module.new, container, ctx, menu)
			if built then
				panel = result
			else
				warn("[Menu] panel " .. id .. " failed: " .. tostring(result))
			end
		else
			warn("[Menu] panel module " .. name .. " failed: " .. tostring(module))
		end
		panel = panel or {}
		panel.container = container
		menu.panels[id] = panel
		return panel
	end

	function menu.select(id)
		local entry = menu.tabButtons[id]
		if not entry then
			return
		end
		local previous = menu.current
		if previous and menu.panels[previous] then
			local old = menu.panels[previous]
			old.container.Visible = false
			if old.hide then
				old.hide()
			end
		end
		menu.current = id
		for key, other in menu.tabButtons do
			local selected = key == id
			other.button.setPalette(selected and other.tab.palette or Theme.gray)
			other.select.UIStroke.Transparency = selected and 0 or 1
		end
		modal.title.Text = entry.tab.title
		local panel = loadPanel(id)
		panel.container.Visible = true
		if panel.show then
			panel.show()
		end
	end

	function menu.open(id)
		menu.refreshTabs()
		local target = id or menu.current or "shop"
		if not menu.tabButtons[target] or not visibleFor(menu.tabButtons[target].tab) then
			target = "shop"
		end
		modal.show()
		menu.select(target)
	end

	function menu.close()
		modal.hide()
	end

	function menu.isOpen()
		return modal.open
	end

	modal.onHide = function()
		local old = menu.current and menu.panels[menu.current]
		if old and old.hide then
			old.hide()
		end
		if ctx.hud then
			ctx.hud.setVisible(true)
		end
		menu.closed = os.clock()
	end
	modal.onShow = function()
		if ctx.hud then
			ctx.hud.setVisible(false)
		end
	end

	menu.modal = modal
	menu.content = content
	return menu
end

return Menu
