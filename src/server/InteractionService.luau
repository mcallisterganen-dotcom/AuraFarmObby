-- Lobby + world interactables: spin wheel, daily claim, fountain, emote pads, tip boards.
-- ProximityPrompt-driven so it feels like a finished Roblox lobby.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ObbyConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ObbyConfig"))
local AuraTheme = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("AuraTheme"))
local RNG = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RNG"))
local StageConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("StageConfig"))

local InteractionService = {}

export type Deps = {
	PlayerData: any,
	toast: (Player, string, string?) -> (),
	sfx: (Player, string) -> (),
	pushStats: (Player) -> (),
	grantAura: (Player, number, string?) -> (),
	grantCoins: (Player, number) -> (),
	onKill: (Player) -> (),
	enterStage: (Player, number, any?) -> (),
	Remotes: any,
}

local deps: Deps
local rootFolder: Folder?

local function part(props: { [string]: any }): BasePart
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = props.CanCollide == true
	p.Material = props.Material or Enum.Material.SmoothPlastic
	p.Color = props.Color or AuraTheme.Colors.Path
	p.Size = props.Size or Vector3.new(4, 1, 4)
	p.CFrame = props.CFrame or CFrame.new(props.Position or Vector3.zero)
	p.Name = props.Name or "Interact"
	p.Transparency = props.Transparency or 0
	p.CastShadow = props.CastShadow ~= false
	if props.Shape then
		p.Shape = props.Shape
	end
	p.Parent = props.Parent
	if props.IsPath then
		p:SetAttribute("IsPath", true)
		p.CanCollide = true
	end
	return p
end

local function billboard(parent: BasePart, text: string, color: Color3?, height: number?)
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(180, 48)
	bb.StudsOffset = Vector3.new(0, height or 4, 0)
	bb.AlwaysOnTop = true
	bb.Parent = parent
	local tl = Instance.new("TextLabel")
	tl.Size = UDim2.fromScale(1, 1)
	tl.BackgroundTransparency = 1
	tl.Font = Enum.Font.GothamBold
	tl.TextSize = 18
	tl.TextColor3 = color or Color3.new(1, 1, 1)
	tl.TextStrokeTransparency = 0.4
	tl.Text = text
	tl.Parent = bb
	return bb
end

local function prompt(parent: BasePart, action: string, object: string, hold: number?): ProximityPrompt
	local pp = Instance.new("ProximityPrompt")
	pp.ActionText = action
	pp.ObjectText = object
	pp.HoldDuration = hold or 0
	pp.MaxActivationDistance = 12
	pp.RequiresLineOfSight = false
	pp.Parent = parent
	return pp
end

local function dayKey(): string
	return os.date("!%Y-%m-%d")
end

function InteractionService.Init(d: Deps)
	deps = d
end

