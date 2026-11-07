--[[
	PlayerDataService
	Loads and saves each player's progress with DataStoreService.
	If loading fails we never save for that player, so a DataStore outage
	can't wipe anyone's progress.

	In Studio: Game Settings > Security > "Enable Studio Access to API Services"
	must be ON for saving to work while testing.
]]

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))
local Remotes = require(script.Parent.Remotes)

local PlayerDataService = {}

local profiles = {} -- [player] = { Data = table, CanSave = bool }

local store
local okStore, storeErr = pcall(function()
	store = DataStoreService:GetDataStore(GameConfig.DataStoreName)
end)
if not okStore then
	warn("[PlayerData] DataStore unavailable, progress will not save:", storeErr)
end

local function defaultData()
	return {
		Version = 1,
		Level = 1,
		XP = 0,
		Gold = 0,
		RespawnTown = GameConfig.StartingTown,
		Discovered = {}, -- [worldId] = true
		DiscoveredTowns = { [GameConfig.StartingTown] = true },
		DungeonClears = {}, -- [dungeonId] = count
	}
end

local function reconcile(data)
	for key, value in pairs(defaultData()) do
		if data[key] == nil then
			data[key] = value
		end
	end
	return data
end

local function keyFor(player)
	return "Player_" .. player.UserId
end

function PlayerDataService.Load(player)
	local data = nil
	local canSave = false

	if store then
		for attempt = 1, 3 do
			local ok, result = pcall(function()
				return store:GetAsync(keyFor(player))
			end)
			if ok then
				data = result
				canSave = true
				break
			end
			warn(("[PlayerData] Load attempt %d failed for %s: %s"):format(attempt, player.Name, tostring(result)))
			-- Studio without API access (or an unpublished place): don't keep retrying
			local msg = tostring(result)
			if RunService:IsStudio() and (msg:find("403") or msg:find("publish") or msg:find("Studio")) then
				warn("[PlayerData] Saving is off in Studio. Turn on Game Settings > Security > Enable Studio Access to API Services.")
				break
			end
			task.wait(1.5)
		end
	end

	if type(data) == "table" then
		data = reconcile(data)
	else
		data = defaultData()
	end

	profiles[player] = { Data = data, CanSave = canSave }
	return data
end

function PlayerDataService.Get(player)
	local profile = profiles[player]
	return profile and profile.Data
end

function PlayerDataService.Save(player)
	local profile = profiles[player]
	if not profile or not profile.CanSave or not store then
		return
	end
	local ok, err = pcall(function()
		store:UpdateAsync(keyFor(player), function()
			return profile.Data
		end)
	end)
	if not ok then
		warn("[PlayerData] Save failed for " .. player.Name .. ": " .. tostring(err))
	end
end

function PlayerDataService.Release(player)
	PlayerDataService.Save(player)
	profiles[player] = nil
end

-- Wipes a player's progress back to a fresh save (used by /resetme)
function PlayerDataService.ResetData(player)
	local profile = profiles[player]
	if profile then
		profile.Data = defaultData()
	end
end

function PlayerDataService.SaveAll()
	for player in pairs(profiles) do
		task.spawn(PlayerDataService.Save, player)
	end
end

-- Sends the parts of the profile the UI needs (atlas, towns, clears)
function PlayerDataService.Sync(player)
	local data = PlayerDataService.Get(player)
	if not data then
		return
	end
	Remotes.ProfileUpdated:FireClient(player, {
		Discovered = data.Discovered,
		DiscoveredTowns = data.DiscoveredTowns,
		DungeonClears = data.DungeonClears,
		RespawnTown = data.RespawnTown,
	})
end

return PlayerDataService
