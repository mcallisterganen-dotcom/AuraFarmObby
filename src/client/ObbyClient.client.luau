-- Aura Farm Obby — client HUD
-- tides: notifications, tutorial, settings, music, quests UI, weather banner
-- gear-clicker: compact number format, juice feedback

print("[ObbyClient] Starting")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ObbyConfig = require(Shared:WaitForChild("ObbyConfig"))
local CosmeticsCatalog = require(Shared:WaitForChild("CosmeticsCatalog"))
local FormatUtil = require(Shared:WaitForChild("FormatUtil"))
local TutorialConfig = require(Shared:WaitForChild("TutorialConfig"))
local SoundCatalog = require(Shared:WaitForChild("SoundCatalog"))
local TimeUtil = require(Shared:WaitForChild("TimeUtil"))
local RemotesMod = require(Shared:WaitForChild("Remotes"))

local remoteFolder = RemotesMod.WaitClient(20)
local function R(name: string): RemoteEvent
	return remoteFolder:WaitForChild(name) :: RemoteEvent
end

local Toast = R("Toast")
local AuraUpdate = R("AuraUpdate")
local StatsUpdate = R("StatsUpdate")
local FinishEv = R("Finish")
local RestartRequest = R("RestartRequest")
local BuyCosmetic = R("BuyCosmetic")
local EquipCosmetic = R("EquipCosmetic")
local CosmeticResult = R("CosmeticResult")
local AchievementUnlocked = R("AchievementUnlocked")
local QuestUpdate = R("QuestUpdate")
local ClaimQuest = R("ClaimQuest")
local QuestResult = R("QuestResult")
local WeatherUpdate = R("WeatherUpdate")
local LeaderboardUpdate = R("LeaderboardUpdate")
local RequestLeaderboard = R("RequestLeaderboard")
local OfflineReward = R("OfflineReward")
local SettingsUpdate = R("SettingsUpdate")
local TutorialState = R("TutorialState")
local TutorialComplete = R("TutorialComplete")
local PlaySound = R("PlaySound")

-- State
local aura = 0
local coins = 0
local bestTime: number? = nil
local equippedTrail = "trail_starter"
local unlocked: { [string]: boolean } = { trail_starter = true }
local runStart = os.clock()
local finished = false
local checkpointIndex = 0
local settings = { music = true, sfx = true, reduceFx = false }
local weatherLabel = "Clear Skies"
local weatherMult = 1
local questSnap: any = nil
local tutorialStep = 0
local leaderboardRows: { any } = {}

local COLORS = ObbyConfig.Colors

-- Root GUI
local gui = Instance.new("ScreenGui")
gui.Name = "AuraFarmHud"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local function corner(parent: Instance, r: number?)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or 10)
	c.Parent = parent
	return c
end

local function pad(parent: Instance, px: number?)
	local p = Instance.new("UIPadding")
	local n = px or 8
	p.PaddingTop = UDim.new(0, n)
	p.PaddingBottom = UDim.new(0, n)
	p.PaddingLeft = UDim.new(0, n)
	p.PaddingRight = UDim.new(0, n)
	p.Parent = parent
	return p
end

local function stroke(parent: Instance, color: Color3?, thickness: number?)
	local s = Instance.new("UIStroke")
	s.Color = color or Color3.fromRGB(255, 255, 255)
	s.Thickness = thickness or 1
	s.Transparency = 0.7
	s.Parent = parent
	return s
end

-- SFX / Music
local sfxFolder = Instance.new("Folder")
sfxFolder.Name = "AuraFarmSfx"
sfxFolder.Parent = SoundService

local music = Instance.new("Sound")
music.Name = "AuraFarmMusic"
music.SoundId = SoundCatalog.MusicId
music.Volume = SoundCatalog.MusicVolume
music.Looped = true
music.Parent = SoundService

local function playSfx(key: string)
	if settings.sfx == false then
		return
	end
	local id = SoundCatalog.Ids[key]
	if not id then
		return
	end
	local s = Instance.new("Sound")
	s.SoundId = id
	s.Volume = SoundCatalog.SfxVolume
	s.Parent = sfxFolder
	s:Play()
	s.Ended:Connect(function()
		s:Destroy()
	end)
	task.delay(4, function()
		if s.Parent then
			s:Destroy()
		end
	end)
end

local function refreshMusic()
	if settings.music then
		if not music.IsPlaying then
			music:Play()
		end
	else
		music:Stop()
	end
end

task.defer(function()
	task.wait(1)
	refreshMusic()
end)

-- Top bar
local top = Instance.new("Frame")
top.Name = "TopBar"
top.AnchorPoint = Vector2.new(0.5, 0)
top.Position = UDim2.new(0.5, 0, 0, 12)
top.Size = UDim2.new(0, 460, 0, 56)
top.BackgroundColor3 = COLORS.UI
top.BackgroundTransparency = 0.15
top.Parent = gui
corner(top, 14)
stroke(top, COLORS.Aura, 1.5)
pad(top, 10)

