# Quest system, stations and items

## Pieces
- `scripts/autoload/QuestManager.gd` (autoload): spawns a random quest every 7-11 s (max 3 active), counts down
  patience, advances steps. Signals: quest_added / quest_step_changed / quest_completed / quest_failed / quests_cleared.
- `scripts/quests/QuestDB.gd`: the quest pool. **Add new chores here.** `QuestData` = definition, `ActiveQuest` = running instance.
- `scripts/world/Station.gd`: furniture box. With a `station_id` it joins group `stations` and quest steps can target it.
- `scripts/world/Item.gd`: carryable item (group `items`). One item per player, floats above the head.
- `scripts/world/Wife.gd`: the wife on the sofa (station `wife`), face follows the Wife-O-Meter.
- `scripts/world/Room.gd`: floor + wall colliders for day 1 (house + yard, door gap in the right wall).
- `scripts/ui/HUD.gd`: Wife-O-Meter, money, quest tickets with patience bars, pause / game-over text.

## How a step works
A step = `{ station, needs, gives, work, text }`. The player stands next to the station and HOLDS interact (E / Space).
If the player holds the `needs` item (or the step needs none and hands are free), work accumulates; after `work`
seconds the needed item is consumed and the `gives` item appears in the player's hands. Last step done = quest complete.
TAP interact with free hands near a floor item = pick up; tap while holding = drop.

## Current quests
coffee (machine -> fridge for milk -> wife), trash (trash can -> dumpster outside), keys (find the keys at a random
`hiding_spots` marker -> wife).

## Decisions
- Quests are data (station ids + item ids), never per-quest code, so new chores need no new scripts.
- Input actions are per player (`p1_move_left`, `p1_interact`); Player has `player_id`. Nothing assumes one player.
- Items created by a quest are removed when it ends, so nobody is stuck holding a cold coffee.
- All look is placeholder drawn in code (`_draw`), so stations are invisible in the editor until real art replaces it.
- UI text is English for now (Hebrew needs a font with Hebrew glyphs + RTL setup).

## Not done yet
Real art for room/stations/wife, sounds, day timer / win condition, debug console, second player, upgrades shop.
