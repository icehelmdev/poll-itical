@tool
class_name NPCSpawnPoint
extends Node3D
## Spawns a group of NPCs at random positions inside a circle around this node.
## NPCs are added to this node's parent, so moving/freeing the spawn point
## afterwards doesn't affect them. The disc is an editor-only preview of the area.
##
## The spawn point is also the group's political identity: it holds the group's
## beliefs and its love/hate meter (approval) for the player. Arguments the
## player speaks near any group member move the meter; crossing the thresholds
## makes the whole group join or attack the player.

signal npcs_spawned(npcs: Array[Node3D])
## `delta` is how much this change moved the meter.
signal approval_changed(approval: float, delta: float)
signal stance_changed(stance: Stance)

enum Stance { NEUTRAL, FOLLOWER, HOSTILE }

## Node group every NPC group registers in at runtime.
const GROUP := &"npc_groups"
const MIN_APPROVAL := -100.0
const MAX_APPROVAL := 100.0

## How many NPCs to spawn.
@export_range(0, 500, 1, "or_greater") var npc_count: int = 5
@export var npc_scene: PackedScene = preload("res://scenes/npc/npc.tscn")
## NPCs are placed randomly within this radius.
@export_range(0.0, 50.0, 0.1, "or_greater") var spawn_radius: float = 3.0:
	set(value):
		spawn_radius = value
		_update_preview()
## Try to keep at least this much space between spawned NPCs.
@export var min_spacing: float = 1.0
@export var spawn_on_ready: bool = true

@export_group("Politics")
## Shown above the group's meter. Defaults to the node name.
@export var group_name: String = ""
## What this group cares about. Topics not listed count as 0 (indifferent).
@export var beliefs: Array[Belief] = []
@export_range(-100.0, 100.0, 1.0) var starting_approval: float = 0.0
## At or above this the group joins the player.
@export_range(0.0, 100.0, 1.0) var join_threshold: float = 50.0
## At or below this the group attacks the player.
@export_range(-100.0, 0.0, 1.0) var attack_threshold: float = -50.0
## Meter change per belief point an argument scores. With 1.0, an argument
## about a +10 topic moves the meter by 10.
@export_range(0.0, 10.0, 0.1, "or_greater") var persuasion_strength: float = 1.0

var approval: float = 0.0
var stance: Stance = Stance.NEUTRAL
var members: Array[Node3D] = []

@onready var _preview: MeshInstance3D = $Preview


func _ready() -> void:
	_update_preview()
	if Engine.is_editor_hint():
		return
	_preview.visible = false
	add_to_group(GROUP)
	approval = clampf(starting_approval, MIN_APPROVAL, MAX_APPROVAL)
	stance = _stance_for(approval)
	if spawn_on_ready:
		# Deferred: the parent is still setting up its children during _ready.
		spawn.call_deferred()


func spawn() -> Array[Node3D]:
	var spawned: Array[Node3D] = []
	var parent := get_parent()
	if npc_scene == null or parent == null:
		push_warning("NPCSpawnPoint '%s' has no npc_scene or parent." % name)
		return spawned

	var used_positions: Array[Vector3] = []
	for i in npc_count:
		var npc := npc_scene.instantiate() as Node3D
		var spawn_position := _pick_position(used_positions)
		used_positions.append(spawn_position)
		# Position before adding so the NPC's _ready() sees its real home position.
		npc.position = (parent as Node3D).to_local(spawn_position) if parent is Node3D else spawn_position
		if "group" in npc:
			npc.group = self
		parent.add_child(npc)
		members.append(npc)
		npc.tree_exited.connect(members.erase.bind(npc))
		spawned.append(npc)

	npcs_spawned.emit(spawned)
	return spawned


func get_display_name() -> String:
	return group_name if not group_name.is_empty() else String(name)


## This group's belief in a topic emote (-10..10, 0 if it doesn't care).
func get_belief_value(emote_id: int) -> int:
	var total := 0
	for belief in beliefs:
		if belief and belief.emote == emote_id:
			total += belief.value
	return total


## How much `argument` would move this group's meter.
func evaluate(argument: Argument) -> float:
	return argument.evaluate(get_belief_value) * persuasion_strength


## Applies an argument the player spoke within earshot. Returns the meter change.
func hear_argument(argument: Argument) -> float:
	var delta := evaluate(argument)
	add_approval(delta)
	for member in members:
		if member.has_method("react_to_argument"):
			member.react_to_argument(delta)
	return delta


func add_approval(delta: float) -> void:
	var previous := approval
	approval = clampf(approval + delta, MIN_APPROVAL, MAX_APPROVAL)
	approval_changed.emit(approval, approval - previous)
	var new_stance := _stance_for(approval)
	if new_stance != stance:
		stance = new_stance
		stance_changed.emit(stance)


## True if any member stands within `radius` of `point` (ignoring height).
func is_in_range(point: Vector3, radius: float) -> bool:
	for member in members:
		if is_instance_valid(member) and _flat_distance(member.global_position, point) <= radius:
			return true
	return false


## Average position of all members (or the spawn point if empty).
func get_center() -> Vector3:
	if members.is_empty():
		return global_position
	var sum := Vector3.ZERO
	for member in members:
		sum += member.global_position
	return sum / members.size()


func _stance_for(value: float) -> Stance:
	if value >= join_threshold:
		return Stance.FOLLOWER
	if value <= attack_threshold:
		return Stance.HOSTILE
	return Stance.NEUTRAL


static func _flat_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func _pick_position(used_positions: Array[Vector3]) -> Vector3:
	var candidate := global_position
	for attempt in 12:
		var angle := randf() * TAU
		var distance := sqrt(randf()) * spawn_radius
		candidate = global_position + Vector3(cos(angle), 0.0, sin(angle)) * distance
		var too_close := false
		for used in used_positions:
			if candidate.distance_to(used) < min_spacing:
				too_close = true
				break
		if not too_close:
			break
	return candidate


func _update_preview() -> void:
	if _preview == null:
		return
	var r := maxf(spawn_radius, 0.01)
	_preview.scale = Vector3(r, 1.0, r)
