-- Parkour movement layer: sprint, crouch, slide.
-- Works WITH default Humanoid movement (does not reimplement WASD).

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MovementConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("MovementConfig"))

local MovementSystem = {}
MovementSystem.__index = MovementSystem

function MovementSystem.new(character: Model, humanoid: Humanoid, rootPart: BasePart)
	local self = setmetatable({}, MovementSystem)
	self.character = character
	self.humanoid = humanoid
	self.rootPart = rootPart
	self._destroyed = false

	self.isSprinting = false
	self.isCrouching = false
	self.isSliding = false
	self.lastSlide = 0
	self.baseHip = humanoid.HipHeight
	self.baseJump = humanoid.JumpPower > 0 and humanoid.JumpPower or humanoid.JumpHeight
	self.usingJumpPower = humanoid.UseJumpPower

	humanoid.WalkSpeed = MovementConfig.BaseWalkSpeed
	if humanoid.UseJumpPower then
		humanoid.JumpPower = MovementConfig.Jump.Power
	else
		-- approximate conversion
		humanoid.JumpHeight = math.clamp(MovementConfig.Jump.Power / 7.5, 5, 12)
	end

	self.camera = workspace.CurrentCamera
	self:_applyFov(MovementConfig.Camera.NormalFOV)

	self._began = UserInputService.InputBegan:Connect(function(input, gp)
		if gp or self._destroyed then
			return
		end
		if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
			self:SetSprint(true)
		elseif input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.RightControl then
			self:SetCrouch(true)
		elseif input.KeyCode == Enum.KeyCode.C then
			self:TrySlide()
		end
	end)

	self._ended = UserInputService.InputEnded:Connect(function(input)
		if self._destroyed then
			return
		end
		if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
			self:SetSprint(false)
		elseif input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.RightControl then
			self:SetCrouch(false)
		end
	end)

	self._hb = RunService.Heartbeat:Connect(function()
		self:_tick()
	end)

	humanoid.Died:Connect(function()
		self:Destroy()
	end)

	return self
end

function MovementSystem:_applyFov(fov: number)
	if not self.camera then
		return
	end
	TweenService:Create(
		self.camera,
		TweenInfo.new(MovementConfig.Camera.TweenSpeed, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
		{ FieldOfView = fov }
	):Play()
end

function MovementSystem:_refreshSpeed()
	if self._destroyed or not self.humanoid then
		return
	end
	if self.isSliding then
		return
	end
	if self.isCrouching then
		self.humanoid.WalkSpeed = MovementConfig.CrouchWalkSpeed
		self:_applyFov(MovementConfig.Camera.NormalFOV - 4)
	elseif self.isSprinting then
		self.humanoid.WalkSpeed = MovementConfig.BaseWalkSpeed * MovementConfig.SprintMultiplier
		self:_applyFov(MovementConfig.Camera.SprintFOV)
	else
		self.humanoid.WalkSpeed = MovementConfig.BaseWalkSpeed
		self:_applyFov(MovementConfig.Camera.NormalFOV)
	end
end

function MovementSystem:SetSprint(on: boolean)
	if self.isCrouching and on then
		return
	end
	self.isSprinting = on
	self:_refreshSpeed()
end

function MovementSystem:SetCrouch(on: boolean)
	if not MovementConfig.Crouch.Enabled then
		return
	end
	if self.isSliding then
		return
	end
	self.isCrouching = on
	if on then
		self.isSprinting = false
		self.humanoid.HipHeight = self.baseHip + MovementConfig.Crouch.HipHeightDelta
	else
		self.humanoid.HipHeight = self.baseHip
	end
	self:_refreshSpeed()
end

function MovementSystem:TrySlide()
	if not MovementConfig.Sliding.Enabled or self.isSliding or self._destroyed then
		return false
	end
	local now = os.clock()
	if now - self.lastSlide < MovementConfig.Sliding.Cooldown then
		return false
	end

	local hrp = self.rootPart
	local vel = hrp.AssemblyLinearVelocity
	local flat = Vector3.new(vel.X, 0, vel.Z)
	if flat.Magnitude < MovementConfig.Sliding.MinForwardSpeed and self.humanoid.MoveDirection.Magnitude < 0.2 then
		return false
	end

	self.isSliding = true
	self.lastSlide = now
	self.isCrouching = false
	self.humanoid.HipHeight = self.baseHip + MovementConfig.Crouch.HipHeightDelta
	self:_applyFov(MovementConfig.Camera.SlideFOV)

	local dir = flat.Magnitude > 1 and flat.Unit or self.humanoid.MoveDirection
	if dir.Magnitude < 0.1 then
		dir = hrp.CFrame.LookVector
	end
	dir = Vector3.new(dir.X, 0, dir.Z).Unit
	hrp.AssemblyLinearVelocity = Vector3.new(
		dir.X * (flat.Magnitude + MovementConfig.Sliding.SpeedBoost),
		vel.Y,
		dir.Z * (flat.Magnitude + MovementConfig.Sliding.SpeedBoost)
	)

	task.delay(MovementConfig.Sliding.Duration, function()
		if self._destroyed then
			return
		end
		self.isSliding = false
		if not self.isCrouching then
			self.humanoid.HipHeight = self.baseHip
		end
		self:_refreshSpeed()
	end)

	return true
end

function MovementSystem:_tick()
	if self._destroyed or not self.character.Parent then
		return
	end
	-- Keep sprint speed applied if shift held through air
	if self.isSprinting and not self.isCrouching and not self.isSliding then
		self.humanoid.WalkSpeed = MovementConfig.BaseWalkSpeed * MovementConfig.SprintMultiplier
	end
end

function MovementSystem:Destroy()
	if self._destroyed then
		return
	end
	self._destroyed = true
	if self._began then
		self._began:Disconnect()
	end
	if self._ended then
		self._ended:Disconnect()
	end
	if self._hb then
		self._hb:Disconnect()
	end
	if self.humanoid then
		self.humanoid.WalkSpeed = MovementConfig.BaseWalkSpeed
		self.humanoid.HipHeight = self.baseHip
	end
	self:_applyFov(MovementConfig.Camera.NormalFOV)
end

return MovementSystem
