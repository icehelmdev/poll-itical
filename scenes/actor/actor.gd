class_name Actor
extends CharacterBody3D
## Shared movement for every character (player, NPCs). Subclasses only decide
## *where* to go by overriding _get_move_direction(); acceleration, gravity and
## sliding are identical so everything moves and animates the same way.

@export var move_speed: float = 6.0
@export var acceleration: float = 40.0
@export var deceleration: float = 50.0

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")


func _physics_process(delta: float) -> void:
	var direction := _get_move_direction(delta)

	var target_velocity := direction * move_speed
	var rate := acceleration if direction != Vector3.ZERO else deceleration
	velocity.x = move_toward(velocity.x, target_velocity.x, rate * delta)
	velocity.z = move_toward(velocity.z, target_velocity.z, rate * delta)

	if not is_on_floor():
		velocity.y -= _gravity * delta

	move_and_slide()


## World-space planar direction to move in, length 0..1. Override in subclasses.
func _get_move_direction(_delta: float) -> Vector3:
	return Vector3.ZERO
