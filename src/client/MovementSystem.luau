-- MovementSystem.luau
-- Advanced physics-based movement controller for obby

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local MovementConfig = require(game.ReplicatedStorage:WaitForChild("shared"):WaitForChild("MovementConfig"))

local MovementSystem = {}
MovementSystem.__index = MovementSystem

function MovementSystem.new(character: Model, humanoid: Humanoid, humanoidRootPart: BasePart)
    local self = setmetatable({}, MovementSystem)
    
    self.character = character
    self.humanoid = humanoid
    self.rootPart = humanoidRootPart
    
    -- State tracking
    self.isGrounded = false
    self.isCrouching = false
    self.isSliding = false
    self.isSprinting = false
    self.currentVelocity = Vector3.new()
    self.moveDirection = Vector3.new()
    
    -- Camera
    self.camera = workspace.CurrentCamera
    self.originalCameraOffset = Vector3.new()
    
    -- Input tracking
    self.inputDirection = Vector3.new()
    self.lastJumpTime = 0
    self.lastSlideTime = 0
    
    -- Physics
    self.lastGroundNormal = Vector3.new(0, 1, 0)
    self.slopeAngle = 0
    
    -- Connect to heartbeat for physics updates
    self.heartbeatConnection = RunService.Heartbeat:Connect(function()
        self:_updatePhysics()
    end)
    
    -- Connect to input
    self:_setupInputHandling()
    
    -- Cleanup on death
    humanoid.Died:Connect(function()
        self:Destroy()
    end)
    
    return self
end

-- Setup input handling
function MovementSystem:_setupInputHandling()
    local shiftHeld = false
    
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
            shiftHeld = true
            self.isSprinting = true
        elseif input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.RightControl then
            if MovementConfig.Crouch.Enabled and not self.isSliding then
                self:_setCrouch(true)
            end
        elseif input.KeyCode == Enum.KeyCode.C then
            if MovementConfig.Sliding.Enabled and self.isGrounded and os.clock() - self.lastSlideTime > MovementConfig.Sliding.Cooldown then
                self:_startSlide()
            end
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input, gameProcessed)
        if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
            shiftHeld = false
            self.isSprinting = false
        elseif input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.RightControl then
            if MovementConfig.Crouch.Enabled then
                self:_setCrouch(false)
            end
        end
    end)
    
    -- Track movement input
    RunService.Heartbeat:Connect(function()
        local moveDir = Vector3.new()
        
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + self.camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - self.camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - self.camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + self.camera.CFrame.RightVector end
        
        if moveDir.Magnitude > 0 then
            moveDir = moveDir.Unit
        end
        
        self.moveDirection = moveDir
    end)
end

-- Detect if player is grounded
function MovementSystem:_checkGrounded()
    if not self.rootPart then return false end
    
    local rayOrigin = self.rootPart.Position
    local rayDirection = Vector3.new(0, -10, 0)
    
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Ignore
    raycastParams.FilterDescendantsInstances = {self.character}
    
    local result = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
    
    if result then
        self.lastGroundNormal = result.Normal
        -- Calculate slope angle
        self.slopeAngle = math.acos(math.clamp(result.Normal.Y, -1, 1))
        return true
    end
    
    return false
end

-- Update physics each frame
function MovementSystem:_updatePhysics()
    if not self.character.Parent or not self.humanoid then return end
    
    self.isGrounded = self:_checkGrounded()
    
    local targetVelocity = self:_calculateTargetVelocity()
    
    -- Smooth velocity transition
    local acceleration = self.isGrounded and MovementConfig.Acceleration or MovementConfig.AirDeceleration
    self.currentVelocity = self.currentVelocity:Lerp(targetVelocity, acceleration * game:GetService("RunService").Heartbeat:Wait() / 60)
    
    -- Apply velocity
    self.rootPart.AssemblyLinearVelocity = Vector3.new(
        self.currentVelocity.X,
        self.rootPart.AssemblyLinearVelocity.Y,  -- Preserve Y for gravity
        self.currentVelocity.Z
    )
    
    -- Update camera
    self:_updateCamera()
end

