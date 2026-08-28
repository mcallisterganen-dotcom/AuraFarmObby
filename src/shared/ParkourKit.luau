-- Reusable parkour primitives. All gameplay tags match ObbyConfig.
-- Forward progress is typically -Z from a local origin.

local TweenService = game:GetService("TweenService")
local ObbyConfig = require(script.Parent:WaitForChild("ObbyConfig"))

local ParkourKit = {}

export type Theme = {
	path: Color3,
	accent: Color3,
	kill: Color3,
	metal: Color3,
	wood: Color3,
}

function ParkourKit.DefaultTheme(): Theme
	return {
		path = Color3.fromRGB(72, 168, 110),
		accent = Color3.fromRGB(190, 255, 160),
		kill = Color3.fromRGB(200, 60, 70),
		metal = Color3.fromRGB(90, 95, 110),
		wood = Color3.fromRGB(120, 85, 55),
	}
end

function ParkourKit.Part(props: { [string]: any }): BasePart
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = props.Material or Enum.Material.Slate
	p.Color = props.Color or Color3.fromRGB(100, 100, 100)
	p.Size = props.Size or Vector3.new(4, 1, 4)
	p.CFrame = props.CFrame or CFrame.new(props.Position or Vector3.zero)
	p.Name = props.Name or "Part"
	p.CanCollide = if props.CanCollide == nil then true else props.CanCollide
	p.Transparency = props.Transparency or 0
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
	a.Parent = parent
	local l = Instance.new("PointLight")
	l.Brightness = brightness or 1.2
	l.Range = range or 16
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
		Material = Enum.Material.Slate,
	})
	-- thin accent lip
	ParkourKit.Part({
		Name = (name or "Pad") .. "Lip",
		Parent = parent,
		Size = Vector3.new(size.X + 0.2, 0.35, size.Z + 0.2),
		Position = at + Vector3.new(0, size.Y * 0.5 + 0.1, 0),
		Color = theme.accent,
		Material = Enum.Material.Neon,
		CanCollide = false,
		Transparency = 0.35,
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
	local len = z1 - z0
	local mid = (z0 + z1) * 0.5
	return ParkourKit.Pad(parent, Vector3.new(x, y, mid), Vector3.new(width, 1.2, len), theme, "Path")
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
	-- returns final Z (more negative)
	local z = start.Z
	local y = start.Y
	local x = start.X
	local sway = xSway or 0
	for i = 1, count do
		local ox = if sway == 0 then 0 else math.sin(i * 1.2) * sway
		ParkourKit.Pad(
			parent,
			Vector3.new(x + ox, y, z),
			padSize,
			theme,
			"GapPad" .. i
		)
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
	dirZ: number? -- -1 forward (default)
): Vector3
	local dz = dirZ or -1
	local pos = start
	for i = 1, steps do
		pos = Vector3.new(start.X, start.Y + (i - 1) * stepHeight, start.Z + dz * (i - 1) * stepDepth)
		ParkourKit.Pad(parent, pos, Vector3.new(width, 1, stepDepth + 0.2), theme, "Step" .. i)
	end
	local endPos = Vector3.new(
		start.X,
		start.Y + (steps - 1) * stepHeight,
		start.Z + dz * (steps - 1) * stepDepth
	)
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
		Name = "Kill",
		Parent = parent,
		Size = size,
		Position = at,
		Color = theme.kill,
		Material = Enum.Material.Neon,
		Attribute = { [ObbyConfig.KillTag] = true },
	})
	p.Name = "KillBrick"
	-- ObbyServer looks for Attribute or name patterns — set both attribute styles
	p:SetAttribute("Kill", true)
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
	task.spawn(function()
		local t0 = os.clock()
		while p.Parent do
			local t = (os.clock() - t0) / period
			local o = math.sin(t * math.pi * 2) * amp
			p.Position = base + axis.Unit * o
			-- lip if present
			local lip = p.Parent and p.Parent:FindFirstChild(p.Name .. "Lip")
			-- lips are separate named parts created after — skip
			task.wait(0.03)
		end
	end)
	return p
end

