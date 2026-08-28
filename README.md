# Aura Farm Obby

A Roblox obby game with aura farming mechanics, smooth animations, professional graphics, and cosmetic rewards.

## Systems

### 1. Animation System (Anima-inspired)
- Smooth locomotion blending (Idle → Walk → Run)
- Automatic speed-based transitions
- Support for directional animations
- Emote/action animations (Victory, Dance, Cheer)
- **Files:**
  - `src/shared/AnimationConfig.luau` - Central animation configuration
  - `src/client/AnimationSystem.luau` - Animation blending engine

### 2. Graphics System
- Multiple visual presets (Default, Neon, Cinematic, AuraFarm)
- Post-processing effects (Bloom, Color Correction, Sun Rays)
- Smooth shader transitions
- Optimized for highlighting auras
- **File:** `src/client/GraphicsSystem.luau`

### 3. Cosmetics System
- **Aura Skins** - Colored particle effects (Default, Gold, Crimson, Mystic)
- **Trails** - Movement trails (Sparkle, Fire, Smoke)
- **Emotes** - Victory animations, dances, cheers
- Equippable cosmetics with rarity tiers
- **File:** `src/client/CosmeticsSystem.luau`

## How to Use

### Setup
1. Place `src/shared/AnimationConfig.luau` in `ReplicatedStorage/shared/`
2. Place `src/client/AnimationSystem.luau` in `ReplicatedStorage/client/`
3. Place `src/client/GraphicsSystem.luau` in `ReplicatedStorage/client/`
4. Place `src/client/CosmeticsSystem.luau` in `ReplicatedStorage/client/`
5. Place `src/client/PlayerClient.client.luau` in `StarterPlayer/StarterCharacterScripts/`

### In-Game Controls
- **E** - Play Victory emote
- **R** - Cycle aura skins (Default → Gold → Crimson → Mystic)
- **T** - Cycle trails (None → Sparkle → Fire → Smoke)
- **G** - Cycle graphics presets (AuraFarm → Neon → Cinematic → Default)

## Customization

### Add Custom Aura Skins
Edit `CosmeticsSystem.Cosmetics.AuraSkins`:
```lua
YourSkin = {
    Name = "Your Aura Name",
    Color = Color3.fromRGB(255, 0, 0),  -- RGB color
    Rarity = "Epic",
    Particles = "AuraEffect_yourname",
},
```

### Add Graphics Presets
Edit `GraphicsSystem.Presets`:
```lua
YourPreset = {
    Brightness = 2.0,
    Ambient = Color3.fromRGB(r, g, b),
    -- ... more properties
}
```

### Customize Animations
Edit `AnimationConfig.Animations` with your own animation IDs from Roblox.

## Architecture

```
src/
├── shared/
│   └── AnimationConfig.luau       # Animation IDs & blending config
├── client/
│   ├── AnimationSystem.luau       # Smooth animation blending
│   ├── GraphicsSystem.luau        # Visual effects & lighting
│   ├── CosmeticsSystem.luau       # Cosmetic skins & trails
│   └── PlayerClient.client.luau   # Main client entry point
```

## Next Steps

1. **Connect to Server** - Link cosmetics to DataStore for persistence
2. **Aura Drops** - Spawn auras with different rarities and skins
3. **Stage Rewards** - Award cosmetics when completing obby stages
4. **Leaderboard** - Show players with rarest auras
5. **Battle Pass** - Seasonal cosmetic rewards

---

**Built with smooth animations, stunning graphics, and rewarding cosmetics!**
