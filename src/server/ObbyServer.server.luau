-- Aura Farm Obby — server hub (multi-stage)
-- Data, trails, quests, weather, ordered best-times, offline earnings,
-- rate limits, lucky orbs, achievements, cosmetics, stage select/portals.

print("[ObbyServer] Starting")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ObbyConfig = require(Shared:WaitForChild("ObbyConfig"))
local StageConfig = require(Shared:WaitForChild("StageConfig"))
local CosmeticsCatalog = require(Shared:WaitForChild("CosmeticsCatalog"))
local Achievements = require(Shared:WaitForChild("Achievements"))
local Remotes = require(Shared:WaitForChild("Remotes"))
local RNG = require(Shared:WaitForChild("RNG"))
local RateLimiter = require(Shared:WaitForChild("RateLimiter"))

local StageBuilder = require(script.Parent:WaitForChild("StageBuilder"))
local TerrainGenerator = require(script.Parent:WaitForChild("TerrainGenerator"))
local StageStreamer = require(script.Parent:WaitForChild("StageStreamer"))
local CollisionService = require(script.Parent:WaitForChild("CollisionService"))
local InteractionService = require(script.Parent:WaitForChild("InteractionService"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))
local TrailService = require(script.Parent:WaitForChild("TrailService"))
local QuestService = require(script.Parent:WaitForChild("QuestService"))
local WeatherService = require(script.Parent:WaitForChild("WeatherService"))
local OrderedStats = require(script.Parent:WaitForChild("OrderedStats"))
local OfflineEarnings = require(script.Parent:WaitForChild("OfflineEarnings"))
local AuraTheme = require(Shared:WaitForChild("AuraTheme"))
local WorldRules = require(Shared:WaitForChild("WorldRules"))

Remotes.InitServer()
PlayerData.Init()
OrderedStats.Init()

AuraTheme.ApplyLighting(Lighting)
AuraTheme.EnsurePostFx(Lighting)

local remoteFolder = ReplicatedStorage:WaitForChild("ObbyRemotes")
local function R(name: string): RemoteEvent
	return remoteFolder:WaitForChild(name) :: RemoteEvent
end

local Toast = R("Toast")
local AuraUpdate = R("AuraUpdate")
local StatsUpdate = R("StatsUpdate")
local FinishEv = R("Finish")
local RestartRequest = R("RestartRequest")
local BuyCosmetic = R("BuyCosmetic")
local EquipCosmetic = R("EquipCosmetic")
local CosmeticResult = R("CosmeticResult")
local AchievementUnlocked = R("AchievementUnlocked")
local QuestUpdate = R("QuestUpdate")
local ClaimQuest = R("ClaimQuest")
local QuestResult = R("QuestResult")
local WeatherUpdate = R("WeatherUpdate")
local LeaderboardUpdate = R("LeaderboardUpdate")
local RequestLeaderboard = R("RequestLeaderboard")
local OfflineReward = R("OfflineReward")
local SettingsUpdate = R("SettingsUpdate")
local TutorialState = R("TutorialState")
local TutorialComplete = R("TutorialComplete")
local PlaySound = R("PlaySound")
local StageUpdate = R("StageUpdate")

local restartLimiter = RateLimiter.new(3, 4)
local shopLimiter = RateLimiter.new(8, 3)
local claimLimiter = RateLimiter.new(6, 3)
local stageLimiter = RateLimiter.new(4, 3)

type RunState = {
	stageId: number,
	checkpointIndex: number,
	checkpointCF: CFrame?,
	runStartClock: number,
	finished: boolean,
	collectedOrbs: { [string]: boolean },
	combo: number,
	comboExpire: number,
	lastKill: number,
	lastRestart: number,
	sessionStart: number,
	playMinuteAcc: number,
	invulnUntil: number,
}

local runs: { [number]: RunState } = {}
local stagesRoot: Folder? = nil

local function grantAura(player: Player, amount: number, _src: string?)
	local profile = PlayerData.Get(player)
	if not profile or amount == 0 then
		return
	end
	profile.aura += math.floor(amount)
	PlayerData.MarkDirty(player)
	AuraUpdate:FireClient(player, profile.aura, profile.coins)
end

