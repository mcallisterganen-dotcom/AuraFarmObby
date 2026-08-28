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
	"OpenShop",
	-- v0.3
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
}

local function getFolder(): Folder
	local folder = ReplicatedStorage:FindFirstChild(FOLDER_NAME)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = FOLDER_NAME
		folder.Parent = ReplicatedStorage
	end
	return folder :: Folder
end

function Remotes.InitServer()
	local folder = getFolder()
	for _, name in EVENT_NAMES do
		if not folder:FindFirstChild(name) then
			local ev = Instance.new("RemoteEvent")
			ev.Name = name
			ev.Parent = folder
		end
	end
	return folder
end

function Remotes.WaitClient(timeout: number?): Folder
	return ReplicatedStorage:WaitForChild(FOLDER_NAME, timeout or 15) :: Folder
end

function Remotes.Get(name: string): RemoteEvent
	local folder = getFolder()
	local ev = folder:FindFirstChild(name)
	assert(ev and ev:IsA("RemoteEvent"), "Missing remote: " .. name)
	return ev :: RemoteEvent
end

return Remotes
