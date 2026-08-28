-- Sprint / crouch / slide tuning (parkour feel without replacing default Humanoid move).

local MovementConfig = {}

MovementConfig.BaseWalkSpeed = 16
MovementConfig.SprintMultiplier = 1.45
MovementConfig.CrouchWalkSpeed = 8

MovementConfig.Sliding = {
	Enabled = true,
	SpeedBoost = 22,
	Duration = 0.55,
	Cooldown = 0.85,
	MinForwardSpeed = 8,
}

MovementConfig.Jump = {
	Power = 50,
}

MovementConfig.Crouch = {
	Enabled = true,
	HipHeightDelta = -1.0,
}

MovementConfig.Camera = {
	NormalFOV = 70,
	SprintFOV = 78,
	SlideFOV = 88,
	TweenSpeed = 0.18,
}

return MovementConfig
