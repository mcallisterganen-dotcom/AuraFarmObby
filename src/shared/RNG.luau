-- Weighted random helpers.

local RNG = {}

function RNG.WeightedPick(entries: { { weight: number } }): number?
	local total = 0
	for _, entry in entries do
		if entry.weight > 0 then
			total += entry.weight
		end
	end
	if total <= 0 then
		return nil
	end
	local roll = math.random() * total
	local cumulative = 0
	for i, entry in entries do
		if entry.weight > 0 then
			cumulative += entry.weight
			if roll <= cumulative then
				return i
			end
		end
	end
	for i = #entries, 1, -1 do
		if entries[i].weight > 0 then
			return i
		end
	end
	return nil
end

function RNG.WeightedTablePick(weights: { [string]: number }): string?
	local total = 0
	local keys = {}
	for key, weight in weights do
		if weight > 0 then
			total += weight
			table.insert(keys, key)
		end
	end
	if total <= 0 or #keys == 0 then
		return nil
	end
	local roll = math.random() * total
	local cumulative = 0
	for _, key in keys do
		local w = weights[key]
		if w and w > 0 then
			cumulative += w
			if roll <= cumulative then
				return key
			end
		end
	end
	return keys[#keys]
end

function RNG.Chance(p: number): boolean
	return math.random() < math.clamp(p, 0, 1)
end

-- Lucky orb multiplier roll (common → jackpot)
function RNG.OrbMultiplier(): (number, string)
	local tier = RNG.WeightedTablePick({
		Normal = 70,
		Glowing = 20,
		Radiant = 8,
		Jackpot = 2,
	}) or "Normal"
	if tier == "Glowing" then
		return 2, "Glowing"
	elseif tier == "Radiant" then
		return 3, "Radiant"
	elseif tier == "Jackpot" then
		return 5, "Jackpot"
	end
	return 1, "Normal"
end

return RNG
