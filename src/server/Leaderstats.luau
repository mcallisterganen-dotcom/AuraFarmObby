-- Classic Roblox leaderboard values (Aura, Best, Finishes).
-- Server-owned NumberValues; never trust the client.

local Leaderstats = {}

local function ensureFolder(player: Player): Folder
	local f = player:FindFirstChild("leaderstats")
	if f and f:IsA("Folder") then
		return f
	end
	if f then
		f:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = "leaderstats"
	folder.Parent = player
	return folder
end

local function ensureValue(folder: Folder, name: string, className: string): Instance
	local v = folder:FindFirstChild(name)
	if v and v.ClassName == className then
		return v
	end
	if v then
		v:Destroy()
	end
	local n = Instance.new(className)
	n.Name = name
	n.Parent = folder
	return n
end

function Leaderstats.Setup(player: Player)
	local folder = ensureFolder(player)
	ensureValue(folder, "Aura", "IntValue")
	ensureValue(folder, "Best", "NumberValue") -- seconds; 0 = none
	ensureValue(folder, "Clears", "IntValue")
end

function Leaderstats.Update(player: Player, profile: {
	aura: number,
	bestTime: number?,
	totalFinishes: number,
})
	local folder = player:FindFirstChild("leaderstats")
	if not folder then
		Leaderstats.Setup(player)
		folder = player:FindFirstChild("leaderstats")
	end
	if not folder then
		return
	end

	local aura = folder:FindFirstChild("Aura")
	if aura and aura:IsA("IntValue") then
		aura.Value = math.floor(profile.aura or 0)
	end

	local best = folder:FindFirstChild("Best")
	if best and best:IsA("NumberValue") then
		best.Value = profile.bestTime or 0
	end

	local clears = folder:FindFirstChild("Clears")
	if clears and clears:IsA("IntValue") then
		clears.Value = math.floor(profile.totalFinishes or 0)
	end
end

return Leaderstats
