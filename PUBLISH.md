# Publish checklist — Aura Farm Obby

Use this before putting the game on Roblox servers.

## 1. Build & open
```bash
rojo build -o game.rbxlx
# or: rojo serve  →  Studio Rojo plugin Connect
```

## 2. Studio game settings
| Setting | Value |
|---------|--------|
| Game name | Aura Farm Obby |
| Max players | 12–20 (obby feels better smaller) |
| Genre | Adventure / Obby |
| Enable Studio Access to API Services | **On** (for DataStores in Studio tests) |
| Allow HTTP | Off unless you add analytics |

**Game Settings → Security**
- Enable Studio Access to API Services: On (test only)
- Third Party Sales / Teleports: Off unless needed

**Game Settings → Avatar**
- Consistent R15 recommended (animations assume R15-ish)

## 3. DataStores
Live game needs DataStores enabled (default on published places).

Keys used (do not rename after launch without migration):
- Player profiles (see `PlayerData.luau`)
- Ordered best times (see `OrderedStats.luau`)

Test: finish a run → leave → rejoin → aura/best time still there.

## 4. Playtest matrix
- [ ] PC: sprint Shift, crouch Ctrl, slide C, emote E, aura Y, graphics G
- [ ] Mobile: on-screen Sprint / Crouch / Slide appear
- [ ] Touch finish pad → clear UI + aura gain
- [ ] Kill brick → respawn at last checkpoint
- [ ] Shop buy + equip trail
- [ ] Daily quest claim
- [ ] Best times board (T)
- [ ] Settings reduce FX
- [ ] Rejoin after 5+ min → offline reward toast
- [ ] Two players see separate leaderstats

## 5. Anti-exploit (already in code)
- Finish requires proximity to pad
- Finish rejects runs faster than `MinFinishTimeSec` (default 8s)
- Optional checkpoint gate via `MinCheckpointForFinish`
- Shop / restart / claim rate-limited
- All currency + best times server-authoritative

## 6. Publish
1. File → Publish to Roblox → create place or overwrite
2. Website → Create → Experiences → the place → **Make Live**
3. Configure icon, thumbnails, description
4. Description blurb:

> Solo-friendly aura farm obby. Clear Stage 1, grab orbs, unlock trails, chase best times, hit dailies. Fair skill — no pay-to-win required.

## 7. After go-live
- Watch Creator Dashboard → Errors / Analytics
- If DataStore errors spike, check budget (saves are dirty-flagged, not per-touch)
- Never wipe OrderedDataStore keys without a season reset plan

## What those GitHub links actually gave us
| Repo | Verdict |
|------|---------|
| brockmartin/roblox-game-skill | **Used** — security, publish, obby genre checklist |
| Smokestack-Games/rbxsync | Tooling only (not game code) |
| eBlguun/Assets | Empty README / asset dump — no Luau systems |
| e-DAMCommunity/Resources | Link list (Godot/Unity/etc.) — not portable |
| prographon/graphics-developer-roadmap | Graphics *learning* roadmap — inspiration only |
| killop/anything_about_game | Huge multi-engine bookmark dump — not Luau |
| Furthir/awesome-useful-projects | General awesome-list |
| LunyScript-RFC | Unity C# scripting RFC — **not Roblox** |
| nifty-site-manager/nsm | Static website manager — **irrelevant** |

**Bottom line:** almost none of those repos contain Roblox game systems to paste in. Polish came from your existing codebase + the Roblox skill guide + production patterns (loading, mobile, anti-cheat, soft shutdown, leaderstats).
