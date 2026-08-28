-- Daily quests + login streak (tides QuestService, simplified for obby).

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local DailyQuests = require(Shared:WaitForChild("DailyQuests"))
local TimeUtil = require(Shared:WaitForChild("TimeUtil"))
local ObbyConfig = require(Shared:WaitForChild("ObbyConfig"))

local QuestService = {}

local function ensureDaily(profile)
	local today = TimeUtil.UtcYmd()
	if profile.dailyYmd ~= today then
		-- rollover
		local streak = profile.loginStreak or 0
		local lastLogin = profile.lastLoginAt
		if lastLogin and TimeUtil.IsPreviousUtcDay(lastLogin, os.time()) then
			streak += 1
		elseif lastLogin and TimeUtil.IsSameUtcDay(lastLogin, os.time()) then
			-- same day rejoin
		else
			streak = 1
		end
		profile.loginStreak = streak
		profile.lastLoginAt = os.time()
		profile.dailyYmd = today
		profile.dailyProgress = {
			finish = 0,
			orb = 0,
			death = 0,
			checkpoint = 0,
			play_minutes = 0,
		}
		profile.dailyClaimed = {}
		profile.streakClaimedYmd = profile.streakClaimedYmd -- keep until claimed
		-- assign quest ids for the day
		local picks = DailyQuests.ForDay(today)
		profile.dailyQuestIds = { picks[1].id, picks[2].id, picks[3].id }
	else
		profile.lastLoginAt = os.time()
	end
	if type(profile.dailyProgress) ~= "table" then
		profile.dailyProgress = { finish = 0, orb = 0, death = 0, checkpoint = 0, play_minutes = 0 }
	end
	if type(profile.dailyClaimed) ~= "table" then
		profile.dailyClaimed = {}
	end
	if type(profile.dailyQuestIds) ~= "table" then
		local picks = DailyQuests.ForDay(profile.dailyYmd or TimeUtil.UtcYmd())
		profile.dailyQuestIds = { picks[1].id, picks[2].id, picks[3].id }
	end
end

function QuestService.OnJoin(profile)
	ensureDaily(profile)
	-- streak bonus once per day
	local today = TimeUtil.UtcYmd()
	if profile.streakClaimedYmd ~= today then
		local streak = profile.loginStreak or 1
		local aura = math.min(50, 5 + streak * 3)
		local coins = math.min(25, 2 + streak * 2)
		profile.aura = (profile.aura or 0) + aura
		profile.coins = (profile.coins or 0) + coins
		profile.streakClaimedYmd = today
		return {
			streak = streak,
			rewardAura = aura,
			rewardCoins = coins,
		}
	end
	return {
		streak = profile.loginStreak or 1,
		rewardAura = 0,
		rewardCoins = 0,
	}
end

function QuestService.AddProgress(profile, stat: string, amount: number?)
	ensureDaily(profile)
	amount = amount or 1
	local p = profile.dailyProgress
	if p[stat] ~= nil then
		p[stat] = (p[stat] or 0) + amount
	end
end

function QuestService.Snapshot(profile)
	ensureDaily(profile)
	local list = {}
	for _, id in profile.dailyQuestIds do
		local def = DailyQuests.Get(id)
		if def then
			local prog = profile.dailyProgress[def.stat] or 0
			table.insert(list, {
				id = def.id,
				name = def.name,
				description = def.description,
				stat = def.stat,
				target = def.target,
				progress = prog,
				claimed = profile.dailyClaimed[def.id] == true,
				complete = prog >= def.target,
				rewardAura = def.rewardAura,
				rewardCoins = def.rewardCoins,
			})
		end
	end
	return {
		ymd = profile.dailyYmd,
		streak = profile.loginStreak or 1,
		quests = list,
		resetsIn = TimeUtil.SecondsUntilNextUtcMidnight(),
	}
end

function QuestService.TryClaim(profile, questId: string): (boolean, string, number?, number?)
	ensureDaily(profile)
	local def = DailyQuests.Get(questId)
	if not def then
		return false, "Unknown quest"
	end
	local found = false
	for _, id in profile.dailyQuestIds do
		if id == questId then
			found = true
			break
		end
	end
	if not found then
		return false, "Not today's quest"
	end
	if profile.dailyClaimed[questId] then
		return false, "Already claimed"
	end
	local prog = profile.dailyProgress[def.stat] or 0
	if prog < def.target then
		return false, "Not complete"
	end
	profile.dailyClaimed[questId] = true
	profile.aura = (profile.aura or 0) + def.rewardAura
	profile.coins = (profile.coins or 0) + def.rewardCoins
	return true, "Claimed " .. def.name, def.rewardAura, def.rewardCoins
end

return QuestService
