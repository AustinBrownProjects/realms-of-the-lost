--[[
	Dungeons
	12 dungeons across the 10 worlds. RecommendedLevel drives monster levels,
	the boss level and the difficulty rating players see. The hardest dungeon
	is level 1200 (GameConfig.AllContentLevel).

	Rooms = number of monster rooms between the entrance hall and the boss.
	Secret = hidden in the World Atlas until the player has visited its world.
]]

local function theme(floor, wall, material, light)
	return { Floor = floor, Wall = wall, Material = material, Light = light }
end

local Dungeons = {
	{
		Id = "MossyCellar",
		Name = "Mossy Cellar",
		WorldId = "EmberbrookVale",
		RecommendedLevel = 5,
		Description = "Rats have taken over the old cellar under the village.",
		Rooms = 2,
		MobsPerRoom = 3,
		Mobs = { "CellarRat", "Slime" },
		BossId = "RatKing",
		Theme = theme(Color3.fromRGB(90, 110, 70), Color3.fromRGB(110, 105, 95), Enum.Material.Cobblestone, Color3.fromRGB(255, 200, 120)),
	},
	{
		Id = "GoblinWarren",
		Name = "Goblin Warren",
		WorldId = "EmberbrookVale",
		RecommendedLevel = 20,
		Description = "A maze of tunnels where the goblin chieftain hoards stolen gold.",
		Rooms = 3,
		MobsPerRoom = 4,
		Mobs = { "Goblin" },
		BossId = "GoblinChieftain",
		Theme = theme(Color3.fromRGB(100, 80, 60), Color3.fromRGB(80, 65, 50), Enum.Material.Ground, Color3.fromRGB(255, 170, 90)),
	},
	{
		Id = "BarrowOfKings",
		Name = "Barrow of Kings",
		WorldId = "GoldgrassPlains",
		RecommendedLevel = 80,
		Description = "An ancient burial mound. The old kings do not rest quietly.",
		Rooms = 3,
		MobsPerRoom = 4,
		Mobs = { "Skeleton", "Bandit" },
		BossId = "BarrowKing",
		Theme = theme(Color3.fromRGB(120, 115, 100), Color3.fromRGB(90, 88, 80), Enum.Material.Slate, Color3.fromRGB(180, 220, 255)),
	},
	{
		Id = "ThornheartHollow",
		Name = "Thornheart Hollow",
		WorldId = "WhisperingWilds",
		RecommendedLevel = 160,
		Description = "A hollow tree the size of a castle, ruled by the Thornmother.",
		Rooms = 3,
		MobsPerRoom = 4,
		Mobs = { "ThornSprite", "DireBear" },
		BossId = "Thornmother",
		Theme = theme(Color3.fromRGB(90, 70, 45), Color3.fromRGB(70, 55, 35), Enum.Material.Wood, Color3.fromRGB(180, 255, 140)),
	},
	{
		Id = "ElderRootSanctum",
		Name = "Elder Root Sanctum",
		WorldId = "WhisperingWilds",
		RecommendedLevel = 700,
		Secret = true,
		Description = "Hidden deep in the Wilds. The Eldest Root is older than the world itself.",
		Rooms = 4,
		MobsPerRoom = 4,
		Mobs = { "AncientTreant", "ThornSprite" },
		BossId = "TheEldestRoot",
		Theme = theme(Color3.fromRGB(50, 70, 40), Color3.fromRGB(40, 50, 30), Enum.Material.WoodPlanks, Color3.fromRGB(120, 255, 160)),
	},
	{
		Id = "DrownedChapel",
		Name = "Drowned Chapel",
		WorldId = "SaltmireSwamp",
		RecommendedLevel = 220,
		Description = "A sunken chapel where the drowned still hold mass.",
		Rooms = 3,
		MobsPerRoom = 4,
		Mobs = { "MireLurker", "Skeleton" },
		BossId = "DrownedAbbess",
		Theme = theme(Color3.fromRGB(70, 85, 75), Color3.fromRGB(85, 95, 90), Enum.Material.Brick, Color3.fromRGB(140, 255, 200)),
	},
	{
		Id = "TombOfThePharaoh",
		Name = "Tomb of the Sand Pharaoh",
		WorldId = "SunscorchDesert",
		RecommendedLevel = 300,
		Description = "Traps, mummies and a pharaoh who refuses to stay dead.",
		Rooms = 4,
		MobsPerRoom = 4,
		Mobs = { "DuneMummy", "SandScorpion" },
		BossId = "SandPharaoh",
		Theme = theme(Color3.fromRGB(200, 170, 110), Color3.fromRGB(170, 140, 90), Enum.Material.Sandstone, Color3.fromRGB(255, 200, 100)),
	},
	{
		Id = "GlacierVault",
		Name = "Glacier Vault",
		WorldId = "FrostfangTundra",
		RecommendedLevel = 450,
		Description = "A vault carved into a glacier, sealed for a thousand years.",
		Rooms = 4,
		MobsPerRoom = 4,
		Mobs = { "IceGolem", "FrostWolf" },
		BossId = "GlacierColossus",
		Theme = theme(Color3.fromRGB(180, 215, 240), Color3.fromRGB(140, 180, 220), Enum.Material.Ice, Color3.fromRGB(160, 220, 255)),
	},
	{
		Id = "LeviathansGrotto",
		Name = "Leviathan's Grotto",
		WorldId = "StormbreakCoast",
		RecommendedLevel = 550,
		Description = "A sea cave where something enormous is nesting.",
		Rooms = 4,
		MobsPerRoom = 5,
		Mobs = { "ReefCrab", "StormHarpy" },
		BossId = "LeviathanSpawn",
		Theme = theme(Color3.fromRGB(60, 90, 100), Color3.fromRGB(50, 70, 80), Enum.Material.Rock, Color3.fromRGB(100, 220, 255)),
	},
	{
		Id = "PrismLabyrinth",
		Name = "Prism Labyrinth",
		WorldId = "CrystalHollows",
		RecommendedLevel = 800,
		Description = "Halls of mirrored crystal guarded by the Prism Warden.",
		Rooms = 4,
		MobsPerRoom = 5,
		Mobs = { "CrystalGolem", "ShardWraith" },
		BossId = "PrismWarden",
		Theme = theme(Color3.fromRGB(90, 100, 160), Color3.fromRGB(120, 140, 210), Enum.Material.Glass, Color3.fromRGB(170, 190, 255)),
	},
	{
		Id = "MoltenForge",
		Name = "Molten Forge",
		WorldId = "AshenCaldera",
		RecommendedLevel = 950,
		Description = "The forge where the Tyrant hammers out weapons for an army of fire.",
		Rooms = 5,
		MobsPerRoom = 5,
		Mobs = { "MagmaImp", "CinderDrake" },
		BossId = "ForgeTyrant",
		Theme = theme(Color3.fromRGB(60, 40, 35), Color3.fromRGB(45, 35, 35), Enum.Material.CrackedLava, Color3.fromRGB(255, 120, 50)),
	},
	{
		Id = "ThroneOfTheFallenStar",
		Name = "Throne of the Fallen Star",
		WorldId = "CelestialReach",
		RecommendedLevel = 1200,
		Description = "The final throne. Clear it and every corner of the world is yours.",
		Rooms = 5,
		MobsPerRoom = 5,
		Mobs = { "StarSentinel", "VoidSeraph" },
		BossId = "TheFallenStar",
		Theme = theme(Color3.fromRGB(230, 225, 245), Color3.fromRGB(200, 190, 230), Enum.Material.Marble, Color3.fromRGB(255, 230, 160)),
	},
}

local byId = {}
for _, d in ipairs(Dungeons) do
	byId[d.Id] = d
end

local module = {}
module.List = Dungeons

function module.Get(id)
	return byId[id]
end

return module
