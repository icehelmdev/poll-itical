// Inverted-hull outline with a constant width in screen pixels.
// Use as the `next_pass` of a mesh's material.
shader_type spatial;
render_mode unshaded, cull_front, depth_draw_opaque, shadows_disabled;

uniform vec4 outline_color : source_color = vec4(0.2117647, 0.2117647, 0.2117647, 1.0);
// Outline thickness in screen pixels.
uniform float outline_width : hint_range(0.0, 20.0) = 2.0;
// Extrude along the direction from the mesh origin instead of the vertex normal.
// Use for hard-edged convex meshes (boxes) to avoid gaps at the corners.
uniform bool use_vertex_direction = false;

void vertex() {
	vec4 clip_position = PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(VERTEX, 1.0));
	vec3 extrude_direction = use_vertex_direction ? VERTEX : NORMAL;
	vec2 clip_direction = (PROJECTION_MATRIX * vec4(mat3(MODELVIEW_MATRIX) * extrude_direction, 0.0)).xy;

	// Normalize in pixel space so the width is the same horizontally and vertically.
	vec2 pixel_direction = clip_direction * VIEWPORT_SIZE;
	if (dot(pixel_direction, pixel_direction) > 0.000001) {
		pixel_direction = normalize(pixel_direction);
		// One pixel is 2 / VIEWPORT_SIZE in NDC; multiply by w to move from NDC to clip space.
		clip_position.xy += pixel_direction * outline_width * 2.0 / VIEWPORT_SIZE * clip_position.w;
	}
	POSITION = clip_position;
}

void fragment() {
	ALBEDO = outline_color.rgb;
}
