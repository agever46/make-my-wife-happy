# Game design: Make My Wife Happy

## Vision (decided 2026-11-11)
Overcooked-style chaos: short, frantic sessions on a single-screen map. The wife sits on the sofa and
hands out funny chores; the husband must finish them before her patience runs out.
Chores happen inside the house and outside it. Co-op for 2+ players is planned, so every system is
built multiplayer-ready from the start, even while the game is single-player.

## Core loop
1. A quest ticket pops up (like an Overcooked order) with its own patience bar.
2. The player runs between stations, carries items, and performs short actions (hold / mash / timing).
3. Done in time: Wife-O-Meter up + money. Too late: sharp Wife-O-Meter drop.
4. Wife-O-Meter drains every second. At 0 the day ends (game over). Survive the day timer to win the level.

## Building blocks
- **Stations** (coffee machine, sink, washing machine, trash can, car, mailbox...): the player interacts when close.
- **Carryable items** (cup, laundry basket, trash bag, groceries): one item in hands at a time, can be put down or handed over.
- **Quests** = an ordered list of steps (go to station, do action, bring item to target). Defined as data, not code.
- **Levels = days**. Each day is one map: day 1 living room + kitchen, later the yard, the street, the supermarket.

## Quest ideas
Inside: coffee "exactly how I like it" (milk, sugar, temperature), find the lost keys / remote, chase the fly,
clean the carpet stain, hang the laundry before it rains, change the lightbulb, kill the spider, find her phone (it is ringing somewhere).
Outside: take out the trash before the truck leaves, walk the dog, bring the right items from the supermarket
(the list changes on the phone mid-way), water the plants, pick up the delivery, wash the car, parallel park.
Co-op (2+ players): carry the sofa together, one holds the ladder while the other changes the bulb, fold a bedsheet
from both ends, one distracts the baby/dog while the other cleans, passing groceries in a chain from the car.

## Multiplayer-ready rules (apply now)
- No code may assume a single player: use the `players` group and a `player_id` on each Player, never a global "the player".
- Input actions are per player (`p1_move_left`, `p2_move_left`, ...). Player 1 = keyboard, others = gamepads.
- Quests declare `min_players` / `max_players`; the quest picker filters by the current player count.
- Stations and items track *who* is using/holding them.
- Local co-op first (one screen, like Overcooked). Online is a later, separate decision.

## Build order
1. HUD (Wife-O-Meter, money, quest tickets). 2. Stations + carry/interact. 3. Quest system with 3 quests
(coffee, trash, keys). 4. Living-room + kitchen map with the wife on the sofa. 5. Debug console. 6. Outside area. 7. Second player.
