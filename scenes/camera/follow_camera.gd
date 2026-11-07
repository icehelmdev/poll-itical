class_name FollowCamera
extends Camera3D
## Orthographic camera that smoothly follows a target from a fixed offset.

@export var target: Node3D
@export var follow_offset: Vector3 = Vector3(0.0, 20.0, 12.0)
## Higher values follow more tightly. 0 disables smoothing.
@export_range(0.0, 30.0, 0.1) var follow_speed: float = 8.0


func _ready() -> void:
	if target == null:
		push_warning("FollowCamera has no target assigned.")
		return
	global_position = target.global_position + follow_offset
	look_at(target.global_position, Vector3.UP)


func _physics_process(delta: float) -> void:
	if target == null:
		return
	var desired_position := target.global_position + follow_offset
	if follow_speed <= 0.0:
		global_position = desired_position
	else:
		var weight := 1.0 - exp(-follow_speed * delta)
		global_position = global_position.lerp(desired_position, weight)
