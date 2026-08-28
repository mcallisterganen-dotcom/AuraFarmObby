-- MovementConfig.luau
-- Configuration for physics-based movement system

local MovementConfig = {}

-- Base movement speeds
MovementConfig.BaseWalkSpeed = 16
MovementConfig.MaxRunSpeed = 40
MovementConfig.SprintMultiplier = 1.5
MovementConfig.CrouchWalkSpeed = 8

-- Acceleration/Deceleration
MovementConfig.Acceleration = 70
MovementConfig.Deceleration = 35
MovementConfig.AirDeceleration = 15

-- Sliding physics
MovementConfig.Sliding = {
    Enabled = true,
    SpeedBoost = 30,           -- Speed gained when starting slide
    SpeedMultiplier = 1.5,     -- Sliding speed multiplier
    Deceleration = 28,         -- Decel while sliding on ground
    AirDeceleration = 15,      -- Decel while sliding in air
    MinSpeed = 6,              -- Minimum speed to maintain slide
    Cooldown = 0.3,            -- Cooldown between slides
    GroundControl = 0.4,       -- Control while sliding on ground
    AirControl = 0.25,         -- Control while sliding in air
    MaxAirTime = 3.0,          -- Max time sliding in air
}

-- Slope physics
MovementConfig.Slopes = {
    Enabled = true,
    Threshold = 0.15,          -- Angle threshold for slope detection
    Acceleration = 60,         -- Acceleration down slopes
    MaxSpeed = 100,            -- Max speed on slopes
    ControlPenalty = 0.7,      -- Control reduction on slopes
}

-- Momentum
MovementConfig.Momentum = {
    Enabled = true,
    RetainOnJump = true,
    JumpMultiplier = 1.3,      -- Multiplier for jump when moving
    AirDeceleration = 20,      -- Air decel with momentum
}

-- Jump mechanics
MovementConfig.Jump = {
    Power = 55,
    Cooldown = 0.2,            -- Minimum time between jumps
    DoubleJumpEnabled = false,  -- Double jump ability
    WallJumpEnabled = false,    -- Wall jump ability
}

-- Air strafing (in-air movement control)
MovementConfig.AirStrafe = {
    Enabled = true,
    Acceleration = 35,
    MaxSpeed = 15,
    Drag = 0.98,               -- Air resistance
}

-- Crouch system
MovementConfig.Crouch = {
    Enabled = true,
    WalkSpeed = 8,
    HipHeightDelta = -1.5,     -- Hip reduction when crouching
    CeilingCheck = true,       -- Check for ceiling when uncrouching
}

-- Camera settings
MovementConfig.Camera = {
    NormalFOV = 70,
    SlideFOV = 90,
    MaxSpeedFOV = 95,
    CrouchDrop = Vector3.new(0, -2.5, 0),  -- Camera offset when crouching
    StrafeRoll = math.rad(3.5),            -- Camera roll during strafing
    TweenSpeed = 0.15,                     -- Camera tween duration
}

-- Ground detection
MovementConfig.GroundDetection = {
    RaycastDistance = 5,
    Raycast = function()
        return RaycastParams.new()
    end
}

return MovementConfig
