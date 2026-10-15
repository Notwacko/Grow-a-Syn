local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SocialService = game:GetService("SocialService")

local ui = script.Parent.Parent.ui
local Theme = require(ui.Theme)
local Ui = require(ui.Ui)
local Util = require(ui.Util)
local Store = require(ui.Store)
local Sfx = require(ui.Sfx)
local Balance = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Balance"))

local PanelQuests = {}

local KIND_ICONS = {
	arrive = "people",
	buy = "shop",
	merge = "puzzle",
	mature = "seed",
	upgrade = "upgrade",
	earn = "coins",
	spin = "wheel",
}

function PanelQuests.new(container, ctx, menu)
	local panel = {}
	local scroll = Ui.scroll(container, { gap = 10, pad = 6 })
	local running = false
	local timers = {}

	local function sectionHeader(text, order)
		local row = Ui.frame(scroll, { size = UDim2.new(1, -12, 0, 46), order = order, z = 3 })
		local label = Ui.label(row, { text = text, textSize = 30, size = UDim2.new(0.6, 0, 1, 0), xalign = Enum.TextXAlignment.Left, stroke = 3, z = 4 })
		label.TextColor3 = Theme.ink
		local stroke = label:FindFirstChildOfClass("UIStroke")
		if stroke then
			stroke:Destroy()
		end
		local timer = Ui.label(row, { text = "", textSize = 20, color = Theme.inkSoft, stroke = false, size = UDim2.new(0.4, 0, 1, 0), position = UDim2.fromScale(0.6, 0), xalign = Enum.TextXAlignment.Right, z = 4 })
		timer.Font = Theme.bodyFont
		return timer
	end

	local function questRow(entry, scope, order)
		local ready = entry.prog >= entry.goal and not entry.claimed
		local card = Ui.card(scroll, { size = UDim2.new(1, -12, 0, 92), order = order, strokeColor = ready and Theme.gold[2] or Theme.ink, stroke = ready and 4 or 3 })
		local iconBox = Ui.frame(card, { size = UDim2.fromOffset(64, 64), position = UDim2.fromOffset(12, 14), color = Theme.cream2, transparency = 0, radius = 14, stroke = 2, z = 4 })
		Ui.image(iconBox, { image = KIND_ICONS[entry.kind] or "star", size = UDim2.new(1, -8, 1, -8), position = UDim2.fromOffset(4, 4), z = 5 })
		local text = Ui.label(card, { text = entry.text, textSize = 24, color = Theme.ink, stroke = false, size = UDim2.new(1, -340, 0, 32), position = UDim2.fromOffset(90, 10), xalign = Enum.TextXAlignment.Left, fit = true, z = 4 })
		local isMoney = entry.kind == "earn"
		local bar = Ui.bar(card, {
			size = UDim2.new(1, -340, 0, 26),
			position = UDim2.fromOffset(90, 52),
			height = 26,
			palette = entry.claimed and Theme.gray or (ready and Theme.gold or Theme.green),
			text = isMoney and string.format("%s / %s", Util.short(entry.prog), Util.short(entry.goal)) or string.format("%d / %d", math.floor(entry.prog), entry.goal),
		})
		bar.fill.Size = UDim2.fromScale(math.clamp(entry.prog / entry.goal, 0, 1), 1)
		local amount = Balance.incomeMinutes(Store.attr("MoneyPerSecond", 0), entry.minutes)
		local reward = Ui.pill(card, { size = UDim2.fromOffset(118, 44), position = UDim2.new(1, -150, 0, 12), anchor = Vector2.new(1, 0), icon = "coins", text = "+" .. Util.short(amount), height = 44, textSize = 20 })
		local button = Ui.button(card, {
			palette = ready and Theme.green or Theme.gray,
			size = UDim2.fromOffset(124, 56),
			position = UDim2.new(1, -12, 0.5, -2),
			anchor = Vector2.new(1, 0.5),
			text = entry.claimed and "Claimed" or (ready and "Claim" or "Not yet"),
			textSize = 21,
			enabled = ready,
		})
		button.onDisabled = function() end
		button.click(function()
			button.setEnabled(false)
			local result = Store.call("quests.claim", { scope = scope, index = entry.index })
			if result.ok then
				Sfx.play("coin")
			else
				ctx.explain(result)
			end
		end)
		return card
	end

	local function bonusRow(text, claimed, order)
		local row = Ui.card(scroll, { size = UDim2.new(1, -12, 0, 52), order = order, color = Theme.cream2, strokeColor = claimed and Theme.green[2] or Theme.gold[2] })
		local label = Ui.label(row, { text = (claimed and "Completed: " or "Bonus: ") .. text, textSize = 22, color = Theme.ink, stroke = false, size = UDim2.new(1, -20, 1, 0), position = UDim2.fromOffset(10, 0), xalign = Enum.TextXAlignment.Left, fit = true, z = 4 })
		label.Font = Theme.titleFont
	end

	local function friendsCard(order)
		local card = Ui.card(scroll, { size = UDim2.new(1, -12, 0, 84), order = order, color = Theme.cream2, strokeColor = Theme.red[2] })
		Ui.image(card, { image = "heart", size = UDim2.fromOffset(60, 60), position = UDim2.fromOffset(12, 12), z = 5 })
		local friends = Store.attr("FriendsCount", 0)
		local title = Ui.label(card, { text = "Play with friends", textSize = 26, color = Theme.ink, stroke = false, size = UDim2.new(1, -330, 0, 34), position = UDim2.fromOffset(84, 8), xalign = Enum.TextXAlignment.Left, z = 5 })
		local sub = Ui.label(card, {
			text = string.format("Every friend in your server adds +5%% income (up to 5). Right now: %d friend%s, +%d%%.", friends, friends == 1 and "" or "s", friends * 5),
			textSize = 16,
			color = Theme.inkSoft,
			stroke = false,
			size = UDim2.new(1, -330, 0, 40),
			position = UDim2.fromOffset(84, 42),
			xalign = Enum.TextXAlignment.Left,
			wrap = true,
			z = 5,
		})
		sub.Font = Theme.bodyFont
		title.Font = Theme.titleFont
		local invite = Ui.button(card, { palette = Theme.red, size = UDim2.fromOffset(190, 54), position = UDim2.new(1, -14, 0.5, 0), anchor = Vector2.new(1, 0.5), text = "Invite", textSize = 26 })
		invite.click(function()
			local ok, can = pcall(SocialService.CanSendGameInviteAsync, SocialService, Store.player)
			if ok and can then
				pcall(SocialService.PromptGameInvite, SocialService, Store.player)
			else
				ctx.toast("info", "Invites are not available right now")
			end
		end)
	end

	function panel.refresh()
		local data = Store.get("quests")
		if not data then
			return
		end
		Ui.clear(scroll)
		timers = {}
		friendsCard(0)
		timers.daily = sectionHeader("Daily Quests", 1)
		for index, entry in data.daily do
			questRow(entry, "d", 1 + index)
		end
		bonusRow(string.format("finish all three for +%d minutes of income", data.dailyBonusMinutes), data.dailyBonus, 10)
		timers.weekly = sectionHeader("Weekly Goals", 20)
		for index, entry in data.weekly do
			questRow(entry, "w", 20 + index)
		end
		bonusRow("finish every weekly goal for a free Epic Menorah", data.weeklyBonus, 40)
		panel.tick()
	end

	function panel.tick()
		local data = Store.get("quests")
		if not data or not timers.daily then
			return
		end
		timers.daily.Text = "Resets in " .. Util.words(data.dayEnds - Store.now())
		timers.weekly.Text = "Resets in " .. Util.words(data.weekEnds - Store.now())
	end

	Store.on("quests", function()
		if running then
			panel.refresh()
		end
	end)

	function panel.show()
		running = true
		panel.refresh()
		task.spawn(function()
			while running and container.Parent do
				task.wait(1)
				panel.tick()
			end
		end)
	end

	function panel.hide()
		running = false
	end

	return panel
end

return PanelQuests
