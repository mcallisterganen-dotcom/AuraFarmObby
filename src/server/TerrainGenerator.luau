-- Grounded "aura void" world: solid ground under every stage, cliffs, fog walls,
-- ambient crystals. Gameplay pads stay on StageBuilder — this is the earth + atmosphere.

local StageConfig = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("StageConfig"))
local AuraTheme = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("AuraTheme"))
local ObbyConfig = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("ObbyConfig"))

local TerrainGenerator = {}
TerrainGenerator.__index = TerrainGenerator

local C = AuraTheme.Colors
local M = AuraTheme.Materials

local function part(props: { [string]: any }): BasePart
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = if props.CanCollide == nil then false else props.CanCollide
	p.Material = props.Material or M.Ground
	p.Color = props.Color or C.Ground
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

function TerrainGenerator.new()
	return setmetatable({}, TerrainGenerator)
end

-- Global void death plane — kills anyone who falls off the course
function TerrainGenerator:_voidKill(parent: Instance)
	-- Visual abyss
	part({
		Name = "VoidVisual",
		Parent = parent,
		Size = Vector3.new(4000, 8, 4000),
		Position = Vector3.new(200, -55, -200),
		Color = C.VoidDeep,
		Material = Enum.Material.SmoothPlastic,
		CanCollide = false,
		Transparency = 0.2,
		CastShadow = false,
	})

	-- Actual kill volume (wide + thick so you can't miss it)
	local kill = part({
		Name = "WorldVoidKill",
		Parent = parent,
		Size = Vector3.new(4000, 20, 4000),
		Position = Vector3.new(200, -70, -200),
		Color = C.Danger,
		Material = M.Glow,
		CanCollide = true,
		Transparency = 0.85,
		CastShadow = false,
	})
	kill:SetAttribute(ObbyConfig.KillTag, true)
	kill:SetAttribute("Kill", true)

	-- Soft fog wall rings (visual only)
	for i = 1, 6 do
		local r = 180 + i * 40
		part({
			Name = "FogRing" .. i,
			Parent = parent,
			Size = Vector3.new(r * 2, 80, r * 2),
			Position = Vector3.new(200, 20, -100),
			Color = C.Fog,
			Material = M.Force,
			CanCollide = false,
			Transparency = 0.92,
			CastShadow = false,
		})
	end
end

-- Solid ground plate under a stage so it never looks "floating in nothing"
function TerrainGenerator:_groundPlate(
	parent: Instance,
	originX: number,
	baseY: number,
	lengthZ: number,
	width: number,
	color: Color3
)
	local groundY = baseY - 14
	-- Main earth slab under the whole run
	part({
		Name = "GroundSlab",
		Parent = parent,
		Size = Vector3.new(width, 18, lengthZ),
		Position = Vector3.new(originX, groundY, -lengthZ * 0.45),
		Color = color,
		Material = M.Ground,
		CanCollide = true, -- can stand if you fall to the shelf
		CastShadow = true,
	})
	-- Side berms
	for _, side in { -1, 1 } do
		part({
			Name = "Berm",
			Parent = parent,
			Size = Vector3.new(14, 22, lengthZ * 0.9),
			Position = Vector3.new(originX + side * (width * 0.5 + 4), groundY + 2, -lengthZ * 0.4),
			Color = Color3.fromRGB(
				math.clamp(math.floor(color.R * 255) - 10, 0, 255),
				math.clamp(math.floor(color.G * 255) - 8, 0, 255),
				math.clamp(math.floor(color.B * 255) + 10, 0, 255)
			),
			Material = M.Rock,
			CanCollide = true,
		})
	end
	-- Kill shelf edge: if you walk off the ground plate you still hit void
	-- (void kill is global)
end

function TerrainGenerator:_roomShell(parent: Instance, originX: number, baseY: number, theme: string)
	-- Soft walls so each stage feels like a "room" in the void
	local wallColor = if theme == "neon"
		then Color3.fromRGB(20, 16, 40)
		elseif theme == "canyon" then Color3.fromRGB(35, 25, 55)
		else Color3.fromRGB(30, 40, 50)

	for _, side in { -1, 1 } do
		part({
			Name = "RoomWall",
			Parent = parent,
			Size = Vector3.new(6, 90, 320),
			Position = Vector3.new(originX + side * 95, baseY + 20, -120),
			Color = wallColor,
			Material = M.Rock,
			CanCollide = false,
			Transparency = 0.35,
		})
	end
	-- Back wall
	part({
		Name = "RoomBack",
		Parent = parent,
		Size = Vector3.new(200, 90, 6),
		Position = Vector3.new(originX, baseY + 20, 50),
		Color = wallColor,
		Material = M.Rock,
		CanCollide = false,
		Transparency = 0.4,
	})
	-- Far wall
	part({
		Name = "RoomFar",
		Parent = parent,
		Size = Vector3.new(200, 90, 6),
		Position = Vector3.new(originX, baseY + 20, -300),
		Color = wallColor,
		Material = M.Rock,
		CanCollide = false,
		Transparency = 0.45,
	})
end

function TerrainGenerator:_meadow(parent: Instance, originX: number, baseY: number, rng: Random)
	local decor = Instance.new("Folder")
	decor.Name = "MeadowDecor"
	decor.Parent = parent

	self:_groundPlate(decor, originX, baseY, 280, 70, Color3.fromRGB(32, 48, 40))
	self:_roomShell(decor, originX, baseY, "meadow")

	-- Soft grass mounds
	for i = 1, 36 do
		local side = if rng:NextNumber() > 0.5 then 1 else -1
		local x = originX + side * (16 + rng:NextNumber() * 40)
		local z = 10 - rng:NextNumber() * 240
		local h = 3 + rng:NextNumber() * 10
		part({
			Name = "Hill" .. i,
			Parent = decor,
			Size = Vector3.new(10 + rng:NextNumber() * 16, h, 10 + rng:NextNumber() * 14),
			Position = Vector3.new(x, baseY - 10 + h * 0.35, z),
			Color = Color3.fromRGB(40 + rng:NextInteger(0, 30), 90 + rng:NextInteger(0, 40), 70),
			Material = Enum.Material.Grass,
			CanCollide = false,
		})
	end

	-- Aura trees (purple-tinted canopy = farm vibe)
	for i = 1, 22 do
		local side = if rng:NextNumber() > 0.5 then 1 else -1
		local x = originX + side * (20 + rng:NextNumber() * 36)
		local z = -rng:NextNumber() * 220
		local trunkH = 7 + rng:NextNumber() * 5
		part({
			Name = "Trunk" .. i,
			Parent = decor,
			Size = Vector3.new(1.5, trunkH, 1.5),
			Position = Vector3.new(x, baseY - 6 + trunkH * 0.5, z),
			Color = Color3.fromRGB(70, 50, 40),
			Material = Enum.Material.Wood,
			CanCollide = false,
		})
		part({
			Name = "Canopy" .. i,
			Parent = decor,
			Size = Vector3.new(9, 7, 9),
			Position = Vector3.new(x, baseY - 6 + trunkH + 2.5, z),
			Color = Color3.fromRGB(90 + rng:NextInteger(0, 40), 60, 140 + rng:NextInteger(0, 40)),
			Material = Enum.Material.Grass,
			Shape = Enum.PartType.Ball,
			CanCollide = false,
		})
	end

	-- Path lanterns
	for i = 0, 14 do
		local z = -i * 16
		for _, side in { -1, 1 } do
			local x = originX + side * 11
			part({
				Name = "LanternPole",
				Parent = decor,
				Size = Vector3.new(0.55, 8, 0.55),
				Position = Vector3.new(x, baseY - 2, z),
				Color = Color3.fromRGB(50, 45, 70),
				Material = M.Metal,
				CanCollide = false,
			})
			local glow = part({
				Name = "LanternGlow",
				Parent = decor,
				Size = Vector3.new(1.4, 1.4, 1.4),
				Position = Vector3.new(x, baseY + 3, z),
				Color = C.Accent,
				Material = M.Glow,
				CanCollide = false,
				CastShadow = false,
			})
			local pl = Instance.new("PointLight")
			pl.Brightness = 1.4
			pl.Range = 20
			pl.Color = C.Accent
			pl.Parent = glow
		end
	end
end

function TerrainGenerator:_canyon(parent: Instance, originX: number, baseY: number, rng: Random)
	local decor = Instance.new("Folder")
	decor.Name = "CanyonDecor"
	decor.Parent = parent

	self:_groundPlate(decor, originX, baseY, 300, 64, Color3.fromRGB(36, 28, 55))
	self:_roomShell(decor, originX, baseY, "canyon")

	for i = 1, 26 do
		local side = if i % 2 == 0 then 1 else -1
		local x = originX + side * (14 + rng:NextNumber() * 12)
		local z = -rng:NextNumber() * 280
		local h = 18 + rng:NextNumber() * 36
		part({
			Name = "Cliff" .. i,
			Parent = decor,
			Size = Vector3.new(12 + rng:NextNumber() * 10, h, 16 + rng:NextNumber() * 18),
			Position = Vector3.new(x, baseY - 8 + h * 0.3, z),
			Color = Color3.fromRGB(60 + rng:NextInteger(0, 30), 45, 90 + rng:NextInteger(0, 40)),
			Material = M.Rock,
			CanCollide = true,
		})
	end

	for i = 1, 34 do
		local side = if rng:NextNumber() > 0.5 then 1 else -1
		local x = originX + side * (10 + rng:NextNumber() * 32)
		local z = -rng:NextNumber() * 260
		local h = 6 + rng:NextNumber() * 14
		local crystal = part({
			Name = "Crystal" .. i,
			Parent = decor,
			Size = Vector3.new(2.2, h, 2.2),
			Position = Vector3.new(x, baseY - 6 + h * 0.45, z),
			Color = Color3.fromRGB(150 + rng:NextInteger(0, 70), 100, 255),
			Material = M.Glow,
			CanCollide = false,
			Transparency = 0.12,
		})
		crystal.CFrame = CFrame.new(crystal.Position)
			* CFrame.Angles(rng:NextNumber() * 0.35, rng:NextNumber() * 3, rng:NextNumber() * 0.35)
		local pl = Instance.new("PointLight")
		pl.Brightness = 1.0
		pl.Range = 16
		pl.Color = C.Accent
		pl.Parent = crystal
	end
end

function TerrainGenerator:_neon(parent: Instance, originX: number, baseY: number, rng: Random)
	local decor = Instance.new("Folder")
	decor.Name = "NeonDecor"
	decor.Parent = parent

	self:_groundPlate(decor, originX, baseY, 320, 60, Color3.fromRGB(18, 16, 32))
	self:_roomShell(decor, originX, baseY, "neon")

	-- City grid floor under path (visual)
	for i = 0, 20 do
		local z = -i * 14
		part({
			Name = "GridLine",
			Parent = decor,
			Size = Vector3.new(50, 0.3, 0.6),
			Position = Vector3.new(originX, baseY - 12.5, z),
			Color = C.AccentCool,
			Material = M.Glow,
			CanCollide = false,
			Transparency = 0.4,
			CastShadow = false,
		})
	end

	for i = 1, 20 do
		local side = if i % 2 == 0 then 1 else -1
		local x = originX + side * (18 + (i % 5) * 7)
		local z = -i * 13
		local h = 28 + (i * 9) % 55
		part({
			Name = "Tower" .. i,
			Parent = decor,
			Size = Vector3.new(7, h, 7),
			Position = Vector3.new(x, baseY - 8 + h * 0.35, z),
			Color = Color3.fromRGB(22, 24, 40),
			Material = M.Metal,
			CanCollide = false,
		})
		local strip = part({
			Name = "Strip" .. i,
			Parent = decor,
			Size = Vector3.new(7.4, 1.4, 0.7),
			Position = Vector3.new(x, baseY + 6 + (i % 5) * 5, z + 3.5),
			Color = if i % 2 == 0 then C.AccentCool else C.AccentHot,
			Material = M.Glow,
			CanCollide = false,
			CastShadow = false,
		})
		local pl = Instance.new("PointLight")
		pl.Brightness = 1.6
		pl.Range = 24
		pl.Color = strip.Color
		pl.Parent = strip
	end

	for i = 1, 50 do
		local x = originX + (rng:NextNumber() - 0.5) * 60
		local z = -rng:NextNumber() * 290
		local y = baseY + rng:NextNumber() * 35
		part({
			Name = "Bit" .. i,
			Parent = decor,
			Size = Vector3.new(1.1, 1.1, 1.1),
			Position = Vector3.new(x, y, z),
			Color = Color3.fromRGB(rng:NextInteger(80, 255), rng:NextInteger(40, 200), 255),
			Material = M.Glow,
			CanCollide = false,
			Transparency = 0.25,
			CastShadow = false,
		})
	end
end

function TerrainGenerator:_lobby(parent: Instance)
	local decor = Instance.new("Folder")
	decor.Name = "LobbyDecor"
	decor.Parent = parent
	local spawn = StageConfig.LobbySpawn
	-- Big grounded plaza
	part({
		Name = "LobbyGround",
		Parent = decor,
		Size = Vector3.new(80, 16, 80),
		Position = spawn + Vector3.new(0, -10, 0),
		Color = C.Ground,
		Material = M.Ground,
		CanCollide = true,
	})
	-- Aura pillars
	for i = 0, 7 do
		local ang = (i / 8) * math.pi * 2
		local x = spawn.X + math.cos(ang) * 28
		local z = spawn.Z + math.sin(ang) * 28
		part({
			Name = "Pillar" .. i,
			Parent = decor,
			Size = Vector3.new(3, 20, 3),
			Position = Vector3.new(x, spawn.Y + 6, z),
			Color = C.Path,
			Material = M.Metal,
			CanCollide = false,
		})
		local cap = part({
			Name = "PillarCap" .. i,
			Parent = decor,
			Size = Vector3.new(4, 2, 4),
			Position = Vector3.new(x, spawn.Y + 16, z),
			Color = C.Accent,
			Material = M.Glow,
			CanCollide = false,
		})
		local pl = Instance.new("PointLight")
		pl.Brightness = 1.5
		pl.Range = 22
		pl.Color = C.Accent
		pl.Parent = cap
	end
end

function TerrainGenerator:Generate(_stagesRoot: Instance?): Folder
	local root = workspace:FindFirstChild("AuraFarmTerrain")
	if root then
		root:Destroy()
	end
	root = Instance.new("Folder")
	root.Name = "AuraFarmTerrain"
	root.Parent = workspace

	self:_voidKill(root)
	self:_lobby(root)

	for _, def in StageConfig.Stages do
		local seed = 1000 + def.id * 97
		local rng = Random.new(seed)
		local room = Instance.new("Folder")
		room.Name = "Room" .. def.id
		room:SetAttribute("StageId", def.id)
		room.Parent = root
		if def.theme == "meadow" then
			self:_meadow(room, def.originX, def.baseY, rng)
		elseif def.theme == "canyon" then
			self:_canyon(room, def.originX, def.baseY, rng)
		elseif def.theme == "neon" then
			self:_neon(room, def.originX, def.baseY, rng)
		end
	end

	print("[TerrainGenerator] Grounded aura rooms ready")
	return root
end

return TerrainGenerator