function ParkourKit.Checkpoint(parent: Instance, index: number, at: Vector3, theme: Theme): BasePart
	local pad = ParkourKit.Part({
		Name = "Checkpoint" .. index,
		Parent = parent,
		Size = Vector3.new(10, 1.4, 10),
		Position = at,
		Color = Color3.fromRGB(80, 160, 255),
		Material = Enum.Material.ForceField,
	})
	pad:SetAttribute(ObbyConfig.CheckpointTag, index)
	pad:SetAttribute("CheckpointIndex", index)

	local beacon = ParkourKit.Part({
		Name = "CP" .. index .. "Beacon",
		Parent = parent,
		Size = Vector3.new(1.2, 16, 1.2),
		Position = at + Vector3.new(0, 9, 0),
		Color = theme.accent,
		Material = Enum.Material.Neon,
		CanCollide = false,
		Transparency = 0.25,
	})
	ParkourKit.Light(parent, at + Vector3.new(0, 10, 0), theme.accent, 2, 28)

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
	tl.TextStrokeTransparency = 0.5
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
		Color = Color3.fromRGB(255, 220, 90),
		Material = Enum.Material.Neon,
	})
	pad:SetAttribute(ObbyConfig.FinishTag, true)
	pad:SetAttribute("Finish", true)

	-- arch
	ParkourKit.Part({
		Name = "FinishArchL",
		Parent = parent,
		Size = Vector3.new(1.5, 14, 1.5),
		Position = at + Vector3.new(-8, 7, 0),
		Color = theme.accent,
		Material = Enum.Material.Neon,
		CanCollide = false,
	})
	ParkourKit.Part({
		Name = "FinishArchR",
		Parent = parent,
		Size = Vector3.new(1.5, 14, 1.5),
		Position = at + Vector3.new(8, 7, 0),
		Color = theme.accent,
		Material = Enum.Material.Neon,
		CanCollide = false,
	})
	ParkourKit.Part({
		Name = "FinishArchTop",
		Parent = parent,
		Size = Vector3.new(18, 1.5, 1.5),
		Position = at + Vector3.new(0, 14, 0),
		Color = Color3.fromRGB(255, 240, 150),
		Material = Enum.Material.Neon,
		CanCollide = false,
	})
	ParkourKit.Light(parent, at + Vector3.new(0, 12, 0), Color3.fromRGB(255, 230, 120), 3, 36)

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
	tl.TextColor3 = Color3.fromRGB(255, 240, 160)
	tl.TextStrokeTransparency = 0.4
	tl.Text = "FINISH"
	tl.Parent = bb
	return pad
end

function ParkourKit.Orb(parent: Instance, at: Vector3, aura: number?): BasePart
	local o = ParkourKit.Part({
		Name = "AuraOrb",
		Parent = parent,
		Size = Vector3.new(2.2, 2.2, 2.2),
		Position = at,
		Color = Color3.fromRGB(200, 140, 255),
		Material = Enum.Material.Neon,
		Shape = Enum.PartType.Ball,
		CanCollide = false,
	})
	o:SetAttribute(ObbyConfig.OrbTag, true)
	o:SetAttribute("Orb", true)
	o:SetAttribute("Aura", aura or ObbyConfig.OrbAura or 2)
	ParkourKit.Light(parent, at, Color3.fromRGB(210, 150, 255), 1.5, 12)

	task.spawn(function()
		local base = at
		local t0 = os.clock()
		while o.Parent do
			local t = os.clock() - t0
			o.Position = base + Vector3.new(0, math.sin(t * 2) * 0.6, 0)
			o.CFrame = CFrame.new(o.Position) * CFrame.Angles(0, t * 1.5, 0)
			task.wait(0.03)
		end
	end)
	return o
end

function ParkourKit.GuideArrow(parent: Instance, at: Vector3, theme: Theme)
	local a = ParkourKit.Part({
		Name = "GuideArrow",
		Parent = parent,
		Size = Vector3.new(2, 0.4, 4),
		Position = at,
		Color = theme.accent,
		Material = Enum.Material.Neon,
		CanCollide = false,
		Transparency = 0.2,
	})
	-- point -Z
	a.CFrame = CFrame.new(at) * CFrame.Angles(0, 0, 0)
end

function ParkourKit.SafetyRails(parent: Instance, at: Vector3, length: number, width: number, theme: Theme)
	local y = at.Y + 1.2
	ParkourKit.Part({
		Name = "RailL",
		Parent = parent,
		Size = Vector3.new(0.6, 2.2, length),
		Position = Vector3.new(at.X - width * 0.5, y, at.Z),
		Color = theme.metal,
		Material = Enum.Material.Metal,
		CanCollide = true,
	})
	ParkourKit.Part({
		Name = "RailR",
		Parent = parent,
		Size = Vector3.new(0.6, 2.2, length),
		Position = Vector3.new(at.X + width * 0.5, y, at.Z),
		Color = theme.metal,
		Material = Enum.Material.Metal,
		CanCollide = true,
	})
end

function ParkourKit.BouncePad(parent: Instance, at: Vector3, theme: Theme, power: number?): BasePart
	local p = ParkourKit.Part({
		Name = "Bounce",
		Parent = parent,
		Size = Vector3.new(8, 1.2, 8),
		Position = at,
		Color = Color3.fromRGB(255, 140, 60),
		Material = Enum.Material.Neon,
	})
	p:SetAttribute("Bounce", power or 70)
	local spawn = Instance.new("SpawnLocation")
	-- use Touched bounce via attribute; ObbyServer/client can read Bounce
	return p
end

return ParkourKit
