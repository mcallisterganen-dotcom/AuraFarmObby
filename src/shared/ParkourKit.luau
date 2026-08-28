-- Parkour primitives — path-only, readable mats, reliable orbs.

local ObbyConfig = require(script.Parent:WaitForChild("ObbyConfig"))
local AuraTheme = require(script.Parent:WaitForChild("AuraTheme"))

local ParkourKit = {}

export type Theme = {
	path: Color3,
	accent: Color3,
	kill: Color3,
	metal: Color3,
	wood: Color3,
	ground: Color3?,
}

local orbSerial = 0

function ParkourKit.DefaultTheme(): Theme
	local C = AuraTheme.Colors
	return {
		path = C.Path,
		accent = C.Accent,
		kill = C.Danger,
		metal = Color3.fromRGB(70, 60, 100),
		wood = Color3.fromRGB(90, 60, 120),
		ground = C.Ground,
	}
end

function ParkourKit.Part(props: { [string]: any }): BasePart
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = props.Material or Enum.Material.SmoothPlastic
	p.Color = props.Color or AuraTheme.Colors.Path
	p.Size = props.Size or Vector3.new(4, 1, 4)
	p.CFrame = props.CFrame or CFrame.new(props.Position or Vector3.zero)
	p.Name = props.Name or "Part"
	p.CanCollide = if props.CanCollide == nil then true else props.CanCollide
	p.CanTouch = if props.CanTouch == nil then true else props.CanTouch
	p.Transparency = props.Transparency or 0
	p.CastShadow = props.CastShadow ~= false
	if props.Friction or props.IsPath then
		p.CustomPhysicalProperties = PhysicalProperties.new(
			props.Density or 1,
			props.Friction or 1.25,
			props.Elasticity or 0,
			props.FrictionWeight or 2,
			props.ElasticityWeight or 1
		)
	end
	if props.Shape then
		p.Shape = props.Shape
	end
	if props.IsPath then
		p:SetAttribute("IsPath", true)
		p.CanCollide = true
	end
	p.Parent = props.Parent
	if props.Attribute then
		for k, v in props.Attribute do
			p:SetAttribute(k, v)
		end
	end
	return p
end

function ParkourKit.Light(parent: Instance, pos: Vector3, color: Color3, brightness: number?, range: number?)
	local a = Instance.new("Part")
	a.Name = "LightAnchor"
	a.Anchored = true
	a.CanCollide = false
	a.CanTouch = false
	a.Transparency = 1
	a.Size = Vector3.new(0.4, 0.4, 0.4)
	a.Position = pos
	a.CastShadow = false
	a.Parent = parent
	local l = Instance.new("PointLight")
	l.Brightness = brightness or 0.9
	l.Range = range or 14
	l.Color = color
	l.Parent = a
	return a
end

function ParkourKit.Pad(
	parent: Instance,
	at: Vector3,
	size: Vector3,
	theme: Theme,
	name: string?
): BasePart
	local p = ParkourKit.Part({
		Name = name or "Pad",
		Parent = parent,
		Size = size,
		Position = at,
		Color = theme.path,
		Material = Enum.Material.SmoothPlastic,
		Friction = 1.3,
		IsPath = true,
	})
	-- Soft readable rim (not blinding neon)
	local rimColor = theme.path:Lerp(theme.accent, 0.3)
	ParkourKit.Part({
		Name = (name or "Pad") .. "Edge",
		Parent = parent,
		Size = Vector3.new(size.X + 0.22, 0.16, size.Z + 0.22),
		Position = at + Vector3.new(0, size.Y * 0.5 + 0.03, 0),
		Color = rimColor,
		Material = Enum.Material.SmoothPlastic,
		CanCollide = false,
		CanTouch = false,
		Transparency = 0.5,
		CastShadow = false,
	})
	return p
end

function ParkourKit.LongPath(
	parent: Instance,
	fromZ: number,
	toZ: number,
	y: number,
	x: number,
	width: number,
	theme: Theme
): BasePart
	local z0, z1 = math.min(fromZ, toZ), math.max(fromZ, toZ)
	local len = math.max(z1 - z0, 2)
	local mid = (z0 + z1) * 0.5
	return ParkourKit.Pad(parent, Vector3.new(x, y, mid), Vector3.new(width, 1.4, len), theme, "Path")
end

