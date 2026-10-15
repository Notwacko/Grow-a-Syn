-- Inventory grid with category filters, equip/unequip into slots, and the 3-identical-items merge flow.
-- There is deliberately NO sell, discard or delete control anywhere in this file (Torah scrolls can never be removed).
local Theme = require(script.Parent.Theme)
local C = require(script.Parent.Components)
local Net = require(script.Parent.Net)
local Sound = require(script.Parent.Sound)
local Contract = require(script.Parent.Contract)

local Color, Space = Theme.Color, Theme.Space

local InventoryUI = {}

local CARD_SIZE = UDim2.fromOffset(112, 152)
local TOP_ROW = Space.Tab + Space.S

local function displayName(info, entry)
	local mutation = entry and entry.mutation
	if mutation then
		return (string.upper(string.sub(mutation, 1, 1)) .. string.sub(mutation, 2)) .. " " .. info.name
	end
	return info.name
end

function InventoryUI.new(ctx)
	local self = { IsOpen = false }
	local popup, grid, hintRow, hintText, mergeConfirm, mergeToggle, filterScroll
	local filter = "all"
	local mergeMode = false
	local selected = {} -- uid -> true
	local selectedList = {}
	local changedConn
	local setMerge

	local function itemInfo(entry)
		return Net.getCatalog().byId[entry.id]
	end

	local function layoutGrid()
		local y = TOP_ROW + (mergeMode and (Space.Tab + Space.S) or 0)
		hintRow.Visible = mergeMode
		grid.Position = UDim2.fromOffset(0, y)
		grid.Size = UDim2.new(1, 0, 1, -y)
	end

	local function refreshHint()
		if not mergeMode then
			return
		end
		hintText.Text = #selectedList == 0 and "Pick 3 identical items" or (#selectedList .. " / 3 selected")
		mergeConfirm:setEnabled(#selectedList == 3)
	end

	local function clearSelection()
		selected, selectedList = {}, {}
	end

	local function openPreview()
		local catalog = Net.getCatalog()
		local first
		for _, entry in Net.getInventory() do
			if entry.uid == selectedList[1] then
				first = entry
			end
		end
		local info = first and itemInfo(first)
		if not info then
			return
		end
		local result = info.mergesTo and catalog.byId[info.mergesTo]
		local dialog = C.popup(ctx.layers.popup, {
			title = "Merge 3 items?",
			color = Color.Yellow,
			closable = false,
			size = UDim2.new(1, -Space.XL * 2, 0, 292),
			maxSize = Vector2.new(420, 292),
		})
		local row = C.row(dialog.Body, { size = UDim2.new(1, 0, 0, 120), alignX = Enum.HorizontalAlignment.Center, gap = Space.S, name = "Preview" })
		for i = 1, 3 do
			local cell = C.card(row, { size = UDim2.fromOffset(64, 80), order = i, accent = Theme.rarityColor(info.rarity, catalog) })
			C.modelView(cell.Frame, info.model, { size = UDim2.new(1, -Space.S, 1, -Space.S), position = UDim2.fromOffset(Space.XS, Space.XS), rarity = info.rarity })
		end
		C.text(row, { text = "➜", size = "L", sizeU = UDim2.fromOffset(Space.XXL, 80), order = 4 })
		local out = C.card(row, { size = UDim2.fromOffset(80, 96), order = 5, accent = result and Theme.rarityColor(result.rarity, catalog) or Color.Yellow })
		if result then
			C.modelView(out.Frame, result.model, { size = UDim2.new(1, -Space.S, 1, -Space.S), position = UDim2.fromOffset(Space.XS, Space.XS), rarity = result.rarity })
		else
			C.text(out.Frame, { text = "?", size = "XL" })
		end
		C.text(dialog.Body, {
			text = result and (result.name .. " (" .. (result.rarity or "") .. ")") or "A better item",
			size = "S",
			wrap = true,
			sizeU = UDim2.new(1, 0, 0, Space.XXL),
			position = UDim2.fromOffset(0, 124),
		})
		local buttons = C.row(dialog.Body, { size = UDim2.new(1, 0, 0, Space.Tab), position = UDim2.new(0, 0, 1, -Space.Tab), alignX = Enum.HorizontalAlignment.Center, gap = Space.M })
		C.button(buttons, { text = "Cancel", color = Color.Grey, size = UDim2.fromOffset(136, Space.Tab), order = 1, onClick = function() dialog:Close() end })
		local go
		go = C.button(buttons, {
			text = "Merge!",
			color = Color.Green,
			size = UDim2.fromOffset(136, Space.Tab),
			order = 2,
			onClick = function()
				go:setEnabled(false)
				local res = Net.merge(table.clone(selectedList))
				dialog:Close()
				if res.ok then
					Sound.play("merge")
					ctx.toast("Merged! Look at your new item.", "success")
					clearSelection()
					if popup and not popup.closed then
						C.sparkleBurst(popup.Root, UDim2.fromScale(0.5, 0.5), 20)
					end
				else
					Sound.play("error")
					ctx.toast(Contract.Reasons[res.reason] or Contract.Reasons.default, "error")
				end
			end,
		})
	end

	local function openDetail(entry)
		local catalog = Net.getCatalog()
		local info = itemInfo(entry)
		if not info then
			return
		end
		local slots = Contract.SlotsByCategory[info.category] or {}
		local used = {}
		for _, other in Net.getInventory() do
			if other.slot then
				used[other.slot] = true
			end
		end
		local dialog = C.popup(ctx.layers.popup, {
			title = displayName(info, entry),
			color = Theme.rarityColor(info.rarity, catalog),
			size = UDim2.new(1, -Space.XL * 2, 0, 320),
			maxSize = Vector2.new(420, 320),
		})
		C.modelView(dialog.Body, info.model, { size = UDim2.new(1, 0, 0, 112), rarity = info.rarity, mutation = entry.mutation })
		C.text(dialog.Body, {
			text = (Contract.CategoryNames[info.category] or "") .. "  •  " .. (info.rarity or "") .. (entry.growth and entry.growth < 1 and string.format("  •  growing %d%%", math.floor(entry.growth * 100)) or ""),
			size = "S",
			sizeU = UDim2.new(1, 0, 0, Space.L),
			position = UDim2.fromOffset(0, 116),
		})
		local function act(res, okText)
			if res.ok then
				ctx.toast(okText, "success")
				dialog:Close()
			else
				Sound.play("error")
				ctx.toast(Contract.Reasons[res.reason] or Contract.Reasons.default, "error")
			end
		end
		if entry.slot then
			C.text(dialog.Body, { text = "In " .. entry.slot:gsub("^Slot_", ""), size = "S", sizeU = UDim2.new(1, 0, 0, Space.L), position = UDim2.fromOffset(0, 138) })
			C.button(dialog.Body, {
				text = "Unequip",
				color = Color.Orange,
				size = UDim2.fromOffset(160, Space.Tab),
				anchor = Vector2.new(0.5, 0),
				position = UDim2.new(0.5, 0, 0, 160),
				onClick = function()
					act(Net.unequip(entry.uid), "Item put back in your bag.")
				end,
			})
		else
			local list = C.scroll(dialog.Body, { horizontal = true, size = UDim2.new(1, 0, 0, Space.Tab), position = UDim2.fromOffset(0, 160) })
			C.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, Space.S), SortOrder = Enum.SortOrder.LayoutOrder }, list)
			C.text(dialog.Body, { text = "Place it in a slot:", size = "S", sizeU = UDim2.new(1, 0, 0, Space.L), position = UDim2.fromOffset(0, 138) })
			for i, slot in slots do
				local btn = C.button(list, {
					text = tostring(i),
					color = used[slot] and Color.Grey or Color.Green,
					size = UDim2.fromOffset(Space.Tab, Space.Tab),
					order = i,
					onClick = function()
						act(Net.equip(entry.uid, slot), "Placed in your synagogue!")
					end,
				})
			end
		end
	end

	local function onCardTap(entry, card)
		if not mergeMode then
			openDetail(entry)
			return
		end
		if selected[entry.uid] then
			selected[entry.uid] = nil
			table.remove(selectedList, table.find(selectedList, entry.uid))
		else
			if #selectedList >= 3 then
				return
			end
			local firstId
			for _, other in Net.getInventory() do
				if other.uid == selectedList[1] then
					firstId = other.id
				end
			end
			if firstId and firstId ~= entry.id then
				ctx.toast("Pick 3 identical items.", "info")
				return
			end
			selected[entry.uid] = true
			table.insert(selectedList, entry.uid)
		end
		card.Frame.UIStroke.Color = selected[entry.uid] and Color.Yellow or card.accent
		card.check.Visible = selected[entry.uid] == true
		refreshHint()
	end

	local function rebuild()
		if not popup or popup.closed then
			return
		end
		local catalog = Net.getCatalog()
		local inventory = Net.getInventory()
		if not popup or popup.closed then
			return
		end
		for _, child in grid:GetChildren() do
			if child:IsA("Frame") then
				child:Destroy()
			end
		end
		-- drop selections that no longer exist
		local alive = {}
		for _, entry in inventory do
			alive[entry.uid] = true
		end
		for i = #selectedList, 1, -1 do
			if not alive[selectedList[i]] then
				selected[selectedList[i]] = nil
				table.remove(selectedList, i)
			end
		end
		local shown = 0
		for i, entry in inventory do
			local info = itemInfo(entry)
			if info and (filter == "all" or info.category == filter) then
				shown += 1
				local accent = Theme.rarityColor(info.rarity, catalog)
				local card = C.card(grid, { order = i, accent = selected[entry.uid] and Color.Yellow or accent, name = entry.uid })
				card.accent = accent
				C.modelView(card.Frame, info.model, { size = UDim2.new(1, -Space.S, 0, 72), position = UDim2.fromOffset(Space.XS, Space.XS), rarity = info.rarity, mutation = entry.mutation })
				C.text(card.Frame, { text = displayName(info, entry), size = "XS", wrap = true, sizeU = UDim2.new(1, -Space.S, 0, 32), position = UDim2.fromOffset(Space.XS, 80) })
				if entry.slot then
					local tag = C.pill(card.Frame, { text = (entry.growth and entry.growth < 1) and string.format("Growing %d%%", math.floor(entry.growth * 100)) or "Placed", color = Color.Green, textSize = "XS" })
					tag.Root.Size = UDim2.fromOffset(0, Space.XL)
					tag.Root.AnchorPoint = Vector2.new(0.5, 1)
					tag.Root.Position = UDim2.new(0.5, 0, 1, -Space.XS)
				else
					C.text(card.Frame, { text = info.rarity or "", size = "XS", color = accent, sizeU = UDim2.new(1, 0, 0, Space.L), anchor = Vector2.new(0, 1), position = UDim2.new(0, 0, 1, -Space.S) })
				end
				card.check = C.text(card.Frame, { text = "✔", size = "L", color = Color.Yellow, sizeU = UDim2.fromOffset(Space.XXL, Space.XXL), position = UDim2.fromOffset(0, 0), z = 6 })
				card.check.Visible = selected[entry.uid] == true
				local hit = C.new("TextButton", { Text = "", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 8 }, card.Frame)
				hit.Activated:Connect(function()
					Sound.play("click")
					onCardTap(entry, card)
				end)
			end
		end
		if shown == 0 then
			C.text(grid, { text = "Nothing here yet. Visit the Shop!", size = "S", wrap = true, sizeU = UDim2.new(1, 0, 0, Space.XXL) })
		end
		refreshHint()
	end

	local function rebuildFilters()
		local inventory = Net.getInventory()
		if not popup or popup.closed then
			return
		end
		for _, child in filterScroll:GetChildren() do
			if child:IsA("Frame") then
				child:Destroy()
			end
		end
		local present = { all = true }
		for _, entry in inventory do
			local info = itemInfo(entry)
			if info then
				present[info.category] = true
			end
		end
		local order = { "all", "torah", "ark", "siddur", "menorah", "kiddush_cup", "chandelier", "ornament", "holiday_decor" }
		local index = 0
		for _, key in order do
			if present[key] then
				index += 1
				C.button(filterScroll, {
					text = key == "all" and "All" or (Contract.CategoryIcons[key] .. " " .. Contract.CategoryNames[key]),
					textSize = "S",
					color = key == filter and Color.Yellow or Color.Blue,
					size = UDim2.fromOffset(key == "all" and 72 or 136, Space.Tab),
					order = index,
					onClick = function()
						filter = key
						rebuildFilters()
						rebuild()
					end,
				})
			end
		end
	end

	setMerge = function(on)
		mergeMode = on
		clearSelection()
		mergeToggle:setColor(on and Color.Orange or Color.Purple)
		layoutGrid()
		rebuild()
	end

	function self:Open(startMerge)
		if self.IsOpen then
			if startMerge ~= nil and startMerge ~= mergeMode then
				setMerge(startMerge)
			end
			return
		end
		self.IsOpen = true
		filter, mergeMode = "all", false
		clearSelection()
		popup = C.popup(ctx.layers.window, {
			title = "Items",
			color = Color.Yellow,
			onClose = function()
				self.IsOpen = false
				if changedConn then
					changedConn:Disconnect()
					changedConn = nil
				end
			end,
		})
		filterScroll = C.scroll(popup.Body, { horizontal = true, size = UDim2.new(1, -112 - Space.S, 0, Space.Tab + Space.S), name = "Filters" })
		C.new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, Space.S), SortOrder = Enum.SortOrder.LayoutOrder }, filterScroll)
		mergeToggle = C.button(popup.Body, {
			text = "🧩 Merge",
			textSize = "S",
			color = Color.Purple,
			size = UDim2.fromOffset(112, Space.Tab),
			anchor = Vector2.new(1, 0),
			position = UDim2.fromScale(1, 0),
			onClick = function()
				setMerge(not mergeMode)
			end,
		})
		hintRow = C.new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(0, TOP_ROW), Size = UDim2.new(1, 0, 0, Space.Tab), Visible = false }, popup.Body)
		hintText = C.text(hintRow, { text = "", size = "S", sizeU = UDim2.new(1, -144, 1, 0), alignX = Enum.TextXAlignment.Left })
		mergeConfirm = C.button(hintRow, {
			text = "Merge",
			textSize = "S",
			color = Color.Green,
			size = UDim2.fromOffset(136, Space.Tab),
			anchor = Vector2.new(1, 0),
			position = UDim2.fromScale(1, 0),
			onClick = openPreview,
		})
		grid = C.grid(popup.Body, CARD_SIZE, {})
		layoutGrid()
		rebuildFilters()
		rebuild()
		changedConn = Net.InventoryChanged:connect(function()
			if popup and not popup.closed then
				rebuildFilters()
				rebuild()
			end
		end)
		if startMerge then
			setMerge(true)
		end
	end

	function self:Close()
		if popup and not popup.closed then
			popup:Close()
		end
	end

	return self
end

return InventoryUI