local function grantCoins(player: Player, amount: number)
	local profile = PlayerData.Get(player)
	if not profile or amount == 0 then
		return
	end
	profile.coins += math.floor(amount)
	PlayerData.MarkDirty(player)
	AuraUpdate:FireClient(player, profile.aura, profile.coins)
end


local function toast(player: Player, text: string, kind: string?)
	Toast:FireClient(player, text, kind or "info")
end

local function sfx(player: Player, name: string)
	PlaySound:FireClient(player, name)
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
	stat("Streak", profile.loginStreak or 0)
	local bestCs = 0
	if profile.bestTime and profile.bestTime > 0 then
		bestCs = math.floor(profile.bestTime * 100 + 0.5)
	end
	stat("BestCs", bestCs)
	stat("Stage", profile.currentStage or 1)
end

local function pushQuests(player: Player)
	local profile = PlayerData.Get(player)
	if not profile then
		return
	end
	QuestUpdate:FireClient(player, QuestService.Snapshot(profile))
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
		snap.stageId = run and run.stageId or (profile.currentStage or 1)
		local def = StageConfig.Get(snap.stageId)
		snap.stageName = def and def.name or ("Stage " .. tostring(snap.stageId))
		snap.weatherLabel = WeatherService.GetMood().label
		snap.weatherMult = WeatherService.GetAuraMultiplier()
		StatsUpdate:FireClient(player, snap)
		AuraUpdate:FireClient(player, profile.aura, profile.coins)
		StageUpdate:FireClient(player, {
			stageId = snap.stageId,
			stageName = snap.stageName,
			stagesCleared = snap.stagesCleared,
			bestTimes = snap.bestTimes,
		})
	end
end

local function newRun(stageId: number): RunState
	return {
		stageId = stageId,
		checkpointIndex = 0,
		checkpointCF = nil,
		runStartClock = os.clock(),
		finished = false,
		collectedOrbs = {},
		combo = 0,
		comboExpire = 0,
		lastKill = 0,
		lastRestart = 0,
		sessionStart = os.clock(),
		playMinuteAcc = 0,
		invulnUntil = 0,
	}
end

local function stageFolder(stageId: number): Instance?
	local root = stagesRoot or workspace:FindFirstChild(ObbyConfig.StageFolderName)
	if not root then
		return nil
	end
	return root:FindFirstChild(StageConfig.FolderName(stageId))
end

local function getStageSpawnCF(stageId: number): CFrame
	local folder = stageFolder(stageId)
	if folder then
		local sp = folder:FindFirstChild("StartSpawn")
		if sp and sp:IsA("BasePart") then
			return sp.CFrame + Vector3.new(0, 3, 0)
		end
		local def = StageConfig.Get(stageId)
		if def then
			return CFrame.new(def.originX, def.baseY + 5, 28)
		end
	end
	return ObbyConfig.StartCFrame or CFrame.new(0, 16, 28)
end

local function getSpawnCF(run: RunState): CFrame
	if run.checkpointCF then
		return run.checkpointCF + Vector3.new(0, 3, 0)
	end
	return getStageSpawnCF(run.stageId)
end

local function applyStageLighting(stageId: number)
	local def = StageConfig.Get(stageId)
	if not def then
		return
	end
	pcall(function()
		Lighting.ClockTime = def.clockTime
		Lighting.FogColor = def.fogColor
		Lighting.FogStart = 40
		Lighting.FogEnd = 220
		Lighting.Ambient = Color3.fromRGB(70, 50, 110)
	end)
end

local function teleportTo(player: Player, cf: CFrame)
	local char = player.Character
	if not char then
		return
	end
	local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
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

local function canEnterStage(profile, stageId: number): (boolean, string?)
	local def = StageConfig.Get(stageId)
	if not def then
		return false, "Unknown stage"
	end
	if not PlayerData.IsStageUnlocked(profile, stageId, def.requiresStage) then
		local req = def.requiresStage or (stageId - 1)
		local reqDef = StageConfig.Get(req)
		local name = reqDef and reqDef.name or ("Stage " .. tostring(req))
		return false, "Clear " .. name .. " first"
	end
	return true, nil
end

