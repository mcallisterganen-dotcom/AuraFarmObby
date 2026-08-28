-- PlayerClient.client.luau
-- Main client script that initializes animation, graphics, and cosmetics systems

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

-- Ensure shared modules exist
local shared = ReplicatedStorage:WaitForChild("shared")
local AnimationConfig = require(shared:WaitForChild("AnimationConfig"))

-- Load client modules
local client = ReplicatedStorage:WaitForChild("client")
local AnimationSystem = require(client:WaitForChild("AnimationSystem"))
local GraphicsSystem = require(client:WaitForChild("GraphicsSystem"))
local CosmeticsSystem = require(client:WaitForChild("CosmeticsSystem"))

-- Initialize systems
print("[AuraFarmObby] Initializing client systems...")

local animationSys = AnimationSystem.new(character, humanoid, humanoidRootPart)
print("[AuraFarmObby] ✓ Animation System loaded")

local graphicsSys = GraphicsSystem.new()
graphicsSys:ApplyPreset("AuraFarm", 1.0)  -- Apply aura farm preset on load
print("[AuraFarmObby] ✓ Graphics System loaded")

local cosmeticsSys = CosmeticsSystem.new(character, animationSys)
print("[AuraFarmObby] ✓ Cosmetics System loaded")

-- Handle character respawn
local function onCharacterAdded(newCharacter)
    character = newCharacter
    humanoid = character:WaitForChild("Humanoid")
    humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    
    animationSys = AnimationSystem.new(character, humanoid, humanoidRootPart)
    cosmeticsSys = CosmeticsSystem.new(character, animationSys)
end

player.CharacterAdded:Connect(onCharacterAdded)

-- Example: Test cosmetics with key presses
local UserInputService = game:GetService("UserInputService")

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.E then
        -- Play victory emote
        cosmeticsSys:PlayEmote("Victory")
    elseif input.KeyCode == Enum.KeyCode.R then
        -- Cycle aura skins
        local skins = {"Default", "Gold", "Crimson", "Mystic"}
        local currentIndex = table.find(skins, cosmeticsSys.equippedAuraSkin) or 1
        local nextSkin = skins[(currentIndex % #skins) + 1]
        cosmeticsSys:EquipAuraSkin(nextSkin)
        print("[AuraFarmObby] Equipped: " .. nextSkin .. " Aura")
    elseif input.KeyCode == Enum.KeyCode.T then
        -- Cycle trails
        local trails = {"None", "Sparkle", "Fire", "Smoke"}
        local currentIndex = table.find(trails, cosmeticsSys.equippedTrail) or 1
        local nextTrail = trails[(currentIndex % #trails) + 1]
        cosmeticsSys:EquipTrail(nextTrail)
        print("[AuraFarmObby] Equipped: " .. nextTrail .. " Trail")
    elseif input.KeyCode == Enum.KeyCode.G then
        -- Cycle graphics presets
        local presets = {"AuraFarm", "Neon", "Cinematic", "Default"}
        local currentIndex = table.find(presets, graphicsSys.currentPreset) or 1
        local nextPreset = presets[(currentIndex % #presets) + 1]
        graphicsSys:ApplyPreset(nextPreset, 1.0)
        print("[AuraFarmObby] Applied: " .. nextPreset .. " Graphics")
    end
end)

print("[AuraFarmObby] Client initialized! Press E (emote), R (aura), T (trail), G (graphics)")
