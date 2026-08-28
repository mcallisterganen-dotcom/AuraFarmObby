-- GraphicsSystem.luau
-- Handles visual effects, shaders, and lighting

local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local GraphicsSystem = {}
GraphicsSystem.__index = GraphicsSystem

-- Preset configurations
GraphicsSystem.Presets = {
    Default = {
        Brightness = 2,
        Ambient = Color3.fromRGB(127, 127, 127),
        OutdoorAmbient = Color3.fromRGB(127, 127, 127),
        ClockTime = 14,
        GlobalShadows = true,
        EnvironmentDiffuseScale = 1,
        EnvironmentSpecularScale = 1,
        FogEnd = 100000,
    },
    
    Neon = {  -- Vibrant, high-energy look
        Brightness = 2.5,
        Ambient = Color3.fromRGB(100, 150, 255),
        OutdoorAmbient = Color3.fromRGB(100, 150, 255),
        ClockTime = 16,
        GlobalShadows = false,
        EnvironmentDiffuseScale = 0.5,
        EnvironmentSpecularScale = 1.5,
        FogEnd = 100000,
        Effects = {
            BloomEffect = { Intensity = 0.8, Size = 20, Threshold = 0.7 },
            ColorCorrectionEffect = { Saturation = 0.3, Contrast = 0.2, TintColor = Color3.fromRGB(200, 220, 255) },
        }
    },
    
    Cinematic = {  -- Dark, moody, professional
        Brightness = 1.5,
        Ambient = Color3.fromRGB(50, 50, 60),
        OutdoorAmbient = Color3.fromRGB(80, 80, 100),
        ClockTime = 17,
        GlobalShadows = true,
        EnvironmentDiffuseScale = 0.3,
        EnvironmentSpecularScale = 0.8,
        FogEnd = 100000,
        Effects = {
            BloomEffect = { Intensity = 0.5, Size = 15, Threshold = 0.8 },
            ColorCorrectionEffect = { Saturation = -0.2, Contrast = 0.3, TintColor = Color3.fromRGB(220, 200, 180) },
        }
    },
    
    AuraFarm = {  -- Optimized for aura visibility
        Brightness = 2.2,
        Ambient = Color3.fromRGB(150, 130, 180),
        OutdoorAmbient = Color3.fromRGB(150, 130, 180),
        ClockTime = 12,
        GlobalShadows = true,
        EnvironmentDiffuseScale = 0.6,
        EnvironmentSpecularScale = 1.2,
        FogEnd = 100000,
        Effects = {
            BloomEffect = { Intensity = 1.0, Size = 25, Threshold = 0.6 },
            ColorCorrectionEffect = { Saturation = 0.15, Contrast = 0.15, TintColor = Color3.fromRGB(220, 210, 240) },
        }
    },
}

-- Create graphics system
function GraphicsSystem.new()
    local self = setmetatable({}, GraphicsSystem)
    self.currentPreset = "Default"
    self.savedSettings = {}
    self.effects = {}
    return self
end

-- Apply a preset
function GraphicsSystem:ApplyPreset(presetName: string, tweenDuration: number?)
    tweenDuration = tweenDuration or 0.5
    
    local preset = self.Presets[presetName]
    if not preset then
        warn("Preset not found: " .. presetName)
        return
    end
    
    -- Save current settings
    if not self.savedSettings["Default"] then
        self.savedSettings["Default"] = {
            Brightness = Lighting.Brightness,
            Ambient = Lighting.Ambient,
            OutdoorAmbient = Lighting.OutdoorAmbient,
            ClockTime = Lighting.ClockTime,
        }
    end
    
    -- Tween lighting properties
    local tweenInfo = TweenInfo.new(
        tweenDuration,
        Enum.EasingStyle.Quad,
        Enum.EasingDirection.InOut
    )
    
    local tweenData = {
        Brightness = preset.Brightness,
        Ambient = preset.Ambient,
        OutdoorAmbient = preset.OutdoorAmbient,
    }
    
    local tween = TweenService:Create(Lighting, tweenInfo, tweenData)
    tween:Play()
    
    -- Apply non-tweened properties immediately
    Lighting.ClockTime = preset.ClockTime
    Lighting.GlobalShadows = preset.GlobalShadows
    Lighting.EnvironmentDiffuseScale = preset.EnvironmentDiffuseScale
    Lighting.EnvironmentSpecularScale = preset.EnvironmentSpecularScale
    Lighting.FogEnd = preset.FogEnd
    
    -- Remove old effects
    self:_clearEffects()
    
    -- Apply new effects
    if preset.Effects then
        self:_applyEffects(preset.Effects)
    end
    
    self.currentPreset = presetName
end

-- Apply post-processing effects
function GraphicsSystem:_applyEffects(effectsTable: table)
    for effectName, props in pairs(effectsTable) do
        local effect = Instance.new(effectName)
        
        -- Set properties
        for prop, value in pairs(props) do
            pcall(function()
                effect[prop] = value
            end)
        end
        
        effect.Parent = Lighting
        table.insert(self.effects, effect)
    end
end

-- Clear all effects
function GraphicsSystem:_clearEffects()
    for _, effect in ipairs(self.effects) do
        pcall(function()
            effect:Destroy()
        end)
    end
    self.effects = {}
end

-- Add particle effect to a part
function GraphicsSystem:AddAuraParticles(part: BasePart, auraColor: Color3, auraType: string?)
    auraType = auraType or "default"
    
    local emitter = Instance.new("ParticleEmitter")
    emitter.Name = "AuraEffect_" .. auraType
    emitter.Texture = "rbxasset://textures/Particles/smoke_main.dds"
    emitter.Color = ColorSequence.new(auraColor)
    emitter.LightEmission = 0.5
    emitter.Lifetime = NumberRange.new(2, 3)
    emitter.Rate = 15
    emitter.Rotation = NumberRange.new(0, 360)
    emitter.RotSpeed = NumberRange.new(-100, 100)
    emitter.Speed = NumberRange.new(2)
    emitter.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 0.5)})
    
    emitter.Parent = part
    return emitter
end

-- Add glow effect
function GraphicsSystem:AddGlowEffect(part: BasePart, glowColor: Color3, intensity: number?)
    intensity = intensity or 0.8
    
    -- Store original material
    local originalMaterial = part.Material
    
    -- Create a glow by adjusting properties
    part.Material = Enum.Material.Neon
    part.Color = glowColor
    
    -- Optional: Add a surface glow with a script (advanced)
    return { Material = originalMaterial, Color = part.Color }
end

-- Restore default graphics
function GraphicsSystem:RestoreDefault()
    self:ApplyPreset("Default", 1.0)
end

return GraphicsSystem
