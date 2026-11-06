--[[
	Worlds
	The 10 areas of the world. Order is the intended "story" order, but the
	level ranges deliberately zig-zag: some later areas are easier than earlier
	ones, and some early areas hide brutal dungeons. Nothing is locked.

	Grid = tile position in the greybox map (x, z). Neighbouring tiles touch,
	so most areas have several exits = semi open world.

	Map (z goes down):
	        x=0                 x=1                 x=2
	z=0  Emberbrook Vale     Goldgrass Plains    Sunscorch Desert
	z=1  Whispering Wilds    Saltmire Swamp      Ashen Caldera
	z=2  Frostfang Tundra    Stormbreak Coast    Crystal Hollows
	z=3                      Celestial Reach
]]

local Worlds = {
	{
		Id = "EmberbrookVale",
		Name = "Emberbrook Vale",
		Order = 1,
		Biome = "Meadow",
		LevelRange = { 1, 30 },
		Grid = Vector2.new(0, 0),
		Description = "Rolling green meadows around the starting village. Two beginner dungeons lie nearby.",
		GroundColor = Color3.fromRGB(106, 170, 72),
		GroundMaterial = Enum.Material.Grass,
		Towns = { "Emberbrook Village" },
		Monsters = {
			{ Id = "Slime", MinLevel = 1, MaxLevel = 6, Spawns = 3 },
			{ Id = "WildBoar", MinLevel = 5, MaxLevel = 15, Spawns = 3 },
			{ Id = "Goblin", MinLevel = 12, MaxLevel = 28, Spawns = 2 },
		},
		Dungeons = { "MossyCellar", "GoblinWarren" },
		Lighting = { ClockTime = 14, Atmosphere = Color3.fromRGB(200, 225, 255), Density = 0.25 },
	},
	{
		Id = "GoldgrassPlains",
		Name = "Goldgrass Plains",
		Order = 2,
		Biome = "Plains",
		LevelRange = { 20, 120 },
		Grid = Vector2.new(1, 0),
		Description = "Wide golden fields with farming towns, roaming wolves and bandit camps.",
		GroundColor = Color3.fromRGB(178, 176, 82),
		GroundMaterial = Enum.Material.Grass,
		Towns = { "Haymarket", "Millbrook" },
		Monsters = {
			{ Id = "PlainsWolf", MinLevel = 20, MaxLevel = 60, Spawns = 3 },
			{ Id = "Bandit", MinLevel = 45, MaxLevel = 90, Spawns = 3 },
			{ Id = "GiantBeetle", MinLevel = 80, MaxLevel = 120, Spawns = 2 },
		},
		Dungeons = { "BarrowOfKings" },
		Lighting = { ClockTime = 15.5, Atmosphere = Color3.fromRGB(255, 235, 190), Density = 0.25 },
	},
	{
		Id = "WhisperingWilds",
		Name = "Whispering Wilds",
		Order = 3,
		Biome = "Forest",
		LevelRange = { 90, 220 },
		Grid = Vector2.new(0, 1),
		Description = "A dense forest. Most of it is manageable, but something ancient sleeps in the deep woods.",
		GroundColor = Color3.fromRGB(52, 110, 52),
		GroundMaterial = Enum.Material.LeafyGrass,
		Towns = { "Thornwick" },
		Monsters = {
			{ Id = "ThornSprite", MinLevel = 90, MaxLevel = 150, Spawns = 3 },
			{ Id = "DireBear", MinLevel = 140, MaxLevel = 220, Spawns = 3 },
			-- A high-level threat in a mid-level area, guarding the secret dungeon
			{ Id = "AncientTreant", MinLevel = 650, MaxLevel = 700, Spawns = 1, NearDungeon = "ElderRootSanctum" },
		},
		Dungeons = { "ThornheartHollow", "ElderRootSanctum" },
		Lighting = { ClockTime = 16.5, Atmosphere = Color3.fromRGB(150, 200, 150), Density = 0.4 },
	},
	{
		Id = "SunscorchDesert",
		Name = "Sunscorch Desert",
		Order = 4,
		Biome = "Desert",
		LevelRange = { 180, 350 },
		Grid = Vector2.new(2, 0),
		Description = "Blistering dunes, scorpions and the buried tomb of a forgotten pharaoh.",
		GroundColor = Color3.fromRGB(226, 196, 122),
		GroundMaterial = Enum.Material.Sand,
		Towns = { "Oasis Sahra", "Dunerest" },
		Monsters = {
			{ Id = "SandScorpion", MinLevel = 180, MaxLevel = 260, Spawns = 3 },
			{ Id = "DuneMummy", MinLevel = 240, MaxLevel = 350, Spawns = 3 },
		},
		Dungeons = { "TombOfThePharaoh" },
		Lighting = { ClockTime = 13, Atmosphere = Color3.fromRGB(255, 220, 160), Density = 0.3 },
	},
	{
		Id = "SaltmireSwamp",
		Name = "Saltmire Swamp",
		Order = 5,
		Biome = "Swamp",
		LevelRange = { 150, 280 },
		Grid = Vector2.new(1, 1),
		Description = "A misty marsh. Easier than the desert, if you don't mind the smell.",
		GroundColor = Color3.fromRGB(88, 96, 60),
		GroundMaterial = Enum.Material.Mud,
		Towns = { "Stilthaven" },
		Monsters = {
			{ Id = "BogToad", MinLevel = 150, MaxLevel = 210, Spawns = 3 },
			{ Id = "MireLurker", MinLevel = 200, MaxLevel = 280, Spawns = 3 },
		},
		Dungeons = { "DrownedChapel" },
		Lighting = { ClockTime = 17.5, Atmosphere = Color3.fromRGB(150, 165, 130), Density = 0.5 },
	},
	{
		Id = "FrostfangTundra",
		Name = "Frostfang Tundra",
		Order = 6,
		Biome = "Snow",
		LevelRange = { 300, 550 },
		Grid = Vector2.new(0, 2),
		Description = "Frozen wastes where wolves hunt in packs and golems of ice guard a sealed vault.",
		GroundColor = Color3.fromRGB(236, 241, 250),
		GroundMaterial = Enum.Material.Snow,
		Towns = { "Icehold", "Frostmere" },
		Monsters = {
			{ Id = "FrostWolf", MinLevel = 300, MaxLevel = 420, Spawns = 3 },
			{ Id = "IceGolem", MinLevel = 400, MaxLevel = 550, Spawns = 3 },
		},
		Dungeons = { "GlacierVault" },
		Lighting = { ClockTime = 12, Atmosphere = Color3.fromRGB(220, 235, 255), Density = 0.45 },
	},
	{
		Id = "StormbreakCoast",
		Name = "Stormbreak Coast",
		Order = 7,
		Biome = "Coast",
		LevelRange = { 400, 650 },
		Grid = Vector2.new(1, 2),
		Description = "Wind-lashed cliffs and beaches. Harpies circle above the leviathan's grotto.",
		GroundColor = Color3.fromRGB(196, 186, 150),
		GroundMaterial = Enum.Material.Sand,
		Towns = { "Port Gale", "Saltcliff" },
		Monsters = {
			{ Id = "ReefCrab", MinLevel = 400, MaxLevel = 520, Spawns = 3 },
			{ Id = "StormHarpy", MinLevel = 500, MaxLevel = 650, Spawns = 3 },
		},
		Dungeons = { "LeviathansGrotto" },
		Lighting = { ClockTime = 9, Atmosphere = Color3.fromRGB(170, 190, 210), Density = 0.4 },
	},
	{
		Id = "AshenCaldera",
		Name = "Ashen Caldera",
		Order = 8,
		Biome = "Volcanic",
		LevelRange = { 650, 1000 },
		Grid = Vector2.new(2, 1),
		Description = "A volcanic crater full of lava rivers. Harder than the Crystal Hollows beyond it.",
		GroundColor = Color3.fromRGB(58, 48, 48),
		GroundMaterial = Enum.Material.Basalt,
		Towns = { "Cinderkeep" },
		Monsters = {
			{ Id = "MagmaImp", MinLevel = 650, MaxLevel = 820, Spawns = 3 },
			{ Id = "CinderDrake", MinLevel = 800, MaxLevel = 1000, Spawns = 3 },
		},
		Dungeons = { "MoltenForge" },
		Lighting = { ClockTime = 18.3, Atmosphere = Color3.fromRGB(255, 130, 80), Density = 0.5 },
	},
	{
		Id = "CrystalHollows",
		Name = "Crystal Hollows",
		Order = 9,
		Biome = "Crystal",
		LevelRange = { 600, 900 },
		Grid = Vector2.new(2, 2),
		Description = "Glittering caverns open to the sky, home to golems of living crystal.",
		GroundColor = Color3.fromRGB(78, 88, 132),
		GroundMaterial = Enum.Material.Slate,
		Towns = { "Glimmerdeep", "Shardrest" },
		Monsters = {
			{ Id = "CrystalGolem", MinLevel = 600, MaxLevel = 760, Spawns = 3 },
			{ Id = "ShardWraith", MinLevel = 720, MaxLevel = 900, Spawns = 3 },
		},
		Dungeons = { "PrismLabyrinth" },
		Lighting = { ClockTime = 20, Atmosphere = Color3.fromRGB(140, 160, 255), Density = 0.45 },
	},
	{
		Id = "CelestialReach",
		Name = "Celestial Reach",
		Order = 10,
		Biome = "Celestial",
		LevelRange = { 1000, 1300 },
		Grid = Vector2.new(1, 3),
		Description = "Ruins at the edge of the sky. The Fallen Star waits on its throne.",
		GroundColor = Color3.fromRGB(222, 216, 238),
		GroundMaterial = Enum.Material.Marble,
		Towns = { "Skyhaven" },
		Monsters = {
			{ Id = "StarSentinel", MinLevel = 1000, MaxLevel = 1150, Spawns = 3 },
			{ Id = "VoidSeraph", MinLevel = 1100, MaxLevel = 1300, Spawns = 3 },
		},
		Dungeons = { "ThroneOfTheFallenStar" },
		Lighting = { ClockTime = 0.5, Atmosphere = Color3.fromRGB(190, 170, 255), Density = 0.3 },
	},
}

local byId = {}
for _, world in ipairs(Worlds) do
	byId[world.Id] = world
end

local module = {}
module.List = Worlds

function module.Get(id)
	return byId[id]
end

return module
