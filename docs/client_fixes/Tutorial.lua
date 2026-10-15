local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Theme = require(script.Parent.Theme)
local C = require(script.Parent.Components)
local Net = require(script.Parent.Net)
local Format = require(script.Parent.Format)
local Contract = require(script.Parent.Contract)

local Color, Space = Theme.Color, Theme.Space
local Step = Contract.Step
local player = Players.LocalPlayer

local Tutorial = {}

local TEXT = {
	[Step.ClaimPlot] = "Walk to the glowing pad to claim your plot!",
	[Step.Greet] = "Go to your synagogue door and welcome your first visitors!",
	[Step.Buy] = "Open the Shop and buy a Simple Siddur!",
	[Step.Minyan] = "Your congregation is growing. Ten people make a minyan!",
	[Step.Denomination] = "You have a minyan! Choose your denomination.",
}

local function rootPart()
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart")
end

local function plots()
	return workspace:FindFirstChild("Plots")
end

local function nearestFreePad()
	local folder, root = plots(), rootPart()
	if not folder or not root then
		return nil
	end
	local best, bestDistance
	for _, plot in folder:GetChildren() do
		local pad = plot:FindFirstChild("ClaimPad")
		if pad and pad:IsA("BasePart") and (plot:GetAttribute("OwnerUserId") or 0) == 0 then
			local d = (pad.Position - root.Position).Magnitude
			if not bestDistance or d < bestDistance then
				best, bestDistance = pad, d
			end
		end
	end
	return best
end

local function myDoor()
	local folder = plots()
	local plot = folder and folder:FindFirstChild("Plot" .. tostring(Net.attr("PlotId", 0)))
	return plot and plot:FindFirstChild("Door", true)
end

