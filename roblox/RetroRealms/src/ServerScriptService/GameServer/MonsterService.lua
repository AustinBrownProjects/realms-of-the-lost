--[[
	MonsterService
	Spawns monsters (overworld spawn points + dungeons), runs their AI,
	handles monster attacks on players and hands out XP/gold on death.

	Overworld spawn points are Parts inside Workspace > MonsterSpawns with
	attributes:
	  MonsterId (string)  e.g. "PlainsWolf"
	  MinLevel / MaxLevel (number)
	  MaxAlive (number, default 3)
	  Radius (number, default 25)    spread around the part
	  RespawnTime (number, default 20)
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local Progression = require(Shared:WaitForChild("Progression"))
local Monsters = require(Shared:WaitForChild("Monsters"))

local Remotes = require(script.Parent.Remotes)
local LevelService = require(script.Parent.LevelService)

local MonsterService = {}

local active = {} -- [model] = info
local spawnPoints = {}
local overworldFolder

local cfg = GameConfig.Monsters

---------------------------------------------------------------------------
-- Model building
---------------------------------------------------------------------------

local function weld(a, b)
	local w = Instance.new("WeldConstraint")
	w.Part0 = a
	w.Part1 = b
	w.Parent = a
end

-- A chunky retro placeholder: body block/ball with two eyes
local function buildPlaceholder(def)
	local model = Instance.new("Model")
	local size = def.Size

	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = size
	root.Transparency = 1
	root.CanCollide = true
	root.Parent = model

	local body = Instance.new("Part")
	body.Name = "Body"
	if def.Shape == "Ball" then
		body.Shape = Enum.PartType.Ball
		local d = math.min(size.X, size.Y, size.Z)
		body.Size = Vector3.new(d, d, d)
	else
		body.Size = size
	end
	body.Color = def.Color
	body.Material = def.Material
	body.CanCollide = false
	body.Massless = true
	body.CFrame = root.CFrame
	body.Parent = model
	weld(root, body)

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(1, 1, 1)
	head.Transparency = 1
	head.CanCollide = false
	head.Massless = true
	head.CFrame = root.CFrame * CFrame.new(0, size.Y / 2, 0)
	head.Parent = model
	weld(root, head)

	-- Eyes on the front face (-Z is forward in Roblox)
	local eyeSize = math.clamp(math.min(size.X, size.Y) * 0.18, 0.3, 2.5)
	for _, side in ipairs({ -1, 1 }) do
		local eye = Instance.new("Part")
		eye.Name = "Eye"
		eye.Size = Vector3.new(eyeSize, eyeSize, 0.2)
		eye.Color = def.Boss and Color3.fromRGB(255, 60, 40) or Color3.fromRGB(20, 20, 20)
		eye.Material = def.Boss and Enum.Material.Neon or Enum.Material.SmoothPlastic
		eye.CanCollide = false
		eye.Massless = true
		eye.CFrame = root.CFrame * CFrame.new(side * size.X * 0.2, size.Y * 0.2, -size.Z / 2 - 0.1)
		eye.Parent = model
		weld(root, eye)
	end

	local humanoid = Instance.new("Humanoid")
	humanoid.RigType = Enum.HumanoidRigType.R15
	humanoid.HipHeight = 0.3
	humanoid.Parent = model

	model.PrimaryPart = root
	return model
end

local function getModel(def)
	local folder = ServerStorage:FindFirstChild("MonsterModels")
	local template = folder and folder:FindFirstChild(def.Id)
	if template then
		local model = template:Clone()
		if not model:FindFirstChildOfClass("Humanoid") then
			Instance.new("Humanoid").Parent = model
		end
		model.PrimaryPart = model.PrimaryPart or model:FindFirstChild("HumanoidRootPart")
		if model.PrimaryPart then
			return model
		end
		warn("[Monsters] Custom model " .. def.Id .. " has no HumanoidRootPart, using placeholder")
		model:Destroy()
	end
	return buildPlaceholder(def)
end

---------------------------------------------------------------------------
-- Rewards / death
---------------------------------------------------------------------------

local function onDied(model, info)
	if info.Dead then
		return
	end
	info.Dead = true

	local position = info.Root.Position
	local xpMult = info.Def.XP * (info.Def.Boss and GameConfig.Rewards.BossXPMultiplier or 1)
	local goldMult = info.Def.Gold * (info.Def.Boss and GameConfig.Rewards.BossGoldMultiplier or 1)

	for player in pairs(info.Contributors) do
		if player.Parent then
			local xp = Progression.MonsterXP(info.Level, LevelService.GetLevel(player), xpMult)
			local gold = Progression.MonsterGold(info.Level, goldMult)
			LevelService.AddXP(player, xp)
			LevelService.AddGold(player, gold)
			Remotes.Reward:FireClient(player, position, xp, gold)
		end
	end

	if info.OnDied then
		task.spawn(info.OnDied, info)
	end

	-- Fade out and remove
	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") and part.Transparency < 1 then
			TweenService:Create(part, TweenInfo.new(cfg.CorpseTime), { Transparency = 1 }):Play()
		end
	end
	task.delay(cfg.CorpseTime, function()
		active[model] = nil
		model:Destroy()
	end)
end

---------------------------------------------------------------------------
-- Spawning
---------------------------------------------------------------------------

--[[
	options:
	  Parent      Instance (default Workspace.Monsters)
	  OnDied      function(info)
	  Aggressive  bool override
	  Leash       number override
	  WanderRadius number override (0 = stand guard)
]]
function MonsterService.SpawnMonster(monsterId, level, cframe, options)
	options = options or {}
	local def = Monsters.Get(monsterId)
	if not def then
		warn("[Monsters] Unknown monster id: " .. tostring(monsterId))
		return nil
	end
	level = math.clamp(math.floor(level), 1, GameConfig.MaxLevel)

	local base = Progression.GetStats(level)
	local stats = {
		MaxHealth = math.max(1, math.floor(base.MaxHealth * def.Health)),
		Attack = math.max(1, math.floor(base.Attack * def.Attack)),
		Defense = math.max(0, math.floor(base.Defense * def.Defense)),
	}

	local model = getModel(def)
	model.Name = def.Name
	model:SetAttribute("MonsterId", def.Id)
	model:SetAttribute("Level", level)
	model:SetAttribute("DisplayName", def.Name)
	model:SetAttribute("IsBoss", def.Boss == true)
	model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic

	local humanoid = model:FindFirstChildOfClass("Humanoid")
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	humanoid.RequiresNeck = false
	humanoid.BreakJointsOnDeath = false
	humanoid.MaxHealth = stats.MaxHealth
	humanoid.Health = stats.MaxHealth
	humanoid.WalkSpeed = def.Speed

	model:PivotTo(cframe)
	model.Parent = options.Parent or overworldFolder
	CollectionService:AddTag(model, "Monster")

	local root = model.PrimaryPart
	pcall(function()
		root:SetNetworkOwner(nil)
	end)

	local aggressive = def.Aggressive
	if options.Aggressive ~= nil then
		aggressive = options.Aggressive
	end

	local info = {
		Model = model,
		Def = def,
		Level = level,
		Stats = stats,
		Humanoid = humanoid,
		Root = root,
		Home = cframe.Position,
		Aggressive = aggressive,
		Leash = options.Leash or cfg.LeashDistance,
		WanderRadius = options.WanderRadius or cfg.WanderRadius,
		Contributors = {},
		Target = nil,
		LastAttack = 0,
		AttackCount = 0,
		NextWander = os.clock() + math.random() * 5,
		Returning = false,
		OnDied = options.OnDied,
		Dead = false,
	}
	active[model] = info

	humanoid.Died:Connect(function()
		onDied(model, info)
	end)
	model.AncestryChanged:Connect(function()
		if not model:IsDescendantOf(workspace) then
			active[model] = nil
		end
	end)

	return model, info
end

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

local function groundAt(position)
	local filter = {}
	if overworldFolder then
		table.insert(filter, overworldFolder)
	end
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character then
			table.insert(filter, player.Character)
		end
	end
	rayParams.FilterDescendantsInstances = filter
	local result = workspace:Raycast(position + Vector3.new(0, 150, 0), Vector3.new(0, -400, 0), rayParams)
	return result and result.Position or position
end

local function playerNear(position, range)
	for _, player in ipairs(Players:GetPlayers()) do
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if hrp and (hrp.Position - position).Magnitude <= range then
			return true
		end
	end
	return false
end

local function spawnFromPoint(sp)
	local def = Monsters.Get(sp.MonsterId)
	local angle = math.random() * math.pi * 2
	local dist = math.random() * sp.Radius
	local guess = sp.Part.Position + Vector3.new(math.cos(angle) * dist, 0, math.sin(angle) * dist)
	local ground = groundAt(guess)
	local pos = ground + Vector3.new(0, def.Size.Y / 2 + 1, 0)
	local level = math.random(sp.MinLevel, sp.MaxLevel)
	local rot = CFrame.Angles(0, math.random() * math.pi * 2, 0)

	sp.Alive += 1
	local model = MonsterService.SpawnMonster(sp.MonsterId, level, CFrame.new(pos) * rot, {
		OnDied = function()
			sp.Alive -= 1
			sp.NextSpawn = os.clock() + sp.RespawnTime
		end,
	})
	if not model then
		sp.Alive -= 1
	end
end

function MonsterService.RegisterSpawnPoint(part)
	local id = part:GetAttribute("MonsterId")
	if not id or not Monsters.Get(id) then
		warn("[Monsters] Spawn point " .. part:GetFullName() .. " has an unknown MonsterId: " .. tostring(id))
		return
	end
	part.Transparency = 1
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Anchored = true

	local minLevel = part:GetAttribute("MinLevel") or 1
	local maxLevel = part:GetAttribute("MaxLevel") or minLevel
	table.insert(spawnPoints, {
		Part = part,
		MonsterId = id,
		MinLevel = math.floor(minLevel),
		MaxLevel = math.floor(math.max(minLevel, maxLevel)),
		MaxAlive = part:GetAttribute("MaxAlive") or 3,
		Radius = part:GetAttribute("Radius") or 25,
		RespawnTime = part:GetAttribute("RespawnTime") or 20,
		Alive = 0,
		NextSpawn = 0,
	})
end

---------------------------------------------------------------------------
-- Combat helpers
---------------------------------------------------------------------------

function MonsterService.GetMonstersInRange(position, range)
	local results = {}
	for model, info in pairs(active) do
		if not info.Dead and info.Root.Parent then
			local dist = (info.Root.Position - position).Magnitude - math.max(info.Def.Size.X, info.Def.Size.Z) / 2
			if dist <= range then
				table.insert(results, { Model = model, Info = info, Distance = dist })
			end
		end
	end
	table.sort(results, function(a, b)
		return a.Distance < b.Distance
	end)
	return results
end

function MonsterService.DamageMonster(model, amount, player)
	local info = active[model]
	if not info or info.Dead then
		return
	end
	info.Contributors[player] = (info.Contributors[player] or 0) + amount
	info.Provoked = true
	if not info.Target or not info.Target.Parent then
		info.Target = player
	end
	info.Humanoid:TakeDamage(amount)
end

local function hurtPlayer(info, player, multiplier)
	local char = player.Character
	local humanoid = char and char:FindFirstChildOfClass("Humanoid")
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not humanoid or humanoid.Health <= 0 or not hrp then
		return
	end
	local playerLevel = LevelService.GetLevel(player)
	local playerStats = Progression.GetStats(playerLevel)
	local dmg = Progression.RollDamage(info.Level, info.Stats.Attack, playerLevel, playerStats.Defense, false)
	dmg = math.floor(dmg * (multiplier or 1))
	humanoid:TakeDamage(dmg)
	Remotes.DamageNumber:FireClient(player, hrp.Position + Vector3.new(0, 3, 0), dmg, false, true)
end

local function bossSlam(info)
	local radius = math.max(info.Def.Size.X, info.Def.Size.Z) + 12
	local center = info.Root.Position
	local delayTime = 0.9
	Remotes.BossSlam:FireAllClients(center - Vector3.new(0, info.Def.Size.Y / 2, 0), radius, delayTime)
	task.delay(delayTime, function()
		if info.Dead then
			return
		end
		for _, player in ipairs(Players:GetPlayers()) do
			local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			if hrp then
				local flat = Vector3.new(hrp.Position.X - center.X, 0, hrp.Position.Z - center.Z)
				if flat.Magnitude <= radius and math.abs(hrp.Position.Y - center.Y) < 30 then
					hurtPlayer(info, player, 1.6)
				end
			end
		end
	end)
end

---------------------------------------------------------------------------
-- AI
---------------------------------------------------------------------------

local function findTarget(info)
	local best, bestDist = nil, info.Def.AggroRange
	for _, player in ipairs(Players:GetPlayers()) do
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hrp and hum and hum.Health > 0 then
			local d = (hrp.Position - info.Root.Position).Magnitude
			if d < bestDist and (hrp.Position - info.Home).Magnitude < info.Leash then
				best, bestDist = player, d
			end
		end
	end
	return best
end

local function updateMonster(info, now)
	local root = info.Root
	if not root.Parent or info.Humanoid.Health <= 0 then
		return
	end
	local humanoid = info.Humanoid
	local fromHome = (root.Position - info.Home).Magnitude

	-- Leashed: run home and heal up
	if fromHome > info.Leash then
		info.Target = nil
		info.Provoked = false
		info.Returning = true
	end
	if info.Returning then
		humanoid:MoveTo(info.Home)
		humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + humanoid.MaxHealth * 0.1)
		if fromHome < 8 then
			info.Returning = false
			humanoid.Health = humanoid.MaxHealth
			info.Contributors = {}
		end
		return
	end

	-- Validate current target
	local target = info.Target
	if target then
		local char = target.Parent and target.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if not hum or hum.Health <= 0 or not hrp or (hrp.Position - root.Position).Magnitude > info.Def.AggroRange * 2 then
			target = nil
			info.Target = nil
			info.Provoked = false
		end
	end
	if not target and info.Aggressive then
		target = findTarget(info)
		info.Target = target
	end

	if target then
		local hrp = target.Character.HumanoidRootPart
		local offset = hrp.Position - root.Position
		local flatDist = Vector3.new(offset.X, 0, offset.Z).Magnitude
		if flatDist <= info.Def.AttackRange then
			humanoid:MoveTo(root.Position)
			local lookAt = Vector3.new(hrp.Position.X, root.Position.Y, hrp.Position.Z)
			if (lookAt - root.Position).Magnitude > 0.1 then
				root.CFrame = CFrame.lookAt(root.Position, lookAt)
			end
			if now - info.LastAttack >= info.Def.AttackCooldown then
				info.LastAttack = now
				info.AttackCount += 1
				if info.Def.Boss and info.AttackCount % info.Def.SlamEvery == 0 then
					bossSlam(info)
				else
					hurtPlayer(info, target, 1)
				end
			end
		else
			humanoid:MoveTo(hrp.Position)
		end
		return
	end

	-- Idle wander
	if info.WanderRadius > 0 and now >= info.NextWander then
		info.NextWander = now + 4 + math.random() * 6
		local angle = math.random() * math.pi * 2
		local r = math.random() * info.WanderRadius
		humanoid:MoveTo(info.Home + Vector3.new(math.cos(angle) * r, 0, math.sin(angle) * r))
	end
end

---------------------------------------------------------------------------
-- Init
---------------------------------------------------------------------------

function MonsterService.Init()
	overworldFolder = workspace:FindFirstChild("Monsters")
	if not overworldFolder then
		overworldFolder = Instance.new("Folder")
		overworldFolder.Name = "Monsters"
		overworldFolder.Parent = workspace
	end

	local spawnFolder = workspace:FindFirstChild("MonsterSpawns")
	if spawnFolder then
		for _, part in ipairs(spawnFolder:GetDescendants()) do
			if part:IsA("BasePart") then
				MonsterService.RegisterSpawnPoint(part)
			end
		end
	end

	-- Spawner: only fills spawn points that have a player nearby
	task.spawn(function()
		while true do
			task.wait(cfg.SpawnerStep)
			local now = os.clock()
			for _, sp in ipairs(spawnPoints) do
				if sp.Alive < sp.MaxAlive and now >= sp.NextSpawn and playerNear(sp.Part.Position, cfg.ActivationRange) then
					sp.NextSpawn = now + 0.5
					spawnFromPoint(sp)
				end
			end
		end
	end)

	-- AI loop
	task.spawn(function()
		while true do
			task.wait(cfg.AIStep)
			local now = os.clock()
			local list = {}
			for _, info in pairs(active) do
				table.insert(list, info)
			end
			for _, info in ipairs(list) do
				if not info.Dead then
					local ok, err = pcall(updateMonster, info, now)
					if not ok then
						warn("[Monsters] AI error: " .. tostring(err))
					end
				end
			end
		end
	end)
end

return MonsterService
