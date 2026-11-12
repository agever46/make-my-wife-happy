# 2D -> 3D upgrade plan (decided 2026-11-12)

The last 2D version is commit `631317e` (use `git checkout 631317e` to see or run it).

## Logic vs rendering (what the 2D project had)
| File | Role |
|---|---|
| `autoload/GameManager.gd` | LOGIC: state machine, Wife-O-Meter, money, 1 s tick, day timer. No visuals. Kept as is. |
| `autoload/QuestManager.gd` | LOGIC, but it knew 2D types (`Station`, `Player`, `Item`, `Marker2D`, scene-tree groups). Refactored to talk only in ids. |
| `quests/*` | LOGIC, pure data. Kept. |
| `ui/HUD.gd` | UI (CanvasLayer). Restyled. |
| `Main.gd` | glue: start / pause / restart. Kept. |
| `Player.gd`, `PlayerRig.gd`, `world/*.gd`, `Player*.tscn`, `Main.tscn` | RENDERING + 2D input/collision. Replaced by `world3d/*`. |

## The seam between logic and world
- World -> logic: `QuestManager.try_work(station_id, held_item_id, delta)` returns a Dictionary
  `{progress, done, consume, give, quest_uid}` (empty = nothing to do here). Also `is_station_needed(id)`, `icon_item_for(id)`.
- Logic -> world (signals): `item_spawn_requested(quest_uid, item_id)`, `quest_items_released(quest_uid)`, `world_reset`.
- `GameManager.player_count` is set by the players themselves (logic never searches the scene tree).
- Any renderer (3D, or a future 2D one) only needs to implement those calls and signals.

## File structure
```
scripts/autoload/  GameManager.gd  QuestManager.gd            (pure logic)
scripts/quests/    QuestData.gd  ActiveQuest.gd  QuestDB.gd   (pure data)
scripts/world3d/   Grid.gd HouseLayout.gd HouseBuilder.gd     (grid + layout + builder)
                   Bevel.gd PlaceholderFactory.gd ModelLoader.gd ContactShadow.gd
                   Station3D.gd Wife3D.gd StationIndicator.gd Player3D.gd Item3D.gd World.gd CameraRig.gd
scripts/ui/        HUD.gd
shaders/           rim_glow / billboard_bubble / billboard_bar / contact_shadow
scenes/            Main.tscn (Node3D)  Player3D.tscn
assets/models/     README.md + your .glb files (Interact_*, Prop_*, Char_*)
```

## Decisions
- 1 grid cell = 1 m. x = east, z = south (toward the camera), y = up. Model front = +Z.
- Renderer stays GL Compatibility (web + weak PCs). SSAO is Forward+ only, so it is enabled in the Environment
  (switch the project renderer to Forward+ to see it) and a cheap "contact shadow" under furniture and walls fakes it everywhere.
- Players move with `MOTION_MODE_FLOATING` on the y=0 plane (no gravity, no ground collider).
