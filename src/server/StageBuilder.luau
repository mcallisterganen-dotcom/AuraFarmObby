-- Multi-stage designed parkour (Meadow / Canyon / Neon).
-- Uses ParkourKit primitives + StageConfig data. Forward axis = -Z.

local StageConfig = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("StageConfig"))
local ParkourKit = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("ParkourKit"))
local ObbyConfig = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("ObbyConfig"))

local StageBuilder = {}

local function themeFrom(def): ParkourKit.Theme
	return {
		path = def.pathColor,
		accent = def.accentColor,
		kill = def.killColor,
		metal = Color3.fromRGB(90, 95, 110),
		wood = Color3.fromRGB(120, 85, 55),
	}
end

local function ox(def, x: number): number
	return def.originX + x
end

-- ============================================================================
-- STAGE 1 — Meadow Run (tutorial-friendly flow)
-- ============================================================================
local function buildMeadow(folder: Folder, def)
	local T = themeFrom(def)
	local y = def.baseY
	local z = 0
	local orbAura = def.orbAura

	-- Plaza / spawn
	ParkourKit.Pad(folder, Vector3.new(ox(def, 0), y, 20), Vector3.new(28, 1.4, 36), T, "Plaza")
	ParkourKit.SafetyRails(folder, Vector3.new(ox(def, 0), y, 20), 36, 28, T)
	ParkourKit.GuideArrow(folder, Vector3.new(ox(def, 0), y + 3, 6), T)

	-- Spawn marker (ObbyServer looks for SpawnLocation or attribute)
	local spawnPart = ParkourKit.Part({
		Name = "StageSpawn",
		Parent = folder,
		Size = Vector3.new(6, 1, 6),
		Position = Vector3.new(ox(def, 0), y + 1, 28),
		Color = T.accent,
		Material = Enum.Material.Neon,
		Transparency = 0.4,
		CanCollide = false,
	})
	spawnPart:SetAttribute("StageSpawn", true)
	local sp = Instance.new("SpawnLocation")
	sp.Name = "StartSpawn"
	sp.Size = Vector3.new(6, 1, 6)
	sp.Position = Vector3.new(ox(def, 0), y + 1.2, 28)
	sp.Duration = 0
	sp.Neutral = true
	sp.Anchored = true
	sp.Transparency = 0.5
	sp.Parent = folder

	-- Intro path
	z = 0
	ParkourKit.LongPath(folder, z, z - 40, y, ox(def, 0), 12, T)
	z = -40
	ParkourKit.Orb(folder, Vector3.new(ox(def, 0), y + 5, z + 10), orbAura, def.id)
	ParkourKit.Checkpoint(folder, 1, Vector3.new(ox(def, 0), y + 0.2, z), T)
	z -= 12

	-- Easy gap run
	z = ParkourKit.GapRun(
		folder,
		Vector3.new(ox(def, 0), y, z),
		5,
		4.5,
		Vector3.new(8, 1.2, 8),
		T,
		0
	)
	ParkourKit.Orb(folder, Vector3.new(ox(def, 3), y + 5, z + 6), orbAura, def.id)
	z -= 6
	ParkourKit.Checkpoint(folder, 2, Vector3.new(ox(def, 0), y + 0.2, z), T)
	z -= 14

	-- Mild weave
	z = ParkourKit.Weave(folder, Vector3.new(ox(def, 0), y, z), 6, 9, 5, Vector3.new(7, 1.2, 7), T)
	ParkourKit.GuideArrow(folder, Vector3.new(ox(def, 0), y + 3, z + 4), T)
	z -= 8
	ParkourKit.Checkpoint(folder, 3, Vector3.new(ox(def, 0), y + 0.2, z), T)
	z -= 12

	-- Stairs up
	local stairEnd = ParkourKit.Staircase(folder, Vector3.new(ox(def, 0), y, z), 8, 1.5, 3.2, 10, T, -1)
	y = stairEnd.Y
	z = stairEnd.Z - 10
	ParkourKit.LongPath(folder, z + 10, z - 20, y, ox(def, 0), 10, T)
	z -= 20
	ParkourKit.Orb(folder, Vector3.new(ox(def, -4), y + 5, z + 8), orbAura, def.id)
	ParkourKit.Checkpoint(folder, 4, Vector3.new(ox(def, 0), y + 0.2, z), T)
	z -= 14

	-- Moving pad + kill near miss
	ParkourKit.MovingPad(folder, Vector3.new(ox(def, 0), y, z), Vector3.new(9, 1.2, 9), T, Vector3.new(1, 0, 0), 6, 3.2)
	z -= 16
	ParkourKit.KillBrick(folder, Vector3.new(ox(def, 0), y - 6, z + 8), Vector3.new(40, 1, 30), T)
	ParkourKit.GapRun(folder, Vector3.new(ox(def, 0), y, z), 4, 5.5, Vector3.new(7, 1.2, 7), T, 2)
	z -= 28

	-- Finish plateau
	ParkourKit.Pad(folder, Vector3.new(ox(def, 0), y, z), Vector3.new(22, 1.5, 22), T, "FinishPlaza")
	ParkourKit.Finish(folder, Vector3.new(ox(def, 0), y + 0.4, z - 4), T)
	ParkourKit.Orb(folder, Vector3.new(ox(def, 6), y + 6, z), orbAura, def.id)
	ParkourKit.Orb(folder, Vector3.new(ox(def, -6), y + 6, z), orbAura, def.id)

	-- Portal to next stage (visual + touch attribute)
	local portal = ParkourKit.Part({
		Name = "PortalTo2",
		Parent = folder,
		Size = Vector3.new(10, 12, 2),
		Position = Vector3.new(ox(def, 14), y + 7, z - 4),
		Color = Color3.fromRGB(160, 100, 255),
		Material = Enum.Material.ForceField,
		CanCollide = false,
	})
	portal:SetAttribute("PortalToStage", 2)
