--[[
	Progression
	All level maths lives here: XP curve, stats per level, damage, rewards and
	the SAO-style difficulty rating. Nothing in the game is locked by level -
	these numbers are what make a level 20 player bounce off a level 500
	dungeon, and what make a level 2000 player wildly overpowered.
]]

local GameConfig = require(script.Parent.GameConfig)

local Progression = {}

-- XP needed to go from `level` to `level + 1`
function Progression.XPToNext(level)
	return math.floor(100 * level ^ 1.6)
end

-- Base stats for a player (monsters multiply these by their own multipliers)
function Progression.GetStats(level)
	return {
		MaxHealth = math.floor(100 + 20 * level + 0.05 * level * level),
		Attack = math.floor(10 + 2 * level + 0.005 * level * level),
		Defense = math.floor(5 + level + 0.0025 * level * level),
	}
end

--[[
	Level gap multiplier. Each `scale` levels of gap doubles (or halves) damage.
	scale grows with the defender's level so a 10 level gap matters a lot at
	level 15 but very little at level 900.
]]
function Progression.LevelDiffMultiplier(attackerLevel, defenderLevel)
	local diff = attackerLevel - defenderLevel
	local scale = math.max(10, defenderLevel * 0.1)
	local mult = 2 ^ (diff / scale)
	return math.clamp(mult, GameConfig.Combat.LevelDiffMinMult, GameConfig.Combat.LevelDiffMaxMult)
end

-- Raw damage before randomness and crits
function Progression.BaseDamage(attackerLevel, attack, defenderLevel, defense)
	local base = (attack * attack) / math.max(1, attack + defense)
	return base * Progression.LevelDiffMultiplier(attackerLevel, defenderLevel)
end

-- Final damage with +/-10% variance. Returns damage, isCrit
function Progression.RollDamage(attackerLevel, attack, defenderLevel, defense, canCrit)
	local dmg = Progression.BaseDamage(attackerLevel, attack, defenderLevel, defense)
	dmg *= 0.9 + math.random() * 0.2
	local crit = false
	if canCrit and math.random() < GameConfig.Combat.CritChance then
		crit = true
		dmg *= GameConfig.Combat.CritMultiplier
	end
	return math.max(GameConfig.Combat.MinDamage, math.floor(dmg)), crit
end

-- XP for killing a monster. Weaker monsters give much less, stronger give a bonus.
function Progression.MonsterXP(monsterLevel, playerLevel, xpMult)
	local base = 20 * monsterLevel ^ 1.4 * (xpMult or 1)
	local ratio = monsterLevel / math.max(1, playerLevel)
	local factor
	if ratio >= 1 then
		factor = math.min(1.25, 1 + (ratio - 1) * 0.25)
	else
		factor = math.max(0.05, ratio * ratio)
	end
	return math.max(1, math.floor(base * factor))
end

function Progression.MonsterGold(monsterLevel, goldMult)
	local gold = GameConfig.Rewards.GoldPerLevel * monsterLevel * (goldMult or 1)
	return math.max(1, math.floor(gold * (0.8 + math.random() * 0.4)))
end

-- Difficulty rating (like the colour of a monster's cursor in SAO)
Progression.Difficulties = {
	{
		Name = "Trivial",
		MaxRatio = 0.6,
		Color = Color3.fromRGB(150, 150, 150),
		Warning = "Barely worth your time.",
	},
	{
		Name = "Easy",
		MaxRatio = 0.9,
		Color = Color3.fromRGB(110, 210, 90),
		Warning = "You should have no trouble here.",
	},
	{
		Name = "Fair",
		MaxRatio = 1.15,
		Color = Color3.fromRGB(245, 220, 80),
		Warning = "A fair fight. Stay sharp.",
	},
	{
		Name = "Hard",
		MaxRatio = 1.6,
		Color = Color3.fromRGB(255, 150, 50),
		Warning = "Dangerous. Bring friends or come back stronger.",
	},
	{
		Name = "Deadly",
		MaxRatio = 3,
		Color = Color3.fromRGB(230, 60, 60),
		Warning = "Monsters here will crush you in a few hits.",
	},
	{
		Name = "Suicidal",
		MaxRatio = math.huge,
		Color = Color3.fromRGB(190, 40, 160),
		Warning = "Far beyond your level. You will almost certainly die instantly.",
	},
}

-- `targetLevel` = monster / dungeon / area level, `playerLevel` = you
function Progression.GetDifficulty(targetLevel, playerLevel)
	-- +10 softens the ratio at very low levels (Lv 1 vs Lv 5 is "Hard", not "Suicidal")
	local ratio = (targetLevel + 10) / (math.max(1, playerLevel) + 10)
	for _, d in ipairs(Progression.Difficulties) do
		if ratio <= d.MaxRatio then
			return d
		end
	end
	return Progression.Difficulties[#Progression.Difficulties]
end

-- Player walk speed creeps up with level (16 at Lv 1, 28 at Lv 2000)
function Progression.WalkSpeed(level)
	return 16 + math.min(12, level * 0.006)
end

return Progression