local topLayout = Instance.new("UIListLayout")
topLayout.FillDirection = Enum.FillDirection.Horizontal
topLayout.Padding = UDim.new(0, 10)
topLayout.VerticalAlignment = Enum.VerticalAlignment.Center
topLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
topLayout.Parent = top

local function makeStat(name: string, color: Color3, width: number?): TextLabel
	local t = Instance.new("TextLabel")
	t.Name = name
	t.BackgroundTransparency = 1
	t.Size = UDim2.new(0, width or 110, 1, 0)
	t.Font = Enum.Font.GothamBold
	t.TextSize = 17
	t.TextColor3 = color
	t.Text = name .. ": 0"
	t.Parent = top
	return t
end

local auraLabel = makeStat("Aura", COLORS.Aura, 110)
local coinLabel = makeStat("Coins", COLORS.Coin, 100)
local timeLabel = makeStat("Time", Color3.fromRGB(220, 230, 255), 120)
local streakLabel = makeStat("Streak", Color3.fromRGB(255, 160, 100), 90)

local cpLabel = Instance.new("TextLabel")
cpLabel.Name = "Checkpoint"
cpLabel.Position = UDim2.new(0, 16, 0, 76)
cpLabel.Size = UDim2.new(0, 100, 0, 28)
cpLabel.BackgroundColor3 = COLORS.UI
cpLabel.BackgroundTransparency = 0.2
cpLabel.Font = Enum.Font.GothamMedium
cpLabel.TextSize = 14
cpLabel.TextColor3 = COLORS.Checkpoint
cpLabel.Text = "CP 0"
cpLabel.Parent = gui
corner(cpLabel, 8)

local weatherChip = Instance.new("TextLabel")
weatherChip.Name = "Weather"
weatherChip.Position = UDim2.new(0, 124, 0, 76)
weatherChip.Size = UDim2.new(0, 200, 0, 28)
weatherChip.BackgroundColor3 = COLORS.UI
weatherChip.BackgroundTransparency = 0.2
weatherChip.Font = Enum.Font.GothamMedium
weatherChip.TextSize = 13
weatherChip.TextColor3 = Color3.fromRGB(180, 210, 255)
weatherChip.Text = "Weather: Clear"
weatherChip.Parent = gui
corner(weatherChip, 8)

-- Buttons
local btnCol = Instance.new("Frame")
btnCol.Name = "Buttons"
btnCol.AnchorPoint = Vector2.new(1, 0.5)
btnCol.Position = UDim2.new(1, -16, 0.5, 0)
btnCol.Size = UDim2.new(0, 120, 0, 280)
btnCol.BackgroundTransparency = 1
btnCol.Parent = gui

local btnLayout = Instance.new("UIListLayout")
btnLayout.Padding = UDim.new(0, 8)
btnLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
btnLayout.Parent = btnCol

local function makeButton(text: string, color: Color3): TextButton
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(1, 0, 0, 40)
	b.BackgroundColor3 = color
	b.Font = Enum.Font.GothamBold
	b.TextSize = 15
	b.TextColor3 = Color3.new(1, 1, 1)
	b.Text = text
	b.AutoButtonColor = true
	b.Parent = btnCol
	corner(b, 12)
	stroke(b, Color3.new(1, 1, 1), 1)
	return b
end

local shopBtn = makeButton("Shop", Color3.fromRGB(120, 70, 200))
local questBtn = makeButton("Quests", Color3.fromRGB(70, 140, 200))
local boardBtn = makeButton("Times", Color3.fromRGB(50, 120, 100))
local settingsBtn = makeButton("Settings", Color3.fromRGB(80, 80, 100))
local restartBtn = makeButton("Restart", Color3.fromRGB(70, 90, 140))

-- Toasts
local toastFrame = Instance.new("Frame")
toastFrame.Name = "Toasts"
toastFrame.AnchorPoint = Vector2.new(0.5, 1)
toastFrame.Position = UDim2.new(0.5, 0, 1, -24)
toastFrame.Size = UDim2.new(0, 380, 0, 220)
toastFrame.BackgroundTransparency = 1
toastFrame.Parent = gui

local toastLayout = Instance.new("UIListLayout")
toastLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
toastLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
toastLayout.Padding = UDim.new(0, 6)
toastLayout.SortOrder = Enum.SortOrder.LayoutOrder
toastLayout.Parent = toastFrame

local toastOrder = 0
local kindColor = {
	info = Color3.fromRGB(200, 210, 255),
	good = COLORS.Good,
	warn = COLORS.Warn,
	bad = COLORS.Bad,
	aura = COLORS.Aura,
}