function Tutorial.new(ctx, hud, hooks)
	local self = {}
	local step = nil
	local banner, bannerText, bannerMoney
	local welcome
	local uiHighlight, stopPulse
	local worldTarget, worldAnchor, beam, att0, bobConnection = nil, nil, nil, nil, nil

	banner = C.panel(ctx.layers.hud, {
		name = "TutorialBanner",
		anchor = Vector2.new(0.5, 0),
		position = UDim2.new(0.5, 0, 0, Space.S),
		size = UDim2.new(1, -(Space.Touch + Space.S) * 2 - Space.S * 2, 0, Space.Touch + Space.XL),
		color = Color.Panel,
	})
	banner.Root.Visible = false
	C.new("UISizeConstraint", { MaxSize = Vector2.new(400, 1000) }, banner.Root)
	bannerText = C.text(banner.Frame, {
		text = "",
		size = "S",
		wrap = true,
		sizeU = UDim2.new(1, -Space.L, 0, Space.Touch - Space.XL),
		position = UDim2.fromOffset(Space.S, Space.XS),
	})
	bannerMoney = C.text(banner.Frame, {
		text = "",
		size = "M",
		color = Color.Yellow,
		sizeU = UDim2.new(1, -Space.L, 0, Space.XL),
		position = UDim2.new(0, Space.S, 1, -Space.XL - Space.XS),
	})
	local bannerHit = C.new("TextButton", { Text = "", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 5 }, banner.Frame)
	bannerHit.Activated:Connect(function()
		if step == Step.Denomination then
			hooks.openPicker()
		end
	end)

	local function paintMoney()
		bannerMoney.Text = "💰 You have " .. Format.short(Net.attr("Money", 0)) .. " money"
	end
	Net.onAttr("Money", paintMoney)
	paintMoney()

	local function clearUiHighlight()
		if stopPulse then
			stopPulse()
			stopPulse = nil
		end
		if uiHighlight then
			uiHighlight:Destroy()
			uiHighlight = nil
		end
	end

	local function highlightUi(target, arrowGlyph, arrowSide)
		clearUiHighlight()
		if not target then
			return
		end
		uiHighlight = C.new("Frame", {
			Name = "TutorialHighlight",
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.new(1, Space.M, 1, Space.M),
			ZIndex = 20,
		}, target)
		C.corner(uiHighlight, Theme.Radius.M)
		C.new("UIStroke", { Color = Color.Yellow, Thickness = Theme.Stroke.Thick, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, uiHighlight)
		local arrow = C.text(uiHighlight, {
			text = arrowGlyph,
			size = "XL",
			color = Color.Yellow,
			sizeU = UDim2.fromOffset(Space.XXL + Space.S, Space.XXL + Space.S),
			anchor = arrowSide == "right" and Vector2.new(0, 0.5) or Vector2.new(0.5, 1),
			position = arrowSide == "right" and UDim2.new(1, Space.XS, 0.5, 0) or UDim2.new(0.5, 0, 0, -Space.XS),
			z = 21,
		})
		stopPulse = C.pulse(uiHighlight, 1.08)
		local bob = TweenService:Create(arrow, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
			Position = arrowSide == "right" and UDim2.new(1, Space.M, 0.5, 0) or UDim2.new(0.5, 0, 0, -Space.M),
		})
		bob:Play()
		local previous = stopPulse
		stopPulse = function()
			previous()
			bob:Cancel()
		end
	end

	local function clearWorld()
		worldTarget = nil
		if bobConnection then
			bobConnection:Disconnect()
			bobConnection = nil
		end
		if worldAnchor then
			worldAnchor:Destroy()
			worldAnchor = nil
		end
		if att0 then
			att0:Destroy()
			att0 = nil
		end
		beam = nil
	end

	local function buildWorldMarker(targetPart)
		clearWorld()
		local root = rootPart()
		if not targetPart or not root then
			return
		end
		worldTarget = targetPart
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
		gui.Size = UDim2.fromOffset(64, 64)
		gui.AlwaysOnTop = true
		gui.LightInfluence = 0
		gui.Adornee = worldAnchor
		gui.Parent = worldAnchor
		C.text(gui, { text = "⬇", size = "XL", color = Color.Yellow })
		local att1 = Instance.new("Attachment")
		att1.Parent = worldAnchor
		att0 = Instance.new("Attachment")
		att0.Name = "TutorialBeamStart"
		att0.Parent = root
		beam = Instance.new("Beam")
		beam.Attachment0 = att0
		beam.Attachment1 = att1
		beam.Color = ColorSequence.new(Color.Yellow)
		beam.Width0 = 0.6
		beam.Width1 = 0.6
		beam.FaceCamera = true
		beam.LightEmission = 1
		beam.Parent = worldAnchor
		local started = os.clock()
		bobConnection = RunService.Heartbeat:Connect(function()
			if worldTarget and worldTarget.Parent then
				local lift = worldTarget.Size.Y / 2 + 6 + math.sin((os.clock() - started) * 4) * 1.2
				worldAnchor.Position = worldTarget.Position + Vector3.new(0, lift, 0)
			end
		end)
	end

	local function refreshWorldTarget()
		if step == Step.ClaimPlot then
			buildWorldMarker(nearestFreePad())
		elseif step == Step.Greet then
			buildWorldMarker(myDoor())
		else
			clearWorld()
		end
	end

	task.spawn(function()
		while true do
			task.wait(1)
			if step == Step.ClaimPlot then
				local pad = nearestFreePad()
				if pad ~= worldTarget or (att0 and not att0.Parent) then
					refreshWorldTarget()
				end
			elseif step == Step.Greet and (att0 and not att0.Parent) then
				refreshWorldTarget()
			end
		end
	end)

	local function closeWelcome()
		if welcome then
			welcome:Close()
			welcome = nil
		end
	end

	local function showWelcome()
		if welcome then
			return
		end
		welcome = C.popup(ctx.layers.popup, {
			title = "Welcome, Rabbi!",
			color = Color.Blue,
			closable = false,
			size = UDim2.new(1, -Space.XL * 2, 0, 260),
			maxSize = Vector2.new(440, 260),
		})
		C.text(welcome.Body, {
			text = "You lead a brand new synagogue.\nWelcome people, grow your congregation and build something beautiful. We will guide you step by step.",
			size = "S",
			wrap = true,
			sizeU = UDim2.new(1, 0, 0, 100),
		})
		C.text(welcome.Body, {
			text = "💰 You start with " .. Format.short(Net.attr("Money", 0)) .. " money",
			size = "M",
			color = Color.Yellow,
			sizeU = UDim2.new(1, 0, 0, Space.XL),
			position = UDim2.fromOffset(0, 100),
		})
		C.button(welcome.Body, {
			text = "Let's go!",
			color = Color.Green,
			size = UDim2.fromOffset(180, Space.Tab),
			anchor = Vector2.new(0.5, 1),
			position = UDim2.new(0.5, 0, 1, 0),
			onClick = function()
				Net.advanceTutorial()
				closeWelcome()
			end,
		})
	end

	local function apply(newStep)
		step = newStep or Step.Done
		clearUiHighlight()
		if step ~= Step.Welcome then
			closeWelcome()
		end
		if step == Step.Welcome then
			banner.Root.Visible = false
			clearWorld()
			showWelcome()
			return
		end
		local text = TEXT[step]
		banner.Root.Visible = text ~= nil
		bannerText.Text = text or ""
		refreshWorldTarget()
		if step == Step.Buy then
			highlightUi(hud.targets.Shop, "◀", "right")
		elseif step == Step.Minyan then
			highlightUi(hud.targets.Congregation, "⬇", "top")
		elseif step == Step.Denomination then
			hooks.openPicker()
		end
	end

	Net.onAttr("TutorialStep", apply)
	player.CharacterAdded:Connect(function()
		task.wait(1)
		refreshWorldTarget()
	end)
	apply(Net.attr("TutorialStep", Step.Welcome))
	return self
end

return Tutorial
