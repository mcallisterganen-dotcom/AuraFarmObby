-- Global "Aura Farm" visual identity — purple void, soft bloom, farm-core vibe.
-- Single source of truth for lighting / fog / materials that feel on-brand.

local AuraTheme = {}

AuraTheme.Name = "Aura Farm"

-- Core palette
AuraTheme.Colors = {
	Void = Color3.fromRGB(12, 8, 22),
	VoidDeep = Color3.fromRGB(6, 4, 14),
	Fog = Color3.fromRGB(40, 24, 70),
	Ambient = Color3.fromRGB(70, 50, 110),
	Outdoor = Color3.fromRGB(90, 70, 140),
	Accent = Color3.fromRGB(180, 120, 255),
	AccentHot = Color3.fromRGB(255, 100, 200),
	AccentCool = Color3.fromRGB(100, 220, 255),
	Gold = Color3.fromRGB(255, 210, 120),
	Path = Color3.fromRGB(32, 28, 48), -- matte dark run surface (readable feet)
	PathEdge = Color3.fromRGB(90, 70, 130), -- soft rim, not blinding
	Safe = Color3.fromRGB(80, 200, 140),
	Danger = Color3.fromRGB(255, 60, 100),
	Ground = Color3.fromRGB(28, 20, 48),
	Rock = Color3.fromRGB(45, 35, 70),
}

-- Materials that WORK for parkour (Neon is slippery / hard to read as floor)
AuraTheme.Materials = {
	Path = Enum.Material.SmoothPlastic, -- grippy, readable
	PathAccent = Enum.Material.Neon, -- edges only
	Metal = Enum.Material.Metal,
	Ground = Enum.Material.Slate,
	Rock = Enum.Material.Basalt,
	Glow = Enum.Material.Neon,
	Force = Enum.Material.ForceField,
	Glass = Enum.Material.Glass,
}

-- Default atmosphere when not in a stage-specific mood
AuraTheme.Lighting = {
	ClockTime = 20.5, -- night aura farm
	Brightness = 1.15, -- lower so platforms stay readable
	Ambient = Color3.fromRGB(55, 42, 85),
	OutdoorAmbient = Color3.fromRGB(70, 55, 105),
	FogColor = AuraTheme.Colors.Fog,
	FogStart = 60,
	FogEnd = 280, -- tight = focus on current room
	EnvironmentDiffuseScale = 0.35,
	EnvironmentSpecularScale = 0.2,
	ShadowSoftness = 0.45,
	ExposureCompensation = 0.0,
}

AuraTheme.Bloom = {
	Intensity = 0.22, -- keep glow on orbs/accents, not floors
	Size = 18,
	Threshold = 1.15, -- only very bright parts bloom
}

AuraTheme.ColorCorrection = {
	Brightness = -0.02,
	Contrast = 0.14,
	Saturation = 0.1,
	TintColor = Color3.fromRGB(220, 210, 235),
}

-- Stage room isolation
AuraTheme.Room = {
	-- How far from originX a room's content lives
	HalfWidth = 90,
	-- Fog/end focus distance while inside a room
	FocusFogEnd = 220,
	LobbyFogEnd = 320,
}

function AuraTheme.ApplyLighting(lighting: Lighting)
	local L = AuraTheme.Lighting
	lighting.ClockTime = L.ClockTime
	lighting.Brightness = L.Brightness
	lighting.Ambient = L.Ambient
	lighting.OutdoorAmbient = L.OutdoorAmbient
	lighting.FogColor = L.FogColor
	lighting.FogStart = L.FogStart
	lighting.FogEnd = L.FogEnd
	pcall(function()
		lighting.EnvironmentDiffuseScale = L.EnvironmentDiffuseScale
		lighting.EnvironmentSpecularScale = L.EnvironmentSpecularScale
		lighting.ShadowSoftness = L.ShadowSoftness
		lighting.ExposureCompensation = L.ExposureCompensation
	end)
	-- Technology: Future looks best for neon accents; ShadowMap is safer
	pcall(function()
		lighting.Technology = Enum.Technology.ShadowMap
	end)
end

function AuraTheme.EnsurePostFx(lighting: Lighting)
	local bloom = lighting:FindFirstChild("AuraBloom")
	if not bloom then
		bloom = Instance.new("BloomEffect")
		bloom.Name = "AuraBloom"
		bloom.Parent = lighting
	end
	bloom.Intensity = AuraTheme.Bloom.Intensity
	bloom.Size = AuraTheme.Bloom.Size
	bloom.Threshold = AuraTheme.Bloom.Threshold

	local cc = lighting:FindFirstChild("AuraCC")
	if not cc then
		cc = Instance.new("ColorCorrectionEffect")
		cc.Name = "AuraCC"
		cc.Parent = lighting
	end
	cc.Brightness = AuraTheme.ColorCorrection.Brightness
	cc.Contrast = AuraTheme.ColorCorrection.Contrast
	cc.Saturation = AuraTheme.ColorCorrection.Saturation
	cc.TintColor = AuraTheme.ColorCorrection.TintColor

	local atmo = lighting:FindFirstChildOfClass("Atmosphere")
	if not atmo then
		atmo = Instance.new("Atmosphere")
		atmo.Parent = lighting
	end
	atmo.Density = 0.35
	atmo.Offset = 0.1
	atmo.Color = Color3.fromRGB(90, 60, 140)
	atmo.Decay = Color3.fromRGB(40, 20, 80)
	atmo.Glare = 0.2
	atmo.Haze = 1.5
end

return AuraTheme