local function showToast(text: string, kind: string?)
	toastOrder += 1
	local f = Instance.new("TextLabel")
	f.LayoutOrder = toastOrder
	f.Size = UDim2.new(1, 0, 0, 32)
	f.BackgroundColor3 = COLORS.UI
	f.Font = Enum.Font.GothamMedium
	f.TextSize = 15
	f.TextColor3 = kindColor[kind or "info"] or kindColor.info
	f.Text = text
	f.Parent = toastFrame
	corner(f, 8)
	f.TextTransparency = 1
	f.BackgroundTransparency = 1
	TweenService:Create(f, TweenInfo.new(0.2), { TextTransparency = 0, BackgroundTransparency = 0.15 }):Play()
	if not settings.reduceFx then
		playSfx("Notify")
	end
	task.delay(2.6, function()
		local tw = TweenService:Create(f, TweenInfo.new(0.35), { TextTransparency = 1, BackgroundTransparency = 1 })
		tw:Play()
		tw.Completed:Wait()
		f:Destroy()
	end)
end

-- Modal helper
local function makeModal(name: string, titleText: string, size: UDim2): (Frame, Frame, TextButton)
	local panel = Instance.new("Frame")
	panel.Name = name
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.Size = size
	panel.BackgroundColor3 = COLORS.UI
	panel.BackgroundTransparency = 0.05
	panel.Visible = false
	panel.Parent = gui
	corner(panel, 16)
	stroke(panel, COLORS.Aura, 2)
	pad(panel, 14)

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(1, -40, 0, 32)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 22
	title.TextColor3 = COLORS.Aura
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Text = titleText
	title.Parent = panel

	local close = Instance.new("TextButton")
	close.AnchorPoint = Vector2.new(1, 0)
	close.Position = UDim2.new(1, 0, 0, 0)
	close.Size = UDim2.new(0, 36, 0, 36)
	close.BackgroundColor3 = Color3.fromRGB(80, 40, 50)
	close.Font = Enum.Font.GothamBold
	close.TextSize = 18
	close.TextColor3 = Color3.new(1, 1, 1)
	close.Text = "X"
	close.Parent = panel
	corner(close, 8)

	local body = Instance.new("Frame")
	body.Name = "Body"
	body.Position = UDim2.new(0, 0, 0, 44)
	body.Size = UDim2.new(1, 0, 1, -52)
	body.BackgroundTransparency = 1
	body.Parent = panel

	return panel, body, close
end

local function closeAllModals()
	for _, child in gui:GetChildren() do
		if child:IsA("Frame") and child:GetAttribute("IsModal") then
			child.Visible = false
		end
	end
end

-- Finish panel
local finishPanel = Instance.new("Frame")
finishPanel.Name = "FinishPanel"
finishPanel.AnchorPoint = Vector2.new(0.5, 0.5)
finishPanel.Position = UDim2.fromScale(0.5, 0.5)
finishPanel.Size = UDim2.new(0, 340, 0, 260)
finishPanel.BackgroundColor3 = COLORS.UI
finishPanel.BackgroundTransparency = 0.05
finishPanel.Visible = false
finishPanel:SetAttribute("IsModal", true)
finishPanel.Parent = gui
corner(finishPanel, 16)
stroke(finishPanel, COLORS.Finish, 2)
pad(finishPanel, 16)

local finishTitle = Instance.new("TextLabel")
finishTitle.BackgroundTransparency = 1
finishTitle.Size = UDim2.new(1, 0, 0, 36)
finishTitle.Font = Enum.Font.GothamBold
finishTitle.TextSize = 26
finishTitle.TextColor3 = COLORS.Finish
finishTitle.Text = "Stage Clear!"
finishTitle.Parent = finishPanel

local finishBody = Instance.new("TextLabel")
finishBody.BackgroundTransparency = 1
finishBody.Position = UDim2.new(0, 0, 0, 44)
finishBody.Size = UDim2.new(1, 0, 0, 120)
finishBody.Font = Enum.Font.Gotham
finishBody.TextSize = 16
finishBody.TextColor3 = Color3.fromRGB(230, 230, 240)
finishBody.TextWrapped = true
finishBody.TextYAlignment = Enum.TextYAlignment.Top
finishBody.Text = ""
finishBody.Parent = finishPanel

local finishAgain = Instance.new("TextButton")
finishAgain.Position = UDim2.new(0, 0, 1, -52)
finishAgain.Size = UDim2.new(0.48, -4, 0, 44)
finishAgain.BackgroundColor3 = Color3.fromRGB(60, 160, 100)
finishAgain.Font = Enum.Font.GothamBold
finishAgain.TextSize = 16
finishAgain.TextColor3 = Color3.new(1, 1, 1)
finishAgain.Text = "Run Again"
finishAgain.Parent = finishPanel
corner(finishAgain, 12)

