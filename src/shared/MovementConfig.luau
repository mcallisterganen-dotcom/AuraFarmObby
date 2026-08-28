-- Sprint / crouch / slide — snappy parkour feel.

local MovementConfig = {}

MovementConfig.BaseWalkSpeed = 16
MovementConfig.SprintMultiplier = 1.55 -- ~24.8
MovementConfig.CrouchMultiplier = 0.55
MovementConfig.SlideDuration = 0.55
MovementConfig.SlideSpeedBoost = 1.35
MovementConfig.SlideCooldown = 0.85
MovementConfig.JumpCooldown = 50
MovementConfig.SprintFovBoost = 8
MovementConfig.CrouchHipHeight = 0.5 -- relative adjust if supported

-- Camera
MovementConfig.Camera = {
	SprintFov = 78,
	DefaultFov = 70,
	TweenSpeed = 0.18,
}

return MovementConfig
