--[[
	Effects
	Floating damage numbers, XP/gold popups, boss slam warning rings and the
	sword swing flash. Everything here is client-only and cleans itself up.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))

local UI = require(script.Parent.UI)

local Effects = {}

local fxFolder

local function floatText(position, text, color, size, duration)
	local att = Instance.new("Attachment")
	att.WorldPosition = position + Vector3.new(math.random() * 2 - 1, 0, math.random() * 2 - 1)
	att.Parent = workspace.Terrain

	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(220, size + 8)
	gui.AlwaysOnTop = true
	gui.LightInfluence = 0
	gui.MaxDistance = 160
	gui.Adornee = att
	gui.Parent = att

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = UI.TitleFont
	label.TextSize = size
	label.Text = text
	label.TextColor3 = color
	label.TextStrokeTransparency = 0
	label.Parent = gui

	UI.tween(gui, duration, { StudsOffset = Vector3.new(0, 4, 0) })
	task.delay(duration * 0.5, function()
		UI.tween(label, duration * 0.5, { TextTransparency = 1, TextStrokeTransparency = 1 })
	end)
	Debris:AddItem(att, duration + 0.1)
end

local function onDamageNumber(position, amount, isCrit, isPlayerHurt)
	if typeof(position) ~= "Vector3" then
		return
	end
	local text = UI.short(amount)
	local color = Color3.fromRGB(255, 255, 255)
	local size = 22
	if isPlayerHurt then
		color = Color3.fromRGB(255, 80, 80)
		text = "-" .. text
	elseif isCrit then
		color = Color3.fromRGB(255, 200, 40)
		size = 30
		text = text .. "!"
	end
	floatText(position, text, color, size, 0.9)
end

local function onReward(position, xp, gold)
	if typeof(position) ~= "Vector3" then
		return
	end
	floatText(position + Vector3.new(0, 2, 0), "+" .. UI.short(xp) .. " XP", UI.Colors.XP, 20, 1.4)
	task.delay(0.15, function()
		floatText(position, "+" .. UI.short(gold) .. " G", UI.Colors.Gold, 18, 1.4)
	end)
end

local function flatDisc(position, radius, color, transparency)
	local p = Instance.new("Part")
	p.Shape = Enum.PartType.Cylinder
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Material = Enum.Material.Neon
	p.Color = color
	p.Transparency = transparency
	p.Size = Vector3.new(0.3, radius * 2, radius * 2)
	p.CFrame = CFrame.new(position + Vector3.new(0, 0.3, 0)) * CFrame.Angles(0, 0, math.pi / 2)
	p.Parent = fxFolder
	return p
end

local function onBossSlam(position, radius, delayTime)
	if typeof(position) ~= "Vector3" then
		return
	end
	local ring = flatDisc(position, radius, Color3.fromRGB(255, 40, 40), 0.7)
	local fill = flatDisc(position, 0.5, Color3.fromRGB(255, 120, 60), 0.4)
	UI.tween(fill, delayTime, { Size = Vector3.new(0.35, radius * 2, radius * 2) }, Enum.EasingStyle.Linear)
	task.delay(delayTime, function()
		ring.Color = Color3.fromRGB(255, 255, 255)
		ring.Transparency = 0.2
		fill:Destroy()
		UI.tween(ring, 0.35, { Transparency = 1 })
		Debris:AddItem(ring, 0.4)
	end)
end

-- Quick white arc in front of the character
function Effects.Swing(rootPart)
	local range = GameConfig.Combat.PlayerAttackRange
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Material = Enum.Material.Neon
	p.Color = Color3.fromRGB(255, 255, 255)
	p.Transparency = 0.55
	p.Size = Vector3.new(range * 1.3, 0.2, range * 0.8)
	p.CFrame = rootPart.CFrame * CFrame.new(0, 0, -range * 0.5) * CFrame.Angles(0, 0, math.rad(math.random(-20, 20)))
	p.Parent = fxFolder
	UI.tween(p, 0.18, { Transparency = 1 })
	Debris:AddItem(p, 0.2)
end

function Effects.Init()
	fxFolder = Instance.new("Folder")
	fxFolder.Name = "ClientEffects"
	fxFolder.Parent = workspace

	Remotes:WaitForChild("DamageNumber").OnClientEvent:Connect(onDamageNumber)
	Remotes:WaitForChild("Reward").OnClientEvent:Connect(onReward)
	Remotes:WaitForChild("BossSlam").OnClientEvent:Connect(onBossSlam)
end

return Effects
