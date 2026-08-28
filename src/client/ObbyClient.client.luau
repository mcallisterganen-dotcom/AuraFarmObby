-- Aura Farm Obby — client HUD, shop, toasts, finish panel (PC + mobile)
-- UI patterns inspired by tides-of-trade NotificationController / UIUtil.

print("[ObbyClient] Starting")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ObbyConfig = require(Shared:WaitForChild("ObbyConfig"))
local CosmeticsCatalog = require(Shared:WaitForChild("CosmeticsCatalog"))
local RemotesMod = require(Shared:WaitForChild("Remotes"))

local remoteFolder = RemotesMod.WaitClient(20)
local Toast = remoteFolder:WaitForChild("Toast") :: RemoteEvent
local AuraUpdate = remoteFolder:WaitForChild("AuraUpdate") :: RemoteEvent
local StatsUpdate = remoteFolder:WaitForChild("StatsUpdate") :: RemoteEvent
local FinishEv = remoteFolder:WaitForChild("Finish") :: RemoteEvent
local RestartRequest = remoteFolder:WaitForChild("RestartRequest") :: RemoteEvent
local BuyCosmetic = remoteFolder:WaitForChild("BuyCosmetic") :: RemoteEvent
local EquipCosmetic = remoteFolder:WaitForChild("EquipCosmetic") :: RemoteEvent
local CosmeticResult = remoteFolder:WaitForChild("CosmeticResult") :: RemoteEvent
local AchievementUnlocked = remoteFolder:WaitForChild("AchievementUnlocked") :: RemoteEvent

-- State
local aura = 0
local coins = 0
local bestTime: number? = nil
local equippedTrail = "trail_starter"
local unlocked: { [string]: boolean } = { trail_starter = true }
local runStart = os.clock()
local finished = false
local checkpointIndex = 0

-- Root GUI
local gui = Instance.new("ScreenGui")
gui.Name = "AuraFarmHud"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local COLORS = ObbyConfig.Colors

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

-- Top bar
local top = Instance.new("Frame")
top.Name = "TopBar"
top.AnchorPoint = Vector2.new(0.5, 0)
top.Position = UDim2.new(0.5, 0, 0, 12)
top.Size = UDim2.new(0, 420, 0, 56)
top.BackgroundColor3 = COLORS.UI
top.BackgroundTransparency = 0.15
top.Parent = gui
corner(top, 14)
stroke(top, COLORS.Aura, 1.5)
pad(top, 10)

local topLayout = Instance.new("UIListLayout")
topLayout.FillDirection = Enum.FillDirection.Horizontal
topLayout.Padding = UDim.new(0, 12)
topLayout.VerticalAlignment = Enum.VerticalAlignment.Center
topLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
topLayout.Parent = top

local function makeStat(name: string, color: Color3): TextLabel
	local t = Instance.new("TextLabel")
	t.Name = name
	t.BackgroundTransparency = 1
	t.Size = UDim2.new(0, 120, 1, 0)
	t.Font = Enum.Font.GothamBold
	t.TextSize = 18
	t.TextColor3 = color
	t.Text = name .. ": 0"
	t.Parent = top
	return t
end

local auraLabel = makeStat("Aura", COLORS.Aura)
local coinLabel = makeStat("Coins", COLORS.Coin)
local timeLabel = makeStat("Time", Color3.fromRGB(220, 230, 255))
timeLabel.Size = UDim2.new(0, 130, 1, 0)

-- Checkpoint chip
local cpLabel = Instance.new("TextLabel")
cpLabel.Name = "Checkpoint"
cpLabel.AnchorPoint = Vector2.new(0, 0)
cpLabel.Position = UDim2.new(0, 16, 0, 76)
cpLabel.Size = UDim2.new(0, 160, 0, 28)
cpLabel.BackgroundColor3 = COLORS.UI
cpLabel.BackgroundTransparency = 0.2
cpLabel.Font = Enum.Font.GothamMedium
cpLabel.TextSize = 14
cpLabel.TextColor3 = COLORS.Checkpoint
cpLabel.Text = "CP 0"
cpLabel.Parent = gui
corner(cpLabel, 8)

