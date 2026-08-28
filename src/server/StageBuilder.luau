-- Aura Farm Stage 1 — designed parkour course (not random pads).
-- Forward axis = -Z. Tags stay compatible with ObbyServer wiring.

local TweenService = game:GetService("TweenService")
local ObbyConfig = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("ObbyConfig"))

local StageBuilder = {}

local PALETTE = {
	Stone = Color3.fromRGB(72, 78, 98),
	StoneLight = Color3.fromRGB(98, 108, 132),
	Path = Color3.fromRGB(86, 140, 220),
	PathAlt = Color3.fromRGB(110, 168, 245),
	Accent = Color3.fromRGB(255, 168, 72),
	AccentDeep = Color3.fromRGB(230, 120, 40),
	Safe = Color3.fromRGB(70, 190, 130),
	SafeDeep = Color3.fromRGB(40, 140, 100),
	Checkpoint = Color3.fromRGB(255, 214, 70),
	CheckpointGlow = Color3.fromRGB(255, 240, 150),
	Kill = Color3.fromRGB(210, 45, 55),
	KillCore = Color3.fromRGB(255, 90, 70),
	Finish = Color3.fromRGB(90, 255, 170),
	FinishRing = Color3.fromRGB(180, 255, 220),
	Mover = Color3.fromRGB(160, 110, 255),
	MoverTrack = Color3.fromRGB(50, 45, 80),
	Orb = Color3.fromRGB(190, 120, 255),
	Guide = Color3.fromRGB(140, 200, 255),
	Trim = Color3.fromRGB(40, 48, 70),
	Neon = Color3.fromRGB(120, 220, 255),
}

local function part(props: { [string]: any }): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.Material = Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CastShadow = true
	for key, value in props do
		(p :: any)[key] = value
	end
	return p
end

local function tag(inst: Instance, name: string)
	inst:SetAttribute("Tag", name)
end

local function weld(a: BasePart, b: BasePart)
	local w = Instance.new("WeldConstraint")
	w.Part0 = a
	w.Part1 = b
	w.Parent = a
end

local function light(parent: Instance, color: Color3, brightness: number, range: number)
	local l = Instance.new("PointLight")
	l.Color = color
	l.Brightness = brightness
	l.Range = range
	l.Parent = parent
	return l
end

local function label(parent: BasePart, text: string, color: Color3?, height: number?)
	local att = Instance.new("Attachment")
	att.Position = Vector3.new(0, height or 4, 0)
	att.Parent = parent
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(220, 36)
	bb.AlwaysOnTop = true
	bb.Parent = att
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.fromScale(1, 1)
	t.Font = Enum.Font.GothamBold
	t.TextScaled = true
	t.TextColor3 = color or Color3.new(1, 1, 1)
	t.TextStrokeTransparency = 0.4
	t.Text = text
	t.Parent = bb
	return bb
end

local function rim(parent: Instance, base: BasePart, thickness: number, color: Color3)
	-- thin edge strip on top for polish
	local top = part({
		Name = base.Name .. "_Rim",
		Size = Vector3.new(base.Size.X + 0.15, thickness, base.Size.Z + 0.15),
		Position = base.Position + Vector3.new(0, base.Size.Y / 2 + thickness / 2, 0),
		Color = color,
		Material = Enum.Material.Neon,
		Transparency = 0.35,
		CanCollide = false,
		Parent = parent,
	})
	return top
end

local function pillar(parent: Instance, at: Vector3, height: number, color: Color3?)
	return part({
		Name = "Pillar",
		Size = Vector3.new(2.4, height, 2.4),
		Position = at + Vector3.new(0, height / 2, 0),
		Color = color or PALETTE.Trim,
		Material = Enum.Material.Slate,
		Parent = parent,
	})
end

