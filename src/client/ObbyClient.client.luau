-- Aura Farm Obby — client HUD, toasts, finish panel (PC + mobile)

print("[ObbyClient] Starting")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Build a visible HUD FIRST so Play is never a blank screen
local gui = Instance.new("ScreenGui")
gui.Name = "AuraFarmHud"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local boot = Instance.new("TextLabel")
boot.Name = "Boot"
boot.Size = UDim2.new(0.8, 0, 0, 80)
boot.Position = UDim2.new(0.1, 0, 0.4, 0)
boot.BackgroundColor3 = Color3.fromRGB(18, 18, 28)
boot.BackgroundTransparency = 0.15
boot.BorderSizePixel = 0
boot.Font = Enum.Font.GothamBlack
boot.TextSize = 28
boot.TextColor3 = Color3.fromRGB(255, 255, 255)
boot.TextWrapped = true
boot.Text = "Aura Farm Obby\nLoading..."
boot.Parent = gui
local bootCorner = Instance.new("UICorner")
bootCorner.CornerRadius = UDim.new(0, 12)
bootCorner.Parent = boot

local function failBoot(msg: string)
	boot.Visible = true
	boot.Text = "Aura Farm Obby\n" .. msg
	boot.TextColor3 = Color3.fromRGB(255, 120, 120)
	warn("[ObbyClient] " .. msg)
end

-- Shared config (Rojo must map this)
local Shared = ReplicatedStorage:WaitForChild("Shared", 10)
if not Shared then
	failBoot("Missing ReplicatedStorage.Shared — Rojo not connected?\nRun: rojo serve  then Connect in Studio")
	return
end

local ObbyConfigModule = Shared:WaitForChild("ObbyConfig", 10)
if not ObbyConfigModule then
	failBoot("Missing ObbyConfig module — check default.project.json sync")
	return
end

local ObbyConfig = require(ObbyConfigModule)

local remotes = ReplicatedStorage:WaitForChild("ObbyRemotes", 15)
if not remotes then
	failBoot("Server did not start (no ObbyRemotes).\nCheck Output for [ObbyServer] errors")
	return
end

local RE_Stats = remotes:WaitForChild("StatsChanged") :: RemoteEvent
local RE_Toast = remotes:WaitForChild("Toast") :: RemoteEvent
local RE_Finished = remotes:WaitForChild("Finished") :: RemoteEvent
local RE_Restart = remotes:WaitForChild("RequestRestart") :: RemoteEvent
local RE_RunReset = remotes:WaitForChild("RunReset") :: RemoteEvent

boot.Visible = false

local stats = {
	aura = 0,
	coins = 0,
	orbs = 0,
	totalOrbs = 0,
	deaths = 0,
	checkpoint = 0,
	finished = false,
	elapsed = 0,
	bestTime = nil :: number?,
	gameName = ObbyConfig.GameName,
	runStartClock = os.clock(),
}

local function formatTime(seconds: number): string
	if seconds ~= seconds or seconds < 0 then
		return "0:00.0"
	end
	local m = math.floor(seconds / 60)
	local s = seconds - m * 60
	return string.format("%d:%04.1f", m, s)
end

local function panel(parent: Instance, name: string, size: UDim2, pos: UDim2): Frame
	local f = Instance.new("Frame")
	f.Name = name
	f.Size = size
	f.Position = pos
	f.BackgroundColor3 = ObbyConfig.Colors.Panel
	f.BackgroundTransparency = 0.18
	f.BorderSizePixel = 0
	f.Parent = parent
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 12)
	c.Parent = f
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 255, 255)
	stroke.Transparency = 0.85
	stroke.Thickness = 1
	stroke.Parent = f
	return f
end

local top = panel(gui, "TopBar", UDim2.new(0.92, 0, 0, 56), UDim2.new(0.04, 0, 0, 12))

local title = Instance.new("TextLabel")
title.Name = "Title"
title.BackgroundTransparency = 1
title.Position = UDim2.fromOffset(14, 0)
title.Size = UDim2.new(0.4, 0, 1, 0)
title.Font = Enum.Font.GothamBlack
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextScaled = true
title.Text = ObbyConfig.GameName
title.Parent = top
local titleConstraint = Instance.new("UITextSizeConstraint")
titleConstraint.MaxTextSize = 22
titleConstraint.Parent = title

local timerLabel = Instance.new("TextLabel")
timerLabel.Name = "Timer"
timerLabel.BackgroundTransparency = 1
timerLabel.AnchorPoint = Vector2.new(0.5, 0.5)
timerLabel.Position = UDim2.fromScale(0.5, 0.5)
timerLabel.Size = UDim2.new(0.2, 0, 0.7, 0)
timerLabel.Font = Enum.Font.GothamBold
timerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
timerLabel.TextScaled = true
timerLabel.Text = "0:00.0"
timerLabel.Parent = top

