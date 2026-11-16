class_name ArgumentBuilder
extends Control
## Menu for constructing arguments out of emotes and assigning them to the
## radial menu. Pauses the game while open.
##
## Flow: click emotes to build a statement (max 3) -> Save -> the argument goes
## to your library (and the first free radial slot). Select an argument in the
## library, then click a radial slot to assign it. Right-click a slot to clear it.

signal closed

var _draft: Array[int] = []
var _selected: Argument

var _draft_row: HBoxContainer
var _draft_text: Label
var _draft_score_hint: Label
var _save_button: Button
var _library_list: VBoxContainer
var _slot_grid: GridContainer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UIStyle.make_theme()
	_build()
	ArgumentBook.library_changed.connect(_refresh_library)
	ArgumentBook.slots_changed.connect(_refresh_slots)
	_refresh_draft()
	_refresh_library()
	_refresh_slots()


func open() -> void:
	show()
	get_tree().paused = true
	_refresh_library()
	_refresh_slots()


func close() -> void:
	hide()
	get_tree().paused = false
	closed.emit()


# --- Building the layout ----------------------------------------------------

func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.45)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(820, 0)
	center.add_child(panel)

	var root := VBoxContainer.new()
	root.add_theme_constant_override(&"separation", 6)
	panel.add_child(root)

	root.add_child(UIStyle.label("Argument Builder", 26, UIStyle.ACCENT))
	root.add_child(UIStyle.label(
		"Topics (Peace, Happy, Angry) are what people have beliefs about. Good / Bad judges them.",
		15, UIStyle.TEXT_DIM))

	# Emote palette.
	root.add_child(UIStyle.label("Emotes", 20))
	var palette := HBoxContainer.new()
	palette.add_theme_constant_override(&"separation", 8)
	root.add_child(palette)
	for id in Emote.all():
		var button := Button.new()
		button.icon = EmoteIcons.get_icon(id)
		button.expand_icon = true
		button.text = Emote.get_display_name(id)
		button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.custom_minimum_size = Vector2(96, 86)
		button.tooltip_text = "Judgement" if Emote.is_judgement(id) else "Topic"
		button.pressed.connect(_add_to_draft.bind(id))
		palette.add_child(button)

	# Statement being built.
	root.add_child(UIStyle.label("Statement", 20))
	var draft_box := HBoxContainer.new()
	draft_box.add_theme_constant_override(&"separation", 12)
	root.add_child(draft_box)
	_draft_row = HBoxContainer.new()
	_draft_row.add_theme_constant_override(&"separation", 6)
	draft_box.add_child(_draft_row)
	var draft_info := VBoxContainer.new()
	draft_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	draft_box.add_child(draft_info)
	_draft_text = UIStyle.label("", 26)
	draft_info.add_child(_draft_text)
	_draft_score_hint = UIStyle.label("", 15, UIStyle.TEXT_DIM)
	draft_info.add_child(_draft_score_hint)
	var draft_buttons := VBoxContainer.new()
	draft_box.add_child(draft_buttons)
	_save_button = Button.new()
	_save_button.text = "Save argument"
	_save_button.pressed.connect(_save_draft)
	draft_buttons.add_child(_save_button)
	var clear_button := Button.new()
	clear_button.text = "Clear"
	clear_button.pressed.connect(func() -> void:
		_draft.clear()
		_refresh_draft())
	draft_buttons.add_child(clear_button)

	root.add_child(HSeparator.new())

	# Library + radial slots side by side.
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override(&"separation", 20)
	root.add_child(columns)

	var library_column := VBoxContainer.new()
	library_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(library_column)
	library_column.add_child(UIStyle.label("Your arguments", 20))
	library_column.add_child(UIStyle.label("Click one to select it.", 15, UIStyle.TEXT_DIM))
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 150)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	library_column.add_child(scroll)
	_library_list = VBoxContainer.new()
	_library_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_library_list)

	var slot_column := VBoxContainer.new()
	columns.add_child(slot_column)
	slot_column.add_child(UIStyle.label("Radial menu slots", 20))
	slot_column.add_child(UIStyle.label("Click: assign selected. Right-click: clear.", 15, UIStyle.TEXT_DIM))
	_slot_grid = GridContainer.new()
	_slot_grid.columns = 3
	_slot_grid.add_theme_constant_override(&"h_separation", 8)
	_slot_grid.add_theme_constant_override(&"v_separation", 8)
	slot_column.add_child(_slot_grid)

	var footer := UIStyle.label("Tab / Esc to close", 15, UIStyle.TEXT_DIM)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	root.add_child(footer)


