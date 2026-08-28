-- Lightweight DataStore profile (tides ProfileService idea + gear-clicker lifecycle).
-- Session-safe: loads on join, autosaves, saves on leave.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local ObbyConfig = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("ObbyConfig"))

local PlayerData = {}

local profiles: { [number]: any } = {}
local dirty: { [number]: boolean } = {}
local store: DataStore? = nil
local storeReady = false

local function deepCopy(t)
	if type(t) ~= "table" then
		return t
	end
	local n = {}
	for k, v in t do
		n[k] = deepCopy(v)
	end
	return n
end

local function mergeDefaults(data: any)
	local d = deepCopy(ObbyConfig.DefaultData)
	if type(data) ~= "table" then
		return d
	end
	for k, v in data do
		if d[k] ~= nil or k == "bestTime" or k == "lastLoginAt" or k == "lastSeenAt" or k == "dailyYmd" or k == "streakClaimedYmd" then
			if type(v) == "table" and type(d[k]) == "table" then
				for k2, v2 in v do
					d[k][k2] = v2
				end
			else
				d[k] = v
			end
		end
	end
	if type(d.unlocked) ~= "table" then
		d.unlocked = { trail_starter = true }
	end
	d.unlocked.trail_starter = true
	if type(d.achievements) ~= "table" then
		d.achievements = {}
	end
	if type(d.settings) ~= "table" then
		d.settings = deepCopy(ObbyConfig.DefaultData.settings)
	end
	if type(d.dailyProgress) ~= "table" then
		d.dailyProgress = deepCopy(ObbyConfig.DefaultData.dailyProgress)
	end
	if type(d.dailyClaimed) ~= "table" then
		d.dailyClaimed = {}
	end
	if type(d.dailyQuestIds) ~= "table" then
		d.dailyQuestIds = {}
	end
	d.aura = math.max(0, math.floor(tonumber(d.aura) or 0))
	d.coins = math.max(0, math.floor(tonumber(d.coins) or 0))
	d.totalFinishes = math.max(0, math.floor(tonumber(d.totalFinishes) or 0))
	d.totalDeaths = math.max(0, math.floor(tonumber(d.totalDeaths) or 0))
	d.totalOrbs = math.max(0, math.floor(tonumber(d.totalOrbs) or 0))
	d.loginStreak = math.max(0, math.floor(tonumber(d.loginStreak) or 0))
	if d.bestTime ~= nil then
		d.bestTime = tonumber(d.bestTime)
	end
	if type(d.equippedTrail) ~= "string" then
		d.equippedTrail = "trail_starter"
	end
	d.tutorialDone = d.tutorialDone == true
	return d
end

local function keyFor(userId: number): string
	return "u_" .. tostring(userId)
end

function PlayerData.Init()
	if not ObbyConfig.DataStoreEnabled then
		print("[PlayerData] DataStore disabled in config — session-only")
		return
	end
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(ObbyConfig.DataStoreName)
	end)
	if ok and result then
		store = result
		storeReady = true
		print("[PlayerData] DataStore ready:", ObbyConfig.DataStoreName)
	else
		warn("[PlayerData] DataStore unavailable (Studio API off?) — session-only:", result)
	end
end

function PlayerData.Load(player: Player)
	local userId = player.UserId
	if profiles[userId] then
		return profiles[userId]
	end

	local loaded = nil
	if storeReady and store and userId > 0 then
		local ok, data = pcall(function()
			return store:GetAsync(keyFor(userId))
		end)
		if ok then
			loaded = data
		else
			warn("[PlayerData] GetAsync failed for", player.Name, data)
		end
	end

	local profile = mergeDefaults(loaded)
	profiles[userId] = profile
	dirty[userId] = false
	return profile
end

function PlayerData.Get(player: Player)
	return profiles[player.UserId]
end

function PlayerData.MarkDirty(player: Player)
	dirty[player.UserId] = true
end

function PlayerData.Save(player: Player): boolean
	local userId = player.UserId
	local profile = profiles[userId]
	if not profile then
		return false
	end
	profile.lastSeenAt = os.time()
	if not storeReady or not store or userId <= 0 then
		dirty[userId] = false
		return true
	end
	local ok, err = pcall(function()
		store:SetAsync(keyFor(userId), profile)
	end)
	if not ok then
		warn("[PlayerData] SetAsync failed for", player.Name, err)
		return false
	end
	dirty[userId] = false
	return true
end

function PlayerData.Release(player: Player)
	PlayerData.Save(player)
	profiles[player.UserId] = nil
	dirty[player.UserId] = nil
end

function PlayerData.Snapshot(player: Player)
	local p = profiles[player.UserId]
	if not p then
		return nil
	end
	return {
		aura = p.aura,
		coins = p.coins,
		bestTime = p.bestTime,
		totalFinishes = p.totalFinishes,
		totalDeaths = p.totalDeaths,
		totalOrbs = p.totalOrbs,
		unlocked = p.unlocked,
		equippedTrail = p.equippedTrail,
		achievements = p.achievements,
		loginStreak = p.loginStreak,
		tutorialDone = p.tutorialDone,
		settings = p.settings,
	}
end

task.spawn(function()
	while true do
		task.wait(60)
		for _, player in Players:GetPlayers() do
			if dirty[player.UserId] then
				PlayerData.Save(player)
			end
		end
	end
end)

return PlayerData
