-- Lightweight DataStore profile. Session-safe: load, dirty autosave, save on leave.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local ObbyConfig = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("ObbyConfig"))

local PlayerData = {}

-- Keep v4 key so existing saves still load; nested multi-stage fields are additive.
local STORE_NAME = "AuraFarmObby_v4"
local store: DataStore? = nil
pcall(function()
	store = DataStoreService:GetDataStore(STORE_NAME)
end)

export type Profile = {
	aura: number,
	coins: number,
	bestTime: number?,
	bestTimes: { [string]: number },
	stagesCleared: { [string]: boolean },
	totalFinishes: number,
	totalOrbs: number,
	totalDeaths: number,
	unlocked: { [string]: boolean },
	equippedTrail: string?,
	achievements: { [string]: boolean },
	loginStreak: number,
	lastLoginDay: number?,
	lastSeen: number?,
	lastLogoutAt: number?,
	daily: any,
	stats: { [string]: number },
	settings: { [string]: any },
	tutorialDone: boolean,
	currentStage: number,
}

local profiles: { [number]: Profile } = {}
local dirty: { [number]: boolean } = {}

local function defaultProfile(): Profile
	return {
		aura = ObbyConfig.StartingAura or 0,
		coins = ObbyConfig.StartingCoins or 0,
		bestTime = nil,
		bestTimes = {},
		stagesCleared = {},
		totalFinishes = 0,
		totalOrbs = 0,
		totalDeaths = 0,
		unlocked = { default = true },
		equippedTrail = "default",
		achievements = {},
		loginStreak = 0,
		lastLoginDay = nil,
		lastSeen = os.time(),
		lastLogoutAt = nil,
		daily = nil,
		stats = {
			orbs = 0,
			kills = 0,
			playMinutes = 0,
			finishes = 0,
		},
		settings = {
			sfx = true,
			reduceFx = false,
		},
		tutorialDone = false,
		currentStage = 1,
	}
end

local function reconcile(raw: any): Profile
	local d = defaultProfile()
	if typeof(raw) ~= "table" then
		return d
	end
	if typeof(raw.aura) == "number" then
		d.aura = math.max(0, math.floor(raw.aura))
	end
	if typeof(raw.coins) == "number" then
		d.coins = math.max(0, math.floor(raw.coins))
	end
	if typeof(raw.bestTime) == "number" and raw.bestTime > 0 then
		d.bestTime = raw.bestTime
	end
	if typeof(raw.bestTimes) == "table" then
		for k, v in raw.bestTimes do
			if typeof(v) == "number" and v > 0 then
				d.bestTimes[tostring(k)] = v
			end
		end
	end
	if typeof(raw.stagesCleared) == "table" then
		for k, v in raw.stagesCleared do
			if v then
				d.stagesCleared[tostring(k)] = true
			end
		end
	end
	if typeof(raw.totalFinishes) == "number" then
		d.totalFinishes = math.max(0, math.floor(raw.totalFinishes))
		if d.totalFinishes > 0 and not next(d.stagesCleared) then
			d.stagesCleared["1"] = true
		end
	end
	if typeof(raw.totalOrbs) == "number" then
		d.totalOrbs = math.max(0, math.floor(raw.totalOrbs))
	end
	if typeof(raw.totalDeaths) == "number" then
		d.totalDeaths = math.max(0, math.floor(raw.totalDeaths))
	end
	if typeof(raw.unlocked) == "table" then
		for k, v in raw.unlocked do
			if v then
				d.unlocked[tostring(k)] = true
			end
		end
	end
	d.unlocked.default = true
	if typeof(raw.equippedTrail) == "string" then
		d.equippedTrail = raw.equippedTrail
	end
	if typeof(raw.achievements) == "table" then
		for k, v in raw.achievements do
			if v then
				d.achievements[tostring(k)] = true
			end
		end
	end
	if typeof(raw.loginStreak) == "number" then
		d.loginStreak = math.max(0, math.floor(raw.loginStreak))
	end
	if typeof(raw.lastLoginDay) == "number" then
		d.lastLoginDay = raw.lastLoginDay
	end
	if typeof(raw.lastSeen) == "number" then
		d.lastSeen = raw.lastSeen
	end
	if typeof(raw.lastLogoutAt) == "number" then
		d.lastLogoutAt = raw.lastLogoutAt
	end
	if raw.daily ~= nil then
		d.daily = raw.daily
	end
	if typeof(raw.stats) == "table" then
		for k, v in raw.stats do
			if typeof(v) == "number" then
				d.stats[tostring(k)] = v
			end
		end
	end
	if typeof(raw.settings) == "table" then
		for k, v in raw.settings do
			d.settings[tostring(k)] = v
		end
	end
	if raw.tutorialDone == true then
		d.tutorialDone = true
	end
	if typeof(raw.currentStage) == "number" then
		d.currentStage = math.clamp(math.floor(raw.currentStage), 1, 99)
	end
	return d