local function enterStage(player: Player, stageId: number, opts: { silent: boolean? }?)
	local profile = PlayerData.Get(player)
	if not profile then
		return
	end
	local ok, err = canEnterStage(profile, stageId)
	if not ok then
		toast(player, err or "Locked", "warn")
		sfx(player, "Error")
		return
	end
	profile.currentStage = stageId
	PlayerData.MarkDirty(player)
	local run = newRun(stageId)
	run.invulnUntil = os.clock() + (ObbyConfig.RespawnInvulnSec or 1.5)
	runs[player.UserId] = run
	applyStageLighting(stageId)
	StageStreamer.Focus(player, stageId)
	if player.Character then
		teleportTo(player, getSpawnCF(run))
		applyTrail(player)
	end
	pushStats(player)
	if not (opts and opts.silent) then
		local def = StageConfig.Get(stageId)
		toast(player, string.format("Stage %d — %s", stageId, def and def.name or ""), "info")
		sfx(player, "Whoosh")
	end
end

local function checkAchievements(player: Player)
	local profile = PlayerData.Get(player)
	if not profile then
		return
	end
	if type(profile.achievements) ~= "table" then
		profile.achievements = {}
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

	local function stagesClearedCount(): number
		local n = 0
		for _ in profile.stagesCleared do
			n += 1
		end
		return n
	end

	local function statValue(stat: string): number
		if stat == "finishes" then
			return profile.totalFinishes
		elseif stat == "orbs" then
			return profile.totalOrbs
		elseif stat == "death_count" or stat == "deaths" then
			return profile.totalDeaths
		elseif stat == "best_time" then
			return profile.bestTime or 0
		elseif stat == "trails" then
			return trailsOwned()
		elseif stat == "streak" then
			return profile.loginStreak or 0
		elseif stat == "stages" then
			return stagesClearedCount()
		elseif stat == "aura" then
			return profile.aura
		end
		return profile.stats[stat] or 0
	end

	for _, def in Achievements.List do
		if profile.achievements[def.id] then
			continue
		end
		local val = statValue(def.stat)
		local ok = false
		if def.stat == "best_time" then
			ok = val > 0 and val <= (def.threshold or 0)
		else
			ok = val >= (def.threshold or 0)
		end
		if ok then
			profile.achievements[def.id] = true
			profile.aura += def.rewardAura or 0
			profile.coins += def.rewardCoins or 0
			PlayerData.MarkDirty(player)
			AchievementUnlocked:FireClient(player, {
				id = def.id,
				name = def.name,
				description = def.description,
				rewardAura = def.rewardAura,
				rewardCoins = def.rewardCoins,
			})
			sfx(player, "Achievement")
			toast(player, string.format("Achievement: %s", def.name), "good")
		end
	end
end

local function onKill(player: Player)
	local run = runs[player.UserId]
	local profile = PlayerData.Get(player)
	if not profile then
		return
	end
	if not run then
		local char = player.Character
		if char then
			local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
			if hrp then
				hrp.CFrame = CFrame.new(StageConfig.LobbySpawn + Vector3.new(0, 4, 0))
				hrp.AssemblyLinearVelocity = Vector3.zero
			end
		end
		return
	end
	local now = os.clock()
	if now < (run.invulnUntil or 0) then
		return
	end
	if now - run.lastKill < (ObbyConfig.KillDebounceSec or 1.25) then
		return
	end
	run.lastKill = now
	run.invulnUntil = now + (ObbyConfig.RespawnInvulnSec or 1.5)
	profile.totalDeaths += 1
	profile.stats.kills = (profile.stats.kills or 0) + 1
	PlayerData.MarkDirty(player)
	QuestService.Record(profile, "deaths", 1)
	teleportTo(player, getSpawnCF(run))
	sfx(player, "Death")
	toast(player, "Checkpoint restore", "warn")
	pushStats(player)
	checkAchievements(player)
end

local function wireCharacter(player: Player, char: Model)
	local hum = char:WaitForChild("Humanoid", 10) :: Humanoid?
	if hum then
		hum.Died:Connect(function()
			onKill(player)
		end)
	end

	-- Fall death watchdog (void part + height) so falling always kills
	task.spawn(function()
		while player.Character == char do
			local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
			if hrp then
				local run = runs[player.UserId]
				local floorY = WorldRules.AbsoluteKillY
				if run then
					local def = StageConfig.Get(run.stageId)
					if def then
						floorY = math.min(floorY, def.baseY - WorldRules.FallMarginStuds)
					end
				end
				if hrp.Position.Y < floorY or hrp.Position.Y < WorldRules.AbsoluteKillY then
					onKill(player)
				end
			end
			task.wait(0.12)
		end
	end)

	applyTrail(player)
	local run = runs[player.UserId]
	if run then
		task.defer(function()
			if player.Character == char then
				teleportTo(player, getSpawnCF(run))
				run.invulnUntil = os.clock() + (ObbyConfig.RespawnInvulnSec or 1.5)
			end
		end)
	end
