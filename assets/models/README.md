# 3D models (Blender -> Godot)

Drop `.glb` (or `.gltf`) exports here. The game looks for a file with the exact name below; if none exists it uses
a built-in placeholder, so you can replace models one at a time. No code changes needed.

## Export rules
- 1 Blender unit = 1 metre. The house grid is 1 m x 1 m, so a fridge is about 0.9 x 1.9 x 0.8.
- **Origin at the bottom-centre of the object, on the floor (Z = 0 in Blender).**
- Model front faces **-Y in Blender** (glTF export "+Y up" turns this into +Z in Godot, which is what the game expects).
- Apply scale and rotation (Ctrl+A) before exporting. Export as glTF Binary (.glb), "+Y Up", with materials.
- Flat, stylized materials with a small bevel on the edges look best. No lights or cameras in the file.

## Names
| File | Footprint (cells) | Notes |
|---|---|---|
| `Interact_Fridge` | 1 x 1 | station `fridge` |
| `Interact_CoffeeMachine` | 1 x 1 | station `coffee_machine`; include the counter it stands on |
| `Interact_TrashCan` | 1 x 1 | station `trash_can` |
| `Interact_Dumpster` | 2 x 1 | station `dumpster` |
| `Char_Wife` | seated, ~1 x 1 | station `wife`; optional child nodes `Skull`, `BrowL`, `BrowR` get mood animation |
| `Char_Husband` | standing | the player; optional child nodes `LegL`, `LegR`, `ArmL`, `ArmR` (pivot at hip / shoulder) get the walk swing |
| `Prop_Counter` | 1 x 1 | kitchen counter |
| `Prop_Couch` | 3 x 1 | back towards -Z |
| `Prop_CoffeeTable` | 1 x 1 | |
| `Prop_Rug` | 3 x 2 | flat, no collision |
| `Prop_TV` | 2 x 1 | TV on its stand |
| `Interact_Stove` | 1 x 1 | station `stove`; include the counter |
| `Interact_Sink` | 1 x 1 | station `sink`; include the counter |
| `Interact_WashingMachine` | 1 x 1 | station `washing_machine` |
| `Interact_Stain` | 1 x 1 | flat stain on the carpet, shown only while its quest is active |
| `Interact_Clothesline` | 2 x 1 | station `clothesline` |
| `Interact_Mailbox` / `Interact_LeashHook` / `Interact_Dog` / `Interact_Car` | 1x1 / 0.4x1 / 1x1 / 2x1 | yard and hall stations |
| `Interact_ToyBox` | 1 x 1 | station `toy_box` |
| `Prop_DiningTable` | 2 x 1 | |
| `Prop_Chair` | 0.6 x 0.6 | back towards -Z |
| `Prop_Bus` | 2.2 x 5 | the school bus; front towards +Z, door on the -X side |
| `Char_Kid_A` / `Char_Kid_B` | child, ~1.0 m | optional child nodes `LegL`/`LegR` (hip pivot), `KneeL`/`KneeR`, `ArmL`/`ArmR` get the walk and sit animation |

Where each one stands is set in `scripts/world3d/HouseLayout.gd` (cell, size, rotation).
