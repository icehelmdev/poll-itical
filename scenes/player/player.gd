class_name Player
extends Actor
## Top-down player controlled with WASD. Movement is relative to the active camera's yaw.


func _get_move_direction(_delta: float) -> Vector3:
	var input_vector := Input.get_vector(&"move_left", &"move_right", &"move_forward", &"move_back")
	return _get_camera_relative_direction(input_vector)


func _get_camera_relative_direction(input_vector: Vector2) -> Vector3:
	var direction := Vector3(input_vector.x, 0.0, input_vector.y)
	var camera := get_viewport().get_camera_3d()
	if camera:
		direction = direction.rotated(Vector3.UP, camera.global_rotation.y)
	return direction.normalized() if direction.length_squared() > 1.0 else direction
