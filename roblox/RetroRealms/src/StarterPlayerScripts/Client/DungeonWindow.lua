--[[
	DungeonWindow
	The "are you sure?" window shown at a dungeon entrance. Nothing is
	level-locked - this window only warns you how dangerous it is.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Progression = require(Shared:WaitForChild("Progression"))
local Dungeons = require(Shared:WaitForChild("Dungeons"))
local GameConfig = require(Shared:WaitForChild("GameConfig"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local UI = require(script.Parent.UI)
local State = require(script.Parent.State)

local player = Players.LocalPlayer

local DungeonWindow = {}

local refs = {}
local currentId

local function close()
	refs.Frame.Visible = false
	currentId = nil
end

local function open(dungeonId)
	local def = Dungeons.Get(dungeonId)
	if not def or State.InDungeon() then
		return
	end
	currentId = dungeonId
	local level = State.Level()
	local d = Progression.GetDifficulty(def.RecommendedLevel, level)
	local clears = State.Profile.DungeonClears[def.Id] or 0

	refs.Title.Text = def.Name
	refs.Desc.Text = def.Description
	refs.Levels.Text = ("RECOMMENDED LV %d      YOUR LV %d"):format(def.RecommendedLevel, level)
	refs.Rating.Text = string.upper(d.Name)
	refs.Rating.TextColor3 = d.Color
	refs.Warning.Text = d.Warning
	refs.Warning.TextColor3 = d.Color
	refs.Extra.Text = ("Party up: friends who enter within %ds join your run (max %d).   Cleared: %d"):format(
		GameConfig.Dungeon.JoinWindowSeconds,
		GameConfig.Dungeon.MaxPartySize,
		clears
	)
	local scary = d.Name == "Deadly" or d.Name == "Suicidal"
	refs.Enter.Text = scary and "ENTER ANYWAY" or "ENTER"
	refs.Enter.BackgroundColor3 = scary and Color3.fromRGB(130, 35, 35) or Color3.fromRGB(50, 110, 60)
	refs.Frame.Visible = true
end

function DungeonWindow.Init()
	local frame = UI.panel(UI.Root, {
		Name = "DungeonWindow",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(460, 300),
		Visible = false,
		ZIndex = 5,
	})
	UI.padding(frame, 14)
	refs.Frame = frame

	refs.Title = UI.label(frame, { Font = UI.TitleFont, TextSize = 28, TextColor3 = UI.Colors.Gold, TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.new(1, 0, 0, 32) })
	refs.Desc = UI.label(frame, { TextWrapped = true, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.fromOffset(0, 38), Size = UDim2.new(1, 0, 0, 40), TextColor3 = UI.Colors.Muted })
	refs.Levels = UI.label(frame, { Font = UI.TitleFont, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.fromOffset(0, 86), Size = UDim2.new(1, 0, 0, 20) })
	refs.Rating = UI.label(frame, { Font = UI.TitleFont, TextSize = 34, TextStrokeTransparency = 0, TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.fromOffset(0, 112), Size = UDim2.new(1, 0, 0, 38) })
	refs.Warning = UI.label(frame, { TextWrapped = true, TextSize = 15, TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.fromOffset(0, 152), Size = UDim2.new(1, 0, 0, 36) })
	refs.Extra = UI.label(frame, { TextWrapped = true, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.fromOffset(0, 190), Size = UDim2.new(1, 0, 0, 30), TextColor3 = UI.Colors.Muted })

	refs.Enter = UI.button(frame, "ENTER", { AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(0.5, -8, 1, 0), Size = UDim2.fromOffset(170, 40) }, function()
		if currentId then
			Remotes.EnterDungeon:FireServer(currentId)
		end
		close()
	end)
	UI.button(frame, "CANCEL", { AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0.5, 8, 1, 0), Size = UDim2.fromOffset(170, 40) }, close)

	Remotes:WaitForChild("DungeonPrompt").OnClientEvent:Connect(open)
	player:GetAttributeChangedSignal("InDungeon"):Connect(close)
	player.CharacterAdded:Connect(close)
end

return DungeonWindow
