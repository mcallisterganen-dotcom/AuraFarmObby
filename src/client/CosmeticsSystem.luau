-- Client aura body FX + emotes. Server owns shop trails (TrailService).

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local CosmeticsCatalog = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("CosmeticsCatalog"))
local AuraTheme = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("AuraTheme"))

local CosmeticsSystem = {}
CosmeticsSystem.__index = CosmeticsSystem

local function makeAuraAttachment(hrp: BasePart): ParticleEmitter
	local att = hrp:FindFirstChild("AuraFarmAtt")
	if not att then
		att = Instance.new("Attachment")
		att.Name = "AuraFarmAtt"
		att.Parent = hrp
	end
	local pe = att:FindFirstChild("AuraParticles") :: ParticleEmitter?
	if pe then
		return pe
	end
	pe = Instance.new("ParticleEmitter")
	pe.Name = "AuraParticles"
	pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	pe.Rate = 18
	pe.Lifetime = NumberRange.new(0.5, 1.0)
	pe.Speed = NumberRange.new(0.4, 1.6)
	pe.SpreadAngle = Vector2.new(40, 40)
	pe.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.35),
		NumberSequenceKeypoint.new(1, 0),
	})
	pe.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(1, 1),
	})
	pe.Color = ColorSequence.new(AuraTheme.Colors.Accent, AuraTheme.Colors.AccentHot)
	pe.LightEmission = 0.7
	pe.LockedToPart = false
	pe.Parent = att
	return pe
end

function CosmeticsSystem.new(character: Model, humanoid: Humanoid, hrp: BasePart)
	local self = setmetatable({}, CosmeticsSystem)
	self.character = character
	self.humanoid = humanoid
	self.hrp = hrp
	self.emitter = makeAuraAttachment(hrp)
	self._trailId = "default"
	self._destroyed = false

	-- Soft aura point light
	local light = hrp:FindFirstChild("AuraBodyLight")
	if not light then
		light = Instance.new("PointLight")
		light.Name = "AuraBodyLight"
		light.Parent = hrp
	end
	light.Brightness = 0.6
	light.Range = 10
	light.Color = AuraTheme.Colors.Accent
	self.light = light

	return self
end

function CosmeticsSystem:SetTrailId(trailId: string?)
	self._trailId = trailId or "default"
	local def = CosmeticsCatalog.GetTrail(self._trailId) or CosmeticsCatalog.GetTrail("default")
	if def and self.emitter then
		self.emitter.Color = ColorSequence.new(def.color, def.color2 or def.color)
	end
	if def and self.light then
		self.light.Color = def.color
	end
end

function CosmeticsSystem:SetEnabled(on: boolean)
	if self.emitter then
		self.emitter.Enabled = on
	end
	if self.light then
		self.light.Enabled = on
	end
end

function CosmeticsSystem:PulseTrailColor(trailId: string?)
	local def = CosmeticsCatalog.GetTrail(trailId or self._trailId)
	if not def or not self.hrp then
		return
	end
	local highlight = self.character:FindFirstChild("AuraPulse")
	if not highlight then
		highlight = Instance.new("Highlight")
		highlight.Name = "AuraPulse"
		highlight.FillTransparency = 0.7
		highlight.OutlineTransparency = 0.3
		highlight.Parent = self.character
	end
	highlight.OutlineColor = def.color
	highlight.FillColor = def.color
	highlight.Enabled = true
	task.delay(0.45, function()
		if highlight and highlight.Parent then
			highlight.Enabled = false
		end
	end)
end

-- Cycle through catalog trails for local aura color (Y key in PlayerClient).
function CosmeticsSystem:CycleAura(): string
	local trails = CosmeticsCatalog.All()
	local list = {}
	for _, def in ipairs(trails) do
		if type(def) == "table" and def.id then
			table.insert(list, def.id)
		end
	end
	if #list == 0 then
		return self._trailId or "default"
	end
	local cur = self._trailId or "default"
	local idx = 1
	for i, id in ipairs(list) do
		if id == cur then
			idx = i
			break
		end
	end
	local nextId = list[(idx % #list) + 1]
	self:SetTrailId(nextId)
	self:PulseTrailColor(nextId)
	return nextId
end

function CosmeticsSystem:Destroy()
	self._destroyed = true
	if self.emitter then
		self.emitter.Enabled = false
	end
end

return CosmeticsSystem
