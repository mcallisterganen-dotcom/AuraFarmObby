-- Trail / aura cosmetics (tides-of-trade CosmeticsCatalog pattern, obby-flavored).
-- Buy with Aura; equip for a visible trail while running.

local CosmeticsCatalog = {}

export type TrailDef = {
	id: string,
	name: string,
	description: string,
	priceAura: number,
	color: Color3,
	color2: Color3?,
	width0: number?,
	width1: number?,
	lightEmission: number?,
}

local trails: { TrailDef } = {
	{
		id = "trail_starter",
		name = "Soft Mist",
		description = "A faint starter trail. Free.",
		priceAura = 0,
		color = Color3.fromRGB(200, 200, 220),
		color2 = Color3.fromRGB(140, 140, 160),
		width0 = 0.35,
		width1 = 0.05,
		lightEmission = 0.2,
	},
	{
		id = "trail_violet",
		name = "Violet Wake",
		description = "Classic aura purple.",
		priceAura = 40,
		color = Color3.fromRGB(180, 100, 255),
		color2 = Color3.fromRGB(100, 40, 200),
		width0 = 0.55,
		width1 = 0.08,
		lightEmission = 0.55,
	},
	{
		id = "trail_gold",
		name = "Gold Rush",
		description = "For finish-line flex.",
		priceAura = 80,
		color = Color3.fromRGB(255, 210, 70),
		color2 = Color3.fromRGB(255, 140, 20),
		width0 = 0.6,
		width1 = 0.1,
		lightEmission = 0.7,
	},
	{
		id = "trail_toxic",
		name = "Toxic Speed",
		description = "Looks fast. Is it?",
		priceAura = 120,
		color = Color3.fromRGB(80, 255, 120),
		color2 = Color3.fromRGB(20, 180, 80),
		width0 = 0.5,
		width1 = 0.08,
		lightEmission = 0.65,
	},
	{
		id = "trail_crimson",
		name = "Crimson Echo",
		description = "Death never looked this good.",
		priceAura = 160,
		color = Color3.fromRGB(255, 60, 90),
		color2 = Color3.fromRGB(160, 20, 40),
		width0 = 0.65,
		width1 = 0.1,
		lightEmission = 0.75,
	},
	{
		id = "trail_rainbow",
		name = "Prism Farm",
		description = "Endgame drip. Stack that aura.",
		priceAura = 300,
		color = Color3.fromRGB(255, 100, 255),
		color2 = Color3.fromRGB(80, 200, 255),
		width0 = 0.75,
		width1 = 0.12,
		lightEmission = 0.9,
	},
}

CosmeticsCatalog.Trails = trails

function CosmeticsCatalog.GetTrail(id: string): TrailDef?
	for _, t in trails do
		if t.id == id then
			return t
		end
	end
	return nil
end

function CosmeticsCatalog.All(): { TrailDef }
	return trails
end

return CosmeticsCatalog
