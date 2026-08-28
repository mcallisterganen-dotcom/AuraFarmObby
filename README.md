# Aura Farm Obby (Roblox + Rojo)

Solo fair-skill obby: clear Stage 1, grab Aura orbs, flex cosmetics later.

## Play (pick ONE method)

### A) Rojo live sync (best while coding)
1. In a terminal at this folder: `rojo serve`
2. In Roblox Studio: Rojo plugin → **Connect** (same port)
3. Press **Play**
4. You should see a green start pad in the sky, HUD on screen

### B) Open built place (no live sync needed)
1. In a terminal: `rojo build -o game.rbxlx`
2. Double-open `game.rbxlx` in Studio (File → Open)
3. Press **Play**

If you only press Play on an old empty baseplate place, **nothing new will appear** — Studio must be connected to Rojo or opened from `game.rbxlx`.

## What you should see
- Green start platform (elevated)
- Blue/orange path, yellow checkpoints, red kill bricks
- Purple Aura orbs, pink moving pad, gold FINISH
- HUD: timer, Aura, coins, Restart button

## Project layout
```
src/
  client/ObbyClient.client.luau  → StarterPlayerScripts
  server/ObbyServer.server.luau  → ServerScriptService
  server/StageBuilder.luau       → ServerScriptService (ModuleScript)
  shared/ObbyConfig.luau         → ReplicatedStorage.Shared
```

## Output window checks
After Play, open **View → Output**. You want:
- `[ObbyServer] Starting`
- `[StageBuilder] Stage 1 built`
- `[ObbyServer] Ready — Aura Farm Obby`
- `[ObbyClient] Starting`
- `[ObbyClient] HUD ready`

If those lines are missing, scripts never synced into the place.
