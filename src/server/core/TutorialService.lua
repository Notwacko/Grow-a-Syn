local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Link = require(script.Parent.Link)
local Config = require(script.Parent.Config)
local Guard = require(script.Parent.Guard)
local Notify = require(script.Parent.Notify)
local Fx = require(script.Parent.Fx)
local CongregationService = require(script.Parent.CongregationService)
local BuildingService = require(script.Parent.BuildingService)
local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))

local TutorialService = {}

local STEP = Constants.TUTORIAL

local states = {}
local pendingAdvance = {}

local minyanRemote
local advanceRemote

local function currentStep(player)
	return player:GetAttribute("TutorialStep") or STEP.WELCOME
end

local function setStep(player, step)
	if currentStep(player) ~= step then
		player:SetAttribute("TutorialStep", step)
	end
end

local function celebrateMinyan(player)
	local info = BuildingService.getInfo(player)
	if info then
		local center = info.floor.Position + Vector3.new(0, 8, 0)
		Fx.confetti(center, 2)
		Fx.ring(Vector3.new(center.X, info.floorTopY + 0.5, center.Z), Color3.fromRGB(255, 214, 80), 50)
		Fx.floatText(center + Vector3.new(0, 10, 0), "MINYAN!", Color3.fromRGB(255, 214, 80))
		Fx.sound(center, Config.SOUNDS.victory, 0.8, 1)
		local front = Vector3.new(info.door.Position.X, 1, info.door.Position.Z) + info.floor.CFrame.LookVector * 30
		Fx.fireworkShow(front, 8, 48)
	end
	Notify.send(player, "success", "You have a minyan! Ten people are praying together")
end

local function skipBuyIfOffline(player, state)
	if state.buyScheduled or workspace:GetAttribute("ProgressionOnline") == true then
		return
	end
	state.buyScheduled = true
	task.delay(Config.TUTORIAL_BUY_FALLBACK_DELAY, function()
		if states[player] ~= state or currentStep(player) ~= STEP.BUY then
			return
		end
		if workspace:GetAttribute("ProgressionOnline") == true then
			return
		end
		Notify.send(player, "info", "The shop is still being stocked. Keep welcoming your congregation!")
		setStep(player, STEP.MINYAN)
	end)
end

local function evaluate(player)
	local state = states[player]
	if not state then
		return
	end
	for _ = 1, 8 do
		local step = currentStep(player)
		local before = step
		if step == STEP.WELCOME then
			if (player:GetAttribute("PlotId") or 0) > 0 then
				setStep(player, STEP.CLAIM_PLOT)
			end
		elseif step == STEP.BUY then
			skipBuyIfOffline(player, state)
		elseif step == STEP.CLAIM_PLOT then
			if (player:GetAttribute("PlotId") or 0) > 0 then
				setStep(player, STEP.GREET)
			end
		elseif step == STEP.GREET then
			if (player:GetAttribute("PlotId") or 0) > 0 then
				CongregationService.spawnGuests(player)
				if CongregationService.greetCount(player) >= Constants.TUTORIAL_GREETERS then
					setStep(player, STEP.BUY)
				end
			else
				setStep(player, STEP.CLAIM_PLOT)
			end
		elseif step == STEP.MINYAN then
			if player:GetAttribute("HasMinyan") == true then
				setStep(player, STEP.DENOMINATION)
			end
		elseif step == STEP.DENOMINATION then
			local denomination = player:GetAttribute("Denomination")
			if type(denomination) == "string" and denomination ~= "" then
				setStep(player, STEP.DONE)
			end
		end
		if currentStep(player) == before then
			break
		end
	end
end

function TutorialService.init(player)
	local state = { connections = {}, minyanFired = player:GetAttribute("HasMinyan") == true }
	states[player] = state
	local function listen(attribute)
		table.insert(state.connections, player:GetAttributeChangedSignal(attribute):Connect(function()
			evaluate(player)
		end))
	end
	listen("TutorialStep")
	listen("PlotId")
	listen("Denomination")
	table.insert(state.connections, player:GetAttributeChangedSignal("HasMinyan"):Connect(function()
		if player:GetAttribute("HasMinyan") == true and not state.minyanFired then
			state.minyanFired = true
			minyanRemote:FireClient(player)
			celebrateMinyan(player)
		end
		evaluate(player)
	end))
	if pendingAdvance[player] then
		pendingAdvance[player] = nil
		if currentStep(player) == STEP.WELCOME then
			setStep(player, STEP.CLAIM_PLOT)
		end
	end
	evaluate(player)
end

function TutorialService.onGreeted(player)
	evaluate(player)
end

function TutorialService.onPurchased(player, offerId)
	if not Guard.isPlayer(player) then
		return
	end
	if currentStep(player) == STEP.BUY then
		setStep(player, STEP.MINYAN)
	end
end

function TutorialService.forget(player)
	pendingAdvance[player] = nil
	local state = states[player]
	if state then
		for _, connection in state.connections do
			connection:Disconnect()
		end
		states[player] = nil
	end
end

function TutorialService.bind()
	minyanRemote = Link.get(ReplicatedStorage, "Remotes", Constants.REMOTES.MinyanReached, "RemoteEvent")
	advanceRemote = Link.get(ReplicatedStorage, "Remotes", Constants.REMOTES.AdvanceTutorial, "RemoteEvent")
	local purchased = Link.get(ServerStorage, "Bridge", Constants.BRIDGE.Purchased, "BindableEvent")
	purchased.Event:Connect(TutorialService.onPurchased)
	Guard.connect(advanceRemote, "AdvanceTutorial", Config.COOLDOWNS.AdvanceTutorial, function(player)
		if not states[player] then
			pendingAdvance[player] = true
			return
		end
		if currentStep(player) ~= STEP.WELCOME then
			Guard.flag(player, "AdvanceTutorial", "not at step 0")
			return
		end
		setStep(player, STEP.CLAIM_PLOT)
	end)
end

function TutorialService.onClaimed(player)
	evaluate(player)
end

return TutorialService
