local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local ui = script.Parent.Parent.ui
local Theme = require(ui.Theme)
local Ui = require(ui.Ui)
local Util = require(ui.Util)
local Store = require(ui.Store)
local ItemView = require(ui.ItemView)
local Sfx = require(ui.Sfx)
local Shared = ReplicatedStorage:WaitForChild("Shared")
local CosmeticCatalog = require(Shared:WaitForChild("CosmeticCatalog"))

local PanelWardrobe = {}

local EFFECT_ICONS = {
	sparkle = "star",
	stars = "star",
	hearts = "heart",
	rainbow = "wheel",
	snow = "rain",
	leaves = "land",
	confetti = "gift",
	glow = "sun",
}

local RARITY_ORDER = {}
for index, id in Theme.rarityOrder do
	RARITY_ORDER[id] = index
end

local function iconFor(definition)
	if definition.effect then
		return EFFECT_ICONS[definition.effect] or "star"
	end
	return definition.model
end

function PanelWardrobe.new(container, ctx, menu)
	local panel = {}
	local slot = "head"
	local running = false
	local previewModel, previewConnection

	local leftWidth = Ui.touch and 200 or 270
	local left = Ui.card(container, { name = "Preview", size = UDim2.new(0, leftWidth, 1, 0), color = Theme.cream2, strokeColor = Theme.purple[2], stroke = 4 })
	local viewport = Ui.make("ViewportFrame", {
		Name = "Viewport",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -16, 1, -150),
		Position = UDim2.fromOffset(8, 8),
		ZIndex = 4,
		Ambient = Color3.fromRGB(180, 180, 190),
		LightColor = Color3.fromRGB(255, 255, 255),
	}, left)
	local world = Instance.new("WorldModel")
	world.Parent = viewport
	local camera = Instance.new("Camera")
	camera.FieldOfView = 38
	camera.Parent = viewport
	viewport.CurrentCamera = camera

	local outfitLabel = Ui.label(left, {
		text = "",
		textSize = 20,
		color = Theme.ink,
		stroke = false,
		size = UDim2.new(1, -16, 0, 26),
		position = UDim2.new(0, 8, 1, -140),
		fit = true,
		z = 5,
	})
	local outfitButton = Ui.button(left, {
		palette = Theme.purple,
		size = UDim2.new(1, -20, 0, 46),
		position = UDim2.new(0, 10, 1, -108),
		text = "Next Outfit",
		textSize = 22,
	})
	local styleButton = Ui.button(left, {
		palette = Theme.blue,
		size = UDim2.new(1, -20, 0, 46),
		position = UDim2.new(0, 10, 1, -54),
		text = "Dress Style",
		textSize = 22,
	})

	local right = Ui.frame(container, { name = "Right", size = UDim2.new(1, -(leftWidth + 14), 1, 0), position = UDim2.fromOffset(leftWidth + 14, 0), z = 3 })
	local tabs = Ui.frame(right, { name = "SlotTabs", size = UDim2.new(1, 0, 0, 50), z = 4 })
	Ui.make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Center }, tabs)
	local tabButtons = {}
	for index, definition in CosmeticCatalog.SLOTS do
		local button = Ui.button(tabs, { palette = Theme.gray, size = UDim2.fromOffset(definition.id == "effect" and 108 or 92, 46), text = definition.name, textSize = 19, radius = 14, order = index })
		button.click(function()
			slot = definition.id
			panel.refresh()
		end)
		tabButtons[definition.id] = button
	end
	local passBanner = Ui.card(right, { size = UDim2.new(1, 0, 0, 56), position = UDim2.fromOffset(0, 56), color = Theme.cream2, strokeColor = Theme.purple[2], stroke = 3 })
	Ui.image(passBanner, { image = "pass_golden_wardrobe", size = UDim2.fromOffset(44, 44), position = UDim2.new(0, 8, 0.5, 0), anchor = Vector2.new(0, 0.5), z = 5 })
	local passText = Ui.label(passBanner, { text = "Premium Wardrobe: wear every premium style", textSize = 19, color = Theme.ink, stroke = false, size = UDim2.new(1, -250, 1, 0), position = UDim2.fromOffset(60, 0), xalign = Enum.TextXAlignment.Left, fit = true, z = 5 })
	passText.Font = Theme.titleFont
	local passButton = Ui.button(passBanner, { palette = Theme.purple, size = UDim2.fromOffset(160, 42), position = UDim2.new(1, -8, 0.5, -2), anchor = Vector2.new(1, 0.5), text = "View Pass", textSize = 19 })
	passButton.click(function()
		menu.select("store")
	end)
	local scroll = Ui.scroll(right, { size = UDim2.new(1, 0, 1, -122), position = UDim2.fromOffset(0, 120), grid = { cell = UDim2.fromOffset(168, 222), pad = UDim2.fromOffset(10, 10) }, pad = 4 })

	local function clearPreview()
		if previewConnection then
			previewConnection:Disconnect()
			previewConnection = nil
		end
		if previewModel then
			previewModel:Destroy()
			previewModel = nil
		end
	end

	function panel.buildPreview()
		clearPreview()
		local character = Players.LocalPlayer.Character
		if not character or not character:FindFirstChild("HumanoidRootPart") then
			return
		end
		character.Archivable = true
		local ok, clone = pcall(function()
			return character:Clone()
		end)
		if not ok or not clone then
			return
		end
		for _, descendant in clone:GetDescendants() do
			if descendant:IsA("Script") or descendant:IsA("LocalScript") or descendant:IsA("Sound") then
				descendant:Destroy()
			elseif descendant:IsA("BasePart") then
				descendant.Anchored = true
			end
		end
		local humanoid = clone:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		end
		clone.Parent = world
		previewModel = clone
		local root = clone:FindFirstChild("HumanoidRootPart")
		local origin = CFrame.new(0, 0, 0)
		clone:PivotTo(origin)
		local angle = 0
		local pivot = clone:GetPivot()
		local box, size = clone:GetBoundingBox()
		local center = box.Position
		camera.CFrame = CFrame.lookAt(center + Vector3.new(0, 0.4, size.Y * 1.9 + 2), center + Vector3.new(0, 0.2, 0))
		previewConnection = RunService.RenderStepped:Connect(function(dt)
			angle += dt * 0.7
			if clone.Parent then
				clone:PivotTo(CFrame.new(pivot.Position) * CFrame.Angles(0, math.rad(200) + math.sin(angle) * 0.7, 0))
			end
		end)
		root.Anchored = true
	end

	local function buy(definition, view)
		local result = Store.call("wardrobe.buy", { id = definition.id })
		if result.ok then
			Sfx.play("buy")
		else
			ctx.explain(result)
		end
	end

	local function robuxBuy(definition)
		local result = Store.call("store.buyProduct", { key = "cosmetic_" .. definition.robux, target = definition.id })
		if not result.ok then
			if result.reason == "offline" then
				ctx.toast("info", "Coming soon")
			else
				ctx.explain(result)
			end
		end
	end

	function panel.refresh()
		local data = Store.get("wardrobe")
		if not data then
			return
		end
		for id, button in tabButtons do
			button.setPalette(id == slot and Theme.purple or Theme.gray)
		end
		local pass = nil
		local storeData = Store.get("store")
		if storeData then
			for _, entry in storeData.passes do
				if entry.key == "premium_wardrobe" then
					pass = entry
				end
			end
		end
		passBanner.Visible = not (pass and pass.owned)
		scroll.Position = passBanner.Visible and UDim2.fromOffset(0, 120) or UDim2.fromOffset(0, 58)
		scroll.Size = passBanner.Visible and UDim2.new(1, 0, 1, -122) or UDim2.new(1, 0, 1, -60)
		local outfit = data.outfit
		outfitLabel.Text = outfit and ((outfit.auto and "Outfit: Auto - " or "Outfit: ") .. outfit.name) or ""
		styleButton.setText(outfit and outfit.style == "modest" and "Style: Modest" or "Style: Classic")
		Ui.clear(scroll)
		local items = {}
		for _, item in data.items do
			if item.slot == slot then
				table.insert(items, item)
			end
		end
		table.sort(items, function(a, b)
			if a.owned ~= b.owned then
				return a.owned
			end
			if RARITY_ORDER[a.rarity] ~= RARITY_ORDER[b.rarity] then
				return RARITY_ORDER[a.rarity] < RARITY_ORDER[b.rarity]
			end
			return a.name < b.name
		end)
		local money = Store.attr("Money", 0)
		for index, item in items do
			local definition = CosmeticCatalog.get(item.id)
			local color = Theme.rarityColor(item.rarity)
			local card = Ui.card(scroll, { size = UDim2.fromOffset(168, 222), order = index, strokeColor = item.equipped and Theme.gold[1] or color, stroke = item.equipped and 5 or (Theme.rarity[item.rarity] or Theme.rarity.common).stroke })
			ItemView.glow(card, color, 96, UDim2.new(0.5, 0, 0, 66))
			Ui.image(card, { image = iconFor(definition), size = UDim2.fromOffset(104, 104), position = UDim2.new(0.5, 0, 0, 66), anchor = Vector2.new(0.5, 0.5), z = 5 })
			local swatchColor = definition.colors and (definition.colors.Base or definition.colors.Stripe)
			if swatchColor then
				Ui.frame(card, { size = UDim2.fromOffset(26, 26), position = UDim2.new(1, -8, 0, 36), anchor = Vector2.new(1, 0), color = swatchColor, transparency = 0, radius = 13, stroke = 3, z = 7 })
			end
			ItemView.rarityTag(card, item.rarity, { size = UDim2.new(1, -16, 0, 22), position = UDim2.fromOffset(8, 6) })
			local name = Ui.label(card, { text = item.name, textSize = 17, color = Theme.ink, stroke = false, size = UDim2.new(1, -10, 0, 46), position = UDim2.fromOffset(5, 124), wrap = true, fit = true, z = 5 })
			if item.premium then
				local badge = Ui.frame(card, { size = UDim2.fromOffset(70, 20), position = UDim2.fromOffset(8, 32), color = Theme.purple[1], transparency = 0, radius = 10, stroke = 2, z = 8 })
				Ui.label(badge, { text = "Premium", textSize = 13, size = UDim2.fromScale(1, 1), fit = true, stroke = 2, z = 9 })
			end
			local button
			if item.owned then
				button = Ui.button(card, { palette = item.equipped and Theme.orange or Theme.green, size = UDim2.new(1, -20, 0, 40), position = UDim2.new(0.5, 0, 1, -8), anchor = Vector2.new(0.5, 1), text = item.equipped and "Take Off" or "Wear", textSize = 20 })
				button.click(function()
					Sfx.play("pop")
					local result
					if item.equipped then
						result = Store.call("wardrobe.unequip", { slot = item.slot })
					else
						result = Store.call("wardrobe.equip", { id = item.id })
					end
					ctx.explain(result)
				end)
			elseif item.patron then
				button = Ui.button(card, { palette = Theme.gold, size = UDim2.new(1, -20, 0, 40), position = UDim2.new(0.5, 0, 1, -8), anchor = Vector2.new(0.5, 1), text = "Patron Pass", textSize = 18 })
				button.click(function()
					menu.select("store")
				end)
			elseif item.money then
				button = Ui.button(card, { palette = money >= item.money and Theme.green or Theme.red, size = UDim2.new(1, -20, 0, 40), position = UDim2.new(0.5, 0, 1, -8), anchor = Vector2.new(0.5, 1), icon = "coin", iconSize = 26, text = Util.short(item.money), textSize = 21 })
				button.click(function()
					buy(definition)
				end)
			else
				button = Ui.button(card, { palette = Theme.purple, size = UDim2.new(1, -20, 0, 40), position = UDim2.new(0.5, 0, 1, -8), anchor = Vector2.new(0.5, 1), text = "R$ " .. tostring(item.robux or ""), textSize = 21 })
				button.click(function()
					robuxBuy(definition)
				end)
			end
		end
	end

	outfitButton.click(function()
		Store.call("wardrobe.outfit")
		task.delay(1, function()
			if running then
				panel.buildPreview()
			end
		end)
	end)
	styleButton.click(function()
		Store.call("wardrobe.style")
		task.delay(1, function()
			if running then
				panel.buildPreview()
			end
		end)
	end)

	Store.on("wardrobe", function()
		if running then
			panel.refresh()
			task.delay(1.2, function()
				if running then
					panel.buildPreview()
				end
			end)
		end
	end)
	Store.on("store", function()
		if running then
			panel.refresh()
		end
	end)

	function panel.show()
		running = true
		panel.refresh()
		panel.buildPreview()
	end

	function panel.hide()
		running = false
		clearPreview()
	end

	return panel
end

return PanelWardrobe
