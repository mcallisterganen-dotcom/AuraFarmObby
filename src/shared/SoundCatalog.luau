-- SFX catalog using Roblox built-in library IDs (no custom upload required).

local SoundCatalog = {}

SoundCatalog.Ids = {
	Orb = "rbxassetid://9119720957",
	Lucky = "rbxassetid://9119720957",
	Checkpoint = "rbxassetid://12222253",
	Finish = "rbxassetid://12222208",
	Death = "rbxassetid://12222216",
	Whoosh = "rbxassetid://9114224583",
	Purchase = "rbxassetid://12222255",
	Equip = "rbxassetid://12222255",
	Achievement = "rbxassetid://12222208",
	Error = "rbxassetid://12222216",
	UI = "rbxassetid://6701939800",
	Bounce = "rbxassetid://9119720957",
}

-- Soft ambient loop (optional music bed)
SoundCatalog.MusicId = "rbxassetid://1844702927"
SoundCatalog.MusicVolume = 0.25
SoundCatalog.SfxVolume = 0.55

function SoundCatalog.Get(name: string): string?
	return SoundCatalog.Ids[name]
end

return SoundCatalog
