-- Daily quest pool.

local DailyQuests = {}

export type QuestDef = {
	id: string,
	name: string,
	description: string,
	stat: string,
	target: number,
	rewardAura: number,
	rewardCoins: number,
}

local POOL: { QuestDef } = {
	{
		id = "d_finish_1",
		name = "Daily Clear",
		description = "Finish a stage once",
		stat = "finishes",
		target = 1,
		rewardAura = 20,
		rewardCoins = 8,
	},
	{
		id = "d_finish_3",
		name = "Triple Clear",
		description = "Finish stages 3 times",
		stat = "finishes",
		target = 3,
		rewardAura = 45,
		rewardCoins = 15,
	},
	{
		id = "d_orbs_10",
		name = "Orb Route",
		description = "Collect 10 orbs",
		stat = "orbs",
		target = 10,
		rewardAura = 25,
		rewardCoins = 10,
	},
	{
		id = "d_orbs_25",
		name = "Orb Marathon",
		description = "Collect 25 orbs",
		stat = "orbs",
		target = 25,
		rewardAura = 50,
		rewardCoins = 18,
	},
	{
		id = "d_cp_5",
		name = "Checkpoint Tour",
		description = "Hit 5 new checkpoints",
		stat = "checkpoints",
		target = 5,
		rewardAura = 20,
		rewardCoins = 8,
	},
	{
		id = "d_play_10",
		name = "Session Time",
		description = "Play for 10 minutes",
		stat = "playMinutes",
		target = 10,
		rewardAura = 30,
		rewardCoins = 12,
	},
	{
		id = "d_play_20",
		name = "Long Session",
		description = "Play for 20 minutes",
		stat = "playMinutes",
		target = 20,
		rewardAura = 55,
		rewardCoins = 20,
	},
}

function DailyQuests.Pool(): { QuestDef }
	return POOL
end

function DailyQuests.PickForDay(seed: number): { QuestDef }
	local rng = Random.new(seed)
	local pool = table.clone(POOL)
	-- shuffle
	for i = #pool, 2, -1 do
		local j = rng:NextInteger(1, i)
		pool[i], pool[j] = pool[j], pool[i]
	end
	return { pool[1], pool[2], pool[3] }
end

function DailyQuests.Get(id: string): QuestDef?
	for _, q in POOL do
		if q.id == id then
			return q
		end
	end
	return nil
end

return DailyQuests
