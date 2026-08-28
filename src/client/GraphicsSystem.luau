-- Aura-farm post FX + client focus fog (stage rooms).
-- Server owns ClockTime; client adds bloom/CC and tightens fog for focus.

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local AuraTheme = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("AuraTheme"))

local GraphicsSystem = {}
GraphicsSystem.__index = GraphicsSystem

local PRESETS = {
	{
		name = "Aura",
		bloom = 0.55,
		bloomSize = 28,
		threshold = 0.85,
		sat = 0.22,
		contrast = 0.12,
		tint = Color3.fromRGB(230, 210, 255),
		fogEnd = 240,
	},
	{
		name = "Crisp",
		bloom = 0.25,
		bloomSize = 18,
		threshold = 1.0,
		sat = 0.05,
		contrast = 0.18,
		tint = Color3.fromRGB(255, 255, 255),
		fogEnd = 320,
	},
	{
		name = "Dream",
		bloom = 0.9,
		bloomSize = 40,
		threshold = 0.7,
		sat = 0.35,
		contrast = 0.08,
		tint = Color3.fromRGB(220, 180, 255),
		fogEnd = 180,
	},
	{
		name = "Perf",
		bloom = 0.1,
		bloomSize = 12,
		threshold = 1.2,
		sat = 0,
		contrast = 0.05,
		tint = Color3.fromRGB(255, 255, 255),
		fogEnd = 400,
	},
}

function GraphicsSystem.new()
	local self = setmetatable({}, GraphicsSystem)
	self._index = 1
	self._reduceFx = false

	AuraTheme.ApplyLighting(Lighting)
	AuraTheme.EnsurePostFx(Lighting)

	self.bloom = Lighting:FindFirstChild("AuraBloom") :: BloomEffect
	self.cc = Lighting:FindFirstChild("AuraCC") :: ColorCorrectionEffect

	self:ApplyPreset(1)

	-- Client-side focus: if FocusedStage attribute changes, tighten fog
	local player = Players.LocalPlayer
	self._attr = player:GetAttributeChangedSignal("FocusedStage"):Connect(function()
		self:_applyFocusFog()
	end)
	self:_applyFocusFog()

	return self
end

function GraphicsSystem:_applyFocusFog()
	local player = Players.LocalPlayer
	local sid = player:GetAttribute("FocusedStage")
	local preset = PRESETS[self._index] or PRESETS[1]
	local fogEnd = preset.fogEnd
	if typeof(sid) == "number" and sid > 0 then
		fogEnd = math.min(fogEnd, AuraTheme.Room.FocusFogEnd)
	end
	TweenService:Create(Lighting, TweenInfo.new(0.6), {
		FogEnd = fogEnd,
		FogStart = 50,
	}):Play()
end

function GraphicsSystem:ApplyPreset(index: number)
	self._index = ((index - 1) % #PRESETS) + 1
	local p = PRESETS[self._index]
	if self.bloom then
		self.bloom.Intensity = if self._reduceFx then p.bloom * 0.3 else p.bloom
		self.bloom.Size = p.bloomSize
		self.bloom.Threshold = p.threshold
	end
	if self.cc then
		self.cc.Saturation = if self._reduceFx then 0 else p.sat
		self.cc.Contrast = p.contrast
		self.cc.TintColor = p.tint
	end
	self:_applyFocusFog()
	return p.name
end

function GraphicsSystem:Cycle(): string
	return self:ApplyPreset(self._index + 1)
end

function GraphicsSystem:SetReduceFx(on: boolean)
	self._reduceFx = on
	self:ApplyPreset(self._index)
end

function GraphicsSystem:SetReduced(on: boolean)
	self:SetReduceFx(on)
end

function GraphicsSystem:Flash(color: Color3, duration: number?)
	local d = duration or 0.2
	if not self.cc then
		return
	end
	local old = self.cc.TintColor
	self.cc.TintColor = color
	self.cc.Brightness = 0.25
	task.delay(d, function()
		if self.cc then
			self.cc.Brightness = 0.02
			self.cc.TintColor = old
		end
	end)
end

function GraphicsSystem:Destroy()
	if self._attr then
		self._attr:Disconnect()
	end
end

return GraphicsSystem
