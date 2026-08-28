-- Builds Stage 1 at runtime so the place works even with an empty baseplate.
-- Parts use Attribute "Tag" so ObbyServer can wire touch logic consistently.

local ObbyConfig = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("ObbyConfig"))

local StageBuilder = {}

local function part(props: { [string]: any }): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.Material = Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for key, value in props do
		(p :: any)[key] = value
	end
	return p
end

local function setTag(instance: Instance, tagName: string)
	instance:SetAttribute("Tag", tagName)
end

function StageBuilder.Build(): Folder
	local existing = workspace:FindFirstChild(ObbyConfig.StageFolderName)
	if existing then
		existing:Destroy()
	end

	-- Remove default template spawn/base so our SpawnLocation is used
	for _, child in workspace:GetChildren() do
		if child:IsA("SpawnLocation") then
			child:Destroy()
		elseif child:IsA("BasePart") and child.Name == "Baseplate" then
			child:Destroy()
		end
	end

	local folder = Instance.new("Folder")
	folder.Name = ObbyConfig.StageFolderName
	folder.Parent = workspace

	local Y = 8
	local pathColor = Color3.fromRGB(100, 170, 255)
	local accent = Color3.fromRGB(255, 170, 60)

	-- Big readable start pad
	local startPad = part({
		Name = "StartPad",
		Size = Vector3.new(28, 2, 28),
		Position = Vector3.new(0, Y, 0),
		Color = Color3.fromRGB(80, 200, 120),
	})
	setTag(startPad, ObbyConfig.StartTag)
	startPad.Parent = folder

	-- Real spawn on the pad
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = ObbyConfig.StartSpawnName
	spawn.Size = Vector3.new(10, 1, 10)
	spawn.Position = Vector3.new(0, Y + 1.5, 0)
	spawn.Anchored = true
	spawn.Duration = 0
	spawn.Neutral = true
	spawn.Enabled = true
	spawn.Color = Color3.fromRGB(100, 255, 140)
	spawn.Material = Enum.Material.Neon
	spawn.Parent = folder

	-- Title billboard
	local titlePart = part({
		Name = "TitleBillboard",
		Size = Vector3.new(4, 4, 4),
		Position = Vector3.new(0, Y + 12, 0),
		Transparency = 1,
		CanCollide = false,
	})
	titlePart.Parent = folder
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(420, 80)
	bb.AlwaysOnTop = true
	bb.Parent = titlePart
	local title = Instance.new("TextLabel")
	title.Size = UDim2.fromScale(1, 1)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBlack
	title.TextScaled = true
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextStrokeTransparency = 0.5
	title.Text = ObbyConfig.GameName
	title.Parent = bb

	-- Section 1: easy jumps (forward = -Z)
	for i = 1, 5 do
		local p = part({
			Name = "Path1_" .. i,
			Size = Vector3.new(8, 1, 8),
			Position = Vector3.new(0, Y, -22 - (i - 1) * 12),
			Color = if i % 2 == 0 then pathColor else Color3.fromRGB(120, 200, 255),
		})
		p.Parent = folder
	end

	-- Checkpoint 1
	local cp1 = part({
		Name = "Checkpoint1",
		Size = Vector3.new(10, 1, 10),
		Position = Vector3.new(0, Y, -86),
		Color = Color3.fromRGB(255, 220, 80),
	})
	setTag(cp1, ObbyConfig.CheckpointTag)
	cp1:SetAttribute("Index", 1)
	cp1.Parent = folder
	local cp1Beacon = part({
		Name = "Checkpoint1Beacon",
		Size = Vector3.new(2, 8, 2),
		Position = Vector3.new(0, Y + 4.5, -86),
		Color = Color3.fromRGB(255, 230, 120),
		CanCollide = false,
		Transparency = 0.35,
	})
	cp1Beacon.Parent = folder

	-- Section 2: narrower + kill brick lane
	for i = 1, 4 do
		local p = part({
			Name = "Path2_" .. i,
			Size = Vector3.new(6, 1, 6),
			Position = Vector3.new((i % 2 == 0) and 4 or -4, Y + 2, -100 - (i - 1) * 11),
			Color = accent,
		})
		p.Parent = folder
	end

	local kill1 = part({
		Name = "KillBrick1",
		Size = Vector3.new(28, 1, 8),
		Position = Vector3.new(0, Y - 1, -116),
		Color = Color3.fromRGB(220, 50, 50),
		Material = Enum.Material.Neon,
	})
	setTag(kill1, ObbyConfig.KillTag)
	kill1.Parent = folder

	-- Checkpoint 2
	local cp2 = part({
		Name = "Checkpoint2",
		Size = Vector3.new(10, 1, 10),
		Position = Vector3.new(0, Y + 3, -148),
		Color = Color3.fromRGB(255, 220, 80),
	})
	setTag(cp2, ObbyConfig.CheckpointTag)
	cp2:SetAttribute("Index", 2)
	cp2.Parent = folder

	-- Section 3: rising stairs + gap
	for i = 1, 6 do
		local p = part({
			Name = "Stairs_" .. i,
			Size = Vector3.new(7, 1, 5),
			Position = Vector3.new(0, Y + 3 + i * 2, -160 - i * 6),
			Color = Color3.fromRGB(180, 120, 255),
		})
		p.Parent = folder
	end

	-- Moving platform
	local mover = part({
		Name = "Mover1",
		Size = Vector3.new(7, 1, 7),
		Position = Vector3.new(-12, Y + 15, -208),
		Color = Color3.fromRGB(255, 100, 180),
		Material = Enum.Material.Neon,
	})
	setTag(mover, ObbyConfig.MoverTag)
	mover:SetAttribute("MoverId", 1)
	mover.Parent = folder

	local afterMover = part({
		Name = "Path3_AfterMover",
		Size = Vector3.new(8, 1, 8),
		Position = Vector3.new(12, Y + 15, -208),
		Color = pathColor,
	})
	afterMover.Parent = folder

	-- Kill pit under mover gap
	local kill2 = part({
		Name = "KillBrick2",
		Size = Vector3.new(40, 1, 20),
		Position = Vector3.new(0, Y + 6, -208),
		Color = Color3.fromRGB(220, 50, 50),
		Material = Enum.Material.Neon,
	})
	setTag(kill2, ObbyConfig.KillTag)
	kill2.Parent = folder

	-- Checkpoint 3
	local cp3 = part({
		Name = "Checkpoint3",
		Size = Vector3.new(10, 1, 10),
		Position = Vector3.new(12, Y + 15, -224),
		Color = Color3.fromRGB(255, 220, 80),
	})
	setTag(cp3, ObbyConfig.CheckpointTag)
	cp3:SetAttribute("Index", 3)
	cp3.Parent = folder

	-- Final stretch
	for i = 1, 4 do
		local p = part({
			Name = "Final_" .. i,
			Size = Vector3.new(5, 1, 5),
			Position = Vector3.new(12 + (i % 2 == 0 and -3 or 3), Y + 15, -238 - (i - 1) * 10),
			Color = Color3.fromRGB(100, 255, 200),
		})
		p.Parent = folder
	end

	-- Finish pad
	local finish = part({
		Name = "FinishPad",
		Size = Vector3.new(16, 1, 16),
		Position = Vector3.new(12, Y + 15, -288),
		Color = Color3.fromRGB(255, 230, 60),
		Material = Enum.Material.Neon,
	})
	setTag(finish, ObbyConfig.FinishTag)
	finish.Parent = folder

	local finishWall = part({
		Name = "FinishSign",
		Size = Vector3.new(14, 6, 1),
		Position = Vector3.new(12, Y + 19, -296),
		Color = Color3.fromRGB(255, 255, 255),
		CanCollide = false,
	})
	finishWall.Parent = folder
	local finishGui = Instance.new("SurfaceGui")
	finishGui.Face = Enum.NormalId.Front
	finishGui.Parent = finishWall
	local finishLabel = Instance.new("TextLabel")
	finishLabel.Size = UDim2.fromScale(1, 1)
	finishLabel.BackgroundTransparency = 1
	finishLabel.Text = "FINISH"
	finishLabel.Font = Enum.Font.GothamBlack
	finishLabel.TextScaled = true
	finishLabel.TextColor3 = Color3.fromRGB(40, 40, 40)
	finishLabel.Parent = finishGui

	-- Aura orbs along the route
	local orbPositions = {
		Vector3.new(0, Y + 3, -34),
		Vector3.new(0, Y + 3, -58),
		Vector3.new(-4, Y + 5, -108),
		Vector3.new(4, Y + 5, -130),
		Vector3.new(0, Y + 10, -168),
		Vector3.new(0, Y + 18, -190),
		Vector3.new(12, Y + 18, -240),
		Vector3.new(12, Y + 18, -265),
	}

	for i, pos in orbPositions do
		local orb = part({
			Name = "AuraOrb_" .. i,
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(2.4, 2.4, 2.4),
			Position = pos,
			Color = Color3.fromRGB(190, 130, 255),
			Material = Enum.Material.Neon,
			CanCollide = false,
			Transparency = 0.15,
		})
		setTag(orb, ObbyConfig.OrbTag)
		orb:SetAttribute("OrbId", "orb_" .. i)
		orb:SetAttribute("BaseTransparency", 0.15)
		orb.Parent = folder

		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(190, 130, 255)
		light.Brightness = 2
		light.Range = 10
		light.Parent = orb
	end

	-- Collidable void slab under the course
	local voidKill = part({
		Name = "VoidKill",
		Size = Vector3.new(300, 2, 500),
		Position = Vector3.new(0, -10, -140),
		Color = Color3.fromRGB(25, 10, 30),
		Material = Enum.Material.SmoothPlastic,
		Transparency = 0.25,
	})
	setTag(voidKill, ObbyConfig.KillTag)
	voidKill.Parent = folder

	-- Lighting nudge
	local lighting = game:GetService("Lighting")
	lighting.Brightness = 2
	lighting.Ambient = Color3.fromRGB(120, 120, 140)
	lighting.OutdoorAmbient = Color3.fromRGB(140, 140, 160)
	lighting.ClockTime = 14
	lighting.GlobalShadows = false

	StageBuilder.StartMovers(folder)
	print("[StageBuilder] Stage 1 built — look for green StartPad at origin")
	return folder
end

function StageBuilder.StartMovers(folder: Folder)
	local mover = folder:FindFirstChild("Mover1")
	if not mover or not mover:IsA("BasePart") then
		return
	end

	task.spawn(function()
		local base = mover.Position
		local t0 = os.clock()
		while mover.Parent do
			local t = os.clock() - t0
			local x = math.sin(t * 1.35) * 12
			mover.Position = Vector3.new(base.X + x, base.Y, base.Z)
			task.wait(0.03)
		end
	end)
end

return StageBuilder
