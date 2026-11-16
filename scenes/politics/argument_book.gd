extends Node
## Autoload "ArgumentBook": the player's library of constructed arguments and
## which of them are assigned to the radial menu. Lives outside the level so it
## survives scene reloads.

signal library_changed
signal slots_changed

const SLOT_COUNT := 6

var arguments: Array[Argument] = []
## Radial menu slots; each entry is an Argument or null.
var slots: Array = []


func _ready() -> void:
	slots.resize(SLOT_COUNT)
	# A starter argument so the radial menu isn't empty on first play.
	var starter := add_argument([Emote.Id.PEACE, Emote.Id.GOOD])
	assign_slot(0, starter)


## Adds a new argument (or returns the existing identical one).
func add_argument(emote_ids: Array) -> Argument:
	var argument := Argument.create(emote_ids)
	if not argument.is_valid():
		return null
	for existing in arguments:
		if existing.is_same_as(argument):
			return existing
	arguments.append(argument)
	library_changed.emit()
	return argument


func remove_argument(argument: Argument) -> void:
	arguments.erase(argument)
	var slots_touched := false
	for i in SLOT_COUNT:
		if slots[i] == argument:
			slots[i] = null
			slots_touched = true
	library_changed.emit()
	if slots_touched:
		slots_changed.emit()


func assign_slot(index: int, argument: Argument) -> void:
	if index < 0 or index >= SLOT_COUNT:
		return
	slots[index] = argument
	slots_changed.emit()


func clear_slot(index: int) -> void:
	assign_slot(index, null)


func get_slot(index: int) -> Argument:
	if index < 0 or index >= SLOT_COUNT:
		return null
	return slots[index]


func first_empty_slot() -> int:
	for i in SLOT_COUNT:
		if slots[i] == null:
			return i
	return -1
