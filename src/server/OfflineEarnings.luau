-- Soft offline aura drip while away (gear-clicker EarningsService idea).
-- Caps so it never replaces actually playing.

local ObbyConfig = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("ObbyConfig"))
local TimeUtil = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("TimeUtil"))

local OfflineEarnings = {}

function OfflineEarnings.Collect(profile): { aura: number, coins: number, seconds: number }?
	local last = profile.lastSeenAt
	profile.lastSeenAt = os.time()
	if type(last) ~= "number" then
		return nil
	end
	local elapsed = os.time() - last
	local minSec = ObbyConfig.OfflineMinSec or 120
	local maxSec = ObbyConfig.OfflineMaxSec or (6 * 3600)
	if elapsed < minSec then
		return nil
	end
	local counted = math.min(elapsed, maxSec)
	-- Rate scales lightly with lifetime finishes (progress feel)
	local finishes = profile.totalFinishes or 0
	local auraPerHour = (ObbyConfig.OfflineAuraPerHour or 12) + math.min(20, finishes)
	local coinPerHour = (ObbyConfig.OfflineCoinsPerHour or 4) + math.min(8, math.floor(finishes / 2))
	local hours = counted / 3600
	local aura = math.floor(auraPerHour * hours)
	local coins = math.floor(coinPerHour * hours)
	if aura <= 0 and coins <= 0 then
		return nil
	end
	profile.aura = (profile.aura or 0) + aura
	profile.coins = (profile.coins or 0) + coins
	return {
		aura = aura,
		coins = coins,
		seconds = counted,
		label = TimeUtil.FormatCompact(counted),
	}
end

function OfflineEarnings.Touch(profile)
	profile.lastSeenAt = os.time()
end

return OfflineEarnings
