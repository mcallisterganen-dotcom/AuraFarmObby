-- Boots Animation + Cosmetics + Graphics + Movement and wires them to the obby.
-- Keybinds avoid ObbyClient: R restart, B shop, Q quests, T times, P settings.

print("[PlayerClient] Starting")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local Shared = ReplicatedStorage:WaitForChild("Shared")

local AnimationSystem = require(script.Parent:WaitForChild("AnimationSystem"))
local CosmeticsSystem = require(script.Parent:WaitForChild("CosmeticsSystem"))
local GraphicsSystem = require(script.Parent:WaitForChild("GraphicsSystem"))
local MovementSystem = require(script.Parent:WaitForChild("MovementSystem"))
local AuraTheme = require(Shared:WaitForChild("AuraTheme"))

local graphics = GraphicsSystem.new()
local anim: any = nil
local cosmetics: any = nil
local movement: any = nil

local function toast(text: string)
	pcall(function()
		StarterGui:SetCore("SendNotification", {
			Title = "Aura Farm",
			Text = text,
			Duration = 2,
		})
	end)
end

local function bindCharacter(char: Model)
	if anim then
		anim:Destroy()
		anim = nil
	end
	if cosmetics then
		cosmetics:Destroy()
		cosmetics = nil
	end
	if movement then
		movement:Destroy()
		movement = nil
	end

	local hum = char:WaitForChild("Humanoid", 10) :: Humanoid?
	local hrp = char:WaitForChild("HumanoidRootPart", 10) :: BasePart?
	if not hum or not hrp then
		warn("[PlayerClient] Character missing Humanoid/HRP")
		return
	end

	anim = AnimationSystem.new(char, hum, hrp)
	cosmetics = CosmeticsSystem.new(char, hum, hrp)
	movement = MovementSystem.new(char, hum, hrp)
	print("[PlayerClient] Systems bound for", char.Name)
end

if player.Character then
	task.spawn(bindCharacter, player.Character)
end
player.CharacterAdded:Connect(bindCharacter)

-- Input
UserInputService.InputBegan:Connect(function(input, gp)
	if gp then
		return
	end
	if input.KeyCode == Enum.KeyCode.E then
		if anim then
			local name = anim:PlayNextEmote()
			if name then
				toast("Emote: " .. name)
			end
		end
	elseif input.KeyCode == Enum.KeyCode.Y then
		if cosmetics then
			cosmetics:PulseTrailColor()
			graphics:Flash(AuraTheme.Colors.Accent, 0.25)
			toast("Aura pulse")
		end
	elseif input.KeyCode == Enum.KeyCode.G then
		local name = graphics:Cycle()
		toast("Graphics: " .. name)
	end
end)

-- Wire remotes for juice
task.spawn(function()
	local folder = ReplicatedStorage:WaitForChild("ObbyRemotes", 30)
	if not folder then
		warn("[PlayerClient] Remotes not found — juice hooks skipped")
		return
	end

	local Finish = folder:WaitForChild("Finish") :: RemoteEvent
	local StatsUpdate = folder:WaitForChild("StatsUpdate") :: RemoteEvent
	local AchievementUnlocked = folder:FindFirstChild("AchievementUnlocked")

	Finish.OnClientEvent:Connect(function()
		if anim then
			anim:PlayEmote("Victory")
		end
		if cosmetics then
			cosmetics:PulseTrailColor()
		end
		graphics:Flash(AuraTheme.Colors.Gold, 0.35)
	end)

	StatsUpdate.OnClientEvent:Connect(function(snap)
		if type(snap) ~= "table" then
			return
		end
		if cosmetics and type(snap.equippedTrail) == "string" then
			cosmetics:SetTrailId(snap.equippedTrail)
		end
		if type(snap.settings) == "table" and snap.settings.reduceFx ~= nil then
			graphics:SetReduced(snap.settings.reduceFx == true)
			if cosmetics then
				cosmetics:SetEnabled(not snap.settings.reduceFx)
			end
		end
	end)

	if AchievementUnlocked and AchievementUnlocked:IsA("RemoteEvent") then
		AchievementUnlocked.OnClientEvent:Connect(function()
			if cosmetics then
				cosmetics:PulseTrailColor()
			end
			graphics:Flash(AuraTheme.Colors.AccentHot, 0.3)
		end)
	end
end)

toast("Shift sprint · Ctrl crouch · C slide · E/Y/G")

-- Server-driven emote pads (lobby)
player:GetAttributeChangedSignal("PlayEmote"):Connect(function()
	local name = player:GetAttribute("PlayEmote")
	if typeof(name) == "string" and anim then
		anim:PlayEmote(name)
	end
end)

print("[PlayerClient] Ready")