function ParkourKit.GapRun(
	parent: Instance,
	start: Vector3,
	count: number,
	gap: number,
	padSize: Vector3,
	theme: Theme,
	xSway: number?
): number
	local z = start.Z
	local y = start.Y
	local x = start.X
	local sway = xSway or 0
	for i = 1, count do
		local ox = if sway == 0 then 0 else math.sin(i * 1.2) * sway
		ParkourKit.Pad(parent, Vector3.new(x + ox, y, z), padSize, theme, "GapPad" .. i)
		z -= padSize.Z * 0.5 + gap + padSize.Z * 0.5
	end
	return z
end

function ParkourKit.Staircase(
	parent: Instance,
	start: Vector3,
	steps: number,
	stepHeight: number,
	stepDepth: number,
	width: number,
	theme: Theme,
	dirZ: number?
): Vector3
	local dz = dirZ or -1
	local endPos = start
	for i = 1, steps do
		endPos = Vector3.new(
			start.X,
			start.Y + (i - 1) * stepHeight,
			start.Z + dz * (i - 1) * stepDepth
		)
		ParkourKit.Pad(parent, endPos, Vector3.new(width, 1.2, stepDepth + 0.25), theme, "Step" .. i)
	end
	return endPos
end

function ParkourKit.Weave(
	parent: Instance,
	start: Vector3,
	count: number,
	spacing: number,
	amplitude: number,
	padSize: Vector3,
	theme: Theme
): number
	local z = start.Z
	for i = 1, count do
		local side = if i % 2 == 0 then amplitude else -amplitude
		ParkourKit.Pad(parent, Vector3.new(start.X + side, start.Y, z), padSize, theme, "Weave" .. i)
		z -= spacing
	end
	return z
end

function ParkourKit.KillBrick(parent: Instance, at: Vector3, size: Vector3, theme: Theme): BasePart
	local p = ParkourKit.Part({
		Name = "KillBrick",
		Parent = parent,
		Size = size,
		Position = at,
		Color = theme.kill,
		Material = Enum.Material.SmoothPlastic,
		Friction = 0.3,
		CanCollide = true,
	})
	p.Transparency = 0.4
	p:SetAttribute(ObbyConfig.KillTag, true)
	p:SetAttribute("Kill", true)
	ParkourKit.Light(parent, at + Vector3.new(0, 2, 0), theme.kill, 0.8, 16)
	return p
end

function ParkourKit.MovingPad(
	parent: Instance,
	at: Vector3,
	size: Vector3,
	theme: Theme,
	axis: Vector3,
	amp: number,
	period: number
): BasePart
	local p = ParkourKit.Pad(parent, at, size, theme, "Mover")
	p:SetAttribute("Moving", true)
	local base = at
	local unit = if axis.Magnitude > 0 then axis.Unit else Vector3.xAxis
	task.spawn(function()
		local t0 = os.clock()
		while p.Parent do
			local t = (os.clock() - t0) / math.max(period, 0.1)
			local o = math.sin(t * math.pi * 2) * amp
			p.Position = base + unit * o
			local edge = p.Parent and p.Parent:FindFirstChild(p.Name .. "Edge")
			if edge and edge:IsA("BasePart") then
				edge.Position = p.Position + Vector3.new(0, p.Size.Y * 0.5 + 0.03, 0)
			end
			task.wait(0.03)
		end
	end)
	return p
end

function ParkourKit.Checkpoint(parent: Instance, index: number, at: Vector3, theme: Theme): BasePart
	local pad = ParkourKit.Part({
		Name = "Checkpoint" .. index,
		Parent = parent,
		Size = Vector3.new(10, 1.5, 10),
		Position = at,
		Color = Color3.fromRGB(55, 70, 110),
		Material = Enum.Material.SmoothPlastic,
		Friction = 1.3,
		IsPath = true,
	})
	pad:SetAttribute(ObbyConfig.CheckpointTag, index)
	pad:SetAttribute("CheckpointIndex", index)

	ParkourKit.Part({
		Name = "CP" .. index .. "Ring",
		Parent = parent,
		Size = Vector3.new(11, 0.3, 11),
		Position = at + Vector3.new(0, 0.9, 0),
		Color = theme.accent,
		Material = Enum.Material.SmoothPlastic,
		CanCollide = false,
		Transparency = 0.55,
	})
	ParkourKit.Part({
		Name = "CP" .. index .. "Beacon",
		Parent = parent,
		Size = Vector3.new(0.6, 12, 0.6),
		Position = at + Vector3.new(0, 7, 0),
		Color = theme.accent,
		Material = Enum.Material.Neon,
		CanCollide = false,
		Transparency = 0.55,
	})
	ParkourKit.Light(parent, at + Vector3.new(0, 6, 0), theme.accent, 0.7, 14)

	local bb = Instance.new("BillboardGui")
	bb.Name = "CPLabel"
	bb.Size = UDim2.fromOffset(120, 40)
	bb.StudsOffset = Vector3.new(0, 12, 0)
	bb.AlwaysOnTop = true
	bb.Parent = pad
	local tl = Instance.new("TextLabel")
	tl.Size = UDim2.fromScale(1, 1)
	tl.BackgroundTransparency = 1
	tl.Font = Enum.Font.GothamBold
	tl.TextSize = 18
	tl.TextColor3 = Color3.new(1, 1, 1)
	tl.TextStrokeTransparency = 0.4
	tl.Text = "CP " .. index
	tl.Parent = bb
	return pad
