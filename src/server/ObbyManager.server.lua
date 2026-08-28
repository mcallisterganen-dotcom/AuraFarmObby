-- ObbyManager.server.luau
-- Main server-side obby manager

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local ObbyManager = {}

-- Configuration
local STAGE_COUNT = 20
local CHECKPOINT_SAVE_INTERVAL = 5

-- DataStore for checkpoints
local checkpointStore = DataStoreService:GetDataStore("ObbyCheckpoints")

-- Player tracking
local playerProgress = {}

-- Setup stage checkpoint detection
local function setupStageDetection()
    local stages = workspace:WaitForChild("Stages")
    
    for _, stageFolder in ipairs(stages:GetChildren()) do
        local finishLine = stageFolder:FindFirstChild("FinishLine") or stageFolder:FindFirstChildWithAttribute("IsFinish", true)
        
        if finishLine then
            local touchConnection
            touchConnection = finishLine.Touched:Connect(function(hit)
                local character = hit.Parent
                local player = Players:GetPlayerFromCharacter(character)
                
                if player then
                    local stageNumber = finishLine:GetAttribute("StageNumber") or 1
                    
                    -- Save checkpoint
                    if not playerProgress[player] then
                        playerProgress[player] = {}
                    end
                    
                    playerProgress[player].CurrentStage = stageNumber
                    playerProgress[player].LastCheckpoint = tick()
                    
                    -- Reward with aura cosmetics based on stage
                    ObbyManager:RewardPlayer(player, stageNumber)
                    
                    print("[Obby] " .. player.Name .. " completed stage " .. stageNumber)
                end
            end)
        end
    end
end

-- Player joined
local function onPlayerAdded(player: Player)
    playerProgress[player] = {
        CurrentStage = 0,
        TotalTime = 0,
        StartTime = tick(),
    }
    
    -- Load saved checkpoint
    pcall(function()
        local saved = checkpointStore:GetAsync("player_" .. player.UserId)
        if saved then
            playerProgress[player].CurrentStage = saved.stage or 0
        end
    end)
end

-- Player left
local function onPlayerRemoving(player: Player)
    if playerProgress[player] then
        -- Save checkpoint
        pcall(function()
            checkpointStore:SetAsync("player_" .. player.UserId, {
                stage = playerProgress[player].CurrentStage,
                time = playerProgress[player].TotalTime,
            })
        end)
    end
    
    playerProgress[player] = nil
end

-- Reward player with cosmetics/currency
function ObbyManager:RewardPlayer(player: Player, stageNumber: number)
    -- Award coins based on stage difficulty
    local coinReward = 100 + (stageNumber * 50)
    
    -- Unlock cosmetics at certain stages
    if stageNumber == 5 then
        -- Unlock Gold Aura
    elseif stageNumber == 10 then
        -- Unlock Crimson Aura
    elseif stageNumber == 20 then
        -- Unlock Mystic Aura
    end
    
    return coinReward
end

-- Get player progress
function ObbyManager:GetPlayerProgress(player: Player)
    return playerProgress[player] or { CurrentStage = 0 }
end

-- Teleport player to checkpoint
function ObbyManager:TeleportToStage(player: Player, stageNumber: number)
    local character = player.Character
    if not character then return end
    
    local stages = workspace:FindFirstChild("Stages")
    if not stages then return end
    
    local stageFolder = stages:FindFirstChild("Stage_" .. stageNumber)
    if not stageFolder then return end
    
    local platform = stageFolder:FindFirstChild("Part") or stageFolder:GetChildren()[1]
    if not platform or not platform:IsA("BasePart") then return end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if humanoidRootPart then
        humanoidRootPart.CFrame = platform.CFrame + Vector3.new(0, 5, 0)
    end
end

-- Setup game
local function init()
    print("[Obby] Initializing...")
    
    -- Generate terrain if needed
    if not workspace:FindFirstChild("Stages") then
        local TerrainGenerator = require(script.Parent:WaitForChild("TerrainGenerator"))
        print("[Obby] Generating " .. STAGE_COUNT .. " stages...")
        TerrainGenerator:GenerateObby(STAGE_COUNT)
    end
    
    -- Setup stage detection
    task.wait(1)
    setupStageDetection()
    
    -- Connect player events
    Players.PlayerAdded:Connect(onPlayerAdded)
    Players.PlayerRemoving:Connect(onPlayerRemoving)
    
    -- Load existing players
    for _, player in ipairs(Players:GetPlayers()) do
        onPlayerAdded(player)
    end
    
    print("[Obby] Initialized successfully!")
end

init()

return ObbyManager
