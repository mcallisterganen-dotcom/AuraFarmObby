-- Aura Farm Obby — shared constants (client + server)
-- Patterns inspired by tides-of-trade GameConfig: one tunable source of truth.

local ObbyConfig = {}

ObbyConfig.GameName = "Aura Farm Obby"
ObbyConfig.Version = "0.4.0"

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
ObbyConfig.ComboWindowSec = 2.5
ObbyConfig.ComboBonusPerStep = 1

-- Offline earnings (gear-clicker style AFK drip)
ObbyConfig.OfflineMinSec = 120
ObbyConfig.OfflineMaxSec = 6 * 3600
ObbyConfig.OfflineAuraPerHour = 12
ObbyConfig.OfflineCoinsPerHour = 4

-- Gameplay
ObbyConfig.RestartCooldownSec = 1.25
ObbyConfig.MinFinishTimeSec = 8 -- reject impossibly fast clears
ObbyConfig.MinCheckpointForFinish = 1 -- must touch at least one CP (0 = start only stages)
ObbyConfig.KillDebounceSec = 0.85
ObbyConfig.FallY = -5
ObbyConfig.StartCFrame = CFrame.new(0, 28, 6)

-- DataStore
ObbyConfig.DataStoreName = "AuraFarmObby_v2"
ObbyConfig.OrderedBestTimeName = "AuraFarm_BestTime_v1"
ObbyConfig.DataStoreEnabled = true

-- Default saved profile shape
ObbyConfig.DefaultData = {
	aura = 0,
	coins = 0,
	bestTime = nil,
	totalFinishes = 0,
	totalDeaths = 0,
	totalOrbs = 0,
	unlocked = { trail_starter = true },
	equippedTrail = "trail_starter",
	achievements = {},
	-- dailies / streak
	loginStreak = 0,
	lastLoginAt = nil,
	dailyYmd = nil,
	dailyQuestIds = {},
	dailyProgress = { finish = 0, orb = 0, death = 0, checkpoint = 0, play_minutes = 0 },
	dailyClaimed = {},
	streakClaimedYmd = nil,
	lastSeenAt = nil,
	-- meta
	tutorialDone = false,
	settings = {
		music = true,
		sfx = true,
		reduceFx = false,
	},
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