end

function ParkourKit.Finish(parent: Instance, at: Vector3, theme: Theme): BasePart
	local pad = ParkourKit.Part({
		Name = "Finish",
		Parent = parent,
		Size = Vector3.new(16, 1.6, 16),
		Position = at,
		Color = Color3.fromRGB(120, 95, 50),
		Material = Enum.Material.SmoothPlastic,
		Friction = 1.3,
		IsPath = true,
	})
	pad:SetAttribute(ObbyConfig.FinishTag, true)
	pad:SetAttribute("Finish", true)

	ParkourKit.Part({
		Name = "FinishGlow",
		Parent = parent,
		Size = Vector3.new(17, 0.3, 17),
		Position = at + Vector3.new(0, 1.0, 0),
		Color = AuraTheme.Colors.Gold,
		Material = Enum.Material.SmoothPlastic,
		CanCollide = false,
		Transparency = 0.5,
	})
	ParkourKit.Part({
		Name = "FinishArchL",
		Parent = parent,
		Size = Vector3.new(1.2, 12, 1.2),
		Position = at + Vector3.new(-8, 6, 0),
		Color = theme.accent,
		Material = Enum.Material.Neon,
		CanCollide = false,
		Transparency = 0.4,
	})
	ParkourKit.Part({
		Name = "FinishArchR",
		Parent = parent,
		Size = Vector3.new(1.2, 12, 1.2),
		Position = at + Vector3.new(8, 6, 0),
		Color = theme.accent,
		Material = Enum.Material.Neon,
		CanCollide = false,
		Transparency = 0.4,
	})
	ParkourKit.Part({
		Name = "FinishArchTop",
		Parent = parent,
		Size = Vector3.new(18, 1.2, 1.2),
		Position = at + Vector3.new(0, 12, 0),
		Color = AuraTheme.Colors.Gold,
		Material = Enum.Material.Neon,
		CanCollide = false,
		Transparency = 0.35,
	})
	ParkourKit.Light(parent, at + Vector3.new(0, 10, 0), AuraTheme.Colors.Gold, 1.2, 20)

	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(160, 48)
	bb.StudsOffset = Vector3.new(0, 14, 0)
	bb.AlwaysOnTop = true
	bb.Parent = pad
	local tl = Instance.new("TextLabel")
	tl.Size = UDim2.fromScale(1, 1)
	tl.BackgroundTransparency = 1
	tl.Font = Enum.Font.GothamBold
	tl.TextSize = 22
	tl.TextColor3 = AuraTheme.Colors.Gold
	tl.TextStrokeTransparency = 0.3
	tl.Text = "FINISH"
	tl.Parent = bb
	return pad
end

