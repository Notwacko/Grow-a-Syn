-- Mock-mode test bench (only created when the server is absent): fake plots for the tutorial arrows and
-- a small collapsible panel to push the game state around on a phone-sized window.
local Players = game:GetService("Players")

local Theme = require(script.Parent.Theme)
local C = require(script.Parent.Components)
local Net = require(script.Parent.Net)

local Color, Space = Theme.Color, Theme.Space
local player = Players.LocalPlayer

local Dev = {}

local function part(parent, name, size, position, color)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.Position = position
	p.Color = color
	p.Material = Enum.Material.Neon
	p.Parent = parent
	return p
end

local function buildMockWorld()
	if workspace:FindFirstChild("Plots") then
		return
	end
	local character = player.Character or player.CharacterAdded:Wait()
	local root = character:WaitForChild("HumanoidRootPart", 10)
	local origin = root and root.Position or Vector3.new(0, 5, 0)
	local plots = Instance.new("Folder")
	plots.Name = "Plots"
	plots.Parent = workspace
	local mine = Instance.new("Model")
	mine.Name = "Plot1"
	mine:SetAttribute("OwnerUserId", player.UserId)
	mine.Parent = plots
	part(mine, "ClaimPad", Vector3.new(0.6, 11, 11), origin + Vector3.new(-40, -2, 20), Color3.fromRGB(120, 120, 120))
	local building = Instance.new("Model")
	building.Name = "Building"
	building.Parent = mine
	part(building, "Door", Vector3.new(6, 9, 1), origin + Vector3.new(-40, 2.5, 50), Color.Orange)
	local free = Instance.new("Model")
	free.Name = "Plot2"
	free:SetAttribute("OwnerUserId", 0)
	free.Parent = plots
	part(free, "ClaimPad", Vector3.new(0.6, 11, 11), origin + Vector3.new(40, -2, 10), Color.Green)
end

function Dev.new(ctx)
	task.spawn(buildMockWorld)
	local toggle
	local column = C.new("Frame", {
		Name = "DevColumn",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -Space.S, 0, Space.S + Space.Tab + Space.XS),
		AutomaticSize = Enum.AutomaticSize.XY,
		Size = UDim2.new(),
		Visible = false,
	}, ctx.layers.dev)
	C.new("UIListLayout", { Padding = UDim.new(0, Space.XS), HorizontalAlignment = Enum.HorizontalAlignment.Right, SortOrder = Enum.SortOrder.LayoutOrder }, column)
	local function add(text, order, fn)
		C.button(column, { text = text, textSize = "S", color = Color.Panel, size = UDim2.fromOffset(Space.Touch + Space.XL, Space.Tab), order = order, onClick = fn })
	end
	add("Step", 1, function()
		Net.advanceTutorial()
	end)
	add("+Greet", 2, function()
		player:SetAttribute("Congregation", math.min((player:GetAttribute("Congregation") or 0) + 1, player:GetAttribute("MaxCongregation") or 12))
	end)
	add("Minyan", 3, function()
		player:SetAttribute("Congregation", 10)
		player:SetAttribute("HasMinyan", true)
		Net.MinyanReached:fire()
	end)
	add("+Money", 4, function()
		player:SetAttribute("Money", (player:GetAttribute("Money") or 0) + 250)
	end)
	add("Tier+", 5, function()
		if (player:GetAttribute("Denomination") or "") == "" then
			ctx.toast("Choose a denomination first", "error")
		else
			Net.upgradeBuilding()
		end
	end)
	add("Boost", 6, function()
		player:SetAttribute("BoostMult", 2)
		player:SetAttribute("BoostEndsAt", workspace:GetServerTimeNow() + 90)
	end)
	add("Toast", 7, function()
		ctx.toast("Thank you for coming to services!", "info")
	end)
	toggle = C.button(ctx.layers.dev, {
		text = "DEV",
		textSize = "S",
		color = Color.Ink,
		size = UDim2.fromOffset(Space.Tab, Space.Tab),
		anchor = Vector2.new(1, 0),
		position = UDim2.new(1, -Space.S, 0, Space.S),
		onClick = function()
			column.Visible = not column.Visible
		end,
	})
end

return Dev
