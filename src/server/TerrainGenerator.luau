-- World dressing around Stage 1: void floor, sky islands, ambient crystals,
-- path edge lanterns, and a readable horizon. Never rebuilds gameplay pads.

local TerrainGenerator = {}
TerrainGenerator.__index = TerrainGenerator

local COLORS = {
	Void = Color3.fromRGB(22, 24, 38),
	Void2 = Color3.fromRGB(30, 34, 52),
	Island = Color3.fromRGB(55, 62, 82),
	IslandTop = Color3.fromRGB(70, 110, 90),
	Crystal = Color3.fromRGB(170, 110, 255),
	Crystal2 = Color3.fromRGB(110, 180, 255),
	Lantern = Color3.fromRGB(255, 190, 110),
	FogRing = Color3.fromRGB(40, 50, 80),
	Cloud = Color3.fromRGB(200, 210, 230),
}

local function part(props: { [string]: any }): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CastShadow = true
	for k, v in props do
		(p :: any)[k] = v
	end
	return p
end

function TerrainGenerator.new()
	return setmetatable({ rng = Random.new(20250828) }, TerrainGenerator)
end

function TerrainGenerator:_folder(stage: Instance): Folder
	local decor = stage:FindFirstChild("Decor")
	if decor then
		decor:ClearAllChildren()
	else
		decor = Instance.new("Folder")
		decor.Name = "Decor"
		decor.Parent = stage
	end
	return decor :: Folder
end

function TerrainGenerator:_voidFloor(decor: Folder, courseMinZ: number, courseMaxZ: number, baseY: number)
	-- Deep void plane (death catch visual, non-gameplay)
	local depth = math.abs(courseMinZ - courseMaxZ) + 120
	local midZ = (courseMinZ + courseMaxZ) * 0.5
	part({
		Name = "VoidFloor",
		Size = Vector3.new(220, 2, depth),
		Position = Vector3.new(0, baseY - 28, midZ),
		Color = COLORS.Void,
		Material = Enum.Material.SmoothPlastic,
		Transparency = 0.15,
		CanCollide = false, -- real fail = FallY / kill bricks
		Parent = decor,
	})
	-- concentric darker rings
	for i = 1, 4 do
		part({
			Name = "VoidRing" .. i,
			Size = Vector3.new(40 + i * 35, 1, 40 + i * 35),
			Position = Vector3.new(0, baseY - 27.2 - i * 0.3, midZ - 40),
			Color = if i % 2 == 0 then COLORS.Void2 else COLORS.FogRing,
			Material = Enum.Material.SmoothPlastic,
			Transparency = 0.35 + i * 0.08,
			CanCollide = false,
			Parent = decor,
		})
	end
end

function TerrainGenerator:_skyIslands(decor: Folder, baseY: number, alongZ: number)
	local rng = self.rng
	for i = 1, 18 do
		local side = if i % 2 == 0 then 1 else -1
		local x = side * rng:NextNumber(28, 70)
		local z = alongZ - rng:NextNumber(0, 200)
		local y = baseY + rng:NextNumber(-8, 40)
		local sx = rng:NextNumber(8, 22)
		local sy = rng:NextNumber(4, 10)
		local sz = rng:NextNumber(8, 20)
		local island = part({
			Name = "SkyIsland" .. i,
			Size = Vector3.new(sx, sy, sz),
			Position = Vector3.new(x, y, z),
			Color = COLORS.Island,
			Material = Enum.Material.Slate,
			Parent = decor,
		})
		-- grassy cap
		part({
			Name = "IslandCap" .. i,
			Size = Vector3.new(sx * 0.95, 1.2, sz * 0.95),
			Position = Vector3.new(x, y + sy / 2 + 0.4, z),
			Color = COLORS.IslandTop,
			Material = Enum.Material.Grass,
			Parent = decor,
		})
		-- drip stones under
		for j = 1, 3 do
			local ds = rng:NextNumber(1.5, 4)
			part({
				Name = "Drip",
				Size = Vector3.new(ds, rng:NextNumber(3, 9), ds),
				Position = Vector3.new(
					x + rng:NextNumber(-sx / 3, sx / 3),
					y - sy / 2 - rng:NextNumber(2, 6),
					z + rng:NextNumber(-sz / 3, sz / 3)
				),
				Color = COLORS.Island,
				Material = Enum.Material.Slate,
				Parent = decor,
			})
		end
	end
end

function TerrainGenerator:_crystals(decor: Folder, baseY: number, alongZ: number)
	local rng = self.rng
	for i = 1, 24 do
		local side = if rng:NextNumber() > 0.5 then 1 else -1
		local h = rng:NextNumber(4, 14)
		local c = part({
			Name = "Crystal" .. i,
			Size = Vector3.new(rng:NextNumber(1.2, 2.4), h, rng:NextNumber(1.2, 2.4)),
			Position = Vector3.new(side * rng:NextNumber(18, 55), baseY + rng:NextNumber(2, 35) + h / 2, alongZ - rng:NextNumber(0, 210)),
			Color = if i % 2 == 0 then COLORS.Crystal else COLORS.Crystal2,
			Material = Enum.Material.Neon,
			CanCollide = false,
			Transparency = 0.15,
			Orientation = Vector3.new(rng:NextNumber(-15, 15), rng:NextNumber(0, 360), rng:NextNumber(-15, 15)),
			Parent = decor,
		})
		local light = Instance.new("PointLight")
		light.Color = c.Color
		light.Brightness = 1.3
		light.Range = 16
		light.Parent = c
	end
end

