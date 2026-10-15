local Client = game:GetService("StarterPlayer").StarterPlayerScripts.Client
local report = {}

local function patch(moduleName, edits)
	local target = Client:FindFirstChild(moduleName)
	if not target then
		table.insert(report, moduleName .. " MISSING")
		return
	end
	local source = target.Source
	for _, edit in edits do
		local label, old, new = edit[1], edit[2], edit[3]
		if string.find(source, new, 1, true) then
			table.insert(report, moduleName .. ": " .. label .. " already patched")
		else
			local from, to = string.find(source, old, 1, true)
			if from then
				source = string.sub(source, 1, from - 1) .. new .. string.sub(source, to + 1)
				table.insert(report, moduleName .. ": " .. label .. " patched")
			else
				table.insert(report, moduleName .. ": " .. label .. " NOT FOUND")
			end
		end
	end
	target.Source = source
end

patch("Components", {
	{
		"skin require",
		"local ModelLookup = require(script.Parent.ModelLookup)\n",
		'local ModelLookup = require(script.Parent.ModelLookup)\nlocal ItemSkin = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("ItemSkin"))\n',
	},
	{
		"modelView skin",
		"\tlocal instance = ModelLookup.get(modelName)\n",
		"\tlocal instance = ModelLookup.get(modelName)\n\tif o.rarity then\n\t\tItemSkin.apply(instance, o.rarity, o.mutation, false)\n\tend\n",
	},
})

patch("Net", {
	{
		"shop seen signal",
		"\tInventoryChanged = newSignal(),\n}",
		"\tInventoryChanged = newSignal(),\n\tShopSeen = newSignal(),\n}",
	},
	{
		"refresh catalog",
		"function Net.getInventory()\n",
		"function Net.refreshCatalog()\n\tif Net.isMock then\n\t\treturn Net.getCatalog()\n\tend\n\tlocal res = invoke(Contract.Functions.GetCatalog)\n\tif res.ok then\n\t\tcatalog = normalizeCatalog(res.data or res)\n\tend\n\treturn catalog or Net.getCatalog()\nend\n\nfunction Net.getInventory()\n",
	},
})

patch("InventoryUI", {
	{
		"display helper",
		"local TOP_ROW = Space.Tab + Space.S\n",
		'local TOP_ROW = Space.Tab + Space.S\n\nlocal function displayName(info, entry)\n\tlocal mutation = entry and entry.mutation\n\tif mutation then\n\t\treturn (string.upper(string.sub(mutation, 1, 1)) .. string.sub(mutation, 2)) .. " " .. info.name\n\tend\n\treturn info.name\nend\n',
	},
	{
		"merge cells",
		"C.modelView(cell.Frame, info.model, { size = UDim2.new(1, -Space.S, 1, -Space.S), position = UDim2.fromOffset(Space.XS, Space.XS) })",
		"C.modelView(cell.Frame, info.model, { size = UDim2.new(1, -Space.S, 1, -Space.S), position = UDim2.fromOffset(Space.XS, Space.XS), rarity = info.rarity })",
	},
	{
		"merge result",
		"C.modelView(out.Frame, result.model, { size = UDim2.new(1, -Space.S, 1, -Space.S), position = UDim2.fromOffset(Space.XS, Space.XS) })",
		"C.modelView(out.Frame, result.model, { size = UDim2.new(1, -Space.S, 1, -Space.S), position = UDim2.fromOffset(Space.XS, Space.XS), rarity = result.rarity })",
	},
	{
		"detail title",
		"\t\t\ttitle = info.name,\n",
		"\t\t\ttitle = displayName(info, entry),\n",
	},
	{
		"detail view",
		"C.modelView(dialog.Body, info.model, { size = UDim2.new(1, 0, 0, 112) })",
		"C.modelView(dialog.Body, info.model, { size = UDim2.new(1, 0, 0, 112), rarity = info.rarity, mutation = entry.mutation })",
	},
	{
		"detail text",
		'text = (Contract.CategoryNames[info.category] or "") .. "  •  " .. (info.rarity or ""),',
		'text = (Contract.CategoryNames[info.category] or "") .. "  •  " .. (info.rarity or "") .. (entry.growth and entry.growth < 1 and string.format("  •  growing %d%%", math.floor(entry.growth * 100)) or ""),',
	},
	{
		"card view",
		"C.modelView(card.Frame, info.model, { size = UDim2.new(1, -Space.S, 0, 72), position = UDim2.fromOffset(Space.XS, Space.XS) })",
		"C.modelView(card.Frame, info.model, { size = UDim2.new(1, -Space.S, 0, 72), position = UDim2.fromOffset(Space.XS, Space.XS), rarity = info.rarity, mutation = entry.mutation })",
	},
	{
		"card name",
		"C.text(card.Frame, { text = info.name, size = \"XS\"",
		"C.text(card.Frame, { text = displayName(info, entry), size = \"XS\"",
	},
	{
		"card tag",
		'local tag = C.pill(card.Frame, { text = "Equipped", color = Color.Green, textSize = "XS" })',
		'local tag = C.pill(card.Frame, { text = (entry.growth and entry.growth < 1) and string.format("Growing %d%%", math.floor(entry.growth * 100)) or "Placed", color = Color.Green, textSize = "XS" })',
	},
})

return report
