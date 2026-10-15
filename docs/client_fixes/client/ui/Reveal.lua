local Theme = require(script.Parent.Theme)
local Ui = require(script.Parent.Ui)
local Util = require(script.Parent.Util)
local Sfx = require(script.Parent.Sfx)
local ItemView = require(script.Parent.ItemView)

local Reveal = {}

local ANTICIPATION = { common = 0.15, uncommon = 0.3, rare = 0.5, epic = 0.75, legendary = 1.0, mythical = 1.2 }

local root
local queue = {}
local running = false

local function present(spec)
	local rarity = spec.rarity or "common"
	local color = Theme.rarityColor(rarity)
	local finished = false
	local skipped = false
	local overlay = Ui.frame(root, { name = "Reveal", z = 10 })
	local dim = Ui.make("TextButton", {
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = Color3.fromRGB(10, 14, 32),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 1,
	}, overlay)
	Util.tween(dim, { BackgroundTransparency = 0.3 }, 0.25)
	local card = Ui.frame(overlay, {
		name = "Card",
		size = UDim2.fromOffset(480, spec.tall and 540 or 480),
		position = UDim2.fromScale(0.5, 0.5),
		anchor = Vector2.new(0.5, 0.5),
		color = Theme.cream,
		transparency = 0,
		radius = 26,
		stroke = 5,
		z = 3,
	})
	card.UIStroke.Color = color
	local cardScale = Ui.make("UIScale", { Scale = 0.7 }, card)
	Util.tween(cardScale, { Scale = 1 }, 0.3, Enum.EasingStyle.Back)
	local bar = Ui.frame(card, { size = UDim2.new(1, 0, 0, 64), color = Color3.new(1, 1, 1), transparency = 0, radius = 24, z = 4 })
	Ui.gradient(bar, { Theme.tint(color, 0.15), Theme.shade(color, 0.12) }, 90)
	Ui.frame(bar, { size = UDim2.new(1, 0, 0, 24), position = UDim2.new(0, 0, 1, -24), color = Theme.shade(color, 0.12), transparency = 0, z = 4 })
	Ui.label(bar, { text = spec.title or "New!", textSize = 32, size = UDim2.new(1, -20, 1, 0), position = UDim2.fromOffset(10, 0), stroke = 3, fit = true, z = 6 })
	local stage = Ui.frame(card, { name = "Stage", size = UDim2.fromOffset(240, 200), position = UDim2.new(0.5, 0, 0, 74), anchor = Vector2.new(0.5, 0), z = 4 })
	local rays = Ui.image(stage, { image = "star", size = UDim2.fromOffset(230, 230), position = UDim2.fromScale(0.5, 0.5), anchor = Vector2.new(0.5, 0.5), color = Theme.tint(color, 0.4), z = 4 })
	rays.ImageTransparency = 1
	local glow = ItemView.glow(stage, color, 180)
	glow.BackgroundTransparency = 1
	local iconHolder = Ui.frame(stage, { size = UDim2.fromOffset(180, 180), position = UDim2.fromScale(0.5, 0.5), anchor = Vector2.new(0.5, 0.5), z = 6 })
	local iconScale = Ui.make("UIScale", { Scale = 0 }, iconHolder)
	local icon = Ui.image(iconHolder, { image = spec.icon or "star", z = 7 })
	if spec.model then
		icon.Visible = false
	end
	local flash = Ui.frame(card, { size = UDim2.fromScale(1, 1), color = Color3.new(1, 1, 1), transparency = 1, radius = 24, z = 20 })
	local nameLabel = Ui.label(card, {
		text = spec.name or "",
		textSize = 32,
		color = Theme.ink,
		stroke = false,
		size = UDim2.new(1, -30, 0, 44),
		position = UDim2.fromOffset(15, 282),
		fit = true,
		z = 5,
	})
	nameLabel.TextTransparency = 1
	local sub = Ui.label(card, {
		text = spec.sub or "",
		textSize = 22,
		color = Theme.inkSoft,
		stroke = false,
		size = UDim2.new(1, -40, 0, 70),
		position = UDim2.fromOffset(20, 324),
		wrap = true,
		rich = true,
		z = 5,
	})
	sub.Font = Theme.bodyFont
	sub.TextTransparency = 1
	local tag
	if spec.rarity and not spec.noTag then
		tag = ItemView.rarityTag(card, rarity, { size = UDim2.fromOffset(120, 26), position = UDim2.new(0.5, 0, 0, 258), anchor = Vector2.new(0.5, 0) })
		tag.Visible = false
	end
	local collect = Ui.button(card, {
		palette = Theme.green,
		size = UDim2.fromOffset(220, 60),
		position = UDim2.new(0.5, 0, 1, -14),
		anchor = Vector2.new(0.5, 1),
		text = spec.button or "Collect",
		textSize = 28,
		z = 8,
	})
	collect.root.Visible = false

	local function finish()
		if finished then
			return
		end
		finished = true
		Util.tween(cardScale, { Scale = 0.85 }, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		Util.tween(dim, { BackgroundTransparency = 1 }, 0.15)
		task.delay(0.17, function()
			overlay:Destroy()
			running = false
			Reveal.next()
		end)
	end
	collect.click(function()
		Sfx.play("coin")
		if spec.onCollect then
			task.spawn(spec.onCollect)
		end
		finish()
	end)

	local function land()
		Util.tween(iconScale, { Scale = 1.15 }, 0.25, Enum.EasingStyle.Back)
		task.delay(0.25, function()
			Util.tween(iconScale, { Scale = 1 }, 0.15)
		end)
		Util.tween(flash, { BackgroundTransparency = 1 }, 0.4)
		flash.BackgroundTransparency = 0.2
		Util.tween(rays, { ImageTransparency = 0.45 }, 0.4)
		glow.BackgroundTransparency = 0.6
		Util.tween(nameLabel, { TextTransparency = 0 }, 0.3)
		Util.tween(sub, { TextTransparency = 0 }, 0.3)
		if tag then
			tag.Visible = true
		end
		Ui.burst(overlay, { position = UDim2.fromScale(0.5, 0.42), count = rarity == "common" and 8 or 18, distance = 260, z = 25 })
		Sfx.play(spec.sound or "win", rarity == "common" and 1.2 or 1)
		task.delay(0.5, function()
			if not finished then
				collect.root.Visible = true
				Ui.pop(collect.root, 1.15)
			end
		end)
		task.spawn(function()
			while not finished and rays.Parent do
				rays.Rotation += 1.2
				task.wait(0.03)
			end
		end)
	end

	dim.Activated:Connect(function()
		skipped = true
	end)

	task.spawn(function()
		Util.tween(iconScale, { Scale = 0.55 }, 0.25, Enum.EasingStyle.Back)
		local wait = spec.fast and 0.1 or (ANTICIPATION[rarity] or 0.3)
		local started = os.clock()
		local shake = 0
		while os.clock() - started < wait and not skipped do
			shake += 1
			iconHolder.Rotation = (shake % 2 == 0 and 1 or -1) * math.min(shake * 1.2, 10)
			task.wait(0.05)
		end
		iconHolder.Rotation = 0
		land()
	end)
end

function Reveal.next()
	if running then
		return
	end
	local spec = table.remove(queue, 1)
	if not spec then
		return
	end
	running = true
	present(spec)
end

function Reveal.push(spec)
	table.insert(queue, spec)
	Reveal.next()
end

function Reveal.start(layer)
	root = layer
end

return Reveal
