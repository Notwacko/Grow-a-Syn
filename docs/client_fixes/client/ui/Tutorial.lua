local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Theme = require(script.Parent.Theme)
local Ui = require(script.Parent.Ui)
local Util = require(script.Parent.Util)
local Store = require(script.Parent.Store)
local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))

local STEP = Constants.TUTORIAL
local player = Players.LocalPlayer

local Tutorial = {}

local TEXT = {
	[STEP.CLAIM_PLOT] = "Walk to the glowing pad to claim your plot!",
	[STEP.GREET] = "Go to your synagogue door and welcome your first visitors! (Press E or tap Greet)",
	[STEP.BUY] = "Open the Shop and buy a Simple Siddur!",
	[STEP.MINYAN] = "Keep welcoming guests. Ten people make a minyan!",
	[STEP.DENOMINATION] = "You have a minyan! Choose your path.",
}

local function rootPart()
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart")
end

local function nearestFreePad()
	local folder = workspace:FindFirstChild("Plots")
	local root = rootPart()
	if not folder or not root then
		return nil
	end
	local best, bestDistance
	for _, plot in folder:GetChildren() do
		local pad = plot:FindFirstChild("ClaimPad")
		if pad and pad:IsA("BasePart") and (plot:GetAttribute("OwnerUserId") or 0) == 0 then
			local distance = (pad.Position - root.Position).Magnitude
			if not bestDistance or distance < bestDistance then
				best, bestDistance = pad, distance
			end
		end
	end
	return best
end

local function nearestGreeter()
	local folder = workspace:FindFirstChild("Plots")
	local plot = folder and folder:FindFirstChild("Plot" .. tostring(Store.attr("PlotId", 0)))
	local congregants = plot and plot:FindFirstChild("Congregants")
	local root = rootPart()
	if not congregants or not root then
		return nil
	end
	local best, bestDistance
	for _, model in congregants:GetChildren() do
		local point = model:FindFirstChild("GreetPoint", true)
		if point and point:IsA("Attachment") then
			local distance = (point.WorldPosition - root.Position).Magnitude
			if not bestDistance or distance < bestDistance then
				best, bestDistance = point, distance
			end
		end
	end
	return best
end

