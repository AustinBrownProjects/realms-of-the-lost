--[[
	GameConfig
	Global tuning values for Retro Realms. Change numbers here instead of
	digging through the services.
]]

local GameConfig = {
	GameName = "Retro Realms",

	-- Progression -----------------------------------------------------------
	MaxLevel = 2000,
	-- The hardest dungeon is tuned for this level. Everything after it is
	-- the "overpowered" endgame climb to MaxLevel.
	AllContentLevel = 1200,

	-- Saving ----------------------------------------------------------------
	DataStoreName = "RetroRealms_PlayerData_v1",
	AutosaveInterval = 120, -- seconds

	-- World -----------------------------------------------------------------
	-- The downloadable place file already has the greybox map saved in
	-- Workspace, so you can edit it in Studio. If you ever delete the
	-- "WorldZones" folder, a fresh placeholder map is generated at server
	-- start while this is true.
	BuildGreyboxMap = true,
	TileSize = 1000, -- studs per world tile in the greybox map
	StartingTown = "Emberbrook Village",
	RespawnTime = 4,
	TownDiscoverRadius = 45,
	TravelCooldown = 10,

	Combat = {
		PlayerAttackCooldown = 0.45,
		PlayerAttackRange = 11,
		PlayerAttackArcDot = 0.2, -- 1 = straight ahead only, 0 = 180 degree swing
		MaxTargetsPerSwing = 3,
		CritChance = 0.1,
		CritMultiplier = 1.75,
		MinDamage = 1,
		-- How much a level gap can scale damage (see Progression.LevelDiffMultiplier)
		LevelDiffMinMult = 0.02,
		LevelDiffMaxMult = 20,
	},

	Monsters = {
		AIStep = 0.2, -- seconds between AI updates
		LeashDistance = 120, -- how far a monster chases from home before giving up
		WanderRadius = 25,
		CorpseTime = 1.5,
		ActivationRange = 450, -- spawn points only fill up when a player is this close
		SpawnerStep = 2,
	},

	Dungeon = {
		JoinWindowSeconds = 15, -- players entering within this window share a run
		MaxPartySize = 6,
		ExitDelayAfterClear = 45,
		EntranceUseRange = 18,
		SlotSpacing = 1500,
		Origin = Vector3.new(12000, 300, -12000), -- dungeon instances are built out here
	},

	Rewards = {
		GoldPerLevel = 2,
		BossXPMultiplier = 8,
		BossGoldMultiplier = 25,
		ClearBonusXPMultiplier = 12,
		ClearBonusGoldMultiplier = 40,
	},

	-- Dev chat commands (/setlevel 500 etc). Always on in Studio.
	-- Add your Roblox UserId here to use them in live servers.
	DevCommandUserIds = {},
}

return GameConfig
