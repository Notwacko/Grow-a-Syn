local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Theme = require(script.Parent.Theme)
local Ui = require(script.Parent.Ui)
local Util = require(script.Parent.Util)
local Store = require(script.Parent.Store)
local Sfx = require(script.Parent.Sfx)
local Reveal = require(script.Parent.Reveal)
local Balance = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Balance"))
local ItemCatalog = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ItemCatalog"))

local Popups = {}

local function infoLabel(parent, text, props)
	props = props or {}
	local label = Ui.label(parent, {
		text = text,
		textSize = props.textSize or 18,
		color = props.color or Theme.ink,
		stroke = false,
		size = props.size or UDim2.new(1, 0, 0, 24),
		position = props.position,
		anchor = props.anchor,
		wrap = true,
		xalign = props.xalign,
		z = props.z or 6,
	})
	label.Font = props.font or Theme.bodyFont
	return label
end

local function buildDaily(root, ctx)
	local modal = Ui.modal(root, { name = "Daily", title = "Daily Rewards", size = UDim2.new(0.8, 0, 0.78, 0), max = Vector2.new(820, 560), headerPalette = Theme.gold })
	local body = modal.body
	local streakPill, streakLabel = Ui.pill(body, {
		size = UDim2.fromOffset(260, 50),
		position = UDim2.fromOffset(0, 0),
		icon = "flame",
		text = "Streak: 0",
		height = 50,
		textSize = 24,
		color = Theme.ink,
	})
	local freezePill, freezeLabel = Ui.pill(body, {
		size = UDim2.fromOffset(250, 50),
		position = UDim2.new(1, 0, 0, 0),
		anchor = Vector2.new(1, 0),
		icon = "heart",
		text = "Freezes: 0 / 2",
		height = 50,
		textSize = 22,
		color = Theme.ink,
	})
	local row = Ui.frame(body, { name = "Tiles", size = UDim2.new(1, 0, 0, 170), position = UDim2.fromOffset(0, 68), z = 4 })
	Ui.make("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 8), VerticalAlignment = Enum.VerticalAlignment.Center }, row)
	local claim = Ui.button(body, {
		palette = Theme.green,
		size = UDim2.fromOffset(320, 66),
		position = UDim2.new(0.5, 0, 0, 262),
		anchor = Vector2.new(0.5, 0),
		text = "Claim Reward",
		textSize = 30,
	})
	local note = infoLabel(body, "Come back every day to grow your streak. Missing a day costs a few streak days, unless a freeze protects you. Day 7 gives a free item!", {
		size = UDim2.new(1, -20, 0, 70),
		position = UDim2.new(0, 10, 0, 346),
		textSize = 18,
		xalign = Enum.TextXAlignment.Center,
	})
	local tiles = {}
	for index = 1, 7 do
		local wide = index == 7
		local tile = Ui.card(row, { size = UDim2.fromOffset(wide and 126 or 92, 160), order = index })
		local head = Ui.label(tile, { text = "Day " .. index, textSize = 20, color = Theme.ink, stroke = false, size = UDim2.new(1, 0, 0, 26), position = UDim2.fromOffset(0, 6), z = 5 })
		local icon = Ui.image(tile, { image = wide and "gift" or "coins", size = UDim2.fromOffset(wide and 64 or 52, wide and 64 or 52), position = UDim2.new(0.5, 0, 0, 34), anchor = Vector2.new(0.5, 0), z = 5 })
		local amount = infoLabel(tile, "", { size = UDim2.new(1, -6, 0, 40), position = UDim2.new(0, 3, 0, 98), textSize = 16, xalign = Enum.TextXAlignment.Center, z = 5 })
		local done = Ui.frame(tile, { name = "Done", size = UDim2.fromScale(1, 1), color = Theme.green[2], transparency = 0.2, radius = Theme.radius.card, visible = false, z = 9 })
		Ui.label(done, { text = "Done", textSize = 24, size = UDim2.fromScale(1, 1), z = 10 })
		tiles[index] = { tile = tile, stroke = tile.UIStroke, amount = amount, done = done, icon = icon }
	end
	local stopPulse
	local function paint()
		local daily = Store.get("daily")
		if not daily then
			return
		end
		streakLabel.Text = "Streak: " .. daily.streak .. (daily.streak == 1 and " day" or " days")
		freezeLabel.Text = string.format("Freezes: %d / %d", daily.freezes, daily.maxFreezes)
		local mps = Store.attr("MoneyPerSecond", 0)
		local completed = daily.streak > 0 and daily.streak % 7 == 0 and not daily.canClaim
		for index, tile in tiles do
			local reward = daily.rewards[index]
			local claimed = index < daily.today or completed
			local isToday = index == daily.today and daily.canClaim
			local text = Util.minutes(reward.minutes) .. "\n+" .. Util.short(Balance.incomeMinutes(mps, reward.minutes))
			if reward.item then
				text = text .. "\n+ Rare item"
			end
			tile.amount.Text = text
			tile.done.Visible = claimed
			tile.stroke.Color = isToday and Theme.gold[2] or Theme.ink
			tile.stroke.Thickness = isToday and 5 or 3
		end
		local remaining = (daily.nextAt or 0) - Store.now()
		if daily.canClaim and remaining <= 0 then
			claim.setEnabled(true)
			claim.setText("Claim Day " .. (daily.streak + 1))
			if not stopPulse then
				stopPulse = Ui.pulse(claim.root, 1.05)
			end
		else
			claim.setEnabled(false)
			claim.setText("Next in " .. Util.clock(math.max(remaining, 0)))
			if stopPulse then
				stopPulse()
				stopPulse = nil
			end
		end
	end
	claim.click(function()
		claim.setEnabled(false)
		local result = Store.call("daily.claim")
		if not result.ok then
			ctx.explain(result)
		end
		task.delay(0.4, paint)
	end)
	Store.on("daily", paint)
	modal.onShow = function()
		paint()
		task.spawn(function()
			while modal.open do
				paint()
				task.wait(1)
			end
		end)
	end
	return modal
end

local function buildWheel(root, ctx)
	local modal = Ui.modal(root, { name = "Wheel", title = "Lucky Wheel", size = UDim2.new(0.78, 0, 0.9, 0), max = Vector2.new(780, 760), headerPalette = Theme.teal })
	local body = modal.body
	local wheelHolder = Ui.frame(body, { name = "WheelHolder", size = UDim2.fromOffset(440, 440), position = UDim2.new(0.5, 0, 0, 30), anchor = Vector2.new(0.5, 0), z = 4 })
	local disc = Ui.image(wheelHolder, { image = "wheel_disc", size = UDim2.fromScale(1, 1), position = UDim2.fromScale(0.5, 0.5), anchor = Vector2.new(0.5, 0.5), z = 4 })
	local pointer = Ui.frame(body, {
		name = "Pointer",
		size = UDim2.fromOffset(44, 44),
		position = UDim2.new(0.5, 0, 0, 22),
		anchor = Vector2.new(0.5, 0.5),
		color = Theme.gold[1],
		transparency = 0,
		radius = 6,
		stroke = 4,
		z = 8,
	})
	pointer.Rotation = 45
	local spin = Ui.button(body, {
		palette = Theme.green,
		size = UDim2.fromOffset(340, 70),
		position = UDim2.new(0.5, 0, 0, 500),
		anchor = Vector2.new(0.5, 0),
		text = "Spin!",
		textSize = 32,
	})
	local oddsText = infoLabel(body, "", { size = UDim2.new(1, -20, 0, 96), position = UDim2.new(0, 10, 0, 580), textSize = 16, xalign = Enum.TextXAlignment.Center })
	local spinning = false
	local function paint()
		local state = Store.get("spin")
		if not state or spinning then
			return
		end
		local remaining = (state.nextAt or 0) - Store.now()
		if state.canSpin and remaining <= 0 then
			spin.setEnabled(true)
			spin.setText("Free Spin!")
		else
			spin.setEnabled(false)
			spin.setText("Next spin " .. Util.clock(math.max(remaining, 0)))
		end
		local parts = {}
		for _, odd in state.odds do
			table.insert(parts, string.format("%s %.1f%%", odd.label, odd.percent))
		end
		oddsText.Text = "One free spin every day. Odds: " .. table.concat(parts, "  |  ")
	end
	spin.click(function()
		if spinning then
			return
		end
		local result = Store.call("spin.spin")
		if not result.ok then
			ctx.explain(result)
			return
		end
		spinning = true
		spin.setEnabled(false)
		spin.setText("Good luck...")
		local center = (result.segment - 0.5) * 36
		local jitter = math.random(-13, 13)
		local base = math.ceil(disc.Rotation / 360) * 360
		local target = base + 360 * 6 + ((360 - center + jitter) % 360)
		local tween = Util.tween(disc, { Rotation = target }, 5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
		task.spawn(function()
			local last = disc.Rotation
			while spinning and disc.Parent do
				task.wait(0.06)
				local now = disc.Rotation
				if math.floor(now / 36) ~= math.floor(last / 36) then
					Sfx.play("tick")
					Ui.pop(pointer, 1.25)
				end
				last = now
			end
		end)
		tween.Completed:Wait()
		spinning = false
		Sfx.play("win")
		Store.call("spin.collect")
		task.delay(0.6, paint)
	end)
	Store.on("spin", paint)
	modal.onShow = function()
		paint()
		task.spawn(function()
			while modal.open do
				paint()
				task.wait(1)
			end
		end)
	end
	return modal
end

function Popups.start(root, ctx)
	local popups = {}
	popups.daily = buildDaily(root, ctx)
	popups.wheel = buildWheel(root, ctx)
	local api = {}
	function api.show(name)
		for key, popup in popups do
			if key ~= name and popup.open then
				popup.hide(true)
			end
		end
		if popups[name] then
			popups[name].show()
		end
	end
	function api.hideAll()
		for _, popup in popups do
			popup.hide(true)
		end
	end
	local shownOffline = false
	local function checkOffline()
		local offline = Store.get("offline")
		if offline and offline.amount and offline.amount > 0 and not shownOffline and Store.attr("TutorialStep", 0) >= 6 then
			shownOffline = true
			Reveal.push({
				title = "Welcome Back!",
				name = "+" .. Util.short(offline.amount) .. " money",
				sub = string.format("Your synagogue kept going while you were away for %s.%s", Util.words(offline.away or offline.seconds), offline.patron and "\nPatron bonus doubled it!" or ""),
				icon = "coins",
				rarity = "uncommon",
				button = "Collect",
				tall = offline.patron,
				onCollect = function()
					local result = Store.call("offline.claim")
					if not result.ok then
						ctx.explain(result)
					end
					shownOffline = false
				end,
			})
		end
	end
	Store.on("offline", checkOffline)
	Store.onAttr("TutorialStep", checkOffline)
	task.delay(2, checkOffline)
	return api
end

return Popups
