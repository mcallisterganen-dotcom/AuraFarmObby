-- Achievement definitions.

local Achievements = {}

export type AchievementDef = {
	id: string,
	name: string,
	description: string,
	stat: string,
	threshold: number,
	rewardAura: number,
	rewardCoins: number,
}

Achievements.List = {
	{
		id = "first_clear",
		name = "First Steps",
		description = "Clear any stage once",
		stat = "finishes",
		threshold = 1,
		rewardAura = 15,
		rewardCoins = 5,
	},
	{
		id = "clear_5",
		name = "Warming Up",
		description = "Clear stages 5 times total",
		stat = "finishes",
		threshold = 5,
		rewardAura = 30,
		rewardCoins = 10,
	},
	{
		id = "clear_25",
		name = "Parkour Regular",
		description = "25 total clears",
		stat = "finishes",
		threshold = 25,
		rewardAura = 80,
		rewardCoins = 25,
	},
	{
		id = "orb_10",
		name = "Orb Curious",
		description = "Collect 10 aura orbs",
		stat = "orbs",
		threshold = 10,
		rewardAura = 10,
		rewardCoins = 5,
	},
	{
		id = "orb_100",
		name = "Orb Hoarder",
		description = "Collect 100 aura orbs",
		stat = "orbs",
		threshold = 100,
		rewardAura = 50,
		rewardCoins = 20,
	},
	{
		id = "death_1",
		name = "It Happens",
		description = "Die to a kill brick once",
		stat = "death_count",
		threshold = 1,
		rewardAura = 5,
		rewardCoins = 0,
	},
	{
		id = "death_25",
		name = "Pain is Learning",
		description = "25 kill-brick deaths",
		stat = "death_count",
		threshold = 25,
		rewardAura = 25,
		rewardCoins = 10,
	},
	{
		id = "trail_3",
		name = "Fashion Start",
		description = "Own 3 trails",
		stat = "trails",
		threshold = 3,
		rewardAura = 20,
		rewardCoins = 10,
	},
	{
		id = "trail_all",
		name = "Closet Full",
		description = "Own 8 trails",
		stat = "trails",
		threshold = 8,
		rewardAura = 100,
		rewardCoins = 40,
	},
	{
		id = "streak_3",
		name = "Comeback Kid",
		description = "3-day login streak",
		stat = "streak",
		threshold = 3,
		rewardAura = 25,
		rewardCoins = 10,
	},
	{
		id = "streak_7",
		name = "Dedicated",
		description = "7-day login streak",
		stat = "streak",
		threshold = 7,
		rewardAura = 70,
		rewardCoins = 30,
	},
	{
		id = "stages_2",
		name = "Canyon Bound",
		description = "Clear 2 different stages",
		stat = "stages",
		threshold = 2,
		rewardAura = 40,
		rewardCoins = 15,
	},
	{
		id = "stages_3",
		name = "Spire Ascendant",
		description = "Clear all 3 stages",
		stat = "stages",
		threshold = 3,
		rewardAura = 150,
		rewardCoins = 60,
	},
	{
		id = "aura_500",
		name = "Aura Bank",
		description = "Hold 500 Aura at once",
		stat = "aura",
		threshold = 500,
		rewardAura = 50,
		rewardCoins = 20,
	},
	{
		id = "speed_60",
		name = "Sub-Minute",
		description = "Any stage best under 60s",
		stat = "best_time",
		threshold = 60,
		rewardAura = 40,
		rewardCoins = 15,
	},
} :: { AchievementDef }

function Achievements.Get(id: string): AchievementDef?
	for _, a in Achievements.List do
		if a.id == id then
			return a
		end
	end
	return nil
end

return Achievements