-- Buttons column (right)
local btnCol = Instance.new("Frame")
btnCol.Name = "Buttons"
btnCol.AnchorPoint = Vector2.new(1, 0.5)
btnCol.Position = UDim2.new(1, -16, 0.5, 0)
btnCol.Size = UDim2.new(0, 120, 0, 160)
btnCol.BackgroundTransparency = 1
btnCol.Parent = gui

local btnLayout = Instance.new("UIListLayout")
btnLayout.Padding = UDim.new(0, 10)
btnLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
btnLayout.Parent = btnCol

local function makeButton(text: string, color: Color3): TextButton
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(1, 0, 0, 44)
	b.BackgroundColor3 = color
	b.Font = Enum.Font.GothamBold
	b.TextSize = 16
	b.TextColor3 = Color3.new(1, 1, 1)
	b.Text = text
	b.AutoButtonColor = true
	b.Parent = btnCol
	corner(b, 12)
	stroke(b, Color3.new(1, 1, 1), 1)
	return b
end

local shopBtn = makeButton("Shop", Color3.fromRGB(120, 70, 200))
local restartBtn = makeButton("Restart", Color3.fromRGB(70, 90, 140))

-- Toast stack
local toastFrame = Instance.new("Frame")
toastFrame.Name = "Toasts"
toastFrame.AnchorPoint = Vector2.new(0.5, 1)
toastFrame.Position = UDim2.new(0.5, 0, 1, -24)
toastFrame.Size = UDim2.new(0, 360, 0, 200)
toastFrame.BackgroundTransparency = 1
toastFrame.Parent = gui

local toastLayout = Instance.new("UIListLayout")
toastLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
toastLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
toastLayout.Padding = UDim.new(0, 6)
toastLayout.Parent = toastFrame
toastLayout.SortOrder = Enum.SortOrder.LayoutOrder

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
	local order = toastOrder
	local f = Instance.new("TextLabel")
	f.LayoutOrder = order
	f.Size = UDim2.new(1, 0, 0, 32)
	f.BackgroundColor3 = COLORS.UI
	f.BackgroundTransparency = 0.1
	f.Font = Enum.Font.GothamMedium
	f.TextSize = 15
	f.TextColor3 = kindColor[kind or "info"] or kindColor.info
	f.Text = text
	f.Parent = toastFrame
	corner(f, 8)
	f.TextTransparency = 1
	f.BackgroundTransparency = 1
	TweenService:Create(f, TweenInfo.new(0.2), { TextTransparency = 0, BackgroundTransparency = 0.15 }):Play()
	task.delay(2.4, function()
		local tw = TweenService:Create(f, TweenInfo.new(0.35), { TextTransparency = 1, BackgroundTransparency = 1 })
		tw:Play()
		tw.Completed:Wait()
		f:Destroy()
	end)
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

-- Shop panel
local shopPanel = Instance.new("Frame")
shopPanel.Name = "ShopPanel"
shopPanel.AnchorPoint = Vector2.new(0.5, 0.5)
shopPanel.Position = UDim2.fromScale(0.5, 0.5)
shopPanel.Size = UDim2.new(0, 380, 0, 420)
shopPanel.BackgroundColor3 = COLORS.UI
shopPanel.BackgroundTransparency = 0.05
shopPanel.Visible = false
shopPanel.Parent = gui
corner(shopPanel, 16)
stroke(shopPanel, COLORS.Aura, 2)
pad(shopPanel, 14)

local shopTitle = Instance.new("TextLabel")
shopTitle.BackgroundTransparency = 1
shopTitle.Size = UDim2.new(1, -40, 0, 32)
shopTitle.Font = Enum.Font.GothamBold
shopTitle.TextSize = 22
shopTitle.TextColor3 = COLORS.Aura
shopTitle.Text = "Aura Shop — Trails"
shopTitle.TextXAlignment = Enum.TextXAlignment.Left
shopTitle.Parent = shopPanel

