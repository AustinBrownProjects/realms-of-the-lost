--[[
	State
	What the client knows about the local player's progress and where they
	are standing. Other modules listen to ProfileChanged / ZoneChanged.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local player = Players.LocalPlayer

local State = {
	Profile = { Discovered = {}, DiscoveredTowns = {}, DungeonClears = {}, RespawnTown = nil },
	ZoneKind = nil, -- "World" | "Dungeon"
	ZoneId = nil,
}

local profileEvent = Instance.new("BindableEvent")
local zoneEvent = Instance.new("BindableEvent")
State.ProfileChanged = profileEvent.Event
State.ZoneChanged = zoneEvent.Event

function State.Level()
	return player:GetAttribute("Level") or 1
end

function State.InDungeon()
	return player:GetAttribute("InDungeon") ~= nil
end

function State.Init()
	Remotes:WaitForChild("ProfileUpdated").OnClientEvent:Connect(function(profile)
		if type(profile) == "table" then
			profile.Discovered = profile.Discovered or {}
			profile.DiscoveredTowns = profile.DiscoveredTowns or {}
			profile.DungeonClears = profile.DungeonClears or {}
			State.Profile = profile
			profileEvent:Fire()
		end
	end)
	Remotes:WaitForChild("ZoneChanged").OnClientEvent:Connect(function(kind, id)
		State.ZoneKind = kind
		State.ZoneId = id
		zoneEvent:Fire(kind, id)
	end)
end

return State
