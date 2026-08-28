-- Aura Farm Obby — shared constants (client + server)
-- Patterns inspired by tides-of-trade GameConfig: one tunable source of truth.

local ObbyConfig = {}

ObbyConfig.GameName = "Aura Farm Obby"
ObbyConfig.Version = "0.2.0"

-- Folder / tag names used in Workspace
ObbyConfig.StageFolderName = "AuraFarmStage1"
ObbyConfig.CheckpointTag = "Checkpoint"
ObbyConfig.KillTag = "KillBrick"
ObbyConfig.OrbTag = "AuraOrb"
ObbyConfig.FinishTag = "Finish"
ObbyConfig.MoverTag = "Mover"
ObbyConfig.StartTag = "Start"
ObbyConfig.StartSpawnName = "StageSpawn"

-- Economy / progression
ObbyConfig.OrbAuraValue = 5
ObbyConfig.FinishAuraBonus = 25
ObbyConfig.FinishCoinBonus = 10
ObbyConfig.CheckpointCoinBonus = 1
ObbyConfig.OrbCoinValue = 1
ObbyConfig.ComboWindowSec = 2.5 -- chain orb pickups for bonus aura
ObbyConfig.ComboBonusPerStep = 1 -- extra aura per combo step after 1

-- Gameplay
ObbyConfig.RestartCooldownSec = 1.25
ObbyConfig.KillDebounceSec = 0.85
ObbyConfig.FallY = -30
ObbyConfig.StartCFrame = CFrame.new(0, 18, 0)

-- DataStore
ObbyConfig.DataStoreName = "AuraFarmObby_v1"
ObbyConfig.DataStoreEnabled = true -- set false in Studio if API services off

-- Default saved profile shape
ObbyConfig.DefaultData = {
	aura = 0,
	coins = 0,
	bestTime = nil, -- seconds (number) or nil
	totalFinishes = 0,
	totalDeaths = 0,
	totalOrbs = 0,
	unlocked = { trail_starter = true },
	equippedTrail = "trail_starter",
	achievements = {},
}

-- Colors
ObbyConfig.Colors = {
	Aura = Color3.fromRGB(180, 120, 255),
	Coin = Color3.fromRGB(255, 200, 60),
	Checkpoint = Color3.fromRGB(255, 220, 50),
	Kill = Color3.fromRGB(220, 40, 40),
	Finish = Color3.fromRGB(80, 255, 140),
	Pad = Color3.fromRGB(60, 140, 255),
	UI = Color3.fromRGB(18, 18, 28),
	Good = Color3.fromRGB(100, 255, 160),
	Warn = Color3.fromRGB(255, 180, 80),
	Bad = Color3.fromRGB(255, 100, 110),
}

return ObbyConfig
