-- TerrainGenerator.luau
-- Procedural terrain generation for obby stages

local TerrainGenerator = {}
TerrainGenerator.__index = TerrainGenerator

local Terrain = workspace.Terrain

-- Noise function (Perlin-like)
local function noise2d(x: number, z: number, seed: number): number
    local i = math.floor(x)
    local j = math.floor(z)
    local f = x - i
    local g = z - j
    
    local h = function(a: number, b: number)
        local k = (seed * 73856093) ~ (a * 19349663) ~ (b * 83492791)
        k = math.abs(math.sin(k) * 43758.5453)
        return k - math.floor(k)
    end
    
    local n00 = h(i, j)
    local n10 = h(i + 1, j)
    local n01 = h(i, j + 1)
    local n11 = h(i + 1, j + 1)
    
    local u = f * f * (3.0 - 2.0 * f)
    local v = g * g * (3.0 - 2.0 * g)
    
    local nx0 = n00 + u * (n10 - n00)
    local nx1 = n01 + u * (n11 - n01)
    return nx0 + v * (nx1 - nx0)
end

-- Generate a single obby stage
function TerrainGenerator:GenerateStage(stageNumber: number, difficulty: number?)
    difficulty = difficulty or (stageNumber / 10)  -- Increases with stage number
    difficulty = math.clamp(difficulty, 0, 1)
    
    local stageFolder = Instance.new("Folder")
    stageFolder.Name = "Stage_" .. stageNumber
    stageFolder.Parent = workspace:FindFirstChild("Stages") or workspace
    
    -- Stage starting position
    local startX = (stageNumber - 1) * 50
    local startZ = 0
    
    -- Generate main platform
    local platformSize = 10
    local platform = Instance.new("Part")
    platform.Shape = Enum.PartType.Block
    platform.Size = Vector3.new(platformSize, 2, platformSize)
    platform.TopSurface = Enum.SurfaceType.Smooth
    platform.BottomSurface = Enum.SurfaceType.Smooth
    platform.Material = Enum.Material.Concrete
    platform.BrickColor = BrickColor.new("Dark stone grey")
    platform.CanCollide = true
    platform.Position = Vector3.new(startX, 10, startZ)
    platform.Parent = stageFolder
    
    -- Add stage complexity based on difficulty
    if difficulty > 0.3 then
        self:_addObstacles(stageFolder, startX, startZ, difficulty)
    end
    
    if difficulty > 0.5 then
        self:_addMovingPlatforms(stageFolder, startX, startZ)
    end
    
    if difficulty > 0.7 then
        self:_addHazards(stageFolder, startX, startZ)
    end
    
    -- Add finish line
    local finishLine = Instance.new("Part")
    finishLine.Shape = Enum.PartType.Block
    finishLine.Size = Vector3.new(platformSize, 2, platformSize)
    finishLine.TopSurface = Enum.SurfaceType.Smooth
    finishLine.BottomSurface = Enum.SurfaceType.Smooth
    finishLine.Material = Enum.Material.Neon
    finishLine.BrickColor = BrickColor.new("Lime green")
    finishLine.CanCollide = true
    finishLine.Position = Vector3.new(startX + 40, 10, startZ)
    finishLine.Parent = stageFolder
    
    finishLine:SetAttribute("IsFinish", true)
    finishLine:SetAttribute("StageNumber", stageNumber)
    
    return stageFolder
end

-- Add jumping obstacles
function TerrainGenerator:_addObstacles(stageFolder: Folder, startX: number, startZ: number, difficulty: number)
    local obstacleCount = math.ceil(3 + difficulty * 5)
    
    for i = 1, obstacleCount do
        local platform = Instance.new("Part")
        platform.Shape = Enum.PartType.Block
        platform.Size = Vector3.new(8 - difficulty * 2, 1, 8 - difficulty * 2)
        platform.TopSurface = Enum.SurfaceType.Smooth
        platform.BottomSurface = Enum.SurfaceType.Smooth
        platform.Material = Enum.Material.Concrete
        platform.BrickColor = BrickColor.new("Medium stone grey")
        platform.CanCollide = true
        platform.Position = Vector3.new(
            startX + 10 + (i * 4),
            10 + (i * 2) + (noise2d(i, difficulty, 42) * 3),
            startZ + (noise2d(i * 0.5, difficulty, 123) * 8 - 4)
        )
        platform.Parent = stageFolder
    end
end

-- Add moving platforms
function TerrainGenerator:_addMovingPlatforms(stageFolder: Folder, startX: number, startZ: number)
    for i = 1, 2 do
        local platform = Instance.new("Part")
        platform.Shape = Enum.PartType.Block
        platform.Size = Vector3.new(6, 1, 6)
        platform.TopSurface = Enum.SurfaceType.Smooth
        platform.BottomSurface = Enum.SurfaceType.Smooth
        platform.Material = Enum.Material.SmoothPlastic
        platform.BrickColor = BrickColor.new("Bright blue")
        platform.CanCollide = true
        platform.Position = Vector3.new(startX + 20 + (i * 5), 15, startZ)
        platform.Parent = stageFolder
        
        -- Create oscillating motion
        local runService = game:GetService("RunService")
        local startPos = platform.Position
        
        runService.Heartbeat:Connect(function()
            if platform.Parent then
                local angle = (tick() + i) % (math.pi * 2)
                platform.Position = startPos + Vector3.new(math.sin(angle) * 5, 0, 0)
            end
        end)
    end
end

-- Add hazard spikes
function TerrainGenerator:_addHazards(stageFolder: Folder, startX: number, startZ: number)
    for i = 1, 3 do
        local spike = Instance.new("Part")
        spike.Shape = Enum.PartType.Block
        spike.Size = Vector3.new(2, 3, 2)
        spike.TopSurface = Enum.SurfaceType.Smooth
        spike.BottomSurface = Enum.SurfaceType.Smooth
        spike.Material = Enum.Material.Neon
        spike.BrickColor = BrickColor.new("Bright red")
        spike.CanCollide = true
        spike.Position = Vector3.new(startX + 15 + (i * 4), 8, startZ)
        spike.Parent = stageFolder
        
        spike:SetAttribute("IsHazard", true)
    end
end

-- Generate full obby (multiple stages)
function TerrainGenerator:GenerateObby(stageCount: number)
    local obbyFolder = Instance.new("Folder")
    obbyFolder.Name = "Stages"
    obbyFolder.Parent = workspace
    
    for i = 1, stageCount do
        self:GenerateStage(i, i / stageCount)
        task.wait(0.1)  -- Prevent lag
    end
    
    return obbyFolder
end

return TerrainGenerator
