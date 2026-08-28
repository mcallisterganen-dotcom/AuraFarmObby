-- Client aura particles + emotes.
-- Movement trails stay on the SERVER (TrailService + CosmeticsCatalog shop).
-- This layer adds body aura FX that stack with equipped shop trails.

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local CosmeticsCatalog = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("CosmeticsCatalog"))

local CosmeticsSystem = {}
CosmeticsSystem.__index = CosmeticsSystem

CosmeticsSystem.AuraSkins = {
	Default = {
		name = "Default Aura",
		color = Color3.fromRGB(160, 120, 255),
		rate = 12,
		size = 0.35,
	},
	Gold = {
		name = "Golden Aura",
		color = Color3.fromRGB(255, 200, 40),
		rate = 16,
		size = 0.4,
	},
	Crimson = {
		name = "Crimson Aura",
		color = Color3.fromRGB(255, 60, 80),
		rate = 18,
		size = 0.45,
	},
	Mystic = {
		name = "Mystic Aura",
		color = Color3.fromRGB(120, 80, 255),
		rate = 22,
		size = 0.5,
	},
}

CosmeticsSystem.AuraOrder = { "Default", "Gold", "Crimson", "Mystic" }

CosmeticsSystem.Emotes = { "Victory", "Dance", "Cheer" }

function CosmeticsSystem.new(character: Model, animationSystem: any)
	local self = setmetatable({}, CosmeticsSystem)
	self.character = character
	self.hrp = character:WaitForChild("HumanoidRootPart") :: BasePart
	self.animationSystem = animationSystem
	self.equippedAura = "Default"
	self.auraIndex = 1
	self.emoteIndex = 0
	self.folder = Instance.new("Folder")
	self.folder.Name = "AuraFarmClientFX"
	self.folder.Parent = character
	self.emitter = nil
	self.light = nil
	self:_applyAura("Default")
	return self
end

function CosmeticsSystem:_clearAura()
	if self.emitter then
		self.emitter:Destroy()
		self.emitter = nil
	end
	if self.light then
		self.light:Destroy()
		self.light = nil
	end
end

function CosmeticsSystem:_applyAura(skinName: string)
	local skin = CosmeticsSystem.AuraSkins[skinName]
	if not skin then
		return false
	end
	self:_clearAura()
	self.equippedAura = skinName

	local att = self.hrp:FindFirstChild("AuraFarmAuraAtt")
	if not att then
		att = Instance.new("Attachment")
		att.Name = "AuraFarmAuraAtt"
		att.Position = Vector3.new(0, 0, 0)
		att.Parent = self.hrp
	end

	local p = Instance.new("ParticleEmitter")
	p.Name = "AuraSkinParticles"
	p.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	p.Color = ColorSequence.new(skin.color)
	p.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, skin.size),
		NumberSequenceKeypoint.new(1, 0.05),
	})
	p.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(1, 1),
	})
	p.Lifetime = NumberRange.new(0.35, 0.7)
	p.Rate = skin.rate
	p.Speed = NumberRange.new(0.2, 1.2)
	p.SpreadAngle = Vector2.new(360, 360)
	p.RotSpeed = NumberRange.new(-40, 40)
	p.LightEmission = 0.6
	p.Parent = att
	self.emitter = p

	local light = Instance.new("PointLight")
	light.Name = "AuraSkinLight"
	light.Color = skin.color
	light.Brightness = 0.55
	light.Range = 8
	light.Parent = self.hrp
	self.light = light

	return true
end

function CosmeticsSystem:EquipAuraSkin(skinName: string): boolean
	return self:_applyAura(skinName)
end

function CosmeticsSystem:CycleAura(): string
	self.auraIndex = (self.auraIndex % #CosmeticsSystem.AuraOrder) + 1
	local name = CosmeticsSystem.AuraOrder[self.auraIndex]
	self:_applyAura(name)
	return name
end

function CosmeticsSystem:PlayNextEmote(): string?
	if not self.animationSystem then
		return nil
	end
	self.emoteIndex = (self.emoteIndex % #CosmeticsSystem.Emotes) + 1
	local name = CosmeticsSystem.Emotes[self.emoteIndex]
	if self.animationSystem:PlayEmote(name) then
		return name
	end
	return nil
end

-- Pulse body color briefly to match equipped shop trail (visual juice only)
function CosmeticsSystem:PulseTrailColor(trailId: string?)
	local def = CosmeticsCatalog.GetTrail(trailId or "default")
	if not def or not self.hrp then
		return
	end
	local highlight = self.character:FindFirstChild("AuraFarmPulse")
	if not highlight then
		highlight = Instance.new("Highlight")
		highlight.Name = "AuraFarmPulse"
		highlight.FillTransparency = 1
		highlight.OutlineTransparency = 0.2
		highlight.Parent = self.character
	end
	highlight.OutlineColor = def.color
	highlight.FillColor = def.color
	highlight.FillTransparency = 0.85
	TweenService:Create(highlight, TweenInfo.new(0.6), {
		FillTransparency = 1,
		OutlineTransparency = 1,
	}):Play()
end

function CosmeticsSystem:SetEnabled(on: boolean)
	if self.emitter then
		self.emitter.Enabled = on
	end
	if self.light then
		self.light.Enabled = on
	end
end

function CosmeticsSystem:Destroy()
	self:_clearAura()
	if self.folder then
		self.folder:Destroy()
	end
	local h = self.character and self.character:FindFirstChild("AuraFarmPulse")
	if h then
		h:Destroy()
	end
	local att = self.hrp and self.hrp:FindFirstChild("AuraFarmAuraAtt")
	if att then
		att:Destroy()
	end
end

return CosmeticsSystem
