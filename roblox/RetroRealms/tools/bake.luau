--[[
	Bakes the greybox map into a place file so it can be edited in Studio.
	Usage (from roblox/RetroRealms):
	    rojo build -o build/scripts.rbxlx
	    lune run tools/bake.luau build/scripts.rbxlx build/RetroRealms.rbxl
]]
local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local luau = require("@lune/luau")
local task = require("@lune/task")
local process = require("@lune/process")

local inPath, outPath = process.args[1], process.args[2]
local game = roblox.deserializePlace(fs.readFile(inPath))
local Instance = roblox.Instance

-- Minimal stand-ins for things Lune doesn't have
local function makeRandom(seed)
	local state = seed % 2147483647
	if state <= 0 then state += 2147483646 end
	local function nextRaw()
		state = (state * 16807) % 2147483647
		return state / 2147483647
	end
	return {
		NextNumber = function(_, a, b)
			local r = nextRaw()
			if a then return a + (b - a) * r end
			return r
		end,
		NextInteger = function(_, a, b)
			return a + math.floor(nextRaw() * (b - a + 1))
		end,
	}
end
local RandomShim = { new = function(seed) return makeRandom(seed or os.time()) end }

local cache = {}
local function loadModule(moduleScript)
	if cache[moduleScript] then return cache[moduleScript] end
	local source = moduleScript.Source
	source = source:gsub(":WaitForChild%(", ":FindFirstChild(")
	local env = setmetatable({
		script = moduleScript,
		game = game,
		workspace = game:GetService("Workspace"),
		Instance = Instance,
		Random = RandomShim,
		task = { wait = function() end, spawn = task.spawn, delay = task.delay, defer = task.defer },
		warn = function(...) print("[warn]", ...) ; _G.WARNINGS = (_G.WARNINGS or 0) + 1 end,
	}, nil)
	for k, v in pairs(roblox) do
		if env[k] == nil then env[k] = v end
	end
	env.require = function(m) return loadModule(m) end
	local fn = luau.load(luau.compile(source), { debugName = moduleScript:GetFullName(), environment = env })
	local result = fn()
	cache[moduleScript] = result
	return result
end

local sss = game:GetService("ServerScriptService")
local builderModule = sss.GameServer.GreyboxMapBuilder
local Builder = loadModule(builderModule)

local ws = game:GetService("Workspace")
assert(not ws:FindFirstChild("WorldZones"), "map already baked")
Builder.BuildWorld()

-- Every dungeon arena must build without errors
local Dungeons = loadModule(game:GetService("ReplicatedStorage").Shared.Dungeons)
for i, def in ipairs(Dungeons.List) do
	local arena = Builder.BuildDungeonArena(def, roblox.Vector3.new(12000 + i * 1500, 300, -12000))
	assert(arena.Model and #arena.MobCFrames == def.Rooms * def.MobsPerRoom, "bad arena " .. def.Id)
	arena.Model:Destroy()
end

-- Give every generated model a sensible pivot (Studio does this automatically)
for _, inst in ipairs(ws:GetDescendants()) do
	if inst:IsA("Model") then
		local min, max
		for _, p in ipairs(inst:GetDescendants()) do
			if p:IsA("BasePart") then
				local pos = p.CFrame.Position
				min = min and roblox.Vector3.new(math.min(min.X, pos.X), math.min(min.Y, pos.Y), math.min(min.Z, pos.Z)) or pos
				max = max and roblox.Vector3.new(math.max(max.X, pos.X), math.max(max.Y, pos.Y), math.max(max.Z, pos.Z)) or pos
			end
		end
		if min then
			inst.WorldPivot = roblox.CFrame.new((min + max) / 2)
		end
	end
end

local counts = {}
for _, name in ipairs({ "Map", "WorldZones", "Towns", "DungeonEntrances", "MonsterSpawns" }) do
	local f = ws:FindFirstChild(name)
	local parts = 0
	for _, d in ipairs(f and f:GetDescendants() or {}) do
		if d:IsA("BasePart") then parts += 1 end
	end
	counts[name] = parts
	print(name, parts)
end
print("warnings:", _G.WARNINGS or 0)
fs.writeFile(outPath, roblox.serializePlace(game, string.sub(outPath, -6) == ".rbxlx"))
print("wrote", outPath)
