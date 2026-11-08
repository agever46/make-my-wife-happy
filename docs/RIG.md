# Cut-out rig (Skeleton2D)

`scenes/PlayerRig.tscn` = Skeleton2D + Bone2D chain + AnimationPlayer (`Anim`). `scenes/PlayerCutout.tscn` = Player with the rig.
Animations `idle` / `walk` are built in code by `scripts/PlayerRig.gd` (tune the exported values in the Inspector).

Bones: Hip > (Torso > Head, ArmL, ArmR), LegL, LegR. Each bone has a `Placeholder` Polygon2D child.

## Use your own parts
1. Under each bone add a `Sprite2D` (or move your existing sprites there) and delete that bone's `Placeholder`.
2. Set `Centered` off and `Offset` so the joint (shoulder, hip, neck) sits exactly at the bone origin (0,0) - the limb rotates around it.
3. Draw order: use `z_index` (far arm/leg = -1, near arm/leg = +1). Parts drawn facing RIGHT.
4. Swap the player in `scenes/Main.tscn`: change the Player instance to `res://scenes/PlayerCutout.tscn`.
5. Walk feel: `leg_swing_deg`, `arm_swing_deg`, `overshoot` (elastic), `hip_bob_px`, `cycle_time`. If feet slide, tune `Player.walk_cycle_length`.

Note: in a pure front view legs swing toward the camera, so a rotation looks like a scissor. For a front-facing sprite, prefer 3/4 or side parts.
