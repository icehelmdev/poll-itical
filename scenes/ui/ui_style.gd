class_name UIStyle
extends RefCounted
## Shared colors, style boxes and small widget builders for the game's UI.

const PANEL := Color(0.16, 0.18, 0.24, 0.96)
const TILE := Color(0.42, 0.48, 0.58)
const TILE_HOVER := Color(0.52, 0.58, 0.7)
const TILE_PRESSED := Color(0.95, 0.72, 0.3)
const TEXT := Color(0.94, 0.96, 0.94)
const TEXT_DIM := Color(0.7, 0.74, 0.8)
const ACCENT := Color(0.95, 0.72, 0.3)
const LOVE := Color(0.42, 0.85, 0.5)
const HATE := Color(0.95, 0.38, 0.35)


static func box(color: Color, radius: int = 10, border: Color = Color.TRANSPARENT, border_width: int = 0, padding: int = 8) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.set_content_margin_all(padding)
	if border_width > 0:
		style.border_color = border
		style.set_border_width_all(border_width)
	return style


static func make_theme() -> Theme:
	var theme := Theme.new()
	theme.default_font_size = 18
	theme.set_color(&"font_color", &"Label", TEXT)
	for state in [&"font_color", &"font_hover_color", &"font_focus_color", &"font_hover_pressed_color"]:
		theme.set_color(state, &"Button", TEXT)
	theme.set_color(&"font_pressed_color", &"Button", Color(0.12, 0.12, 0.14))
	theme.set_color(&"font_disabled_color", &"Button", TEXT_DIM * Color(1, 1, 1, 0.6))
	theme.set_stylebox(&"normal", &"Button", box(TILE))
	theme.set_stylebox(&"hover", &"Button", box(TILE_HOVER))
	theme.set_stylebox(&"pressed", &"Button", box(TILE_PRESSED))
	theme.set_stylebox(&"hover_pressed", &"Button", box(TILE_PRESSED.lightened(0.1)))
	theme.set_stylebox(&"disabled", &"Button", box(TILE.darkened(0.4)))
	theme.set_stylebox(&"focus", &"Button", StyleBoxEmpty.new())
	theme.set_stylebox(&"panel", &"PanelContainer", box(PANEL, 18, TILE, 2, 16))
	return theme


static func label(text: String, size: int = 18, color: Color = TEXT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override(&"font_size", size)
	l.add_theme_color_override(&"font_color", color)
	return l


static func icon(emote_id: int, size: float) -> TextureRect:
	var rect := TextureRect.new()
	rect.texture = EmoteIcons.get_icon(emote_id)
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.custom_minimum_size = Vector2(size, size)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect


## A button showing an argument as a row of emote icons plus its text.
static func argument_button(argument: Argument, icon_size: float = 40.0, show_text: bool = true) -> Button:
	var button := Button.new()
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override(&"separation", 4)
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 6)
	row.alignment = BoxContainer.ALIGNMENT_CENTER if not show_text else BoxContainer.ALIGNMENT_BEGIN
	if argument:
		for id in argument.emotes:
			row.add_child(icon(id, icon_size))
		if show_text:
			var text := label(argument.get_text(), 18)
			text.mouse_filter = Control.MOUSE_FILTER_IGNORE
			text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			text.size_flags_vertical = Control.SIZE_FILL
			row.add_child(text)
	button.add_child(row)
	button.custom_minimum_size = Vector2(0.0, icon_size + 12.0)
	# The row isn't a container child, so grow the button to fit it once laid out.
	row.minimum_size_changed.connect(func() -> void:
		button.custom_minimum_size.x = row.get_combined_minimum_size().x + 12.0)
	return button
