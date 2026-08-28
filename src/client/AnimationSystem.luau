-- Locomotion layer that REPLACES the default Animate LocalScript behavior
-- so run/walk look correct and don't fight stock animate.

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AnimationConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("AnimationConfig"))

local AnimationSystem = {}
AnimationSystem.__index = AnimationSystem

local function loadTrack(animator: Animator, id: string, priority: Enum.AnimationPriority, looped: boolean): AnimationTrack?
	local anim = Instance.new("Animation")
	anim.AnimationId = id
	local ok, track = pcall(function()
		return animator:LoadAnimation(anim)
	end)
	if not ok or not track then
		warn("[AnimationSystem] Failed to load", id, track)
		return nil
	end
	track.Priority = priority
	track.Looped = looped
	return track
end

function AnimationSystem.new(character: Model, humanoid: Humanoid, hrp: BasePart)
	local self = setmetatable({}, AnimationSystem)
	self.character = character
	self.humanoid = humanoid
	self.hrp = hrp
	self._destroyed = false
	self._tracks = {} :: { [string]: AnimationTrack }
	self._current = nil :: string?
	self._emoteTrack = nil :: AnimationTrack?

	-- Mute default Animate so we own locomotion
	local animate = character:FindFirstChild("Animate")
	if animate and animate:IsA("LocalScript") then
		animate.Disabled = true
	elseif animate then
		-- ModuleScript / Script variants
		pcall(function()
			(animate :: any).Disabled = true
		end)
	end
	-- Stop any leftover tracks
	for _, t in humanoid:GetPlayingAnimationTracks() do
		t:Stop(0)
	end

	local animator = humanoid:FindFirstChildOfClass("Animator")
	if not animator then
		animator = Instance.new("Animator")
		animator.Parent = humanoid
	end
	self.animator = animator

	local ids = AnimationConfig.Ids
	local pri = AnimationConfig.Priorities
	self._tracks.Idle = loadTrack(animator, ids.Idle, pri.Idle, true)
	self._tracks.Walk = loadTrack(animator, ids.Walk, pri.Walk, true)
	self._tracks.Run = loadTrack(animator, ids.Run, pri.Run, true)
	self._tracks.Jump = loadTrack(animator, ids.Jump, pri.Jump, false)
	self._tracks.Fall = loadTrack(animator, ids.Fall, pri.Fall, true)

	self._emotes = {}
	for _, name in AnimationConfig.EmoteList do
		local id = ids[name]
		if id then
			self._emotes[name] = loadTrack(animator, id, pri.Emote, false)
		end
	end

	-- Start idle
	self:_play("Idle", 0.2)

	self._stateConn = humanoid.StateChanged:Connect(function(_, new)
		if self._destroyed then
			return
		end
		if new == Enum.HumanoidStateType.Jumping then
			self:_play("Jump", 0.05)
		elseif new == Enum.HumanoidStateType.Freefall then
			self:_play("Fall", 0.1)
		end
	end)

	self._hb = RunService.RenderStepped:Connect(function()
		if self._destroyed then
			return
		end
		self:_tick()
	end)

	return self
end

function AnimationSystem:_play(name: string, fade: number?)
	if self._current == name and name ~= "Jump" then
		return
	end
	local track = self._tracks[name]
	if not track then
		return
	end
	local fadeTime = fade or AnimationConfig.FadeTime
	if self._current and self._tracks[self._current] and self._current ~= name then
		self._tracks[self._current]:Stop(fadeTime)
	end
	track:Play(fadeTime)
	self._current = name
end

function AnimationSystem:_tick()
	if self._emoteTrack and self._emoteTrack.IsPlaying then
		return
	end
	local hum = self.humanoid
	local state = hum:GetState()
	if state == Enum.HumanoidStateType.Jumping then
		return
	end
	if state == Enum.HumanoidStateType.Freefall then
		if self._current ~= "Fall" then
			self:_play("Fall", 0.08)
		end
		return
	end
	if state == Enum.HumanoidStateType.Climbing then
		return
	end

	local speed = hum.MoveDirection.Magnitude * hum.WalkSpeed
	-- also use assembly velocity for slope/air remnants
	local hrp = self.hrp
	if hrp then
		local v = hrp.AssemblyLinearVelocity
		local planar = Vector3.new(v.X, 0, v.Z).Magnitude
		speed = math.max(speed, planar)
	end

	if speed < AnimationConfig.WalkSpeedThreshold then
		self:_play("Idle", 0.15)
	elseif hum.WalkSpeed >= AnimationConfig.RunSpeedThreshold or speed >= AnimationConfig.RunSpeedThreshold then
		self:_play("Run", 0.1)
		local run = self._tracks.Run
		if run then
			run:AdjustSpeed(math.clamp(speed / 20, 0.85, 1.35))
		end
	else
		self:_play("Walk", 0.1)
		local walk = self._tracks.Walk
		if walk then
			walk:AdjustSpeed(math.clamp(speed / 12, 0.7, 1.4))
		end
	end
end

function AnimationSystem:PlayEmote(name: string): boolean
	if name == "Victory" then
		name = "Cheer"
	end
	local track = self._emotes[name]
	if not track then
		return false
	end
	if self._emoteTrack and self._emoteTrack.IsPlaying then
		self._emoteTrack:Stop(0.1)
	end
	-- pause locomotion
	if self._current and self._tracks[self._current] then
		self._tracks[self._current]:Stop(0.1)
	end
	self._current = nil
	track:Play(0.1)
	self._emoteTrack = track
	track.Stopped:Once(function()
		if self._emoteTrack == track then
			self._emoteTrack = nil
		end
	end)
	return true
end

function AnimationSystem:PlayNextEmote(): string?
	self._emoteIndex = (self._emoteIndex or 0) + 1
	local list = AnimationConfig.EmoteList
	local name = list[((self._emoteIndex - 1) % #list) + 1]
	if self:PlayEmote(name) then
		return name
	end
	return nil
end

function AnimationSystem:Destroy()
	self._destroyed = true
	if self._hb then
		self._hb:Disconnect()
	end
	if self._stateConn then
		self._stateConn:Disconnect()
	end
	for _, t in self._tracks do
		t:Stop(0)
	end
	self._tracks = {}
end

return AnimationSystem
