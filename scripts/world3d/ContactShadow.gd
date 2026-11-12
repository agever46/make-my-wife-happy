class_name ContactShadow
extends RefCounted
## Fake ambient occlusion: a soft dark rounded rectangle lying on the floor under an object.

const SHADER := preload("res://shaders/contact_shadow.gdshader")


## footprint = size of the object on the floor (metres). The patch extends `soft` metres beyond it.
static func make(footprint: Vector2, soft: float = 0.35, strength: float = 0.45) -> MeshInstance3D:
	var quad := QuadMesh.new()
	quad.size = footprint + Vector2(soft, soft) * 2.0
	var mat := ShaderMaterial.new()
	mat.shader = SHADER
	mat.set_shader_parameter("half_size", footprint * 0.5)
	mat.set_shader_parameter("quad_size", quad.size)
	mat.set_shader_parameter("soft", soft)
	mat.set_shader_parameter("strength", strength)
	var mi := MeshInstance3D.new()
	mi.name = "ContactShadow"
	mi.mesh = quad
	mi.material_override = mat
	mi.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	mi.position = Vector3(0.0, 0.015, 0.0)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi
