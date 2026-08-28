-- Aura Farm Obby — shared constants (client + server)

local ObbyConfig = {}

ObbyConfig.GameName = "Aura Farm Obby"
ObbyConfig.Version = "0.6.1"

-- World / spawn (legacy single-stage names still used as fallbacks)
ObbyConfig.StageFolderName = "AuraFarmStages"
ObbyConfig.StartSpawnName = "StartSpawn"
ObbyConfig.StartCFrame = CFrame.new(0, 16, 28)
ObbyConfig.LobbyCFrame = CFrame.new(0, 10, 40)

-- Gameplay tags (attributes on BaseParts)
ObbyConfig.CheckpointTag = "CheckpointIndex" -- number
ObbyConfig.FinishTag = "Finish" -- boolean
ObbyConfig.KillTag = "Kill" -- boolean
ObbyConfig.OrbTag = "Orb" -- boolean
ObbyConfig.BounceTag = "Bounce" -- number (upward velocity)
ObbyConfig.PortalTag = "PortalToStage" -- number
ObbyConfig.SelectStageTag = "SelectStage" -- number

-- Economy defaults (per-stage overrides in StageConfig)
ObbyConfig.OrbAura = 2
ObbyConfig.LuckyOrbChance = 0.08
ObbyConfig.LuckyOrbMult = 3
ObbyConfig.FinishAuraBonus = 25
ObbyConfig.FinishCoinBonus = 10
ObbyConfig.StartingAura = 0
ObbyConfig.StartingCoins = 0
ObbyConfig.ComboWindowSec = 4
ObbyConfig.ComboAuraBonus = 1 -- extra aura per combo step

-- Anti-cheat / run rules (stage can override)
ObbyConfig.MinFinishTimeSec = 10
ObbyConfig.MinCheckpointForFinish = 1
ObbyConfig.KillDebounceSec = 1.25
ObbyConfig.FinishTouchDebounceSec = 2
ObbyConfig.OrbTouchDebounceSec = 0.5
ObbyConfig.MaxFinishDistance = 18
ObbyConfig.RespawnInvulnSec = 1.5
ObbyConfig.DefaultStageId = 1

-- UI
ObbyConfig.ToastDuration = 3

ObbyConfig.Colors = {
	Aura = Color3.fromRGB(190, 140, 255),
	Good = Color3.fromRGB(120, 255, 160),
	Bad = Color3.fromRGB(255, 100, 110),
	Info = Color3.fromRGB(140, 180, 255),
	Coin = Color3.fromRGB(255, 210, 90),
	Finish = Color3.fromRGB(255, 220, 100),
}

return ObbyConfig
