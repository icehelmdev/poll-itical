class_name GroupMeters
extends Control
## Draws each NPC group's love/hate meter floating above the group, with the
## join (+50) and attack (-50) thresholds marked, plus popping "+10" numbers
## whenever an argument moves a meter.

const BAR_SIZE := Vector2(130, 12)
const HEIGHT_ABOVE_GROUP := 3.2
const POPUP_TIME := 1.3

var _shown_values := {}  # NPCSpawnPoint -> displayed (smoothed) approval
var _popups: Array[Dictionary] = []  # {group, text, color, age}
var _connected := {}


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	for node in get_tree().get_nodes_in_group(NPCSpawnPoint.GROUP):
		var group := node as NPCSpawnPoint
		if not _connected.has(group):
			_connected[group] = true
			group.approval_changed.connect(_on_approval_changed.bind(group))
		var shown: float = _shown_values.get(group, group.approval)
		_shown_values[group] = lerpf(shown, group.approval, 1.0 - exp(-8.0 * delta))
	for popup in _popups:
		popup.age += delta
	_popups = _popups.filter(func(p: Dictionary) -> bool: return p.age < POPUP_TIME)
	queue_redraw()


func _on_approval_changed(_approval: float, delta: float, group: NPCSpawnPoint) -> void:
	if is_zero_approx(delta):
		return
	_popups.append({
		group = group,
		text = "%+d" % roundi(delta),
		color = UIStyle.LOVE if delta > 0.0 else UIStyle.HATE,
		age = 0.0,
	})


func _draw() -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	var font := ThemeDB.fallback_font
	for key in _shown_values:
		if not is_instance_valid(key):
			continue
		var group := key as NPCSpawnPoint
		if group.members.is_empty():
			continue
		var world := group.get_center() + Vector3.UP * HEIGHT_ABOVE_GROUP
		if camera.is_position_behind(world):
			continue
		var anchor := camera.unproject_position(world)
		_draw_meter(group, anchor, _shown_values[key], font)

	for popup in _popups:
		var group: NPCSpawnPoint = popup.group
		if not is_instance_valid(group):
			continue
		var anchor := camera.unproject_position(group.get_center() + Vector3.UP * HEIGHT_ABOVE_GROUP)
		var t: float = popup.age / POPUP_TIME
		var pos: Vector2 = anchor + Vector2(BAR_SIZE.x * 0.5 + 10.0, -6.0 - 30.0 * ease(t, 0.4))
		var color: Color = popup.color
		color.a = 1.0 - ease(t, 3.0)
		draw_string_outline(font, pos, popup.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, 6, Color(0, 0, 0, color.a * 0.7))
		draw_string(font, pos, popup.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, color)


func _draw_meter(group: NPCSpawnPoint, anchor: Vector2, value: float, font: Font) -> void:
	var rect := Rect2(anchor - BAR_SIZE * 0.5, BAR_SIZE)
	draw_rect(rect.grow(3.0), Color(0.08, 0.09, 0.12, 0.85))
	draw_rect(rect, Color(0.3, 0.32, 0.38))

	# Fill from the middle toward the value.
	var mid_x := rect.position.x + rect.size.x * 0.5
	var fill_w := rect.size.x * 0.5 * clampf(value / 100.0, -1.0, 1.0)
	var fill_color := UIStyle.LOVE if value >= 0.0 else UIStyle.HATE
	draw_rect(Rect2(Vector2(mid_x + minf(fill_w, 0.0), rect.position.y), Vector2(absf(fill_w), rect.size.y)), fill_color)

	# Center line and thresholds.
	draw_line(Vector2(mid_x, rect.position.y - 2), Vector2(mid_x, rect.end.y + 2), UIStyle.TEXT, 2.0)
	for threshold in [group.join_threshold, group.attack_threshold]:
		var x: float = mid_x + rect.size.x * 0.5 * threshold / 100.0
		var tick_color := UIStyle.LOVE if threshold > 0.0 else UIStyle.HATE
		draw_line(Vector2(x, rect.position.y - 4), Vector2(x, rect.end.y + 4), tick_color.lightened(0.3), 2.0)

	var title := "%s  %d" % [group.get_display_name(), roundi(group.approval)]
	match group.stance:
		NPCSpawnPoint.Stance.FOLLOWER:
			title += "  - with you!"
		NPCSpawnPoint.Stance.HOSTILE:
			title += "  - HOSTILE"
	var font_size := 16
	var width := font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var text_pos := Vector2(anchor.x - width * 0.5, rect.position.y - 8.0)
	draw_string_outline(font, text_pos, title, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 5, Color(0, 0, 0, 0.75))
	var title_color := UIStyle.TEXT
	if group.stance == NPCSpawnPoint.Stance.FOLLOWER:
		title_color = UIStyle.LOVE
	elif group.stance == NPCSpawnPoint.Stance.HOSTILE:
		title_color = UIStyle.HATE
	draw_string(font, text_pos, title, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, title_color)
