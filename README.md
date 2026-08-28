# Aura Farm Obby (Roblox + Rojo)

Solo fair-skill obby: clear Stage 1, farm Aura orbs, unlock trail cosmetics, chase best times.

Ideas integrated from reference projects (especially [tides-of-trade](https://github.com/Chronos31bit/tides-of-trade)):

| Feature | Source vibe |
|--------|-------------|
| DataStore profile + autosave | ProfileService-style persistence |
| Cosmetics catalog + shop | CosmeticsCatalog |
| Achievements + unlock toasts | AchievementCatalog / notifications |
| leaderstats (Aura / Coins / Finishes) | social flex |
| Combo orb pickups | juicier economy feedback |
| Trail equip on character | wearable cosmetics |
| Central `ObbyConfig` | GameConfig single source of truth |
| Weighted lucky orb rolls | gear-clicker RNG / rarity juice |

## Play (pick ONE method)

### A) Rojo live sync (best while coding)
1. Terminal in this folder:
   ```bash
   export PATH="$HOME/.rokit/bin:$PATH"
   rojo serve
   ```
2. Roblox Studio → Rojo plugin → **Connect**
3. Press **Play**

### B) Open the built place
```bash
export PATH="$HOME/.rokit/bin:$PATH"
rojo build -o game.rbxlx
```
Double-click `game.rbxlx` → **Play**.

## Controls
- **Run** the parkour (WASD / thumbstick)
- **R** or **Restart** button — reset the run (keeps Aura/cosmetics)
- **B** or **Shop** — buy/equip trails with Aura
- Touch **checkpoints** to save progress; **red** = kill; **purple orbs** = Aura; **gold finish** = clear

## Studio tips
- Enable **Studio Access to API Services** if you want DataStore saves in Play Solo  
  (Game Settings → Security). Otherwise progress is session-only.
- Output should show:
  - `[ObbyServer] Ready — Aura Farm Obby`
  - `[ObbyClient] HUD ready`
  - `[StageBuilder] Stage 1 built`

## Layout
```
src/
  shared/   ObbyConfig, CosmeticsCatalog, Achievements, Remotes
  server/   ObbyServer, StageBuilder, PlayerData, TrailService
  client/   ObbyClient (HUD + shop + finish)
```

## GitHub
https://github.com/mcallisterganen-dotcom/AuraFarmObby
