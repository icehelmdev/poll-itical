@tool
class_name Belief
extends Resource
## How strongly a group feels about one emote topic.
## -10 = they hate it (promoting it makes them hate you), +10 = they love it.

@export var emote: Emote.Id = Emote.Id.PEACE:
	set(new_value):
		emote = new_value
		_update_name()
@export_range(-10, 10, 1) var value: int = 0:
	set(new_value):
		value = new_value
		_update_name()


func _init() -> void:
	_update_name()


func _update_name() -> void:
	resource_name = "%s %+d" % [Emote.get_display_name(emote), value]
	emit_changed()
