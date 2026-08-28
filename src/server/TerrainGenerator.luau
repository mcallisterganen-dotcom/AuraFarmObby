-- Biome dressing per stage + shared void/horizon.
-- Never collides with gameplay pads; purely visual world-building.

local StageConfig = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("StageConfig"))

local TerrainGenerator = {}
TerrainGenerator.__index = TerrainGenerator

local function part(props: { [string]: any }): BasePart
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = props.CanCollide == true
	p.Material = props.Material or Enum.Material.Rock
	p.Color = props.Color or Color3.fromRGB(50, 50, 60)
	p.Size = props.Size or Vector3.new(4, 4, 4)
	p.CFrame = props.CFrame or CFrame.new(props.Position or Vector3.zero)
	p.Name = props.Name or "Decor"
	p.Transparency = props.Transparency or 0
	p.CastShadow = props.CastShadow ~= false
	if props.Shape then
		p.Shape = props.Shape
	end
	p.Parent = props.Parent
	return p
end

local function rngFrom(seed: number)
	return Random.new(seed)
end

function TerrainGenerator.new()
	return setmetatable({ rng = Random.new(42) }, TerrainGenerator)
end

function TerrainGenerator:_void(parent: Instance)
	-- Readable abyss under everything
	part({
		Name = "VoidPlane",
		Parent = parent,
		Size = Vector3.new(2000, 2, 2000),
		Position = Vector3.new(200, -40, -200),
		Color = Color3.fromRGB(8, 8, 14),
		Material = Enum.Material.SmoothPlastic,
		CanCollide = false,
		Transparency = 0.35,
		CastShadow = false,
	})
	-- Soft kill volume far below (server also uses stage kill bricks)
	local kill = part({
		Name = "WorldKill",
		Parent = parent,
		Size = Vector3.new(2000, 4, 2000),
		Position = Vector3.new(200, -80, -200),
		Color = Color3.fromRGB(40, 0, 0),
		Material = Enum.Material.Neon,
		CanCollide = true,
		Transparency = 0.8,
	})
	kill:SetAttribute("Kill", true)
end

function TerrainGenerator:_horizon(parent: Instance, cx: number)
	for i = 1, 14 do
		local ang = (i / 14) * math.pi * 2
		local r = 380 + (i % 3) * 40
		local h = 40 + (i * 13) % 70
		part({
			Name = "Horizon" .. i,
			Parent = parent,
			Size = Vector3.new(30 + i * 2, h, 30 + i),
			Position = Vector3.new(cx + math.cos(ang) * r, h * 0.3 - 10, math.sin(ang) * r - 120),
			Color = Color3.fromRGB(30 + i * 2, 32, 48 + i),
			Material = Enum.Material.Slate,
			CanCollide = false,
			Transparency = 0.15,
		})
	end
end