function InteractionService.Build(parent: Instance): Folder
	if rootFolder then
		rootFolder:Destroy()
	end
	rootFolder = Instance.new("Folder")
	rootFolder.Name = "AuraFarmInteract"
	rootFolder.Parent = parent

	local spawn = StageConfig.LobbySpawn

	-- ===== Lobby plaza floor (PATH) =====
	part({
		Name = "LobbyFloor",
		Parent = rootFolder,
		Size = Vector3.new(70, 2.2, 70),
		Position = spawn + Vector3.new(0, -1.1, 0),
		Color = Color3.fromRGB(28, 24, 42),
		Material = Enum.Material.Slate,
		IsPath = true,
		CanCollide = true,
	})
	-- Soft center ring
	part({
		Name = "LobbyRing",
		Parent = rootFolder,
		Size = Vector3.new(24, 0.4, 24),
		Position = spawn + Vector3.new(0, 0.2, 0),
		Color = AuraTheme.Colors.Accent,
		Material = Enum.Material.SmoothPlastic,
		CanCollide = false,
		Transparency = 0.55,
	})

	-- ===== Spin Wheel =====
	local wheelBase = part({
		Name = "SpinWheelBase",
		Parent = rootFolder,
		Size = Vector3.new(8, 1.5, 8),
		Position = spawn + Vector3.new(-22, 0.75, 8),
		Color = Color3.fromRGB(40, 30, 60),
		IsPath = true,
		CanCollide = true,
	})
	local wheel = part({
		Name = "SpinWheel",
		Parent = rootFolder,
		Size = Vector3.new(10, 0.6, 10),
		Position = spawn + Vector3.new(-22, 3.2, 8),
		Color = AuraTheme.Colors.AccentHot,
		Material = Enum.Material.SmoothPlastic,
		Shape = Enum.PartType.Cylinder,
		CanCollide = false,
	})
	wheel.CFrame = CFrame.new(wheel.Position) * CFrame.Angles(0, 0, math.rad(90))
	billboard(wheelBase, "AURA WHEEL", AuraTheme.Colors.Gold, 6)
	local wheelPrompt = prompt(wheelBase, "Spin", "Daily Wheel", 0.4)
	wheelPrompt.Triggered:Connect(function(player)
		InteractionService.OnSpin(player, wheel)
	end)

	-- ===== Daily chest =====
	local chest = part({
		Name = "DailyChest",
		Parent = rootFolder,
		Size = Vector3.new(5, 4, 5),
		Position = spawn + Vector3.new(22, 2, 8),
		Color = AuraTheme.Colors.Gold,
		Material = Enum.Material.SmoothPlastic,
		IsPath = true,
		CanCollide = true,
	})
	billboard(chest, "DAILY CHEST", AuraTheme.Colors.Gold, 5)
	local chestPrompt = prompt(chest, "Claim", "Daily Reward", 0.5)
	chestPrompt.Triggered:Connect(function(player)
		InteractionService.OnDaily(player)
	end)

	-- ===== Aura fountain (heal combo / small drip) =====
	local fountain = part({
		Name = "AuraFountain",
		Parent = rootFolder,
		Size = Vector3.new(10, 1.2, 10),
		Position = spawn + Vector3.new(0, 0.6, -18),
		Color = Color3.fromRGB(50, 40, 90),
		IsPath = true,
		CanCollide = true,
	})
	local spout = part({
		Name = "FountainSpout",
		Parent = rootFolder,
		Size = Vector3.new(2, 6, 2),
		Position = spawn + Vector3.new(0, 4, -18),
		Color = AuraTheme.Colors.Accent,
		Material = Enum.Material.Neon,
		CanCollide = false,
		Transparency = 0.35,
	})
	local pe = Instance.new("ParticleEmitter")
	pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	pe.Rate = 28
	pe.Lifetime = NumberRange.new(0.6, 1.2)
	pe.Speed = NumberRange.new(2, 6)
	pe.SpreadAngle = Vector2.new(30, 30)
	pe.Color = ColorSequence.new(AuraTheme.Colors.Accent, AuraTheme.Colors.AccentHot)
	pe.Size = NumberSequence.new(0.4, 0)
	pe.Parent = spout
	billboard(fountain, "AURA FOUNTAIN", AuraTheme.Colors.Accent, 5)
	local fPrompt = prompt(fountain, "Bathe", "Aura Fountain", 0.3)
	fPrompt.Triggered:Connect(function(player)
		InteractionService.OnFountain(player)
	end)

	-- ===== Emote pads =====
	local emotes = { "Wave", "Dance", "Cheer", "Laugh" }
	for i, name in emotes do
		local ang = ((i - 1) / #emotes) * math.pi * 2
		local pos = spawn + Vector3.new(math.cos(ang) * 16, 0.4, math.sin(ang) * 16 + 4)
		local pad = part({
			Name = "EmotePad_" .. name,
			Parent = rootFolder,
			Size = Vector3.new(6, 0.8, 6),
			Position = pos,
			Color = Color3.fromRGB(60, 45, 95),
			IsPath = true,
			CanCollide = true,
		})
		pad:SetAttribute("EmoteName", name)
		billboard(pad, name:upper(), Color3.fromRGB(255, 255, 255), 3)
		local pp = prompt(pad, "Play", name, 0)
		pp.Triggered:Connect(function(player)
			InteractionService.OnEmotePad(player, name)
		end)
	end

	-- ===== Tip boards =====
	local tips = {
		{ "SHIFT", "Sprint for flow" },
		{ "C", "Slide under pressure" },
		{ "ORBS", "Touch orbs = aura" },
		{ "FALL", "Void = checkpoint" },
		{ "B", "Shop trails" },
		{ "Q", "Daily quests" },
	}
	for i, tip in tips do
		local x = -20 + (i - 1) * 8
		local board = part({
			Name = "TipBoard" .. i,
			Parent = rootFolder,
			Size = Vector3.new(6, 5, 0.6),
			Position = spawn + Vector3.new(x, 3.5, 28),
			Color = Color3.fromRGB(35, 28, 55),
			CanCollide = false,
		})
		billboard(board, tip[1] .. " — " .. tip[2], Color3.fromRGB(200, 190, 255), 0.5)
	end

	-- ===== Practice bounce =====
	local bounce = part({
		Name = "LobbyBounce",
		Parent = rootFolder,
		Size = Vector3.new(8, 1.4, 8),
		Position = spawn + Vector3.new(0, 0.7, 22),
		Color = Color3.fromRGB(255, 140, 70),
		IsPath = true,
		CanCollide = true,
	})
	bounce:SetAttribute(ObbyConfig.BounceTag, 75)
	bounce:SetAttribute("BouncePower", 75)
	billboard(bounce, "BOUNCE", Color3.fromRGB(255, 180, 100), 3)

	-- ===== Stage launch pads with prompts =====
	for _, def in StageConfig.Stages do
		local x = -18 + (def.id - 1) * 18
		local launch = part({
			Name = "LaunchStage" .. def.id,
			Parent = rootFolder,
			Size = Vector3.new(12, 1.6, 12),
			Position = spawn + Vector3.new(x, 0.8, -30),
			Color = def.pathColor,
			IsPath = true,
			CanCollide = true,
		})
		launch:SetAttribute("PortalToStage", def.id)
		billboard(launch, string.format("STAGE %d\n%s", def.id, def.name), def.accentColor, 5)
		local pp = prompt(launch, "Enter", def.name, 0.25)
		pp.Triggered:Connect(function(player)
			if deps and deps.enterStage then
				deps.enterStage(player, def.id)
			end
		end)
	end

	print("[InteractionService] Lobby interactables ready")
	return rootFolder
end

function InteractionService.OnSpin(player: Player, wheel: BasePart?)
	if not deps then
		return
	end
	local profile = deps.PlayerData.Get(player)
	if not profile then
		return
	end
	profile.meta = profile.meta or {}
	local key = "spin_" .. dayKey()
	if profile.meta[key] then
		deps.toast(player, "Wheel already spun today — come back tomorrow!", "warn")
		deps.sfx(player, "Error")
		return
	end
	profile.meta[key] = true
	deps.PlayerData.MarkDirty(player)

	-- Visual spin
	if wheel then
		local base = wheel.CFrame
		local spin = 360 * 3 + math.random(0, 180)
		local tw = TweenService:Create(wheel, TweenInfo.new(1.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			CFrame = base * CFrame.Angles(math.rad(spin), 0, 0),
		})
		tw:Play()
	end

	local roll = RNG.WeightedTablePick({
		AuraSmall = 40,
		AuraMed = 25,
		AuraBig = 12,
		Coins = 15,
		Jackpot = 5,
		Nothing = 3,
	}) or "AuraSmall"

	if roll == "AuraSmall" then
		deps.grantAura(player, 15, "wheel")
		deps.toast(player, "Wheel: +15 Aura", "aura")
	elseif roll == "AuraMed" then
		deps.grantAura(player, 40, "wheel")
		deps.toast(player, "Wheel: +40 Aura!", "aura")
	elseif roll == "AuraBig" then
		deps.grantAura(player, 90, "wheel")
		deps.toast(player, "Wheel: +90 Aura!!", "good")
	elseif roll == "Coins" then
		deps.grantCoins(player, 25)
		deps.toast(player, "Wheel: +25 Coins", "good")
	elseif roll == "Jackpot" then
		deps.grantAura(player, 200, "wheel")
		deps.grantCoins(player, 50)
		deps.toast(player, "JACKPOT! +200 Aura +50 Coins", "good")
	else
		deps.toast(player, "Wheel: better luck next time", "info")
	end
	deps.sfx(player, "Lucky")
	deps.pushStats(player)
end

function InteractionService.OnDaily(player: Player)
	if not deps then
		return
	end
	local profile = deps.PlayerData.Get(player)
	if not profile then
		return
	end
	profile.meta = profile.meta or {}
	local key = "daily_" .. dayKey()
	if profile.meta[key] then
		deps.toast(player, "Daily already claimed!", "warn")
		deps.sfx(player, "Error")
		return
	end
	profile.meta[key] = true
	local streak = (profile.meta.dailyStreak or 0) + 1
	-- reset streak if missed yesterday? keep simple: always +1 when claim
	profile.meta.dailyStreak = streak
	deps.PlayerData.MarkDirty(player)

	local aura = 30 + math.min(streak, 14) * 5
	local coins = 10 + math.min(streak, 14) * 2
	deps.grantAura(player, aura, "daily")
	deps.grantCoins(player, coins)
	deps.toast(player, string.format("Daily day %d: +%d Aura · +%d Coins", streak, aura, coins), "good")
	deps.sfx(player, "Achievement")
	deps.pushStats(player)
end

function InteractionService.OnFountain(player: Player)
	if not deps then
		return
	end
	local profile = deps.PlayerData.Get(player)
	if not profile then
		return
	end
	profile.meta = profile.meta or {}
	local now = os.time()
	local last = profile.meta.fountainAt or 0
	if now - last < 45 then
		deps.toast(player, string.format("Fountain cooling… %ds", 45 - (now - last)), "info")
		return
	end
	profile.meta.fountainAt = now
	deps.PlayerData.MarkDirty(player)
	deps.grantAura(player, 8, "fountain")
	deps.toast(player, "Fountain blessing +8 Aura", "aura")
	deps.sfx(player, "Orb")
	deps.pushStats(player)

	-- soft heal invuln / feel
	local char = player.Character
	if char then
		local hum = char:FindFirstChildOfClass("Humanoid")
		if hum then
			hum.Health = math.min(hum.MaxHealth, hum.Health + 25)
		end
	end
end

function InteractionService.OnEmotePad(player: Player, emoteName: string)
	if not deps then
		return
	end
	deps.toast(player, "Emote: " .. emoteName, "info")
	deps.sfx(player, "Whoosh")
	-- Client listens to Toast / can also use a remote; fire a lightweight attribute
	player:SetAttribute("PlayEmote", emoteName)
	task.delay(0.1, function()
		if player.Parent then
			player:SetAttribute("PlayEmote", nil)
		end
	end)
end

return InteractionService
