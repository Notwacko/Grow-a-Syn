local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

if not RunService:IsStudio() then
	return
end

local Constants = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Constants"))
local ModelLookup = require(script.Parent.Parent.ModelLookup)
local Assets = require(script.Parent.Parent.Assets)

local REMOTES = {
	{ "RE_Notify", "RemoteEvent", "A" },
	{ "RE_ClaimPlot", "RemoteEvent", "A" },
	{ "RE_ExpandLand", "RemoteEvent", "A" },
	{ "RE_AdvanceTutorial", "RemoteEvent", "A" },
	{ "RE_MinyanReached", "RemoteEvent", "A" },
	{ "RF_GetCatalog", "RemoteFunction", "B" },
	{ "RF_GetInventory", "RemoteFunction", "B" },
	{ "RE_InventoryChanged", "RemoteEvent", "B" },
	{ "RF_Buy", "RemoteFunction", "B" },
	{ "RF_Merge", "RemoteFunction", "B" },
	{ "RF_Equip", "RemoteFunction", "B" },
	{ "RF_Unequip", "RemoteFunction", "B" },
	{ "RF_ChooseDenomination", "RemoteFunction", "B" },
	{ "RF_UpgradeBuilding", "RemoteFunction", "B" },
}

local BRIDGE = {
	{ "SpendMoney", "BindableFunction" },
	{ "GrantMoney", "BindableEvent" },
	{ "Purchased", "BindableEvent" },
}

local PLOT_PARTS = { "Land", "ClaimPad", "NpcSpawn", "BuildingAnchor" }

local pass, fail, missing = 0, 0, 0

local function ok(label)
	pass += 1
	print("[ContractCheck] PASS    " .. label)
end

local function bad(label, detail)
	fail += 1
	warn("[ContractCheck] FAIL    " .. label .. (detail and (": " .. detail) or ""))
end

local function absent(label)
	missing += 1
	print("[ContractCheck] MISSING " .. label .. " (procedural fallback or later phase)")
end

local function checkTypeOf(value, expected)
	return typeof(value) == expected
end

local function buildingNames()
	local names = { Constants.BUILDING_STARTER }
	for _, denomination in Constants.DENOMINATIONS do
		for tier = 2, Constants.MAX_TIER do
			table.insert(names, denomination .. "_T" .. tier)
		end
	end
	return names
end

local function tierOf(name)
	return tonumber(string.match(name, "_T(%d)$")) or 1
end