function TerrainGenerator:_meadow(parent: Instance, originX: number, baseY: number, rng: Random)
	local decor = Instance.new("Folder")
	decor.Name = "MeadowDecor"
	decor.Parent = parent

	-- Rolling hills beside path
	for i = 1, 28 do
		local side = if rng:NextNumber() > 0.5 then 1 else -1
		local x = originX + side * (18 + rng:NextNumber() * 50)
		local z = -rng:NextNumber() * 220
		local h = 4 + rng:NextNumber() * 14
		part({
			Name = "Hill" .. i,
			Parent = decor,
			Size = Vector3.new(12 + rng:NextNumber() * 20, h, 12 + rng:NextNumber() * 18),
			Position = Vector3.new(x, baseY - 4 + h * 0.3, z),
			Color = Color3.fromRGB(50 + rng:NextInteger(0, 40), 110 + rng:NextInteger(0, 50), 70),
			Material = Enum.Material.Grass,
			CanCollide = false,
		})
	end

	-- Trees (simple trunk + canopy)
	for i = 1, 20 do
		local side = if rng:NextNumber() > 0.5 then 1 else -1
		local x = originX + side * (22 + rng:NextNumber() * 40)
		local z = -10 - rng:NextNumber() * 200
		local trunkH = 6 + rng:NextNumber() * 5
		part({
			Name = "Trunk" .. i,
			Parent = decor,
			Size = Vector3.new(1.4, trunkH, 1.4),
			Position = Vector3.new(x, baseY + trunkH * 0.5, z),
			Color = Color3.fromRGB(90, 60, 40),
			Material = Enum.Material.Wood,
			CanCollide = false,
		})
		part({
			Name = "Canopy" .. i,
			Parent = decor,
			Size = Vector3.new(8, 6, 8),
			Position = Vector3.new(x, baseY + trunkH + 2, z),
			Color = Color3.fromRGB(40, 140, 70),
			Material = Enum.Material.Grass,
			Shape = Enum.PartType.Ball,
			CanCollide = false,
		})
	end

	-- Path lanterns
	for i = 0, 12 do
		local z = -i * 18
		for _, side in { -1, 1 } do
			local x = originX + side * 9
			part({
				Name = "LanternPole",
				Parent = decor,
				Size = Vector3.new(0.6, 7, 0.6),
				Position = Vector3.new(x, baseY + 3.5, z),
				Color = Color3.fromRGB(70, 70, 80),
				Material = Enum.Material.Metal,
				CanCollide = false,
			})
			local glow = part({
				Name = "LanternGlow",
				Parent = decor,
				Size = Vector3.new(1.2, 1.2, 1.2),
				Position = Vector3.new(x, baseY + 7, z),
				Color = Color3.fromRGB(255, 220, 140),
				Material = Enum.Material.Neon,
				CanCollide = false,
			})
			local pl = Instance.new("PointLight")
			pl.Brightness = 1.2
			pl.Range = 18
			pl.Color = Color3.fromRGB(255, 220, 150)
			pl.Parent = glow
		end
	end
end

function TerrainGenerator:_canyon(parent: Instance, originX: number, baseY: number, rng: Random)
	local decor = Instance.new("Folder")
	decor.Name = "CanyonDecor"
	decor.Parent = parent

	-- Cliff walls
	for i = 1, 22 do
		local side = if i % 2 == 0 then 1 else -1
		local x = originX + side * (16 + rng:NextNumber() * 10)
		local z = -rng:NextNumber() * 260
		local h = 20 + rng:NextNumber() * 40
		part({
			Name = "Cliff" .. i,
			Parent = decor,
			Size = Vector3.new(10 + rng:NextNumber() * 12, h, 14 + rng:NextNumber() * 20),
			Position = Vector3.new(x, baseY + h * 0.25 - 8, z),
			Color = Color3.fromRGB(70 + rng:NextInteger(0, 30), 50, 90 + rng:NextInteger(0, 40)),
			Material = Enum.Material.Slate,
			CanCollide = false,
		})
	end

	-- Crystal spikes
	for i = 1, 30 do
		local side = if rng:NextNumber() > 0.5 then 1 else -1
		local x = originX + side * (12 + rng:NextNumber() * 35)
		local z = -rng:NextNumber() * 250
		local h = 5 + rng:NextNumber() * 16
		local crystal = part({
			Name = "Crystal" .. i,
			Parent = decor,
			Size = Vector3.new(2, h, 2),
			Position = Vector3.new(x, baseY + h * 0.4, z),
			Color = Color3.fromRGB(140 + rng:NextInteger(0, 80), 100, 255),
			Material = Enum.Material.Neon,
			CanCollide = false,
			Transparency = 0.15,
		})
		crystal.CFrame = CFrame.new(crystal.Position)
			* CFrame.Angles(rng:NextNumber() * 0.4, rng:NextNumber() * 3, rng:NextNumber() * 0.4)
		local pl = Instance.new("PointLight")
		pl.Brightness = 0.8
		pl.Range = 14
		pl.Color = Color3.fromRGB(180, 140, 255)
		pl.Parent = crystal
	end

	-- Floating islands
	for i = 1, 10 do
		local x = originX + (rng:NextNumber() - 0.5) * 80
		local z = -40 - rng:NextNumber() * 200
		local y = baseY + 10 + rng:NextNumber() * 25
		part({
			Name = "Island" .. i,
			Parent = decor,
			Size = Vector3.new(8 + rng:NextNumber() * 14, 3, 8 + rng:NextNumber() * 12),
			Position = Vector3.new(x, y, z),
			Color = Color3.fromRGB(90, 70, 130),
			Material = Enum.Material.Basalt,
			CanCollide = false,
		})
	end
