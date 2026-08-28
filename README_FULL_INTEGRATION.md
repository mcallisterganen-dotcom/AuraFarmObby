# Aura Farm Obby — Full Integration

A complete Roblox obby with smooth physics-based movement, procedural terrain generation, professional animations, graphics effects, and cosmetic rewards.

## 🎮 Systems Included

### 1. Movement System (HD-Movement inspired)
- **Physics-based movement** with momentum and acceleration
- **Slope detection** - Gain speed going downhill, lose it climbing
- **Sliding mechanics** - Press C to slide with momentum boost
- **Crouch system** - CTRL to crouch (reduces speed, fits tight spaces)
- **Air strafing** - Smooth in-air movement control
- **Sprint** - SHIFT for 1.5x speed boost
- **Camera feedback** - FOV increases during slides and high speeds

### 2. Animation System
- **Smooth blending** - Transitions between idle/walk/run
- **9-track directional locomotion** - Realistic movement in all directions
- **Emotes & celebrations** - Victory dances on stage completion
- **Cosmetic animations** - Victory, Dance, Cheer

### 3. Graphics System
- **4 Visual Presets:**
  - AuraFarm (optimized for visibility)
  - Neon (vibrant, high-energy)
  - Cinematic (dark, professional)
  - Default (classic look)
- **Post-processing effects** - Bloom, color correction, sun rays
- **Dynamic lighting** - Smooth shader transitions

### 4. Cosmetics System
- **Aura Skins** - Default, Gold, Crimson, Mystic
- **Trails** - Sparkle, Fire, Smoke particle effects
- **Emotes** - Victory, Dance, Cheer celebrations
- **Particle effects** - Customizable colors and rarity tiers

### 5. Terrain Generator (Server-side)
- **Procedural stages** - 20 levels with increasing difficulty
- **Jumping obstacles** - Platforms at varying heights
- **Moving platforms** - Oscillating blue platforms
- **Hazard spikes** - Red obstacles that reset progress
- **Difficulty scaling** - Obstacles increase in number and complexity

### 6. Obby Manager (Server-side)
- **Checkpoint system** - Save progress at stage completion
- **DataStore persistence** - Resume at last checkpoint
- **Stage detection** - Automatic finish line recognition
- **Reward system** - Coin and cosmetic rewards per stage

## 📁 File Structure

```
src/
├── shared/
│   ├── AnimationConfig.luau      # Animation IDs & settings
│   └── MovementConfig.luau       # Movement physics & speeds
├── client/
│   ├── AnimationSystem.luau      # Smooth animation blending
│   ├── MovementSystem.luau       # Physics-based movement
│   ├── GraphicsSystem.luau       # Visual effects & shaders
│   ├── CosmeticsSystem.luau      # Skins, trails, emotes
│   └── IntegratedClient.client.luau  # Master client script
├── server/
│   ├── ObbyManager.server.lua    # Checkpoint & rewards
│   └── TerrainGenerator.luau     # Procedural level generation
└── README.md
```

## 🎮 Controls

| Key | Action |
|-----|--------|
| **WASD** | Move (relative to camera) |
| **SHIFT** | Sprint (1.5x speed) |
| **CTRL** | Crouch (move slower, fit tight spaces) |
| **C** | Slide (momentum boost + control) |
| **SPACE** | Jump |
| **E** | Victory Emote |
| **R** | Cycle Aura Skins |
| **T** | Cycle Trails |
| **G** | Cycle Graphics Presets |

## 🚀 Quick Start

### Installation

1. **Shared Config Files** → Place in `ReplicatedStorage/shared/`
   - `AnimationConfig.luau`
   - `MovementConfig.luau`

2. **Client Systems** → Place in `ReplicatedStorage/client/`
   - `AnimationSystem.luau`
   - `MovementSystem.luau`
   - `GraphicsSystem.luau`
   - `CosmeticsSystem.luau`

