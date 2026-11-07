--[[
	GameServer (main server script)
	Starts every service in the right order and handles players joining,
	spawning, dying and leaving.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))

-- We spawn characters ourselves once the player's save has loaded
Players.CharacterAutoLoads = false

local Remotes = require(script.Remotes)
local PlayerDataService = require(script.PlayerDataService)
local LevelService = require(script.LevelService)
local WorldService = require(script.WorldService)
local MonsterService = require(script.MonsterService)
local CombatService = require(script.CombatService)
local DungeonService = require(script.DungeonService)
local GreyboxMapBuilder = require(script.GreyboxMapBuilder)
local DevCommands = require(script.DevCommands)

local _ = Remotes -- make sure every RemoteEvent exists before clients look for them

---------------------------------------------------------------------------
-- World
---------------------------------------------------------------------------

if GameConfig.BuildGreyboxMap and not workspace:FindFirstChild("WorldZones") then
	GreyboxMapBuilder.BuildWorld()
end

WorldService.Init()
MonsterService.Init()
CombatService.Init()
DungeonService.Init()
DevCommands.Init()

---------------------------------------------------------------------------
-- Starter sword
---------------------------------------------------------------------------

local swordTemplate
local function getSword()
	if swordTemplate then
		return swordTemplate
	end
	local tool = Instance.new("Tool")
	tool.Name = "Sword"
	tool.CanBeDropped = false
	tool.RequiresHandle = true
	tool.ToolTip = "Click or tap to attack"
	-- Classic Roblox sword grip: hand holds one end, blade points forward
	tool.Grip = CFrame.new(0, 0, -1.7, 0, 0, 1, 1, 0, 0, 0, 1, 0)

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.35, 0.9, 4.4)
	handle.Color = Color3.fromRGB(200, 205, 215)
	handle.Material = Enum.Material.Metal
	handle.CanCollide = false
	handle.Massless = true
	handle.Parent = tool

	local function attach(size, offset, color, material)
		local p = Instance.new("Part")
		p.Name = "Trim"
		p.Size = size
		p.CFrame = handle.CFrame * offset
		p.Color = color
		p.Material = material
		p.CanCollide = false
		p.Massless = true
		p.Parent = tool
		local w = Instance.new("WeldConstraint")
		w.Part0 = handle
		w.Part1 = p
		w.Parent = p
	end
	attach(Vector3.new(0.5, 2.2, 0.4), CFrame.new(0, 0, -1.1), Color3.fromRGB(230, 186, 84), Enum.Material.Metal) -- guard
	attach(Vector3.new(0.5, 0.5, 1.1), CFrame.new(0, 0, -1.75), Color3.fromRGB(90, 55, 35), Enum.Material.Wood) -- grip

	swordTemplate = tool
	return tool
end

local function giveSword(player, character, humanoid)
	if player.Backpack:FindFirstChild("Sword") or character:FindFirstChild("Sword") then
		return
	end
	local sword = getSword():Clone()
	sword.Parent = player.Backpack
	task.defer(function()
		if humanoid.Parent and humanoid.Health > 0 and sword.Parent == player.Backpack then
			humanoid:EquipTool(sword)
		end
	end)
end

---------------------------------------------------------------------------
-- Players
---------------------------------------------------------------------------

local function spawnPlayer(player)
	if not player.Parent then
		return
	end
	WorldService.PrepareRespawn(player)
	player:LoadCharacter()
end

local function onCharacterAdded(player, character)
	local humanoid = character:WaitForChild("Humanoid", 10)
	if not humanoid then
		return
	end
	LevelService.ApplyStats(player, true)
	giveSword(player, character, humanoid)
	task.spawn(WorldService.PlaceAtSpawn, player, character)
	PlayerDataService.Sync(player)

	humanoid.Died:Once(function()
		task.wait(GameConfig.RespawnTime)
		if player.Parent and player.Character == character then
			spawnPlayer(player)
		end
	end)
end

local function onPlayerAdded(player)
	PlayerDataService.Load(player)
	if not player.Parent then
		-- Left while loading
		PlayerDataService.Release(player)
		return
	end
	LevelService.SetupPlayer(player)
	WorldService.SetupPlayer(player)
	player.CharacterAdded:Connect(function(character)
		onCharacterAdded(player, character)
	end)
	PlayerDataService.Sync(player)
	spawnPlayer(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

Players.PlayerRemoving:Connect(function(player)
	PlayerDataService.Release(player)
end)

---------------------------------------------------------------------------
-- Saving
---------------------------------------------------------------------------

task.spawn(function()
	while true do
		task.wait(GameConfig.AutosaveInterval)
		PlayerDataService.SaveAll()
	end
end)

game:BindToClose(function()
	if RunService:IsStudio() then
		-- Short wait in Studio so stopping a test doesn't hang
		PlayerDataService.SaveAll()
		task.wait(2)
		return
	end
	local pending = 0
	for _, player in ipairs(Players:GetPlayers()) do
		pending += 1
		task.spawn(function()
			PlayerDataService.Save(player)
			pending -= 1
		end)
	end
	local started = os.clock()
	while pending > 0 and os.clock() - started < 25 do
		task.wait(0.2)
	end
end)

print(("[%s] Server ready"):format(GameConfig.GameName))
