shader_type spatial;
// Camera-facing speech bubble: rounded rectangle with a small tail pointing down at the speaker.
render_mode unshaded, blend_mix, depth_test_disabled, depth_draw_never, cull_disabled, shadows_disabled;

uniform vec2 body_size = vec2(2.0, 0.8);   // the rounded rectangle, metres
uniform float tail = 0.22;
uniform float tail_x = 0.0;                 // where the tail sits along the body (metres from its centre)                  // extra height below the body for the tail, metres
uniform vec4 fill_color : source_color = vec4(1.0, 0.98, 0.93, 1.0);
uniform vec4 border_color : source_color = vec4(1.0, 0.6, 0.18, 1.0);

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
	vec2 quad = vec2(body_size.x, body_size.y + tail);
	vec2 p = (UV - 0.5) * quad;
	p.y = -p.y; // UV y grows downwards
	vec2 body_center = vec2(0.0, tail * 0.5);
	float r = min(0.2, body_size.y * 0.45);
	float d = sd_round_box(p - body_center, body_size * 0.5, r);
	// Tail: a triangle under the body, tip at the bottom of the quad.
	float body_bottom = body_center.y - body_size.y * 0.5;
	float tip = -quad.y * 0.5;
	float t = clamp((p.y - tip) / max(body_bottom - tip, 0.001), 0.0, 1.0);
	float tail_half = 0.13 * t;
	float in_tail = step(p.y, body_bottom + 0.03) * step(abs(p.x - tail_x), tail_half);
	float shape = min(d, mix(1.0, -0.001, in_tail));
	float inside = 1.0 - smoothstep(-0.006, 0.006, shape);
	float border = smoothstep(-0.05, -0.035, shape);
	ALBEDO = mix(fill_color.rgb, border_color.rgb, border);
	ALPHA = inside;
}
