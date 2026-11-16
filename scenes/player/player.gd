class_name Player
extends Actor
## Top-down player controlled with WASD. Movement is relative to the active camera's yaw.
## Has health so hostile groups can hurt (and eventually shout down) the player.

signal health_changed(health: float, max_health: float)
signal died

const GROUP := &"player"

@export var max_health: float = 100.0
## Seconds without taking a hit before health starts regenerating.
@export var regen_delay: float = 4.0
@export var regen_per_second: float = 6.0

var health: float

var _time_since_hit: float = 0.0

@onready var _visual: PlayerVisual = $Visual
@onready var caster: ArgumentCaster = $ArgumentCaster


func _ready() -> void:
	add_to_group(GROUP)
	health = max_health


func _physics_process(delta: float) -> void:
	super(delta)
	_time_since_hit += delta
	if not is_dead() and health < max_health and _time_since_hit >= regen_delay:
		health = minf(health + regen_per_second * delta, max_health)
		health_changed.emit(health, max_health)


func is_dead() -> bool:
	return health <= 0.0


func take_hit(damage: float, knockback: Vector3) -> void:
	if is_dead():
		return
	health = maxf(health - damage, 0.0)
	_time_since_hit = 0.0
	apply_knockback(knockback, 0.2)
	_visual.squash(6.0)
	health_changed.emit(health, max_health)
	if is_dead():
		died.emit()


func _get_move_direction(_delta: float) -> Vector3:
	if is_dead():
		return Vector3.ZERO
	var input_vector := Input.get_vector(&"move_left", &"move_right", &"move_forward", &"move_back")
	return _get_camera_relative_direction(input_vector)


func _get_camera_relative_direction(input_vector: Vector2) -> Vector3:
	var direction := Vector3(input_vector.x, 0.0, input_vector.y)
	var camera := get_viewport().get_camera_3d()
	if camera:
		direction = direction.rotated(Vector3.UP, camera.global_rotation.y)
	return direction.normalized() if direction.length_squared() > 1.0 else direction
