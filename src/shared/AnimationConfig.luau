-- AnimationConfig.luau
-- Central configuration for all animation IDs and blending parameters

local AnimationConfig = {}

-- Animation IDs (Replace with your own or use placeholders)
AnimationConfig.Animations = {
    -- Movement Animations
    Idle = "rbxassetid://507766666",
    Walk = "rbxassetid://507777826",
    Run = "rbxassetid://507788054",
    Jump = "rbxassetid://507765000",
    Fall = "rbxassetid://507767968",
    Land = "rbxassetid://507768133",
    
    -- Victory/Celebration
    Victory = "rbxassetid://507770818",
    Dance = "rbxassetid://507771019",
    Cheer = "rbxassetid://507771383",
}

-- Blending Configuration
AnimationConfig.Blending = {
    -- Speed thresholds for gait transitions
    WalkThreshold = 0,      -- Speed at which idle transitions to walk
    RunThreshold = 6,       -- Speed at which walk transitions to run
    MaxRunSpeed = 20,       -- Maximum run speed for blending
    
    -- Blend timing (in seconds)
    BlendDuration = 0.15,   -- How long to blend between animations
    BlendRate = 0.1,        -- Per-frame blend rate
    
    -- Animation playback speeds (relative to authored speed)
    IdleSpeed = 1.0,
    WalkSpeed = 1.0,
    RunSpeed = 1.2,         -- Runs slightly faster for responsiveness
    JumpSpeed = 1.0,
}

-- Animation Priorities (higher = overrides lower)
AnimationConfig.Priorities = {
    Idle = Enum.AnimationPriority.Idle,
    Movement = Enum.AnimationPriority.Movement,
    Action = Enum.AnimationPriority.Action,      -- Jump, land, emotes
    Core = Enum.AnimationPriority.Core,          -- Victory sequences
}

-- Fade times for smooth transitions
AnimationConfig.FadeTimes = {
    Normal = 0.1,           -- Standard fade
    Quick = 0.05,           -- Fast fade for responsive actions
    Smooth = 0.2,           -- Slow fade for cinematic moments
}

return AnimationConfig
