local Client = game:GetService("StarterPlayer").StarterPlayerScripts.Client
local script = Client.Components
local source = script.Source
local report = {}

local function replace(label, old, new)
	local from, to = string.find(source, old, 1, true)
	if from then
		source = string.sub(source, 1, from - 1) .. new .. string.sub(source, to + 1)
		table.insert(report, label .. " patched")
	elseif string.find(source, new, 1, true) then
		table.insert(report, label .. " already patched")
	else
		table.insert(report, label .. " NOT FOUND")
	end
end

replace("button image",
	'local label = C.text(hit, { text = o.text or o.icon or "", size = o.textSize or (o.icon and "L" or "M"), z = 3 })\n',
	'local label = C.text(hit, { text = o.text or o.icon or "", size = o.textSize or (o.icon and "L" or "M"), z = 3 })\n\tif o.image then\n\t\tlabel.Text = ""\n\t\tnew("ImageLabel", { Name = "Icon", BackgroundTransparency = 1, Image = o.image, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.82, 0.82), ScaleType = Enum.ScaleType.Fit, ZIndex = 3 }, hit)\n\tend\n')

replace("pill image",
	'\tnew("UIPadding", { PaddingLeft = UDim.new(0, Space.M), PaddingRight = UDim.new(0, Space.M) }, frame)\n\tlocal label = C.text(frame, { text = o.text or "", size = o.textSize or "M", sizeU = UDim2.fromScale(0, 1) })\n',
	'\tnew("UIPadding", { PaddingLeft = UDim.new(0, Space.S), PaddingRight = UDim.new(0, Space.M) }, frame)\n\tif o.image then\n\t\tnew("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, Space.XS), SortOrder = Enum.SortOrder.LayoutOrder }, frame)\n\t\tnew("ImageLabel", { Name = "Icon", BackgroundTransparency = 1, Image = o.image, Size = UDim2.fromOffset(Space.XL + Space.XS, Space.XL + Space.XS), ScaleType = Enum.ScaleType.Fit, LayoutOrder = 0 }, frame)\n\tend\n\tlocal label = C.text(frame, { text = o.text or "", size = o.textSize or "M", sizeU = UDim2.fromScale(0, 1), order = 1 })\n')

replace("popup close",
	'\t\t\ticon = "✕",\n',
	'\t\t\ttext = "X",\n')

script.Source = source
return report
