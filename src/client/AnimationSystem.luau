-- AnimationSystem.luau
-- Handles smooth character animation blending (Anima-inspired)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local AnimationConfig = require(game.ReplicatedStorage:WaitForChild("shared"):WaitForChild("AnimationConfig"))

local AnimationSystem = {}
AnimationSystem.__index = AnimationSystem

-- Create a new animation system for a character
function AnimationSystem.new(character: Model, humanoid: Humanoid, humanoidRootPart: BasePart)
    local self = setmetatable({}, AnimationSystem)
    
    self.character = character
    self.humanoid = humanoid
    self.rootPart = humanoidRootPart
    self.animator = humanoid:WaitForChild("Animator")
    
    -- Animation tracks
    self.tracks = {}
    self.currentState = "Idle"
    self.blendValue = 0  -- 0 = Idle, 1 = Walk, 2+ = Run
    
    -- Load animations
    self:_loadAnimations()
    
    -- Connect to heartbeat for blending updates
    self.connection = RunService.Heartbeat:Connect(function()
        self:_updateBlend()
    end)
    
    -- Cleanup on character death
    humanoid.Died:Connect(function()
        self:Destroy()
    end)
    
    return self
end

-- Load all animation tracks
function AnimationSystem:_loadAnimations()
    for animName, animId in pairs(AnimationConfig.Animations) do
        local anim = Instance.new("Animation")
        anim.AnimationId = animId
        
        local track = self.animator:LoadAnimation(anim)
        track.Priority = AnimationConfig.Priorities.Movement
        track.Looped = (animName == "Idle" or animName == "Walk" or animName == "Run")
        
        self.tracks[animName] = track
    end
end

-- Update animation blending based on character speed
function AnimationSystem:_updateBlend()
    if not self.character.Parent or not self.humanoid then
        return
    end
    
    -- Calculate current speed
    local speed = self.humanoid.MoveDirection.Magnitude * self.humanoid.WalkSpeed
    
    -- Determine blend state
    local targetState
    local targetBlend = 0
    
    if speed < AnimationConfig.Blending.WalkThreshold then
        -- Idle
        targetState = "Idle"
        targetBlend = 0
    elseif speed < AnimationConfig.Blending.RunThreshold then
        -- Walking
        targetState = "Walk"
        targetBlend = speed / AnimationConfig.Blending.RunThreshold
    else
        -- Running
        targetState = "Run"
        targetBlend = 1 + (math.min(speed, AnimationConfig.Blending.MaxRunSpeed) / AnimationConfig.Blending.MaxRunSpeed)
    end
    
    -- Smooth blend transition
    self.blendValue = self.blendValue + (targetBlend - self.blendValue) * AnimationConfig.Blending.BlendRate
    
    -- Apply animations
    if self.currentState ~= targetState then
        self:_transitionTo(targetState)
    end
    
    -- Adjust playback speeds based on blend
    if self.tracks.Idle then
        self.tracks.Idle:AdjustWeight(1 - math.min(self.blendValue, 1), 0.1)
    end
    if self.tracks.Walk then
        local walkWeight = math.max(0, 1 - math.abs(self.blendValue - 0.5) * 2)
        self.tracks.Walk:AdjustWeight(walkWeight, 0.1)
        self.tracks.Walk:AdjustSpeed(AnimationConfig.Blending.WalkSpeed)
    end
    if self.tracks.Run then
        local runWeight = math.max(0, self.blendValue - 1)
        self.tracks.Run:AdjustWeight(runWeight, 0.1)
        self.tracks.Run:AdjustSpeed(AnimationConfig.Blending.RunSpeed)
    end
end

-- Transition to a new animation state
function AnimationSystem:_transitionTo(newState: string)
    -- Stop previous animations
    if self.tracks[self.currentState] then
        self.tracks[self.currentState]:Stop(AnimationConfig.FadeTimes.Normal)
    end
    
    -- Start new animation
    if self.tracks[newState] then
        self.tracks[newState]:Play(AnimationConfig.FadeTimes.Normal)
    end
    
    self.currentState = newState
end

-- Play a one-shot animation (emote, victory, etc.)
function AnimationSystem:PlayAction(actionName: string, fadeTime: number?)
    fadeTime = fadeTime or AnimationConfig.FadeTimes.Normal
    
    if not self.tracks[actionName] then
        warn("Animation not found: " .. actionName)
        return
    end
    
    -- Stop movement animations temporarily
    for _, track in pairs(self.tracks) do
        if track.IsPlaying and track.Name ~= actionName then
            track:Stop(fadeTime)
        end
    end
    
    -- Play action
    self.tracks[actionName]:Play(fadeTime)
    self.tracks[actionName].Priority = AnimationConfig.Priorities.Action
end

-- Resume movement animations after an action
function AnimationSystem:ResumeMovement()
    self:_transitionTo(self.currentState)
end

-- Cleanup
function AnimationSystem:Destroy()
    if self.connection then
        self.connection:Disconnect()
    end
    
    for _, track in pairs(self.tracks) do
        if track then
            track:Stop(0)
        end
    end
end

return AnimationSystem
