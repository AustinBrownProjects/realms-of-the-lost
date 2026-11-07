--[[
	GreyboxMapBuilder
	Generates a playable placeholder world at server start when the place has
	no Workspace.WorldZones folder (and GameConfig.BuildGreyboxMap is true):
	  - one TileSize x TileSize tile per world, laid out on Worlds[].Grid
	  - towns (SpawnLocations), dungeon entrances and monster spawn points
	  - roads, signposts, border cliffs and simple blocky biome scenery
	It also builds the greybox dungeon arenas used when a dungeon has no
	custom template in ServerStorage > DungeonTemplates.

	Want to hand-build the map? Press Play, copy these folders from Workspace:
	Map, WorldZones, Towns, DungeonEntrances, MonsterSpawns. Stop the game,
	paste them into Workspace, then set GameConfig.BuildGreyboxMap = false.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local Worlds = require(Shared:WaitForChild("Worlds"))
local Dungeons = require(Shared:WaitForChild("Dungeons"))

local Builder = {}

local T = GameConfig.TileSize
local HALF = T / 2
local EDGE = HALF - 40 -- keep content away from the border cliffs

-- Offsets inside a tile (tile centre = 0,0)
local TOWN_SLOTS = { Vector3.new(0, 0, 0), Vector3.new(-280, 0, 280) }
local DUNGEON_SLOTS = { Vector3.new(250, 0, -250), Vector3.new(-270, 0, -230), Vector3.new(300, 0, 120) }
local SECRET_SLOT = Vector3.new(390, 0, 390)
local DIRS = { Vector2.new(1, 0), Vector2.new(-1, 0), Vector2.new(0, 1), Vector2.new(0, -1) }

local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

local function darken(c, a)
	return c:Lerp(Color3.new(0, 0, 0), a)
end

local function lighten(c, a)
	return c:Lerp(Color3.new(1, 1, 1), a)
end

local function flat(v)
	return Vector3.new(v.X, 0, v.Z)
end

local function newPart(parent, size, cframe, color, material, shape)
	local p = Instance.new("Part")
	if shape then
		p.Shape = shape
	end
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Size = size
	p.CFrame = cframe
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.Parent = parent
	return p
end

-- Scenery: not hit by raycasts (so monsters never spawn on tree tops)
local function deco(parent, size, cframe, color, material, collide, shape)
	local p = newPart(parent, size, cframe, color, material, shape)
	p.CanQuery = false
	p.CanTouch = false
	p.CanCollide = collide ~= false
	return p
end

local function newFolder(name, parent)
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
end

local function billboard(parent, position, title, subtitle, color, maxDistance)
	local anchor = Instance.new("Part")
	anchor.Name = "Sign"
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Transparency = 1
	anchor.Size = Vector3.new(1, 1, 1)
	anchor.CFrame = CFrame.new(position)
	anchor.Parent = parent

	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(300, 56)
	gui.MaxDistance = maxDistance or 220
	gui.LightInfluence = 0
	gui.Parent = anchor

	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.new(1, 0, 0.6, 0)
	t.Font = Enum.Font.Arcade
	t.TextScaled = true
	t.Text = title
	t.TextColor3 = color or Color3.new(1, 1, 1)
	t.TextStrokeTransparency = 0
	t.Parent = gui

	if subtitle then
		local s = t:Clone()
		s.Size = UDim2.new(1, 0, 0.4, 0)
		s.Position = UDim2.fromScale(0, 0.6)
		s.Font = Enum.Font.Code
		s.Text = subtitle
		s.TextColor3 = Color3.fromRGB(235, 230, 215)
		s.Parent = gui
	end
	return anchor
end

local function distToSegment(p, a, b)
	local ab = flat(b - a)
	local ap = flat(p - a)
	local len2 = ab:Dot(ab)
	if len2 < 1e-6 then
		return ap.Magnitude
	end
	local t = math.clamp(ap:Dot(ab) / len2, 0, 1)
	return (ap - ab * t).Magnitude
end

local function blocked(pos, avoid, roads, pad)
	for _, a in ipairs(avoid) do
		if flat(pos - a.Pos).Magnitude < a.Radius + pad then
			return true
		end
	end
	for _, r in ipairs(roads) do
		if distToSegment(pos, r[1], r[2]) < 9 + pad then
			return true
		end
	end
	return false
end

---------------------------------------------------------------------------
-- Scenery pieces
---------------------------------------------------------------------------

local BARK = rgb(105, 75, 50)

local function tree(f, rng, p, trunk, leaf, height, style)
	local h = height * (0.75 + rng:NextNumber() * 0.5)
	local w = math.max(1.6, h * 0.11)
	local spin = CFrame.Angles(0, rng:NextNumber() * math.pi, 0)
	deco(f, Vector3.new(w, h, w), CFrame.new(p + Vector3.new(0, h / 2, 0)) * spin, trunk, Enum.Material.Wood)

	if style == "Pine" then
		for i = 0, 2 do
			local s = h * (0.8 - i * 0.22)
			deco(f, Vector3.new(s, h * 0.2, s), CFrame.new(p + Vector3.new(0, h * 0.42 + i * h * 0.2, 0)) * spin, leaf, Enum.Material.Grass)
		end
	elseif style == "Dead" then
		for _, side in ipairs({ -1, 1 }) do
			local len = h * 0.4
			deco(
				f,
				Vector3.new(w * 0.6, len, w * 0.6),
				CFrame.new(p + Vector3.new(0, h * 0.75, 0)) * spin * CFrame.Angles(0, 0, side * math.rad(40)) * CFrame.new(0, len / 2, 0),
				trunk,
				Enum.Material.Wood
			)
		end
	elseif style == "Palm" then
		local top = p + Vector3.new(0, h, 0)
		for i = 0, 3 do
			deco(
				f,
				Vector3.new(2, 0.5, h * 0.45),
				CFrame.new(top) * CFrame.Angles(0, i * math.pi / 2 + rng:NextNumber() * 0.3, 0) * CFrame.Angles(math.rad(-15), 0, 0) * CFrame.new(0, 0, -h * 0.2),
				leaf,
				Enum.Material.Grass,
				false
			)
		end
	else
		local s = h * 0.7
		deco(f, Vector3.new(s, s * 0.8, s), CFrame.new(p + Vector3.new(0, h + s * 0.2, 0)) * spin, leaf, Enum.Material.Grass)
	end
end

local function rock(f, rng, p, color, material, scale)
	local s = (3 + rng:NextNumber() * 7) * (scale or 1)
	local size = Vector3.new(s * (0.8 + rng:NextNumber() * 0.6), s * (0.5 + rng:NextNumber() * 0.5), s * (0.8 + rng:NextNumber() * 0.6))
	local cf = CFrame.new(p + Vector3.new(0, size.Y * 0.35, 0))
		* CFrame.Angles(rng:NextNumber() * 0.4, rng:NextNumber() * math.pi, rng:NextNumber() * 0.4)
	deco(f, size, cf, color, material)
end

local FLOWER_COLORS = { rgb(255, 90, 90), rgb(255, 220, 80), rgb(140, 160, 255), rgb(255, 255, 255), rgb(255, 140, 220) }
local function flowers(f, rng, p)
	for _ = 1, rng:NextInteger(3, 6) do
		local o = Vector3.new(rng:NextNumber() * 6 - 3, 0.4, rng:NextNumber() * 6 - 3)
		deco(f, Vector3.new(0.8, 0.8, 0.8), CFrame.new(p + o), FLOWER_COLORS[rng:NextInteger(1, #FLOWER_COLORS)], Enum.Material.SmoothPlastic, false)
	end
end

local function hay(f, rng, p)
	deco(f, Vector3.new(5, 5, 5), CFrame.new(p + Vector3.new(0, 2.5, 0)) * CFrame.Angles(0, rng:NextNumber() * math.pi, 0), rgb(222, 190, 92), Enum.Material.Grass, true, Enum.PartType.Cylinder)
end

local function cactus(f, rng, p)
	local h = 8 + rng:NextNumber() * 8
	local green = rgb(88, 140, 62)
	local spin = CFrame.Angles(0, rng:NextNumber() * math.pi, 0)
	local base = CFrame.new(p) * spin
	deco(f, Vector3.new(2.4, h, 2.4), base * CFrame.new(0, h / 2, 0), green, Enum.Material.Grass)
	for _, side in ipairs({ -1, 1 }) do
		if rng:NextNumber() < 0.7 then
			local ah = h * 0.35
			local y = h * (0.4 + rng:NextNumber() * 0.2)
			deco(f, Vector3.new(2.2, 1.6, 1.6), base * CFrame.new(side * 2, y, 0), green, Enum.Material.Grass)
			deco(f, Vector3.new(1.6, ah, 1.6), base * CFrame.new(side * 3, y + ah / 2, 0), green, Enum.Material.Grass)
		end
	end
end

local function bones(f, rng, p)
	local white = rgb(235, 230, 215)
	for _ = 1, 3 do
		deco(
			f,
			Vector3.new(0.6, 0.6, 3 + rng:NextNumber() * 2),
			CFrame.new(p + Vector3.new(rng:NextNumber() * 4 - 2, 0.3, rng:NextNumber() * 4 - 2)) * CFrame.Angles(0, rng:NextNumber() * math.pi, 0),
			white,
			Enum.Material.SmoothPlastic,
			false
		)
	end
end

local function pool(f, rng, p, color, material, transparency, glow)
	local r = 10 + rng:NextNumber() * 18
	local part = deco(f, Vector3.new(0.4, r * 2, r * 2), CFrame.new(p + Vector3.new(0, 0.12, 0)) * CFrame.Angles(0, 0, math.pi / 2), color, material, false, Enum.PartType.Cylinder)
	part.Transparency = transparency or 0
	if glow then
		local light = Instance.new("PointLight")
		light.Color = color
		light.Range = math.min(40, r * 1.5)
		light.Brightness = 1.5
		light.Parent = part
	end
end

local function reeds(f, rng, p)
	for _ = 1, rng:NextInteger(3, 5) do
		local h = 3 + rng:NextNumber() * 3
		deco(
			f,
			Vector3.new(0.4, h, 0.4),
			CFrame.new(p + Vector3.new(rng:NextNumber() * 3 - 1.5, h / 2, rng:NextNumber() * 3 - 1.5)) * CFrame.Angles(rng:NextNumber() * 0.3 - 0.15, 0, rng:NextNumber() * 0.3 - 0.15),
			rgb(110, 130, 60),
			Enum.Material.Grass,
			false
		)
	end
end

local function spike(f, rng, p, color, material, height, glow)
	local h = height * (0.6 + rng:NextNumber() * 0.8)
	local w = h * (0.15 + rng:NextNumber() * 0.1)
	local part = deco(
		f,
		Vector3.new(w, h, w),
		CFrame.new(p) * CFrame.Angles(rng:NextNumber() * 0.5 - 0.25, rng:NextNumber() * math.pi, rng:NextNumber() * 0.5 - 0.25) * CFrame.new(0, h / 2 - 1, 0),
		color,
		material
	)
	if glow then
		local light = Instance.new("PointLight")
		light.Color = color
		light.Range = 22
		light.Brightness = 1.2
		light.Parent = part
	end
	return part
end

local CRYSTAL_COLORS = { rgb(120, 220, 255), rgb(190, 120, 255), rgb(255, 130, 220), rgb(140, 255, 210) }
local function crystals(f, rng, p)
	local color = CRYSTAL_COLORS[rng:NextInteger(1, #CRYSTAL_COLORS)]
	for i = 1, rng:NextInteger(2, 4) do
		local o = Vector3.new(rng:NextNumber() * 6 - 3, 0, rng:NextNumber() * 6 - 3)
		spike(f, rng, p + o, color, i == 1 and Enum.Material.Neon or Enum.Material.Glass, 14, i == 1)
	end
end

local function pillar(f, rng, p, color)
	local broken = rng:NextNumber() < 0.4
	local h = broken and (6 + rng:NextNumber() * 10) or (18 + rng:NextNumber() * 10)
	local float = (not broken and rng:NextNumber() < 0.3) and (6 + rng:NextNumber() * 10) or 0
	deco(f, Vector3.new(4, h, 4), CFrame.new(p + Vector3.new(0, h / 2 + float, 0)), color, Enum.Material.Marble)
	if not broken then
		deco(f, Vector3.new(6, 1.5, 6), CFrame.new(p + Vector3.new(0, h + float + 0.75, 0)), lighten(color, 0.3), Enum.Material.Marble)
		deco(f, Vector3.new(6, 1.5, 6), CFrame.new(p + Vector3.new(0, float + 0.75, 0)), lighten(color, 0.3), Enum.Material.Marble)
	end
end

local function orb(f, rng, p, color)
	local d = 2 + rng:NextNumber() * 3
	local part = deco(f, Vector3.new(d, d, d), CFrame.new(p + Vector3.new(0, 8 + rng:NextNumber() * 14, 0)), color, Enum.Material.Neon, false, Enum.PartType.Ball)
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = 26
	light.Brightness = 1.5
	light.Parent = part
end

local function mushroom(f, rng, p)
	local h = 2 + rng:NextNumber() * 3
	deco(f, Vector3.new(1, h, 1), CFrame.new(p + Vector3.new(0, h / 2, 0)), rgb(235, 225, 200), Enum.Material.SmoothPlastic, false)
	deco(f, Vector3.new(h * 1.2, h * 0.4, h * 1.2), CFrame.new(p + Vector3.new(0, h, 0)), rgb(210, 50, 50), Enum.Material.SmoothPlastic, false)
end

-- weight, function(folder, rng, position, world)
local SCENERY = {
	Meadow = { Count = 110, Items = {
		{ 6, function(f, r, p) tree(f, r, p, BARK, rgb(80, 160, 64), 18) end },
		{ 2, function(f, r, p) rock(f, r, p, rgb(140, 140, 132), Enum.Material.Slate, 0.8) end },
		{ 4, function(f, r, p) flowers(f, r, p) end },
	} },
	Plains = { Count = 90, Items = {
		{ 3, function(f, r, p) hay(f, r, p) end },
		{ 2, function(f, r, p) tree(f, r, p, BARK, rgb(120, 150, 60), 16) end },
		{ 1, function(f, r, p) rock(f, r, p, rgb(150, 140, 120), Enum.Material.Slate, 0.8) end },
		{ 2, function(f, r, p) flowers(f, r, p) end },
	} },
	Forest = { Count = 220, Items = {
		{ 7, function(f, r, p) tree(f, r, p, rgb(80, 58, 38), rgb(40, 100, 45), 30) end },
		{ 3, function(f, r, p) tree(f, r, p, rgb(80, 58, 38), rgb(30, 80, 45), 34, "Pine") end },
		{ 1, function(f, r, p) rock(f, r, p, rgb(100, 110, 95), Enum.Material.Slate, 1) end },
		{ 2, function(f, r, p) mushroom(f, r, p) end },
	} },
	Desert = { Count = 90, Items = {
		{ 4, function(f, r, p) cactus(f, r, p) end },
		{ 3, function(f, r, p) rock(f, r, p, rgb(205, 165, 110), Enum.Material.Sandstone, 1.4) end },
		{ 1, function(f, r, p) bones(f, r, p) end },
	} },
	Swamp = { Count = 120, Items = {
		{ 4, function(f, r, p) tree(f, r, p, rgb(85, 80, 65), rgb(0, 0, 0), 20, "Dead") end },
		{ 3, function(f, r, p) pool(f, r, p, rgb(60, 90, 70), Enum.Material.SmoothPlastic, 0.2) end },
		{ 3, function(f, r, p) reeds(f, r, p) end },
		{ 1, function(f, r, p) mushroom(f, r, p) end },
	} },
	Snow = { Count = 130, Items = {
		{ 6, function(f, r, p) tree(f, r, p, rgb(90, 70, 55), rgb(225, 235, 240), 26, "Pine") end },
		{ 3, function(f, r, p) spike(f, r, p, rgb(170, 215, 245), Enum.Material.Ice, 14) end },
		{ 1, function(f, r, p) rock(f, r, p, rgb(200, 205, 215), Enum.Material.Slate, 1.2) end },
	} },
	Coast = { Count = 90, Items = {
		{ 3, function(f, r, p) tree(f, r, p, rgb(150, 120, 80), rgb(70, 150, 70), 20, "Palm") end },
		{ 3, function(f, r, p) rock(f, r, p, rgb(120, 125, 130), Enum.Material.Slate, 1.5) end },
		{ 2, function(f, r, p) pool(f, r, p, rgb(60, 140, 200), Enum.Material.Glass, 0.3) end },
	} },
	Volcanic = { Count = 110, Items = {
		{ 3, function(f, r, p) pool(f, r, p, rgb(255, 110, 30), Enum.Material.Neon, 0, true) end },
		{ 4, function(f, r, p) spike(f, r, p, rgb(45, 38, 38), Enum.Material.Basalt, 24) end },
		{ 2, function(f, r, p) rock(f, r, p, rgb(70, 60, 58), Enum.Material.Basalt, 1.4) end },
	} },
	Crystal = { Count = 120, Items = {
		{ 5, function(f, r, p) crystals(f, r, p) end },
		{ 2, function(f, r, p) rock(f, r, p, rgb(70, 75, 110), Enum.Material.Slate, 1.4) end },
	} },
	Celestial = { Count = 80, Items = {
		{ 4, function(f, r, p) pillar(f, r, p, rgb(230, 225, 245)) end },
		{ 2, function(f, r, p) orb(f, r, p, rgb(200, 180, 255)) end },
		{ 1, function(f, r, p) rock(f, r, p, rgb(200, 195, 220), Enum.Material.Marble, 1) end },
	} },
}

local HOUSE = {
	Meadow = { Wall = rgb(235, 225, 200), Roof = rgb(170, 70, 50), Mat = Enum.Material.WoodPlanks },
	Plains = { Wall = rgb(225, 210, 170), Roof = rgb(150, 100, 50), Mat = Enum.Material.WoodPlanks },
	Forest = { Wall = rgb(130, 95, 60), Roof = rgb(60, 95, 50), Mat = Enum.Material.Wood },
	Desert = { Wall = rgb(220, 190, 140), Roof = rgb(200, 165, 110), Mat = Enum.Material.Sandstone },
	Swamp = { Wall = rgb(110, 95, 70), Roof = rgb(80, 90, 60), Mat = Enum.Material.WoodPlanks },
	Snow = { Wall = rgb(110, 80, 60), Roof = rgb(240, 245, 255), Mat = Enum.Material.WoodPlanks },
	Coast = { Wall = rgb(235, 235, 230), Roof = rgb(60, 110, 170), Mat = Enum.Material.Concrete },
	Volcanic = { Wall = rgb(70, 60, 60), Roof = rgb(150, 50, 30), Mat = Enum.Material.Basalt },
	Crystal = { Wall = rgb(100, 110, 150), Roof = rgb(150, 200, 255), Mat = Enum.Material.Slate },
	Celestial = { Wall = rgb(240, 235, 250), Roof = rgb(220, 190, 110), Mat = Enum.Material.Marble },
}

local function decorate(folder, rng, world, center, avoid, roads)
	local set = SCENERY[world.Biome] or SCENERY.Meadow
	local total = 0
	for _, item in ipairs(set.Items) do
		total += item[1]
	end
	for _ = 1, set.Count do
		for _ = 1, 8 do
			local p = center + Vector3.new(rng:NextNumber() * EDGE * 2 - EDGE, 0, rng:NextNumber() * EDGE * 2 - EDGE)
			if not blocked(p, avoid, roads, 8) then
				local roll = rng:NextNumber() * total
				for _, item in ipairs(set.Items) do
					roll -= item[1]
					if roll <= 0 then
						item[2](folder, rng, p, world)
						break
					end
				end
				break
			end
		end
	end
end

---------------------------------------------------------------------------
-- Towns, entrances, roads, borders
---------------------------------------------------------------------------

local function house(parent, cf, style, rng)
	local w, h, d = 14 + rng:NextInteger(0, 4), 9 + rng:NextInteger(0, 3), 12
	newPart(parent, Vector3.new(w, h, d), cf * CFrame.new(0, h / 2, 0), style.Wall, style.Mat)
	newPart(parent, Vector3.new(4, 6, 0.4), cf * CFrame.new(0, 3, -d / 2 - 0.2), darken(style.Wall, 0.6), Enum.Material.Wood)
	for _, x in ipairs({ -w / 2 + 3, w / 2 - 3 }) do
		newPart(parent, Vector3.new(2.5, 2.5, 0.3), cf * CFrame.new(x, h * 0.6, -d / 2 - 0.15), rgb(255, 220, 140), Enum.Material.Neon)
	end
	-- Roof: a square prism turned 45 degrees, half sunk into the walls
	local r = d / math.sqrt(2) + 0.6
	newPart(parent, Vector3.new(w + 1.5, r, r), cf * CFrame.new(0, h, 0) * CFrame.Angles(math.rad(45), 0, 0), style.Roof, Enum.Material.Slate)
end

local function lamp(parent, pos)
	newPart(parent, Vector3.new(0.8, 10, 0.8), CFrame.new(pos + Vector3.new(0, 5, 0)), rgb(50, 45, 40), Enum.Material.Metal)
	local lantern = newPart(parent, Vector3.new(1.6, 1.6, 1.6), CFrame.new(pos + Vector3.new(0, 10.6, 0)), rgb(255, 210, 130), Enum.Material.Neon)
	local light = Instance.new("PointLight")
	light.Color = rgb(255, 210, 140)
	light.Range = 26
	light.Brightness = 1.4
	light.Parent = lantern
end

local function buildTown(tileFolder, townsFolder, world, name, pos, rng, isStart)
	local model = Instance.new("Model")
	model.Name = name
	model.Parent = tileFolder
	local style = HOUSE[world.Biome] or HOUSE.Meadow

	local plaza = newPart(model, Vector3.new(76, 0.6, 76), CFrame.new(pos + Vector3.new(0, 0.3, 0)), world.GroundColor:Lerp(rgb(150, 150, 150), 0.6), Enum.Material.Cobblestone)
	plaza.Name = "Plaza"

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = name
	spawn.Anchored = true
	spawn.Size = Vector3.new(10, 1, 10)
	spawn.CFrame = CFrame.new(pos + Vector3.new(0, 0.9, 0))
	spawn.Color = rgb(255, 215, 90)
	spawn.Material = Enum.Material.SmoothPlastic
	spawn.TopSurface = Enum.SurfaceType.Smooth
	spawn.Neutral = true
	spawn.AllowTeamChangeOnTouch = false
	spawn.Duration = 3
	spawn:SetAttribute("TownName", name)
	spawn:SetAttribute("WorldId", world.Id)
	spawn.Parent = townsFolder

	-- Houses sit between the 8 compass directions so roads never hit them
	local count = isStart and 8 or 6
	local skip = {}
	if not isStart then
		skip[rng:NextInteger(1, 8)] = true
		skip[rng:NextInteger(1, 8)] = true
	end
	local built = 0
	for i = 1, 8 do
		if not skip[i] and built < count then
			built += 1
			local angle = (i - 0.5) / 8 * math.pi * 2
			local hp = pos + Vector3.new(math.cos(angle) * 54, 0, math.sin(angle) * 54)
			house(model, CFrame.lookAt(hp, Vector3.new(pos.X, 0, pos.Z)), style, rng)
		end
	end
	for _, o in ipairs({ Vector3.new(34, 0, 34), Vector3.new(-34, 0, 34), Vector3.new(34, 0, -34), Vector3.new(-34, 0, -34) }) do
		lamp(model, pos + o)
	end

	billboard(model, pos + Vector3.new(0, 16, 0), name, isStart and "Starting village - respawn point" or "Town - respawn point", rgb(255, 215, 90), 260)
end

local function buildEntrance(tileFolder, entranceFolder, def, pos, hub)
	local th = def.Theme
	local model = Instance.new("Model")
	model.Name = def.Id .. "_Entrance"
	model.Parent = tileFolder

	local dir = flat(hub - pos)
	dir = dir.Magnitude > 1 and dir.Unit or Vector3.new(0, 0, 1)
	local base = CFrame.lookAt(pos, pos + dir) -- front (-Z) faces the hub town

	newPart(model, Vector3.new(30, 1, 26), base * CFrame.new(0, 0.5, -2), th.Wall, Enum.Material.Cobblestone)
	newPart(model, Vector3.new(38, 26, 22), base * CFrame.new(0, 13, 14), darken(th.Wall, 0.25), Enum.Material.Rock)
	for _, x in ipairs({ -8, 8 }) do
		newPart(model, Vector3.new(4, 18, 4), base * CFrame.new(x, 9, 2), th.Wall, th.Material == Enum.Material.Ice and Enum.Material.Glass or th.Material)
	end
	newPart(model, Vector3.new(22, 4, 5), base * CFrame.new(0, 20, 2), th.Wall, Enum.Material.Slate)

	local portal = newPart(entranceFolder, Vector3.new(12, 16, 1), base * CFrame.new(0, 9, 3), th.Light, Enum.Material.Neon)
	portal.Name = def.Id
	portal.Transparency = 0.15
	portal:SetAttribute("DungeonId", def.Id)
	local light = Instance.new("PointLight")
	light.Color = th.Light
	light.Range = 30
	light.Brightness = 2
	light.Parent = portal
end

local function signpost(parent, pos, neighbour)
	newPart(parent, Vector3.new(0.8, 8, 0.8), CFrame.new(pos + Vector3.new(0, 4, 0)), BARK, Enum.Material.Wood)
	newPart(parent, Vector3.new(6, 2.4, 0.4), CFrame.new(pos + Vector3.new(0, 7, 0)), rgb(150, 110, 70), Enum.Material.WoodPlanks)
	billboard(
		parent,
		pos + Vector3.new(0, 11, 0),
		"> " .. neighbour.Name,
		("Area level %d - %d"):format(neighbour.LevelRange[1], neighbour.LevelRange[2]),
		rgb(255, 255, 255),
		180
	)
end

local function road(parent, a, b, color)
	local mid = (a + b) / 2
	local len = flat(b - a).Magnitude
	if len < 1 then
		return
	end
	local p = deco(parent, Vector3.new(12, 0.2, len + 12), CFrame.lookAt(mid, Vector3.new(b.X, mid.Y, b.Z)) + Vector3.new(0, 0.1, 0), color, Enum.Material.Ground, false)
	p.Name = "Road"
end

local function cliffs(parent, rng, center, dir, world)
	local outward = Vector3.new(dir.X, 0, dir.Y)
	local along = Vector3.new(-dir.Y, 0, dir.X)
	local color = world.Biome == "Snow" and rgb(215, 222, 235)
		or world.Biome == "Celestial" and rgb(235, 232, 250)
		or darken(world.GroundColor, 0.35)
	local segment = 120
	for k = 0, 8 do
		local h = 90 + rng:NextNumber() * 60
		local thick = 40 + rng:NextNumber() * 16
		local offset = -HALF - 40 + segment / 2 + k * segment
		local pos = center + outward * (HALF + thick / 2) + along * offset + Vector3.new(0, h / 2 - 4, 0)
		local size = dir.X ~= 0 and Vector3.new(thick, h, segment) or Vector3.new(segment, h, thick)
		local p = newPart(parent, size, CFrame.new(pos), color, Enum.Material.Rock)
		p.Name = "Cliff"
	end
end

local function spawnPoint(folder, entry, pos, maxAlive, radius, respawn)
	local p = Instance.new("Part")
	p.Name = entry.Id .. "_Spawn"
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.Transparency = 1
	p.Size = Vector3.new(4, 1, 4)
	p.CFrame = CFrame.new(pos + Vector3.new(0, 1, 0))
	p:SetAttribute("MonsterId", entry.Id)
	p:SetAttribute("MinLevel", entry.MinLevel)
	p:SetAttribute("MaxLevel", entry.MaxLevel)
	p:SetAttribute("MaxAlive", maxAlive)
	p:SetAttribute("Radius", radius)
	p:SetAttribute("RespawnTime", respawn)
	p.Parent = folder
end

local function findSpot(rng, center, hub, rMin, rMax, avoid)
	local candidate = hub + Vector3.new(rMin, 0, 0)
	for _ = 1, 40 do
		local angle = rng:NextNumber() * math.pi * 2
		local r = rMin + rng:NextNumber() * (rMax - rMin)
		candidate = hub + Vector3.new(math.cos(angle) * r, 0, math.sin(angle) * r)
		local rel = candidate - center
		if math.abs(rel.X) <= EDGE - 20 and math.abs(rel.Z) <= EDGE - 20 and not blocked(candidate, avoid, {}, 40) then
			return candidate
		end
	end
	local rel = candidate - center
	return center + Vector3.new(math.clamp(rel.X, -EDGE, EDGE), 0, math.clamp(rel.Z, -EDGE, EDGE))
end

local function gridKey(x, z)
	return x .. "," .. z
end

local function buildTile(world, byGrid, folders)
	local center = Vector3.new(world.Grid.X * T, 0, world.Grid.Y * T)
	local rng = Random.new(world.Order * 7919)
	local tile = newFolder(world.Id, folders.Map)

	local ground = newPart(tile, Vector3.new(T, 4, T), CFrame.new(center - Vector3.new(0, 2, 0)), world.GroundColor, world.GroundMaterial)
	ground.Name = "Ground"

	local zone = newPart(folders.Zones, Vector3.new(T, 600, T), CFrame.new(center + Vector3.new(0, 200, 0)), Color3.new(1, 1, 1))
	zone.Name = world.Id
	zone.Transparency = 1
	zone.CanCollide = false
	zone.CanQuery = false
	zone.CanTouch = false
	zone:SetAttribute("WorldId", world.Id)

	local avoid = {}
	local roads = {}

	-- Towns
	local townPositions = {}
	for i, townName in ipairs(world.Towns) do
		local slot = TOWN_SLOTS[i] or Vector3.new(rng:NextInteger(-300, 300), 0, rng:NextInteger(-300, 300))
		local pos = center + slot
		buildTown(tile, folders.Towns, world, townName, pos, rng, townName == GameConfig.StartingTown)
		table.insert(townPositions, pos)
		table.insert(avoid, { Pos = pos, Radius = 80 })
	end
	local hub = townPositions[1] or center
	for i = 2, #townPositions do
		table.insert(roads, { hub, townPositions[i] })
	end

	-- Dungeon entrances
	local entrancePos = {}
	local slotIndex = 0
	for _, dungeonId in ipairs(world.Dungeons) do
		local def = Dungeons.Get(dungeonId)
		if def then
			local offset
			if def.Secret then
				offset = SECRET_SLOT
			else
				slotIndex += 1
				offset = DUNGEON_SLOTS[slotIndex] or Vector3.new(0, 0, -300)
			end
			local pos = center + offset
			buildEntrance(tile, folders.Entrances, def, pos, hub)
			entrancePos[dungeonId] = pos
			table.insert(avoid, { Pos = pos, Radius = 40 })
			if not def.Secret then
				table.insert(roads, { hub, pos }) -- secret dungeons have no road
			end
		end
	end

	-- Exits to neighbouring areas, or cliffs where the world ends
	for _, dir in ipairs(DIRS) do
		local neighbour = byGrid[gridKey(world.Grid.X + dir.X, world.Grid.Y + dir.Y)]
		local outward = Vector3.new(dir.X, 0, dir.Y)
		if neighbour then
			local edge = center + outward * HALF
			table.insert(roads, { hub, edge })
			local side = Vector3.new(-dir.Y, 0, dir.X)
			signpost(tile, edge - outward * 40 + side * 14, neighbour)
			table.insert(avoid, { Pos = edge - outward * 40 + side * 14, Radius = 6 })
		else
			cliffs(tile, rng, center, dir, world)
		end
	end

	local roadColor = darken(world.GroundColor, 0.3):Lerp(rgb(120, 100, 80), 0.4)
	for _, r in ipairs(roads) do
		road(tile, r[1], r[2], roadColor)
	end

	-- Monster spawn points: earlier entries sit closer to the hub town
	local normal = {}
	for _, m in ipairs(world.Monsters) do
		if not m.NearDungeon then
			table.insert(normal, m)
		end
	end
	local band = 300 / math.max(1, #normal)
	for i, m in ipairs(normal) do
		local rMin = 140 + (i - 1) * band
		for _ = 1, m.Spawns do
			local pos = findSpot(rng, center, hub, rMin, rMin + band, avoid)
			spawnPoint(folders.Spawns, m, pos, 3, 28, 20)
			table.insert(avoid, { Pos = pos, Radius = 10 })
		end
	end
	for _, m in ipairs(world.Monsters) do
		local ep = m.NearDungeon and entrancePos[m.NearDungeon]
		if ep then
			local toward = flat(center - ep).Unit
			for k = 1, m.Spawns do
				spawnPoint(folders.Spawns, m, ep + toward * (50 + k * 12), 1, 10, 60)
			end
		end
	end

	decorate(newFolder("Scenery", tile), rng, world, center, avoid, roads)
end

function Builder.BuildWorld()
	local folders = {
		Map = newFolder("Map", workspace),
		Zones = newFolder("WorldZones", workspace),
		Towns = newFolder("Towns", workspace),
		Entrances = newFolder("DungeonEntrances", workspace),
		Spawns = newFolder("MonsterSpawns", workspace),
	}
	local byGrid = {}
	for _, world in ipairs(Worlds.List) do
		byGrid[gridKey(world.Grid.X, world.Grid.Y)] = world
	end
	for _, world in ipairs(Worlds.List) do
		local ok, err = pcall(buildTile, world, byGrid, folders)
		if not ok then
			warn("[Greybox] Failed to build " .. world.Id .. ": " .. tostring(err))
		end
		task.wait() -- spread the work over a few frames
	end
	print("[Greybox] World built")
end

---------------------------------------------------------------------------
-- Dungeon arenas
---------------------------------------------------------------------------

--[[
	Straight run of rooms heading -Z from `origin` (floor height = origin.Y):
	entrance hall -> def.Rooms monster rooms -> boss room, joined by corridors.
]]
function Builder.BuildDungeonArena(def, origin)
	local th = def.Theme
	local model = Instance.new("Model")
	local WALL_H, DOOR, CORRIDOR = 34, 18, 34
	local wallMat = th.Material
	local floorMat = th.Material == Enum.Material.Ice and Enum.Material.Concrete or th.Material -- ice is too slippery to fight on
	local cursor = 0
	local rooms = {}

	local function addRoom(kind, w, d)
		local room = { Kind = kind, Center = Vector3.new(origin.X, origin.Y, origin.Z - cursor - d / 2), W = w, D = d }
		table.insert(rooms, room)
		cursor += d
		return room
	end

	local function addCorridor()
		local c = Vector3.new(origin.X, origin.Y, origin.Z - cursor - CORRIDOR / 2)
		newPart(model, Vector3.new(DOOR + 8, 2, CORRIDOR + 2), CFrame.new(c - Vector3.new(0, 1, 0)), th.Floor, floorMat)
		for _, s in ipairs({ -1, 1 }) do
			newPart(model, Vector3.new(4, WALL_H, CORRIDOR), CFrame.new(c + Vector3.new(s * (DOOR / 2 + 2), WALL_H / 2, 0)), th.Wall, wallMat)
		end
		cursor += CORRIDOR
	end

	local function wallAcross(center, width, door)
		local total = width + 8
		if door then
			local seg = (total - DOOR) / 2
			for _, s in ipairs({ -1, 1 }) do
				newPart(model, Vector3.new(seg, WALL_H, 4), CFrame.new(center + Vector3.new(s * (DOOR / 2 + seg / 2), WALL_H / 2, 0)), th.Wall, wallMat)
			end
		else
			newPart(model, Vector3.new(total, WALL_H, 4), CFrame.new(center + Vector3.new(0, WALL_H / 2, 0)), th.Wall, wallMat)
		end
	end

	local function torch(pos)
		newPart(model, Vector3.new(1, 3, 1), CFrame.new(pos), rgb(60, 45, 35), Enum.Material.Wood)
		local flame = newPart(model, Vector3.new(1.2, 1.2, 1.2), CFrame.new(pos + Vector3.new(0, 2, 0)), th.Light, Enum.Material.Neon)
		flame.CanCollide = false
		local light = Instance.new("PointLight")
		light.Color = th.Light
		light.Range = 32
		light.Brightness = 1.6
		light.Parent = flame
	end

	local hall = addRoom("Hall", 64, 64)
	local mobRooms = {}
	for _ = 1, def.Rooms do
		addCorridor()
		table.insert(mobRooms, addRoom("Mob", 96, 96))
	end
	addCorridor()
	local boss = addRoom("Boss", 150, 150)

	for i, room in ipairs(rooms) do
		local c = room.Center
		newPart(model, Vector3.new(room.W, 2, room.D), CFrame.new(c - Vector3.new(0, 1, 0)), th.Floor, floorMat)
		for _, s in ipairs({ -1, 1 }) do
			newPart(model, Vector3.new(4, WALL_H, room.D + 8), CFrame.new(c + Vector3.new(s * (room.W / 2 + 2), WALL_H / 2, 0)), th.Wall, wallMat)
			for _, dz in ipairs({ -room.D / 4, room.D / 4 }) do
				torch(c + Vector3.new(s * (room.W / 2 - 1), 10, dz))
			end
		end
		wallAcross(c + Vector3.new(0, 0, room.D / 2 + 2), room.W, i > 1)
		wallAcross(c - Vector3.new(0, 0, room.D / 2 + 2), room.W, i < #rooms)
	end

	-- Boss room pillars
	local bc = boss.Center
	for _, sx in ipairs({ -1, 1 }) do
		for _, sz in ipairs({ -1, 1 }) do
			newPart(model, Vector3.new(8, WALL_H, 8), CFrame.new(bc + Vector3.new(sx * (boss.W / 2 - 16), WALL_H / 2, sz * (boss.D / 2 - 16))), darken(th.Wall, 0.15), wallMat)
		end
	end

	local mobs = {}
	for _, room in ipairs(mobRooms) do
		local n = def.MobsPerRoom
		for k = 1, n do
			local angle = (k / n) * math.pi * 2
			local p = room.Center + Vector3.new(math.cos(angle) * 22, 10, math.sin(angle) * 22)
			table.insert(mobs, CFrame.lookAt(p, p + Vector3.new(0, 0, 1)))
		end
	end

	local hc = hall.Center
	local bossPos = bc + Vector3.new(0, 14, -25)
	local exitPos = bc + Vector3.new(0, 3, -(boss.D / 2 - 14))
	return {
		Model = model,
		StartCFrame = CFrame.lookAt(hc + Vector3.new(0, 4, 8), hc + Vector3.new(0, 4, -50)),
		RetreatCFrame = CFrame.lookAt(hc + Vector3.new(0, 3, 24), hc + Vector3.new(0, 3, 0)),
		MobCFrames = mobs,
		BossCFrame = CFrame.lookAt(bossPos, bossPos + Vector3.new(0, 0, 1)),
		ExitCFrame = CFrame.lookAt(exitPos, bc + Vector3.new(0, 3, 0)),
	}
end

return Builder