local finishShop = Instance.new("TextButton")
finishShop.Position = UDim2.new(0.52, 4, 1, -52)
finishShop.Size = UDim2.new(0.48, -4, 0, 44)
finishShop.BackgroundColor3 = Color3.fromRGB(120, 70, 200)
finishShop.Font = Enum.Font.GothamBold
finishShop.TextSize = 16
finishShop.TextColor3 = Color3.new(1, 1, 1)
finishShop.Text = "Open Shop"
finishShop.Parent = finishPanel
corner(finishShop, 12)

-- Shop
local shopPanel, shopBody, shopClose = makeModal("ShopPanel", "Aura Shop — Trails", UDim2.new(0, 380, 0, 420))
shopPanel:SetAttribute("IsModal", true)
local shopScroll = Instance.new("ScrollingFrame")
shopScroll.Size = UDim2.fromScale(1, 1)
shopScroll.BackgroundTransparency = 1
shopScroll.BorderSizePixel = 0
shopScroll.ScrollBarThickness = 6
shopScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
shopScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
shopScroll.Parent = shopBody
local shopList = Instance.new("UIListLayout")
shopList.Padding = UDim.new(0, 8)
shopList.Parent = shopScroll
local shopRows: { [string]: Frame } = {}

local function refreshShop()
	for _, row in shopRows do
		row:Destroy()
	end
	table.clear(shopRows)
	for _, def in CosmeticsCatalog.All() do
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, -8, 0, 72)
		row.BackgroundColor3 = Color3.fromRGB(28, 28, 42)
		row.Parent = shopScroll
		corner(row, 10)
		stroke(row, def.color, 1)
		pad(row, 10)

		local swatch = Instance.new("Frame")
		swatch.Size = UDim2.new(0, 20, 1, 0)
		swatch.BackgroundColor3 = def.color
		swatch.Parent = row
		corner(swatch, 6)

		local name = Instance.new("TextLabel")
		name.BackgroundTransparency = 1
		name.Position = UDim2.new(0, 28, 0, 0)
		name.Size = UDim2.new(1, -140, 0, 24)
		name.Font = Enum.Font.GothamBold
		name.TextSize = 16
		name.TextColor3 = Color3.new(1, 1, 1)
		name.TextXAlignment = Enum.TextXAlignment.Left
		name.Text = def.name
		name.Parent = row

		local desc = Instance.new("TextLabel")
		desc.BackgroundTransparency = 1
		desc.Position = UDim2.new(0, 28, 0, 26)
		desc.Size = UDim2.new(1, -140, 0, 28)
		desc.Font = Enum.Font.Gotham
		desc.TextSize = 12
		desc.TextColor3 = Color3.fromRGB(180, 180, 200)
		desc.TextXAlignment = Enum.TextXAlignment.Left
		desc.TextWrapped = true
		desc.Text = def.description
		desc.Parent = row

		local action = Instance.new("TextButton")
		action.AnchorPoint = Vector2.new(1, 0.5)
		action.Position = UDim2.new(1, 0, 0.5, 0)
		action.Size = UDim2.new(0, 100, 0, 36)
		action.Font = Enum.Font.GothamBold
		action.TextSize = 14
		action.TextColor3 = Color3.new(1, 1, 1)
		action.Parent = row
		corner(action, 8)

		local owned = unlocked[def.id] == true
		local equipped = equippedTrail == def.id
		if equipped then
			action.Text = "Equipped"
			action.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
		elseif owned then
			action.Text = "Equip"
			action.BackgroundColor3 = Color3.fromRGB(50, 120, 200)
			action.MouseButton1Click:Connect(function()
				playSfx("Click")
				EquipCosmetic:FireServer(def.id)
			end)
		else
			action.Text = def.priceAura > 0 and (FormatUtil.Comma(def.priceAura) .. " Aura") or "Free"
			action.BackgroundColor3 = Color3.fromRGB(120, 70, 200)
			action.MouseButton1Click:Connect(function()
				playSfx("Click")
				BuyCosmetic:FireServer(def.id)
			end)
		end
		shopRows[def.id] = row
	end
end

-- Quests panel
local questPanel, questBody, questClose = makeModal("QuestPanel", "Daily Quests", UDim2.new(0, 380, 0, 400))
questPanel:SetAttribute("IsModal", true)
local questHeader = Instance.new("TextLabel")
questHeader.BackgroundTransparency = 1
questHeader.Size = UDim2.new(1, 0, 0, 40)
questHeader.Font = Enum.Font.Gotham
questHeader.TextSize = 14
questHeader.TextColor3 = Color3.fromRGB(200, 200, 220)
questHeader.TextXAlignment = Enum.TextXAlignment.Left
questHeader.TextWrapped = true
questHeader.Text = "Loading…"
questHeader.Parent = questBody

local questScroll = Instance.new("ScrollingFrame")
questScroll.Position = UDim2.new(0, 0, 0, 44)
questScroll.Size = UDim2.new(1, 0, 1, -44)
questScroll.BackgroundTransparency = 1
questScroll.BorderSizePixel = 0
questScroll.ScrollBarThickness = 6
questScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
questScroll.Parent = questBody
local questList = Instance.new("UIListLayout")
questList.Padding = UDim.new(0, 8)
questList.Parent = questScroll

