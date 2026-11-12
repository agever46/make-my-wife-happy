shader_type spatial;
// Soft dark patch under furniture and along walls. Fakes ambient occlusion where objects meet the floor
// (real SSAO only exists in the Forward+ renderer).
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled;

uniform vec2 half_size = vec2(0.5);
uniform vec2 quad_size = vec2(1.6);
uniform float soft = 0.35;
uniform float strength : hint_range(0.0, 1.0) = 0.45;

void fragment() {
	vec2 p = (UV - 0.5) * quad_size;
	float d = length(max(abs(p) - half_size, 0.0));
	ALBEDO = vec3(0.1, 0.06, 0.16);
	ALPHA = (1.0 - smoothstep(0.0, soft, d)) * strength;
}
