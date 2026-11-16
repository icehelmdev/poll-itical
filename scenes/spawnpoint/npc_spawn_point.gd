@tool
class_name NPCSpawnPoint
extends Node3D
## Spawns a number of NPCs at random positions inside a circle around this node.
## NPCs are added to this node's parent, so moving/freeing the spawn point
## afterwards doesn't affect them. The disc is an editor-only preview of the area.

signal npcs_spawned(npcs: Array[Node3D])

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

@onready var _preview: MeshInstance3D = $Preview


func _ready() -> void:
	_update_preview()
	if Engine.is_editor_hint():
		return
	_preview.visible = false
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
		parent.add_child(npc)
		spawned.append(npc)

	npcs_spawned.emit(spawned)
	return spawned


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
