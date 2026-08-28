-- On-screen Sprint / Slide for touch devices (desktop still uses keyboard).

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")

if not UserInputService.TouchEnabled then
	return
end

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Find MovementSystem via PlayerClient sibling pattern is awkward;
-- instead fire VirtualInput-like flags on the local player attributes
-- that MovementSystem already watches, OR simulate key holds via attributes.

local gui = Instance.new("ScreenGui")
gui.Name = "AuraFarmMobile"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 50
gui.Parent = playerGui

local function makeBtn(name: string, text: string, pos: UDim2, size: UDim2): TextButton
	local b = Instance.new("TextButton")
	b.Name = name
	b.Text = text
	b.Font = Enum.Font.GothamBold
	b.TextSize = 18
	b.TextColor3 = Color3.new(1, 1, 1)
	b.BackgroundColor3 = Color3.fromRGB(30, 30, 48)
	b.BackgroundTransparency = 0.25
	b.Size = size
	b.Position = pos
	b.AnchorPoint = Vector2.new(0.5, 0.5)
	b.Parent = gui
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 12)
	c.Parent = b
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(160, 100, 255)
	stroke.Thickness = 1.5
	stroke.Transparency = 0.4
	stroke.Parent = b
	return b
end

local sprint = makeBtn("Sprint", "SPRINT", UDim2.new(1, -90, 1, -150), UDim2.fromOffset(110, 56))
local slide = makeBtn("Slide", "SLIDE", UDim2.new(1, -90, 1, -80), UDim2.fromOffset(110, 56))
local crouch = makeBtn("Crouch", "CROUCH", UDim2.new(1, -210, 1, -80), UDim2.fromOffset(110, 56))

-- Attributes consumed by MovementSystem
local function setFlag(key: string, on: boolean)
	player:SetAttribute(key, on)
end

sprint.MouseButton1Down:Connect(function()
	setFlag("AF_Sprint", true)
end)
sprint.MouseButton1Up:Connect(function()
	setFlag("AF_Sprint", false)
end)
sprint.MouseLeave:Connect(function()
	setFlag("AF_Sprint", false)
end)

crouch.MouseButton1Down:Connect(function()
	setFlag("AF_Crouch", true)
end)
crouch.MouseButton1Up:Connect(function()
	setFlag("AF_Crouch", false)
end)
crouch.MouseLeave:Connect(function()
	setFlag("AF_Crouch", false)
end)

slide.MouseButton1Click:Connect(function()
	setFlag("AF_SlidePulse", true)
	task.defer(function()
		setFlag("AF_SlidePulse", false)
	end)
end)

pcall(function()
	StarterGui:SetCore("SendNotification", {
		Title = "Touch controls",
		Text = "Sprint / Crouch / Slide on the right",
		Duration = 3,
	})
end)
