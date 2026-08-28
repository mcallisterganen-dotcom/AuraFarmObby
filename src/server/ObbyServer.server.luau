-- Aura Farm Obby — server: stage, checkpoints, kills, orbs, finish, cosmetics, data

print("[ObbyServer] Starting")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ObbyConfig = require(Shared:WaitForChild("ObbyConfig"))
local CosmeticsCatalog = require(Shared:WaitForChild("CosmeticsCatalog"))
local Achievements = require(Shared:WaitForChild("Achievements"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local RNG = require(Shared:WaitForChild("RNG"))

local StageBuilder = require(script.Parent:WaitForChild("StageBuilder"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))
local TrailService = require(script.Parent:WaitForChild("TrailService"))

Remotes.InitServer()
PlayerData.Init()

local remoteFolder = ReplicatedStorage:WaitForChild("ObbyRemotes")
local Toast = remoteFolder:WaitForChild("Toast") :: RemoteEvent
local AuraUpdate = remoteFolder:WaitForChild("AuraUpdate") :: RemoteEvent
local StatsUpdate = remoteFolder:WaitForChild("StatsUpdate") :: RemoteEvent
local FinishEv = remoteFolder:WaitForChild("Finish") :: RemoteEvent
local RestartRequest = remoteFolder:WaitForChild("RestartRequest") :: RemoteEvent
local BuyCosmetic = remoteFolder:WaitForChild("BuyCosmetic") :: RemoteEvent
local EquipCosmetic = remoteFolder:WaitForChild("EquipCosmetic") :: RemoteEvent
local CosmeticResult = remoteFolder:WaitForChild("CosmeticResult") :: RemoteEvent
local AchievementUnlocked = remoteFolder:WaitForChild("AchievementUnlocked") :: RemoteEvent

-- Session run state (not persisted)
type RunState = {
	checkpointIndex: number,
	checkpointCF: CFrame?,
	runStartClock: number,
	finished: boolean,
	collectedOrbs: { [string]: boolean },
	combo: number,
	comboExpire: number,
	lastKill: number,
	lastRestart: number,
}

local runs: { [number]: RunState } = {}

local function toast(player: Player, text: string, kind: string?)
	Toast:FireClient(player, text, kind or "info")
end

local function ensureLeaderstats(player: Player, profile)
	local ls = player:FindFirstChild("leaderstats")
	if not ls then
		ls = Instance.new("Folder")
		ls.Name = "leaderstats"
		ls.Parent = player
	end
	local function stat(name: string, value: number)
		local v = ls:FindFirstChild(name)
		if not v then
			v = Instance.new("IntValue")
			v.Name = name
			v.Parent = ls
		end
		(v :: IntValue).Value = math.floor(value)
	end
	stat("Aura", profile.aura)
	stat("Coins", profile.coins)
	stat("Finishes", profile.totalFinishes)
end

local function pushStats(player: Player)
	local profile = PlayerData.Get(player)
	if not profile then
		return
	end
	ensureLeaderstats(player, profile)
	local snap = PlayerData.Snapshot(player)
	if snap then
		local run = runs[player.UserId]
		snap.checkpointIndex = run and run.checkpointIndex or 0
		snap.runTime = run and (os.clock() - run.runStartClock) or 0
		snap.finished = run and run.finished or false
		snap.combo = run and run.combo or 0
		StatsUpdate:FireClient(player, snap)
		AuraUpdate:FireClient(player, profile.aura, profile.coins)
	end
end

local function newRun(): RunState
	return {
		checkpointIndex = 0,
		checkpointCF = nil,
		runStartClock = os.clock(),
		finished = false,
		collectedOrbs = {},
		combo = 0,
		comboExpire = 0,
		lastKill = 0,
		lastRestart = 0,
	}
end

local function getSpawnCF(run: RunState): CFrame
	if run.checkpointCF then
		return run.checkpointCF + Vector3.new(0, 3, 0)
	end
	local stage = workspace:FindFirstChild(ObbyConfig.StageFolderName)
	if stage then
		local sp = stage:FindFirstChild(ObbyConfig.StartSpawnName, true)
		if sp and sp:IsA("BasePart") then
			return sp.CFrame + Vector3.new(0, 3, 0)
		end
	end
	return ObbyConfig.StartCFrame
end

local function teleportTo(player: Player, cf: CFrame)
	local char = player.Character
	if not char then
		return
	end
	local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum then
		hum.Health = hum.MaxHealth
	end
	if hrp then
		hrp.AssemblyLinearVelocity = Vector3.zero
		hrp.AssemblyAngularVelocity = Vector3.zero
		hrp.CFrame = cf
	end
end

local function applyTrail(player: Player)
	local profile = PlayerData.Get(player)
	local char = player.Character
	if profile and char then
		TrailService.Apply(char, profile.equippedTrail)
	end
end

local function checkAchievements(player: Player)
	local profile = PlayerData.Get(player)
	if not profile then
		return
	end

	local function trailsOwned(): number
		local n = 0
		for _, t in CosmeticsCatalog.All() do
			if profile.unlocked[t.id] then
				n += 1
			end
		end
		return n
	end

	local function statValue(stat: string): number
		if stat == "finish_count" then
			return profile.totalFinishes
		elseif stat == "orb_count" then
			return profile.totalOrbs
		elseif stat == "death_count" then
			return profile.totalDeaths
		elseif stat == "best_time_under" then
			return profile.bestTime or math.huge
		elseif stat == "aura_total" then
			return profile.aura
		elseif stat == "coins_total" then
			return profile.coins
		elseif stat == "trails_owned" then
			return trailsOwned()
		end
		return 0
	end

	for _, def in Achievements.List do
		if profile.achievements[def.id] then
			continue
		end
		local val = statValue(def.stat)
		local ok = false
		if def.stat == "best_time_under" then
			ok = profile.bestTime ~= nil and profile.bestTime <= def.target
		else
			ok = val >= def.target
		end
		if ok then
			profile.achievements[def.id] = true
			profile.aura += def.rewardAura
			profile.coins += def.rewardCoins
			PlayerData.MarkDirty(player)
			AchievementUnlocked:FireClient(player, {
				id = def.id,
				name = def.name,
				description = def.description,
				rewardAura = def.rewardAura,
				rewardCoins = def.rewardCoins,
			})
			toast(
				player,
				string.format("Achievement: %s (+%d aura)", def.name, def.rewardAura),
				"good"
			)
		end
	end
end

local function onKill(player: Player)
	local run = runs[player.UserId]
	local profile = PlayerData.Get(player)
	if not run or not profile or run.finished then
		return
	end
	local now = os.clock()
	if now - run.lastKill < ObbyConfig.KillDebounceSec then
		return
	end
	run.lastKill = now
	run.combo = 0
	profile.totalDeaths += 1
	PlayerData.MarkDirty(player)
	checkAchievements(player)
	pushStats(player)
	toast(player, "Ouch — back to checkpoint", "bad")
	teleportTo(player, getSpawnCF(run))
end

local function bindCharacter(player: Player, char: Model)
	local run = runs[player.UserId]
	if not run then
		return
	end

	task.defer(function()
		task.wait(0.1)
		if player.Character == char then
			teleportTo(player, getSpawnCF(run))
			applyTrail(player)
		end
	end)

	local hum = char:WaitForChild("Humanoid", 10) :: Humanoid?
	if hum then
		hum.Died:Connect(function()
			onKill(player)
			-- brief respawn handled by Roblox; we re-teleport on character
		end)
	end

	-- Fall void check
	task.spawn(function()
		while player.Character == char do
			local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
			if hrp and hrp.Position.Y < ObbyConfig.FallY then
				onKill(player)
			end
			task.wait(0.2)
		end
	end)
end

local function wireStageParts(stage: Instance)
	for _, part in stage:GetDescendants() do
		if not part:IsA("BasePart") then
			continue
		end
		local tag = part:GetAttribute("Tag")
		if tag == ObbyConfig.CheckpointTag then
			local idx = tonumber(part:GetAttribute("Index")) or 0
			part.Touched:Connect(function(hit)
				local char = hit:FindFirstAncestorOfClass("Model")
				if not char then
					return
				end
				local player = Players:GetPlayerFromCharacter(char)
				if not player then
					return
				end
				local run = runs[player.UserId]
				local profile = PlayerData.Get(player)
				if not run or not profile or run.finished then
					return
				end
				if idx > run.checkpointIndex then
					run.checkpointIndex = idx
					run.checkpointCF = part.CFrame
					profile.coins += ObbyConfig.CheckpointCoinBonus
					PlayerData.MarkDirty(player)
					pushStats(player)
					toast(player, string.format("Checkpoint %d", idx), "good")
				end
			end)
		elseif tag == ObbyConfig.KillTag then
			part.Touched:Connect(function(hit)
				local char = hit:FindFirstAncestorOfClass("Model")
				if not char then
					return
				end
				local player = Players:GetPlayerFromCharacter(char)
				if player then
					onKill(player)
				end
			end)
		elseif tag == ObbyConfig.OrbTag then
			local orbId = part:GetAttribute("OrbId") or part:GetFullName()
			part.Touched:Connect(function(hit)
				local char = hit:FindFirstAncestorOfClass("Model")
				if not char then
					return
				end
				local player = Players:GetPlayerFromCharacter(char)
				if not player then
					return
				end
				local run = runs[player.UserId]
				local profile = PlayerData.Get(player)
				if not run or not profile or run.finished then
					return
				end
				if run.collectedOrbs[orbId] then
					return
				end
				run.collectedOrbs[orbId] = true

				local now = os.clock()
				if now <= run.comboExpire then
					run.combo += 1
				else
					run.combo = 1
				end
				run.comboExpire = now + ObbyConfig.ComboWindowSec

				local comboBonus = math.max(0, (run.combo - 1) * ObbyConfig.ComboBonusPerStep)
				local mult, tier = RNG.OrbMultiplier()
				local gain = (ObbyConfig.OrbAuraValue + comboBonus) * mult
				profile.aura += gain
				profile.coins += ObbyConfig.OrbCoinValue * (mult > 1 and mult or 1)
				profile.totalOrbs += 1
				PlayerData.MarkDirty(player)

				-- Hide orb for this session visually for all (simple)
				part.Transparency = 1
				part.CanTouch = false
				local light = part:FindFirstChildWhichIsA("PointLight")
				if light then
					light.Enabled = false
				end

				checkAchievements(player)
				pushStats(player)
				local bits = { string.format("+%d Aura", gain) }
				if run.combo > 1 then
					table.insert(bits, string.format("x%d combo", run.combo))
				end
				if mult > 1 then
					table.insert(bits, tier .. " x" .. tostring(mult))
				end
				toast(player, table.concat(bits, " · "), "aura")
			end)
		elseif tag == ObbyConfig.FinishTag then
			part.Touched:Connect(function(hit)
				local char = hit:FindFirstAncestorOfClass("Model")
				if not char then
					return
				end
				local player = Players:GetPlayerFromCharacter(char)
				if not player then
					return
				end
				local run = runs[player.UserId]
				local profile = PlayerData.Get(player)
				if not run or not profile or run.finished then
					return
				end
				run.finished = true
				local elapsed = os.clock() - run.runStartClock
				profile.totalFinishes += 1
				profile.aura += ObbyConfig.FinishAuraBonus
				profile.coins += ObbyConfig.FinishCoinBonus
				local isBest = false
				if profile.bestTime == nil or elapsed < profile.bestTime then
					profile.bestTime = elapsed
					isBest = true
				end
				PlayerData.MarkDirty(player)
				checkAchievements(player)
				pushStats(player)
				FinishEv:FireClient(player, {
					time = elapsed,
					bestTime = profile.bestTime,
					isBest = isBest,
					aura = profile.aura,
					coins = profile.coins,
					bonusAura = ObbyConfig.FinishAuraBonus,
					bonusCoins = ObbyConfig.FinishCoinBonus,
				})
				toast(
					player,
					string.format(
						"Stage clear! %.2fs%s",
						elapsed,
						isBest and " — NEW BEST" or ""
					),
					"good"
				)
				PlayerData.Save(player)
			end)
		end
	end
end

-- Build stage
local stageFolder = StageBuilder.Build()
wireStageParts(stageFolder)
print("[ObbyServer] Stage wired")

-- Player lifecycle
local function onPlayer(player: Player)
	local profile = PlayerData.Load(player)
	runs[player.UserId] = newRun()
	ensureLeaderstats(player, profile)
	pushStats(player)
	toast(player, "Welcome to " .. ObbyConfig.GameName, "info")

	player.CharacterAdded:Connect(function(char)
		bindCharacter(player, char)
	end)
	if player.Character then
		bindCharacter(player, player.Character)
	end
end

Players.PlayerAdded:Connect(onPlayer)
for _, p in Players:GetPlayers() do
	task.spawn(onPlayer, p)
end

Players.PlayerRemoving:Connect(function(player)
	PlayerData.Release(player)
	runs[player.UserId] = nil
end)

game:BindToClose(function()
	for _, player in Players:GetPlayers() do
		PlayerData.Save(player)
	end
	task.wait(2)
end)

-- Restart run (from finish panel or button)
RestartRequest.OnServerEvent:Connect(function(player)
	local run = runs[player.UserId]
	if not run then
		return
	end
	local now = os.clock()
	if now - run.lastRestart < ObbyConfig.RestartCooldownSec then
		return
	end
	run.lastRestart = now

	-- Reset run progress but keep meta profile
	local fresh = newRun()
	fresh.lastRestart = now
	runs[player.UserId] = fresh

	-- Restore orbs visibility for everyone is heavy; rebuild stage orbs only
	-- Simple approach: re-enable orbs that this player needs on a personal flag —
	-- for solo, restore all orbs in stage.
	local stage = workspace:FindFirstChild(ObbyConfig.StageFolderName)
	if stage then
		for _, part in stage:GetDescendants() do
			if part:IsA("BasePart") and part:GetAttribute("Tag") == ObbyConfig.OrbTag then
				part.Transparency = part:GetAttribute("BaseTransparency") or 0.15
				part.CanTouch = true
				local light = part:FindFirstChildWhichIsA("PointLight")
				if light then
					light.Enabled = true
				end
			end
		end
	end

	pushStats(player)
	toast(player, "Run reset — go!", "info")
	if player.Character then
		teleportTo(player, getSpawnCF(fresh))
		applyTrail(player)
	else
		player:LoadCharacter()
	end
end)

BuyCosmetic.OnServerEvent:Connect(function(player, trailId)
	if type(trailId) ~= "string" then
		return
	end
	local profile = PlayerData.Get(player)
	local def = CosmeticsCatalog.GetTrail(trailId)
	if not profile or not def then
		CosmeticResult:FireClient(player, false, "Unknown trail")
		return
	end
	if profile.unlocked[trailId] then
		CosmeticResult:FireClient(player, false, "Already owned")
		return
	end
	if def.priceAura <= 0 then
		profile.unlocked[trailId] = true
	elseif profile.aura < def.priceAura then
		CosmeticResult:FireClient(player, false, "Not enough Aura")
		toast(player, "Need more Aura", "warn")
		return
	else
		profile.aura -= def.priceAura
		profile.unlocked[trailId] = true
	end
	PlayerData.MarkDirty(player)
	checkAchievements(player)
	pushStats(player)
	CosmeticResult:FireClient(player, true, "Purchased " .. def.name)
	toast(player, "Unlocked " .. def.name, "good")
	PlayerData.Save(player)
end)

EquipCosmetic.OnServerEvent:Connect(function(player, trailId)
	if type(trailId) ~= "string" then
		return
	end
	local profile = PlayerData.Get(player)
	local def = CosmeticsCatalog.GetTrail(trailId)
	if not profile or not def then
		return
	end
	if not profile.unlocked[trailId] then
		toast(player, "You don't own that", "warn")
		return
	end
	profile.equippedTrail = trailId
	PlayerData.MarkDirty(player)
	applyTrail(player)
	pushStats(player)
	toast(player, "Equipped " .. def.name, "info")
end)

print("[ObbyServer] Ready —", ObbyConfig.GameName, "v" .. ObbyConfig.Version)