end

function PlayerData.Init()
	-- reserved for future ProfileService swap-in
	print("[PlayerData] Ready store=", STORE_NAME, store ~= nil)
end

function PlayerData.Get(player: Player): Profile?
	return profiles[player.UserId]
end

function PlayerData.MarkDirty(player: Player)
	dirty[player.UserId] = true
end

function PlayerData.HasCleared(profile: Profile, stageId: number): boolean
	return profile.stagesCleared[tostring(stageId)] == true
end

function PlayerData.IsStageUnlocked(profile: Profile, stageId: number, requiresStage: number?): boolean
	if stageId <= 1 then
		return true
	end
	local req = requiresStage or (stageId - 1)
	return PlayerData.HasCleared(profile, req)
end

function PlayerData.Snapshot(player: Player): { [string]: any }?
	local p = profiles[player.UserId]
	if not p then
		return nil
	end
	local cleared = {}
	for k in p.stagesCleared do
		table.insert(cleared, tonumber(k) or 0)
	end
	table.sort(cleared)
	return {
		aura = p.aura,
		coins = p.coins,
		bestTime = p.bestTime,
		bestTimes = p.bestTimes,
		stagesCleared = cleared,
		totalFinishes = p.totalFinishes,
		totalOrbs = p.totalOrbs,
		totalDeaths = p.totalDeaths,
		unlocked = p.unlocked,
		equippedTrail = p.equippedTrail,
		achievements = p.achievements,
		loginStreak = p.loginStreak,
		stats = p.stats,
		settings = p.settings,
		tutorialDone = p.tutorialDone,
		currentStage = p.currentStage,
		daily = p.daily,
	}
end

function PlayerData.Load(player: Player): Profile
	local userId = player.UserId
	local key = "u_" .. userId
	local loaded = nil
	if store then
		local ok, data = pcall(function()
			return store:GetAsync(key)
		end)
		if ok then
			loaded = data
		else
			warn("[PlayerData] GetAsync failed", data)
		end
	end
	local profile = reconcile(loaded)

	local day = math.floor(os.time() / 86400)
	if profile.lastLoginDay == nil then
		profile.loginStreak = math.max(profile.loginStreak, 1)
	elseif profile.lastLoginDay == day then
		-- same day
	elseif profile.lastLoginDay == day - 1 then
		profile.loginStreak += 1
	else
		profile.loginStreak = 1
	end
	profile.lastLoginDay = day
	profile.lastSeen = os.time()

	profiles[userId] = profile
	dirty[userId] = true
	return profile
end

local function serialize(profile: Profile): { [string]: any }
	return {
		aura = profile.aura,
		coins = profile.coins,
		bestTime = profile.bestTime,
		bestTimes = profile.bestTimes,
		stagesCleared = profile.stagesCleared,
		totalFinishes = profile.totalFinishes,
		totalOrbs = profile.totalOrbs,
		totalDeaths = profile.totalDeaths,
		unlocked = profile.unlocked,
		equippedTrail = profile.equippedTrail,
		achievements = profile.achievements,
		loginStreak = profile.loginStreak,
		lastLoginDay = profile.lastLoginDay,
		lastSeen = profile.lastSeen,
		lastLogoutAt = profile.lastLogoutAt,
		daily = profile.daily,
		stats = profile.stats,
		settings = profile.settings,
		tutorialDone = profile.tutorialDone,
		currentStage = profile.currentStage,
	}
end

function PlayerData.Save(player: Player): boolean
	local userId = player.UserId
	local profile = profiles[userId]
	if not profile then
		return false
	end
	profile.lastSeen = os.time()
	profile.lastLogoutAt = os.time()
	if not store then
		dirty[userId] = false
		return false
	end
	local key = "u_" .. userId
	local payload = serialize(profile)
	local ok, err = pcall(function()
		store:UpdateAsync(key, function()
			return payload
		end)
	end)
	if not ok then
		warn("[PlayerData] Save failed", player.Name, err)
		return false
	end
	dirty[userId] = false
	return true
end

function PlayerData.SaveAll()
	for _, player in Players:GetPlayers() do
		pcall(function()
			PlayerData.Save(player)
		end)
	end
end

task.spawn(function()
	while true do
		task.wait(45)
		for _, player in Players:GetPlayers() do
			if dirty[player.UserId] then
				pcall(function()
					PlayerData.Save(player)
				end)
			end
		end
	end
end)

Players.PlayerRemoving:Connect(function(player)
	pcall(function()
		PlayerData.Save(player)
	end)
	profiles[player.UserId] = nil
	dirty[player.UserId] = nil
end)

return PlayerData
