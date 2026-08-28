-- UTC date helpers (tides-of-trade TimeUtil) — dailies / streaks.

local TimeUtil = {}

function TimeUtil.UtcNow(): number
	return os.time()
end

function TimeUtil.UtcYmd(ts: number?): string
	local t = ts or os.time()
	return os.date("!%Y-%m-%d", t) :: string
end

function TimeUtil.IsSameUtcDay(a: number, b: number): boolean
	return TimeUtil.UtcYmd(a) == TimeUtil.UtcYmd(b)
end

-- Returns true if `previous` was yesterday UTC relative to `now`.
function TimeUtil.IsPreviousUtcDay(previous: number, now: number): boolean
	local yest = now - 86400
	return TimeUtil.UtcYmd(previous) == TimeUtil.UtcYmd(yest)
end

function TimeUtil.SecondsUntilNextUtcMidnight(now: number?): number
	local t = now or os.time()
	local d = os.date("!*t", t)
	local secsToday = (d.hour :: number) * 3600 + (d.min :: number) * 60 + (d.sec :: number)
	return 86400 - secsToday
end

function TimeUtil.FormatDuration(sec: number): string
	sec = math.max(0, sec)
	local m = math.floor(sec / 60)
	local s = sec % 60
	if m >= 60 then
		local h = math.floor(m / 60)
		m = m % 60
		return string.format("%d:%02d:%05.2f", h, m, s)
	end
	return string.format("%d:%05.2f", m, s)
end

function TimeUtil.FormatCompact(sec: number): string
	sec = math.floor(math.max(0, sec))
	if sec < 60 then
		return tostring(sec) .. "s"
	elseif sec < 3600 then
		return string.format("%dm %ds", math.floor(sec / 60), sec % 60)
	elseif sec < 86400 then
		return string.format("%dh %dm", math.floor(sec / 3600), math.floor((sec % 3600) / 60))
	end
	return string.format("%dd %dh", math.floor(sec / 86400), math.floor((sec % 86400) / 3600))
end

return TimeUtil
