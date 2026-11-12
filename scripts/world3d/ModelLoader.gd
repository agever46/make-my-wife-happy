class_name ModelLoader
extends RefCounted
## Spawns a model by name. If res://assets/models/<name>.glb (or .gltf) exists, that Blender export is used,
## otherwise a built-in placeholder with the same name and size. Drop a file in with the right name and it replaces the placeholder.
## Blender conventions: origin at the bottom-centre of the object on the floor, model front towards +Y in Blender
## (becomes +Z in Godot after glTF export), 1 Blender unit = 1 m, applied scale and rotation.
## Names: Interact_<Thing> for stations, Prop_<Thing> for furniture, Char_<Who> for characters.
## Optional child node names that get animated if they exist: LegL, LegR, ArmL, ArmR (pivot at hip/shoulder), Head, BrowL, BrowR.

const DIR := "res://assets/models/"


static func spawn(model_name: String) -> Node3D:
	for ext in ["glb", "gltf"]:
		var path := "%s%s.%s" % [DIR, model_name, ext]
		if ResourceLoader.exists(path):
			var scene := load(path) as PackedScene
			if scene != null:
				var node := scene.instantiate() as Node3D
				if node != null:
					node.name = model_name
					return node
	return PlaceholderFactory.make(model_name)
