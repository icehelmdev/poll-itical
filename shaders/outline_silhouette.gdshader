// Silhouette-only outline: an expanded hull that is masked by the stencil
// buffer, so it only shows *outside* the character (no inner/crease lines).
// Use as the `next_pass` of a material that writes stencil value 1
// (see materials/player_edge.tres).
shader_type spatial;
// Writing ALPHA puts this in the transparent pass, which runs after the
// opaque character has filled the stencil buffer.
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;
stencil_mode read, compare_not_equal, 1;

uniform vec4 outline_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
// Outline thickness in screen pixels.
uniform float outline_width : hint_range(0.0, 20.0) = 4.0;
// Extrude along the direction from the mesh origin instead of the vertex normal.
// Avoids gaps at the corners of flat-shaded / hard-edged meshes.
uniform bool use_vertex_direction = false;

void vertex() {
	vec4 clip_position = PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(VERTEX, 1.0));
	vec3 extrude_direction = use_vertex_direction ? VERTEX : NORMAL;
	vec2 clip_direction = (PROJECTION_MATRIX * vec4(mat3(MODELVIEW_MATRIX) * extrude_direction, 0.0)).xy;

	vec2 pixel_direction = clip_direction * VIEWPORT_SIZE;
	if (dot(pixel_direction, pixel_direction) > 0.000001) {
		pixel_direction = normalize(pixel_direction);
		clip_position.xy += pixel_direction * outline_width * 2.0 / VIEWPORT_SIZE * clip_position.w;
	}
	POSITION = clip_position;
}

void fragment() {
	ALBEDO = outline_color.rgb;
	ALPHA = outline_color.a;
}