local function refreshQuests()
	for _, c in questScroll:GetChildren() do
		if c:IsA("Frame") then
			c:Destroy()
		end
	end
	if not questSnap then
		questHeader.Text = "No quest data yet"
		return
	end
	questHeader.Text = string.format(
		"Streak x%d · Resets in %s",
		questSnap.streak or 1,
		TimeUtil.FormatCompact(questSnap.resetsIn or 0)
	)
	for _, q in questSnap.quests or {} do
		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, -8, 0, 88)
		row.BackgroundColor3 = Color3.fromRGB(28, 28, 42)
		row.Parent = questScroll
		corner(row, 10)
		pad(row, 10)

		local title = Instance.new("TextLabel")
		title.BackgroundTransparency = 1
		title.Size = UDim2.new(1, -110, 0, 22)
		title.Font = Enum.Font.GothamBold
		title.TextSize = 16
		title.TextColor3 = Color3.new(1, 1, 1)
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.Text = q.name
		title.Parent = row

		local desc = Instance.new("TextLabel")
		desc.BackgroundTransparency = 1
		desc.Position = UDim2.new(0, 0, 0, 22)
		desc.Size = UDim2.new(1, -110, 0, 28)
		desc.Font = Enum.Font.Gotham
		desc.TextSize = 12
		desc.TextColor3 = Color3.fromRGB(180, 180, 200)
		desc.TextXAlignment = Enum.TextXAlignment.Left
		desc.TextWrapped = true
		desc.Text = q.description
		desc.Parent = row

		local prog = Instance.new("TextLabel")
		prog.BackgroundTransparency = 1
		prog.Position = UDim2.new(0, 0, 0, 52)
		prog.Size = UDim2.new(1, -110, 0, 20)
		prog.Font = Enum.Font.GothamMedium
		prog.TextSize = 13
		prog.TextColor3 = q.complete and COLORS.Good or Color3.fromRGB(200, 210, 255)
		prog.TextXAlignment = Enum.TextXAlignment.Left
		prog.Text = string.format("%d / %d  ·  +%d Aura", math.min(q.progress, q.target), q.target, q.rewardAura)
		prog.Parent = row

		local btn = Instance.new("TextButton")
		btn.AnchorPoint = Vector2.new(1, 0.5)
		btn.Position = UDim2.new(1, 0, 0.5, 0)
		btn.Size = UDim2.new(0, 96, 0, 36)
		btn.Font = Enum.Font.GothamBold
		btn.TextSize = 14
		btn.TextColor3 = Color3.new(1, 1, 1)
		btn.Parent = row
		corner(btn, 8)

		if q.claimed then
			btn.Text = "Claimed"
			btn.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
		elseif q.complete then
			btn.Text = "Claim"
			btn.BackgroundColor3 = Color3.fromRGB(60, 160, 100)
			btn.MouseButton1Click:Connect(function()
				playSfx("Click")
				ClaimQuest:FireServer(q.id)
			end)
		else
			btn.Text = "Active"
			btn.BackgroundColor3 = Color3.fromRGB(50, 70, 110)
		end
	end
end

-- Leaderboard
local boardPanel, boardBody, boardClose = makeModal("BoardPanel", "Best Times", UDim2.new(0, 360, 0, 380))
boardPanel:SetAttribute("IsModal", true)
local boardScroll = Instance.new("ScrollingFrame")
boardScroll.Size = UDim2.fromScale(1, 1)
boardScroll.BackgroundTransparency = 1
boardScroll.BorderSizePixel = 0
boardScroll.ScrollBarThickness = 6
boardScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
boardScroll.Parent = boardBody
local boardList = Instance.new("UIListLayout")
boardList.Padding = UDim.new(0, 6)
boardList.Parent = boardScroll

local function refreshBoard()
	for _, c in boardScroll:GetChildren() do
		if c:IsA("TextLabel") then
			c:Destroy()
		end
	end
	if #leaderboardRows == 0 then
		local empty = Instance.new("TextLabel")
		empty.Size = UDim2.new(1, 0, 0, 40)
		empty.BackgroundTransparency = 1
		empty.Font = Enum.Font.Gotham
		empty.TextSize = 14
		empty.TextColor3 = Color3.fromRGB(180, 180, 200)
		empty.Text = "No times yet — finish a run!"
		empty.Parent = boardScroll
		return
	end
	for i, row in leaderboardRows do
		local t = Instance.new("TextLabel")
		t.Size = UDim2.new(1, -4, 0, 32)
		t.BackgroundColor3 = Color3.fromRGB(28, 28, 42)
		t.Font = Enum.Font.GothamMedium
		t.TextSize = 15
		t.TextColor3 = i == 1 and COLORS.Coin or Color3.fromRGB(220, 220, 240)
		t.TextXAlignment = Enum.TextXAlignment.Left
		t.Text = string.format("  #%d  %s  —  %s", i, row.name or "?", FormatUtil.Time(row.time or 0))
		t.Parent = boardScroll
		corner(t, 8)
	end
