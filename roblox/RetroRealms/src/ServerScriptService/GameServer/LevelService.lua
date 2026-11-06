--[[
	LevelService
	XP, levels, gold and applying level stats to the character.
	Level / XP / XPNeeded / Gold are mirrored as Player attributes so the
	client HUD can read them.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local Progression = require(Shared:WaitForChild("Progression"))

local Remotes = require(script.Parent.Remotes)
local PlayerDataService = require(script.Parent.PlayerDataService)

local LevelService = {}

local function syncAttributes(player, data)
	player:SetAttribute("Level", data.Level)
	player:SetAttribute("XP", data.XP)
	player:SetAttribute("XPNeeded", data.Level >= GameConfig.MaxLevel and 0 or Progression.XPToNext(data.Level))
	player:SetAttribute("Gold", data.Gold)

	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		leaderstats.Level.Value = data.Level
	end
end

function LevelService.SetupPlayer(player)
	local data = PlayerDataService.Get(player)
	if not data then
		return
	end

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	local level = Instance.new("IntValue")
	level.Name = "Level"
	level.Value = data.Level
	level.Parent = leaderstats
	leaderstats.Parent = player

	syncAttributes(player, data)
end

function LevelService.GetLevel(player)
	local data = PlayerDataService.Get(player)
	return data and data.Level or 1
end

function LevelService.GetStats(player)
	return Progression.GetStats(LevelService.GetLevel(player))
end

-- Applies MaxHealth / WalkSpeed for the current level
function LevelService.ApplyStats(player, fullHeal)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	local level = LevelService.GetLevel(player)
	local stats = Progression.GetStats(level)
	local ratio = humanoid.MaxHealth > 0 and humanoid.Health / humanoid.MaxHealth or 1
	humanoid.MaxHealth = stats.MaxHealth
	humanoid.Health = fullHeal and stats.MaxHealth or math.max(1, stats.MaxHealth * ratio)
	humanoid.WalkSpeed = Progression.WalkSpeed(level)
end

function LevelService.AddXP(player, amount)
	local data = PlayerDataService.Get(player)
	if not data or amount <= 0 then
		return
	end
	if data.Level >= GameConfig.MaxLevel then
		return
	end

	data.XP += math.floor(amount)
	local gained = 0
	while data.Level < GameConfig.MaxLevel and data.XP >= Progression.XPToNext(data.Level) do
		data.XP -= Progression.XPToNext(data.Level)
		data.Level += 1
		gained += 1
	end
	if data.Level >= GameConfig.MaxLevel then
		data.Level = GameConfig.MaxLevel
		data.XP = 0
	end

	syncAttributes(player, data)

	if gained > 0 then
		LevelService.ApplyStats(player, true)
		local text = gained == 1 and ("LEVEL UP! You are now level " .. data.Level)
			or ("+" .. gained .. " LEVELS! You are now level " .. data.Level)
		if data.Level >= GameConfig.MaxLevel then
			text = "MAX LEVEL " .. data.Level .. " REACHED. You are unstoppable."
		end
		Remotes.Notify:FireClient(player, text, Color3.fromRGB(255, 215, 90))
	end
end

function LevelService.AddGold(player, amount)
	local data = PlayerDataService.Get(player)
	if not data then
		return
	end
	data.Gold = math.max(0, data.Gold + math.floor(amount))
	syncAttributes(player, data)
end

-- Dev / admin use
function LevelService.SetLevel(player, level)
	local data = PlayerDataService.Get(player)
	if not data then
		return
	end
	data.Level = math.clamp(math.floor(level), 1, GameConfig.MaxLevel)
	data.XP = 0
	syncAttributes(player, data)
	LevelService.ApplyStats(player, true)
end

return LevelService
