-- Parkour primitives — AURA FARM materials.
-- Run surfaces = SmoothPlastic (grip + readable). Neon ONLY on edges/accents.
-- Tags match ObbyConfig.

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
	p.Material = props.Material or AuraTheme.Materials.Path
	p.Color = props.Color or AuraTheme.Colors.Path
	p.Size = props.Size or Vector3.new(4, 1, 4)
	p.CFrame = props.CFrame or CFrame.new(props.Position or Vector3.zero)
	p.Name = props.Name or "Part"
	p.CanCollide = if props.CanCollide == nil then true else props.CanCollide
	p.Transparency = props.Transparency or 0
	p.CastShadow = props.CastShadow ~= false
	-- Critical: custom physical properties so neon-looking pads aren't ice
	if props.Friction or props.Material == Enum.Material.SmoothPlastic or not props.Material then
		p.CustomPhysicalProperties = PhysicalProperties.new(
			props.Density or 1,
			props.Friction or 1.1, -- grippy
			props.Elasticity or 0,
			props.FrictionWeight or 2,
			props.ElasticityWeight or 1
		)
	end
	if props.Shape then
		p.Shape = props.Shape
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
	a.Transparency = 1
	a.Size = Vector3.new(0.4, 0.4, 0.4)
	a.Position = pos
	a.CastShadow = false
	a.Parent = parent
	local l = Instance.new("PointLight")
	l.Brightness = brightness or 1.4
	l.Range = range or 18
	l.Color = color
	l.Parent = a
	return a
end

-- Main run pad: dark plastic body + neon EDGE only (not the whole floor)
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
		Material = AuraTheme.Materials.Path,
		Friction = 1.2,
	})
	-- edge ring (non-colliding neon lip)
	local lip = ParkourKit.Part({
		Name = (name or "Pad") .. "Edge",
		Parent = parent,
		Size = Vector3.new(size.X + 0.35, 0.28, size.Z + 0.35),
		Position = at + Vector3.new(0, size.Y * 0.5 + 0.05, 0),
		Color = theme.accent,
		Material = AuraTheme.Materials.PathAccent,
		CanCollide = false,
		Transparency = 0.15,
		CastShadow = false,
	})
	-- skip heavy physical props on lip
	lip.CustomPhysicalProperties = PhysicalProperties.new(0.3, 0.3, 0, 1, 1)
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
		ParkourKit.Pad(
			parent,
			Vector3.new(start.X + side, start.Y, z),
			padSize,
			theme,
			"Weave" .. i
		)
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
		Material = AuraTheme.Materials.Glow,
		Friction = 0.3,
	})
	p.Transparency = 0.35
	p:SetAttribute(ObbyConfig.KillTag, true)
	p:SetAttribute("Kill", true)
	-- soft red light
	ParkourKit.Light(parent, at + Vector3.new(0, 2, 0), theme.kill, 1.2, 24)
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
				edge.Position = p.Position + Vector3.new(0, p.Size.Y * 0.5 + 0.05, 0)
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
		Color = Color3.fromRGB(90, 140, 255),
		Material = AuraTheme.Materials.Path,
		Friction = 1.2,
	})
	pad:SetAttribute(ObbyConfig.CheckpointTag, index)
	pad:SetAttribute("CheckpointIndex", index)

	-- glowing ring
	ParkourKit.Part({
		Name = "CP" .. index .. "Ring",
		Parent = parent,
		Size = Vector3.new(11, 0.4, 11),
		Position = at + Vector3.new(0, 0.9, 0),
		Color = theme.accent,
		Material = AuraTheme.Materials.Glow,
		CanCollide = false,
		Transparency = 0.25,
	})

	local beacon = ParkourKit.Part({
		Name = "CP" .. index .. "Beacon",
		Parent = parent,
		Size = Vector3.new(1.0, 18, 1.0),
		Position = at + Vector3.new(0, 10, 0),
		Color = theme.accent,
		Material = AuraTheme.Materials.Glow,
		CanCollide = false,
		Transparency = 0.3,
	})
	ParkourKit.Light(parent, at + Vector3.new(0, 10, 0), theme.accent, 2.2, 30)

	local bb = Instance.new("BillboardGui")
	bb.Name = "CPLabel"
	bb.Size = UDim2.fromOffset(120, 40)
	bb.StudsOffset = Vector3.new(0, 14, 0)
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
		Color = AuraTheme.Colors.Gold,
		Material = AuraTheme.Materials.Path,
		Friction = 1.2,
	})
	pad:SetAttribute(ObbyConfig.FinishTag, true)
	pad:SetAttribute("Finish", true)

	ParkourKit.Part({
		Name = "FinishGlow",
		Parent = parent,
		Size = Vector3.new(17, 0.4, 17),
		Position = at + Vector3.new(0, 1.0, 0),
		Color = AuraTheme.Colors.Gold,
		Material = AuraTheme.Materials.Glow,
		CanCollide = false,
		Transparency = 0.2,
	})

	ParkourKit.Part({
		Name = "FinishArchL",
		Parent = parent,
		Size = Vector3.new(1.5, 14, 1.5),
		Position = at + Vector3.new(-8, 7, 0),
		Color = theme.accent,
		Material = AuraTheme.Materials.Glow,
		CanCollide = false,
	})
	ParkourKit.Part({
		Name = "FinishArchR",
		Parent = parent,
		Size = Vector3.new(1.5, 14, 1.5),
		Position = at + Vector3.new(8, 7, 0),
		Color = theme.accent,
		Material = AuraTheme.Materials.Glow,
		CanCollide = false,
	})
	ParkourKit.Part({
		Name = "FinishArchTop",
		Parent = parent,
		Size = Vector3.new(18, 1.5, 1.5),
		Position = at + Vector3.new(0, 14, 0),
		Color = AuraTheme.Colors.Gold,
		Material = AuraTheme.Materials.Glow,
		CanCollide = false,
	})
	ParkourKit.Light(parent, at + Vector3.new(0, 12, 0), AuraTheme.Colors.Gold, 3.2, 40)

	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(160, 48)
	bb.StudsOffset = Vector3.new(0, 16, 0)
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

