-- Achievement definitions (tides-of-trade AchievementCatalog pattern).

local Achievements = {}

export type AchievementDef = {
	id: string,
	name: string,
	description: string,
	-- one of: finish_count, orb_count, death_count, best_time_under, aura_total, coins_total
	stat: string,
	target: number,
	rewardAura: number,
	rewardCoins: number,
}

local list: { AchievementDef } = {
	{
		id = "first_finish",
		name = "First Clear",
		description = "Finish Stage 1 once.",
		stat = "finish_count",
		target = 1,
		rewardAura = 15,
		rewardCoins = 5,
	},
	{
		id = "finishes_5",
		name = "Warm-up Legend",
		description = "Finish Stage 1 five times.",
		stat = "finish_count",
		target = 5,
		rewardAura = 40,
		rewardCoins = 15,
	},
	{
		id = "orbs_20",
		name = "Orb Collector",
		description = "Pick up 20 aura orbs total.",
		stat = "orb_count",
		target = 20,
		rewardAura = 25,
		rewardCoins = 10,
	},
	{
		id = "orbs_50",
		name = "Aura Hoarder",
		description = "Pick up 50 aura orbs total.",
		stat = "orb_count",
		target = 50,
		rewardAura = 60,
		rewardCoins = 25,
	},
	{
		id = "speed_45",
		name = "Sub-45",
		description = "Beat Stage 1 in under 45 seconds.",
		stat = "best_time_under",
		target = 45,
		rewardAura = 50,
		rewardCoins = 20,
	},
	{
		id = "speed_30",
		name = "Sub-30 Speedrunner",
		description = "Beat Stage 1 in under 30 seconds.",
		stat = "best_time_under",
		target = 30,
		rewardAura = 100,
		rewardCoins = 40,
	},
	{
		id = "deaths_10",
		name = "Pain Tax",
		description = "Die 10 times. It builds character.",
		stat = "death_count",
		target = 10,
		rewardAura = 10,
		rewardCoins = 5,
	},
	{
		id = "aura_200",
		name = "Glow-up",
		description = "Hold 200 total aura earned (banked).",
		stat = "aura_total",
		target = 200,
		rewardAura = 0,
		rewardCoins = 30,
	},
	{
		id = "buy_first_trail",
		name = "Fashionably Early",
		description = "Buy any paid trail cosmetic.",
		stat = "trails_owned",
		target = 2, -- starter + 1
		rewardAura = 10,
		rewardCoins = 5,
	},
}

Achievements.List = list

function Achievements.Get(id: string): AchievementDef?
	for _, a in list do
		if a.id == id then
			return a
		end
	end
	return nil
end

return Achievements
