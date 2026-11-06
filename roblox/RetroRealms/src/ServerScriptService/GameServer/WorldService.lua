--[[
	WorldService
	Tracks which world each player is standing in, discovers worlds and
	towns, sets respawn towns and handles fast travel between discovered towns.

	Map setup (the greybox builder makes all of this for you):
	  Workspace > WorldZones : Parts with attribute WorldId. Make them tall and
	                           cover each area. CanCollide off, invisible.
	  Workspace > Towns      : SpawnLocations with attributes TownName and WorldId.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local Worlds = require(Shared:WaitForChild("Worlds"))

local Remotes = require(script.Parent.Remotes)
local PlayerDataService = require(script.Parent.PlayerDataService)

local WorldService = {}

local zones = {} -- { Part, WorldId }
local towns = {} -- [townName] = { Name, WorldId, Part }
local currentWorld = {} -- [player] = worldId
local lastTravel = {}

local function pointInZone(part, position)
	local rel = part.CFrame:PointToObjectSpace(position)
	local half = part.Size / 2
	return math.abs(rel.X) <= half.X and math.abs(rel.Z) <= half.Z and math.abs(rel.Y) <= half.Y
end

function WorldService.GetWorldAt(position)
	for _, zone in ipairs(zones) do
		if pointInZone(zone.Part, position) then
			return zone.WorldId
		end
	end
	return nil
end

function WorldService.GetTown(name)
	return towns[name]
end

local function getRespawnPart(player)
	local data = PlayerDataService.Get(player)
	local name = data and data.RespawnTown or GameConfig.StartingTown
	local town = towns[name] or towns[GameConfig.StartingTown]
	if town then
		return town.Part
	end
	return workspace:FindFirstChildWhichIsA("SpawnLocation", true)
end

-- Call before player:LoadCharacter()
function WorldService.PrepareRespawn(player)
	local part = getRespawnPart(player)
	if part and part:IsA("SpawnLocation") then
		player.RespawnLocation = part
	end
end

-- Call from CharacterAdded. Makes sure the player ends up at their town.
function WorldService.PlaceAtSpawn(player, character)
	local part = getRespawnPart(player)
	if not part then
		return
	end
	local hrp = character:WaitForChild("HumanoidRootPart", 10)
	if not hrp then
		return
	end
	task.wait()
	if (hrp.Position - part.Position).Magnitude > 25 then
		character:PivotTo(part.CFrame + Vector3.new(0, 5, 0))
	end
end

-- Forget the player's current world so the banner shows again (after a dungeon)
function WorldService.ResetZone(player)
	currentWorld[player] = nil
end

local function discoverTown(player, data, town)
	if data.RespawnTown == town.Name then
		return
	end
	local isNew = not data.DiscoveredTowns[town.Name]
	data.DiscoveredTowns[town.Name] = true
	data.RespawnTown = town.Name
	WorldService.PrepareRespawn(player)
	if isNew then
		Remotes.Notify:FireClient(player, "Town discovered: " .. town.Name .. " (fast travel unlocked)", Color3.fromRGB(140, 220, 255))
	else
		Remotes.Notify:FireClient(player, "Respawn point set: " .. town.Name, Color3.fromRGB(200, 200, 200))
	end
	PlayerDataService.Sync(player)
end

local function updatePlayer(player)
	if player:GetAttribute("InDungeon") then
		return
	end
	local data = PlayerDataService.Get(player)
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not data or not hrp then
		return
	end

	local worldId = WorldService.GetWorldAt(hrp.Position)
	if worldId and worldId ~= currentWorld[player] then
		currentWorld[player] = worldId
		player:SetAttribute("WorldId", worldId)
		Remotes.ZoneChanged:FireClient(player, "World", worldId)
		if not data.Discovered[worldId] then
			data.Discovered[worldId] = true
			local world = Worlds.Get(worldId)
			if world then
				Remotes.Notify:FireClient(player, "New area discovered: " .. world.Name, Color3.fromRGB(255, 215, 90))
			end
			PlayerDataService.Sync(player)
		end
	end

	for _, town in pairs(towns) do
		if (town.Part.Position - hrp.Position).Magnitude <= GameConfig.TownDiscoverRadius then
			discoverTown(player, data, town)
			break
		end
	end
end

local function onTravel(player, townName)
	if typeof(townName) ~= "string" then
		return
	end
	local data = PlayerDataService.Get(player)
	local town = towns[townName]
	if not data or not town or not data.DiscoveredTowns[townName] then
		return
	end
	if player:GetAttribute("InDungeon") then
		Remotes.Notify:FireClient(player, "You can't fast travel from inside a dungeon.", Color3.fromRGB(255, 120, 120))
		return
	end
	local now = os.clock()
	if lastTravel[player] and now - lastTravel[player] < GameConfig.TravelCooldown then
		Remotes.Notify:FireClient(player, "Fast travel is recharging...", Color3.fromRGB(255, 180, 120))
		return
	end
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then
		return
	end
	lastTravel[player] = now
	local target = town.Part.CFrame + Vector3.new(0, 5, 0)
	pcall(function()
		player:RequestStreamAroundAsync(target.Position)
	end)
	char:PivotTo(target)
	Remotes.Notify:FireClient(player, "Travelled to " .. townName, Color3.fromRGB(140, 220, 255))
end

function WorldService.Init()
	local zoneFolder = workspace:FindFirstChild("WorldZones")
	if zoneFolder then
		for _, part in ipairs(zoneFolder:GetDescendants()) do
			if part:IsA("BasePart") then
				local id = part:GetAttribute("WorldId") or part.Name
				if Worlds.Get(id) then
					part.Transparency = 1
					part.CanCollide = false
					part.CanTouch = false
					part.CanQuery = false
					part.Anchored = true
					table.insert(zones, { Part = part, WorldId = id })
				else
					warn("[World] Zone part with unknown WorldId: " .. part:GetFullName())
				end
			end
		end
	else
		warn("[World] No Workspace.WorldZones folder - area detection disabled")
	end

	local townFolder = workspace:FindFirstChild("Towns")
	if townFolder then
		for _, part in ipairs(townFolder:GetDescendants()) do
			if part:IsA("BasePart") and part:GetAttribute("TownName") then
				local name = part:GetAttribute("TownName")
				towns[name] = { Name = name, WorldId = part:GetAttribute("WorldId"), Part = part }
			end
		end
	end
	if not towns[GameConfig.StartingTown] then
		warn("[World] Starting town '" .. GameConfig.StartingTown .. "' not found in Workspace.Towns")
	end

	Remotes.TravelToTown.OnServerEvent:Connect(onTravel)

	Players.PlayerRemoving:Connect(function(player)
		currentWorld[player] = nil
		lastTravel[player] = nil
	end)

	task.spawn(function()
		while true do
			task.wait(0.5)
			for _, player in ipairs(Players:GetPlayers()) do
				local ok, err = pcall(updatePlayer, player)
				if not ok then
					warn("[World] " .. tostring(err))
				end
			end
		end
	end)
end

function WorldService.SetupPlayer(player)
	WorldService.PrepareRespawn(player)
end

return WorldService
