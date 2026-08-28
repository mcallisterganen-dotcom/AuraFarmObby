-- Multi-stage definitions: themes, rewards, difficulty curves.
-- Layout recipes stay in StageBuilder; this is the data layer.

local StageConfig = {}

export type StageDef = {
	id: number,
	name: string,
	subtitle: string,
	-- World placement (stages sit side-by-side on X)
	originX: number,
	baseY: number,
	-- Gameplay
	minFinishTimeSec: number,
	minCheckpointForFinish: number,
	checkpointCount: number, -- expected CPs (1..n); finish is separate
	-- Economy
	clearAura: number,
	clearCoins: number,
	orbAura: number,
	-- Presentation
	theme: string, -- meadow | canyon | neon
	pathColor: Color3,
	accentColor: Color3,
	killColor: Color3,
	fogColor: Color3,
	clockTime: number,
	-- Unlock
	requiresStage: number?, -- previous stage id that must be cleared once
}

StageConfig.LobbySpawn = Vector3.new(0, 8, 40)

StageConfig.Stages = {
	{
		id = 1,
		name = "Meadow Run",
		subtitle = "Learn the flow",
		originX = 0,
		baseY = 12,
		minFinishTimeSec = 10,
		minCheckpointForFinish = 1,
		checkpointCount = 4,
		clearAura = 25,
		clearCoins = 10,
		orbAura = 2,
		theme = "meadow",
		pathColor = Color3.fromRGB(72, 168, 110),
		accentColor = Color3.fromRGB(190, 255, 160),
		killColor = Color3.fromRGB(200, 60, 70),
		fogColor = Color3.fromRGB(140, 180, 210),
		clockTime = 15.5,
		requiresStage = nil,
	},
	{
		id = 2,
		name = "Crystal Canyon",
		subtitle = "Timing & height",
		originX = 220,
		baseY = 18,
		minFinishTimeSec = 14,
		minCheckpointForFinish = 2,
		checkpointCount = 5,
		clearAura = 55,
		clearCoins = 22,
		orbAura = 3,
		theme = "canyon",
		pathColor = Color3.fromRGB(110, 90, 170),
		accentColor = Color3.fromRGB(180, 140, 255),
		killColor = Color3.fromRGB(255, 90, 120),
		fogColor = Color3.fromRGB(60, 40, 90),
		clockTime = 18.2,
		requiresStage = 1,
	},
	{
		id = 3,
		name = "Neon Spire",
		subtitle = "Precision endgame",
		originX = 460,
		baseY = 28,
		minFinishTimeSec = 18,
		minCheckpointForFinish = 3,
		checkpointCount = 6,
		clearAura = 120,
		clearCoins = 50,
		orbAura = 4,
		theme = "neon",
		pathColor = Color3.fromRGB(40, 44, 70),
		accentColor = Color3.fromRGB(80, 255, 230),
		killColor = Color3.fromRGB(255, 50, 90),
		fogColor = Color3.fromRGB(20, 12, 40),
		clockTime = 21.5,
		requiresStage = 2,
	},
} :: { StageDef }

function StageConfig.Get(id: number): StageDef?
	for _, s in StageConfig.Stages do
		if s.id == id then
			return s
		end
	end
	return nil
end

function StageConfig.Count(): number
	return #StageConfig.Stages
end

function StageConfig.FolderName(id: number): string
	return "Stage" .. tostring(id)
end

return StageConfig
