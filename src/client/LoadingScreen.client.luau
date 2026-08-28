-- First-join loading overlay until stage + remotes are ready.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local ContentProvider = game:GetService("ContentProvider")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local gui = Instance.new("ScreenGui")
gui.Name = "AuraFarmLoading"
gui.IgnoreGuiInset = true
gui.DisplayOrder = 1000
gui.ResetOnSpawn = false
gui.Parent = playerGui

local bg = Instance.new("Frame")
bg.Name = "BG"
bg.Size = UDim2.fromScale(1, 1)
bg.BackgroundColor3 = Color3.fromRGB(10, 10, 18)
bg.BorderSizePixel = 0
bg.Parent = gui

local title = Instance.new("TextLabel")
title.Name = "Title"
title.AnchorPoint = Vector2.new(0.5, 0.5)
title.Position = UDim2.fromScale(0.5, 0.42)
title.Size = UDim2.fromOffset(480, 56)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.TextSize = 36
title.TextColor3 = Color3.fromRGB(200, 160, 255)
title.Text = "Aura Farm Obby"
title.Parent = bg

local sub = Instance.new("TextLabel")
sub.Name = "Sub"
sub.AnchorPoint = Vector2.new(0.5, 0)
sub.Position = UDim2.new(0.5, 0, 0.42, 36)
sub.Size = UDim2.fromOffset(480, 28)
sub.BackgroundTransparency = 1
sub.Font = Enum.Font.Gotham
sub.TextSize = 16
sub.TextColor3 = Color3.fromRGB(180, 180, 200)
sub.Text = "Loading stage…"
sub.Parent = bg

local barBG = Instance.new("Frame")
barBG.Name = "BarBG"
barBG.AnchorPoint = Vector2.new(0.5, 0)
barBG.Position = UDim2.new(0.5, 0, 0.42, 80)
barBG.Size = UDim2.fromOffset(280, 8)
barBG.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
barBG.BorderSizePixel = 0
barBG.Parent = bg
local barCorner = Instance.new("UICorner")
barCorner.CornerRadius = UDim.new(1, 0)
barCorner.Parent = barBG

local bar = Instance.new("Frame")
bar.Name = "Bar"
bar.Size = UDim2.fromScale(0.05, 1)
bar.BackgroundColor3 = Color3.fromRGB(160, 100, 255)
bar.BorderSizePixel = 0
bar.Parent = barBG
local barFillCorner = Instance.new("UICorner")
barFillCorner.CornerRadius = UDim.new(1, 0)
barFillCorner.Parent = bar

local function setProgress(p: number, label: string?)
	p = math.clamp(p, 0, 1)
	bar.Size = UDim2.fromScale(p, 1)
	if label then
		sub.Text = label
	end
end

task.spawn(function()
	setProgress(0.1, "Connecting…")
	local shared = ReplicatedStorage:WaitForChild("Shared", 15)
	setProgress(0.35, "Shared modules…")
	if shared then
		pcall(function()
			ContentProvider:PreloadAsync({ shared })
		end)
	end
	setProgress(0.55, "Remotes…")
	ReplicatedStorage:WaitForChild("ObbyRemotes", 20)
	setProgress(0.75, "Stage…")
	-- Stage lives under Workspace once server builds it
	local deadline = os.clock() + 12
	while os.clock() < deadline do
		local stage = workspace:FindFirstChild("Stage1") or workspace:FindFirstChild("ObbyStage")
		if stage then
			break
		end
		-- also accept any folder with Finish attribute parts
		local found = false
		for _, c in workspace:GetChildren() do
			if c:IsA("Folder") and c:FindFirstChildWhichIsA("BasePart", true) then
				found = true
				break
			end
		end
		if found then
			break
		end
		task.wait(0.15)
	end
	setProgress(0.92, "Almost ready…")
	if not player.Character then
		player.CharacterAdded:Wait()
	end
	local char = player.Character
	if char then
		char:WaitForChild("Humanoid", 8)
	end
	setProgress(1, "Go!")
	task.wait(0.25)

	local tw = TweenService:Create(bg, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		BackgroundTransparency = 1,
	})
	title.TextTransparency = 0
	TweenService:Create(title, TweenInfo.new(0.4), { TextTransparency = 1 }):Play()
	TweenService:Create(sub, TweenInfo.new(0.4), { TextTransparency = 1 }):Play()
	TweenService:Create(barBG, TweenInfo.new(0.4), { BackgroundTransparency = 1 }):Play()
	TweenService:Create(bar, TweenInfo.new(0.4), { BackgroundTransparency = 1 }):Play()
	tw:Play()
	tw.Completed:Wait()
	gui:Destroy()
end)