function TerrainGenerator:_lanterns(decor: Folder, stage: Instance)
	-- Place lanterns near large platforms for path readability
	local count = 0
	for _, inst in stage:GetDescendants() do
		local n = inst.Name
		local isKey = inst:IsA("BasePart") and (
			n:find("Rest") or n:find("Checkpoint") or n:find("StartPad") or n:find("Summit") or n:find("FinishPad") or n:find("Plaza")
		) and not n:find("_")
		if isKey then
			count += 1
			if count > 20 then
				break
			end
			local base = inst :: BasePart
			for _, side in { -1, 1 } do
				local pole = part({
					Name = "LanternPole",
					Size = Vector3.new(0.5, 6, 0.5),
					Position = base.Position + Vector3.new(side * (base.Size.X * 0.45), base.Size.Y / 2 + 3, 0),
					Color = Color3.fromRGB(45, 48, 60),
					Material = Enum.Material.Metal,
					Parent = decor,
				})
				local lamp = part({
					Name = "Lantern",
					Shape = Enum.PartType.Ball,
					Size = Vector3.new(1.4, 1.4, 1.4),
					Position = pole.Position + Vector3.new(0, 3.2, 0),
					Color = COLORS.Lantern,
					Material = Enum.Material.Neon,
					CanCollide = false,
					Parent = decor,
				})
				local l = Instance.new("PointLight")
				l.Color = COLORS.Lantern
				l.Brightness = 1.6
				l.Range = 18
				l.Parent = lamp
			end
		end
	end
end

function TerrainGenerator:_clouds(decor: Folder, baseY: number, alongZ: number)
	local rng = self.rng
	for i = 1, 12 do
		part({
			Name = "Cloud" .. i,
			Size = Vector3.new(rng:NextNumber(20, 40), rng:NextNumber(3, 6), rng:NextNumber(12, 24)),
			Position = Vector3.new(rng:NextNumber(-80, 80), baseY + rng:NextNumber(45, 80), alongZ - rng:NextNumber(-20, 220)),
			Color = COLORS.Cloud,
			Material = Enum.Material.SmoothPlastic,
			Transparency = 0.55,
			CanCollide = false,
			CastShadow = false,
			Parent = decor,
		})
	end
end

function TerrainGenerator:_horizonPillars(decor: Folder, baseY: number)
	local rng = self.rng
	for i = 1, 16 do
		local ang = (i / 16) * math.pi * 2
		local r = 95
		local h = rng:NextNumber(20, 55)
		part({
			Name = "HorizonPillar" .. i,
			Size = Vector3.new(rng:NextNumber(3, 7), h, rng:NextNumber(3, 7)),
			Position = Vector3.new(math.cos(ang) * r, baseY - 10 + h / 2, math.sin(ang) * r - 80),
			Color = COLORS.Island,
			Material = Enum.Material.Basalt,
			Parent = decor,
		})
	end
end

function TerrainGenerator:_lighting()
	local Lighting = game:GetService("Lighting")
	Lighting.EnvironmentDiffuseScale = 0.6
	Lighting.EnvironmentSpecularScale = 0.5
	Lighting.Brightness = 2.2
	Lighting.OutdoorAmbient = Color3.fromRGB(70, 75, 100)
	Lighting.Ambient = Color3.fromRGB(55, 58, 80)
	Lighting.FogColor = Color3.fromRGB(30, 35, 55)
	Lighting.FogStart = 80
	Lighting.FogEnd = 320
	Lighting.GeographicLatitude = 25

	if not Lighting:FindFirstChild("AuraFarmAtmosphere") then
		local a = Instance.new("Atmosphere")
		a.Name = "AuraFarmAtmosphere"
		a.Density = 0.35
		a.Offset = 0.1
		a.Color = Color3.fromRGB(140, 150, 190)
		a.Decay = Color3.fromRGB(90, 80, 140)
		a.Glare = 0.15
		a.Haze = 1.4
		a.Parent = Lighting
	end

	if not Lighting:FindFirstChild("AuraFarmSky") then
		local sky = Instance.new("Sky")
		sky.Name = "AuraFarmSky"
		sky.CelestialBodiesShown = true
		sky.StarCount = 3000
		sky.SkyboxBk = "rbxassetid://6444884337"
		sky.SkyboxDn = "rbxassetid://6444884785"
		sky.SkyboxFt = "rbxassetid://6444884337"
		sky.SkyboxLf = "rbxassetid://6444884337"
		sky.SkyboxRt = "rbxassetid://6444884337"
		sky.SkyboxUp = "rbxassetid://6412503613"
		sky.Parent = Lighting
	end
end

function TerrainGenerator:DecorateStage(stageFolder: Instance)
	local decor = self:_folder(stageFolder)

	-- Measure course bounds from gameplay parts
	local minZ, maxZ, minY = 0, 0, 9999
	for _, inst in stageFolder:GetDescendants() do
		if inst:IsA("BasePart") and inst.Parent == stageFolder then
			minZ = math.min(minZ, inst.Position.Z)
			maxZ = math.max(maxZ, inst.Position.Z)
			minY = math.min(minY, inst.Position.Y)
		end
	end
	if minY > 1000 then
		minY = 20
	end

	self:_voidFloor(decor, minZ, maxZ, minY)
	self:_skyIslands(decor, minY, maxZ)
	self:_crystals(decor, minY, maxZ)
	self:_clouds(decor, minY, maxZ)
	self:_horizonPillars(decor, minY)
	self:_lanterns(decor, stageFolder)
	self:_lighting()

	print(string.format("[TerrainGenerator] Decor ready · z[%.0f..%.0f] y0=%.0f", minZ, maxZ, minY))
	return decor
end

return TerrainGenerator
