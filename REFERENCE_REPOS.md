# Roblox GitHub repos to mine for Aura Farm Obby

Curated list of **public** Roblox / Luau / Rojo projects.  
Use for **ideas and patterns** (systems, UX, architecture). Always check each repo’s **LICENSE** before copying code.

> You already integrated pieces of:
> - https://github.com/Chronos31bit/tides-of-trade.git
> - https://github.com/Chronos31bit/gear-clicker.git
> - https://github.com/mcallisterganen-dotcom/AuraFarmObby.git

---

## A) Your / known game sources (start here)

| Repo | Why it matters |
|------|----------------|
| https://github.com/Chronos31bit/tides-of-trade.git | Full cozy game: quests, weather, tides, cosmetics, ProfileService, Knit, achievements, tutorial, settings, leaderboards |
| https://github.com/Chronos31bit/gear-clicker.git | Clicker/tycoon: RNG rarity, AFK earnings, inventory, data lifecycle |
| https://github.com/mcallisterganen-dotcom/AuraFarmObby.git | This project |

---

## B) Battle-tested libraries (highest ROI for integration)

### Frameworks & structure
| Repo | Clone URL | Use for |
|------|-----------|---------|
| Knit | https://github.com/Sleitnick/Knit.git | Service/controller architecture |
| AeroGameFramework | https://github.com/1ForeverHD/AeroGameFramework.git | Older full game framework |
| NevermoreEngine | https://github.com/Quenty/NevermoreEngine.git | Huge module ecosystem |
| Matter (ECS) | https://github.com/evaera/matter.git | ECS if you go that direction |
| Flamework | https://github.com/rbxts-flamework/core.git | TypeScript DI framework (if using rbxts) |

### Data & networking
| Repo | Clone URL | Use for |
|------|-----------|---------|
| ProfileService | https://github.com/MadStudioRoblox/ProfileService.git | Session-locked player data (gold standard) |
| ProfileStore | https://github.com/lm-lolia/ProfileStore.git | Modern ProfileService successor (verify latest fork/name) |
| ReplicaService | https://github.com/MadStudioRoblox/ReplicaService.git | Server→client data replication |
| Lapis | https://github.com/nezuo/lapis.git | DataStore wrapper |
| DataKeep | https://github.com/ffrostflame/DataKeep.git | Data helpers |
| Promise | https://github.com/evaera/roblox-lua-promise.git | Async flow |

### Admin / commands / QA
| Repo | Clone URL | Use for |
|------|-----------|---------|
| Cmdr | https://github.com/evaera/Cmdr.git | In-game admin commands |
| HD Admin | https://github.com/1ForeverHD/HDAdmin.git | Admin systems reference |

### UI & UX
| Repo | Clone URL | Use for |
|------|-----------|---------|
| TopbarPlus | https://github.com/1ForeverHD/TopbarPlus.git | Topbar icons (shop/quests/settings) |
| ZonePlus | https://github.com/1ForeverHD/ZonePlus.git | Safe zone / checkpoint / finish regions |
| Fusion | https://github.com/dphfox/Fusion.git | Reactive UI |
| Roact | https://github.com/Roblox/roact.git | React-like UI (legacy but everywhere) |
| React-Lua | https://github.com/jsdotlua/react-lua.git | Modern React for Luau |
| UILabs / storybook-ish | search `roblox storybook` | Component previews |

### Util packs
| Repo | Clone URL | Use for |
|------|-----------|---------|
| RbxUtil | https://github.com/Sleitnick/RbxUtil.git | Component, Trove, Signal, Timer, TableUtil, etc. |
| Janitor | https://github.com/howmanysmall/Janitor.git | Cleanup |
| Trove | (inside RbxUtil) | Same idea |
| FastCast | https://github.com/XanTheDragon/FastCastAPI.git | Projectile rays (if you add combat later) |
| RaycastHitbox | https://github.com/TeamSwordphin/raycastHitboxRbxl.git | Melee hitboxes |

