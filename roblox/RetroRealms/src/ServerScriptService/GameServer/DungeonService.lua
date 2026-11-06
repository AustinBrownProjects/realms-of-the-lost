--[[
	DungeonService
	Dungeon entrances, private dungeon runs, bosses and clear rewards.

	Nothing is level-locked: anyone can walk in. Players see a warning window
	with the recommended level and a difficulty rating first.

	Entrances: Parts in Workspace > DungeonEntrances with attribute DungeonId.
	The entrance part's front face (LookVector) should point to where players
	are dropped off when they leave.

	Custom dungeon layouts (optional): put a Model named after the dungeon Id
	in ServerStorage > DungeonTemplates containing Parts named "Start" and
	"BossSpawn", an optional "Exit" Part, and a Folder "MobSpawns" of Parts.
	Without one, a greybox dungeon is generated.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local CollectionService = game:GetService("CollectionService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local Progression = require(Shared:WaitForChild("Progression"))
local Dungeons = require(Shared:WaitForChild("Dungeons"))

local Remotes = require(script.Parent.Remotes)
local PlayerDataService = require(script.Parent.PlayerDataService)
local LevelService = require(script.Parent.LevelService)
local MonsterService = require(script.Parent.MonsterService)
local WorldService = require(script.Parent.WorldService)
local GreyboxMapBuilder = require(script.Parent.GreyboxMapBuilder)

local DungeonService = {}

local cfg = GameConfig.Dungeon
local entrances = {} -- [dungeonId] = { parts }
local runs = {} -- [runId] = run
local playerRun = {} -- [player] = run
local usedSlots = {}
local nextRunId = 0
local activeFolder

local function countPlayers(run)
	local n = 0
	for _ in pairs(run.Players) do
		n += 1
	end
	return n
end

local function nearEntrance(player, dungeonId)
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return nil
	end
	for _, part in ipairs(entrances[dungeonId] or {}) do
		if (part.Position - hrp.Position).Magnitude <= cfg.EntranceUseRange + part.Size.Magnitude / 2 then
			return part
		end
	end
	return nil
end

---------------------------------------------------------------------------
-- Arena
---------------------------------------------------------------------------

local function buildFromTemplate(def, origin)
	local folder = ServerStorage:FindFirstChild("DungeonTemplates")
	local template = folder and folder:FindFirstChild(def.Id)
	if not template then
		return nil
	end
	local model = template:Clone()
	model:PivotTo(CFrame.new(origin))

	local start = model:FindFirstChild("Start", true)
	local boss = model:FindFirstChild("BossSpawn", true)
	if not start or not boss then
		warn("[Dungeon] Template " .. def.Id .. " needs 'Start' and 'BossSpawn' parts - using greybox")
		model:Destroy()
		return nil
	end

	local mobCFrames = {}
	local mobFolder = model:FindFirstChild("MobSpawns", true)
	if mobFolder then
		for _, p in ipairs(mobFolder:GetChildren()) do
			if p:IsA("BasePart") then
				table.insert(mobCFrames, p.CFrame + Vector3.new(0, 3, 0))
				p.Transparency = 1
				p.CanCollide = false
			end
		end
	end
	local exit = model:FindFirstChild("Exit", true)
	for _, p in ipairs({ start, boss }) do
		p.Transparency = 1
		p.CanCollide = false
	end

	return {
		Model = model,
		StartCFrame = start.CFrame + Vector3.new(0, 4, 0),
		RetreatCFrame = start.CFrame * CFrame.new(0, 3, 8),
		MobCFrames = mobCFrames,
		BossCFrame = boss.CFrame + Vector3.new(0, 4, 0),
		ExitCFrame = exit and exit.CFrame or boss.CFrame * CFrame.new(0, 3, -20),
	}
end

local function makePortal(parent, cframe, color, text, onUse)
	local portal = Instance.new("Part")
	portal.Name = "Portal"
	portal.Anchored = true
	portal.CanCollide = false
	portal.Size = Vector3.new(8, 10, 1)
	portal.CFrame = cframe + Vector3.new(0, 2, 0)
	portal.Color = color
	portal.Material = Enum.Material.Neon
	portal.Transparency = 0.25
	portal.Parent = parent

	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = 18
	light.Brightness = 2
	light.Parent = portal

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = text
	prompt.ObjectText = "Portal"
	prompt.HoldDuration = 0.4
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = portal
	prompt.Triggered:Connect(onUse)
	return portal
end

---------------------------------------------------------------------------
-- Runs
---------------------------------------------------------------------------

local removePlayer

local function cleanupRun(run)
	if not runs[run.Id] then
		return
	end
	runs[run.Id] = nil
	usedSlots[run.Slot] = nil
	for player in pairs(run.Players) do
		playerRun[player] = nil
	end
	if run.Model then
		run.Model:Destroy()
	end
end

removePlayer = function(run, player, teleportOut)
	if not run.Players[player] then
		return
	end
	run.Players[player] = nil
	playerRun[player] = nil
	if run.Conns[player] then
		run.Conns[player]:Disconnect()
		run.Conns[player] = nil
	end

	if player.Parent then
		player:SetAttribute("InDungeon", nil)
		WorldService.ResetZone(player)
		if teleportOut then
			local char = player.Character
			if char and run.Entrance and run.Entrance.Parent then
				local out = run.Entrance.Position + run.Entrance.CFrame.LookVector * 14 + Vector3.new(0, 4, 0)
				pcall(function()
					player:RequestStreamAroundAsync(out)
				end)
				char:PivotTo(CFrame.lookAt(out, out + run.Entrance.CFrame.LookVector))
			end
		end
	end

	if countPlayers(run) == 0 then
		cleanupRun(run)
	end
end

local function onBossDefeated(run)
	if run.Cleared then
		return
	end
	run.Cleared = true
	local def = run.Def

	for player in pairs(run.Players) do
		local data = PlayerDataService.Get(player)
		if data then
			local level = LevelService.GetLevel(player)
			local xp = Progression.MonsterXP(def.RecommendedLevel, level, GameConfig.Rewards.ClearBonusXPMultiplier)
			local gold = Progression.MonsterGold(def.RecommendedLevel, GameConfig.Rewards.ClearBonusGoldMultiplier)
			data.DungeonClears[def.Id] = (data.DungeonClears[def.Id] or 0) + 1
			LevelService.AddXP(player, xp)
			LevelService.AddGold(player, gold)
			Remotes.Notify:FireClient(
				player,
				("DUNGEON CLEARED: %s  +%d XP  +%d Gold"):format(def.Name, xp, gold),
				Color3.fromRGB(255, 215, 90)
			)
			PlayerDataService.Sync(player)
		end
	end

	makePortal(run.Model, run.Arena.ExitCFrame, Color3.fromRGB(255, 215, 90), "Leave victorious", function(player)
		removePlayer(run, player, true)
	end)

	task.delay(cfg.ExitDelayAfterClear, function()
		if runs[run.Id] then
			for player in pairs(run.Players) do
				if player.Parent then
					Remotes.Notify:FireClient(player, "The dungeon collapses behind you...", Color3.fromRGB(200, 200, 200))
				end
				removePlayer(run, player, true)
			end
			cleanupRun(run)
		end
	end)
end

local function createRun(def, entrance)
	local slot = 1
	while usedSlots[slot] do
		slot += 1
	end
	usedSlots[slot] = true
	nextRunId += 1

	local origin = cfg.Origin + Vector3.new(slot * cfg.SlotSpacing, 0, 0)
	local arena = buildFromTemplate(def, origin) or GreyboxMapBuilder.BuildDungeonArena(def, origin)
	arena.Model.Name = ("%s_Run%d"):format(def.Id, nextRunId)
	arena.Model.Parent = activeFolder

	local run = {
		Id = nextRunId,
		Def = def,
		Slot = slot,
		Model = arena.Model,
		Arena = arena,
		Entrance = entrance,
		Players = {},
		Conns = {},
		StartTime = os.clock(),
		Cleared = false,
	}
	runs[run.Id] = run

	makePortal(arena.Model, arena.RetreatCFrame, Color3.fromRGB(120, 200, 255), "Retreat", function(player)
		removePlayer(run, player, true)
	end)

	local mobs = Instance.new("Folder")
	mobs.Name = "Monsters"
	mobs.Parent = arena.Model

	for i, cf in ipairs(arena.MobCFrames) do
		local mobId = def.Mobs[((i - 1) % #def.Mobs) + 1]
		local level = math.max(1, def.RecommendedLevel - math.random(0, 6))
		MonsterService.SpawnMonster(mobId, level, cf, {
			Parent = mobs,
			Aggressive = true,
			WanderRadius = 0,
			Leash = 160,
		})
	end

	MonsterService.SpawnMonster(def.BossId, def.RecommendedLevel, arena.BossCFrame, {
		Parent = mobs,
		Aggressive = true,
		WanderRadius = 0,
		Leash = 200,
		OnDied = function()
			onBossDefeated(run)
		end,
	})

	return run
end

local function addPlayer(run, player)
	local char = player.Character
	local humanoid = char and char:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	run.Players[player] = true
	playerRun[player] = run
	player:SetAttribute("InDungeon", run.Def.Id)

	pcall(function()
		player:RequestStreamAroundAsync(run.Arena.StartCFrame.Position)
	end)
	char:PivotTo(run.Arena.StartCFrame)
	Remotes.ZoneChanged:FireClient(player, "Dungeon", run.Def.Id)

	run.Conns[player] = humanoid.Died:Connect(function()
		Remotes.Notify:FireClient(player, "You fell in " .. run.Def.Name .. ".", Color3.fromRGB(255, 100, 100))
		removePlayer(run, player, false)
	end)
end

local function onEnterRequest(player, dungeonId)
	if typeof(dungeonId) ~= "string" then
		return
	end
	local def = Dungeons.Get(dungeonId)
	if not def or playerRun[player] then
		return
	end
	local entrance = nearEntrance(player, dungeonId)
	if not entrance then
		return
	end
	local hum = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 then
		return
	end

	-- Join a run someone just started from the same entrance
	local now = os.clock()
	for _, run in pairs(runs) do
		if
			run.Def.Id == dungeonId
			and run.Entrance == entrance
			and not run.Cleared
			and now - run.StartTime <= cfg.JoinWindowSeconds
			and countPlayers(run) < cfg.MaxPartySize
		then
			addPlayer(run, player)
			return
		end
	end

	addPlayer(createRun(def, entrance), player)
end

---------------------------------------------------------------------------
-- Init
---------------------------------------------------------------------------

local function registerEntrance(part)
	local id = part:GetAttribute("DungeonId")
	local def = id and Dungeons.Get(id)
	if not def then
		warn("[Dungeon] Entrance with unknown DungeonId: " .. part:GetFullName())
		return
	end
	entrances[id] = entrances[id] or {}
	table.insert(entrances[id], part)
	CollectionService:AddTag(part, "DungeonEntrance")

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Enter"
	prompt.ObjectText = def.Name
	prompt.HoldDuration = 0.3
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt.Parent = part
	prompt.Triggered:Connect(function(player)
		Remotes.DungeonPrompt:FireClient(player, id)
	end)
end

function DungeonService.Init()
	activeFolder = Instance.new("Folder")
	activeFolder.Name = "ActiveDungeons"
	activeFolder.Parent = workspace

	local folder = workspace:FindFirstChild("DungeonEntrances")
	if folder then
		for _, part in ipairs(folder:GetDescendants()) do
			if part:IsA("BasePart") and part:GetAttribute("DungeonId") then
				registerEntrance(part)
			end
		end
	end
	for _, def in ipairs(Dungeons.List) do
		if not entrances[def.Id] then
			warn("[Dungeon] No entrance placed for " .. def.Id)
		end
	end

	Remotes.EnterDungeon.OnServerEvent:Connect(onEnterRequest)
	Remotes.LeaveDungeon.OnServerEvent:Connect(function(player)
		local run = playerRun[player]
		if run then
			removePlayer(run, player, true)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		local run = playerRun[player]
		if run then
			removePlayer(run, player, false)
		end
	end)
end

function DungeonService.IsInDungeon(player)
	return playerRun[player] ~= nil
end

return DungeonService