# --- Draft ------------------------------------------------------------------

func _add_to_draft(id: int) -> void:
	if _draft.size() >= Argument.MAX_EMOTES:
		return
	_draft.append(id)
	_refresh_draft()


func _remove_from_draft(index: int) -> void:
	_draft.remove_at(index)
	_refresh_draft()


func _refresh_draft() -> void:
	for child in _draft_row.get_children():
		child.queue_free()
	for i in Argument.MAX_EMOTES:
		var slot := Button.new()
		slot.custom_minimum_size = Vector2(60, 60)
		if i < _draft.size():
			slot.icon = EmoteIcons.get_icon(_draft[i])
			slot.expand_icon = true
			slot.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
			slot.tooltip_text = "Remove"
			slot.pressed.connect(_remove_from_draft.bind(i))
		else:
			slot.text = "+"
			slot.disabled = true
		_draft_row.add_child(slot)

	var argument := Argument.create(_draft)
	_save_button.disabled = not argument.is_valid()
	if _draft.is_empty():
		_draft_text.text = "Pick some emotes..."
		_draft_score_hint.text = ""
	elif not argument.is_valid():
		_draft_text.text = "..."
		_draft_score_hint.text = "Add at least one topic (Peace, Happy, Angry)."
	else:
		_draft_text.text = "\"%s\"" % argument.get_text()
		_draft_score_hint.text = "Groups that love these topics will like you more for this." \
			if argument.get_sign() > 0 else "Groups that hate these topics will like you more for this."


func _save_draft() -> void:
	var argument := ArgumentBook.add_argument(_draft)
	if argument == null:
		return
	_draft.clear()
	_refresh_draft()
	_selected = argument
	var already_slotted := ArgumentBook.slots.has(argument)
	var empty := ArgumentBook.first_empty_slot()
	if not already_slotted and empty >= 0:
		ArgumentBook.assign_slot(empty, argument)
	_refresh_library()


# --- Library & slots --------------------------------------------------------

func _refresh_library() -> void:
	if _library_list == null:
		return
	for child in _library_list.get_children():
		child.queue_free()
	if not ArgumentBook.arguments.has(_selected):
		_selected = null
	for argument in ArgumentBook.arguments:
		var row := HBoxContainer.new()
		var button := UIStyle.argument_button(argument, 36.0)
		button.toggle_mode = true
		button.button_pressed = argument == _selected
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_select.bind(argument))
		row.add_child(button)
		var delete := Button.new()
		delete.text = "X"
		delete.tooltip_text = "Delete argument"
		delete.custom_minimum_size = Vector2(44, 0)
		delete.pressed.connect(ArgumentBook.remove_argument.bind(argument))
		row.add_child(delete)
		_library_list.add_child(row)


func _select(argument: Argument) -> void:
	_selected = null if _selected == argument else argument
	_refresh_library()


func _refresh_slots() -> void:
	if _slot_grid == null:
		return
	for child in _slot_grid.get_children():
		child.queue_free()
	for i in ArgumentBook.SLOT_COUNT:
		var argument := ArgumentBook.get_slot(i)
		var slot := UIStyle.argument_button(argument, 30.0, false)
		slot.custom_minimum_size = Vector2(120, 64)
		var number := UIStyle.label(str(i + 1), 14, UIStyle.TEXT_DIM)
		number.position = Vector2(6, 2)
		number.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(number)
		slot.tooltip_text = argument.get_text() if argument else "Empty"
		slot.pressed.connect(_on_slot_pressed.bind(i))
		slot.gui_input.connect(_on_slot_gui_input.bind(i))
		_slot_grid.add_child(slot)


func _on_slot_pressed(index: int) -> void:
	if _selected:
		ArgumentBook.assign_slot(index, _selected)
	elif ArgumentBook.get_slot(index):
		_select(ArgumentBook.get_slot(index))


func _on_slot_gui_input(event: InputEvent, index: int) -> void:
	var mouse := event as InputEventMouseButton
	if mouse and mouse.pressed and mouse.button_index == MOUSE_BUTTON_RIGHT:
		ArgumentBook.clear_slot(index)
		accept_event()
