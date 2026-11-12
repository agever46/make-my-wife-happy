shader_type spatial;
// Additive rim light drawn over an object (used as material_overlay) to highlight the targeted station.
render_mode blend_add, unshaded, depth_draw_never, cull_back, shadows_disabled;

uniform vec4 glow_color : source_color = vec4(1.0, 0.85, 0.4, 1.0);
uniform float strength : hint_range(0.0, 2.0) = 0.0;

void fragment() {
	float rim = pow(1.0 - clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0), 2.0);
	ALBEDO = glow_color.rgb * strength * (0.1 + rim * 0.9);
}
