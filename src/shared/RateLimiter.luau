-- Sliding-window rate limiter (tides-of-trade RateLimiter).

local RateLimiter = {}
RateLimiter.__index = RateLimiter

export type RateLimiter = typeof(setmetatable(
	{} :: {
		_limit: number,
		_windowSec: number,
		_windows: { [string]: { number } },
	},
	RateLimiter
))

function RateLimiter.new(limit: number, windowSec: number): RateLimiter
	return setmetatable({
		_limit = math.max(1, limit),
		_windowSec = math.max(0.05, windowSec),
		_windows = {},
	}, RateLimiter)
end

function RateLimiter.Allow(self: RateLimiter, key: string): boolean
	local now = os.clock()
	local bucket = self._windows[key]
	if not bucket then
		bucket = {}
		self._windows[key] = bucket
	end
	local cutoff = now - self._windowSec
	local kept = {}
	for _, t in bucket do
		if t >= cutoff then
			table.insert(kept, t)
		end
	end
	if #kept >= self._limit then
		self._windows[key] = kept
		return false
	end
	table.insert(kept, now)
	self._windows[key] = kept
	return true
end

function RateLimiter.Reset(self: RateLimiter, key: string)
	self._windows[key] = nil
end

function RateLimiter.Clear(self: RateLimiter)
	self._windows = {}
end

return RateLimiter
