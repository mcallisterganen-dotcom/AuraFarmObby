-- Boots Animation + Cosmetics + Graphics + Movement and wires them to the obby.
-- Keybinds avoid ObbyClient: R restart, B shop, Q quests, T times, P settings.

print("[PlayerClient] Starting")

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local scripts = script.Parent

local AnimationSystem = require(scripts:WaitForChild("AnimationSystem"))
local CosmeticsSystem = require(scripts:WaitForChild("CosmeticsSystem"))
local GraphicsSystem = require(scripts:WaitForChild("GraphicsSystem"))
local MovementSystem = require(scripts:WaitForChild("MovementSystem"))

local anim: any = nil
local cosmetics: any = nil
local movement: any = nil
local graphics = GraphicsSystem.new()

local function toast(msg: string)
	pcall(function()
		StarterGui:SetCore("SendNotification", {
			Title = "Aura Farm",
			Text = msg,
			Duration = 2,
		})
	end)
	print("[PlayerClient]", msg)
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
	cosmetics = CosmeticsSystem.new(char, anim)
	movement = MovementSystem.new(char, hum, hrp)
	print("[PlayerClient] Systems bound for", char.Name)
end

if player.Character then
	task.spawn(bindCharacter, player.Character)
end
player.CharacterAdded:Connect(bindCharacter)

-- Keybinds (non-conflicting with Obby HUD)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	if input.KeyCode == Enum.KeyCode.E then
		if cosmetics then
			local name = cosmetics:PlayNextEmote()
			if name then
				toast("Emote: " .. name)
			end
		end
	elseif input.KeyCode == Enum.KeyCode.Y then
		if cosmetics then
			local name = cosmetics:CycleAura()
			toast("Aura skin: " .. name)
		end
	elseif input.KeyCode == Enum.KeyCode.G then
		local name = graphics:Cycle()
		toast("Graphics: " .. name)
	elseif input.KeyCode == Enum.KeyCode.H then
		if cosmetics then
			cosmetics:SetEnabled(true)
			toast("Aura particles ON")
		end
	end
end)

-- Hook remotes when HUD folder appears
task.spawn(function()
	local folder = ReplicatedStorage:WaitForChild("ObbyRemotes", 30)
	if not folder then
		warn("[PlayerClient] ObbyRemotes not found — juice hooks skipped")
		return
	end

	local Finish = folder:WaitForChild("Finish") :: RemoteEvent
	local StatsUpdate = folder:WaitForChild("StatsUpdate") :: RemoteEvent
	local AchievementUnlocked = folder:FindFirstChild("AchievementUnlocked")

	Finish.OnClientEvent:Connect(function(_payload)
		if graphics then
			graphics:Flash(Color3.fromRGB(120, 255, 180), 0.2)
		end
		if anim then
			anim:PlayEmote("Victory")
		end
	end)

	StatsUpdate.OnClientEvent:Connect(function(snap)
		if type(snap) ~= "table" then
			return
		end
		if cosmetics and snap.equippedTrail then
			cosmetics:PulseTrailColor(snap.equippedTrail)
		end
		if type(snap.settings) == "table" and graphics then
			if snap.settings.reduceFx == true then
				graphics:SetReduced(true)
				if cosmetics then
					cosmetics:SetEnabled(false)
				end
			else
				graphics:SetReduced(false)
				if cosmetics then
					cosmetics:SetEnabled(true)
				end
			end
		end
	end)

	if AchievementUnlocked and AchievementUnlocked:IsA("RemoteEvent") then
		AchievementUnlocked.OnClientEvent:Connect(function()
			if graphics then
				graphics:Flash(Color3.fromRGB(200, 140, 255), 0.25)
			end
			if anim then
				anim:PlayEmote("Cheer")
			end
		end)
	end
end)

toast("FX ready · Shift sprint · C slide · Ctrl crouch · E/Y/G")
print("[PlayerClient] Ready")