local shopClose = Instance.new("TextButton")
shopClose.AnchorPoint = Vector2.new(1, 0)
shopClose.Position = UDim2.new(1, 0, 0, 0)
shopClose.Size = UDim2.new(0, 36, 0, 36)
shopClose.BackgroundColor3 = Color3.fromRGB(80, 40, 50)
shopClose.Font = Enum.Font.GothamBold
shopClose.TextSize = 18
shopClose.TextColor3 = Color3.new(1, 1, 1)
shopClose.Text = "X"
shopClose.Parent = shopPanel
corner(shopClose, 8)

local shopScroll = Instance.new("ScrollingFrame")
shopScroll.Position = UDim2.new(0, 0, 0, 44)
shopScroll.Size = UDim2.new(1, 0, 1, -52)
shopScroll.BackgroundTransparency = 1
shopScroll.BorderSizePixel = 0
shopScroll.ScrollBarThickness = 6
shopScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
shopScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
shopScroll.Parent = shopPanel

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
			action.Active = false
		elseif owned then
			action.Text = "Equip"
			action.BackgroundColor3 = Color3.fromRGB(50, 120, 200)
			action.MouseButton1Click:Connect(function()
				EquipCosmetic:FireServer(def.id)
			end)
		else
			action.Text = def.priceAura > 0 and (tostring(def.priceAura) .. " Aura") or "Free"
			action.BackgroundColor3 = Color3.fromRGB(120, 70, 200)
			action.MouseButton1Click:Connect(function()
				BuyCosmetic:FireServer(def.id)
			end)
		end

		shopRows[def.id] = row
	end
end

local function setShopOpen(open: boolean)
	shopPanel.Visible = open
	if open then
		finishPanel.Visible = false
		refreshShop()
	end
end

shopBtn.MouseButton1Click:Connect(function()
	setShopOpen(not shopPanel.Visible)
end)
shopClose.MouseButton1Click:Connect(function()
	setShopOpen(false)
end)
finishShop.MouseButton1Click:Connect(function()
	setShopOpen(true)
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

-- Keyboard: R restart, B shop
UserInputService.InputBegan:Connect(function(input, gp)
	if gp then
		return
	end
	if input.KeyCode == Enum.KeyCode.R then
		requestRestart()
	elseif input.KeyCode == Enum.KeyCode.B then
		setShopOpen(not shopPanel.Visible)
	end
end)

local function formatTime(sec: number): string
	return string.format("%d:%05.2f", math.floor(sec / 60), sec % 60)
end

local function refreshTop()
	auraLabel.Text = "Aura: " .. tostring(aura)
	coinLabel.Text = "Coins: " .. tostring(coins)
	cpLabel.Text = "CP " .. tostring(checkpointIndex)
end

-- Timer
RunService.RenderStepped:Connect(function()
	if finished then
		return
	end
	local t = os.clock() - runStart
	timeLabel.Text = "Time: " .. formatTime(t)
end)

-- Remotes
Toast.OnClientEvent:Connect(function(text, kind)
	if type(text) == "string" then
		showToast(text, kind)
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
		"Time: %s\nBest: %s%s\n\n+%d Aura   +%d Coins\n\nBanked Aura: %d",
		formatTime(t),
		bestTime and formatTime(bestTime) or "—",
		payload.isBest and "  ★" or "",
		payload.bonusAura or 0,
		payload.bonusCoins or 0,
		aura
	)
	finishPanel.Visible = true
end)

CosmeticResult.OnClientEvent:Connect(function(ok, msg)
	showToast(tostring(msg), ok and "good" or "warn")
	if shopPanel.Visible then
		-- wait for StatsUpdate; soft refresh
		task.defer(refreshShop)
	end
end)

AchievementUnlocked.OnClientEvent:Connect(function(info)
	if type(info) ~= "table" then
		return
	end
	showToast("★ " .. tostring(info.name), "good")
	-- big banner
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

refreshTop()
showToast(ObbyConfig.GameName .. " ready — press B for shop", "aura")
print("[ObbyClient] HUD ready")
