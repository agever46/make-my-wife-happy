shader_type spatial;
// Round speech bubble that always faces the camera. Used for the floating task icons.
render_mode unshaded, blend_mix, depth_test_disabled, depth_draw_never, cull_disabled, shadows_disabled;

uniform vec4 fill_color : source_color = vec4(1.0, 0.97, 0.9, 1.0);
uniform vec4 ring_color : source_color = vec4(1.0, 0.62, 0.15, 1.0);

void vertex() {
	float sx = length(MODEL_MATRIX[0].xyz);
	float sy = length(MODEL_MATRIX[1].xyz);
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0] * sx, INV_VIEW_MATRIX[1] * sy, INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
}

void fragment() {
	float d = length(UV - 0.5) * 2.0;
	float ring = smoothstep(0.76, 0.8, d);
	ALBEDO = mix(fill_color.rgb, ring_color.rgb, ring);
	ALPHA = 1.0 - smoothstep(0.96, 1.0, d);
}
