-- Soft offline aura drip while away. Capped so it never replaces playing.

local OfflineEarnings = {}

local RATE_PER_HOUR = 12
local MAX_HOURS = 8
local MIN_SECONDS = 5 * 60

function OfflineEarnings.Collect(profile: any): { aura: number, seconds: number, label: string }?
	if typeof(profile) ~= "table" then
		return nil
	end
	local last = profile.lastLogoutAt or profile.lastSeen
	if typeof(last) ~= "number" then
		profile.lastSeen = os.time()
		return nil
	end
	local dt = os.time() - last
	if dt < MIN_SECONDS then
		profile.lastSeen = os.time()
		return nil
	end
	local hours = math.min(dt / 3600, MAX_HOURS)
	local aura = math.floor(hours * RATE_PER_HOUR)
	if aura < 1 then
		profile.lastSeen = os.time()
		return nil
	end
	profile.lastSeen = os.time()
	local label
	if hours >= 1 then
		label = string.format("%.1fh away", hours)
	else
		label = string.format("%dm away", math.floor(dt / 60))
	end
	return {
		aura = aura,
		seconds = dt,
		label = label,
	}
end

function OfflineEarnings.Touch(profile: any)
	if typeof(profile) == "table" then
		profile.lastSeen = os.time()
	end
end

return OfflineEarnings
