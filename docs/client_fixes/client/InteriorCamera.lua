local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local TAG = "InteriorCameraBox"
local MARGIN = Vector3.new(0.8, 0.5, 0.8)
local HEAD = Vector3.new(0, 1.5, 0)
local RESPONSE = 9

local InteriorCamera = {}

local player = Players.LocalPlayer
local started = false
local lastBox = nil
local smooth = 1

local function containing(position)
	for _, box in CollectionService:GetTagged(TAG) do
		if box:IsA("BasePart") then
			local point = box.CFrame:PointToObjectSpace(position)
			local half = box.Size / 2
			if math.abs(point.X) <= half.X and math.abs(point.Y) <= half.Y and math.abs(point.Z) <= half.Z then
				return box
			end
		end
	end
	return nil
end

local function limitAlong(headValue, cameraValue, limit)
	if math.abs(cameraValue) <= limit then
		return 1
	end
	local target = cameraValue > 0 and limit or -limit
	local span = cameraValue - headValue
	if math.abs(span) < 1e-4 then
		return 1
	end
	return math.clamp((target - headValue) / span, 0, 1)
end

local function step(dt)
	local camera = workspace.CurrentCamera
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not camera or not root then
		return
	end
	local box = containing(root.Position)
	if box then
		lastBox = box
	end
	local active = box or lastBox
	if not active or not active.Parent then
		smooth = 1
		lastBox = nil
		return
	end
	local frame = active.CFrame
	local half = active.Size / 2 - MARGIN
	local head = frame:PointToObjectSpace(root.Position + HEAD)
	local cameraLocal = frame:PointToObjectSpace(camera.CFrame.Position)
	local goal = 1
	if box then
		goal = math.min(limitAlong(head.X, cameraLocal.X, half.X), limitAlong(head.Y, cameraLocal.Y, half.Y), limitAlong(head.Z, cameraLocal.Z, half.Z))
	end
	smooth += (goal - smooth) * (1 - math.exp(-dt * RESPONSE))
	if goal >= 1 and smooth > 0.995 then
		smooth = 1
		if not box then
			lastBox = nil
		end
		return
	end
	local placed = head:Lerp(cameraLocal, smooth)
	camera.CFrame = CFrame.new(frame:PointToWorldSpace(placed)) * camera.CFrame.Rotation
end

function InteriorCamera.start()
	if started then
		return
	end
	started = true
	RunService:BindToRenderStep("GrowInteriorCamera", Enum.RenderPriority.Camera.Value + 1, step)
end

return InteriorCamera
