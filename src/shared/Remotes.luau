-- Ensures all RemoteEvents exist (server creates, client waits).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = {}

local FOLDER_NAME = "ObbyRemotes"

local EVENT_NAMES = {
	"Toast",
	"AuraUpdate",
	"StatsUpdate",
	"Finish",
	"RestartRequest",
	"BuyCosmetic",
	"EquipCosmetic",
	"CosmeticResult",
	"AchievementUnlocked",
	"QuestUpdate",
	"ClaimQuest",
	"QuestResult",
	"WeatherUpdate",
	"LeaderboardUpdate",
	"RequestLeaderboard",
	"OfflineReward",
	"SettingsUpdate",
	"TutorialState",
	"TutorialComplete",
	"PlaySound",
	"StageUpdate",
	"SelectStageRequest",
}

function Remotes.InitServer()
	local folder = ReplicatedStorage:FindFirstChild(FOLDER_NAME)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = FOLDER_NAME
		folder.Parent = ReplicatedStorage
	end
	for _, name in EVENT_NAMES do
		if not folder:FindFirstChild(name) then
			local ev = Instance.new("RemoteEvent")
			ev.Name = name
			ev.Parent = folder
		end
	end
	return folder
end

function Remotes.GetFolder(): Folder
	local folder = ReplicatedStorage:WaitForChild(FOLDER_NAME) :: Folder
	return folder
end

function Remotes.Get(name: string): RemoteEvent
	local folder = Remotes.GetFolder()
	local ev = folder:WaitForChild(name)
	return ev :: RemoteEvent
end

return Remotes
