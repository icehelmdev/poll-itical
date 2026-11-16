class_name HUD
extends CanvasLayer
## In-game UI: health, group meters, radial menu and argument builder.
##
## Controls:
## - Tab: open/close the argument builder (pauses the game).
## - Hold Q or right mouse: radial menu, release over a slot to speak it.
## - 1-6: speak the argument in that slot directly.

var _player: Player
var _meters: GroupMeters
var _radial: RadialMenu
var _builder: ArgumentBuilder
var _status: Control
var _health_fill: ColorRect
var _cooldown_fill: ColorRect
var _supporters_label: Label
var _banner: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_player = get_tree().get_first_node_in_group(Player.GROUP) as Player

	_meters = GroupMeters.new()
	add_child(_meters)

	_build_status()
	_build_hints()

	_radial = RadialMenu.new()
	add_child(_radial)
	_radial.slot_chosen.connect(_speak_slot)

	_builder = ArgumentBuilder.new()
	add_child(_builder)
	_builder.hide()

	_banner = UIStyle.label("", 48, UIStyle.HATE)
	_banner.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_banner.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.add_theme_constant_override(&"outline_size", 10)
	_banner.add_theme_color_override(&"font_outline_color", Color.BLACK)
	add_child(_banner)

	if _player:
		_player.died.connect(_on_player_died)


func _process(_delta: float) -> void:
	if _player == null:
		return
	_health_fill.anchor_right = _player.health / _player.max_health
	_cooldown_fill.anchor_right = 1.0 - _player.caster.get_cooldown_ratio()
	var supporters := 0
	for node in get_tree().get_nodes_in_group(NPCSpawnPoint.GROUP):
		var group := node as NPCSpawnPoint
		if group.stance == NPCSpawnPoint.Stance.FOLLOWER:
			supporters += group.members.size()
	_supporters_label.text = "Supporters: %d" % supporters


func _input(event: InputEvent) -> void:
	# Handled here (not _unhandled_input) so Tab isn't eaten by UI focus navigation.
	if event.is_action_pressed(&"argument_builder"):
		_toggle_builder()
		get_viewport().set_input_as_handled()
	elif _builder.visible and event.is_action_pressed(&"ui_cancel"):
		_builder.close()
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if _builder.visible or _player == null or _player.is_dead():
		return
	if event.is_action_pressed(&"speak_menu"):
		var camera := get_viewport().get_camera_3d()
		var center := camera.unproject_position(_player.global_position + Vector3.UP) if camera \
			else _radial.size * 0.5
		_radial.open(center)
		get_viewport().set_input_as_handled()
	elif event.is_action_released(&"speak_menu"):
		_radial.close(true)
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo:
		var index: int = (event as InputEventKey).physical_keycode - KEY_1
		if index >= 0 and index < ArgumentBook.SLOT_COUNT:
			_speak_slot(index)
			get_viewport().set_input_as_handled()


func _toggle_builder() -> void:
	if _builder.visible:
		_builder.close()
	else:
		_radial.close(false)
		_builder.open()


func _speak_slot(index: int) -> void:
	if _player:
		_player.caster.speak(ArgumentBook.get_slot(index))


func _on_player_died() -> void:
	_radial.close(false)
	_banner.text = "You've been shouted down!"
	await get_tree().create_timer(2.0, true, false, true).timeout
	get_tree().reload_current_scene()


func _build_status() -> void:
	_status = PanelContainer.new()
	_status.add_theme_stylebox_override(&"panel", UIStyle.box(UIStyle.PANEL, 12, UIStyle.TILE, 2, 12))
	_status.position = Vector2(16, 16)
	add_child(_status)
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 6)
	_status.add_child(column)

	column.add_child(UIStyle.label("Credibility", 14, UIStyle.TEXT_DIM))
	_health_fill = _make_bar(column, Color(0.95, 0.5, 0.45), 14.0)
	column.add_child(UIStyle.label("Voice", 14, UIStyle.TEXT_DIM))
	_cooldown_fill = _make_bar(column, UIStyle.ACCENT, 8.0)
	_supporters_label = UIStyle.label("Supporters: 0", 16, UIStyle.LOVE)
	column.add_child(_supporters_label)


func _make_bar(parent: Control, color: Color, height: float) -> ColorRect:
	var background := ColorRect.new()
	background.color = Color(0.08, 0.09, 0.12)
	background.custom_minimum_size = Vector2(220, height)
	parent.add_child(background)
	var fill := ColorRect.new()
	fill.color = color
	fill.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.add_child(fill)
	return fill


func _build_hints() -> void:
	var hints := UIStyle.label("Tab: argument builder   |   Hold Q / right mouse: speak   |   1-6: quick speak",
		16, UIStyle.TEXT)
	hints.add_theme_constant_override(&"outline_size", 6)
	hints.add_theme_color_override(&"font_outline_color", Color(0, 0, 0, 0.7))
	hints.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	hints.grow_horizontal = Control.GROW_DIRECTION_BOTH
	hints.grow_vertical = Control.GROW_DIRECTION_BEGIN
	hints.position.y -= 16
	hints.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(hints)