-- Calculate target velocity based on input and state
function MovementSystem:_calculateTargetVelocity()
    local direction = self.moveDirection
    if direction.Magnitude == 0 then
        return Vector3.new() * 0.95  -- Friction
    end
    
    local maxSpeed = MovementConfig.BaseWalkSpeed
    
    if self.isSprinting and self.isGrounded then
        maxSpeed = maxSpeed * MovementConfig.SprintMultiplier
    elseif self.isCrouching then
        maxSpeed = MovementConfig.CrouchWalkSpeed
    elseif self.isSliding then
        maxSpeed = MovementConfig.Sliding.SpeedMultiplier * MovementConfig.BaseWalkSpeed
    end
    
    -- Slope acceleration
    if self.isGrounded and MovementConfig.Slopes.Enabled and self.slopeAngle > MovementConfig.Slopes.Threshold then
        maxSpeed = math.min(maxSpeed + MovementConfig.Slopes.Acceleration, MovementConfig.Slopes.MaxSpeed)
    end
    
    -- Air strafing
    if not self.isGrounded and MovementConfig.AirStrafe.Enabled then
        maxSpeed = math.min(maxSpeed, MovementConfig.AirStrafe.MaxSpeed)
    end
    
    return direction * maxSpeed
end

-- Crouch system
function MovementSystem:_setCrouch(enabled: boolean)
    if self.isCrouching == enabled then return end
    if self.isSliding then return end
    
    self.isCrouching = enabled
    
    if enabled then
        self.humanoid.WalkSpeed = MovementConfig.Crouch.WalkSpeed
        self.humanoid.HipHeight = self.humanoid.HipHeight + MovementConfig.Crouch.HipHeightDelta
    else
        -- Check for ceiling
        if MovementConfig.Crouch.CeilingCheck then
            local rayOrigin = self.rootPart.Position
            local rayDirection = Vector3.new(0, 5, 0)
            local raycastParams = RaycastParams.new()
            raycastParams.FilterType = Enum.RaycastFilterType.Ignore
            raycastParams.FilterDescendantsInstances = {self.character}
            
            local result = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
            if result then
                return  -- Can't uncrouch, ceiling in the way
            end
        end
        
        self.humanoid.WalkSpeed = MovementConfig.BaseWalkSpeed
        self.humanoid.HipHeight = self.humanoid.HipHeight - MovementConfig.Crouch.HipHeightDelta
    end
end

-- Sliding system
function MovementSystem:_startSlide()
    if self.isSliding or not self.isGrounded then return end
    if os.clock() - self.lastSlideTime < MovementConfig.Sliding.Cooldown then return end
    
    self.isSliding = true
    self.lastSlideTime = os.clock()
    self.currentVelocity = self.moveDirection * (self.currentVelocity.Magnitude + MovementConfig.Sliding.SpeedBoost)
    
    -- Disable crouch during slide
    if self.isCrouching then
        self:_setCrouch(false)
    end
    
    -- Auto-end slide after max time or if too slow
    task.spawn(function()
        local slideStart = os.clock()
        while self.isSliding and self.character.Parent do
            if os.clock() - slideStart > MovementConfig.Sliding.MaxAirTime then
                self.isSliding = false
                break
            end
            if self.isGrounded and self.currentVelocity.Magnitude < MovementConfig.Sliding.MinSpeed then
                self.isSliding = false
                break
            end
            task.wait(0.1)
        end
    end)
end

-- Update camera with dynamic feedback
function MovementSystem:_updateCamera()
    if not self.camera then return end
    
    local targetFOV = MovementConfig.Camera.NormalFOV
    local targetOffset = Vector3.new()
    
    -- Increase FOV while sliding
    if self.isSliding then
        targetFOV = MovementConfig.Camera.SlideFOV
        targetOffset = MovementConfig.Camera.CrouchDrop
    end
    
    -- Increase FOV at high speeds
    local speed = self.currentVelocity.Magnitude
    if speed > MovementConfig.BaseWalkSpeed * 2 then
        targetFOV = MovementConfig.Camera.MaxSpeedFOV
    end
    
    -- Tween FOV
    local tweenInfo = TweenInfo.new(
        MovementConfig.Camera.TweenSpeed,
        Enum.EasingStyle.Quad,
        Enum.EasingDirection.Out
    )
    
    TweenService:Create(
        self.camera,
        tweenInfo,
        { FieldOfView = targetFOV }
    ):Play()
end

-- Cleanup
function MovementSystem:Destroy()
    if self.heartbeatConnection then
        self.heartbeatConnection:Disconnect()
    end
end

return MovementSystem
