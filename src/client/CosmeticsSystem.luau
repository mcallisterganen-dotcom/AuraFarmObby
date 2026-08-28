-- CosmeticsSystem.luau
-- Handles cosmetic skins, trails, and visual customization

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local CosmeticsSystem = {}
CosmeticsSystem.__index = CosmeticsSystem

-- Available cosmetics
CosmeticsSystem.Cosmetics = {
    AuraSkins = {
        Default = {
            Name = "Default Aura",
            Color = Color3.fromRGB(100, 150, 255),
            Rarity = "Common",
            Particles = "AuraEffect_default",
        },
        Gold = {
            Name = "Golden Aura",
            Color = Color3.fromRGB(255, 200, 0),
            Rarity = "Rare",
            Particles = "AuraEffect_gold",
        },
        Crimson = {
            Name = "Crimson Aura",
            Color = Color3.fromRGB(255, 50, 50),
            Rarity = "Epic",
            Particles = "AuraEffect_crimson",
        },
        Mystic = {
            Name = "Mystic Aura",
            Color = Color3.fromRGB(200, 100, 255),
            Rarity = "Legendary",
            Particles = "AuraEffect_mystic",
        },
    },
    
    Trails = {
        None = { Name = "No Trail", Enabled = false },
        Sparkle = {
            Name = "Sparkle Trail",
            Texture = "rbxasset://textures/Particles/sparkles_main.dds",
            Color = Color3.fromRGB(200, 200, 255),
            Lifetime = 0.5,
            Transparency = NumberSequence.new(0, 1),
        },
        Fire = {
            Name = "Fire Trail",
            Texture = "rbxasset://textures/Particles/fire_main.dds",
            Color = Color3.fromRGB(255, 100, 0),
            Lifetime = 0.8,
            Transparency = NumberSequence.new(0, 1),
        },
        Smoke = {
            Name = "Smoke Trail",
            Texture = "rbxasset://textures/Particles/smoke_main.dds",
            Color = Color3.fromRGB(150, 150, 150),
            Lifetime = 1.0,
            Transparency = NumberSequence.new(0.2, 1),
        },
    },
    
    Emotes = {
        Victory = { Name = "Victory", Animation = "rbxassetid://507770818", Duration = 3 },
        Dance = { Name = "Dance", Animation = "rbxassetid://507771019", Duration = 5 },
        Cheer = { Name = "Cheer", Animation = "rbxassetid://507771383", Duration = 2 },
    },
}

-- Create cosmetics system
function CosmeticsSystem.new(character: Model, animationSystem)
    local self = setmetatable({}, CosmeticsSystem)
    
    self.character = character
    self.humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    self.animationSystem = animationSystem
    
    self.equippedAuraSkin = "Default"
    self.equippedTrail = "None"
    self.equippedEmotes = {}
    
    self.trailConnection = nil
    
    return self
end

-- Equip an aura skin cosmetic
function CosmeticsSystem:EquipAuraSkin(skinName: string)
    if not self.Cosmetics.AuraSkins[skinName] then
        warn("Aura skin not found: " .. skinName)
        return false
    end
    
    local skin = self.Cosmetics.AuraSkins[skinName]
    self.equippedAuraSkin = skinName
    
    -- Update particle effects on all parts
    self:_updateAuraEffect()
    
    return true
end

-- Equip a trail cosmetic
function CosmeticsSystem:EquipTrail(trailName: string)
    if not self.Cosmetics.Trails[trailName] then
        warn("Trail not found: " .. trailName)
        return false
    end
    
    -- Stop existing trail
    if self.trailConnection then
        self.trailConnection:Disconnect()
    end
    
    self.equippedTrail = trailName
    
    if trailName == "None" then
        return true
    end
    
    local trailConfig = self.Cosmetics.Trails[trailName]
    
    -- Create trail behind player
    self.trailConnection = RunService.Heartbeat:Connect(function()
        self:_updateTrail(trailConfig)
    end)
    
    return true
end

-- Play an emote
function CosmeticsSystem:PlayEmote(emoteName: string)
    if not self.Cosmetics.Emotes[emoteName] then
        warn("Emote not found: " .. emoteName)
        return false
    end
    
    if not self.animationSystem then
        return false
    end
    
    local emote = self.Cosmetics.Emotes[emoteName]
    self.animationSystem:PlayAction(emoteName)
    
    task.delay(emote.Duration, function()
        if self.animationSystem then
            self.animationSystem:ResumeMovement()
        end
    end)
    
    return true
end

-- Update aura effects based on equipped skin
function CosmeticsSystem:_updateAuraEffect()
    local skin = self.Cosmetics.AuraSkins[self.equippedAuraSkin]
    if not skin then return end
    
    -- Remove old aura effects
    for _, part in ipairs(self.character:GetDescendants()) do
        if part:FindFirstChild("AuraEffect_" .. self.equippedAuraSkin) then
            part:FindFirstChild("AuraEffect_" .. self.equippedAuraSkin):Destroy()
        end
    end
    
    -- Add new aura effect to torso and humanoid root part
    for _, part in ipairs({self.character:FindFirstChild("Torso"), self.humanoidRootPart}) do
        if part then
            local emitter = Instance.new("ParticleEmitter")
            emitter.Name = "AuraEffect_" .. self.equippedAuraSkin
            emitter.Texture = "rbxasset://textures/Particles/smoke_main.dds"
            emitter.Color = ColorSequence.new(skin.Color)
            emitter.LightEmission = 0.6
            emitter.Lifetime = NumberRange.new(2, 3)
            emitter.Rate = 10
            emitter.Transparency = NumberSequence.new(0.2, 1)
            emitter.Speed = NumberRange.new(1, 2)
            emitter.Parent = part
        end
    end
end

-- Update trail effect
function CosmeticsSystem:_updateTrail(trailConfig: table)
    if not self.humanoidRootPart or not self.character.Parent then
        return
    end
    
    -- Create trail attachment if it doesn't exist
    if not self.humanoidRootPart:FindFirstChild("TrailAttach") then
        local attachment = Instance.new("Attachment")
        attachment.Name = "TrailAttach"
        attachment.Parent = self.humanoidRootPart
        
        local trail = Instance.new("Trail")
        trail.Attachment0 = attachment
        trail.Attachment1 = attachment
        trail.MinLength = 0
        trail.Lifetime = trailConfig.Lifetime
        trail.Color = ColorSequence.new(trailConfig.Color)
        trail.Transparency = trailConfig.Transparency or NumberSequence.new(0, 1)
        trail.Parent = attachment
    end
end

-- Get equipped cosmetics info
function CosmeticsSystem:GetEquipped()
    return {
        AuraSkin = self.equippedAuraSkin,
        Trail = self.equippedTrail,
    }
end

-- Cleanup
function CosmeticsSystem:Destroy()
    if self.trailConnection then
        self.trailConnection:Disconnect()
    end
end

return CosmeticsSystem
