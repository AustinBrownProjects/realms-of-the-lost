--[[
	Hud
	Level / HP / XP / gold panel, current area line, notification feed, the
	big area banner, Map + Leave Dungeon buttons and the boss health bar.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Progression = require(Shared:WaitForChild("Progression"))
local Worlds = require(Shared:WaitForChild("Worlds"))
local Dungeons = require(Shared:WaitForChild("Dungeons"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local UI = require(script.Parent.UI)
local State = require(script.Parent.State)

local player = Players.LocalPlayer
local C = UI.Colors

local Hud = {}

local refs = {}
local order = 0
local function nextOrder()
	order += 1
	return order
end

---------------------------------------------------------------------------
-- Notifications
---------------------------------------------------------------------------

function Hud.Notify(text, color)
	local feed = refs.Feed
	local label = UI.label(feed, {
		Text = text,
		TextColor3 = color or C.Text,
		Font = UI.TitleFont,
		TextSize = 18,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Center,
		TextStrokeTransparency = 0,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 22),
		LayoutOrder = nextOrder(),
	})
	-- Keep only the newest 5
	local labels = {}
	for _, child in ipairs(feed:GetChildren()) do
		if child:IsA("TextLabel") then
			table.insert(labels, child)
		end
	end
	table.sort(labels, function(a, b)
		return a.LayoutOrder < b.LayoutOrder
	end)
	for i = 1, #labels - 5 do
		labels[i]:Destroy()
	end
	task.delay(4.5, function()
		if label.Parent then
			UI.tween(label, 0.6, { TextTransparency = 1, TextStrokeTransparency = 1 })
			task.wait(0.6)
			label:Destroy()
		end
	end)
end

---------------------------------------------------------------------------
-- Banner
---------------------------------------------------------------------------

local bannerToken = 0
function Hud.Banner(title, subtitle, color)
	bannerToken += 1
	local token = bannerToken
	local b = refs.Banner
	b.Title.Text = title
	b.Title.TextColor3 = color or C.Gold
	b.Sub.Text = subtitle or ""
	b.Title.TextTransparency, b.Title.TextStrokeTransparency = 1, 1
	b.Sub.TextTransparency, b.Sub.TextStrokeTransparency = 1, 1
	b.Frame.Visible = true
	UI.tween(b.Title, 0.5, { TextTransparency = 0, TextStrokeTransparency = 0 })
	UI.tween(b.Sub, 0.5, { TextTransparency = 0, TextStrokeTransparency = 0.3 })
	task.delay(3.5, function()
		if token ~= bannerToken then
			return
		end
		UI.tween(b.Title, 0.8, { TextTransparency = 1, TextStrokeTransparency = 1 })
		UI.tween(b.Sub, 0.8, { TextTransparency = 1, TextStrokeTransparency = 1 })
	end)
end

---------------------------------------------------------------------------
-- Stats panel
---------------------------------------------------------------------------

local function updateStats()
	local level = State.Level()
	local xp = player:GetAttribute("XP") or 0
	local needed = player:GetAttribute("XPNeeded") or 1
	local gold = player:GetAttribute("Gold") or 0

	refs.Level.Text = "LV " .. level
	if needed <= 0 then
		UI.setBar(refs.XP, 1, "MAX LEVEL")
	else
		UI.setBar(refs.XP, xp / needed, ("XP %s / %s"):format(UI.short(xp), UI.short(needed)))
	end
	refs.Gold.Text = "GOLD " .. UI.comma(gold)
end

local healthConn
local function bindHumanoid(character)
	if healthConn then
		healthConn:Disconnect()
	end
	local humanoid = character:WaitForChild("Humanoid", 10)
	if not humanoid then
		return
	end
	local function update()
		UI.setBar(refs.HP, humanoid.Health / math.max(1, humanoid.MaxHealth), ("HP %s / %s"):format(UI.short(humanoid.Health), UI.short(humanoid.MaxHealth)))
	end
	healthConn = humanoid.HealthChanged:Connect(update)
	humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(update)
	update()
end

local function updateArea()
	local level = State.Level()
	if State.ZoneKind == "Dungeon" then
		local def = Dungeons.Get(State.ZoneId)
		if def then
			local d = Progression.GetDifficulty(def.RecommendedLevel, level)
			refs.Area.Text = ("%s  (Rec. LV %d - %s)"):format(def.Name, def.RecommendedLevel, d.Name)
			refs.Area.TextColor3 = d.Color
		end
	elseif State.ZoneKind == "World" then
		local world = Worlds.Get(State.ZoneId)
		if world then
			local d = Progression.GetDifficulty(world.LevelRange[1], level)
			refs.Area.Text = ("%s  (LV %d-%d)"):format(world.Name, world.LevelRange[1], world.LevelRange[2])
			refs.Area.TextColor3 = d.Color
		end
	end
	refs.Leave.Visible = State.InDungeon()
end

---------------------------------------------------------------------------
-- Boss bar
---------------------------------------------------------------------------

local function nearestBoss()
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return nil
	end
	local best, bestDist = nil, 170
	for _, model in ipairs(CollectionService:GetTagged("Monster")) do
		if model:GetAttribute("IsBoss") and model.PrimaryPart then
			local d = (model.PrimaryPart.Position - hrp.Position).Magnitude
			if d < bestDist then
				best, bestDist = model, d
			end
		end
	end
	return best
end

local function bossLoop()
	while true do
		task.wait(0.25)
		local boss = nearestBoss()
		local hum = boss and boss:FindFirstChildOfClass("Humanoid")
		if hum and hum.Health > 0 then
			local level = boss:GetAttribute("Level") or 1
			local d = Progression.GetDifficulty(level, State.Level())
			refs.BossName.Text = ("%s  LV %d"):format(boss:GetAttribute("DisplayName") or boss.Name, level)
			refs.BossName.TextColor3 = d.Color
			UI.setBar(refs.BossBar, hum.Health / math.max(1, hum.MaxHealth), ("%s / %s"):format(UI.short(hum.Health), UI.short(hum.MaxHealth)))
			refs.Boss.Visible = true
		else
			refs.Boss.Visible = false
		end
	end
end

---------------------------------------------------------------------------
-- Build
---------------------------------------------------------------------------

function Hud.Init(openAtlas)
	local root = UI.Root

	-- Stats panel (top left)
	local panel = UI.panel(root, { Name = "Stats", Size = UDim2.fromOffset(300, 112), Position = UDim2.fromOffset(12, 12) })
	UI.padding(panel, 8)
	UI.make("UIListLayout", { Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder }, panel)

	local top = UI.make("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 22), LayoutOrder = 1 }, panel)
	refs.Level = UI.label(top, { Font = UI.TitleFont, TextSize = 22, TextColor3 = C.Gold, Size = UDim2.new(0.4, 0, 1, 0), Text = "LV 1" })
	UI.label(top, {
		Text = player.DisplayName,
		TextXAlignment = Enum.TextXAlignment.Right,
		Size = UDim2.new(0.6, 0, 1, 0),
		Position = UDim2.fromScale(0.4, 0),
		TextColor3 = C.Muted,
		TextTruncate = Enum.TextTruncate.AtEnd,
	})
	refs.HP = UI.bar(panel, C.HP, { LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 18) })
	refs.XP = UI.bar(panel, C.XP, { LayoutOrder = 3, Size = UDim2.new(1, 0, 0, 14) })
	refs.Gold = UI.label(panel, { LayoutOrder = 4, TextColor3 = C.Gold, Text = "GOLD 0", Font = UI.TitleFont, TextSize = 16 })

	refs.Area = UI.label(root, {
		Position = UDim2.fromOffset(14, 132),
		Size = UDim2.fromOffset(500, 20),
		Font = UI.TitleFont,
		TextSize = 16,
		TextStrokeTransparency = 0,
		Text = "",
	})

	-- Buttons (top right)
	local buttons = UI.make("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 12),
		Size = UDim2.fromOffset(150, 80),
	}, root)
	UI.make("UIListLayout", { Padding = UDim.new(0, 8), HorizontalAlignment = Enum.HorizontalAlignment.Right }, buttons)
	UI.button(buttons, "MAP [M]", { Size = UDim2.fromOffset(130, 34) }, function()
		openAtlas()
	end)
	refs.Leave = UI.button(buttons, "LEAVE DUNGEON", { Size = UDim2.fromOffset(150, 34), BackgroundColor3 = Color3.fromRGB(110, 40, 40), Visible = false }, function()
		Remotes.LeaveDungeon:FireServer()
	end)

	-- Notification feed (top centre)
	refs.Feed = UI.make("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 12),
		Size = UDim2.fromOffset(520, 160),
	}, root)
	UI.make("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, refs.Feed)

	-- Area banner
	local bannerFrame = UI.make("Frame", {
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.3),
		Size = UDim2.fromOffset(700, 90),
		Visible = false,
	}, root)
	refs.Banner = {
		Frame = bannerFrame,
		Title = UI.label(bannerFrame, { Font = UI.TitleFont, TextSize = 44, TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.new(1, 0, 0, 52) }),
		Sub = UI.label(bannerFrame, { TextSize = 18, TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.fromOffset(0, 56), Size = UDim2.new(1, 0, 0, 24) }),
	}

	-- Boss bar (bottom centre)
	refs.Boss = UI.panel(root, {
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -24),
		Size = UDim2.fromOffset(520, 56),
		Visible = false,
	})
	UI.padding(refs.Boss, 6)
	refs.BossName = UI.label(refs.Boss, { Font = UI.TitleFont, TextSize = 18, TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.new(1, 0, 0, 20) })
	refs.BossBar = UI.bar(refs.Boss, Color3.fromRGB(190, 40, 60), { Position = UDim2.fromOffset(0, 24), Size = UDim2.new(1, 0, 0, 18) })

	-- Wiring
	for _, attr in ipairs({ "Level", "XP", "XPNeeded", "Gold" }) do
		player:GetAttributeChangedSignal(attr):Connect(updateStats)
	end
	player:GetAttributeChangedSignal("Level"):Connect(updateArea)
	player:GetAttributeChangedSignal("InDungeon"):Connect(updateArea)
	updateStats()

	if player.Character then
		task.spawn(bindHumanoid, player.Character)
	end
	player.CharacterAdded:Connect(bindHumanoid)

	Remotes:WaitForChild("Notify").OnClientEvent:Connect(Hud.Notify)
	State.ZoneChanged:Connect(updateArea)

	task.spawn(bossLoop)
end

return Hud
