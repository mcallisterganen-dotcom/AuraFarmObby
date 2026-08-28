-- Applies equipped trail cosmetic to character.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CosmeticsCatalog = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("CosmeticsCatalog"))

local TrailService = {}

local function clearTrails(character: Model)
	for _, d in character:GetDescendants() do
		if d:IsA("Trail") and d:GetAttribute("AuraFarmTrail") then
			d:Destroy()
		end
		if d:IsA("Attachment") and d:GetAttribute("AuraFarmTrail") then
			d:Destroy()
		end
	end
end

function TrailService.Apply(character: Model, trailId: string?)
	if not character then
		return
	end
	clearTrails(character)

	local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		return
	end

	local def = CosmeticsCatalog.GetTrail(trailId or "default")
		or CosmeticsCatalog.GetTrail("default")
	if not def then
		return
	end

	local a0 = Instance.new("Attachment")
	a0.Name = "AuraTrailA0"
	a0.Position = Vector3.new(0, 0.6, 0)
	a0:SetAttribute("AuraFarmTrail", true)
	a0.Parent = hrp

	local a1 = Instance.new("Attachment")
	a1.Name = "AuraTrailA1"
	a1.Position = Vector3.new(0, -0.8, 0)
	a1:SetAttribute("AuraFarmTrail", true)
	a1.Parent = hrp

	local w = def.widthScale or 0.5
	local trail = Instance.new("Trail")
	trail.Name = "AuraFarmTrail"
	trail.Attachment0 = a0
	trail.Attachment1 = a1
	trail.Color = ColorSequence.new(def.color, def.color2 or def.color)
	trail.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.15),
		NumberSequenceKeypoint.new(1, 1),
	})
	trail.Lifetime = def.lifetime or 0.55
	trail.FaceCamera = true
	trail.LightEmission = def.lightEmission or 0.5
	trail.WidthScale = NumberSequence.new(w, w * 0.1)
	trail:SetAttribute("AuraFarmTrail", true)
	trail.Parent = hrp
end

return TrailService
