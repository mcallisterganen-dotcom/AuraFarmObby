-- Client post-process presets. Complements server WeatherService (does not own ClockTime).
-- Cycles ColorCorrection / Bloom / DOF on the local client only.

local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local GraphicsSystem = {}
GraphicsSystem.__index = GraphicsSystem

local PRESETS = {
	{
		id = "Balanced",
		cc = { Brightness = 0.02, Contrast = 0.08, Saturation = 0.1, TintColor = Color3.fromRGB(255, 255, 255) },
		bloom = { Intensity = 0.35, Size = 18, Threshold = 1.1 },
		dof = nil,
	},
	{
		id = "Vibrant",
		cc = { Brightness = 0.05, Contrast = 0.15, Saturation = 0.35, TintColor = Color3.fromRGB(255, 245, 255) },
		bloom = { Intensity = 0.55, Size = 24, Threshold = 0.95 },
		dof = nil,
	},
	{
		id = "Cinematic",
		cc = { Brightness = -0.02, Contrast = 0.22, Saturation = -0.05, TintColor = Color3.fromRGB(240, 230, 255) },
		bloom = { Intensity = 0.4, Size = 20, Threshold = 1.0 },
		dof = { FarIntensity = 0.2, FocusDistance = 40, InFocusRadius = 30, NearIntensity = 0.05 },
	},
	{
		id = "Neon Night",
		cc = { Brightness = 0.0, Contrast = 0.18, Saturation = 0.25, TintColor = Color3.fromRGB(200, 180, 255) },
		bloom = { Intensity = 0.7, Size = 28, Threshold = 0.85 },
		dof = nil,
	},
	{
		id = "Off",
		cc = nil,
		bloom = nil,
		dof = nil,
	},
}

function GraphicsSystem.new()
	local self = setmetatable({}, GraphicsSystem)
	self.index = 1
	self.enabled = true
	self.cc = nil
	self.bloom = nil
	self.dof = nil
	self:_ensureEffects()
	self:ApplyPreset(PRESETS[1].id)
	return self
end

function GraphicsSystem:_ensureEffects()
	-- Tag our effects so we don't destroy weather-unrelated lighting
	self.cc = Lighting:FindFirstChild("AuraFarmCC")
	if not self.cc then
		self.cc = Instance.new("ColorCorrectionEffect")
		self.cc.Name = "AuraFarmCC"
		self.cc.Parent = Lighting
	end
	self.bloom = Lighting:FindFirstChild("AuraFarmBloom")
	if not self.bloom then
		self.bloom = Instance.new("BloomEffect")
		self.bloom.Name = "AuraFarmBloom"
		self.bloom.Parent = Lighting
	end
	self.dof = Lighting:FindFirstChild("AuraFarmDOF")
	if not self.dof then
		self.dof = Instance.new("DepthOfFieldEffect")
		self.dof.Name = "AuraFarmDOF"
		self.dof.Enabled = false
		self.dof.Parent = Lighting
	end
end

function GraphicsSystem:ApplyPreset(id: string): string
	local preset = PRESETS[1]
	for i, p in PRESETS do
		if p.id == id then
			preset = p
			self.index = i
			break
		end
	end
	self:_ensureEffects()

	local tweenInfo = TweenInfo.new(0.45, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

	if not preset.cc then
		self.cc.Enabled = false
		self.bloom.Enabled = false
		self.dof.Enabled = false
		return preset.id
	end

	self.cc.Enabled = true
	TweenService:Create(self.cc, tweenInfo, preset.cc):Play()

	if preset.bloom then
		self.bloom.Enabled = true
		TweenService:Create(self.bloom, tweenInfo, preset.bloom):Play()
	else
		self.bloom.Enabled = false
	end

	if preset.dof then
		self.dof.Enabled = true
		TweenService:Create(self.dof, tweenInfo, preset.dof):Play()
	else
		self.dof.Enabled = false
	end

	return preset.id
end

function GraphicsSystem:Cycle(): string
	self.index = (self.index % #PRESETS) + 1
	return self:ApplyPreset(PRESETS[self.index].id)
end

function GraphicsSystem:GetPresetName(): string
	return PRESETS[self.index].id
end

function GraphicsSystem:SetReduced(reduced: boolean)
	if reduced then
		self:ApplyPreset("Off")
	else
		self:ApplyPreset(PRESETS[math.clamp(self.index, 1, #PRESETS - 1)].id)
	end
end

function GraphicsSystem:Flash(color: Color3?, duration: number?)
	self:_ensureEffects()
	local prevBright = self.cc.Brightness
	self.cc.Enabled = true
	self.cc.TintColor = color or Color3.fromRGB(200, 160, 255)
	self.cc.Brightness = 0.35
	task.delay(duration or 0.15, function()
		TweenService:Create(self.cc, TweenInfo.new(0.4), {
			Brightness = prevBright,
			TintColor = Color3.fromRGB(255, 255, 255),
		}):Play()
	end)
end

function GraphicsSystem:Destroy()
	if self.cc then
		self.cc:Destroy()
	end
	if self.bloom then
		self.bloom:Destroy()
	end
	if self.dof then
		self.dof:Destroy()
	end
end

return GraphicsSystem