end

-- Settings
local settingsPanel, settingsBody, settingsClose =
	makeModal("SettingsPanel", "Settings", UDim2.new(0, 320, 0, 260))
settingsPanel:SetAttribute("IsModal", true)

local function makeToggle(label: string, key: string, y: number)
	local row = Instance.new("TextButton")
	row.Position = UDim2.new(0, 0, 0, y)
	row.Size = UDim2.new(1, 0, 0, 44)
	row.BackgroundColor3 = Color3.fromRGB(28, 28, 42)
	row.Font = Enum.Font.GothamBold
	row.TextSize = 16
	row.TextColor3 = Color3.new(1, 1, 1)
	row.TextXAlignment = Enum.TextXAlignment.Left
	row.Parent = settingsBody
	corner(row, 10)
	pad(row, 12)

	local function redraw()
		local on = settings[key] == true
		row.Text = string.format("%s: %s", label, on and "ON" or "OFF")
		row.BackgroundColor3 = on and Color3.fromRGB(40, 80, 60) or Color3.fromRGB(28, 28, 42)
	end
	redraw()
	row.MouseButton1Click:Connect(function()
		settings[key] = not settings[key]
		redraw()
		SettingsUpdate:FireServer(settings)
		refreshMusic()
		playSfx("Click")
	end)
	return redraw
end

local redrawMusic = makeToggle("Music", "music", 0)
local redrawSfx = makeToggle("SFX", "sfx", 52)
local redrawFx = makeToggle("Reduce FX", "reduceFx", 104)

local verLabel = Instance.new("TextLabel")
verLabel.Position = UDim2.new(0, 0, 0, 160)
verLabel.Size = UDim2.new(1, 0, 0, 30)
verLabel.BackgroundTransparency = 1
verLabel.Font = Enum.Font.Gotham
verLabel.TextSize = 13
verLabel.TextColor3 = Color3.fromRGB(140, 140, 160)
verLabel.Text = ObbyConfig.GameName .. " v" .. ObbyConfig.Version
verLabel.Parent = settingsBody

-- Tutorial overlay
local tutPanel = Instance.new("Frame")
tutPanel.Name = "Tutorial"
tutPanel.AnchorPoint = Vector2.new(0.5, 1)
tutPanel.Position = UDim2.new(0.5, 0, 1, -80)
tutPanel.Size = UDim2.new(0, 420, 0, 130)
tutPanel.BackgroundColor3 = Color3.fromRGB(20, 18, 40)
tutPanel.BackgroundTransparency = 0.05
tutPanel.Visible = false
tutPanel.Parent = gui
corner(tutPanel, 14)
stroke(tutPanel, COLORS.Aura, 2)
pad(tutPanel, 14)

local tutTitle = Instance.new("TextLabel")
tutTitle.BackgroundTransparency = 1
tutTitle.Size = UDim2.new(1, 0, 0, 24)
tutTitle.Font = Enum.Font.GothamBold
tutTitle.TextSize = 18
tutTitle.TextColor3 = COLORS.Aura
tutTitle.TextXAlignment = Enum.TextXAlignment.Left
tutTitle.Text = ""
tutTitle.Parent = tutPanel

local tutBody = Instance.new("TextLabel")
tutBody.BackgroundTransparency = 1
tutBody.Position = UDim2.new(0, 0, 0, 28)
tutBody.Size = UDim2.new(1, 0, 0, 50)
tutBody.Font = Enum.Font.Gotham
tutBody.TextSize = 14
tutBody.TextColor3 = Color3.fromRGB(220, 220, 235)
tutBody.TextWrapped = true
tutBody.TextXAlignment = Enum.TextXAlignment.Left
tutBody.Text = ""
tutBody.Parent = tutPanel

local tutNext = Instance.new("TextButton")
tutNext.AnchorPoint = Vector2.new(1, 1)
tutNext.Position = UDim2.new(1, 0, 1, 0)
tutNext.Size = UDim2.new(0, 110, 0, 36)
tutNext.BackgroundColor3 = Color3.fromRGB(120, 70, 200)
tutNext.Font = Enum.Font.GothamBold
tutNext.TextSize = 15
tutNext.TextColor3 = Color3.new(1, 1, 1)
tutNext.Text = "Next"
tutNext.Parent = tutPanel
corner(tutNext, 10)

