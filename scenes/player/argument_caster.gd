class_name ArgumentCaster
extends Node3D
## Lets the player speak an argument: shows it as emotes above the player's
## head, sends out a shockwave ring, and every NPC group with a member inside
## the influence radius hears it (moving that group's love/hate meter).

signal argument_spoken(argument: Argument, groups_reached: Array[NPCSpawnPoint])

## Groups with any member within this distance hear the argument.
@export var influence_radius: float = 9.0
## Seconds between arguments.
@export var cooldown: float = 1.2

@export_group("Display")
## Height above the player's feet where the argument's emotes appear.
@export var display_height: float = 3.2
@export var display_spacing: float = 1.0
@export var display_duration: float = 2.0
@export var ring_color: Color = Color(0.94, 0.96, 0.94, 0.85)

var _cooldown_left: float = 0.0
var _display: Node3D


func _physics_process(delta: float) -> void:
	_cooldown_left = maxf(_cooldown_left - delta, 0.0)


func can_speak() -> bool:
	return _cooldown_left <= 0.0


## 1 right after speaking, 0 when ready again.
func get_cooldown_ratio() -> float:
	return _cooldown_left / cooldown if cooldown > 0.0 else 0.0


func speak(argument: Argument) -> bool:
	if argument == null or not argument.is_valid() or not can_speak():
		return false
	var body := get_parent() as Player
	if body and body.is_dead():
		return false
	_cooldown_left = cooldown

	_show_argument(argument)
	_spawn_shockwave()
	var visual := get_parent().get_node_or_null(^"Visual") as PlayerVisual
	if visual:
		visual.squash(5.0)

	var reached: Array[NPCSpawnPoint] = []
	for node in get_tree().get_nodes_in_group(NPCSpawnPoint.GROUP):
		var npc_group := node as NPCSpawnPoint
		if npc_group and npc_group.is_in_range(global_position, influence_radius):
			npc_group.hear_argument(argument)
			reached.append(npc_group)
	argument_spoken.emit(argument, reached)
	return true


func _show_argument(argument: Argument) -> void:
	if is_instance_valid(_display):
		_display.queue_free()
	_display = Node3D.new()
	_display.position = Vector3(0.0, display_height, 0.0)
	add_child(_display)

	var count := argument.emotes.size()
	for i in count:
		var holder := Node3D.new()
		holder.position.x = (i - (count - 1) * 0.5) * display_spacing
		holder.scale = Vector3.ONE * 0.01
		holder.add_child(Emote.instantiate(argument.emotes[i]))
		_display.add_child(holder)
		# Pop each emote in one after another.
		var tween := holder.create_tween()
		tween.tween_interval(i * 0.08)
		tween.tween_property(holder, "scale", Vector3.ONE, 0.3) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	var display := _display
	var out := display.create_tween()
	out.tween_interval(display_duration)
	out.tween_property(display, "scale", Vector3.ONE * 0.01, 0.2) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	out.tween_callback(display.queue_free)


func _spawn_shockwave() -> void:
	var world := get_tree().current_scene as Node3D
	if world == null:
		return
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.albedo_color = ring_color

	var torus := TorusMesh.new()
	torus.inner_radius = 0.93
	torus.outer_radius = 1.0
	torus.rings = 48
	torus.ring_segments = 4
	torus.material = material

	var ring := MeshInstance3D.new()
	ring.mesh = torus
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(ring)
	ring.global_position = Vector3(global_position.x, global_position.y + 0.08, global_position.z)
	ring.scale = Vector3(0.5, 0.05, 0.5)

	var tween := ring.create_tween()
	tween.tween_property(ring, "scale", Vector3(influence_radius, 0.05, influence_radius), 0.45) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(material, "albedo_color:a", 0.0, 0.45) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(ring.queue_free)
