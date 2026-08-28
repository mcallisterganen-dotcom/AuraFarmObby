-- Scenic props / backdrop around the main StageBuilder course.
-- Does NOT create a second competing stage — only decoration + optional side pads.

local TerrainGenerator = {}
TerrainGenerator.__index = TerrainGenerator

local function part(props: { [string]: any }): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in props do
		(p :: any)[k] = v
	end
	return p
end

function TerrainGenerator.new()
	return setmetatable({}, TerrainGenerator)
end

-- Decorate an existing stage folder (from StageBuilder).
function TerrainGenerator:DecorateStage(stageFolder: Instance)
	local decor = stageFolder:FindFirstChild("Decor")
	if decor then
		decor:ClearAllChildren()
	else
		decor = Instance.new("Folder")
		decor.Name = "Decor"
		decor.Parent = stageFolder
	end

	-- Soft ground strips beside the course
	for i = -2, 2 do
		if i ~= 0 then
			local strip = part({
				Name = "GrassStrip",
				Size = Vector3.new(18, 1, 120),
				Position = Vector3.new(i * 22, 0.5, 40),
				Material = Enum.Material.Grass,
				Color = Color3.fromRGB(52, 120, 55),
				Parent = decor,
			})
		end
	end

	-- Rocks
	local rng = Random.new(42)
	for i = 1, 14 do
		local s = rng:NextNumber(2, 6)
		part({
			Name = "Rock" .. i,
			Size = Vector3.new(s, s * rng:NextNumber(0.6, 1.2), s * rng:NextNumber(0.7, 1.1)),
			Position = Vector3.new(rng:NextNumber(-40, 40), s * 0.35, rng:NextNumber(-10, 110)),
			Material = Enum.Material.Slate,
			Color = Color3.fromRGB(90, 90, 100),
			Orientation = Vector3.new(rng:NextNumber(-20, 20), rng:NextNumber(0, 360), rng:NextNumber(-20, 20)),
			Parent = decor,
		})
	end

	-- Soft fill under spawn so falls feel less void-y near start
	part({
		Name = "SafetyPlate",
		Size = Vector3.new(40, 1, 40),
		Position = Vector3.new(0, -20, 0),
		Material = Enum.Material.Concrete,
		Color = Color3.fromRGB(40, 40, 55),
		Transparency = 0.35,
		Parent = decor,
	})

	-- Floating ambient crystals (non-collide juice)
	for i = 1, 8 do
		local c = part({
			Name = "Crystal" .. i,
			Size = Vector3.new(1.2, 3 + rng:NextNumber(0, 2), 1.2),
			Position = Vector3.new(rng:NextNumber(-30, 30), 8 + rng:NextNumber(0, 20), rng:NextNumber(10, 100)),
			Material = Enum.Material.Neon,
			Color = Color3.fromRGB(160, 100, 255),
			CanCollide = false,
			Transparency = 0.25,
			Parent = decor,
		})
		local light = Instance.new("PointLight")
		light.Color = c.Color
		light.Brightness = 1.2
		light.Range = 14
		light.Parent = c
	end

	print("[TerrainGenerator] Decor applied to", stageFolder.Name)
	return decor
end

return TerrainGenerator
