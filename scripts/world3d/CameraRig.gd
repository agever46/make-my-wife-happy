class_name CameraRig
extends Node3D
## Fixed, angled camera for the diorama look (like Overcooked): looks at `target` from the south, tilted down.

@export var target := Vector3(11.0, 0.0, 4.9)
@export_range(30.0, 75.0) var pitch_degrees: float = 55.0
@export var distance: float = 23.5
@export_range(20.0, 70.0) var fov: float = 38.0

var camera: Camera3D


func _ready() -> void:
	camera = Camera3D.new()
	camera.name = "Camera3D"
	camera.fov = fov
	camera.current = true
	add_child(camera)
	var pitch := deg_to_rad(pitch_degrees)
	camera.position = target + Vector3(0.0, sin(pitch), cos(pitch)) * distance
	camera.rotation = Vector3(-pitch, 0.0, 0.0)
