--[[
	DevCommands
	Chat commands for testing. Allowed in Studio, for the game's owner, and
	for any UserId listed in GameConfig.DevCommandUserIds.

	/dev                 list commands
	/setlevel 500        set your level
	/addxp 100000        give XP
	/gold 5000           give gold
	/heal                full heal
	/tp desert           teleport to an area, town or dungeon (part of the name is fine)
	/resetme             wipe your own progress back to level 1
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TextChatService = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local Worlds = require(Shared:WaitForChild("Worlds"))
local Dungeons = require(Shared:WaitForChild("Dungeons"))

local Remotes = require(script.Parent.Remotes)
local PlayerDataService = require(script.Parent.PlayerDataService)
local LevelService = require(script.Parent.LevelService)
local WorldService = require(script.Parent.WorldService)

local DevCommands = {}

local INFO = Color3.fromRGB(150, 220, 255)
local ERR = Color3.fromRGB(255, 120, 120)

local function allowed(player)
	if RunService:IsStudio() then
		return true
	end
	if game.CreatorType == Enum.CreatorType.User and player.UserId == game.CreatorId then
		return true
	end
	return table.find(GameConfig.DevCommandUserIds, player.UserId) ~= nil
end

local function tell(player, text, color)
	Remotes.Notify:FireClient(player, text, color or INFO)
end

local function simplify(s)
	return (string.lower(s):gsub("[^%w]", ""))
end

local function teleport(player, position)
	local char = player.Character
	if not char or player:GetAttribute("InDungeon") then
		tell(player, "Can't teleport right now (dead or inside a dungeon).", ERR)
		return false
	end
	pcall(function()
		player:RequestStreamAroundAsync(position)
	end)
	char:PivotTo(CFrame.new(position + Vector3.new(0, 5, 0)))
	return true
end

local function findTarget(query)
	local q = simplify(query)
	if q == "" then
		return nil
	end
	-- Dungeons first (stand in front of the entrance)
	local entranceFolder = workspace:FindFirstChild("DungeonEntrances")
	for _, def in ipairs(Dungeons.List) do
		if string.find(simplify(def.Name), q, 1, true) or string.find(simplify(def.Id), q, 1, true) then
			if entranceFolder then
				for _, part in ipairs(entranceFolder:GetDescendants()) do
					if part:IsA("BasePart") and part:GetAttribute("DungeonId") == def.Id then
						return part.Position + part.CFrame.LookVector * 16, def.Name
					end
				end
			end
		end
	end
	for _, world in ipairs(Worlds.List) do
		for _, townName in ipairs(world.Towns) do
			if string.find(simplify(townName), q, 1, true) then
				local town = WorldService.GetTown(townName)
				if town then
					return town.Part.Position, townName
				end
			end
		end
	end
	for _, world in ipairs(Worlds.List) do
		if string.find(simplify(world.Name), q, 1, true) or string.find(simplify(world.Biome), q, 1, true) then
			local town = WorldService.GetTown(world.Towns[1])
			if town then
				return town.Part.Position, world.Name
			end
		end
	end
	return nil
end

local COMMANDS = {}

COMMANDS.dev = function(player)
	tell(player, "/setlevel N  /addxp N  /gold N  /heal  /tp name  /resetme")
end

COMMANDS.setlevel = function(player, arg)
	local n = tonumber(arg)
	if not n then
		tell(player, "Usage: /setlevel 500", ERR)
		return
	end
	LevelService.SetLevel(player, n)
	tell(player, "Level set to " .. LevelService.GetLevel(player))
end

COMMANDS.addxp = function(player, arg)
	local n = tonumber(arg)
	if not n then
		tell(player, "Usage: /addxp 10000", ERR)
		return
	end
	LevelService.AddXP(player, n)
	tell(player, "Gave " .. math.floor(n) .. " XP")
end

COMMANDS.gold = function(player, arg)
	local n = tonumber(arg)
	if not n then
		tell(player, "Usage: /gold 1000", ERR)
		return
	end
	LevelService.AddGold(player, n)
	tell(player, "Gave " .. math.floor(n) .. " gold")
end

COMMANDS.heal = function(player)
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if hum and hum.Health > 0 then
		hum.Health = hum.MaxHealth
		tell(player, "Healed")
	end
end

COMMANDS.tp = function(player, arg)
	local pos, name = findTarget(arg or "")
	if not pos then
		tell(player, "No area, town or dungeon matches '" .. tostring(arg) .. "'", ERR)
		return
	end
	if teleport(player, pos) then
		tell(player, "Teleported to " .. name)
	end
end

COMMANDS.resetme = function(player)
	PlayerDataService.ResetData(player)
	LevelService.SetLevel(player, 1)
	LevelService.AddGold(player, 0)
	PlayerDataService.Sync(player)
	tell(player, "Progress reset. Respawning...")
	player:LoadCharacter()
end

local function run(player, text)
	if not player or not allowed(player) then
		return
	end
	local name, arg = string.match(text, "^/(%w+)%s*(.*)$")
	if not name then
		return
	end
	local fn = COMMANDS[string.lower(name)]
	if fn then
		local ok, err = pcall(fn, player, arg)
		if not ok then
			tell(player, "Command failed: " .. tostring(err), ERR)
		end
	end
end

function DevCommands.Init()
	if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
		local folder = Instance.new("Folder")
		folder.Name = "RetroRealmsCommands"
		folder.Parent = TextChatService
		for name in pairs(COMMANDS) do
			local cmd = Instance.new("TextChatCommand")
			cmd.Name = "RR_" .. name
			cmd.PrimaryAlias = "/" .. name
			cmd.Parent = folder
			cmd.Triggered:Connect(function(source, text)
				run(Players:GetPlayerByUserId(source.UserId), text)
			end)
		end
	else
		local function hook(player)
			player.Chatted:Connect(function(text)
				run(player, text)
			end)
		end
		Players.PlayerAdded:Connect(hook)
		for _, p in ipairs(Players:GetPlayers()) do
			hook(p)
		end
	end
end

return DevCommands
