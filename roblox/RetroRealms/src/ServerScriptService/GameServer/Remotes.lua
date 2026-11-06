--[[
	Remotes
	Creates every RemoteEvent the game uses in ReplicatedStorage > Remotes.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local folder = ReplicatedStorage:FindFirstChild("Remotes")
if not folder then
	folder = Instance.new("Folder")
	folder.Name = "Remotes"
	folder.Parent = ReplicatedStorage
end

local NAMES = {
	"Attack", -- client -> server: swing (aim direction)
	"ProfileUpdated", -- server -> client: discovered worlds/towns, clears
	"ZoneChanged", -- server -> client: ("World", worldId) or ("Dungeon", dungeonId)
	"Notify", -- server -> client: text, color
	"DamageNumber", -- server -> client: position, amount, isCrit, isPlayerHurt
	"Reward", -- server -> client: position, xp, gold
	"DungeonPrompt", -- server -> client: dungeonId (opens the confirm window)
	"EnterDungeon", -- client -> server: dungeonId
	"LeaveDungeon", -- client -> server
	"TravelToTown", -- client -> server: townName
	"BossSlam", -- server -> client: position, radius, delay (warning ring)
}

local Remotes = {}
for _, name in ipairs(NAMES) do
	local remote = folder:FindFirstChild(name)
	if not remote then
		remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = folder
	end
	Remotes[name] = remote
end

return Remotes
