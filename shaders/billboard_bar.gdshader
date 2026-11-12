shader_type spatial;
// Rounded progress bar that always faces the camera.
render_mode unshaded, blend_mix, depth_test_disabled, depth_draw_never, cull_disabled, shadows_disabled;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform vec2 bar_size = vec2(0.9, 0.16);

float sd_round_box(vec2 p, vec2 b, float r) {
	vec2 q = abs(p) - b + r;
	return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}

void vertex() {
	float sx = length(MODEL_MATRIX[0].xyz);
	float sy = length(MODEL_MATRIX[1].xyz);
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0] * sx, INV_VIEW_MATRIX[1] * sy, INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
}

void fragment() {
	vec2 p = (UV - 0.5) * bar_size;
	float d = sd_round_box(p, bar_size * 0.5, bar_size.y * 0.5);
	float inside = 1.0 - smoothstep(-0.004, 0.004, d);
	float border = smoothstep(-0.03, -0.02, d);
	vec3 fill = mix(vec3(1.0, 0.55, 0.15), vec3(0.35, 0.9, 0.4), progress);
	vec3 col = mix(vec3(0.16, 0.12, 0.22), fill, step(UV.x, progress));
	col = mix(col, vec3(1.0), border);
	ALBEDO = col;
	ALPHA = inside;
}
