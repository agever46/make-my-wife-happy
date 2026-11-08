class_name PlayerRig
extends Node2D
## Cut-out (Skeleton2D) character rig driven by an AnimationPlayer.
## The "idle" and "walk" animations are built in code in _ready(), so you can tune the
## exported values in the Inspector instead of editing keyframes by hand.
## The rig is drawn facing RIGHT; the whole rig is mirrored with scale.x when moving left.

## Seconds for one full walk cycle (two steps).
@export var cycle_time: float = 0.8
## Ground distance (px) covered by one full cycle. Should match Player.walk_cycle_length.
@export var cycle_length: float = 104.0
@export var leg_swing_deg: float = 32.0
@export var arm_swing_deg: float = 26.0
## >1 pushes the extreme poses past the target and lets the cubic curve settle back (elastic feel).
@export_range(1.0, 1.6) var overshoot: float = 1.2
@export var hip_bob_px: float = 3.0
@export var torso_lean_deg: float = 4.0
@export var torso_sway_deg: float = 3.0

const P_HIP := "Skeleton/Hip"
const P_TORSO := "Skeleton/Hip/Torso"
const P_HEAD := "Skeleton/Hip/Torso/Head"
const P_ARM_L := "Skeleton/Hip/Torso/ArmL"
const P_ARM_R := "Skeleton/Hip/Torso/ArmR"
const P_LEG_L := "Skeleton/Hip/LegL"
const P_LEG_R := "Skeleton/Hip/LegR"

@onready var anim: AnimationPlayer = $Anim
@onready var _hip: Node2D = $Skeleton/Hip


func _ready() -> void:
	var lib := AnimationLibrary.new()
	lib.add_animation(&"idle", _make_idle())
	lib.add_animation(&"walk", _make_walk())
	anim.add_animation_library(&"", lib)
	anim.play(&"idle")


## Call every physics frame from Player.gd.
func update_motion(velocity: Vector2) -> void:
	var speed := velocity.length()
	if speed > 20.0:
		if anim.current_animation != "walk":
			anim.play(&"walk", 0.12) # short blend avoids a pop
		# One cycle should cover cycle_length px of ground: sync feet to speed.
		anim.speed_scale = (speed / cycle_length) * cycle_time
		if absf(velocity.x) > 8.0:
			scale.x = 1.0 if velocity.x > 0.0 else -1.0
	else:
		if anim.current_animation != "idle":
			anim.play(&"idle", 0.2)
		anim.speed_scale = 1.0


# --- Animation builders ------------------------------------------------------

func _make_walk() -> Animation:
	var a := Animation.new()
	a.length = cycle_time
	a.loop_mode = Animation.LOOP_LINEAR
	var t := cycle_time
	var times := [0.0, t * 0.25, t * 0.5, t * 0.75, t]
	var leg := deg_to_rad(leg_swing_deg)
	var arm := deg_to_rad(arm_swing_deg)
	var o := overshoot
	# Legs: extreme poses at contact (0, 0.5), crossing at 0.25 / 0.75.
	_rot_track(a, P_LEG_L, times, [leg * o, 0.0, -leg * o, 0.0, leg * o])
	_rot_track(a, P_LEG_R, times, [-leg * o, 0.0, leg * o, 0.0, -leg * o])
	# Arms swing opposite to the leg on the same side; slightly later = loose, elastic follow-through.
	var lag := t * 0.06
	var arm_times := [lag, t * 0.25 + lag, t * 0.5 + lag, t * 0.75 + lag, t + lag]
	_rot_track(a, P_ARM_L, arm_times, [-arm * o, 0.0, arm * o, 0.0, -arm * o], true)
	_rot_track(a, P_ARM_R, arm_times, [arm * o, 0.0, -arm * o, 0.0, arm * o], true)
	# Torso: constant forward lean plus sway once per step (twice per cycle).
	var lean := deg_to_rad(torso_lean_deg)
	var sway := deg_to_rad(torso_sway_deg)
	_rot_track(a, P_TORSO, times, [lean + sway, lean, lean - sway, lean, lean + sway])
	# Head lags behind the torso and counter-rotates a little.
	_rot_track(a, P_HEAD, arm_times, [-sway * 0.6, 0.0, sway * 0.6, 0.0, -sway * 0.6], true)
	# Hip bob: lowest at contact, highest while passing.
	var y := _hip.position.y
	var bob := hip_bob_px
	_value_track(a, P_HIP + ":position:y", times, [y + bob, y - bob, y + bob, y - bob, y + bob])
	return a


func _make_idle() -> Animation:
	var a := Animation.new()
	a.length = 2.0
	a.loop_mode = Animation.LOOP_LINEAR
	var times := [0.0, 1.0, 2.0]
	var y := _hip.position.y
	_value_track(a, P_HIP + ":position:y", times, [y, y + 1.5, y])
	_rot_track(a, P_ARM_L, times, [0.0, deg_to_rad(2.0), 0.0])
	_rot_track(a, P_ARM_R, times, [0.0, deg_to_rad(-2.0), 0.0])
	_rot_track(a, P_HEAD, times, [0.0, deg_to_rad(-1.5), 0.0])
	return a


func _rot_track(a: Animation, path: String, times: Array, values: Array, wrap_times := false) -> void:
	_value_track(a, path + ":rotation", times, values, wrap_times)


func _value_track(a: Animation, path: String, times: Array, values: Array, wrap_times := false) -> void:
	var idx := a.add_track(Animation.TYPE_VALUE)
	a.track_set_path(idx, NodePath(path))
	a.track_set_interpolation_type(idx, Animation.INTERPOLATION_CUBIC)
	a.track_set_interpolation_loop_wrap(idx, true)
	for i in times.size():
		# Keys shifted by a lag can pass the animation length; clamp so they still load.
		a.track_insert_key(idx, minf(times[i], a.length), values[i])
