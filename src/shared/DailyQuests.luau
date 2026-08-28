-- Daily quest pool (tides-of-trade QuestService pattern, obby-flavored).

local DailyQuests = {}

export type QuestDef = {
	id: string,
	name: string,
	description: string,
	stat: string, -- finish | orb | death | checkpoint | play_minutes
	target: number,
	rewardAura: number,
	rewardCoins: number,
}

-- Rotating pool; server picks 3 per day from this list via day seed.
DailyQuests.Pool = {
	{
		id = "daily_finish_1",
		name = "Clear Once",
		description = "Finish Stage 1 once today.",
		stat = "finish",
		target = 1,
		rewardAura = 20,
		rewardCoins = 10,
	},
	{
		id = "daily_finish_3",
		name = "Triple Clear",
		description = "Finish Stage 1 three times today.",
		stat = "finish",
		target = 3,
		rewardAura = 50,
		rewardCoins = 25,
	},
	{
		id = "daily_orbs_10",
		name = "Orb Run",
		description = "Collect 10 orbs today.",
		stat = "orb",
		target = 10,
		rewardAura = 25,
		rewardCoins = 12,
	},
	{
		id = "daily_orbs_25",
		name = "Orb Sweep",
		description = "Collect 25 orbs today.",
		stat = "orb",
		target = 25,
		rewardAura = 60,
		rewardCoins = 30,
	},
	{
		id = "daily_cp_5",
		name = "Checkpoint Hopper",
		description = "Hit 5 new checkpoints today.",
		stat = "checkpoint",
		target = 5,
		rewardAura = 15,
		rewardCoins = 8,
	},
	{
		id = "daily_deaths_3",
		name = "Practice Falls",
		description = "Die 3 times (learning counts).",
		stat = "death",
		target = 3,
		rewardAura = 10,
		rewardCoins = 5,
	},
	{
		id = "daily_play_10",
		name = "Hang Out",
		description = "Play for 10 minutes today.",
		stat = "play_minutes",
		target = 10,
		rewardAura = 15,
		rewardCoins = 10,
	},
} :: { QuestDef }

function DailyQuests.Get(id: string): QuestDef?
	for _, q in DailyQuests.Pool do
		if q.id == id then
			return q
		end
	end
	return nil
end

-- Deterministic 3 quests for a YYYY-MM-DD string.
function DailyQuests.ForDay(ymd: string): { QuestDef }
	local seed = 0
	for i = 1, #ymd do
		seed = (seed * 33 + string.byte(ymd, i)) % 2147483647
	end
	local rng = Random.new(seed)
	local pool = table.clone(DailyQuests.Pool)
	-- Fisher-Yates
	for i = #pool, 2, -1 do
		local j = rng:NextInteger(1, i)
		pool[i], pool[j] = pool[j], pool[i]
	end
	return { pool[1], pool[2], pool[3] }
end

return DailyQuests
