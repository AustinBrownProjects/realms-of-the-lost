--[[
	UI
	Shared retro UI helpers: colours, fonts, panels, buttons, bars, number
	formatting and the single ScreenGui every client module draws into.
]]

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local UI = {}

UI.Colors = {
	Panel = Color3.fromRGB(20, 18, 30),
	PanelAlt = Color3.fromRGB(34, 30, 48),
	Border = Color3.fromRGB(230, 186, 84),
	BorderDim = Color3.fromRGB(90, 80, 110),
	Text = Color3.fromRGB(242, 236, 220),
	Muted = Color3.fromRGB(160, 152, 170),
	HP = Color3.fromRGB(214, 58, 58),
	XP = Color3.fromRGB(240, 196, 64),
	Gold = Color3.fromRGB(255, 214, 90),
	Good = Color3.fromRGB(120, 220, 120),
	Bad = Color3.fromRGB(240, 90, 90),
	Button = Color3.fromRGB(56, 48, 80),
	BarBack = Color3.fromRGB(10, 8, 16),
}

UI.TitleFont = Enum.Font.Arcade
UI.BodyFont = Enum.Font.Code

function UI.make(className, props, parent)
	local inst = Instance.new(className)
	for k, v in pairs(props or {}) do
		inst[k] = v
	end
	if parent then
		inst.Parent = parent
	end
	return inst
end

function UI.stroke(obj, color, thickness)
	return UI.make("UIStroke", {
		Color = color or UI.Colors.Border,
		Thickness = thickness or 2,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	}, obj)
end

function UI.padding(obj, px)
	return UI.make("UIPadding", {
		PaddingTop = UDim.new(0, px),
		PaddingBottom = UDim.new(0, px),
		PaddingLeft = UDim.new(0, px),
		PaddingRight = UDim.new(0, px),
	}, obj)
end

function UI.panel(parent, props)
	local f = UI.make("Frame", {
		BackgroundColor3 = UI.Colors.Panel,
		BackgroundTransparency = 0.08,
		BorderSizePixel = 0,
	}, nil)
	for k, v in pairs(props or {}) do
		f[k] = v
	end
	UI.stroke(f)
	f.Parent = parent
	return f
end

function UI.label(parent, props)
	local l = UI.make("TextLabel", {
		BackgroundTransparency = 1,
		Font = UI.BodyFont,
		TextColor3 = UI.Colors.Text,
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextStrokeTransparency = 0.5,
		Size = UDim2.new(1, 0, 0, 20),
	}, nil)
	for k, v in pairs(props or {}) do
		l[k] = v
	end
	l.Parent = parent
	return l
end

function UI.button(parent, text, props, onClick)
	local b = UI.make("TextButton", {
		BackgroundColor3 = UI.Colors.Button,
		BorderSizePixel = 0,
		AutoButtonColor = true,
		Font = UI.TitleFont,
		Text = text,
		TextColor3 = UI.Colors.Text,
		TextSize = 16,
		Size = UDim2.fromOffset(120, 32),
	}, nil)
	for k, v in pairs(props or {}) do
		b[k] = v
	end
	UI.stroke(b, UI.Colors.Border, 2)
	b.Parent = parent
	if onClick then
		b.Activated:Connect(onClick)
	end
	return b
end

-- Returns { Frame, Fill, Text }
function UI.bar(parent, color, props)
	local back = UI.make("Frame", {
		BackgroundColor3 = UI.Colors.BarBack,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 16),
	}, nil)
	for k, v in pairs(props or {}) do
		back[k] = v
	end
	UI.stroke(back, UI.Colors.BorderDim, 1)
	local fill = UI.make("Frame", {
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
	}, back)
	local text = UI.make("TextLabel", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Font = UI.BodyFont,
		TextSize = 13,
		TextColor3 = UI.Colors.Text,
		TextStrokeTransparency = 0.2,
		ZIndex = 2,
		Text = "",
	}, back)
	back.Parent = parent
	return { Frame = back, Fill = fill, Text = text }
end

function UI.setBar(bar, ratio, text)
	if ratio ~= ratio then -- NaN
		ratio = 0
	end
	bar.Fill.Size = UDim2.fromScale(math.clamp(ratio, 0, 1), 1)
	if text then
		bar.Text.Text = text
	end
end

-- 1234 -> "1,234"
function UI.comma(n)
	local s = tostring(math.floor(n))
	local formatted = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
	return (formatted:gsub("^(-?),", "%1"))
end

-- 1234567 -> "1.23M"
function UI.short(n)
	n = math.floor(n)
	local abs = math.abs(n)
	if abs >= 1e12 then
		return ("%.2fT"):format(n / 1e12)
	elseif abs >= 1e9 then
		return ("%.2fB"):format(n / 1e9)
	elseif abs >= 1e6 then
		return ("%.2fM"):format(n / 1e6)
	elseif abs >= 1e4 then
		return ("%.1fK"):format(n / 1e3)
	end
	return UI.comma(n)
end

function UI.tween(obj, time, props, style)
	local t = TweenService:Create(obj, TweenInfo.new(time, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
	t:Play()
	return t
end

function UI.Init()
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local root = UI.make("ScreenGui", {
		Name = "RetroRealmsUI",
		ResetOnSpawn = false,
		IgnoreGuiInset = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}, playerGui)
	local scale = UI.make("UIScale", {}, root)

	-- Shrink the UI on small (phone) screens
	local camera = workspace.CurrentCamera
	local function rescale()
		local vp = camera.ViewportSize
		scale.Scale = math.clamp(math.min(vp.X / 1100, vp.Y / 720), 0.55, 1.15)
	end
	camera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale)
	rescale()

	-- Billboards (nameplates etc.) live here so they survive respawns
	UI.Billboards = UI.make("Folder", { Name = "RetroRealmsBillboards" }, playerGui)
	UI.Root = root
end

return UI
