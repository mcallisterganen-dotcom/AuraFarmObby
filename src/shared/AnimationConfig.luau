-- Animation IDs + blend tuning (Anima-inspired).
-- Uses Roblox stock locomotion IDs so it works without custom uploads.

local AnimationConfig = {}

-- Stock R15-ish locomotion (widely used defaults)
AnimationConfig.Animations = {
	Idle = "rbxassetid://507766666",
	Walk = "rbxassetid://507777826",
	Run = "rbxassetid://507767714",
	Jump = "rbxassetid://507765000",
	Fall = "rbxassetid://507767968",
	Climb = "rbxassetid://507765644",
	Swim = "rbxassetid://507784897",
	-- Emotes (also listed under CosmeticsSystem)
	Victory = "rbxassetid://507770239",
	Dance = "rbxassetid://507771019",
	Cheer = "rbxassetid://507770677",
}

AnimationConfig.Blending = {
	WalkThreshold = 0.5,
	RunThreshold = 12,
	MaxRunSpeed = 24,
	BlendRate = 0.15,
	WalkSpeed = 1.0,
	RunSpeed = 1.1,
	JumpFade = 0.15,
}

AnimationConfig.Priorities = {
	Movement = Enum.AnimationPriority.Movement,
	Action = Enum.AnimationPriority.Action,
	Emote = Enum.AnimationPriority.Action4,
}

return AnimationConfig
