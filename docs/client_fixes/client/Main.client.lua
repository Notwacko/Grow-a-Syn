local ui = script.Parent:WaitForChild("ui")
local Layers = require(ui:WaitForChild("Layers"))
local Store = require(ui:WaitForChild("Store"))
local Ui = require(ui:WaitForChild("Ui"))
local Theme = require(ui:WaitForChild("Theme"))
local Toasts = require(ui:WaitForChild("Toasts"))
local Hud = require(ui:WaitForChild("Hud"))
local Menu = require(ui:WaitForChild("Menu"))
local Reveal = require(ui:WaitForChild("Reveal"))
local Events = require(ui:WaitForChild("Events"))
local Popups = require(ui:WaitForChild("Popups"))
local Denomination = require(ui:WaitForChild("Denomination"))
local TierPopup = require(ui:WaitForChild("TierPopup"))
local Tutorial = require(ui:WaitForChild("Tutorial"))
local Sfx = require(ui:WaitForChild("Sfx"))
local PetsWorld = require(ui:WaitForChild("PetsWorld"))

local REASONS = {
	not_enough_money = "Not enough money yet",
	requirements_not_met = "Not ready yet",
	invalid = "That did not work",
	locked = "Locked for now",
	busy = "One moment please",
	offline = "Connecting, try again in a moment",
	unavailable = "Coming soon",
}

Layers.start()
local hudRoot = Layers.make("GrowHud", 1)
local tutorialRoot = Layers.make("GrowTutorial", 4)
local menuRoot = Layers.make("GrowMenu", 10, Enum.ScreenInsets.DeviceSafeInsets)
local popupRoot = Layers.make("GrowPopup", 20, Enum.ScreenInsets.DeviceSafeInsets)
local toastRoot = Layers.make("GrowToast", 30)

local loading = Ui.label(popupRoot, { text = "Loading your synagogue...", textSize = 34, position = UDim2.fromScale(0, 0), size = UDim2.fromScale(1, 1), z = 60 })
Store.init()
loading:Destroy()

local ctx = {
	popupRoot = popupRoot,
}

local settings = Store.get("settings") or {}
Theme.useColorblind = settings.colorblind == true
Sfx.setMuted(settings.sfx == false)
ctx.setPetsVisible = PetsWorld.setVisible
PetsWorld.start()
PetsWorld.setVisible(settings.pets ~= false)

function ctx.toast(kind, text)
	Toasts.show(kind, text)
end

function ctx.explain(result)
	if result and not result.ok then
		Toasts.show("error", REASONS[result.reason] or "That did not work")
	end
end

Toasts.start(toastRoot)
Reveal.start(popupRoot)

ctx.reveal = {
	item = function(spec)
		Reveal.push({
			title = "New Item!",
			name = spec.name,
			icon = "item_" .. spec.category,
			rarity = spec.rarity,
			sub = "Growing in your synagogue",
		})
	end,
}

local actions = {}
ctx.actions = actions
ctx.denomination = Denomination.start(popupRoot, ctx)
ctx.popups = Popups.start(popupRoot, ctx)

function ctx.openTab(tab)
	ctx.popups.hideAll()
	ctx.menu.open(tab)
end

function actions.open(tab)
	if tab == "store" then
		ctx.hud.highlight("store", false)
	end
	ctx.openTab(tab)
end

function actions.popup(name)
	ctx.hud.highlight(name, false)
	if ctx.menu.isOpen() then
		ctx.menu.close()
	end
	ctx.popups.show(name)
end

function actions.land()
	Store.remote("RE_ExpandLand")
end

function actions.upgrade()
	if Store.attr("Denomination", "") == "" then
		if Store.attr("HasMinyan", false) then
			ctx.denomination.show()
		else
			Toasts.show("info", "Reach a minyan of 10 first")
		end
		return
	end
	ctx.explain(Store.remote("RF_UpgradeBuilding"))
end

ctx.hud = Hud.start(hudRoot, actions)
ctx.menu = Menu.start(menuRoot, ctx)
Events.start(ctx)
TierPopup.start()
ctx.tutorial = Tutorial.start(tutorialRoot, ctx)

require(script.Parent:WaitForChild("InteriorCamera")).start()

Store.onAttr("TutorialStep", function()
	ctx.menu.refreshTabs()
end)
ctx.menu.refreshTabs()

task.delay(360, function()
	local store = Store.get("store")
	if store and store.starter and store.starter.available and Store.attr("TutorialStep", 0) >= 6 and not ctx.menu.isOpen() then
		ctx.hud.highlight("store", true)
		ctx.toast("gold", "New in the Store: the New Congregation Pack")
	end
end)

shared.GrowUI = ctx
