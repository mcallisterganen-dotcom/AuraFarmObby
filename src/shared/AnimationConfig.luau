-- Official Roblox R15 default animation asset IDs (Animate script catalog).
-- Source: Roblox default character Animate + DevForum R15 ID lists.

local AnimationConfig = {}

-- These are the standard R15 defaults shipped with characters.
AnimationConfig.Ids = {
	Idle = "rbxassetid://507766666",
	Idle2 = "rbxassetid://507766951",
	Walk = "rbxassetid://507777826",
	Run = "rbxassetid://507767714",
	Jump = "rbxassetid://507765000",
	Fall = "rbxassetid://507767968",
	Climb = "rbxassetid://507765644",
	Swim = "rbxassetid://507784897",
	SwimIdle = "rbxassetid://507785072",
	-- Emotes (built-in tool-free)
	Wave = "rbxassetid://507770239",
	Point = "rbxassetid://507770453",
	Dance = "rbxassetid://507771019",
	Dance2 = "rbxassetid://507776043",
	Dance3 = "rbxassetid://507777268",
	Laugh = "rbxassetid://507770818",
	Cheer = "rbxassetid://507770677",
}

AnimationConfig.EmoteList = { "Wave", "Point", "Dance", "Laugh", "Cheer" }

-- Blend / playback
AnimationConfig.FadeTime = 0.12
AnimationConfig.WalkSpeedThreshold = 0.5
AnimationConfig.RunSpeedThreshold = 18 -- humanoid WalkSpeed while sprinting
AnimationConfig.Priorities = {
	Idle = Enum.AnimationPriority.Idle,
	Walk = Enum.AnimationPriority.Movement,
	Run = Enum.AnimationPriority.Movement,
	Jump = Enum.AnimationPriority.Action,
	Fall = Enum.AnimationPriority.Movement,
	Emote = Enum.AnimationPriority.Action4,
}

return AnimationConfig
