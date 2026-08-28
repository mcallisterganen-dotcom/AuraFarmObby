-- Aura Farm Obby — shared constants (client + server)

local ObbyConfig = {}

ObbyConfig.GameName = "Aura Farm Obby"

-- Folder / tag names used in Workspace
ObbyConfig.StageFolderName = "AuraFarmStage"
ObbyConfig.CheckpointTag = "Checkpoint"
ObbyConfig.KillTag = "KillBrick"
ObbyConfig.FinishTag = "Finish"
ObbyConfig.StartTag = "Start"
ObbyConfig.OrbTag = "AuraOrb"
ObbyConfig.MoverTag = "Mover"

-- Gameplay
ObbyConfig.OrbAuraValue = 5
ObbyConfig.ClearAuraReward = 50
ObbyConfig.ClearCoinReward = 25
ObbyConfig.NoDeathBonusAura = 30
ObbyConfig.NoDeathBonusCoins = 15
ObbyConfig.AllOrbsBonusAura = 20
ObbyConfig.AllOrbsBonusCoins = 10

-- Respawn
ObbyConfig.RespawnImmunitySeconds = 0.75

-- UI colors
ObbyConfig.Colors = {
	Aura = Color3.fromRGB(180, 120, 255),
	Coins = Color3.fromRGB(255, 210, 80),
	Good = Color3.fromRGB(80, 220, 140),
	Bad = Color3.fromRGB(255, 90, 90),
	Panel = Color3.fromRGB(18, 18, 28),
}

return ObbyConfig
