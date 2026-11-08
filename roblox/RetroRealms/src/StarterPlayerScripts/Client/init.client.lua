--[[
	Client (main LocalScript)
	Starts every client module. Lives in StarterPlayer > StarterPlayerScripts.
]]

local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

local UI = require(script.UI)
local State = require(script.State)
local Hud = require(script.Hud)
local Effects = require(script.Effects)
local Nameplates = require(script.Nameplates)
local DungeonWindow = require(script.DungeonWindow)
local Atlas = require(script.Atlas)
local CombatInput = require(script.CombatInput)
local Zones = require(script.Zones)

-- Our own HP bar replaces the default one
task.spawn(function()
	for _ = 1, 10 do
		local ok = pcall(function()
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
		end)
		if ok then
			break
		end
		task.wait(1)
	end
end)

UI.Init()
State.Init()
Hud.Init(Atlas.Toggle)
Effects.Init()
Nameplates.Init()
DungeonWindow.Init()
Atlas.Init()
CombatInput.Init()
Zones.Init()

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.KeyCode == Enum.KeyCode.M then
		Atlas.Toggle()
	end
end)
