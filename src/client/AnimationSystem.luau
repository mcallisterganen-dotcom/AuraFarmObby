-- Smooth locomotion blending (Anima-inspired). Module — required by PlayerClient.

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AnimationConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("AnimationConfig"))

local AnimationSystem = {}
AnimationSystem.__index = AnimationSystem

local LOCOMOTION = { Idle = true, Walk = true, Run = true, Jump = true, Fall = true, Climb = true, Swim = true }

function AnimationSystem.new(character: Model, humanoid: Humanoid, _humanoidRootPart: BasePart)
	local self = setmetatable({}, AnimationSystem)

	self.character = character
	self.humanoid = humanoid
	self.animator = humanoid:FindFirstChildOfClass("Animator")
	if not self.animator then
		self.animator = Instance.new("Animator")
		self.animator.Parent = humanoid
	end

	self.tracks = {}
	self.currentState = "Idle"
	self.blendValue = 0
	self.emoteTrack = nil
	self._destroyed = false

	-- Soften default Animate script so our blends can be heard
	local animate = character:FindFirstChild("Animate")
	if animate and animate:IsA("LocalScript") then
		animate.Disabled = true
	end

	self:_loadAnimations()
	self:_play("Idle", 0.2)

	self.connection = RunService.Heartbeat:Connect(function()
		self:_updateBlend()
	end)

	humanoid.StateChanged:Connect(function(_old, new)
		if self._destroyed then
			return
		end
		if new == Enum.HumanoidStateType.Jumping then
			self:_playOneShot("Jump")
		elseif new == Enum.HumanoidStateType.Freefall then
			self:_transitionTo("Fall")
		elseif new == Enum.HumanoidStateType.Climbing then
			self:_transitionTo("Climb")
		elseif new == Enum.HumanoidStateType.Swimming then
			self:_transitionTo("Swim")
		end
	end)

	humanoid.Died:Connect(function()
		self:Destroy()
	end)

	return self
end

function AnimationSystem:_loadAnimations()
	for animName, animId in AnimationConfig.Animations do
		if type(animId) == "string" and animId ~= "" and animId ~= "rbxassetid://" then
			local anim = Instance.new("Animation")
			anim.AnimationId = animId
			local ok, track = pcall(function()
				return self.animator:LoadAnimation(anim)
			end)
			if ok and track then
				if LOCOMOTION[animName] then
					track.Priority = AnimationConfig.Priorities.Movement
					track.Looped = (animName == "Idle" or animName == "Walk" or animName == "Run" or animName == "Climb" or animName == "Swim" or animName == "Fall")
				else
					track.Priority = AnimationConfig.Priorities.Emote
					track.Looped = false
				end
				self.tracks[animName] = track
			end
		end
	end
end

function AnimationSystem:_play(name: string, fade: number?)
	local track = self.tracks[name]
	if not track then
		return
	end
	if not track.IsPlaying then
		track:Play(fade or 0.15)
	end
end

function AnimationSystem:_playOneShot(name: string)
	local track = self.tracks[name]
	if not track then
		return
	end
	track:Play(AnimationConfig.Blending.JumpFade)
end

function AnimationSystem:_updateBlend()
	if self._destroyed or not self.character.Parent or not self.humanoid then
		return
	end
	if self.emoteTrack and self.emoteTrack.IsPlaying then
		return
	end

	local state = self.humanoid:GetState()
	if state == Enum.HumanoidStateType.Climbing or state == Enum.HumanoidStateType.Swimming then
		return
	end
	if state == Enum.HumanoidStateType.Freefall or state == Enum.HumanoidStateType.Jumping then
		return
	end

	local speed = self.humanoid.MoveDirection.Magnitude * self.humanoid.WalkSpeed
	local targetState: string
	local targetBlend = 0

	if speed < AnimationConfig.Blending.WalkThreshold then
		targetState = "Idle"
		targetBlend = 0
	elseif speed < AnimationConfig.Blending.RunThreshold then
		targetState = "Walk"
		targetBlend = speed / AnimationConfig.Blending.RunThreshold
	else
		targetState = "Run"
		targetBlend = 1 + (math.min(speed, AnimationConfig.Blending.MaxRunSpeed) / AnimationConfig.Blending.MaxRunSpeed)
	end

	self.blendValue += (targetBlend - self.blendValue) * AnimationConfig.Blending.BlendRate

	if self.currentState ~= targetState then
		self:_transitionTo(targetState)
	end

	if self.tracks.Idle then
		self.tracks.Idle:AdjustWeight(math.clamp(1 - self.blendValue, 0, 1), 0.1)
	end
	if self.tracks.Walk then
		local walkWeight = math.clamp(1 - math.abs(self.blendValue - 0.5) * 2, 0, 1)
		if self.blendValue >= 1 then
			walkWeight = math.clamp(2 - self.blendValue, 0, 1)
		end
		self.tracks.Walk:AdjustWeight(walkWeight, 0.1)
		self.tracks.Walk:AdjustSpeed(AnimationConfig.Blending.WalkSpeed)
	end
	if self.tracks.Run then
		local runWeight = math.clamp(self.blendValue - 0.85, 0, 1)
		self.tracks.Run:AdjustWeight(runWeight, 0.1)
		self.tracks.Run:AdjustSpeed(AnimationConfig.Blending.RunSpeed)
	end
end

function AnimationSystem:_transitionTo(newState: string)
	local prev = self.tracks[self.currentState]
	if prev and prev.IsPlaying and self.currentState ~= newState then
		-- keep playing; weights handle blend — only stop unrelated one-shots
	end
	self.currentState = newState
	self:_play(newState, 0.2)
	-- Ensure idle/walk/run are all available for weight blend
	if newState == "Idle" or newState == "Walk" or newState == "Run" then
		self:_play("Idle", 0.2)
		self:_play("Walk", 0.2)
		self:_play("Run", 0.2)
	end
end

function AnimationSystem:PlayEmote(emoteName: string)
	local track = self.tracks[emoteName]
	if not track then
		warn("[AnimationSystem] Missing emote:", emoteName)
		return false
	end
	if self.emoteTrack and self.emoteTrack.IsPlaying then
		self.emoteTrack:Stop(0.1)
	end
	self.emoteTrack = track
	track:Play(0.1)
	return true
end

function AnimationSystem:Destroy()
	if self._destroyed then
		return
	end
	self._destroyed = true
	if self.connection then
		self.connection:Disconnect()
		self.connection = nil
	end
	for _, track in self.tracks do
		pcall(function()
			track:Stop(0)
			track:Destroy()
		end)
	end
	self.tracks = {}
end

return AnimationSystem
