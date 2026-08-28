-- OrderedDataStore best-time board (tides LeaderboardService pattern, simplified).

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local ObbyConfig = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("ObbyConfig"))

local OrderedStats = {}

local store: OrderedDataStore? = nil
local ready = false
local cache: { { userId: number, name: string, time: number } } = {}
local lastFetch = 0

function OrderedStats.Init()
	if not ObbyConfig.DataStoreEnabled then
		return
	end
	local ok, result = pcall(function()
		return DataStoreService:GetOrderedDataStore(ObbyConfig.OrderedBestTimeName or "AuraFarm_BestTime_v1")
	end)
	if ok and result then
		store = result
		ready = true
		print("[OrderedStats] OrderedDataStore ready")
	else
		warn("[OrderedStats] unavailable:", result)
	end
end

-- Lower time is better → store inverted score so higher ranks first.
local function scoreFromTime(sec: number): number
	-- millisecond precision, inverted
	return math.floor((100000 - sec) * 1000)
end

local function timeFromScore(score: number): number
	return (100000 - score / 1000)
end

function OrderedStats.Submit(player: Player, bestTime: number)
	if not ready or not store or player.UserId <= 0 then
		return
	end
	if typeof(bestTime) ~= "number" or bestTime <= 0 then
		return
	end
	local score = scoreFromTime(bestTime)
	task.spawn(function()
		pcall(function()
			store:SetAsync(tostring(player.UserId), score)
		end)
	end)
end

function OrderedStats.GetTop(limit: number?): {
	{
		userId: number,
		name: string,
		time: number,
	}
}
	limit = limit or 10
	local now = os.clock()
	if now - lastFetch < 15 and #cache > 0 then
		return cache
	end
	if not ready or not store then
		return cache
	end

	local ok, pages = pcall(function()
		return store:GetSortedAsync(false, limit)
	end)
	if not ok or not pages then
		return cache
	end

	local page = pages:GetCurrentPage()
	local rows = {}
	for _, entry in page do
		local userId = tonumber(entry.key) or 0
		local t = timeFromScore(entry.value)
		local name = "Player"
		local p = Players:GetPlayerByUserId(userId)
		if p then
			name = p.DisplayName
		else
			local okn, n = pcall(function()
				return Players:GetNameFromUserIdAsync(userId)
			end)
			if okn and n then
				name = n
			end
		end
		table.insert(rows, { userId = userId, name = name, time = t })
	end
	cache = rows
	lastFetch = now
	return rows
end

return OrderedStats
