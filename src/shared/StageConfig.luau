-- Multi-stage definitions — aura-farm identity (purple void rooms).

local AuraTheme = require(script.Parent:WaitForChild("AuraTheme"))

local StageConfig = {}

export type StageDef = {
	id: number,
	name: string,
	subtitle: string,
	originX: number,
	baseY: number,
	minFinishTimeSec: number,
	minCheckpointForFinish: number,
	checkpointCount: number,
	clearAura: number,
	clearCoins: number,
	orbAura: number,
	theme: string,
	pathColor: Color3,
	accentColor: Color3,
	killColor: Color3,
	fogColor: Color3,
	clockTime: number,
	requiresStage: number?,
}

StageConfig.LobbySpawn = Vector3.new(0, 8, 40)

local C = AuraTheme.Colors

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
		pathColor = Color3.fromRGB(40, 55, 48), -- dark grass-slate (not neon floor)
		accentColor = Color3.fromRGB(160, 255, 180),
		killColor = C.Danger,
		fogColor = Color3.fromRGB(50, 70, 90),
		clockTime = 19.5,
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
		pathColor = Color3.fromRGB(48, 36, 72),
		accentColor = C.Accent,
		killColor = C.Danger,
		fogColor = Color3.fromRGB(50, 30, 80),
		clockTime = 20.5,
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
		-- Path is DARK plastic; neon is accent only (ParkourKit)
		pathColor = Color3.fromRGB(28, 30, 48),
		accentColor = C.AccentCool,
		killColor = C.Danger,
		fogColor = Color3.fromRGB(20, 12, 40),
		clockTime = 21.8,
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
