--[[
	Monsters
	Stats are multipliers on Progression.GetStats(level), so any monster can
	exist at any level. If you put a model named after the Id (e.g. "Slime")
	in ServerStorage > MonsterModels it is used instead of the blocky
	placeholder. The model needs a Humanoid and a HumanoidRootPart.

	Shape: "Block" or "Ball" (placeholder look only)
	Aggressive: false = only fights back when hit
]]

local function c(r, g, b)
	return Color3.fromRGB(r, g, b)
end

local Monsters = {
	-- Emberbrook Vale ------------------------------------------------------
	Slime = { Name = "Slime", Shape = "Ball", Size = Vector3.new(3, 3, 3), Color = c(110, 210, 90), Material = Enum.Material.SmoothPlastic, Health = 0.3, Attack = 0.3, Speed = 10, Aggressive = false },
	CellarRat = { Name = "Cellar Rat", Size = Vector3.new(2, 1.5, 3), Color = c(120, 95, 80), Health = 0.25, Attack = 0.35, Speed = 16, Aggressive = true },
	WildBoar = { Name = "Wild Boar", Size = Vector3.new(3, 3, 4.5), Color = c(125, 85, 55), Health = 0.4, Attack = 0.4, Speed = 14, Aggressive = false },
	Goblin = { Name = "Goblin", Size = Vector3.new(2, 3.5, 1.5), Color = c(80, 140, 60), Health = 0.35, Attack = 0.45, Speed = 15, Aggressive = true },

	-- Goldgrass Plains -----------------------------------------------------
	PlainsWolf = { Name = "Plains Wolf", Size = Vector3.new(2.5, 2.5, 4.5), Color = c(150, 140, 130), Health = 0.35, Attack = 0.45, Speed = 20, Aggressive = true },
	Bandit = { Name = "Bandit", Size = Vector3.new(2, 5, 1.5), Color = c(140, 60, 50), Health = 0.45, Attack = 0.45, Speed = 16, Aggressive = true },
	GiantBeetle = { Name = "Giant Beetle", Size = Vector3.new(4, 2.5, 5), Color = c(40, 60, 110), Material = Enum.Material.Metal, Health = 0.6, Attack = 0.35, Defense = 1.5, Speed = 12, Aggressive = false },
	Skeleton = { Name = "Skeleton", Size = Vector3.new(2, 5, 1.2), Color = c(225, 220, 200), Health = 0.35, Attack = 0.5, Speed = 15, Aggressive = true },

	-- Whispering Wilds -----------------------------------------------------
	ThornSprite = { Name = "Thorn Sprite", Shape = "Ball", Size = Vector3.new(2, 2, 2), Color = c(170, 255, 90), Material = Enum.Material.Neon, Health = 0.25, Attack = 0.55, Speed = 18, Aggressive = true },
	DireBear = { Name = "Dire Bear", Size = Vector3.new(5, 5, 7), Color = c(80, 55, 35), Health = 0.7, Attack = 0.55, Speed = 15, Aggressive = true },
	AncientTreant = { Name = "Ancient Treant", Size = Vector3.new(7, 14, 7), Color = c(70, 90, 45), Material = Enum.Material.Wood, Health = 0.9, Attack = 0.7, Speed = 10, Aggressive = true, XP = 1.5 },

	-- Sunscorch Desert -----------------------------------------------------
	SandScorpion = { Name = "Sand Scorpion", Size = Vector3.new(4, 2, 5), Color = c(200, 150, 80), Health = 0.4, Attack = 0.5, Speed = 16, Aggressive = true },
	DuneMummy = { Name = "Dune Mummy", Size = Vector3.new(2.2, 5.5, 1.5), Color = c(215, 200, 165), Material = Enum.Material.Fabric, Health = 0.45, Attack = 0.45, Speed = 11, Aggressive = true },

	-- Saltmire Swamp -------------------------------------------------------
	BogToad = { Name = "Bog Toad", Shape = "Ball", Size = Vector3.new(3.5, 3.5, 3.5), Color = c(110, 120, 50), Health = 0.4, Attack = 0.4, Speed = 13, Aggressive = false },
	MireLurker = { Name = "Mire Lurker", Size = Vector3.new(3, 6, 3), Color = c(45, 75, 55), Material = Enum.Material.Slate, Health = 0.5, Attack = 0.5, Speed = 13, Aggressive = true },

	-- Frostfang Tundra -----------------------------------------------------
	FrostWolf = { Name = "Frost Wolf", Size = Vector3.new(2.5, 2.6, 4.8), Color = c(220, 235, 250), Health = 0.4, Attack = 0.5, Speed = 22, Aggressive = true },
	IceGolem = { Name = "Ice Golem", Size = Vector3.new(6, 8, 4), Color = c(150, 200, 240), Material = Enum.Material.Ice, Health = 0.8, Attack = 0.5, Defense = 1.3, Speed = 10, Aggressive = true },

	-- Stormbreak Coast -----------------------------------------------------
	ReefCrab = { Name = "Reef Crab", Size = Vector3.new(4, 2, 3.5), Color = c(230, 110, 80), Health = 0.5, Attack = 0.4, Defense = 1.6, Speed = 14, Aggressive = false },
	StormHarpy = { Name = "Storm Harpy", Size = Vector3.new(3, 4, 2), Color = c(110, 130, 170), Health = 0.35, Attack = 0.6, Speed = 22, Aggressive = true },

	-- Ashen Caldera --------------------------------------------------------
	MagmaImp = { Name = "Magma Imp", Size = Vector3.new(2, 3, 1.5), Color = c(255, 120, 40), Material = Enum.Material.Neon, Health = 0.35, Attack = 0.6, Speed = 20, Aggressive = true },
	CinderDrake = { Name = "Cinder Drake", Size = Vector3.new(5, 4, 9), Color = c(130, 30, 25), Material = Enum.Material.Basalt, Health = 0.7, Attack = 0.65, Speed = 17, Aggressive = true },

	-- Crystal Hollows ------------------------------------------------------
	CrystalGolem = { Name = "Crystal Golem", Size = Vector3.new(6, 8, 4), Color = c(120, 220, 255), Material = Enum.Material.Glass, Health = 0.8, Attack = 0.5, Defense = 1.5, Speed = 10, Aggressive = true },
	ShardWraith = { Name = "Shard Wraith", Size = Vector3.new(2.5, 6, 1), Color = c(180, 200, 255), Material = Enum.Material.Neon, Health = 0.35, Attack = 0.65, Speed = 20, Aggressive = true },

	-- Celestial Reach ------------------------------------------------------
	StarSentinel = { Name = "Star Sentinel", Size = Vector3.new(4, 8, 3), Color = c(240, 200, 90), Material = Enum.Material.Metal, Health = 0.7, Attack = 0.6, Defense = 1.3, Speed = 14, Aggressive = true },
	VoidSeraph = { Name = "Void Seraph", Size = Vector3.new(3, 6, 3), Color = c(90, 50, 140), Material = Enum.Material.Neon, Health = 0.5, Attack = 0.75, Speed = 22, Aggressive = true },

	-- Bosses ---------------------------------------------------------------
	RatKing = { Name = "The Rat King", Boss = true, Size = Vector3.new(4, 3, 6), Color = c(90, 70, 60) },
	GoblinChieftain = { Name = "Goblin Chieftain", Boss = true, Size = Vector3.new(4, 7, 3), Color = c(60, 120, 40) },
	BarrowKing = { Name = "Barrow-Wight King", Boss = true, Size = Vector3.new(5, 10, 3), Color = c(170, 200, 210), Material = Enum.Material.Metal },
	Thornmother = { Name = "The Thornmother", Boss = true, Size = Vector3.new(8, 10, 8), Color = c(120, 190, 60), Material = Enum.Material.Grass },
	TheEldestRoot = { Name = "The Eldest Root", Boss = true, Size = Vector3.new(12, 22, 12), Color = c(60, 80, 40), Material = Enum.Material.Wood },
	DrownedAbbess = { Name = "The Drowned Abbess", Boss = true, Size = Vector3.new(4, 10, 4), Color = c(90, 140, 130), Material = Enum.Material.Fabric },
	SandPharaoh = { Name = "The Sand Pharaoh", Boss = true, Size = Vector3.new(4, 10, 3), Color = c(240, 200, 80), Material = Enum.Material.Metal },
	GlacierColossus = { Name = "Glacier Colossus", Boss = true, Size = Vector3.new(12, 18, 8), Color = c(170, 220, 255), Material = Enum.Material.Ice },
	LeviathanSpawn = { Name = "Leviathan Spawn", Boss = true, Size = Vector3.new(10, 6, 18), Color = c(40, 90, 120), Material = Enum.Material.Slate },
	PrismWarden = { Name = "The Prism Warden", Boss = true, Size = Vector3.new(8, 14, 8), Color = c(200, 220, 255), Material = Enum.Material.Glass },
	ForgeTyrant = { Name = "The Forge Tyrant", Boss = true, Size = Vector3.new(10, 14, 8), Color = c(120, 40, 20), Material = Enum.Material.CrackedLava },
	TheFallenStar = { Name = "The Fallen Star", Boss = true, Shape = "Ball", Size = Vector3.new(14, 14, 14), Color = c(255, 225, 120), Material = Enum.Material.Neon },
}

-- Defaults applied to every monster
local DEFAULTS = {
	Shape = "Block",
	Material = Enum.Material.SmoothPlastic,
	Health = 0.4,
	Attack = 0.45,
	Defense = 1,
	Speed = 14,
	Aggressive = true,
	XP = 1,
	Gold = 1,
	AttackCooldown = 1.5,
	AggroRange = 40,
}

local BOSS_DEFAULTS = {
	Health = 3,
	Attack = 0.55,
	Defense = 1.2,
	Speed = 15,
	AttackCooldown = 1.8,
	AggroRange = 90,
	SlamEvery = 4, -- every Nth attack is an area slam
}

for id, def in pairs(Monsters) do
	def.Id = id
	if def.Boss then
		for k, v in pairs(BOSS_DEFAULTS) do
			if def[k] == nil then
				def[k] = v
			end
		end
	end
	for k, v in pairs(DEFAULTS) do
		if def[k] == nil then
			def[k] = v
		end
	end
	if def.AttackRange == nil then
		def.AttackRange = math.max(def.Size.X, def.Size.Z) / 2 + 4
	end
end

local module = {}
module.All = Monsters

function module.Get(id)
	return Monsters[id]
end

return module
