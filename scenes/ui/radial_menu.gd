class_name RadialMenu
extends Control
## Hold-to-open radial menu showing the arguments in ArgumentBook's slots.
## Point the mouse at a wedge and release to speak that argument.
## Time slows down while the menu is open.

signal slot_chosen(index: int)

@export var radius: float = 170.0
@export var inner_radius: float = 58.0
@export var slow_motion_scale: float = 0.3

var is_open: bool = false
var menu_center: Vector2

var _hovered: int = -1
var _open_amount: float = 0.0
var _last_ticks: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	hide()


func open(center: Vector2) -> void:
	menu_center = center
	is_open = true
	_hovered = -1
	_open_amount = 0.0
	_last_ticks = Time.get_ticks_msec()
	Engine.time_scale = slow_motion_scale
	show()


## Closes the menu. If `commit`, emits the hovered slot (if any).
func close(commit: bool) -> void:
	if not is_open:
		return
	is_open = false
	Engine.time_scale = 1.0
	hide()
	if commit and _hovered >= 0:
		slot_chosen.emit(_hovered)


func _process(_delta: float) -> void:
	if not is_open:
		return
	# Real time, unaffected by the slow motion.
	var now := Time.get_ticks_msec()
	var real_delta := (now - _last_ticks) / 1000.0
	_last_ticks = now
	_open_amount = minf(_open_amount + real_delta * 8.0, 1.0)

	var offset := get_local_mouse_position() - menu_center
	_hovered = -1
	if offset.length() > inner_radius * 0.5:
		var step := TAU / ArgumentBook.SLOT_COUNT
		# Slot 0 points straight up, then clockwise.
		var angle := offset.angle() + PI / 2.0
		_hovered = wrapi(roundi(angle / step), 0, ArgumentBook.SLOT_COUNT)
	queue_redraw()


func _draw() -> void:
	if not is_open:
		return
	var ease_amount := ease(_open_amount, -2.0)
	var r := radius * lerpf(0.6, 1.0, ease_amount)
	var r_inner := inner_radius * lerpf(0.6, 1.0, ease_amount)
	var alpha := _open_amount
	var count := ArgumentBook.SLOT_COUNT
	var step := TAU / count
	var font := ThemeDB.fallback_font

	for i in count:
		var mid := -PI / 2.0 + i * step
		var hovered := i == _hovered
		var argument := ArgumentBook.get_slot(i)
		var wedge_r := r * (1.08 if hovered else 1.0)
		var color := UIStyle.TILE_PRESSED if hovered else UIStyle.PANEL
		if argument == null and not hovered:
			color = UIStyle.PANEL.darkened(0.3)
		color.a *= alpha * 0.95
		_draw_wedge(menu_center, r_inner, wedge_r, mid - step * 0.5 + 0.02, mid + step * 0.5 - 0.02, color)

		var direction := Vector2.from_angle(mid)
		var slot_center := menu_center + direction * (r_inner + wedge_r) * 0.5
		# Slot number near the outer edge.
		var number_pos := menu_center + direction * (wedge_r - 16.0)
		draw_string(font, number_pos + Vector2(-5, 6), str(i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 14,
			Color(UIStyle.TEXT_DIM, alpha))
		if argument:
			_draw_argument_icons(argument, slot_center, 34.0 if not hovered else 40.0, alpha)

	# Center hub with the hovered argument's text.
	draw_circle(menu_center, r_inner - 4.0, Color(UIStyle.PANEL, alpha))
	var text := "Speak!"
	var hovered_argument := ArgumentBook.get_slot(_hovered) if _hovered >= 0 else null
	if _hovered >= 0:
		text = hovered_argument.get_text() if hovered_argument else "(empty)"
	var font_size := 15
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size).x
	# Text wider than the hub goes underneath the menu instead.
	var text_pos := menu_center + Vector2(-width * 0.5, 5)
	if width > (r_inner - 8.0) * 2.0:
		font_size = 20
		width = font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size).x
		text_pos = menu_center + Vector2(-width * 0.5, r + 36.0)
		draw_rect(Rect2(text_pos + Vector2(-10, -24), Vector2(width + 20, 34)), Color(UIStyle.PANEL, alpha * 0.9))
	draw_string(font, text_pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(UIStyle.TEXT, alpha))


func _draw_wedge(center: Vector2, r_in: float, r_out: float, from: float, to: float, color: Color) -> void:
	var points := PackedVector2Array()
	var segments := 16
	for s in segments + 1:
		points.append(center + Vector2.from_angle(lerpf(from, to, float(s) / segments)) * r_out)
	for s in range(segments, -1, -1):
		points.append(center + Vector2.from_angle(lerpf(from, to, float(s) / segments)) * r_in)
	draw_colored_polygon(points, color)


func _draw_argument_icons(argument: Argument, center: Vector2, icon_size: float, alpha: float) -> void:
	var count := argument.emotes.size()
	var spacing := icon_size * 0.8
	for i in count:
		var texture := EmoteIcons.get_icon(argument.emotes[i])
		if texture == null:
			continue
		var pos := center + Vector2((i - (count - 1) * 0.5) * spacing, 0.0)
		draw_texture_rect(texture, Rect2(pos - Vector2.ONE * icon_size * 0.5, Vector2.ONE * icon_size),
			false, Color(1, 1, 1, alpha))