local rightStats = Instance.new("TextLabel")
rightStats.Name = "RightStats"
rightStats.BackgroundTransparency = 1
rightStats.AnchorPoint = Vector2.new(1, 0)
rightStats.Position = UDim2.new(1, -14, 0, 0)
rightStats.Size = UDim2.new(0.42, 0, 1, 0)
rightStats.Font = Enum.Font.GothamMedium
rightStats.TextXAlignment = Enum.TextXAlignment.Right
rightStats.TextColor3 = Color3.fromRGB(230, 230, 240)
rightStats.TextScaled = true
rightStats.Text = "Aura 0  |  Coins 0"
rightStats.Parent = top
local rightConstraint = Instance.new("UITextSizeConstraint")
rightConstraint.MaxTextSize = 18
rightConstraint.Parent = rightStats

local bottom = panel(gui, "BottomBar", UDim2.new(0.92, 0, 0, 52), UDim2.new(0.04, 0, 1, -64))

local infoLabel = Instance.new("TextLabel")
infoLabel.Name = "Info"
infoLabel.BackgroundTransparency = 1
infoLabel.Position = UDim2.fromOffset(14, 0)
infoLabel.Size = UDim2.new(0.62, -14, 1, 0)
infoLabel.Font = Enum.Font.Gotham
infoLabel.TextXAlignment = Enum.TextXAlignment.Left
infoLabel.TextColor3 = Color3.fromRGB(210, 210, 220)
infoLabel.TextScaled = true
infoLabel.Text = "Orbs 0/0  ·  CP 0  ·  Deaths 0"
infoLabel.Parent = bottom
local infoConstraint = Instance.new("UITextSizeConstraint")
infoConstraint.MaxTextSize = 18
infoConstraint.Parent = infoLabel

local restartBtn = Instance.new("TextButton")
restartBtn.Name = "Restart"
restartBtn.AnchorPoint = Vector2.new(1, 0.5)
restartBtn.Position = UDim2.new(1, -10, 0.5, 0)
restartBtn.Size = UDim2.fromOffset(120, 36)
restartBtn.BackgroundColor3 = Color3.fromRGB(255, 90, 110)
restartBtn.BorderSizePixel = 0
restartBtn.Font = Enum.Font.GothamBold
restartBtn.Text = "Restart"
restartBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
restartBtn.TextSize = 18
restartBtn.AutoButtonColor = true
restartBtn.Parent = bottom
local rbCorner = Instance.new("UICorner")
rbCorner.CornerRadius = UDim.new(0, 8)
rbCorner.Parent = restartBtn

if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
	restartBtn.Size = UDim2.fromOffset(140, 44)
	bottom.Size = UDim2.new(0.92, 0, 0, 60)
	bottom.Position = UDim2.new(0.04, 0, 1, -72)
end

local toastLabel = Instance.new("TextLabel")
toastLabel.Name = "Toast"
toastLabel.AnchorPoint = Vector2.new(0.5, 0)
toastLabel.Position = UDim2.new(0.5, 0, 0, 78)
toastLabel.Size = UDim2.new(0.6, 0, 0, 36)
toastLabel.BackgroundColor3 = ObbyConfig.Colors.Panel
toastLabel.BackgroundTransparency = 0.2
toastLabel.BorderSizePixel = 0
toastLabel.Font = Enum.Font.GothamBold
toastLabel.TextSize = 20
toastLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
toastLabel.Text = ""
toastLabel.Visible = false
toastLabel.Parent = gui
local toastCorner = Instance.new("UICorner")
toastCorner.CornerRadius = UDim.new(0, 10)
toastCorner.Parent = toastLabel

local toastToken = 0
local function showToast(text: string, kind: string?)
	toastToken += 1
	local token = toastToken
	toastLabel.Text = text
	toastLabel.Visible = true
	if kind == "good" then
		toastLabel.TextColor3 = ObbyConfig.Colors.Good
	elseif kind == "bad" then
		toastLabel.TextColor3 = ObbyConfig.Colors.Bad
	elseif kind == "aura" then
		toastLabel.TextColor3 = ObbyConfig.Colors.Aura
	else
		toastLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	end
	task.delay(1.4, function()
		if token == toastToken then
			toastLabel.Visible = false
		end
	end)
end

local finishFrame = panel(gui, "Finish", UDim2.new(0.7, 0, 0, 280), UDim2.fromScale(0.15, 0.22))
finishFrame.Visible = false
finishFrame.ZIndex = 20

local finishTitle = Instance.new("TextLabel")
finishTitle.BackgroundTransparency = 1
finishTitle.Size = UDim2.new(1, -20, 0, 40)
finishTitle.Position = UDim2.fromOffset(10, 12)
finishTitle.Font = Enum.Font.GothamBlack
finishTitle.TextSize = 28
finishTitle.TextColor3 = ObbyConfig.Colors.Good
finishTitle.Text = "STAGE CLEAR"
finishTitle.Parent = finishFrame

