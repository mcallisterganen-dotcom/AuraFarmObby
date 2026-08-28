-- Trail / aura cosmetics. Buy with Aura; equip for a visible trail.

local CosmeticsCatalog = {}

export type TrailDef = {
	id: string,
	name: string,
	description: string,
	priceAura: number,
	color: Color3,
	color2: Color3?,
	lightEmission: number?,
	widthScale: number?,
	lifetime: number?,
	rarity: string?,
}

local TRAILS: { TrailDef } = {
	{
		id = "default",
		name = "Soft Mist",
		description = "Starter trail",
		priceAura = 0,
		color = Color3.fromRGB(200, 200, 220),
		color2 = Color3.fromRGB(160, 160, 180),
		lightEmission = 0.2,
		widthScale = 0.4,
		lifetime = 0.5,
		rarity = "Common",
	},
	{
		id = "violet",
		name = "Violet Drift",
		description = "Classic aura purple",
		priceAura = 40,
		color = Color3.fromRGB(170, 90, 255),
		color2 = Color3.fromRGB(120, 40, 200),
		lightEmission = 0.5,
		widthScale = 0.55,
		lifetime = 0.65,
		rarity = "Common",
	},
	{
		id = "meadow",
		name = "Meadow Glow",
		description = "Stage 1 green breeze",
		priceAura = 60,
		color = Color3.fromRGB(120, 255, 160),
		color2 = Color3.fromRGB(60, 180, 100),
		lightEmission = 0.45,
		widthScale = 0.5,
		lifetime = 0.6,
		rarity = "Common",
	},
	{
		id = "ember",
		name = "Ember Dash",
		description = "Warm speed streak",
		priceAura = 100,
		color = Color3.fromRGB(255, 140, 60),
		color2 = Color3.fromRGB(255, 60, 40),
		lightEmission = 0.7,
		widthScale = 0.6,
		lifetime = 0.7,
		rarity = "Rare",
	},
	{
		id = "canyon",
		name = "Crystal Wake",
		description = "Stage 2 canyon shimmer",
		priceAura = 140,
		color = Color3.fromRGB(180, 140, 255),
		color2 = Color3.fromRGB(100, 60, 200),
		lightEmission = 0.75,
		widthScale = 0.6,
		lifetime = 0.75,
		rarity = "Rare",
	},
	{
		id = "ocean",
		name = "Tide Runner",
		description = "Cool blue flow",
		priceAura = 160,
		color = Color3.fromRGB(80, 180, 255),
		color2 = Color3.fromRGB(40, 100, 220),
		lightEmission = 0.6,
		widthScale = 0.55,
		lifetime = 0.7,
		rarity = "Rare",
	},
	{
		id = "neon",
		name = "Neon Pulse",
		description = "Stage 3 cyber trail",
		priceAura = 220,
		color = Color3.fromRGB(80, 255, 230),
		color2 = Color3.fromRGB(255, 60, 140),
		lightEmission = 0.9,
		widthScale = 0.7,
		lifetime = 0.8,
		rarity = "Epic",
	},
	{
		id = "gold",
		name = "Gold Rush",
		description = "Show-off finish flex",
		priceAura = 300,
		color = Color3.fromRGB(255, 220, 80),
		color2 = Color3.fromRGB(255, 160, 40),
		lightEmission = 0.85,
		widthScale = 0.65,
		lifetime = 0.85,
		rarity = "Epic",
	},
	{
		id = "void",
		name = "Void Ribbon",
		description = "Dark prestige trail",
		priceAura = 450,
		color = Color3.fromRGB(40, 20, 60),
		color2 = Color3.fromRGB(160, 80, 255),
		lightEmission = 0.95,
		widthScale = 0.8,
		lifetime = 1.0,
		rarity = "Legendary",
	},
	{
		id = "rainbow",
		name = "Prism Storm",
		description = "Everything, loudly",
		priceAura = 600,
		color = Color3.fromRGB(255, 80, 180),
		color2 = Color3.fromRGB(80, 255, 220),
		lightEmission = 1,
		widthScale = 0.9,
		lifetime = 1.1,
		rarity = "Legendary",
	},
}

local byId: { [string]: TrailDef } = {}
for _, t in TRAILS do
	byId[t.id] = t
end

function CosmeticsCatalog.All(): { TrailDef }
	return TRAILS
end

function CosmeticsCatalog.Get(id: string): TrailDef?
	return byId[id]
end

function CosmeticsCatalog.GetTrail(id: string): TrailDef?
	return byId[id]
end

return CosmeticsCatalog