local function platform(parent: Instance, name: string, size: Vector3, pos: Vector3, color: Color3, material: Enum.Material?)
	local p = part({
		Name = name,
		Size = size,
		Position = pos,
		Color = color,
		Material = material or Enum.Material.SmoothPlastic,
		Parent = parent,
	})
	-- underside lip
	part({
		Name = name .. "_Lip",
		Size = Vector3.new(size.X * 0.92, 0.5, size.Z * 0.92),
		Position = pos - Vector3.new(0, size.Y / 2 + 0.25, 0),
		Color = PALETTE.Trim,
		Material = Enum.Material.Slate,
		CanCollide = false,
		Parent = parent,
	})
	return p
end

local function checkpoint(parent: Instance, index: number, pos: Vector3)
	local pad = platform(parent, "Checkpoint" .. index, Vector3.new(14, 1.5, 14), pos, PALETTE.Checkpoint, Enum.Material.Neon)
	tag(pad, ObbyConfig.CheckpointTag)
	pad:SetAttribute("Index", index)
	pad.Material = Enum.Material.SmoothPlastic
	pad.Color = PALETTE.Checkpoint

	-- glowing ring
	local ring = part({
		Name = "CP" .. index .. "Ring",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.6, 16, 16),
		CFrame = CFrame.new(pos + Vector3.new(0, 0.9, 0)) * CFrame.Angles(0, 0, math.rad(90)),
		Color = PALETTE.CheckpointGlow,
		Material = Enum.Material.Neon,
		Transparency = 0.25,
		CanCollide = false,
		Parent = parent,
	})

	-- beacon tower
	local beam = part({
		Name = "CP" .. index .. "Beacon",
		Size = Vector3.new(1.2, 14, 1.2),
		Position = pos + Vector3.new(0, 8, 0),
		Color = PALETTE.CheckpointGlow,
		Material = Enum.Material.Neon,
		Transparency = 0.15,
		CanCollide = false,
		Parent = parent,
	})
	light(beam, PALETTE.CheckpointGlow, 2, 28)
	label(pad, "CHECKPOINT " .. index, PALETTE.CheckpointGlow, 10)

	-- corner posts
	for _, off in {
		Vector3.new(5.5, 0, 5.5),
		Vector3.new(-5.5, 0, 5.5),
		Vector3.new(5.5, 0, -5.5),
		Vector3.new(-5.5, 0, -5.5),
	} do
		part({
			Name = "CPPost",
			Size = Vector3.new(1, 3.5, 1),
			Position = pos + off + Vector3.new(0, 1.75, 0),
			Color = PALETTE.Accent,
			Material = Enum.Material.Metal,
			Parent = parent,
		})
	end

	return pad
end

local function killBrick(parent: Instance, name: string, size: Vector3, pos: Vector3)
	local k = part({
		Name = name,
		Size = size,
		Position = pos,
		Color = PALETTE.Kill,
		Material = Enum.Material.Neon,
		Parent = parent,
	})
	tag(k, ObbyConfig.KillTag)
	light(k, PALETTE.KillCore, 1.4, math.max(size.X, size.Z) + 6)
	-- warning stripes via surface appearance-ish second layer
	part({
		Name = name .. "_Warn",
		Size = Vector3.new(size.X * 0.9, size.Y + 0.05, size.Z * 0.15),
		Position = pos + Vector3.new(0, 0.05, 0),
		Color = Color3.fromRGB(255, 210, 60),
		Material = Enum.Material.Neon,
		CanCollide = false,
		Transparency = 0.2,
		Parent = parent,
	})
	return k
end

local function orb(parent: Instance, pos: Vector3, i: number)
	local o = part({
		Name = "AuraOrb_" .. i,
		Shape = Enum.PartType.Ball,
		Size = Vector3.new(2.2, 2.2, 2.2),
		Position = pos,
		Color = PALETTE.Orb,
		Material = Enum.Material.Neon,
		CanCollide = false,
		Parent = parent,
	})
	tag(o, ObbyConfig.OrbTag)
	light(o, PALETTE.Orb, 1.8, 12)
	local spin = Instance.new("Attachment")
	spin.Parent = o
	task.spawn(function()
		local t0 = os.clock()
		while o.Parent do
			local t = os.clock() - t0
			o.CFrame = CFrame.new(pos + Vector3.new(0, math.sin(t * 2) * 0.45, 0)) * CFrame.Angles(0, t * 1.5, 0)
			task.wait(0.03)
		end
	end)
	return o