local function showTutorialStep()
	local steps = TutorialConfig.Steps
	if tutorialStep < 1 or tutorialStep > #steps then
		tutPanel.Visible = false
		return
	end
	local step = steps[tutorialStep]
	tutTitle.Text = string.format("%s (%d/%d)", step.title, tutorialStep, #steps)
	tutBody.Text = step.body
	tutNext.Text = tutorialStep >= #steps and "Done" or "Next"
	tutPanel.Visible = true
end

tutNext.MouseButton1Click:Connect(function()
	playSfx("Click")
	if tutorialStep >= #TutorialConfig.Steps then
		tutPanel.Visible = false
		TutorialComplete:FireServer()
	else
		tutorialStep += 1
		showTutorialStep()
	end
end)

-- Panel open helpers
local function setOpen(panel: Frame, open: boolean)
	if open then
		finishPanel.Visible = false
		shopPanel.Visible = false
		questPanel.Visible = false
		boardPanel.Visible = false
		settingsPanel.Visible = false
		panel.Visible = true
	else
		panel.Visible = false
	end
end

shopBtn.MouseButton1Click:Connect(function()
	playSfx("Click")
	local open = not shopPanel.Visible
	setOpen(shopPanel, open)
	if open then
		refreshShop()
	end
end)
shopClose.MouseButton1Click:Connect(function()
	setOpen(shopPanel, false)
end)
finishShop.MouseButton1Click:Connect(function()
	setOpen(shopPanel, true)
	refreshShop()
end)

questBtn.MouseButton1Click:Connect(function()
	playSfx("Click")
	local open = not questPanel.Visible
	setOpen(questPanel, open)
	if open then
		refreshQuests()
	end
end)
questClose.MouseButton1Click:Connect(function()
	setOpen(questPanel, false)
end)

boardBtn.MouseButton1Click:Connect(function()
	playSfx("Click")
	local open = not boardPanel.Visible
	setOpen(boardPanel, open)
	if open then
		RequestLeaderboard:FireServer()
		refreshBoard()
	end
end)
boardClose.MouseButton1Click:Connect(function()
	setOpen(boardPanel, false)
end)

settingsBtn.MouseButton1Click:Connect(function()
	playSfx("Click")
	setOpen(settingsPanel, not settingsPanel.Visible)
end)
settingsClose.MouseButton1Click:Connect(function()
	setOpen(settingsPanel, false)
end)

local function requestRestart()
	finished = false
	finishPanel.Visible = false
	runStart = os.clock()
	RestartRequest:FireServer()
	showToast("Restarting run…", "info")
end

restartBtn.MouseButton1Click:Connect(requestRestart)
finishAgain.MouseButton1Click:Connect(requestRestart)

UserInputService.InputBegan:Connect(function(input, gp)
	if gp then
		return
	end
	if input.KeyCode == Enum.KeyCode.R then
		requestRestart()
	elseif input.KeyCode == Enum.KeyCode.B then
		local open = not shopPanel.Visible
		setOpen(shopPanel, open)
		if open then
			refreshShop()
		end
	elseif input.KeyCode == Enum.KeyCode.Q then
		local open = not questPanel.Visible
		setOpen(questPanel, open)
		if open then
			refreshQuests()
		end
	elseif input.KeyCode == Enum.KeyCode.T then
		local open = not boardPanel.Visible
		setOpen(boardPanel, open)
		if open then
			RequestLeaderboard:FireServer()
		end
	elseif input.KeyCode == Enum.KeyCode.P then
		setOpen(settingsPanel, not settingsPanel.Visible)
	end
end)

local function refreshTop()
	auraLabel.Text = "Aura: " .. FormatUtil.Compact(aura)
	coinLabel.Text = "Coins: " .. FormatUtil.Compact(coins)
	cpLabel.Text = "CP " .. tostring(checkpointIndex)
	weatherChip.Text = string.format(
		"%s%s",
		weatherLabel,
		weatherMult > 1 and string.format(" x%.2f", weatherMult) or ""
	)
end

RunService.RenderStepped:Connect(function()
	if finished then
		return
	end
	timeLabel.Text = "Time: " .. FormatUtil.Time(os.clock() - runStart)
end)

-- Orb pickup sparkles (local juice)
local function sparkAt(worldPos: Vector3)
	if settings.reduceFx then
		return
	end
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.Size = Vector3.new(0.4, 0.4, 0.4)
	p.Shape = Enum.PartType.Ball
	p.Material = Enum.Material.Neon
	p.Color = COLORS.Aura
	p.Position = worldPos
	p.Transparency = 0.2
	p.Parent = workspace
	TweenService:Create(p, TweenInfo.new(0.45), {
		Transparency = 1,
		Size = Vector3.new(2.5, 2.5, 2.5),
		Position = worldPos + Vector3.new(0, 2, 0),
	}):Play()
	task.delay(0.5, function()
		p:Destroy()
	end)
end

-- Remotes
Toast.OnClientEvent:Connect(function(text, kind)
	if type(text) == "string" then
		showToast(text, kind)
	end
end)

PlaySound.OnClientEvent:Connect(function(name)
	if type(name) == "string" then
		playSfx(name)
	end
end)

AuraUpdate.OnClientEvent:Connect(function(a, c)
	aura = tonumber(a) or aura
	coins = tonumber(c) or coins
	refreshTop()
	if shopPanel.Visible then
		refreshShop()
	end
end)

StatsUpdate.OnClientEvent:Connect(function(snap)
	if type(snap) ~= "table" then
		return
	end
	aura = snap.aura or aura
	coins = snap.coins or coins
	bestTime = snap.bestTime
	equippedTrail = snap.equippedTrail or equippedTrail
	if type(snap.unlocked) == "table" then
		unlocked = snap.unlocked
	end
	checkpointIndex = snap.checkpointIndex or checkpointIndex
	if type(snap.settings) == "table" then
		settings.music = snap.settings.music ~= false
		settings.sfx = snap.settings.sfx ~= false
		settings.reduceFx = snap.settings.reduceFx == true
		redrawMusic()
		redrawSfx()
		redrawFx()
		refreshMusic()
	end
	if snap.loginStreak then
		streakLabel.Text = "Streak: " .. tostring(snap.loginStreak)
	end
	if snap.weatherLabel then
		weatherLabel = snap.weatherLabel
		weatherMult = snap.weatherMult or 1
	end
	if snap.finished then
		finished = true
	end
	refreshTop()
	if shopPanel.Visible then
		refreshShop()
	end
end)

FinishEv.OnClientEvent:Connect(function(payload)
	if type(payload) ~= "table" then
		return
	end
	finished = true
	local t = payload.time or 0
	bestTime = payload.bestTime
	aura = payload.aura or aura
	coins = payload.coins or coins
	refreshTop()
	finishBody.Text = string.format(
		"Time: %s\nBest: %s%s\n\n+%d Aura   +%d Coins\n\nBanked Aura: %s",
		FormatUtil.Time(t),
		bestTime and FormatUtil.Time(bestTime) or "—",
		payload.isBest and "  ★" or "",
		payload.bonusAura or 0,
		payload.bonusCoins or 0,
		FormatUtil.Comma(aura)
	)
	finishPanel.Visible = true
	if not settings.reduceFx then
		-- flash
		local cc = Instance.new("ColorCorrectionEffect")
		cc.Brightness = 0.4
		cc.Parent = Lighting
		TweenService:Create(cc, TweenInfo.new(0.6), { Brightness = 0 }):Play()
		task.delay(0.7, function()
			cc:Destroy()
		end)
	end
end)

CosmeticResult.OnClientEvent:Connect(function(ok, msg)
	showToast(tostring(msg), ok and "good" or "warn")
	task.defer(refreshShop)
end)

AchievementUnlocked.OnClientEvent:Connect(function(info)
	if type(info) ~= "table" then
		return
	end
	showToast("★ " .. tostring(info.name), "good")
	local banner = Instance.new("Frame")
	banner.AnchorPoint = Vector2.new(0.5, 0)
	banner.Position = UDim2.new(0.5, 0, 0, 90)
	banner.Size = UDim2.new(0, 320, 0, 64)
	banner.BackgroundColor3 = Color3.fromRGB(40, 30, 70)
	banner.Parent = gui
	corner(banner, 12)
	stroke(banner, COLORS.Aura, 2)
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.fromScale(1, 1)
	t.Font = Enum.Font.GothamBold
	t.TextSize = 18
	t.TextColor3 = COLORS.Aura
	t.Text = "Achievement\n" .. tostring(info.name)
	t.Parent = banner
	task.delay(3.2, function()
		banner:Destroy()
	end)
end)

QuestUpdate.OnClientEvent:Connect(function(snap)
	questSnap = snap
	if questPanel.Visible then
		refreshQuests()
	end
end)

QuestResult.OnClientEvent:Connect(function(ok, msg)
	showToast(tostring(msg), ok and "good" or "warn")
end)

WeatherUpdate.OnClientEvent:Connect(function(info)
	if type(info) ~= "table" then
		return
	end
	weatherLabel = info.label or weatherLabel
	weatherMult = info.auraMult or 1
	refreshTop()
end)

LeaderboardUpdate.OnClientEvent:Connect(function(rows)
	if type(rows) == "table" then
		leaderboardRows = rows
		if boardPanel.Visible then
			refreshBoard()
		end
	end
end)

OfflineReward.OnClientEvent:Connect(function(info)
	if type(info) ~= "table" then
		return
	end
	showToast(
		string.format("AFK rewards: +%d Aura, +%d Coins (%s)", info.aura or 0, info.coins or 0, info.label or ""),
		"aura"
	)
end)

TutorialState.OnClientEvent:Connect(function(done)
	if done then
		return
	end
	tutorialStep = 1
	showTutorialStep()
end)

refreshTop()
showToast(ObbyConfig.GameName .. " · B shop · Q quests · T times · P settings", "aura")
print("[ObbyClient] HUD ready")
