--[[
	Nameplates
	Floating "LV 12 Goblin" labels with a health bar over every monster,
	coloured by how dangerous it is for YOUR level (like SAO cursors), plus
	signs over dungeon entrances showing the recommended level.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Progression = require(Shared:WaitForChild("Progression"))
local Dungeons = require(Shared:WaitForChild("Dungeons"))

local UI = require(script.Parent.UI)
local State = require(script.Parent.State)

local player = Players.LocalPlayer

local Nameplates = {}

local monsterPlates = {} -- [model] = { Gui, Name, Bar, Conns }
local entrancePlates = {} -- [part] = { Gui, Title, Info }

---------------------------------------------------------------------------
-- Monsters
---------------------------------------------------------------------------

local function refreshMonster(model, plate)
	local level = model:GetAttribute("Level") or 1
	local d = Progression.GetDifficulty(level, State.Level())
	plate.Name.Text = ("LV %d  %s"):format(level, model:GetAttribute("DisplayName") or model.Name)
	plate.Name.TextColor3 = d.Color
end

local function removeMonster(model)
	local plate = monsterPlates[model]
	if plate then
		monsterPlates[model] = nil
		for _, c in ipairs(plate.Conns) do
			c:Disconnect()
		end
		plate.Gui:Destroy()
	end
end

local function addMonster(model)
	if monsterPlates[model] or not model:IsA("Model") then
		return
	end
	local head = model:WaitForChild("Head", 5) or model.PrimaryPart
	local humanoid = model:WaitForChild("Humanoid", 5)
	if not head or not humanoid or not model.Parent then
		return
	end
	local isBoss = model:GetAttribute("IsBoss") == true

	local gui = Instance.new("BillboardGui")
	gui.Name = "Plate"
	gui.Adornee = head
	gui.Size = UDim2.fromOffset(isBoss and 240 or 170, isBoss and 44 or 34)
	gui.StudsOffset = Vector3.new(0, 2.2, 0)
	gui.MaxDistance = isBoss and 260 or 110
	gui.LightInfluence = 0
	gui.Parent = UI.Billboards

	local name = UI.label(gui, {
		Font = UI.TitleFont,
		TextSize = isBoss and 20 or 15,
		TextStrokeTransparency = 0,
		TextXAlignment = Enum.TextXAlignment.Center,
		Size = UDim2.new(1, 0, 0, isBoss and 22 or 18),
	})
	local bar = UI.bar(gui, Color3.fromRGB(220, 60, 60), {
		Position = UDim2.new(0.1, 0, 0, isBoss and 26 or 20),
		Size = UDim2.new(0.8, 0, 0, isBoss and 10 or 7),
	})
	bar.Text.Visible = false

	local plate = { Gui = gui, Name = name, Bar = bar, Conns = {} }
	monsterPlates[model] = plate

	local function updateHealth()
		UI.setBar(bar, humanoid.Health / math.max(1, humanoid.MaxHealth))
		if humanoid.Health <= 0 then
			gui.Enabled = false
		end
	end
	table.insert(plate.Conns, humanoid.HealthChanged:Connect(updateHealth))
	table.insert(plate.Conns, model.AncestryChanged:Connect(function()
		if not model:IsDescendantOf(workspace) then
			removeMonster(model)
		end
	end))
	refreshMonster(model, plate)
	updateHealth()
end

---------------------------------------------------------------------------
-- Dungeon entrances
---------------------------------------------------------------------------

local function refreshEntrance(part, plate)
	local def = Dungeons.Get(part:GetAttribute("DungeonId"))
	if not def then
		return
	end
	local d = Progression.GetDifficulty(def.RecommendedLevel, State.Level())
	local clears = State.Profile.DungeonClears[def.Id] or 0
	plate.Title.Text = def.Name
	plate.Info.Text = ("REC. LV %d  -  %s%s"):format(def.RecommendedLevel, string.upper(d.Name), clears > 0 and ("  -  CLEARED x" .. clears) or "")
	plate.Info.TextColor3 = d.Color
end

local function addEntrance(part)
	if entrancePlates[part] or not part:IsA("BasePart") then
		return
	end
	local gui = Instance.new("BillboardGui")
	gui.Adornee = part
	gui.Size = UDim2.fromOffset(340, 56)
	gui.StudsOffset = Vector3.new(0, part.Size.Y / 2 + 9, 0)
	gui.MaxDistance = 320
	gui.LightInfluence = 0
	gui.Parent = UI.Billboards

	local plate = {
		Gui = gui,
		Title = UI.label(gui, { Font = UI.TitleFont, TextSize = 24, TextColor3 = UI.Colors.Gold, TextStrokeTransparency = 0, TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.new(1, 0, 0, 28) }),
		Info = UI.label(gui, { Font = UI.TitleFont, TextSize = 16, TextStrokeTransparency = 0, TextXAlignment = Enum.TextXAlignment.Center, Position = UDim2.fromOffset(0, 30), Size = UDim2.new(1, 0, 0, 20) }),
	}
	entrancePlates[part] = plate
	refreshEntrance(part, plate)
end

---------------------------------------------------------------------------

local function refreshAll()
	for model, plate in pairs(monsterPlates) do
		refreshMonster(model, plate)
	end
	for part, plate in pairs(entrancePlates) do
		refreshEntrance(part, plate)
	end
end

function Nameplates.Init()
	CollectionService:GetInstanceAddedSignal("Monster"):Connect(function(m)
		task.spawn(addMonster, m)
	end)
	CollectionService:GetInstanceRemovedSignal("Monster"):Connect(removeMonster)
	for _, m in ipairs(CollectionService:GetTagged("Monster")) do
		task.spawn(addMonster, m)
	end

	CollectionService:GetInstanceAddedSignal("DungeonEntrance"):Connect(addEntrance)
	for _, p in ipairs(CollectionService:GetTagged("DungeonEntrance")) do
		addEntrance(p)
	end

	player:GetAttributeChangedSignal("Level"):Connect(refreshAll)
	State.ProfileChanged:Connect(refreshAll)
end

return Nameplates
