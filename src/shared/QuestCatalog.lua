local QuestCatalog = {}

QuestCatalog.DAILY_REWARD_MINUTES = 15
QuestCatalog.DAILY_BONUS_MINUTES = 30
QuestCatalog.WEEKLY_REWARD_MINUTES = 120
QuestCatalog.WEEKLY_BONUS_ITEM = "menorah_epic"

QuestCatalog.daily = {
	easy = {
		{ id = "arrive_8", kind = "arrive", goal = 8, text = "Welcome 8 guests" },
		{ id = "buy_1", kind = "buy", goal = 1, text = "Buy 1 item from the shop" },
		{ id = "upgrade_1", kind = "upgrade", goal = 1, text = "Upgrade a station" },
		{ id = "spin_1", kind = "spin", goal = 1, text = "Spin the Lucky Wheel" },
	},
	medium = {
		{ id = "arrive_40", kind = "arrive", goal = 40, text = "Welcome 40 guests" },
		{ id = "buy_4", kind = "buy", goal = 4, text = "Buy 4 items from the shop" },
		{ id = "merge_1", kind = "merge", goal = 1, text = "Merge items once" },
		{ id = "earn_10", kind = "earn", minutes = 10, text = "Earn 10 minutes of income" },
	},
	hard = {
		{ id = "arrive_100", kind = "arrive", goal = 100, text = "Welcome 100 guests" },
		{ id = "mature_2", kind = "mature", goal = 2, text = "Grow 2 items to full size" },
		{ id = "upgrade_5", kind = "upgrade", goal = 5, text = "Upgrade stations 5 times" },
		{ id = "earn_30", kind = "earn", minutes = 30, text = "Earn 30 minutes of income" },
	},
}

QuestCatalog.weekly = {
	{ id = "w_arrive", kind = "arrive", goal = 600, text = "Welcome 600 guests" },
	{ id = "w_buy", kind = "buy", goal = 40, text = "Buy 40 items from the shop" },
	{ id = "w_merge", kind = "merge", goal = 12, text = "Merge items 12 times" },
	{ id = "w_earn", kind = "earn", minutes = 240, text = "Earn 4 hours of income" },
	{ id = "w_mature", kind = "mature", goal = 15, text = "Grow 15 items to full size" },
}

local byId = {}
for _, group in QuestCatalog.daily do
	for _, quest in group do
		byId[quest.id] = quest
	end
end
for _, quest in QuestCatalog.weekly do
	byId[quest.id] = quest
end

function QuestCatalog.get(id)
	return byId[id]
end

function QuestCatalog.dayId(unixTime)
	return math.floor(unixTime / 86400)
end

function QuestCatalog.weekId(unixTime)
	return math.floor((math.floor(unixTime / 86400) + 3) / 7)
end

return QuestCatalog
