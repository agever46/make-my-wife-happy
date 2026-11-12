# Debug console (game-master console)

Debug builds only (running from the editor counts; a release export has no console).
Open / close: **F1**, the **`** key, or just type the word **debug** while playing. **Esc** closes it.
The game is paused while it is open. Up / Down = command history, Tab = complete a command name.

| Command | What it does |
|---|---|
| `help [cmd]` | list commands |
| `status` | state, happiness, money, time, god mode, quests |
| `happy <0-100>` | set the Wife-O-Meter |
| `money <n>` | set the money |
| `time <seconds>` | set the seconds left in the day |
| `quest <coffee\|trash\|keys\|random>` | start a quest right now |
| `quests` / `clear` | list active quests / remove them all (no reward, no penalty) |
| `bus` | call the school bus now (kids arrive, dinner orders start) |
| `win` / `lose` / `restart` | end the day with victory / game over / start a new day |
| `god [on\|off]` | the Wife-O-Meter can not drop |
| `tp <station>` or `tp <x> <z>` | teleport player 1 (stations: coffee_machine fridge trash_can dumpster wife) |
| `give <item>` | put coffee, coffee_milk, trash_bag or keys in the hands |
| `speed <m/s>` | player walking speed |
| `timescale <x>` | game speed, e.g. `timescale 3` to fast-forward |

Adding a command: add a line to `HELP`, a branch in `execute()` and a `_cmd_*` function in
`scripts/autoload/DebugConsole.gd`. Logic helpers it needs live in `GameManager` / `QuestManager` (`set_happiness`, `set_time_left`, `clear_quests`, `god_mode`).

Note: typing `debug` also presses D, E, B, U, G, so the husband may take a step; use F1 if that matters.
