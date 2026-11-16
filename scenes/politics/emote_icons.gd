extends Node
## Autoload "EmoteIcons": renders each 3D emote mesh into a small texture so the
## same art can be used in the UI (argument builder, radial menu).

const ICON_SIZE := 128

var _icons := {}


func _ready() -> void:
	for id in Emote.all():
		_icons[id] = _render_icon(id)


func get_icon(id: int) -> Texture2D:
	return _icons.get(id)


func _render_icon(id: int) -> Texture2D:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(ICON_SIZE, ICON_SIZE)
	viewport.transparent_bg = true
	viewport.own_world_3d = true
	viewport.msaa_3d = Viewport.MSAA_4X
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)

	var emote := Emote.instantiate(id)
	viewport.add_child(emote)

	# Frame the emote's bounds with an orthographic camera looking down -Z.
	var bounds := _get_bounds(emote)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = maxf(maxf(bounds.size.x, bounds.size.y), 0.1) * 1.12
	viewport.add_child(camera)
	camera.global_position = bounds.get_center() + Vector3(0.0, 0.0, 10.0)
	camera.current = true

	return viewport.get_texture()


func _get_bounds(root: Node3D) -> AABB:
	var bounds := AABB()
	var first := true
	for node in root.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := node as MeshInstance3D
		var box := mesh_instance.global_transform * mesh_instance.get_aabb()
		bounds = box if first else bounds.merge(box)
		first = false
	return bounds if not first else AABB(Vector3(-0.5, -0.5, 0.0), Vector3.ONE)