end

local function partStageId(part: BasePart): number?
	local inst: Instance? = part
	while inst do
		local id = inst:GetAttribute("StageId")
		if typeof(id) == "number" then
			return id
		end
		if inst.Name:match("^Stage%d+$") then
			return tonumber(inst.Name:match("%d+"))
		end
		inst = inst.Parent
	end
	return nil
end

local function wireStageParts(root: Instance)
	for _, part in root:GetDescendants() do
		if not part:IsA("BasePart") then
			continue
		end

		-- Checkpoints
		local cp = part:GetAttribute(ObbyConfig.CheckpointTag)
		if typeof(cp) == "number" then
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
				if not run or run.finished then
					return
				end
				local sid = partStageId(part)
				if sid ~= nil and sid ~= run.stageId then
					return
				end
				if cp > run.checkpointIndex then
					run.checkpointIndex = cp
					run.checkpointCF = part.CFrame
					sfx(player, "Checkpoint")
					toast(player, "Checkpoint " .. tostring(cp), "info")
					pushStats(player)
					local profile = PlayerData.Get(player)
					if profile then
						QuestService.Record(profile, "checkpoints", 1)
					end
				end
			end)
		end

		-- Kill (void + bricks)
		if part:GetAttribute(ObbyConfig.KillTag) == true or part.Name:find("Kill") then
			part.CanTouch = true
			if part.Name == "WorldVoidKill" then
				part.CanCollide = true
			end
			part.Touched:Connect(function(hit)
				if not hit or not hit.Parent then
					return
				end
				local char = hit:FindFirstAncestorOfClass("Model")
				if not char then
					return
				end
				local plr = Players:GetPlayerFromCharacter(char)
				if plr then
					onKill(plr)
				end
			end)
		end

		-- Orbs
		if part:GetAttribute(ObbyConfig.OrbTag) == true then
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
				local sid = partStageId(part)
				if sid ~= nil and sid ~= run.stageId then
					return
				end
				if run.collectedOrbs[orbId] then
					return
				end
				run.collectedOrbs[orbId] = true
				-- Per-player collect only (orbs stay for other players)

				local base = part:GetAttribute("Aura")
				if typeof(base) ~= "number" then
					local def = StageConfig.Get(run.stageId)
					base = (def and def.orbAura) or ObbyConfig.OrbAura or 2
				end
				local mult = WeatherService.GetAuraMultiplier()
				local lucky = false
				if RNG.Chance and RNG.Chance(ObbyConfig.LuckyOrbChance or 0.08) then
					mult *= (ObbyConfig.LuckyOrbMult or 3)
					lucky = true
				elseif math.random() < (ObbyConfig.LuckyOrbChance or 0.08) then
					mult *= (ObbyConfig.LuckyOrbMult or 3)
					lucky = true
				end

				local now = os.clock()
				if now <= run.comboExpire then
					run.combo += 1
				else
					run.combo = 1
				end
				run.comboExpire = now + (ObbyConfig.ComboWindowSec or 4)
				local comboBonus = math.max(0, run.combo - 1) * (ObbyConfig.ComboAuraBonus or 1)
				local gain = math.floor(base * mult + comboBonus)

				profile.aura += gain
				profile.totalOrbs += 1
				profile.stats.orbs = (profile.stats.orbs or 0) + 1
				PlayerData.MarkDirty(player)
				QuestService.Record(profile, "orbs", 1)

				part.Transparency = 1
				part.CanTouch = false
				local light = part:FindFirstChildWhichIsA("PointLight")
				if light then
					light.Enabled = false
				end

				checkAchievements(player)
				pushStats(player)
				sfx(player, if lucky then "Lucky" else "Orb")
				local bits = { string.format("+%d Aura", gain) }
				if lucky then
					table.insert(bits, "LUCKY")
				end
				if run.combo > 1 then
					table.insert(bits, string.format("x%d combo", run.combo))
				end
				local mood = WeatherService.GetMood()
				if mood and mood.label then
					table.insert(bits, mood.label)
				end
				toast(player, table.concat(bits, " · "), "aura")
			end)
		end

		-- Finish
		if part:GetAttribute(ObbyConfig.FinishTag) == true then
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
				local sid = partStageId(part) or run.stageId
				if sid ~= run.stageId then
					return
				end

				local hrp = char:FindFirstChild("HumanoidRootPart")
				if not hrp or not hrp:IsA("BasePart") then
					return
				end
				local dist = (hrp.Position - part.Position).Magnitude
				if dist > (ObbyConfig.MaxFinishDistance or 18) then
					warn("[ObbyServer] Finish rejected (distance)", player.Name, dist)
					return
				end

				local elapsed = os.clock() - run.runStartClock
				local def = StageConfig.Get(run.stageId)
				local minT = (def and def.minFinishTimeSec) or ObbyConfig.MinFinishTimeSec or 10
				if elapsed < minT then
					toast(player, "Finish too fast — try a fair run", "warn")
					return
				end
				local minCp = (def and def.minCheckpointForFinish) or ObbyConfig.MinCheckpointForFinish or 1
				if run.checkpointIndex < minCp then
					toast(player, "Hit more checkpoints first", "warn")
					return
				end

				run.finished = true
				profile.totalFinishes += 1
				profile.stats.finishes = (profile.stats.finishes or 0) + 1
				profile.stagesCleared[tostring(run.stageId)] = true

				local clearAura = (def and def.clearAura) or ObbyConfig.FinishAuraBonus or 25
				local clearCoins = (def and def.clearCoins) or ObbyConfig.FinishCoinBonus or 10
				local wmult = WeatherService.GetAuraMultiplier()
				local auraGain = math.floor(clearAura * wmult)
				profile.aura += auraGain
				profile.coins += clearCoins

				local key = tostring(run.stageId)
				local prev = profile.bestTimes[key]
				local isBest = false
				if not prev or elapsed < prev then
					profile.bestTimes[key] = elapsed
					isBest = true
				end
				if not profile.bestTime or elapsed < profile.bestTime then
					profile.bestTime = elapsed
				end

				PlayerData.MarkDirty(player)
				QuestService.Record(profile, "finishes", 1)
				OrderedStats.Submit(player, elapsed)
				checkAchievements(player)
				pushStats(player)
				pushQuests(player)

				FinishEv:FireClient(player, {
					time = elapsed,
					best = isBest,
					aura = auraGain,
					coins = clearCoins,
					stageId = run.stageId,
					stageName = def and def.name or ("Stage " .. run.stageId),
					nextStage = run.stageId + 1,
					nextUnlocked = PlayerData.IsStageUnlocked(profile, run.stageId + 1, run.stageId),
				})
				sfx(player, "Finish")
				local msg = string.format(
					"Stage %d clear! %.2fs · +%d Aura · +%d Coins",
					run.stageId,
					elapsed,
					auraGain,
					clearCoins
				)
				if isBest then
					msg ..= " · PERSONAL BEST"
				end
				toast(player, msg, "good")
				PlayerData.Save(player)
			end)
		end

		-- Bounce
		local bounce = part:GetAttribute(ObbyConfig.BounceTag)
		if typeof(bounce) == "number" then
			part.Touched:Connect(function(hit)
				local char = hit:FindFirstAncestorOfClass("Model")
				if not char then
					return
				end
				local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
				if hrp then
					hrp.AssemblyLinearVelocity = Vector3.new(
						hrp.AssemblyLinearVelocity.X,
						bounce,
						hrp.AssemblyLinearVelocity.Z
					)
				end
			end)
		end

		-- Portal to next stage
		local portalTo = part:GetAttribute(ObbyConfig.PortalTag)
		if typeof(portalTo) == "number" then
			part.Touched:Connect(function(hit)
				local char = hit:FindFirstAncestorOfClass("Model")
				if not char then
					return
				end
				local player = Players:GetPlayerFromCharacter(char)
				if not player then
					return
				end
				if not stageLimiter:Allow("portal_" .. player.UserId) then
					return
				end
				enterStage(player, portalTo)
			end)
		end

		-- Lobby stage select
		local selectId = part:GetAttribute(ObbyConfig.SelectStageTag)
		if typeof(selectId) == "number" then
			part.Touched:Connect(function(hit)
				local char = hit:FindFirstAncestorOfClass("Model")
				if not char then
					return
				end
				local player = Players:GetPlayerFromCharacter(char)
				if not player then
					return
				end
				if not stageLimiter:Allow("sel_" .. player.UserId) then
					return
				end
				enterStage(player, selectId)
			end)
		end
	end
