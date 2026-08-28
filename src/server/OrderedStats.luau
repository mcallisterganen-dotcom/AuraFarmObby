-- OrderedDataStore best-time board.

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local OrderedStats = {}

local STORE_NAME = "AuraFarmBestTimes_v1"
local ordered: OrderedDataStore? = nil
local cache: { { name: string, userId: number, time: number } } = {}
local cacheAt = 0

function OrderedStats.Init()
	pcall(function()
		ordered = DataStoreService:GetOrderedDataStore(STORE_NAME)
	end)
	print("[OrderedStats] Ready", ordered ~= nil)
end

-- Lower time is better. Store as score = large - centiseconds so higher Ordered score = faster.
local SCORE_BASE = 100000000

function OrderedStats.Submit(player: Player, timeSec: number)
	if not ordered or timeSec <= 0 then
		return
	end
	local cs = math.floor(timeSec * 100 + 0.5)
	local score = SCORE_BASE - cs
	if score < 1 then
		score = 1
	end
	local key = tostring(player.UserId)
	pcall(function()
		ordered:UpdateAsync(key, function(old)
			if typeof(old) == "number" and old >= score then
				return old -- already better (higher score = faster)
			end
			return score
		end)
	end)
	cacheAt = 0 -- invalidate
end

function OrderedStats.GetTop(n: number): { { name: string, userId: number, time: number } }
	n = math.clamp(n or 10, 1, 50)
	if os.clock() - cacheAt < 15 and #cache > 0 then
		local out = {}
		for i = 1, math.min(n, #cache) do
			out[i] = cache[i]
		end
		return out
	end
	local rows = {}
	if ordered then
		local ok, pages = pcall(function()
			return ordered:GetSortedAsync(false, n) -- false = descending score = faster times first
		end)
		if ok and pages then
			local page = pages:GetCurrentPage()
			for _, entry in page do
				local userId = tonumber(entry.key) or 0
				local score = entry.value
				local cs = SCORE_BASE - score
				local timeSec = cs / 100
				local name = "Player"
				local plr = Players:GetPlayerByUserId(userId)
				if plr then
					name = plr.DisplayName
				else
					pcall(function()
						name = Players:GetNameFromUserIdAsync(userId)
					end)
				end
				table.insert(rows, {
					name = name,
					userId = userId,
					time = timeSec,
				})
			end
		end
	end
	cache = rows
	cacheAt = os.clock()
	return rows
end

return OrderedStats