end

local function guideArrow(parent: Instance, pos: Vector3, yawDeg: number)
	local body = part({
		Name = "Guide",
		Size = Vector3.new(2.5, 0.4, 4),
		CFrame = CFrame.new(pos) * CFrame.Angles(0, math.rad(yawDeg), 0),
		Color = PALETTE.Guide,
		Material = Enum.Material.Neon,
		CanCollide = false,
		Transparency = 0.15,
		Parent = parent,
	})
	local tip = part({
		Name = "GuideTip",
		Size = Vector3.new(3.2, 0.4, 2.2),
		CFrame = body.CFrame * CFrame.new(0, 0, -2.6),
		Color = PALETTE.Neon,
		Material = Enum.Material.Neon,
		CanCollide = false,
		Transparency = 0.1,
		Parent = parent,
	})
	return body
end

function StageBuilder.Build(): Folder
	local existing = workspace:FindFirstChild(ObbyConfig.StageFolderName)
	if existing then
		existing:Destroy()
	end

	for _, child in workspace:GetChildren() do
		if child:IsA("SpawnLocation") then
			child:Destroy()
		elseif child:IsA("BasePart") and (child.Name == "Baseplate" or child.Name == "SpawnLocation") then
			child:Destroy()
		end
	end

	local folder = Instance.new("Folder")
	folder.Name = ObbyConfig.StageFolderName
	folder.Parent = workspace

	local Y = 20 -- elevated course so falls feel intentional
	local z = 0 -- cursor along -Z
	local orbId = 0
	local function nextOrb(pos: Vector3)
		orbId += 1
		orb(folder, pos, orbId)
	end

	----------------------------------------------------------------
	-- 0) SPAWN PLAZA
	----------------------------------------------------------------
	local plaza = platform(folder, "StartPad", Vector3.new(36, 2.5, 36), Vector3.new(0, Y, 0), PALETTE.Safe, Enum.Material.Slate)
	tag(plaza, ObbyConfig.StartTag)
	rim(folder, plaza, 0.25, PALETTE.SafeDeep)

	-- plaza rails
	for _, x in { -17, 17 } do
		part({
			Name = "PlazaRail",
			Size = Vector3.new(1.2, 2.5, 34),
			Position = Vector3.new(x, Y + 2, 0),
			Color = PALETTE.StoneLight,
			Material = Enum.Material.Concrete,
			Parent = folder,
		})
	end
	part({
		Name = "PlazaBackRail",
		Size = Vector3.new(36, 2.5, 1.2),
		Position = Vector3.new(0, Y + 2, 17),
		Color = PALETTE.StoneLight,
		Material = Enum.Material.Concrete,
		Parent = folder,
	})

	-- spawn
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = ObbyConfig.StartSpawnName
	spawn.Size = Vector3.new(8, 1, 8)
	spawn.Position = Vector3.new(0, Y + 2, 6)
	spawn.Anchored = true
	spawn.Duration = 0
	spawn.Neutral = true
	spawn.Enabled = true
	spawn.Material = Enum.Material.Neon
	spawn.Color = PALETTE.Safe
	spawn.Parent = folder
	light(spawn, PALETTE.Safe, 1.2, 18)

	-- title arch
	pillar(folder, Vector3.new(-10, Y + 1.25, -16), 12, PALETTE.Stone)
	pillar(folder, Vector3.new(10, Y + 1.25, -16), 12, PALETTE.Stone)
	local arch = part({
		Name = "TitleArch",
		Size = Vector3.new(22, 2.2, 2.2),
		Position = Vector3.new(0, Y + 14, -16),
		Color = PALETTE.Mover,
		Material = Enum.Material.Neon,
		Parent = folder,
	})
	light(arch, PALETTE.Mover, 1.5, 24)
	label(arch, ObbyConfig.GameName, Color3.new(1, 1, 1), 3)
	label(plaza, "STAGE 1  ·  AURA ASCENT", PALETTE.Neon, 7)
	guideArrow(folder, Vector3.new(0, Y + 1.6, -14), 0)

	-- soft stairs out of plaza
	for i = 1, 4 do
		platform(
			folder,
			"ExitStep" .. i,
			Vector3.new(14 - i, 1.2, 4),
			Vector3.new(0, Y + i * 0.6, -18 - i * 3.5),
			if i % 2 == 0 then PALETTE.Path else PALETTE.PathAlt,
			Enum.Material.Concrete
		)
	end
	z = -34
	local pathY = Y + 2.4

	----------------------------------------------------------------
	-- 1) WARM-UP LANE — wide staggered pads, gentle height
	----------------------------------------------------------------
	label(
		platform(folder, "Sec1Sign", Vector3.new(10, 1, 4), Vector3.new(0, pathY, z), PALETTE.Path),
		"1 · WARM-UP",
		PALETTE.Guide,
		5
	)
	z -= 10

	local warmOffsets = { 0, -3.5, 3.5, -5, 5, 0, 2.5, -2.5 }
	for i, ox in warmOffsets do
		local size = if i <= 3 then Vector3.new(10, 1.4, 8) elseif i <= 6 then Vector3.new(8, 1.3, 7) else Vector3.new(7, 1.2, 6)
		local p = platform(
			folder,
			"Warm" .. i,
			size,
			Vector3.new(ox, pathY + (i - 1) * 0.35, z),
			if i % 2 == 0 then PALETTE.Path else PALETTE.PathAlt,
			Enum.Material.SmoothPlastic
		)
		rim(folder, p, 0.15, PALETTE.Neon)
		if i == 2 or i == 5 or i == 8 then
			nextOrb(Vector3.new(ox, pathY + (i - 1) * 0.35 + 3.5, z))
		end
		z -= (size.Z + 3.2)
	end

	-- landing rest
	local rest1 = platform(folder, "Rest1", Vector3.new(16, 1.6, 12), Vector3.new(0, pathY + 3, z), PALETTE.StoneLight, Enum.Material.Concrete)
	guideArrow(folder, Vector3.new(0, pathY + 4, z - 4), 0)
	z -= 14
	checkpoint(folder, 1, Vector3.new(0, pathY + 3, z))
	nextOrb(Vector3.new(0, pathY + 7, z))
	z -= 16

	----------------------------------------------------------------
	-- 2) NARROW GAUNTLET — thin beams + kill floor below
	----------------------------------------------------------------
	local sec2Y = pathY + 4
	label(
		platform(folder, "Sec2Sign", Vector3.new(10, 1, 4), Vector3.new(0, sec2Y, z), PALETTE.Accent),
		"2 · NARROW LANE",
		PALETTE.Accent,
		5
	)
	z -= 8

	-- kill trench under section 2
	killBrick(folder, "KillTrench2", Vector3.new(28, 1.5, 70), Vector3.new(0, sec2Y - 8, z - 28))

	-- side walls for readability
	for _, x in { -12, 12 } do
		part({
			Name = "LaneWall",
			Size = Vector3.new(1.5, 10, 72),
			Position = Vector3.new(x, sec2Y - 2, z - 28),
			Color = PALETTE.Stone,
			Material = Enum.Material.Concrete,
			Transparency = 0.35,
			CanCollide = false,
			Parent = folder,
		})
	end

	local beamWidths = { 5, 4.2, 3.6, 3.2, 2.8, 3.4, 4 }
	for i, w in beamWidths do
		local ox = if i % 2 == 0 then 2.8 else -2.8
		if i == 4 then
			ox = 0
		end
		local p = platform(
			folder,
			"Beam" .. i,
			Vector3.new(w, 1.1, 5.5),
			Vector3.new(ox, sec2Y + i * 0.25, z),
			PALETTE.Accent,
			Enum.Material.Metal
		)
		rim(folder, p, 0.12, PALETTE.AccentDeep)
		if i == 1 or i == 4 or i == 7 then
			nextOrb(Vector3.new(ox, sec2Y + i * 0.25 + 3.2, z))
		end
		-- tiny kill nubs on some beams
		if i == 3 or i == 5 then
			killBrick(folder, "KillNub" .. i, Vector3.new(w * 0.7, 0.8, 1.2), Vector3.new(ox, sec2Y + i * 0.25 + 0.95, z - 1.5))
		end
		z -= 9
	end

	local rest2 = platform(folder, "Rest2", Vector3.new(14, 1.6, 12), Vector3.new(0, sec2Y + 2, z), PALETTE.StoneLight, Enum.Material.Concrete)
	z -= 12
	checkpoint(folder, 2, Vector3.new(0, sec2Y + 2, z))
	z -= 16

	----------------------------------------------------------------
	-- 3) MOVER CROSSING — floating platforms that slide
	----------------------------------------------------------------
	local sec3Y = sec2Y + 3
	label(
		platform(folder, "Sec3Sign", Vector3.new(10, 1, 4), Vector3.new(0, sec3Y, z), PALETTE.Mover),
		"3 · DRIFT PADS",
		PALETTE.Mover,
		5
	)
	z -= 10

	-- approach pads
	for i = 1, 3 do
		platform(
			folder,
			"Approach3_" .. i,
			Vector3.new(7 - i * 0.4, 1.2, 6),
			Vector3.new((i % 2 == 0) and 3 or -3, sec3Y, z),
			PALETTE.PathAlt
		)
		z -= 8
	end

	-- track rails (visual)
	for _, x in { -14, 14 } do
		part({
			Name = "MoverTrack",
			Size = Vector3.new(1, 1, 48),
			Position = Vector3.new(x, sec3Y - 1.5, z - 18),
			Color = PALETTE.MoverTrack,
			Material = Enum.Material.Metal,
			Parent = folder,
		})
	end

	local function makeMover(name: string, size: Vector3, startPos: Vector3, endPos: Vector3, seconds: number)
		local m = part({
			Name = name,
			Size = size,
			Position = startPos,
			Color = PALETTE.Mover,
			Material = Enum.Material.Neon,
			Parent = folder,
		})
		tag(m, ObbyConfig.MoverTag)
		rim(folder, m, 0.18, Color3.fromRGB(220, 180, 255))
		light(m, PALETTE.Mover, 1.2, 14)
		m:SetAttribute("Start", startPos)
		m:SetAttribute("End", endPos)
		m:SetAttribute("Seconds", seconds)

		task.spawn(function()
			local info = TweenInfo.new(seconds, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
			while m.Parent do
				local t1 = TweenService:Create(m, info, { Position = endPos })
				t1:Play()
				t1.Completed:Wait()
				local t2 = TweenService:Create(m, info, { Position = startPos })
				t2:Play()
				t2.Completed:Wait()
			end
		end)
		return m
	end

	makeMover("MoverA", Vector3.new(8, 1.3, 8), Vector3.new(-10, sec3Y, z), Vector3.new(10, sec3Y, z), 2.6)
	nextOrb(Vector3.new(0, sec3Y + 4, z))
	z -= 14
	makeMover("MoverB", Vector3.new(7, 1.3, 7), Vector3.new(10, sec3Y + 1, z), Vector3.new(-10, sec3Y + 1, z), 2.2)
	z -= 14
	makeMover("MoverC", Vector3.new(9, 1.3, 6), Vector3.new(-8, sec3Y + 2, z), Vector3.new(8, sec3Y + 2.5, z - 4), 2.8)
	nextOrb(Vector3.new(0, sec3Y + 6, z - 2))
	z -= 16

	-- catch platform
	platform(folder, "Catch3", Vector3.new(16, 1.6, 12), Vector3.new(0, sec3Y + 2, z), PALETTE.StoneLight, Enum.Material.Concrete)
	z -= 12
	checkpoint(folder, 3, Vector3.new(0, sec3Y + 2, z))
	z -= 16

	----------------------------------------------------------------
	-- 4) ASCENT TOWERS — staircase spiral / height climb
	----------------------------------------------------------------
	local sec4Y = sec3Y + 2
	label(
		platform(folder, "Sec4Sign", Vector3.new(10, 1, 4), Vector3.new(0, sec4Y, z), PALETTE.Path),
		"4 · SKY ASCENT",
		PALETTE.Neon,
		5
	)
	z -= 8

	for i = 1, 12 do
		local angle = i * 0.55
		local radius = 9
		local ox = math.cos(angle) * radius
		local oz = z - i * 4.2
		local py = sec4Y + i * 1.35
		local size = Vector3.new(6.5 - (i % 3) * 0.4, 1.2, 5)
		local p = platform(
			folder,
			"Ascent" .. i,
			size,
			Vector3.new(ox, py, oz),
			if i % 2 == 0 then PALETTE.Path else PALETTE.PathAlt,
			Enum.Material.SmoothPlastic
		)
		rim(folder, p, 0.12, PALETTE.Neon)
		if i % 3 == 0 then
			nextOrb(Vector3.new(ox, py + 3.2, oz))
		end
		-- safety side barrier on outer edge every other
		if i % 2 == 0 then
			part({
				Name = "AscentRail",
				Size = Vector3.new(0.6, 2.2, size.Z * 0.8),
				Position = Vector3.new(ox + math.cos(angle) * 3.2, py + 1.2, oz),
				Color = PALETTE.StoneLight,
				Material = Enum.Material.Concrete,
				Parent = folder,
			})
		end
	end
	z -= 12 * 4.2 + 6
	local topY = sec4Y + 12 * 1.35

	-- summit deck
	local summit = platform(folder, "Summit", Vector3.new(18, 2, 18), Vector3.new(0, topY, z), PALETTE.Stone, Enum.Material.Slate)
	rim(folder, summit, 0.3, PALETTE.Mover)
	for _, off in {
		Vector3.new(7, 0, 7),
		Vector3.new(-7, 0, 7),
		Vector3.new(7, 0, -7),
		Vector3.new(-7, 0, -7),
	} do
		pillar(folder, summit.Position + off - Vector3.new(0, 1, 0), 6, PALETTE.StoneLight)
	end
	nextOrb(Vector3.new(0, topY + 4, z))
	z -= 16
	checkpoint(folder, 4, Vector3.new(0, topY, z))
	z -= 14

	----------------------------------------------------------------
	-- 5) FINAL GAUNTLET — tight jumps + kill walls + finish gate
	----------------------------------------------------------------
	local finY = topY
	label(
		platform(folder, "Sec5Sign", Vector3.new(10, 1, 4), Vector3.new(0, finY, z), PALETTE.Kill),
		"5 · FINAL GATE",
		PALETTE.KillCore,
		5
	)
	z -= 10

	-- kill walls flanking
	killBrick(folder, "KillWallL", Vector3.new(2, 12, 55), Vector3.new(-11, finY + 2, z - 22))
	killBrick(folder, "KillWallR", Vector3.new(2, 12, 55), Vector3.new(11, finY + 2, z - 22))
	killBrick(folder, "KillFloor5", Vector3.new(24, 1.2, 55), Vector3.new(0, finY - 6, z - 22))

	local finals = {
		{ s = Vector3.new(5, 1.1, 5), o = 0 },
		{ s = Vector3.new(4.2, 1.1, 4.5), o = -3.5 },
		{ s = Vector3.new(4.2, 1.1, 4.5), o = 3.5 },
		{ s = Vector3.new(3.6, 1.1, 4), o = -2 },
		{ s = Vector3.new(3.6, 1.1, 4), o = 2.5 },
		{ s = Vector3.new(4.8, 1.1, 5), o = 0 },
		{ s = Vector3.new(3.2, 1.1, 3.5), o = -4 },
		{ s = Vector3.new(3.2, 1.1, 3.5), o = 4 },
		{ s = Vector3.new(6, 1.2, 6), o = 0 },
	}
	for i, def in finals do
		local py = finY + (i % 3) * 0.4
		local p = platform(folder, "Final" .. i, def.s, Vector3.new(def.o, py, z), if i == #finals then PALETTE.Finish else PALETTE.AccentDeep, Enum.Material.Metal)
		rim(folder, p, 0.12, if i == #finals then PALETTE.FinishRing else PALETTE.Accent)
		if i == 2 or i == 5 or i == 8 then
			nextOrb(Vector3.new(def.o, py + 3.2, z))
		end
		-- hanging kill bars over some gaps
		if i == 3 or i == 6 then
			killBrick(folder, "KillHang" .. i, Vector3.new(8, 1, 1.2), Vector3.new(0, py + 5, z - 3))
		end
		z -= def.s.Z + 4.5
	end

	----------------------------------------------------------------
	-- FINISH GATE
	----------------------------------------------------------------
	z -= 4
	local finishPad = platform(folder, "FinishPad", Vector3.new(22, 2, 22), Vector3.new(0, finY + 1, z), PALETTE.Finish, Enum.Material.Neon)
	tag(finishPad, ObbyConfig.FinishTag)
	finishPad.Material = Enum.Material.SmoothPlastic
	finishPad.Color = PALETTE.Finish
	rim(folder, finishPad, 0.35, PALETTE.FinishRing)
	light(finishPad, PALETTE.Finish, 2.5, 30)

	-- gate pillars + lintel
	pillar(folder, Vector3.new(-9, finY + 2, z - 6), 16, PALETTE.Stone)
	pillar(folder, Vector3.new(9, finY + 2, z - 6), 16, PALETTE.Stone)
	local lintel = part({
		Name = "FinishLintel",
		Size = Vector3.new(20, 2.5, 2.5),
		Position = Vector3.new(0, finY + 18, z - 6),
		Color = PALETTE.FinishRing,
		Material = Enum.Material.Neon,
		Parent = folder,
	})
	light(lintel, PALETTE.Finish, 2, 28)
	label(lintel, "FINISH", PALETTE.FinishRing, 3)
	label(finishPad, "TOUCH TO CLEAR", Color3.new(1, 1, 1), 6)

	-- victory orbs
	nextOrb(Vector3.new(-5, finY + 5, z))
	nextOrb(Vector3.new(5, finY + 5, z))
	nextOrb(Vector3.new(0, finY + 6, z + 4))

	-- decorative finish ring
	part({
		Name = "FinishHalo",
		Shape = Enum.PartType.Cylinder,
		Size = Vector3.new(0.8, 24, 24),
		CFrame = CFrame.new(0, finY + 12, z - 6) * CFrame.Angles(0, 0, math.rad(90)),
		Color = PALETTE.FinishRing,
		Material = Enum.Material.Neon,
		Transparency = 0.4,
		CanCollide = false,
		Parent = folder,
	})

	-- update fall plane relative to lowest kill
	ObbyConfig.StartCFrame = CFrame.new(0, Y + 6, 6)

	print(string.format("[StageBuilder] Stage 1 built · length Z→%.0f · orbs=%d · y0=%.0f", z, orbId, Y))
	return folder
end

return StageBuilder