end

-- ============================================================================
-- STAGE 2 — Crystal Canyon
-- ============================================================================
local function buildCanyon(folder: Folder, def)
	local T = themeFrom(def)
	local y = def.baseY
	local z = 0
	local orbAura = def.orbAura

	ParkourKit.Pad(folder, Vector3.new(ox(def, 0), y, 18), Vector3.new(20, 1.4, 28), T, "Plaza")
	local sp = Instance.new("SpawnLocation")
	sp.Name = "StartSpawn"
	sp.Size = Vector3.new(6, 1, 6)
	sp.Position = Vector3.new(ox(def, 0), y + 1.2, 24)
	sp.Duration = 0
	sp.Neutral = true
	sp.Anchored = true
	sp.Transparency = 0.5
	sp.Parent = folder

	z = 0
	ParkourKit.LongPath(folder, z, z - 24, y, ox(def, 0), 9, T)
	z = -24
	ParkourKit.Checkpoint(folder, 1, Vector3.new(ox(def, 0), y + 0.2, z), T)
	z -= 12

	-- Height hops
	for i = 1, 6 do
		y += 2.2
		ParkourKit.Pad(folder, Vector3.new(ox(def, (i % 2 == 0) and 4 or -4), y, z), Vector3.new(7, 1.2, 7), T, "Rise" .. i)
		if i % 2 == 0 then
			ParkourKit.Orb(folder, Vector3.new(ox(def, 0), y + 5, z), orbAura, def.id)
		end
		z -= 9
	end
	ParkourKit.Checkpoint(folder, 2, Vector3.new(ox(def, 0), y + 0.2, z), T)
	z -= 12

	-- Tight weave
	z = ParkourKit.Weave(folder, Vector3.new(ox(def, 0), y, z), 8, 8, 7, Vector3.new(5.5, 1.1, 5.5), T)
	ParkourKit.KillBrick(folder, Vector3.new(ox(def, 0), y - 8, z + 20), Vector3.new(50, 1, 50), T)
	z -= 10
	ParkourKit.Checkpoint(folder, 3, Vector3.new(ox(def, 0), y + 0.2, z), T)
	z -= 14

	-- Dual movers
	ParkourKit.MovingPad(folder, Vector3.new(ox(def, -5), y, z), Vector3.new(7, 1.1, 7), T, Vector3.new(0, 0, 1), 5, 2.8)
	ParkourKit.MovingPad(folder, Vector3.new(ox(def, 5), y, z - 12), Vector3.new(7, 1.1, 7), T, Vector3.new(1, 0, 0), 7, 3.4)
	z -= 28
	ParkourKit.GapRun(folder, Vector3.new(ox(def, 0), y, z), 5, 6, Vector3.new(6, 1.1, 6), T, 3)
	z -= 30
	ParkourKit.Checkpoint(folder, 4, Vector3.new(ox(def, 0), y + 0.2, z), T)
	ParkourKit.Orb(folder, Vector3.new(ox(def, 0), y + 6, z), orbAura, def.id)
	z -= 12

	-- Bounce into high path
	ParkourKit.BouncePad(folder, Vector3.new(ox(def, 0), y, z), T, 85)
	y += 14
	z -= 18
	ParkourKit.Pad(folder, Vector3.new(ox(def, 0), y, z), Vector3.new(12, 1.3, 14), T, "High")
	ParkourKit.Checkpoint(folder, 5, Vector3.new(ox(def, 0), y + 0.2, z - 2), T)
	z -= 16

	ParkourKit.LongPath(folder, z, z - 22, y, ox(def, 0), 8, T)
	z -= 22
	ParkourKit.Pad(folder, Vector3.new(ox(def, 0), y, z), Vector3.new(20, 1.5, 20), T, "FinishPlaza")
	ParkourKit.Finish(folder, Vector3.new(ox(def, 0), y + 0.4, z - 3), T)

	local portal = ParkourKit.Part({
		Name = "PortalTo3",
		Parent = folder,
		Size = Vector3.new(10, 12, 2),
		Position = Vector3.new(ox(def, 14), y + 7, z - 3),
		Color = Color3.fromRGB(80, 255, 230),
		Material = Enum.Material.ForceField,
		CanCollide = false,
	})
	portal:SetAttribute("PortalToStage", 3)