end

-- Build world
CollisionService.Init()
CollisionService.WatchPlayers()

stagesRoot = StageBuilder.BuildAll()
local terrain = TerrainGenerator.new()
local terrainRoot = terrain:Generate(stagesRoot)

InteractionService.Init({
	PlayerData = PlayerData,
	toast = toast,
	sfx = sfx,
	pushStats = pushStats,
	grantAura = grantAura,
	grantCoins = grantCoins,
	onKill = onKill,
	enterStage = enterStage,
	Remotes = Remotes,
})
local interactRoot = InteractionService.Build(workspace)

CollisionService.ClassifyTree(stagesRoot)
CollisionService.ClassifyTree(terrainRoot)
CollisionService.ClassifyTree(interactRoot)

wireStageParts(stagesRoot)
wireStageParts(terrainRoot)
wireStageParts(interactRoot)

StageStreamer.Init(stagesRoot, terrainRoot)
StageStreamer.RebuildVisibility()
print("[ObbyServer] Multi-stage aura world ready (path-only + interact)")

WeatherService.Start(function(mood)
	WeatherUpdate:FireAllClients({
		id = mood.id,
		label = mood.label,
		mult = mood.auraMult or mood.mult or 1,
	})
end)

local function onPlayer(player: Player)
	local profile = PlayerData.Load(player)
	QuestService.Ensure(profile)
	local stageId = profile.currentStage or 1
	if not StageConfig.Get(stageId) then
		stageId = 1
	end
	-- if locked somehow, fall back
	local ok = canEnterStage(profile, stageId)
	if not ok then
		stageId = 1
	end
	runs[player.UserId] = newRun(stageId)
	profile.currentStage = stageId
	applyStageLighting(stageId)
	StageStreamer.Focus(player, stageId)

	local offline = OfflineEarnings.Collect(profile)
	if offline and offline.aura and offline.aura > 0 then
		profile.aura += offline.aura
		PlayerData.MarkDirty(player)
		OfflineReward:FireClient(player, offline)
		toast(player, string.format("Welcome back · +%d offline Aura", offline.aura), "aura")
	end

	ensureLeaderstats(player, profile)
	pushStats(player)
	pushQuests(player)
	TutorialState:FireClient(player, profile.tutorialDone == true)
	checkAchievements(player)

	player.CharacterAdded:Connect(function(char)
		wireCharacter(player, char)
	end)
	if player.Character then
		wireCharacter(player, player.Character)
	end

	local mood = WeatherService.GetMood()
	WeatherUpdate:FireClient(player, {
		id = mood.id,
		label = mood.label,
		mult = mood.auraMult or mood.mult or 1,
	})

	toast(player, "Aura Farm Obby v" .. ObbyConfig.Version .. " · 3 stages", "info")
	toast(player, "R restart · B shop · Q quests · T times · P settings", "aura")