-- Reliable orb: unique id, large touch proxy, tagged, non-solid
function ParkourKit.Orb(parent: Instance, at: Vector3, aura: number?, stageId: number?): BasePart
	orbSerial += 1
	local id = string.format("orb_%d_%d", stageId or 0, orbSerial)
	local value = aura or ObbyConfig.OrbAura or 2

	-- Visible core
	local o = ParkourKit.Part({
		Name = "AuraOrb",
		Parent = parent,
		Size = Vector3.new(2.2, 2.2, 2.2),
		Position = at,
		Color = AuraTheme.Colors.Accent,
		Material = Enum.Material.Neon,
		Shape = Enum.PartType.Ball,
		CanCollide = false,
		CanTouch = true,
		CastShadow = false,
	})
	o:SetAttribute(ObbyConfig.OrbTag, true)
	o:SetAttribute("Orb", true)
	o:SetAttribute("Aura", value)
	o:SetAttribute("OrbId", id)
	o:SetAttribute("OrbValue", value)
	if stageId then
		o:SetAttribute("StageId", stageId)
	end

	-- Invisible larger touch hull (easier pickup)
	local hull = ParkourKit.Part({
		Name = "AuraOrbHull",
		Parent = parent,
		Size = Vector3.new(5, 5, 5),
		Position = at,
		Color = AuraTheme.Colors.Accent,
		Material = Enum.Material.ForceField,
		CanCollide = false,
		CanTouch = true,
		Transparency = 0.92,
		CastShadow = false,
	})
	hull:SetAttribute(ObbyConfig.OrbTag, true)
	hull:SetAttribute("Orb", true)
	hull:SetAttribute("Aura", value)
	hull:SetAttribute("OrbId", id)
	hull:SetAttribute("OrbValue", value)
	hull:SetAttribute("OrbHull", true)
	if stageId then
		hull:SetAttribute("StageId", stageId)
	end

	ParkourKit.Light(parent, at, AuraTheme.Colors.Accent, 1.2, 12)

	-- Billboard value
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(60, 28)
	bb.StudsOffset = Vector3.new(0, 2.2, 0)
	bb.AlwaysOnTop = false
	bb.Parent = o
	local tl = Instance.new("TextLabel")
	tl.Size = UDim2.fromScale(1, 1)
	tl.BackgroundTransparency = 1
	tl.Font = Enum.Font.GothamBold
	tl.TextSize = 14
	tl.TextColor3 = Color3.new(1, 1, 1)
	tl.TextStrokeTransparency = 0.5
	tl.Text = "+" .. tostring(value)
	tl.Parent = bb

	task.spawn(function()
		local base = at
		local t0 = os.clock()
		while o.Parent do
			local t = os.clock() - t0
			local pos = base + Vector3.new(0, math.sin(t * 2.2) * 0.55, 0)
			o.CFrame = CFrame.new(pos) * CFrame.Angles(0, t * 1.8, 0)
			if hull.Parent then
				hull.Position = pos
			end
			task.wait(0.03)
		end
	end)
	return o
end

function ParkourKit.GuideArrow(parent: Instance, at: Vector3, theme: Theme)
	ParkourKit.Part({
		Name = "GuideArrow",
		Parent = parent,
		Size = Vector3.new(2.0, 0.3, 4.0),
		Position = at,
		Color = theme.accent,
		Material = Enum.Material.SmoothPlastic,
		CanCollide = false,
		Transparency = 0.35,
	})
end

function ParkourKit.SafetyRails(parent: Instance, at: Vector3, length: number, width: number, theme: Theme)
	local y = at.Y + 1.3
	ParkourKit.Part({
		Name = "RailL",
		Parent = parent,
		Size = Vector3.new(0.55, 2.4, length),
		Position = Vector3.new(at.X - width * 0.5, y, at.Z),
		Color = theme.metal,
		Material = Enum.Material.Metal,
		IsPath = true,
	})
	ParkourKit.Part({
		Name = "RailR",
		Parent = parent,
		Size = Vector3.new(0.55, 2.4, length),
		Position = Vector3.new(at.X + width * 0.5, y, at.Z),
		Color = theme.metal,
		Material = Enum.Material.Metal,
		IsPath = true,
	})
end

function ParkourKit.BouncePad(parent: Instance, at: Vector3, theme: Theme, power: number?): BasePart
	local p = ParkourKit.Part({
		Name = "Bounce",
		Parent = parent,
		Size = Vector3.new(8, 1.3, 8),
		Position = at,
		Color = Color3.fromRGB(180, 100, 50),
		Material = Enum.Material.SmoothPlastic,
		Friction = 1.0,
		IsPath = true,
	})
	local powerVal = power or 70
	p:SetAttribute(ObbyConfig.BounceTag, powerVal)
	p:SetAttribute("BouncePower", powerVal)
	ParkourKit.Part({
		Name = "BounceGlow",
		Parent = parent,
		Size = Vector3.new(8.4, 0.3, 8.4),
		Position = at + Vector3.new(0, 0.85, 0),
		Color = Color3.fromRGB(255, 160, 80),
		Material = Enum.Material.SmoothPlastic,
		CanCollide = false,
		Transparency = 0.45,
	})
	return p
end

return ParkourKit
