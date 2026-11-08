--[[
	CombatInput
	Swinging the sword. Clicking / tapping while the Sword tool is held plays
	the classic slash animation, shows a swing flash and asks the server to
	hit whatever is in front of you. The server does all the real checks.
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))

local Effects = require(script.Parent.Effects)

local player = Players.LocalPlayer

local CombatInput = {}

local hooked = setmetatable({}, { __mode = "k" })
local lastSwing = 0

local function swing(tool)
	local now = os.clock()
	if now - lastSwing < GameConfig.Combat.PlayerAttackCooldown then
		return
	end
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hrp or not hum or hum.Health <= 0 then
		return
	end
	lastSwing = now

	-- The default Animate script plays its slash animation when it sees this
	local anim = Instance.new("StringValue")
	anim.Name = "toolanim"
	anim.Value = "Slash"
	anim.Parent = tool

	Effects.Swing(hrp)
	Remotes.Attack:FireServer(hrp.CFrame.LookVector)
end

local function hook(tool)
	if not tool:IsA("Tool") or tool.Name ~= "Sword" or hooked[tool] then
		return
	end
	hooked[tool] = true
	tool.Activated:Connect(function()
		swing(tool)
	end)
end

local function watch(container)
	for _, child in ipairs(container:GetChildren()) do
		hook(child)
	end
	container.ChildAdded:Connect(hook)
end

function CombatInput.Init()
	local function onCharacter(character)
		watch(character)
		watch(player:WaitForChild("Backpack"))
	end
	if player.Character then
		onCharacter(player.Character)
	end
	player.CharacterAdded:Connect(onCharacter)
end

return CombatInput
