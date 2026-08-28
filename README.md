# Aura Farm Obby

Solo fair-skill **multi-stage** Roblox obby:

1. **Meadow Run** — learn the flow  
2. **Crystal Canyon** — timing & height  
3. **Neon Spire** — precision endgame  

Farm Aura, unlock trails, chase best times, complete dailies.

**Version:** 0.5.0

## Play (Studio)

```bash
rojo serve
# Studio → Rojo plugin → Connect → Play
# or:
rojo build -o game.rbxlx
```

## What’s in v0.5

| System | Notes |
|--------|--------|
| 3 designed stages | ParkourKit primitives (gaps, weave, movers, bounce, spiral) |
| Biome terrain | Meadow hills/trees, canyon crystals, neon towers |
| Lobby hub | Stage select pads + portals after clears |
| Progression | Stage 2/3 locked until previous clear |
| Per-stage bests | Saved in profile + global OrderedDataStore board |
| Anti-cheat finish | Distance + min time + checkpoint gate |
| Economy | Orbs, combos, weather mult, lucky rolls, shop trails |
| Meta | Dailies, achievements, offline drip, soft shutdown |
| UX | Loading screen, mobile Sprint/Crouch/Slide, graphics presets |

## Controls

| Input | Action |
|-------|--------|
| WASD | Move |
| Shift | Sprint |
| Ctrl | Crouch |
| C | Slide |
| R | Restart run |
| B | Shop |
| Q | Quests |
| T | Best times |
| P | Settings |
| E | Emote (client) |
| Y | Aura flash |
| G | Graphics cycle |
| Mobile | On-screen Sprint / Crouch / Slide |

## Publish

See **[PUBLISH.md](PUBLISH.md)**.

## Repo layout

```
src/shared/   configs, catalogs, ParkourKit, StageConfig
src/server/   ObbyServer hub, StageBuilder, Terrain, data
src/client/   HUD, movement, cosmetics, loading, mobile
```

## Honest note on “AAA”

Real Roblox hits take custom animations, sound design, thumbnails, social loops, and months of playtesting. This codebase is a **strong production foundation** (multi-stage, secure economy, publish checklist). Next polish layers: custom anim IDs, authored SFX, Stage 4–6, monetization that doesn’t break fair skill, private playtests.