end

function TerrainGenerator:_neon(parent: Instance, originX: number, baseY: number, rng: Random)
	local decor = Instance.new("Folder")
	decor.Name = "NeonDecor"
	decor.Parent = parent

	-- Grid towers
	for i = 1, 18 do
		local side = if i % 2 == 0 then 1 else -1
		local x = originX + side * (20 + (i % 5) * 8)
		local z = -i * 14
		local h = 30 + (i * 7) % 50
		part({
			Name = "Tower" .. i,
			Parent = decor,
			Size = Vector3.new(6, h, 6),
			Position = Vector3.new(x, baseY + h * 0.35 - 5, z),
			Color = Color3.fromRGB(25, 28, 45),
			Material = Enum.Material.Metal,
			CanCollide = false,
		})
		-- neon strip
		local strip = part({
			Name = "Strip" .. i,
			Parent = decor,
			Size = Vector3.new(6.4, 1.2, 0.6),
			Position = Vector3.new(x, baseY + 8 + (i % 4) * 6, z + 3.2),
			Color = if i % 2 == 0 then Color3.fromRGB(80, 255, 230) else Color3.fromRGB(255, 60, 140),
			Material = Enum.Material.Neon,
			CanCollide = false,
		})
		local pl = Instance.new("PointLight")
		pl.Brightness = 1.5
		pl.Range = 22
		pl.Color = strip.Color
		pl.Parent = strip
	end

	-- Ring platforms (visual)
	for i = 1, 8 do
		local z = -30 - i * 28
		local y = baseY + 6 + i * 2
		part({
			Name = "Ring" .. i,
			Parent = decor,
			Size = Vector3.new(22, 0.6, 22),
			Position = Vector3.new(originX + 18, y, z),
			Color = Color3.fromRGB(40, 255, 200),
			Material = Enum.Material.ForceField,
			CanCollide = false,
			Transparency = 0.5,
		})
	end

	-- Rain of tiny neon cubes
	for i = 1, 40 do
		local x = originX + (rng:NextNumber() - 0.5) * 70
		local z = -rng:NextNumber() * 280
		local y = baseY + 5 + rng:NextNumber() * 40
		part({
			Name = "Bit" .. i,
			Parent = decor,
			Size = Vector3.new(1, 1, 1),
			Position = Vector3.new(x, y, z),
			Color = Color3.fromRGB(rng:NextInteger(40, 255), rng:NextInteger(40, 255), 255),
			Material = Enum.Material.Neon,
			CanCollide = false,
			Transparency = 0.3,
			CastShadow = false,
		})
	end
end

function TerrainGenerator:Generate(stagesRoot: Instance?): Folder
	local root = workspace:FindFirstChild("AuraFarmTerrain")
	if root then
		root:Destroy()
	end
	root = Instance.new("Folder")
	root.Name = "AuraFarmTerrain"
	root.Parent = workspace

	self:_void(root)
	self:_horizon(root, 220)

	for _, def in StageConfig.Stages do
		local seed = 1000 + def.id * 97
		local rng = rngFrom(seed)
		if def.theme == "meadow" then
			self:_meadow(root, def.originX, def.baseY, rng)
		elseif def.theme == "canyon" then
			self:_canyon(root, def.originX, def.baseY, rng)
		elseif def.theme == "neon" then
			self:_neon(root, def.originX, def.baseY, rng)
		end
	end

	print("[TerrainGenerator] Biomes dressed for", StageConfig.Count(), "stages")
	return root
end

return TerrainGenerator