end

-- ============================================================================
-- STAGE 3 — Neon Spire
-- ============================================================================
local function buildNeon(folder: Folder, def)
	local T = themeFrom(def)
	local y = def.baseY
	local z = 0
	local orbAura = def.orbAura

	ParkourKit.Pad(folder, Vector3.new(ox(def, 0), y, 16), Vector3.new(16, 1.4, 24), T, "Plaza")
	local sp = Instance.new("SpawnLocation")
	sp.Name = "StartSpawn"
	sp.Size = Vector3.new(5, 1, 5)
	sp.Position = Vector3.new(ox(def, 0), y + 1.2, 22)
	sp.Duration = 0
	sp.Neutral = true
	sp.Anchored = true
	sp.Transparency = 0.5
	sp.Parent = folder

	z = 0
	-- Narrow spine
	ParkourKit.LongPath(folder, z, z - 20, y, ox(def, 0), 5, T)
	z = -20
	ParkourKit.Checkpoint(folder, 1, Vector3.new(ox(def, 0), y + 0.2, z), T)
	z -= 10

	-- Precision gaps
	z = ParkourKit.GapRun(folder, Vector3.new(ox(def, 0), y, z), 7, 6.5, Vector3.new(4.5, 1, 4.5), T, 1.5)
	ParkourKit.KillBrick(folder, Vector3.new(ox(def, 0), y - 10, z + 25), Vector3.new(60, 1, 70), T)
	z -= 8
	ParkourKit.Checkpoint(folder, 2, Vector3.new(ox(def, 0), y + 0.2, z), T)
	z -= 12

	-- Vertical spiral-ish stairs
	for i = 1, 10 do
		local ang = i * 0.7
		local rx = math.cos(ang) * 6
		local rz = z - i * 3.2
		y += 1.8
		ParkourKit.Pad(folder, Vector3.new(ox(def, rx), y, rz), Vector3.new(5, 1, 5), T, "Spiral" .. i)
		if i % 3 == 0 then
			ParkourKit.Orb(folder, Vector3.new(ox(def, rx), y + 4, rz), orbAura, def.id)
		end
	end
	z = z - 10 * 3.2 - 8
	ParkourKit.Checkpoint(folder, 3, Vector3.new(ox(def, 0), y + 0.2, z), T)
	z -= 12

	-- Triple movers
	for i = 1, 3 do
		ParkourKit.MovingPad(
			folder,
			Vector3.new(ox(def, (i - 2) * 6), y, z - (i - 1) * 10),
			Vector3.new(5.5, 1, 5.5),
			T,
			if i == 2 then Vector3.new(0, 1, 0) else Vector3.new(1, 0, 0),
			if i == 2 then 4 else 6,
			2.2 + i * 0.3
		)
	end
	z -= 40
	ParkourKit.Checkpoint(folder, 4, Vector3.new(ox(def, 0), y + 0.2, z), T)
	z -= 10

	-- Weave high difficulty
	z = ParkourKit.Weave(folder, Vector3.new(ox(def, 0), y, z), 10, 7.5, 8, Vector3.new(4.2, 1, 4.2), T)
	z -= 8
	ParkourKit.Checkpoint(folder, 5, Vector3.new(ox(def, 0), y + 0.2, z), T)
	ParkourKit.BouncePad(folder, Vector3.new(ox(def, 0), y, z - 8), T, 95)
	y += 16
	z -= 22
	ParkourKit.Pad(folder, Vector3.new(ox(def, 0), y, z), Vector3.new(10, 1.2, 10), T, "Sky")
	ParkourKit.Checkpoint(folder, 6, Vector3.new(ox(def, 0), y + 0.2, z), T)
	z -= 14

	-- Final gauntlet
	z = ParkourKit.GapRun(folder, Vector3.new(ox(def, 0), y, z), 6, 7, Vector3.new(4, 1, 4), T, 2.5)
	z -= 10
	ParkourKit.Pad(folder, Vector3.new(ox(def, 0), y, z), Vector3.new(18, 1.5, 18), T, "FinishPlaza")
	ParkourKit.Finish(folder, Vector3.new(ox(def, 0), y + 0.4, z - 2), T)
	for i = -1, 1 do
		ParkourKit.Orb(folder, Vector3.new(ox(def, i * 5), y + 6, z), orbAura, def.id)
	end