3. **Main Client Script** → Place in `StarterPlayer/StarterCharacterScripts/`
   - `IntegratedClient.client.luau`

4. **Server Scripts** → Place in `ServerScriptService/`
   - `ObbyManager.server.lua` (requires TerrainGenerator.luau as a sibling)
   - `TerrainGenerator.luau`

### First Run

1. Start the game
2. Watch console for `[AuraFarmObby] ✓ All systems integrated and running!`
3. Server will auto-generate 20 stages
4. Walk to stage 1 and start jumping!

## 🎨 Customization

### Adjust Movement Physics

Edit `MovementConfig.luau`:

```lua
MovementConfig.BaseWalkSpeed = 16          -- Normal walk speed
MovementConfig.SprintMultiplier = 1.5      -- Sprint speed boost
MovementConfig.Sliding.SpeedBoost = 30     -- Slide speed burst
MovementConfig.Jump.Power = 55             -- Jump height
```

### Customize Stage Difficulty

Edit `ObbyManager.server.lua`:

```lua
local STAGE_COUNT = 20  -- Number of stages
```

### Add Custom Aura Skins

Edit `CosmeticsSystem.luau`:

```lua
CosmeticsSystem.Cosmetics.AuraSkins.YourSkin = {
    Name = "Your Aura Name",
    Color = Color3.fromRGB(255, 100, 50),
    Rarity = "Legendary",
    Particles = "AuraEffect_yourskin",
}
```

### Change Graphics Presets

Edit `GraphicsSystem.luau`:

```lua
GraphicsSystem.Presets.YourPreset = {
    Brightness = 2.5,
    Ambient = Color3.fromRGB(r, g, b),
    -- ... more properties
}
```

## 📊 Performance Tips

- **Terrain Generation** auto-runs on server start (generates ~20 stages in ~2 seconds)
- **Physics updates** run at 60 FPS via Heartbeat
- **Animation blending** uses smooth interpolation (no jarring snaps)
- **Graphics** auto-adjusts FOV and effects in real-time

## 🔗 Integration Architecture

```
Player Input (WASD, C, E, R, T, G)
        ↓
IntegratedClient.client.luau (master script)
        ↓
┌───────┴─────────┬──────────────┬──────────────┐
│                 │              │              │
MovementSystem  AnimationSystem GraphicsSystem CosmeticsSystem
│                 │              │              │
└───────┬─────────┴──────────────┴──────────────┘
        ↓
  Character Updates
        ↓
   Server Events (ObbyManager)
        ↓
  Checkpoint Save / Rewards
```

## 🎁 Stage Progression & Rewards

- **Stage 1-5** - Learn basic movement, unlock Gold Aura
- **Stage 6-10** - Slope jumping, unlock Crimson Aura
- **Stage 11-15** - Moving platforms challenge
- **Stage 16-20** - Full difficulty, unlock Mystic Aura
- **Completion** - Player can replay anytime

## 🐛 Troubleshooting

### Player falls through terrain
- Check that `ObbyManager.server.lua` is running
- Verify `TerrainGenerator.luau` exists in the same folder

### Movement feels slow
- Edit `MovementConfig.BaseWalkSpeed` (increase value)
- Adjust `MovementConfig.Acceleration` (how fast you speed up)

### Cosmetics not showing
- Ensure `CosmeticsSystem.luau` is in `ReplicatedStorage/client/`
- Try pressing R to cycle aura skins

### Graphics not applying
- Verify `GraphicsSystem.luau` is loaded
- Press G to cycle presets

## 📈 Next Steps

1. **Leaderboard** - Track best times per stage
2. **Daily Challenges** - Reward cosmetics for speed runs
3. **Seasonal Events** - Limited-time cosmetics
4. **Multiplayer Racing** - Race other players on same stage
5. **Custom Skins** - Player-designed aura colors

---

**Built with smooth physics, stunning visuals, rewarding progression, and responsive controls!**

**Status: ✅ FULLY INTEGRATED & READY TO PLAY**
