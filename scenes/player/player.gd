class_name Player
extends CharacterBody3D
## Top-down player controlled with WASD. Movement is relative to the active camera's yaw.

@export var move_speed: float = 6.0
@export var acceleration: float = 40.0
@export var deceleration: float = 50.0

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")


func _physics_process(delta: float) -> void:
	var input_vector := Input.get_vector(&"move_left", &"move_right", &"move_forward", &"move_back")
	var direction := _get_camera_relative_direction(input_vector)

	var target_velocity := direction * move_speed
	var rate := acceleration if direction != Vector3.ZERO else deceleration
	velocity.x = move_toward(velocity.x, target_velocity.x, rate * delta)
	velocity.z = move_toward(velocity.z, target_velocity.z, rate * delta)

	if not is_on_floor():
		velocity.y -= _gravity * delta

	move_and_slide()


func _get_camera_relative_direction(input_vector: Vector2) -> Vector3:
	var direction := Vector3(input_vector.x, 0.0, input_vector.y)
	var camera := get_viewport().get_camera_3d()
	if camera:
		direction = direction.rotated(Vector3.UP, camera.global_rotation.y)
	return direction.normalized() if direction.length_squared() > 1.0 else direction
