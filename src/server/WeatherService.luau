-- Cycling weather / lighting moods (tides WeatherService + TideService vibe).

local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local WeatherService = {}

type Mood = {
	id: string,
	label: string,
	clockTime: number,
	brightness: number,
	ambient: Color3,
	outdoor: Color3,
	fogColor: Color3,
	fogStart: number,
	fogEnd: number,
	auraMult: number, -- orb aura multiplier while active
	durationSec: number,
}

local MOODS: { Mood } = {
	{
		id = "clear",
		label = "Clear Skies",
		clockTime = 14,
		brightness = 2.2,
		ambient = Color3.fromRGB(130, 130, 150),
		outdoor = Color3.fromRGB(150, 150, 170),
		fogColor = Color3.fromRGB(190, 200, 220),
		fogStart = 0,
		fogEnd = 600,
		auraMult = 1,
		durationSec = 90,
	},
	{
		id = "golden",
		label = "Golden Hour",
		clockTime = 17.5,
		brightness = 1.8,
		ambient = Color3.fromRGB(160, 120, 80),
		outdoor = Color3.fromRGB(180, 140, 90),
		fogColor = Color3.fromRGB(220, 180, 120),
		fogStart = 40,
		fogEnd = 450,
		auraMult = 1.25,
		durationSec = 60,
	},
	{
		id = "storm",
		label = "Aura Storm",
		clockTime = 20,
		brightness = 1.2,
		ambient = Color3.fromRGB(60, 50, 100),
		outdoor = Color3.fromRGB(70, 60, 120),
		fogColor = Color3.fromRGB(40, 30, 70),
		fogStart = 20,
		fogEnd = 280,
		auraMult = 1.5,
		durationSec = 45,
	},
	{
		id = "night",
		label = "Night Run",
		clockTime = 0.5,
		brightness = 0.9,
		ambient = Color3.fromRGB(40, 45, 70),
		outdoor = Color3.fromRGB(50, 55, 90),
		fogColor = Color3.fromRGB(20, 20, 40),
		fogStart = 30,
		fogEnd = 350,
		auraMult = 1.15,
		durationSec = 70,
	},
}

local index = 1
local current: Mood = MOODS[1]
local started = false

local function apply(mood: Mood, instant: boolean?)
	current = mood
	local info = TweenInfo.new(instant and 0.05 or 4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
	TweenService:Create(Lighting, info, {
		ClockTime = mood.clockTime,
		Brightness = mood.brightness,
		Ambient = mood.ambient,
		OutdoorAmbient = mood.outdoor,
		FogColor = mood.fogColor,
		FogStart = mood.fogStart,
		FogEnd = mood.fogEnd,
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
