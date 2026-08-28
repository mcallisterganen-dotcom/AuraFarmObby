-- Hard rules for path-only parkour + void death.
-- Collision groups: Players collide with Path + Kill only — never Decor/terrain.

local WorldRules = {}

WorldRules.Groups = {
	Player = "AF_Player",
	Path = "AF_Path", -- pads, checkpoints, finish, bounce, movers, rails
	Kill = "AF_Kill", -- void + kill bricks
	Decor = "AF_Decor", -- terrain, shells, crystals, trees (NO player collide)
	Orb = "AF_Orb", -- touchable, no solid collide
	Ghost = "AF_Ghost", -- lights, rims, VFX
}

-- How far below stage baseY counts as a fall death
WorldRules.FallMarginStuds = 8

-- Absolute world floor — anything under this dies (lobby + stages)
WorldRules.AbsoluteKillY = 2

-- Void kill plane placement
WorldRules.Void = {
	Size = Vector3.new(6000, 120, 6000),
	Position = Vector3.new(200, -40, -200),
}

-- Names that must always stay path-collidable
WorldRules.PathNameHints = {
	"Pad",
	"Path",
	"Step",
	"GapPad",
	"Weave",
	"Mover",
	"Checkpoint",
	"Finish",
	"Bounce",
	"Rail",
	"Spawn",
	"LobbyFloor",
	"LobbyPad",
	"Platform",
}

function WorldRules.IsPathName(name: string): boolean
	for _, hint in WorldRules.PathNameHints do
		if string.find(name, hint, 1, true) then
			return true
		end
	end
	return false
end

return WorldRules