end

for _, player in Players:GetPlayers() do
	task.spawn(onPlayer, player)
end
Players.PlayerAdded:Connect(onPlayer)

Players.PlayerRemoving:Connect(function(player)
	runs[player.UserId] = nil
	StageStreamer.ClearPlayer(player)
end)

-- Playtime tick for daily quest
task.spawn(function()
	while true do
		task.wait(30)
		for _, player in Players:GetPlayers() do
			local run = runs[player.UserId]
			local profile = PlayerData.Get(player)
			if run and profile then
				run.playMinuteAcc += 0.5
				if run.playMinuteAcc >= 1 then
					local mins = math.floor(run.playMinuteAcc)
					run.playMinuteAcc -= mins
					profile.stats.playMinutes = (profile.stats.playMinutes or 0) + mins
					QuestService.Record(profile, "playMinutes", mins)
					PlayerData.MarkDirty(player)
					pushQuests(player)
				end
			end
		end
	end
end)

RestartRequest.OnServerEvent:Connect(function(player)
	if not restartLimiter:Allow("r_" .. player.UserId) then
		return
	end
	local run = runs[player.UserId]
	if not run then
		return
	end
	local now = os.clock()
	if now - run.lastRestart < 1 then
		return
	end
	run.lastRestart = now
	local stageId = run.stageId
	local fresh = newRun(stageId)
	fresh.sessionStart = run.sessionStart
	fresh.playMinuteAcc = run.playMinuteAcc
	runs[player.UserId] = fresh
	-- respawn collected orbs on this stage
	local folder = stageFolder(stageId)
	if folder then
		for _, d in folder:GetDescendants() do
			if d:IsA("BasePart") and d:GetAttribute(ObbyConfig.OrbTag) == true then
				d.Transparency = 0
				d.CanTouch = true
				local light = d:FindFirstChildWhichIsA("PointLight")
				if light then
					light.Enabled = true
				end
			end
		end
	end
	pushStats(player)
	sfx(player, "Whoosh")
	toast(player, "Run reset — go!", "info")
	if player.Character then
		teleportTo(player, getSpawnCF(fresh))
		applyTrail(player)
	end
end)

