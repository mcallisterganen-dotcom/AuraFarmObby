-- Daily quests + progress tracking.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local DailyQuests = require(Shared:WaitForChild("DailyQuests"))
local TimeUtil = require(Shared:WaitForChild("TimeUtil"))

local QuestService = {}

local function daySeed(): number
	local ymd = TimeUtil.UtcYmd(os.time())
	-- simple hash
	local h = 0
	for i = 1, #ymd do
		h = (h * 33 + string.byte(ymd, i)) % 1000000
	end
	return h
end

local function ensureDaily(profile)
	local today = TimeUtil.UtcYmd(os.time())
	if typeof(profile.daily) == "table" and profile.daily.day == today then
		return
	end
	local picks = DailyQuests.PickForDay(daySeed())
	local quests = {}
	for _, def in picks do
		quests[def.id] = {
			id = def.id,
			progress = 0,
			target = def.target,
			claimed = false,
			stat = def.stat,
			name = def.name,
			description = def.description,
			rewardAura = def.rewardAura,
			rewardCoins = def.rewardCoins,
		}
	end
	profile.daily = {
		day = today,
		quests = quests,
	}
end

function QuestService.Ensure(profile)
	ensureDaily(profile)
end

function QuestService.Record(profile, stat: string, amount: number?)
	ensureDaily(profile)
	local amt = amount or 1
	local daily = profile.daily
	if not daily or not daily.quests then
		return
	end
	for _, q in daily.quests do
		if q.stat == stat and not q.claimed then
			q.progress = math.min(q.target, (q.progress or 0) + amt)
		end
	end
end

function QuestService.Snapshot(profile): { [string]: any }
	ensureDaily(profile)
	local list = {}
	for _, q in profile.daily.quests do
		table.insert(list, {
			id = q.id,
			name = q.name,
			description = q.description,
			progress = q.progress,
			target = q.target,
			claimed = q.claimed,
			rewardAura = q.rewardAura,
			rewardCoins = q.rewardCoins,
			complete = q.progress >= q.target,
		})
	end
	table.sort(list, function(a, b)
		return a.id < b.id
	end)
	return {
		day = profile.daily.day,
		quests = list,
	}
end

function QuestService.TryClaim(profile, questId: string): (boolean, string, number?, number?)
	ensureDaily(profile)
	local q = profile.daily.quests[questId]
	if not q then
		return false, "Unknown quest", nil, nil
	end
	if q.claimed then
		return false, "Already claimed", nil, nil
	end
	if (q.progress or 0) < q.target then
		return false, "Not complete", nil, nil
	end
	q.claimed = true
	profile.aura = (profile.aura or 0) + (q.rewardAura or 0)
	profile.coins = (profile.coins or 0) + (q.rewardCoins or 0)
	return true, "Claimed " .. (q.name or questId), q.rewardAura, q.rewardCoins
end

return QuestService
