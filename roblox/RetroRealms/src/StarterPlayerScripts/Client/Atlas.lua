--[[
	Atlas
	The world map window (press M). Shows a little tile map of the world,
	every area's level range, its towns (with fast travel once discovered)
	and its dungeons with difficulty ratings and clear counts.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Progression = require(Shared:WaitForChild("Progression"))
local Worlds = require(Shared:WaitForChild("Worlds"))
local Dungeons = require(Shared:WaitForChild("Dungeons"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local UI = require(script.Parent.UI)
local State = require(script.Parent.State)

local player = Players.LocalPlayer
local C = UI.Colors

local Atlas = {}

local refs = {}
local isOpen = false

local CELL = 46

local function clear(container)
	for _, child in ipairs(container:GetChildren()) do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end

local function buildGrid()
	local grid = refs.Grid
	clear(grid)
	local profile = State.Profile
	local currentWorld = State.ZoneKind == "World" and State.ZoneId or player:GetAttribute("WorldId")
	for _, world in ipairs(Worlds.List) do
		local found = profile.Discovered[world.Id] == true
		local cell = UI.make("Frame", {
			BackgroundColor3 = found and world.GroundColor or Color3.fromRGB(40, 36, 52),
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(world.Grid.X * (CELL + 4), world.Grid.Y * (CELL + 4)),
			Size = UDim2.fromOffset(CELL, CELL),
		}, grid)
		UI.stroke(cell, world.Id == currentWorld and Color3.new(1, 1, 1) or C.BorderDim, world.Id == currentWorld and 3 or 1)
		UI.label(cell, {
			Text = found and tostring(world.Order) or "?",
			Font = UI.TitleFont,
			TextSize = 20,
			TextStrokeTransparency = 0,
			TextXAlignment = Enum.TextXAlignment.Center,
			Size = UDim2.fromScale(1, 1),
		})
	end
end

local order = 0
local function row(height)
	order += 1
	return UI.make("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -8, 0, height),
		LayoutOrder = order,
	}, refs.List)
end

local function buildList()
	local list = refs.List
	clear(list)
	order = 0
	local profile = State.Profile
	local level = State.Level()
	local inDungeon = State.InDungeon()

	for _, world in ipairs(Worlds.List) do
		local found = profile.Discovered[world.Id] == true
		local d = Progression.GetDifficulty(world.LevelRange[1], level)

		local header = row(28)
		header.BackgroundTransparency = 0
		header.BackgroundColor3 = C.PanelAlt
		header.BorderSizePixel = 0
		UI.label(header, {
			Text = ("%d. %s"):format(world.Order, world.Name),
			Font = UI.TitleFont,
			TextSize = 18,
			TextColor3 = found and C.Text or C.Muted,
			Position = UDim2.fromOffset(6, 0),
			Size = UDim2.new(0.6, 0, 1, 0),
		})
		UI.label(header, {
			Text = ("LV %d-%d%s"):format(world.LevelRange[1], world.LevelRange[2], found and "" or "  (unexplored)"),
			Font = UI.TitleFont,
			TextSize = 14,
			TextColor3 = d.Color,
			TextXAlignment = Enum.TextXAlignment.Right,
			Position = UDim2.new(0.4, -6, 0, 0),
			Size = UDim2.new(0.6, 0, 1, 0),
		})

		for _, townName in ipairs(world.Towns) do
			local r = row(26)
			local known = profile.DiscoveredTowns[townName] == true
			local home = profile.RespawnTown == townName
			UI.label(r, {
				Text = ("   Town: %s%s"):format(known and townName or "???", home and "  (respawn)" or ""),
				TextColor3 = known and C.Text or C.Muted,
				Size = UDim2.new(0.7, 0, 1, 0),
			})
			if known and not inDungeon then
				UI.button(r, "TRAVEL", {
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -4, 0.5, 0),
					Size = UDim2.fromOffset(90, 22),
					TextSize = 13,
				}, function()
					Remotes.TravelToTown:FireServer(townName)
					Atlas.Close()
				end)
			end
		end

		for _, dungeonId in ipairs(world.Dungeons) do
			local def = Dungeons.Get(dungeonId)
			if def then
				local r = row(24)
				local hidden = def.Secret and not found
				local clears = profile.DungeonClears[def.Id] or 0
				local dd = Progression.GetDifficulty(def.RecommendedLevel, level)
				UI.label(r, {
					Text = hidden and "   Dungeon: ??? (secret)" or ("   Dungeon: %s%s"):format(def.Name, def.Secret and " (secret)" or ""),
					TextColor3 = hidden and C.Muted or C.Text,
					Size = UDim2.new(0.62, 0, 1, 0),
					TextTruncate = Enum.TextTruncate.AtEnd,
				})
				UI.label(r, {
					Text = hidden and "LV ???" or ("LV %d %s%s"):format(def.RecommendedLevel, string.upper(dd.Name), clears > 0 and (" x" .. clears) or ""),
					Font = UI.TitleFont,
					TextSize = 13,
					TextColor3 = hidden and C.Muted or dd.Color,
					TextXAlignment = Enum.TextXAlignment.Right,
					Position = UDim2.new(0.62, 0, 0, 0),
					Size = UDim2.new(0.38, -6, 1, 0),
				})
			end
		end
	end
end

local function refresh()
	if isOpen then
		buildGrid()
		buildList()
	end
end

function Atlas.Open()
	isOpen = true
	refs.Frame.Visible = true
	refresh()
end

function Atlas.Close()
	isOpen = false
	refs.Frame.Visible = false
end

function Atlas.Toggle()
	if isOpen then
		Atlas.Close()
	else
		Atlas.Open()
	end
end

function Atlas.Init()
	local frame = UI.panel(UI.Root, {
		Name = "Atlas",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(720, 500),
		Visible = false,
		ZIndex = 4,
	})
	UI.padding(frame, 12)
	refs.Frame = frame

	UI.label(frame, { Text = "WORLD ATLAS", Font = UI.TitleFont, TextSize = 28, TextColor3 = C.Gold, Size = UDim2.new(1, 0, 0, 30) })
	UI.button(frame, "X", { AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Size = UDim2.fromOffset(32, 30) }, Atlas.Close)

	refs.Grid = UI.make("Frame", {
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(4, 44),
		Size = UDim2.fromOffset(3 * (CELL + 4), 4 * (CELL + 4)),
	}, frame)
	UI.label(frame, {
		Text = "Nothing is locked.\nColours show how\ndangerous an area\nis for your level.",
		TextSize = 13,
		TextWrapped = true,
		TextColor3 = C.Muted,
		TextYAlignment = Enum.TextYAlignment.Top,
		Position = UDim2.fromOffset(4, 44 + 4 * (CELL + 4) + 8),
		Size = UDim2.fromOffset(160, 90),
	})

	refs.List = UI.make("ScrollingFrame", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(170, 44),
		Size = UDim2.new(1, -170, 1, -44),
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 8,
		ScrollBarImageColor3 = C.Border,
	}, frame)
	UI.make("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, refs.List)

	State.ProfileChanged:Connect(refresh)
	State.ZoneChanged:Connect(refresh)
	player:GetAttributeChangedSignal("Level"):Connect(refresh)
	player:GetAttributeChangedSignal("InDungeon"):Connect(refresh)
end

return Atlas