BuyCosmetic.OnServerEvent:Connect(function(player, trailId)
	if not shopLimiter:Allow("buy_" .. player.UserId) then
		return
	end
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
	sfx(player, "Purchase")
	CosmeticResult:FireClient(player, true, "Purchased " .. def.name)
	toast(player, "Unlocked " .. def.name, "good")
	PlayerData.Save(player)
end)

EquipCosmetic.OnServerEvent:Connect(function(player, trailId)
	if not shopLimiter:Allow("eq_" .. player.UserId) then
		return
	end
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
	sfx(player, "Equip")
	toast(player, "Equipped " .. def.name, "info")
end)

ClaimQuest.OnServerEvent:Connect(function(player, questId)
	if not claimLimiter:Allow("cq_" .. player.UserId) then
		return
	end
	if type(questId) ~= "string" then
		return
	end
	local profile = PlayerData.Get(player)
	if not profile then
		return
	end
	local ok, msg, a, c = QuestService.TryClaim(profile, questId)
	if ok then
		PlayerData.MarkDirty(player)
		pushStats(player)
		pushQuests(player)
		sfx(player, "Purchase")
		QuestResult:FireClient(player, true, msg, a, c)
		toast(player, msg .. string.format(" (+%d Aura)", a or 0), "good")
		PlayerData.Save(player)
	else
		QuestResult:FireClient(player, false, msg)
		toast(player, tostring(msg), "warn")
	end
end)

RequestLeaderboard.OnServerEvent:Connect(function(player)
	if not shopLimiter:Allow("lb_" .. player.UserId) then
		return
	end
	local rows = OrderedStats.GetTop(10)
	LeaderboardUpdate:FireClient(player, rows)
end)

SettingsUpdate.OnServerEvent:Connect(function(player, settings)
	if type(settings) ~= "table" then
		return
	end
	local profile = PlayerData.Get(player)
	if not profile then
		return
	end
	if type(profile.settings) ~= "table" then
		profile.settings = {}
	end
	if settings.music ~= nil then
		profile.settings.music = settings.music == true
	end
	if settings.sfx ~= nil then
		profile.settings.sfx = settings.sfx == true
	end
	if settings.reduceFx ~= nil then
		profile.settings.reduceFx = settings.reduceFx == true
	end
	PlayerData.MarkDirty(player)
	pushStats(player)
end)

TutorialComplete.OnServerEvent:Connect(function(player)
	local profile = PlayerData.Get(player)
	if not profile then
		return
	end
	profile.tutorialDone = true
	PlayerData.MarkDirty(player)
	toast(player, "Tutorial done — good luck!", "good")
end)

game:BindToClose(function()
	print("[ObbyServer] BindToClose — saving all")
	PlayerData.SaveAll()
	task.wait(2)
end)

print("[ObbyServer] Ready —", ObbyConfig.GameName, "v" .. ObbyConfig.Version)