### Camera / character / input
| Repo | Clone URL | Use for |
|------|-----------|---------|
| Realism Client | search `Roblox realism client` | Footsteps, camera tilt |
| Shift Lock modules | many forks | Mobile-friendly camera |
| RbxCharacterSounds | various | Footstep SFX |

---

## C) Tooling (not game content, but needed)

| Repo | Clone URL | Use for |
|------|-----------|---------|
| Rojo | https://github.com/rojo-rbx/rojo.git | File↔Studio sync |
| Wally | https://github.com/UpliftGames/wally.git | Package manager |
| Rokit | https://github.com/rojo-rbx/rokit.git | Toolchain installer |
| Selene | https://github.com/Kampfkarren/selene.git | Luau linter |
| StyLua | https://github.com/JohnnyMorganz/StyLua.git | Formatter |
| Luau | https://github.com/luau-lang/luau.git | Language |
| luau-lsp | https://github.com/JohnnyMorganz/luau-lsp.git | Editor intelligence |
| Darklua | https://github.com/seaofvoices/darklua.git | Bundling/optimize |
| run-in-roblox | https://github.com/rojo-rbx/run-in-roblox.git | CI-ish runs |
| Mantle / Asphalt / Lune | search each | Assets, scripts, automation |

---

## D) Open game / kit / template repos (mine gameplay systems)

Quality varies wildly. Prefer repos with real `src/`, Rojo, and a README.

### Tycoon / simulator / economy
| Repo | Clone URL |
|------|-----------|
| Roblox-tycoon | https://github.com/itsrogermachado/Roblox-tycoon.git |
| roblox_tycoon | https://github.com/sgueltekin/roblox_tycoon.git |
| RobloxTycoon | https://github.com/DevMikeBrown/RobloxTycoon.git |
| Tycoon | https://github.com/Tyziryx/Tycoon.git |
| Roblox-Tycoon | https://github.com/dj-pearson/Roblox-Tycoon.git |

### Obby / parkour-ish (search often; names change)
Search GitHub for:
- `roblox obby`
- `roblox parkour`
- `stage obby rojo`
Then open anything with `default.project.json` + checkpoints.

Useful queries:
```
https://github.com/search?q=roblox+obby+rojo&type=repositories
https://github.com/search?q=roblox+parkour+language%3ALuau&type=repositories
https://github.com/search?q=checkpoint+killbrick+roblox&type=repositories
```

### Combat / FPS / action
Search:
```
https://github.com/search?q=roblox+fps+rojo&type=repositories
https://github.com/search?q=roblox+gun+system+luau&type=repositories
https://github.com/search?q=roblox+sword+combat&type=repositories
```
Known-style targets: FastCast-based guns, simple sword kits, ability systems.

### Full frameworks / boilerplates
Search:
```
https://github.com/search?q=roblox+boilerplate+rojo&type=repositories
https://github.com/search?q=knit+template+roblox&type=repositories
https://github.com/search?q=topic%3Aroblox+stars%3A%3E20&type=repositories
```

### Topic pages (browse regularly)
- https://github.com/topics/roblox
- https://github.com/topics/roblox-studio
- https://github.com/topics/rojo
- https://github.com/topics/luau
- https://github.com/topics/wally
- https://github.com/topics/knit

---

## E) “Awesome” lists & discovery

| Resource | URL |
|----------|-----|
| GitHub topic: roblox | https://github.com/topics/roblox |
| GitHub topic: rojo | https://github.com/topics/rojo |
| GitHub topic: luau | https://github.com/topics/luau |
| Search: roblox game language:Luau | https://github.com/search?q=roblox+game+language%3ALuau&type=repositories&s=stars |
| Search: roblox kit | https://github.com/search?q=roblox+kit+stars%3A%3E10&type=repositories |
| DevForum open source | https://devforum.roblox.com/search?q=open%20source%20github |
| Wally packages | https://wally.run/ |

