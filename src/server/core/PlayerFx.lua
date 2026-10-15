local Config = require(script.Parent.Config)

local PlayerFx = {}

local states = {}

local function tierColor(player)
	local tier = math.clamp(tonumber(player:GetAttribute("Tier")) or 1, 1, 7)
	return Config.TIER_COLORS[tier]
end

local function recolor(state)
	local color = tierColor(state.player)
	if state.trail then
		state.trail.Color = ColorSequence.new(Color3.new(1, 1, 1), color)
	end
	if state.sparkles then
		state.sparkles.Color = ColorSequence.new(Color3.new(1, 1, 1), color)
	end
end

local function attach(state, character)
	local root = character:WaitForChild("HumanoidRootPart", 10)
	if not root or not character.Parent then
		return
	end
	local top = Instance.new("Attachment")
	top.Name = "CoreTrailTop"
	top.Position = Vector3.new(0, 0.9, 0.4)
	top.Parent = root
	local bottom = Instance.new("Attachment")
	bottom.Name = "CoreTrailBottom"
	bottom.Position = Vector3.new(0, -1.7, 0.4)
	bottom.Parent = root
	local trail = Instance.new("Trail")
	trail.Name = "CoreTrail"
	trail.Attachment0 = top
	trail.Attachment1 = bottom
	trail.Lifetime = 0.6
	trail.LightEmission = 0.9
	trail.FaceCamera = true
	trail.MinLength = 0.05
	trail.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.25), NumberSequenceKeypoint.new(1, 1) })
	trail.WidthScale = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0.15) })
	trail.Parent = root
	local sparkles = Instance.new("ParticleEmitter")
	sparkles.Name = "CoreSparkles"
	sparkles.Rate = 5
	sparkles.Lifetime = NumberRange.new(0.9, 1.4)
	sparkles.Speed = NumberRange.new(1, 3)
	sparkles.SpreadAngle = Vector2.new(180, 180)
	sparkles.Acceleration = Vector3.new(0, 1.5, 0)
	sparkles.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0) })
	sparkles.LightEmission = 1
	sparkles.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1) })
	sparkles.Parent = root
	state.trail = trail
	state.sparkles = sparkles
	recolor(state)
end

function PlayerFx.watch(player)
	local state = { player = player, connections = {} }
	states[player] = state
	table.insert(state.connections, player.CharacterAdded:Connect(function(character)
		state.trail = nil
		state.sparkles = nil
		task.spawn(attach, state, character)
	end))
	table.insert(state.connections, player:GetAttributeChangedSignal("Tier"):Connect(function()
		recolor(state)
	end))
	if player.Character then
		task.spawn(attach, state, player.Character)
	end
end

function PlayerFx.forget(player)
	local state = states[player]
	if state then
		for _, connection in state.connections do
			connection:Disconnect()
		end
		states[player] = nil
	end
end

return PlayerFx
