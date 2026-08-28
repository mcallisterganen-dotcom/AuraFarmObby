-- Aura Farm Obby — server: stage, checkpoints, kills, orbs, finish, restart

print("[ObbyServer] Starting")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ObbyConfig = require(Shared:WaitForChild("ObbyConfig"))
local StageBuilder = require(script.Parent:WaitForChild("StageBuilder"))

local stageFolder = StageBuilder.build()
StageBuilder.startMovers(stageFolder)

-- Remotes
local remotes = Instance.new("Folder")
remotes.Name = "ObbyRemotes"
remotes.Parent = ReplicatedStorage

local function remoteEvent(name: string): RemoteEvent
	local r = Instance.new("RemoteEvent")
	r.Name = name
	r.Parent = remotes
	return r
end

local RE_Stats = remoteEvent("StatsChanged")
local RE_Toast = remoteEvent("Toast")
local RE_Finished = remoteEvent("Finished")
local RE_Restart = remoteEvent("RequestRestart")
local RE_RunReset = remoteEvent("RunReset")

export type PlayerState = {
	checkpointIndex: number,
	checkpointCFrame: CFrame,
	aura: number,
	coins: number,
	orbs: { [number]: boolean },
	orbCount: number,
	totalOrbs: number,
	deaths: number,
	finished: boolean,
	runStart: number,
	immunityUntil: number,
	bestTime: number?,
}

local states: { [Player]: PlayerState } = {}
local totalOrbs = 0
for _, child in stageFolder:GetChildren() do
	if child:GetAttribute(ObbyConfig.OrbTag) then
		totalOrbs += 1
	end
end

local function getStartCFrame(): CFrame
	local spawn = stageFolder:FindFirstChild("StageSpawn")
	if spawn and spawn:IsA("BasePart") then
		return spawn.CFrame + Vector3.new(0, 3, 0)
	end
	return CFrame.new(0, 6, 0)
end

local function pushStats(player: Player)
	local s = states[player]
	if not s then
		return
	end
	RE_Stats:FireClient(player, {
		aura = s.aura,
		coins = s.coins,
		orbs = s.orbCount,
		totalOrbs = s.totalOrbs,
		deaths = s.deaths,
		checkpoint = s.checkpointIndex,
		finished = s.finished,
		elapsed = os.clock() - s.runStart,
		bestTime = s.bestTime,
		gameName = ObbyConfig.GameName,
	})
end

local function toast(player: Player, text: string, kind: string?)
	RE_Toast:FireClient(player, text, kind or "info")
end

local function resetRun(player: Player, keepMeta: boolean)
	local prevBest = if keepMeta and states[player] then states[player].bestTime else nil
	local prevAura = if keepMeta and states[player] then states[player].aura else 0
	local prevCoins = if keepMeta and states[player] then states[player].coins else 0

	states[player] = {
		checkpointIndex = 0,
		checkpointCFrame = getStartCFrame(),
		aura = prevAura,
		coins = prevCoins,
		orbs = {},
		orbCount = 0,
		totalOrbs = totalOrbs,
		deaths = 0,
		finished = false,
		runStart = os.clock(),
		immunityUntil = os.clock() + 1,
		bestTime = prevBest,
	}

	-- Restore orb visibility for this player's "run" is server-authoritative collect once per run:
	-- Orbs are physical; we track per-player collection without destroying globally.
	RE_RunReset:FireClient(player)
	pushStats(player)
end

local function teleportTo(player: Player, cf: CFrame)
	local char = player.Character
	if not char then
		return false
	end
	local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		hrp = char:WaitForChild("HumanoidRootPart", 5) :: BasePart?
	end
	if not hrp then
		return false
	end
	local s = states[player]
	if s then
		s.immunityUntil = os.clock() + math.max(ObbyConfig.RespawnImmunitySeconds, 1.25)
	end
	hrp.AssemblyLinearVelocity = Vector3.zero
	hrp.AssemblyAngularVelocity = Vector3.zero
	char:PivotTo(cf)
	return true
end

local function respawnAtCheckpoint(player: Player)
	local s = states[player]
	if not s or s.finished then
		return
	end
	s.deaths += 1
	teleportTo(player, s.checkpointCFrame)
	pushStats(player)
	toast(player, "Checkpoint!", "bad")
end

local function onCharacter(player: Player, character: Model)
	local humanoid = character:WaitForChild("Humanoid", 10) :: Humanoid?
	if not humanoid then
		return
	end
	character:WaitForChild("HumanoidRootPart", 10)

	if not states[player] then
		resetRun(player, false)
	end

	-- Force onto checkpoint/start several times (Studio spawn can race scripts)
	task.spawn(function()
		local s = states[player]
		if not s then
			return
		end
		for _ = 1, 8 do
			teleportTo(player, s.checkpointCFrame)
			task.wait(0.1)
		end
		pushStats(player)
	end)

	humanoid.Died:Connect(function()
		local s = states[player]
		if s and not s.finished then
			-- deaths counted on kill-brick path; avoid double count if already immune-handled
			pushStats(player)
		end
	end)
