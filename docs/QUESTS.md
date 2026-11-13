# Quest system, stations and items (3D version)

> The 2D version of these pieces (Station.gd, Item.gd, Wife.gd, Room.gd, Player.gd) was replaced by `scripts/world3d/*`. See `docs/3D_PLAN.md` for the logic / rendering split.

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

## Quests (9)
| id | steps |
|---|---|
| coffee | coffee machine -> fridge (milk) -> wife |
| trash | trash can -> dumpster (outside) |
| keys | find the lost keys (hidden at a random spot) -> wife |
| laundry | washing machine -> clothesline (outside) |
| mail | mailbox (outside) -> wife |
| dog | leash hook (hall) -> dog (hold 3.5 s to walk it) |
| groceries | car (outside) -> fridge |
| stain | sink (sponge) -> stain on the carpet (scrub, hold 3 s); the stain only shows while this quest is active |
| remote | find the lost TV remote -> wife |

Difficulty ramps over the day: max quests at once 2 -> 4, gap between new quests 9-13 s -> 4.5-7 s (`QuestManager`).
New quest = one entry in `QuestDB.gd` (+ stations in `HouseLayout.gd` and item icons in `Item3D.ICONS` if it needs new ones).

## The school bus and the kids (event)
- `EventManager` (autoload, logic) calls the bus at `BUS_TIME` (22 s into the day). The world (`BusEvent.gd`) drives a yellow bus
  along the road, the two kids (Mia = `kid_a`, Noah = `kid_b`) walk through the yard and the door to their chairs.
- When both sit, `EventManager.kids_seated()` sets the flag `kids_home` and starts the two **dinner** orders; the bus leaves.
- Dinner for each kid: fridge (ingredients) -> stove (cook, hold 3.5 s) -> serve the kid. A plate appears on the table.
- While the kids are home they also make random requests (quests with `requires = kids_home`): water (sink), ketchup / cookie (fridge), lost toy duck (hidden in the house). Each kid has its own set.
- Quest fields: `requires` (needs a flag), `event_only` (never picked at random), `kid` (which kid reacts when it is done).
- **Playtime:** when both dinner orders are over (served or ruined), `EventManager` sets `kids_at_table = false`, `kids_playing = true`
  and emits `kids_play_requested`. The kids stand up and run between `HouseLayout.PLAY_POINTS` in the living room, hopping and playing in place.
  A kid stops running while a player stands next to it, so it can be reached.
- Playtime quests (`requires = kids_playing`): `play_a` / `play_b` (hold interact next to the kid for 4 s) and `tidy` (a toy lies somewhere -> the toy box in the living room).
  Ketchup only makes sense at the table (`requires = kids_at_table`); water, cookie and the lost duck work in both phases.
- When two quests could use the same station, the step that uses the item in the player's hands wins over a step that needs nothing (so delivering water beats "play").
- A day is 150 s now. Debug: `bus` calls the bus immediately, `play` ends dinner and starts playtime.

## Older notes on the first three quests
coffee (machine -> fridge for milk -> wife), trash (trash can -> dumpster outside), keys (find the keys at a random
`hiding_spots` marker -> wife).

## Decisions
- Quests are data (station ids + item ids), never per-quest code, so new chores need no new scripts.
- Input actions are per player (`p1_move_left`, `p1_interact`); Player has `player_id`. Nothing assumes one player.
- Items created by a quest are removed when it ends, so nobody is stuck holding a cold coffee.
- All look is placeholder drawn in code (`_draw`), so stations are invisible in the editor until real art replaces it.
- UI text is English for now (Hebrew needs a font with Hebrew glyphs + RTL setup).

## Day timer and victory
- A day lasts `GameManager.DAY_LENGTH` (120 s). The HUD shows the clock (turns red in the last 15 s).
- Survive the day with the Wife-O-Meter above 0: state VICTORY, signal `day_won(stars, score)`.
- Stars by Wife-O-Meter at the end: 3 at 70+, 2 at 40+, otherwise 1. Score = money * 10 + happiness.
- Dying at the very last tick still loses (decay is applied before the win check).
- Enter restarts after game over or victory. There is no "next day" content yet: Enter replays day 1.

## Not done yet
Sounds, debug console, second player, upgrades shop, more days/maps, walls/path art, Hebrew UI.
