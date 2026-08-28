-- UTC date helpers for dailies / streaks.

local TimeUtil = {}

function TimeUtil.UtcNow(): number
	return os.time()
end

function TimeUtil.UtcYmd(ts: number?): string
	local t = ts or os.time()
	-- os.date with ! = UTC
	return os.date("!%Y-%m-%d", t) :: string
end

function TimeUtil.UtcDayIndex(ts: number?): number
	local t = ts or os.time()
	return math.floor(t / 86400)
end

function TimeUtil.FormatCompact(seconds: number): string
	seconds = math.max(0, math.floor(seconds))
	if seconds < 60 then
		return string.format("%ds", seconds)
	elseif seconds < 3600 then
		return string.format("%dm", math.floor(seconds / 60))
	elseif seconds < 86400 then
		local h = math.floor(seconds / 3600)
		local m = math.floor((seconds % 3600) / 60)
		return string.format("%dh %dm", h, m)
	else
		local d = math.floor(seconds / 86400)
		local h = math.floor((seconds % 86400) / 3600)
		return string.format("%dd %dh", d, h)
	end
end

function TimeUtil.HoursBetween(a: number, b: number): number
	return math.abs(b - a) / 3600
end

return TimeUtil
