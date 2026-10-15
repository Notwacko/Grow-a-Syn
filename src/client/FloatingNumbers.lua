-- Pooled BillboardGuis that rise from congregants ("+N") when income ticks. Capped to ~3 per second.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Theme = require(script.Parent.Theme)
local C = require(script.Parent.Components)

local player = Players.LocalPlayer

local FloatingNumbers = {}

local POOL_MAX = 8
local MIN_GAP = 0.33
local pool = {}
local lastSpawn = 0
local folder

local function take()
	local entry = table.remove(pool)
	if entry then
		return entry
	end
	local gui = Instance.new("BillboardGui")
	gui.Name = "FloatingNumber"
	gui.Size = UDim2.fromOffset(120, Theme.Space.XXL + Theme.Space.S)
	gui.AlwaysOnTop = true
	gui.LightInfluence = 0
	gui.Enabled = false
	gui.Parent = folder
	local label = C.text(gui, { text = "", size = "M", color = Theme.Color.Yellow })
	return { gui = gui, label = label }
end

local function pickAdornee()
	local mine = {}
	for _, model in CollectionService:GetTagged("Congregant") do
		if model:GetAttribute("OwnerUserId") == player.UserId then
			table.insert(mine, model)
		end
	end
	if #mine > 0 then
		local model = mine[math.random(#mine)]
		return model:FindFirstChild("Root") or model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
	end
	local character = player.Character
	return character and (character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart"))
end

function FloatingNumbers.init(playerGui)
	folder = Instance.new("Folder")
	folder.Name = "FloatingNumbers"
	folder.Parent = playerGui
end

function FloatingNumbers.spawn(text)
	local now = os.clock()
	if not folder or now - lastSpawn < MIN_GAP then
		return
	end
	local adornee = pickAdornee()
	if not adornee then
		return
	end
	lastSpawn = now
	local entry = take()
	entry.label.Text = text
	entry.label.TextTransparency = 0
	entry.label.UIStroke.Transparency = 0
	entry.gui.Adornee = adornee
	entry.gui.StudsOffset = Vector3.new(math.random(-10, 10) / 10, 3, 0)
	entry.gui.Enabled = true
	local info = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(entry.gui, info, { StudsOffset = entry.gui.StudsOffset + Vector3.new(0, 4, 0) }):Play()
	TweenService:Create(entry.label, info, { TextTransparency = 1 }):Play()
	TweenService:Create(entry.label.UIStroke, info, { Transparency = 1 }):Play()
	task.delay(1.05, function()
		entry.gui.Enabled = false
		entry.gui.Adornee = nil
		if #pool < POOL_MAX then
			table.insert(pool, entry)
		else
			entry.gui:Destroy()
		end
	end)
end

return FloatingNumbers