local function checkBuilding(name, model)
	local problems = {}
	if not model:IsA("Model") then
		bad(name, "not a Model")
		return
	end
	local floor = model:FindFirstChild("Floor", true)
	if not (floor and floor:IsA("BasePart")) then
		table.insert(problems, "no Floor part")
	elseif not model.PrimaryPart or model.PrimaryPart.Name ~= "Floor" then
		table.insert(problems, "PrimaryPart is not Floor (core will fix it at runtime)")
	end
	local door = model:FindFirstChild("Door", true)
	if not (door and door:IsA("BasePart")) then
		table.insert(problems, "no Door part")
	else
		local height = math.max(door.Size.X, door.Size.Y, door.Size.Z)
		if math.abs(height - 9) > 1.5 then
			table.insert(problems, string.format("Door is %.1f studs tall, expected about 9 (run the import fixer)", height))
		end
	end
	local seatsFolder = model:FindFirstChild("Seats", true)
	local seats = 0
	if seatsFolder then
		for _, child in seatsFolder:GetDescendants() do
			if child:IsA("BasePart") and string.match(child.Name, "^Seat%d+$") then
				seats += 1
			end
		end
	end
	local expected = Constants.seatsForTier(tierOf(name))
	if seats ~= expected then
		table.insert(problems, string.format("%d seats, expected %d", seats, expected))
	end
	local slots = model:FindFirstChild("Slots", true)
	local lacking = {}
	for _, slotName in Constants.SLOT_NAMES do
		if not (slots and slots:FindFirstChild(slotName, true)) then
			table.insert(lacking, slotName)
		end
	end
	if #lacking > 0 then
		table.insert(problems, #lacking .. " slots missing (" .. table.concat(lacking, ", ", 1, math.min(#lacking, 4)) .. "...)")
	end
	if #problems == 0 then
		ok(name .. " building (" .. seats .. " seats, 26 slots)")
	else
		bad(name .. " building", table.concat(problems, "; "))
	end
end

local function lookup(name)
	local instance = ModelLookup.get(name)
	if Assets.isPlaceholder(instance) then
		instance:Destroy()
		return nil
	end
	return instance
end

task.wait(12)

print("[ContractCheck] ---- start ----")

if Workspace:GetAttribute("CoreOnline") == true then
	ok("CoreOnline")
else
	bad("CoreOnline", "core is not online")
end
if Workspace:GetAttribute("ProgressionOnline") == true then
	ok("ProgressionOnline (B)")
else
	absent("ProgressionOnline (B has not come online)")
end
if checkTypeOf(Workspace:GetAttribute("EventMult"), "number") then
	ok("EventMult")
else
	bad("EventMult", "workspace attribute missing")
end

local remotes = ReplicatedStorage:FindFirstChild("Remotes")
for _, entry in REMOTES do
	local object = remotes and remotes:FindFirstChild(entry[1])
	if object and object:IsA(entry[2]) then
		ok(entry[1] .. " (" .. entry[3] .. ")")
	elseif entry[3] == "A" then
		bad(entry[1], "missing or wrong class")
	else
		absent(entry[1] .. " (B)")
	end
end

local bridge = ServerStorage:FindFirstChild("Bridge")
for _, entry in BRIDGE do
	local object = bridge and bridge:FindFirstChild(entry[1])
	if object and object:IsA(entry[2]) then
		ok("Bridge." .. entry[1])
	else
		bad("Bridge." .. entry[1], "missing or wrong class")
	end
end

local plots = Workspace:FindFirstChild("Plots")
for index = 1, Constants.PLOT_COUNT do
	local plot = plots and plots:FindFirstChild("Plot" .. index)
	local problems = {}
	if not plot then
		table.insert(problems, "missing")
	else
		for _, partName in PLOT_PARTS do
			if not plot:FindFirstChild(partName) then
				table.insert(problems, "no " .. partName)
			end
		end
		if not plot:FindFirstChild("Building") then
			table.insert(problems, "no Building model")
		end
		if plot:GetAttribute("OwnerUserId") == nil or plot:GetAttribute("BuildingVersion") == nil then
			table.insert(problems, "attributes missing")
		end
	end
	if #problems == 0 then
		ok("Plot" .. index)
	else
		bad("Plot" .. index, table.concat(problems, ", "))
	end
end

for _, player in Players:GetPlayers() do
	local lacking = {}
	for name, default in Constants.CORE_ATTRIBUTES do
		if typeof(player:GetAttribute(name)) ~= typeof(default) then
			table.insert(lacking, name)
		end
	end
	if #lacking == 0 then
		ok(player.Name .. " core attributes")
	else
		bad(player.Name .. " core attributes", table.concat(lacking, ", "))
	end
	local progression = {}
	for name, default in Constants.PROGRESSION_ATTRIBUTES do
		if typeof(player:GetAttribute(name)) ~= typeof(default) then
			table.insert(progression, name)
		end
	end
	if #progression == 0 then
		ok(player.Name .. " progression attributes (B)")
	else
		absent(player.Name .. " progression attributes not set yet: " .. table.concat(progression, ", "))
	end
end

for _, name in buildingNames() do
	local model = lookup(name)
	if model then
		checkBuilding(name, model)
		model:Destroy()
	else
		absent(name)
	end
end

for variant = 1, 6 do
	local name = "congregant_" .. variant
	local model = lookup(name)
	if not model then
		absent(name)
	else
		local size = model:IsA("Model") and select(2, model:GetBoundingBox()) or model.Size
		local cloth = false
		for _, descendant in model:GetDescendants() do
			if descendant:IsA("BasePart") and string.sub(descendant.Name, 1, 5) == "Cloth" then
				cloth = true
			end
		end
		if model:IsA("Model") and cloth and size.Y > 3 and size.Y < 8 then
			ok(string.format("%s (%.1f studs tall)", name, size.Y))
		else
			bad(name, string.format("expected a Model with Cloth parts and a height near 5.5, got height %.1f cloth=%s", size.Y, tostring(cloth)))
		end
		model:Destroy()
	end
end

for _, name in { "kippah", "tallit" } do
	local model = lookup(name)
	if not model then
		absent(name)
	else
		if model:IsA("Accessory") and model:FindFirstChild("Handle") then
			ok(name .. " accessory")
		else
			bad(name, "must be an Accessory with a Handle")
		end
		model:Destroy()
	end
end

for _, name in { "prop_tree", "prop_fence", "prop_bench", "prop_lamp" } do
	local model = lookup(name)
	if model then
		ok(name)
		model:Destroy()
	else
		absent(name)
	end
end

print(string.format("[ContractCheck] ---- done: %d passed, %d failed, %d missing ----", pass, fail, missing))