function ParkourKit.Orb(parent: Instance, at: Vector3, aura: number?): BasePart
	local o = ParkourKit.Part({
		Name = "AuraOrb",
		Parent = parent,
		Size = Vector3.new(2.4, 2.4, 2.4),
		Position = at,
		Color = AuraTheme.Colors.Accent,
		Material = AuraTheme.Materials.Glow,
		Shape = Enum.PartType.Ball,
		CanCollide = false,
		CastShadow = false,
	})
	o:SetAttribute(ObbyConfig.OrbTag, true)
	o:SetAttribute("Orb", true)
	o:SetAttribute("Aura", aura or ObbyConfig.OrbAura or 2)
	ParkourKit.Light(parent, at, AuraTheme.Colors.Accent, 2, 14)

	task.spawn(function()
		local base = at
		local t0 = os.clock()
		while o.Parent do
			local t = os.clock() - t0
			o.CFrame = CFrame.new(base + Vector3.new(0, math.sin(t * 2.2) * 0.7, 0))
				* CFrame.Angles(0, t * 1.8, 0)
			task.wait(0.03)
		end
	end)
	return o
end

function ParkourKit.GuideArrow(parent: Instance, at: Vector3, theme: Theme)
	ParkourKit.Part({
		Name = "GuideArrow",
		Parent = parent,
		Size = Vector3.new(2.2, 0.35, 4.5),
		Position = at,
		Color = theme.accent,
		Material = AuraTheme.Materials.Glow,
		CanCollide = false,
		Transparency = 0.15,
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
		Material = AuraTheme.Materials.Metal,
	})
	ParkourKit.Part({
		Name = "RailR",
		Parent = parent,
		Size = Vector3.new(0.55, 2.4, length),
		Position = Vector3.new(at.X + width * 0.5, y, at.Z),
		Color = theme.metal,
		Material = AuraTheme.Materials.Metal,
	})
end

function ParkourKit.BouncePad(parent: Instance, at: Vector3, theme: Theme, power: number?): BasePart
	local p = ParkourKit.Part({
		Name = "Bounce",
		Parent = parent,
		Size = Vector3.new(8, 1.3, 8),
		Position = at,
		Color = Color3.fromRGB(255, 140, 70),
		Material = AuraTheme.Materials.Path,
		Friction = 1.0,
	})
	p:SetAttribute(ObbyConfig.BounceTag, power or 70)
	ParkourKit.Part({
		Name = "BounceGlow",
		Parent = parent,
		Size = Vector3.new(8.4, 0.35, 8.4),
		Position = at + Vector3.new(0, 0.85, 0),
		Color = Color3.fromRGB(255, 160, 80),
		Material = AuraTheme.Materials.Glow,
		CanCollide = false,
		Transparency = 0.2,
	})
	return p
end

return ParkourKit
