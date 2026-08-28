-- Number / time display helpers (gear-clicker FormatUtil vibe).

local FormatUtil = {}

function FormatUtil.Comma(n: number): string
	n = math.floor(n)
	local sign = ""
	if n < 0 then
		sign = "-"
		n = -n
	end
	local s = tostring(n)
	local out = s:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
	return sign .. out
end

function FormatUtil.Compact(n: number): string
	local abs = math.abs(n)
	local sign = n < 0 and "-" or ""
	if abs < 1000 then
		return sign .. tostring(math.floor(abs))
	elseif abs < 1e6 then
		return sign .. string.format("%.1fK", abs / 1e3)
	elseif abs < 1e9 then
		return sign .. string.format("%.1fM", abs / 1e6)
	end
	return sign .. string.format("%.1fB", abs / 1e9)
end

function FormatUtil.Time(sec: number): string
	sec = math.max(0, sec)
	local m = math.floor(sec / 60)
	local s = sec % 60
	return string.format("%d:%05.2f", m, s)
end

return FormatUtil
