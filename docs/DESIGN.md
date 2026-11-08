# Design notes

## Structure
- `project.godot` - 1280x720, stretch canvas_items/keep, GL Compatibility, input actions move_* (WASD + arrows), GameManager autoload.
- `scripts/autoload/GameManager.gd` - game state machine (MENU/PLAYING/PAUSED/GAME_OVER), Wife-O-Meter (0-100), money, central 1s Timer, signals.
- `scripts/Player.gd` - CharacterBody2D, Input.get_vector + move_and_slide, exponential smoothing + small elastic overshoot, squash & stretch.
- `scenes/Main.tscn` - Alpha bootstrap; `World` node has y_sort_enabled so characters/furniture sort by Y.

## Decisions
- Isometric feel is faked by scaling vertical speed (`iso_y_scale = 0.5`); movement stays 8-direction.
- Happiness changes are ignored unless state is PLAYING, so late quest callbacks cannot affect a finished game.
- Central Timer uses PROCESS_MODE_PAUSABLE; GameManager itself is ALWAYS so pause toggling works.

## Next
Quest system (random quests with patience timers), HUD, wife/sofa scene, debug console (`debug`).

## Art direction (decision)
Painterly cartoon style (Fortnite-like), not pixel art. Texture filter is Linear. The husband is one front image, mirrored by velocity and animated in code (hop + squash/stretch). Back/side views can be added later.
