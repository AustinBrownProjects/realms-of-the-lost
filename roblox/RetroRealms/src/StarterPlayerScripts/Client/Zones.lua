--[[
	Zones
	When you walk into a new area (or a dungeon): show the big banner and
	fade the sky / fog to that area's mood.
]]

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Progression = require(Shared:WaitForChild("Progression"))
local Worlds = require(Shared:WaitForChild("Worlds"))
local Dungeons = require(Shared:WaitForChild("Dungeons"))

local UI = require(script.Parent.UI)
local State = require(script.Parent.State)
local Hud = require(script.Parent.Hud)

local Zones = {}

local atmosphere
local baseAmbient

local NIGHT_AMBIENT = Color3.fromRGB(80, 75, 100)
local DUNGEON = {
	ClockTime = 0,
	Atmosphere = Color3.fromRGB(40, 36, 52),
	Density = 0.38,
	Ambient = Color3.fromRGB(55, 50, 70),
}

local function applyLighting(clock, color, density, ambient)
	UI.tween(Lighting, 2, { ClockTime = clock, Ambient = ambient })
	UI.tween(atmosphere, 2, { Color = color, Decay = color:Lerp(Color3.new(0, 0, 0), 0.3), Density = density })
end

local function onZone(kind, id)
	local level = State.Level()
	if kind == "World" then
		local world = Worlds.Get(id)
		if not world then
			return
		end
		local d = Progression.GetDifficulty(world.LevelRange[1], level)
		Hud.Banner(string.upper(world.Name), ("Area level %d - %d   |   %s"):format(world.LevelRange[1], world.LevelRange[2], d.Name), d.Color)
		local l = world.Lighting or {}
		local clock = l.ClockTime or 14
		local night = clock < 6.5 or clock > 18.5
		applyLighting(clock, l.Atmosphere or Color3.fromRGB(200, 220, 255), l.Density or 0.3, night and NIGHT_AMBIENT or baseAmbient)
	elseif kind == "Dungeon" then
		local def = Dungeons.Get(id)
		if not def then
			return
		end
		local d = Progression.GetDifficulty(def.RecommendedLevel, level)
		Hud.Banner(string.upper(def.Name), ("Recommended level %d   |   %s"):format(def.RecommendedLevel, d.Name), d.Color)
		applyLighting(DUNGEON.ClockTime, DUNGEON.Atmosphere, DUNGEON.Density, DUNGEON.Ambient)
	end
end

function Zones.Init()
	atmosphere = Lighting:FindFirstChildOfClass("Atmosphere")
	if not atmosphere then
		atmosphere = Instance.new("Atmosphere")
		atmosphere.Parent = Lighting
	end
	atmosphere.Offset = 0.1
	atmosphere.Glare = 0
	atmosphere.Haze = 1.2
	baseAmbient = Lighting.Ambient
	State.ZoneChanged:Connect(onZone)
end

return Zones
