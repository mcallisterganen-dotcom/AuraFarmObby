-- IntegratedClient.client.luau
-- Master client script integrating ALL systems

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

print("[AuraFarmObby] Starting integrated client...")

-- Load all systems
local shared = ReplicatedStorage:WaitForChild("shared")
local client = ReplicatedStorage:WaitForChild("client")

local AnimationConfig = require(shared:WaitForChild("AnimationConfig"))
local MovementConfig = require(shared:WaitForChild("MovementConfig"))

local AnimationSystem = require(client:WaitForChild("AnimationSystem"))
local GraphicsSystem = require(client:WaitForChild("GraphicsSystem"))
local CosmeticsSystem = require(client:WaitForChild("CosmeticsSystem"))
local MovementSystem = require(client:WaitForChild("MovementSystem"))

-- Initialize all systems
print("[AuraFarmObby] Initializing Animation System...")
local animationSys = AnimationSystem.new(character, humanoid, humanoidRootPart)

print("[AuraFarmObby] Initializing Movement System...")
local movementSys = MovementSystem.new(character, humanoid, humanoidRootPart)

print("[AuraFarmObby] Initializing Graphics System...")
local graphicsSys = GraphicsSystem.new()
graphicsSys:ApplyPreset("AuraFarm", 1.0)

print("[AuraFarmObby] Initializing Cosmetics System...")
local cosmeticsSys = CosmeticsSystem.new(character, animationSys)

-- Handle character respawn
local function onCharacterAdded(newCharacter)
    character = newCharacter
    humanoid = character:WaitForChild("Humanoid")
    humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    
    -- Reinitialize all systems
    animationSys = AnimationSystem.new(character, humanoid, humanoidRootPart)
    movementSys = MovementSystem.new(character, humanoid, humanoidRootPart)
    cosmeticsSys = CosmeticsSystem.new(character, animationSys)
end

player.CharacterAdded:Connect(onCharacterAdded)

-- Input handling
local UserInputService = game:GetService("UserInputService")

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.E then
        -- Victory emote
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

print("[AuraFarmObby] ✓ All systems integrated and running!")
print("[AuraFarmObby] Controls:")
print("  WASD - Move (camera-relative)")
print("  SHIFT - Sprint (1.5x speed)")
print("  CTRL - Crouch")
print("  C - Slide (momentum-based)")
print("  SPACE - Jump")
print("  E - Victory Emote")
print("  R - Cycle Aura Skins")
print("  T - Cycle Trails")
print("  G - Cycle Graphics Presets")
