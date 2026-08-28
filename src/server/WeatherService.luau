-- Aura-farm lighting moods (stay on-brand purple void; don't fight AuraTheme).

local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AuraTheme = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("AuraTheme"))

local WeatherService = {}

export type Mood = {
	id: string,
	label: string,
	auraMult: number,
	clockTime: number,
	fogColor: Color3,
	fogStart: number,
	fogEnd: number,
	ambient: Color3,
	durationSec: number,
}

local C = AuraTheme.Colors

local MOODS: { Mood } = {
	{
		id = "calm",
		label = "Calm Void",
		auraMult = 1,
		clockTime = 20.5,
		fogColor = C.Fog,
		fogStart = 50,
		fogEnd = 260,
		ambient = C.Ambient,
		durationSec = 75,
	},
	{
		id = "bloom",
		label = "Aura Bloom",
		auraMult = 1.25,
		clockTime = 21.2,
		fogColor = Color3.fromRGB(70, 40, 120),
		fogStart = 40,
		fogEnd = 220,
		ambient = Color3.fromRGB(90, 60, 140),
		durationSec = 60,
	},
	{
		id = "storm",
		label = "Void Storm",
		auraMult = 1.5,
		clockTime = 22.0,
		fogColor = Color3.fromRGB(30, 15, 50),
		fogStart = 30,
		fogEnd = 180,
		ambient = Color3.fromRGB(50, 30, 80),
		durationSec = 45,
	},
	{
		id = "golden",
		label = "Golden Hour",
		auraMult = 1.1,
		clockTime = 18.5,
		fogColor = Color3.fromRGB(80, 50, 90),
		fogStart = 60,
		fogEnd = 300,
		ambient = Color3.fromRGB(100, 70, 110),
		durationSec = 70,
	},
}

local current: Mood = MOODS[1]
local started = false
local index = 1

local function apply(mood: Mood, instant: boolean?)
	current = mood
	local info = if instant then TweenInfo.new(0) else TweenInfo.new(2.5, Enum.EasingStyle.Sine)
	TweenService:Create(Lighting, info, {
		ClockTime = mood.clockTime,
		FogColor = mood.fogColor,
		FogStart = mood.fogStart,
		FogEnd = mood.fogEnd,
		Ambient = mood.ambient,
		OutdoorAmbient = mood.ambient:Lerp(Color3.new(1, 1, 1), 0.15),
	}):Play()
end

function WeatherService.GetAuraMultiplier(): number
	return current.auraMult
end

function WeatherService.GetMood(): Mood
	return current
end

function WeatherService.Start(onChanged: ((Mood) -> ())?)
	if started then
		return
	end
	started = true
	AuraTheme.EnsurePostFx(Lighting)
	apply(MOODS[1], true)
	if onChanged then
		onChanged(current)
	end
	task.spawn(function()
		while true do
			task.wait(current.durationSec)
			index = (index % #MOODS) + 1
			apply(MOODS[index], false)
			if onChanged then
				onChanged(current)
			end
		end
	end)
end

return WeatherService
