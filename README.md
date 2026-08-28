# Aura Farm Obby

Solo fair-skill obby: clear Stage 1, farm Aura, unlock trails, chase best times, hit dailies.

**v0.3** pulls a *lot* more from reference games — not just cosmetics + RNG.

## Integrated from other repos

### [tides-of-trade](https://github.com/Chronos31bit/tides-of-trade)
| System | In Aura Farm |
|--------|----------------|
| ProfileService-style data + autosave | `PlayerData` |
| Cosmetics catalog + equip | trails shop |
| Achievements + banners | `Achievements` |
| Daily quests + login streak | `QuestService` / `DailyQuests` |
| Weather / environment cycles | `WeatherService` (Clear → Golden → Storm → Night) with Aura mult |
| Ordered leaderboards | `OrderedStats` best times |
| Rate limiter on remotes | `RateLimiter` |
| Time / UTC day helpers | `TimeUtil` |
| Tutorial dialogue flow | first-run tips |
| Settings (music / sfx / reduce FX) | Settings panel |
| Notifications | toast stack + SFX |
| Sound catalog | `SoundCatalog` + client playback |
| Central GameConfig | `ObbyConfig` |

### [gear-clicker](https://github.com/Chronos31bit/gear-clicker)
| System | In Aura Farm |
|--------|----------------|
| Offline / AFK earnings | `OfflineEarnings` on rejoin |
| Soft currency loop | Aura orbs + shop |
| Combo / multiplier feel | orb combo + weather + luck |
| HUD polish | currency, streak, weather, times |

## Run

```bash
rojo serve
```

Rojo → Roblox Studio connect → **Play**.  
Enable **Studio Access to API Services** for DataStore saves + global best times.

## Controls
| Key | Action |
|-----|--------|
| **R** | Restart run |
| **B** | Shop (trails) |
| **Q** | Daily quests |
| **T** | Best times board |
| **P** | Settings |

## Loop
1. Parkour Stage 1 (checkpoints / kills / mover / finish)
2. Orbs → Aura (combo + lucky mult + weather mult)
3. Finish → best time + achievements
4. Spend Aura on trails · claim dailies · build login streak
5. Leave & return → soft AFK rewards

## Layout

```
src/shared/   config, catalogs, util, remotes
src/server/   ObbyServer + StageBuilder + services
src/client/   full HUD (shop, quests, board, settings, tutorial)
```

Repo: https://github.com/mcallisterganen-dotcom/AuraFarmObby