local finishBody = Instance.new("TextLabel")
finishBody.Name = "Body"
finishBody.BackgroundTransparency = 1
finishBody.Size = UDim2.new(1, -24, 0, 150)
finishBody.Position = UDim2.fromOffset(12, 56)
finishBody.Font = Enum.Font.Gotham
finishBody.TextSize = 20
finishBody.TextColor3 = Color3.fromRGB(235, 235, 245)
finishBody.TextXAlignment = Enum.TextXAlignment.Left
finishBody.TextYAlignment = Enum.TextYAlignment.Top
finishBody.TextWrapped = true
finishBody.Text = ""
finishBody.Parent = finishFrame

local finishRestart = Instance.new("TextButton")
finishRestart.Name = "FinishRestart"
finishRestart.AnchorPoint = Vector2.new(0.5, 1)
finishRestart.Position = UDim2.new(0.5, 0, 1, -16)
finishRestart.Size = UDim2.fromOffset(180, 44)
finishRestart.BackgroundColor3 = Color3.fromRGB(120, 90, 255)
finishRestart.BorderSizePixel = 0
finishRestart.Font = Enum.Font.GothamBold
finishRestart.TextSize = 20
finishRestart.TextColor3 = Color3.fromRGB(255, 255, 255)
finishRestart.Text = "Run Again"
finishRestart.Parent = finishFrame
local frCorner = Instance.new("UICorner")
frCorner.CornerRadius = UDim.new(0, 10)
frCorner.Parent = finishRestart

local function requestRestart()
	finishFrame.Visible = false
	stats.finished = false
	stats.runStartClock = os.clock()
	RE_Restart:FireServer()
end

restartBtn.MouseButton1Click:Connect(requestRestart)
finishRestart.MouseButton1Click:Connect(requestRestart)

local function refreshLabels()
	rightStats.Text = `Aura {stats.aura}  |  Coins {stats.coins}`
	infoLabel.Text = `Orbs {stats.orbs}/{stats.totalOrbs}  ·  CP {stats.checkpoint}  ·  Deaths {stats.deaths}`
	if stats.bestTime then
		title.Text = `{stats.gameName}  ·  PB {formatTime(stats.bestTime)}`
	else
		title.Text = stats.gameName
	end
end

RE_Stats.OnClientEvent:Connect(function(payload)
	if typeof(payload) ~= "table" then
		return
	end
	stats.aura = payload.aura or stats.aura
	stats.coins = payload.coins or stats.coins
	stats.orbs = payload.orbs or stats.orbs
	stats.totalOrbs = payload.totalOrbs or stats.totalOrbs
	stats.deaths = payload.deaths or stats.deaths
	stats.checkpoint = payload.checkpoint or stats.checkpoint
	stats.finished = payload.finished == true
	stats.bestTime = payload.bestTime
	stats.gameName = payload.gameName or stats.gameName
	if typeof(payload.elapsed) == "number" then
		stats.elapsed = payload.elapsed
		if not stats.finished then
			stats.runStartClock = os.clock() - payload.elapsed
		end
	end
	refreshLabels()
end)

RE_Toast.OnClientEvent:Connect(function(text, kind)
	if typeof(text) == "string" then
		showToast(text, kind)
	end
end)

RE_Finished.OnClientEvent:Connect(function(payload)
	if typeof(payload) ~= "table" then
		return
	end
	stats.finished = true
	stats.aura = payload.auraTotal or stats.aura
	stats.coins = payload.coinsTotal or stats.coins
	refreshLabels()

	local bonusText = ""
	if typeof(payload.bonuses) == "table" and #payload.bonuses > 0 then
		bonusText = "\nBonuses: " .. table.concat(payload.bonuses, ", ")
	end

	finishBody.Text = table.concat({
		`Time: {formatTime(payload.time or 0)}`,
		`Best: {formatTime(payload.bestTime or payload.time or 0)}`,
		`Aura +{payload.auraGain or 0}  (total {payload.auraTotal or 0})`,
		`Coins +{payload.coinGain or 0}  (total {payload.coinsTotal or 0})`,
		`Orbs {payload.orbs or 0}/{payload.totalOrbs or 0}  ·  Deaths {payload.deaths or 0}`,
		bonusText,
	}, "\n")
	finishFrame.Visible = true
	showToast("Stage clear — aura farmed!", "aura")
end)

RE_RunReset.OnClientEvent:Connect(function()
	finishFrame.Visible = false
	stats.finished = false
	stats.runStartClock = os.clock()
	stats.orbs = 0
	stats.deaths = 0
	stats.checkpoint = 0
	refreshLabels()
end)

RunService.RenderStepped:Connect(function()
	if stats.finished then
		timerLabel.Text = formatTime(stats.elapsed)
		return
	end
	local t = os.clock() - stats.runStartClock
	stats.elapsed = t
	timerLabel.Text = formatTime(t)
end)

refreshLabels()
showToast("Go! Farm that aura", "aura")
print("[ObbyClient] HUD ready")
