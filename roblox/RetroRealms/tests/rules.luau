--[[
	Game rule checks for Retro Realms. Run with Lune from roblox/RetroRealms:
	    lune run tests/rules.luau
	Loads the shared modules straight from src/ with Roblox datatypes from
	@lune/roblox, then checks the design rules the game is built around.
]]

local fs = require("@lune/fs")
local luau = require("@lune/luau")
local roblox = require("@lune/roblox")

local SHARED = "src/ReplicatedStorage/Shared/"
local cache = {}

local function load(name)
	if cache[name] then
		return cache[name]
	end
	local env = {
		script = { Parent = setmetatable({}, { __index = function(_, k) return k end }) },
	}
	for k, v in pairs(roblox) do
		env[k] = v
	end
	env.require = function(dep)
		return load(dep)
	end
	local source = fs.readFile(SHARED .. name .. ".lua")
	local result = luau.load(luau.compile(source), { debugName = name, environment = env })()
	cache[name] = result
	return result
end

local GameConfig = load("GameConfig")
local Progression = load("Progression")
local Worlds = load("Worlds")
local Dungeons = load("Dungeons")
local Monsters = load("Monsters")

local passed, failed = 0, 0
local function test(name, fn)
	local ok, err = pcall(fn)
	if ok then
		passed += 1
		print("PASS  " .. name)
	else
		failed += 1
		print("FAIL  " .. name .. "\n      " .. tostring(err))
	end
end

local function eq(actual, expected, label)
	if actual ~= expected then
		error(("%s: expected %s, got %s"):format(label or "value", tostring(expected), tostring(actual)), 2)
	end
end

test("there are 10 areas of the world", function()
	eq(#Worlds.List, 10, "areas")
end)

test("there are 12 dungeons", function()
	eq(#Dungeons.List, 12, "dungeons")
end)

test("the starting village area has exactly two dungeons", function()
	local start = Worlds.List[1]
	eq(start.Id, "EmberbrookVale", "first area")
	eq(table.find(start.Towns, GameConfig.StartingTown) ~= nil, true, "starting village is in the first area")
	eq(#start.Dungeons, 2, "starting dungeons")
end)

test("every area after the start has at least one town and one dungeon", function()
	for i = 2, #Worlds.List do
		local w = Worlds.List[i]
		assert(#w.Towns >= 1, w.Id .. " has no town")
		assert(#w.Dungeons >= 1, w.Id .. " has no dungeon")
		assert(#w.Monsters >= 1, w.Id .. " has no overworld monsters")
	end
end)

test("dungeon difficulty is not strictly linear across areas", function()
	local previous = -math.huge
	local dips = 0
	for _, w in ipairs(Worlds.List) do
		local lowest = math.huge
		for _, id in ipairs(w.Dungeons) do
			lowest = math.min(lowest, Dungeons.Get(id).RecommendedLevel)
		end
		if lowest < previous then
			dips += 1
		end
		previous = lowest
	end
	assert(dips >= 1, "every later area has a harder dungeon than the one before")
end)

test("max level is 2000 and the hardest dungeon is level 1200", function()
	eq(GameConfig.MaxLevel, 2000, "max level")
	local hardest = 0
	for _, d in ipairs(Dungeons.List) do
		hardest = math.max(hardest, d.RecommendedLevel)
	end
	eq(hardest, 1200, "hardest dungeon")
end)

test("a level 20 player sees a level 500 dungeon as Suicidal", function()
	eq(Progression.GetDifficulty(500, 20).Name, "Suicidal", "rating")
end)

test("a level 20 player is one-shot by a level 500 monster and barely scratches it", function()
	local p = Progression.GetStats(20)
	local m = Progression.GetStats(500)
	local hit = Progression.BaseDamage(500, m.Attack * 0.45, 20, p.Defense)
	assert(hit >= p.MaxHealth, ("monster hit %d vs player HP %d"):format(hit, p.MaxHealth))
	local swing = Progression.BaseDamage(20, p.Attack, 500, m.Defense)
	local monsterHP = m.MaxHealth * 0.4
	assert(monsterHP / math.max(1, swing) > 1000, ("only %.0f swings to kill"):format(monsterHP / math.max(1, swing)))
end)

test("a player at the recommended level gets a Fair rating", function()
	for _, d in ipairs(Dungeons.List) do
		eq(Progression.GetDifficulty(d.RecommendedLevel, d.RecommendedLevel).Name, "Fair", d.Id)
	end
end)

test("every monster and boss referenced by areas and dungeons exists", function()
	for _, w in ipairs(Worlds.List) do
		for _, m in ipairs(w.Monsters) do
			assert(Monsters.Get(m.Id), w.Id .. " uses unknown monster " .. m.Id)
		end
		for _, id in ipairs(w.Dungeons) do
			local d = Dungeons.Get(id)
			assert(d, w.Id .. " uses unknown dungeon " .. id)
			eq(d.WorldId, w.Id, id .. " world")
		end
	end
	for _, d in ipairs(Dungeons.List) do
		assert(Monsters.Get(d.BossId) and Monsters.Get(d.BossId).Boss, d.Id .. " boss missing")
		for _, m in ipairs(d.Mobs) do
			assert(Monsters.Get(m), d.Id .. " uses unknown mob " .. m)
		end
	end
end)

test("level-ups past the hardest dungeon still continue to level 2000", function()
	assert(Progression.XPToNext(1999) > Progression.XPToNext(1200), "XP curve flattens")
	local top = Progression.GetStats(2000)
	local endgame = Progression.GetStats(1200)
	assert(top.Attack > endgame.Attack * 1.5, "level 2000 should be much stronger than 1200")
end)

print(("\n%d passed, %d failed"):format(passed, failed))
if failed > 0 then
	error("rule checks failed")
end
