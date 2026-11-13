# Controls

## Keyboard (player 1)
- Move: WASD or arrow keys.
- Work at a station: HOLD E or Space. Tap E / Space: pick up or drop an item.
- Esc: pause. Enter: restart after the day ends. F1, ` or typing `debug`: debug console.

## Camera
- The camera follows the husband and stays inside the map. **Mouse wheel** or **+ / -** zooms (distance 8 to 25, default 15); the level is remembered in `user://settings.cfg`.
- Debug console: `zoom <8-25>`. Settings are in `scripts/world3d/CameraRig.gd` (`default_distance`, `follow_speed`, `look_ahead_north`).

## Mouse (player 1, works together with the keyboard)
- **Left click on the floor:** walk there. Hold and drag to follow the cursor.
- **Left click on a station / kid / wife:** walk there and work until the step is done (no need to hold anything).
- **Left click on an item:** walk to it and pick it up.
- **Right click:** drop the item you carry, or pick up the nearest one.
- **Hover:** stations and items glow softly and the cursor turns into a hand.
- A key press cancels the mouse order. There is no path finding: the husband veers around a corner a few times and then gives up, so steer around big obstacles yourself.
- Click anywhere on the Game Over / Day Complete screen to start again; click on the Pause screen to continue.

Implementation: `Player3D.gd` (`_unhandled_input`, `_click_at`, `_nav_input`), picking via camera ray against the stations' `pick_aabb()` and a sphere around items.
