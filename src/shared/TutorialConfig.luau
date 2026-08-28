-- First-run tips (tides-of-trade TutorialConfig, shortened for obby).

local TutorialConfig = {}

TutorialConfig.Steps = {
	{
		id = "welcome",
		title = "Welcome",
		body = "This is Aura Farm Obby. Race the course, grab purple orbs, hit the gold finish.",
	},
	{
		id = "checkpoints",
		title = "Checkpoints",
		body = "Yellow pads save your run. Die or fall and you respawn at the last one.",
	},
	{
		id = "orbs",
		title = "Farm Aura",
		body = "Purple orbs give Aura. Chain them fast for combos. Lucky rolls can multiply the payout.",
	},
	{
		id = "shop",
		title = "Trails",
		body = "Press B (or Shop) to spend Aura on glow trails. Flex while you speedrun.",
	},
	{
		id = "dailies",
		title = "Dailies",
		body = "Open Quests for daily goals + login streaks. Come back tomorrow for more rewards.",
	},
}

return TutorialConfig