end

local function bindPlayer(player: Player)
	resetRun(player, false)
	player.CharacterAdded:Connect(function(character)
		onCharacter(player, character)
	end)
	if player.Character then
		onCharacter(player, player.Character)
	end
end

-- Stage exists first; then players
Players.PlayerAdded:Connect(bindPlayer)
for _, player in Players:GetPlayers() do
	task.defer(bindPlayer, player)
end

Players.PlayerRemoving:Connect(function(player)
	states[player] = nil
end)

-- Touch handlers on stage parts
local function touchedByPlayer(hit: BasePart): (Player?, Model?)
	local character = hit:FindFirstAncestorOfClass("Model")
	if not character then
		return nil, nil
	end
	local player = Players:GetPlayerFromCharacter(character)
	if not player then
		return nil, nil
	end
	return player, character
end

local function hookPart(inst: Instance)
	if not inst:IsA("BasePart") then
		return
	end

	inst.Touched:Connect(function(hit)
		if not hit:IsA("BasePart") then
			return
		end
		local player = touchedByPlayer(hit)
		if not player then
			return
		end
		local s = states[player]
		if not s or s.finished then
			return
		end

		-- Kill bricks (debounce via immunity window)
		if inst:GetAttribute(ObbyConfig.KillTag) then
			if os.clock() < s.immunityUntil then
				return
			end
			s.immunityUntil = os.clock() + ObbyConfig.RespawnImmunitySeconds
			respawnAtCheckpoint(player)
			return
		end

		-- Checkpoints
		if inst:GetAttribute(ObbyConfig.CheckpointTag) then
			local idx = inst:GetAttribute("CheckpointIndex")
			if typeof(idx) == "number" and idx > s.checkpointIndex then
				s.checkpointIndex = idx
				s.checkpointCFrame = inst.CFrame + Vector3.new(0, 4, 0)
				pushStats(player)
				toast(player, `Checkpoint {idx}!`, "good")
			end
			return
		end

		-- Finish
		if inst:GetAttribute(ObbyConfig.FinishTag) then
			if s.finished then
				return
			end
			s.finished = true
			local elapsed = os.clock() - s.runStart
			if not s.bestTime or elapsed < s.bestTime then
				s.bestTime = elapsed
			end

			local auraGain = ObbyConfig.ClearAuraReward
			local coinGain = ObbyConfig.ClearCoinReward
			local bonuses = {}

			if s.deaths == 0 then
				auraGain += ObbyConfig.NoDeathBonusAura
				coinGain += ObbyConfig.NoDeathBonusCoins
				table.insert(bonuses, "No Death")
			end
			if s.orbCount >= s.totalOrbs and s.totalOrbs > 0 then
				auraGain += ObbyConfig.AllOrbsBonusAura
				coinGain += ObbyConfig.AllOrbsBonusCoins
				table.insert(bonuses, "All Orbs")
			end

			s.aura += auraGain
			s.coins += coinGain
			pushStats(player)

			RE_Finished:FireClient(player, {
				time = elapsed,
				bestTime = s.bestTime,
				auraGain = auraGain,
				coinGain = coinGain,
				auraTotal = s.aura,
				coinsTotal = s.coins,
				deaths = s.deaths,
				orbs = s.orbCount,
				totalOrbs = s.totalOrbs,
				bonuses = bonuses,
			})
			return
		end

		-- Aura orbs (per-player)
		if inst:GetAttribute(ObbyConfig.OrbTag) then
			local orbId = inst:GetAttribute("OrbId")
			if typeof(orbId) ~= "number" then
				return
			end
			if s.orbs[orbId] then
				return
			end
			s.orbs[orbId] = true
			s.orbCount += 1
			s.aura += ObbyConfig.OrbAuraValue
			pushStats(player)
			toast(player, `+{ObbyConfig.OrbAuraValue} Aura`, "aura")

			-- Local feedback: briefly flash orb (global flash is ok for v1)
			local old = inst.Transparency
			inst.Transparency = 0.85
			task.delay(0.35, function()
				if inst.Parent then
					inst.Transparency = old
				end
			end)
		end
	end)
end

for _, child in stageFolder:GetDescendants() do
	hookPart(child)
end
stageFolder.DescendantAdded:Connect(hookPart)

-- Client requests full restart (stage start)
RE_Restart.OnServerEvent:Connect(function(player: Player)
	resetRun(player, true)
	local char = player.Character
	if char then
		local humanoid = char:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.Health <= 0 then
			player:LoadCharacter()
			return
		end
	end
	teleportTo(player, getStartCFrame())
	toast(player, "Run restarted", "info")
	pushStats(player)
end)

print("[ObbyServer] Ready —", ObbyConfig.GameName)