---

## F) Priority shortlist for *this* obby (integrate next)

Ordered by “fits Aura Farm without becoming a different game”:

1. **https://github.com/MadStudioRoblox/ProfileService.git** — replace homemade DataStore with production-grade sessions  
2. **https://github.com/1ForeverHD/TopbarPlus.git** — clean mobile/PC buttons for Shop / Quests / Times / Settings  
3. **https://github.com/1ForeverHD/ZonePlus.git** — checkpoints/finish/kill zones instead of raw `.Touched`  
4. **https://github.com/Sleitnick/RbxUtil.git** — Trove/Signal/Component cleanup patterns  
5. **https://github.com/evaera/Cmdr.git** — admin: give aura, skip stage, set weather  
6. **https://github.com/Sleitnick/Knit.git** — only if the server file is getting too big  
7. **https://github.com/MadStudioRoblox/ReplicaService.git** — replicate stats cleanly  
8. **https://github.com/evaera/roblox-lua-promise.git** — cleaner async data loads  
9. **https://github.com/Chronos31bit/tides-of-trade.git** — still more: particles, music crossfade, richer tutorial, vendor UI patterns  
10. **https://github.com/Chronos31bit/gear-clicker.git** — still more: inventory UI, rarity colors, rebirth-style prestige for obby  
11. Tycoon kits above — droppers → **orb spawners**, buttons → **stage unlock gates**  
12. Any Rojo **obby** search hit — multi-stage structure, stage select, difficulty  

---

## G) Flat link dump (copy-paste)

```
https://github.com/Chronos31bit/tides-of-trade.git
https://github.com/Chronos31bit/gear-clicker.git
https://github.com/mcallisterganen-dotcom/AuraFarmObby.git

https://github.com/Sleitnick/Knit.git
https://github.com/Sleitnick/RbxUtil.git
https://github.com/MadStudioRoblox/ProfileService.git
https://github.com/MadStudioRoblox/ReplicaService.git
https://github.com/evaera/Cmdr.git
https://github.com/evaera/roblox-lua-promise.git
https://github.com/evaera/matter.git
https://github.com/1ForeverHD/TopbarPlus.git
https://github.com/1ForeverHD/ZonePlus.git
https://github.com/1ForeverHD/AeroGameFramework.git
https://github.com/1ForeverHD/HDAdmin.git
https://github.com/Quenty/NevermoreEngine.git
https://github.com/dphfox/Fusion.git
https://github.com/Roblox/roact.git
https://github.com/jsdotlua/react-lua.git
https://github.com/nezuo/lapis.git
https://github.com/howmanysmall/Janitor.git
https://github.com/XanTheDragon/FastCastAPI.git
https://github.com/TeamSwordphin/raycastHitboxRbxl.git

https://github.com/rojo-rbx/rojo.git
https://github.com/rojo-rbx/rokit.git
https://github.com/UpliftGames/wally.git
https://github.com/Kampfkarren/selene.git
https://github.com/JohnnyMorganz/StyLua.git
https://github.com/JohnnyMorganz/luau-lsp.git
https://github.com/luau-lang/luau.git

https://github.com/itsrogermachado/Roblox-tycoon.git
https://github.com/sgueltekin/roblox_tycoon.git
https://github.com/DevMikeBrown/RobloxTycoon.git
https://github.com/Tyziryx/Tycoon.git
https://github.com/dj-pearson/Roblox-Tycoon.git
```

---

## H) How we’ll use these (when you say go)

For each repo you care about:
1. Clone into `_refs/<name>/` (gitignored)
2. List systems (data, UI, combat, economy, map…)
3. Port **patterns** into Aura Farm (not whole fishing/tycoon loops)
4. Keep LICENSE notes

**Paste any more `.git` links you have** and they’ll be added to section A and scheduled for integration.

---

*Generated for Aura Farm Obby. Not every repo is maintained; star counts and names change. Prefer MIT/Apache licensed code.*
