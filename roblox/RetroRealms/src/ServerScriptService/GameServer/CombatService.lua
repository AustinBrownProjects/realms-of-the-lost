--[[
	CombatService
	Player attacks. The client sends "Attack" with an aim direction; the
	server checks cooldown, range and the swing arc, then damages up to
	MaxTargetsPerSwing monsters.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local Progression = require(Shared:WaitForChild("Progression"))

local Remotes = require(script.Parent.Remotes)
local LevelService = require(script.Parent.LevelService)
local MonsterService = require(script.Parent.MonsterService)

local CombatService = {}

local lastAttack = {}
local combat = GameConfig.Combat

local function onAttack(player, aim)
	local now = os.clock()
	-- small tolerance for network jitter
	if lastAttack[player] and now - lastAttack[player] < combat.PlayerAttackCooldown * 0.85 then
		return
	end
	lastAttack[player] = now

	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local humanoid = char and char:FindFirstChildOfClass("Humanoid")
	if not hrp or not humanoid or humanoid.Health <= 0 then
		return
	end

	local forward = hrp.CFrame.LookVector
	if typeof(aim) == "Vector3" and aim.Magnitude > 0.01 and aim.Magnitude < 2 then
		forward = aim
	end
	forward = Vector3.new(forward.X, 0, forward.Z)
	if forward.Magnitude < 0.01 then
		forward = Vector3.new(0, 0, -1)
	end
	forward = forward.Unit

	local level = LevelService.GetLevel(player)
	local stats = Progression.GetStats(level)
	local hits = 0

	for _, entry in ipairs(MonsterService.GetMonstersInRange(hrp.Position, combat.PlayerAttackRange)) do
		if hits >= combat.MaxTargetsPerSwing then
			break
		end
		local toMonster = entry.Info.Root.Position - hrp.Position
		local flat = Vector3.new(toMonster.X, 0, toMonster.Z)
		local inArc = entry.Distance < 3 or (flat.Magnitude > 0 and flat.Unit:Dot(forward) >= combat.PlayerAttackArcDot)
		if inArc then
			hits += 1
			local info = entry.Info
			local dmg, crit = Progression.RollDamage(level, stats.Attack, info.Level, info.Stats.Defense, true)
			MonsterService.DamageMonster(entry.Model, dmg, player)
			local top = info.Root.Position + Vector3.new(0, info.Def.Size.Y / 2 + 1, 0)
			Remotes.DamageNumber:FireAllClients(top, dmg, crit, false)
		end
	end
end

function CombatService.Init()
	Remotes.Attack.OnServerEvent:Connect(onAttack)
	game:GetService("Players").PlayerRemoving:Connect(function(player)
		lastAttack[player] = nil
	end)
end

return CombatService
