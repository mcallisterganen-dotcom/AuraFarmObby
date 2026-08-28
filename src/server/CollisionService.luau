-- Registers collision groups so players ONLY stand on designated path parts.
-- Decor/terrain never blocks or catches the player.

local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WorldRules = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("WorldRules"))
local ObbyConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("ObbyConfig"))

local CollisionService = {}

local G = WorldRules.Groups
local registered = false

local function ensureGroup(name: string)
	pcall(function()
		PhysicsService:RegisterCollisionGroup(name)
	end)
end

local function setCollidable(a: string, b: string, on: boolean)
	pcall(function()
		PhysicsService:CollisionGroupSetCollidable(a, b, on)
	end)
end

function CollisionService.Init()
	if registered then
		return
	end
	registered = true

	ensureGroup(G.Player)
	ensureGroup(G.Path)
	ensureGroup(G.Kill)
	ensureGroup(G.Decor)
	ensureGroup(G.Orb)
	ensureGroup(G.Ghost)

	-- Default: nothing collides with Player except Path + Kill
	local all = { G.Player, G.Path, G.Kill, G.Decor, G.Orb, G.Ghost }
	for _, a in all do
		for _, b in all do
			setCollidable(a, b, false)
		end
	end

	-- Players stand on path
	setCollidable(G.Player, G.Path, true)
	-- Players die on kill volumes
	setCollidable(G.Player, G.Kill, true)
	-- Path self / kill self ok
	setCollidable(G.Path, G.Path, true)
	setCollidable(G.Kill, G.Kill, true)

	-- Orbs/ghost never solid
	setCollidable(G.Orb, G.Player, false)
	setCollidable(G.Ghost, G.Player, false)
	setCollidable(G.Decor, G.Player, false)

	-- Critical: ignore Default group so any unclassified part cannot be climbed
	setCollidable(G.Player, "Default", false)

	print("[CollisionService] Path-only groups ready")
end

function CollisionService.SetPartGroup(part: BasePart, group: string)
	pcall(function()
		part.CollisionGroup = group
	end)
end

function CollisionService.ClassifyPart(part: BasePart)
	local name = part.Name
	-- Kill always wins
	if part:GetAttribute(ObbyConfig.KillTag) == true or part:GetAttribute("Kill") == true or string.find(name, "Kill", 1, true) then
		part.CanCollide = true
		part.CanTouch = true
		CollisionService.SetPartGroup(part, G.Kill)
		return G.Kill
	end
	-- Orbs
	if part:GetAttribute(ObbyConfig.OrbTag) == true or name == "AuraOrb" or string.find(name, "Orb", 1, true) then
		part.CanCollide = false
		part.CanTouch = true
		CollisionService.SetPartGroup(part, G.Orb)
		return G.Orb
	end
	-- Explicit path attribute
	if part:GetAttribute("IsPath") == true then
		part.CanCollide = true
		CollisionService.SetPartGroup(part, G.Path)
		return G.Path
	end
	-- Name heuristics for path
	if WorldRules.IsPathName(name) then
		-- Edge/rim/glow/beacon never path
		if string.find(name, "Edge", 1, true)
			or string.find(name, "Ring", 1, true)
			or string.find(name, "Glow", 1, true)
			or string.find(name, "Beacon", 1, true)
			or string.find(name, "Arch", 1, true)
			or string.find(name, "Light", 1, true)
			or string.find(name, "Guide", 1, true)
		then
			part.CanCollide = false
			CollisionService.SetPartGroup(part, G.Ghost)
			return G.Ghost
		end
		part.CanCollide = true
		part:SetAttribute("IsPath", true)
		CollisionService.SetPartGroup(part, G.Path)
		return G.Path
	end
	-- Everything else = decor (terrain, shells, crystals…)
	part.CanCollide = false
	CollisionService.SetPartGroup(part, G.Decor)
	return G.Decor
end

function CollisionService.ClassifyTree(root: Instance)
	for _, d in root:GetDescendants() do
		if d:IsA("BasePart") then
			CollisionService.ClassifyPart(d)
		end
	end
end

function CollisionService.BindCharacter(char: Model)
	local function apply(inst: Instance)
		if inst:IsA("BasePart") then
			CollisionService.SetPartGroup(inst, G.Player)
		end
	end
	for _, d in char:GetDescendants() do
		apply(d)
	end
	char.DescendantAdded:Connect(apply)
end

function CollisionService.WatchPlayers()
	local function onChar(char: Model)
		CollisionService.BindCharacter(char)
	end
	local function onPlayer(player: Player)
		if player.Character then
			onChar(player.Character)
		end
		player.CharacterAdded:Connect(onChar)
	end
	for _, p in Players:GetPlayers() do
		onPlayer(p)
	end
	Players.PlayerAdded:Connect(onPlayer)
end

return CollisionService
