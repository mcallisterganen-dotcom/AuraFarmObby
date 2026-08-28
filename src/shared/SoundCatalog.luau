-- Procedural / placeholder SFX ids (tides SoundCatalog pattern).
-- Uses Roblox built-in library IDs that work without custom uploads.

local SoundCatalog = {}

-- Public toolbox-ish classics (safe defaults; swap for your own assets later)
SoundCatalog.Ids = {
	OrbPickup = "rbxassetid://12222216", -- electronic blip
	Checkpoint = "rbxassetid://12222225",
	Finish = "rbxassetid://1837829361", -- success-ish
	Death = "rbxassetid://12222208",
	Purchase = "rbxassetid://12222253",
	Equip = "rbxassetid://12222260",
	Achievement = "rbxassetid://1837829361",
	Click = "rbxassetid://12222208",
	Notify = "rbxassetid://12222216",
	Whoosh = "rbxassetid://12222253",
}

-- Ambient "music" bed — soft loop; disable in settings
SoundCatalog.MusicId = "rbxassetid://1842614858" -- calm loop-ish (replace anytime)
SoundCatalog.MusicVolume = 0.25
SoundCatalog.SfxVolume = 0.55

return SoundCatalog