function Tutorial.start(root, ctx)
	local tutorial = {}
	local banner = Ui.frame(root, {
		name = "Banner",
		size = UDim2.fromOffset(620, 84),
		position = UDim2.new(0.5, 0, 0, 74),
		anchor = Vector2.new(0.5, 0),
		color = Theme.ink,
		transparency = 0,
		radius = 24,
		stroke = 4,
		visible = false,
		z = 5,
	})
	banner.UIStroke.Color = Theme.gold[1]
	Ui.gradient(banner, { Color3.fromRGB(52, 66, 112), Color3.fromRGB(30, 42, 74) }, 90)
	Ui.make("UISizeConstraint", { MaxSize = Vector2.new(620, 100) }, banner)
	local chip = Ui.frame(banner, { size = UDim2.fromOffset(70, 40), position = UDim2.new(0, 14, 0.5, 0), anchor = Vector2.new(0, 0.5), color = Theme.gold[1], transparency = 0, radius = 20, stroke = 3, z = 6 })
	Ui.gradient(chip, Theme.gold, 90)
	local chipLabel = Ui.label(chip, { text = "1/5", textSize = 24, size = UDim2.fromScale(1, 1), stroke = 2.5, z = 7 })
	local text = Ui.label(banner, {
		text = "",
		textSize = 22,
		size = UDim2.new(1, -110, 1, -12),
		position = UDim2.fromOffset(96, 6),
		xalign = Enum.TextXAlignment.Left,
		wrap = true,
		stroke = 2.5,
		fit = true,
		z = 6,
	})
	text.Font = Theme.titleFont

	local welcome = Ui.modal(ctx.popupRoot, { name = "Welcome", title = "Welcome, Rabbi!", size = UDim2.new(0.8, 0, 0.8, 0), max = Vector2.new(640, 520), headerPalette = Theme.blue, dismiss = false })
	welcome.close.root.Visible = false
	Ui.image(welcome.body, { image = "synagogue", size = UDim2.fromOffset(150, 150), position = UDim2.new(0.5, 0, 0, 6), anchor = Vector2.new(0.5, 0), z = 5 })
	local message = Ui.label(welcome.body, {
		text = "You are about to build your very own synagogue. Welcome guests, grow your congregation, decorate with beautiful items and watch your community flourish.",
		textSize = 22,
		color = Theme.ink,
		stroke = false,
		size = UDim2.new(1, -30, 0, 130),
		position = UDim2.new(0, 15, 0, 166),
		wrap = true,
		z = 5,
	})
	message.Font = Theme.bodyFont
	local go = Ui.button(welcome.body, {
		palette = Theme.green,
		size = UDim2.fromOffset(300, 66),
		position = UDim2.new(0.5, 0, 1, -8),
		anchor = Vector2.new(0.5, 1),
		text = "Let's Build!",
		textSize = 32,
	})
	go.click(function()
		go.setEnabled(false)
		Store.remote("RE_AdvanceTutorial")
		welcome.hide(true)
		task.delay(1, function()
			go.setEnabled(true)
		end)
	end)

	local worldAnchor, worldBeam, beamStart, worldTarget, worldConnection
	local function clearWorld()
		if worldConnection then
			worldConnection:Disconnect()
			worldConnection = nil
		end
		for _, object in { worldAnchor, beamStart } do
			if object then
				object:Destroy()
			end
		end
		worldAnchor, worldBeam, beamStart, worldTarget = nil, nil, nil, nil
	end

	local function mark(resolver)
		clearWorld()
		local rootPart0 = rootPart()
		if not rootPart0 then
			return
		end
		worldAnchor = Instance.new("Part")
		worldAnchor.Name = "TutorialArrow"
		worldAnchor.Anchored = true
		worldAnchor.CanCollide = false
		worldAnchor.CanQuery = false
		worldAnchor.CanTouch = false
		worldAnchor.Transparency = 1
		worldAnchor.Size = Vector3.one
		worldAnchor.Parent = workspace
		local gui = Instance.new("BillboardGui")
		gui.Size = UDim2.fromOffset(80, 80)
		gui.AlwaysOnTop = true
		gui.LightInfluence = 0
		gui.Adornee = worldAnchor
		gui.Parent = worldAnchor
		local arrow = Ui.label(gui, { text = "v", textSize = 70, color = Theme.gold[1], stroke = 5, size = UDim2.fromScale(1, 1), z = 5 })
		arrow.Font = Theme.titleFont
		local endAttachment = Instance.new("Attachment")
		endAttachment.Parent = worldAnchor
		beamStart = Instance.new("Attachment")
		beamStart.Name = "TutorialBeamStart"
		beamStart.Parent = rootPart0
		worldBeam = Instance.new("Beam")
		worldBeam.Attachment0 = beamStart
		worldBeam.Attachment1 = endAttachment
		worldBeam.Color = ColorSequence.new(Theme.gold[1])
		worldBeam.Width0 = 0.7
		worldBeam.Width1 = 0.7
		worldBeam.FaceCamera = true
		worldBeam.LightEmission = 1
		worldBeam.Transparency = NumberSequence.new(0.3)
		worldBeam.Parent = worldAnchor
		worldConnection = RunService.RenderStepped:Connect(function()
			local target = resolver()
			if not target then
				worldBeam.Enabled = false
				gui.Enabled = false
				return
			end
			worldBeam.Enabled = true
			gui.Enabled = true
			local position = typeof(target) == "Instance" and (target:IsA("Attachment") and target.WorldPosition or target.Position) or target
			local bob = math.sin(os.clock() * 5) * 0.7
			worldAnchor.Position = position + Vector3.new(0, 7 + bob, 0)
		end)
	end

	local highlightStop
	local function stopHighlight()
		if highlightStop then
			highlightStop()
			highlightStop = nil
		end
		if ctx.hud then
			ctx.hud.highlight("shop", false)
		end
	end

	local lastStep = nil
	local pickerShown = false
	local function apply()
		local step = Store.attr("TutorialStep", 0)
		if step == lastStep then
			return
		end
		local previous = lastStep
		lastStep = step
		if step == STEP.DONE and previous ~= nil and previous < STEP.DONE and ctx.hud then
			ctx.hud.highlight("daily", true)
			ctx.hud.highlight("wheel", true)
			task.delay(2, function()
				ctx.toast("gold", "Grab your Daily Reward and spin the Lucky Wheel!")
			end)
		end
		stopHighlight()
		clearWorld()
		banner.Visible = TEXT[step] ~= nil
		if TEXT[step] then
			text.Text = TEXT[step]
			chipLabel.Text = string.format("%d/5", math.clamp(step, 1, 5))
			Ui.pop(banner, 1.04)
		end
		if step == STEP.WELCOME then
			if not welcome.open then
				task.delay(1.2, function()
					if Store.attr("TutorialStep", 0) == STEP.WELCOME then
						welcome.show()
					end
				end)
			end
		else
			welcome.hide(true)
		end
		if step == STEP.CLAIM_PLOT then
			mark(nearestFreePad)
		elseif step == STEP.GREET then
			mark(nearestGreeter)
		elseif step == STEP.BUY then
			if ctx.hud then
				ctx.hud.highlight("shop", true)
			end
		elseif step == STEP.DENOMINATION then
			if not pickerShown then
				pickerShown = true
				task.delay(1.5, function()
					if Store.attr("TutorialStep", 0) == STEP.DENOMINATION and (Store.attr("Denomination", "") == "") then
						ctx.denomination.show()
					end
				end)
			end
		end
	end

	Store.onAttr("TutorialStep", apply)
	Store.minyan:connect(function()
		if Store.attr("Denomination", "") == "" then
			task.delay(2.5, function()
				if Store.attr("Denomination", "") == "" and not ctx.denomination.isOpen() then
					ctx.denomination.show()
				end
			end)
		end
	end)
	Store.onAttr("Denomination", function(value)
		if value and value ~= "" then
			ctx.denomination.hide()
		end
	end)
	tutorial.apply = function()
		lastStep = nil
		apply()
	end
	tutorial.setBannerVisible = function(visible)
		banner.Visible = visible and TEXT[Store.attr("TutorialStep", 0)] ~= nil
	end
	tutorial.banner = banner
	apply()
	return tutorial
end

return Tutorial