end

local BUILDERS = {
	[1] = buildMeadow,
	[2] = buildCanyon,
	[3] = buildNeon,
}

function StageBuilder.BuildAll(): Folder
	local root = workspace:FindFirstChild("AuraFarmStages")
	if root then
		root:Destroy()
	end
	root = Instance.new("Folder")
	root.Name = "AuraFarmStages"
	root.Parent = workspace

	for _, def in StageConfig.Stages do
		local folder = Instance.new("Folder")
		folder.Name = StageConfig.FolderName(def.id)
		folder:SetAttribute("StageId", def.id)
		folder:SetAttribute("StageName", def.name)
		folder:SetAttribute("Theme", def.theme)
		folder.Parent = root

		local builder = BUILDERS[def.id]
		if builder then
			builder(folder, def)
		else
			warn("[StageBuilder] No builder for stage", def.id)
		end
		print(string.format("[StageBuilder] Built %s (%s)", folder.Name, def.name))
	end

	-- Lobby hub between stages
	local lobby = Instance.new("Folder")
	lobby.Name = "Lobby"
	lobby.Parent = root
	local hubY = 6
	ParkourKit.Pad(
		lobby,
		StageConfig.LobbySpawn,
		Vector3.new(40, 1.5, 40),
		ParkourKit.DefaultTheme(),
		"HubFloor"
	)
	local hubSpawn = Instance.new("SpawnLocation")
	hubSpawn.Name = "LobbySpawn"
	hubSpawn.Size = Vector3.new(8, 1, 8)
	hubSpawn.Position = StageConfig.LobbySpawn + Vector3.new(0, 1.2, 0)
	hubSpawn.Duration = 0
	hubSpawn.Neutral = true
	hubSpawn.Anchored = true
	hubSpawn.BrickColor = BrickColor.new("Medium stone grey")
	hubSpawn.Parent = lobby

	-- Stage select pads
	for _, def in StageConfig.Stages do
		local pad = ParkourKit.Part({
			Name = "SelectStage" .. def.id,
			Parent = lobby,
			Size = Vector3.new(10, 1.5, 10),
			Position = StageConfig.LobbySpawn + Vector3.new((def.id - 2) * 14, 0.2, -16),
			Color = def.accentColor,
			Material = Enum.Material.Neon,
		})
		pad:SetAttribute("SelectStage", def.id)
		local bb = Instance.new("BillboardGui")
		bb.Size = UDim2.fromOffset(140, 50)
		bb.StudsOffset = Vector3.new(0, 6, 0)
		bb.AlwaysOnTop = true
		bb.Parent = pad
		local tl = Instance.new("TextLabel")
		tl.Size = UDim2.fromScale(1, 1)
		tl.BackgroundTransparency = 1
		tl.Font = Enum.Font.GothamBold
		tl.TextSize = 16
		tl.TextColor3 = Color3.new(1, 1, 1)
		tl.Text = string.format("Stage %d\n%s", def.id, def.name)
		tl.Parent = bb
	end

	return root
end

-- Back-compat alias used by older ObbyServer
function StageBuilder.Build(): Folder
	return StageBuilder.BuildAll()
end

return StageBuilder
