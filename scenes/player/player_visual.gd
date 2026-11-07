class_name PlayerVisual
extends Node3D
## Procedural "juice" for the player's mesh: hop while moving, springy squash & stretch,
## and a lean into the movement direction. Purely visual; collision is untouched.
## Place this node at the character's feet so scaling squishes toward the ground.

@export var body: Player

@export_group("Hop")
## Hops per second at full speed.
@export var hop_frequency: float = 3.2
@export var hop_height: float = 0.35
## How quickly the hop fades in/out when starting/stopping.
@export var hop_blend_speed: float = 10.0

@export_group("Squash & Stretch")
## Stretch while moving vertically through a hop (0.15 = 15% taller).
@export var hop_stretch: float = 0.12
## Squash impulse applied each time the character lands.
@export var landing_squash: float = 4.0
## Squash impulse when starting to move, and wobble when stopping.
@export var start_squash: float = 3.0
@export var stop_squash: float = 2.5
@export var spring_stiffness: float = 220.0
@export var spring_damping: float = 11.0

@export_group("Lean")
@export var lean_angle_degrees: float = 10.0
@export var lean_speed: float = 10.0

var _hop_phase: float = 0.0
var _hop_amount: float = 0.0
var _scale_y: float = 1.0
var _scale_velocity: float = 0.0
var _was_moving: bool = false
var _lean: Vector2 = Vector2.ZERO


func _physics_process(delta: float) -> void:
	if body == null:
		return

	var planar_velocity := Vector2(body.velocity.x, body.velocity.z)
	var max_speed := maxf(body.move_speed, 0.001)
	var speed_ratio := clampf(planar_velocity.length() / max_speed, 0.0, 1.0)
	var is_moving := speed_ratio > 0.1

	_update_start_stop(is_moving)
	var hop_offset := _update_hop(delta, speed_ratio)
	_update_spring(delta)
	_update_lean(delta, planar_velocity / max_speed)

	position.y = hop_offset
	# Preserve volume: when taller, get thinner.
	var width := 1.0 / sqrt(maxf(_scale_y, 0.1))
	scale = Vector3(width, _scale_y, width)


func _update_start_stop(is_moving: bool) -> void:
	if is_moving and not _was_moving:
		_scale_velocity -= start_squash
	elif not is_moving and _was_moving:
		_scale_velocity -= stop_squash
	_was_moving = is_moving


func _update_hop(delta: float, speed_ratio: float) -> float:
	_hop_amount = lerpf(_hop_amount, speed_ratio, 1.0 - exp(-hop_blend_speed * delta))

	var previous_phase := _hop_phase
	_hop_phase += delta * hop_frequency * PI * maxf(speed_ratio, 0.0)

	# abs(sin) touches zero every PI radians: that's a landing.
	var landed := floorf(_hop_phase / PI) > floorf(previous_phase / PI)
	if landed and _hop_amount > 0.3:
		_scale_velocity -= landing_squash * _hop_amount

	# Ease back to the ground when idle so we don't freeze mid-air.
	if speed_ratio < 0.01 and _hop_amount < 0.01:
		_hop_phase = 0.0

	return absf(sin(_hop_phase)) * hop_height * _hop_amount


func _update_spring(delta: float) -> void:
	# Stretch when moving fast vertically (takeoff/fall), neutral at the apex.
	var target := 1.0 + hop_stretch * _hop_amount * absf(cos(_hop_phase))
	var acceleration := (target - _scale_y) * spring_stiffness - _scale_velocity * spring_damping
	_scale_velocity += acceleration * delta
	_scale_y += _scale_velocity * delta


func _update_lean(delta: float, planar_direction: Vector2) -> void:
	_lean = _lean.lerp(planar_direction, 1.0 - exp(-lean_speed * delta))
	var max_lean := deg_to_rad(lean_angle_degrees)
	# Tilt the top of the capsule toward the movement direction.
	rotation = Vector3(_lean.y * max_lean, 0.0, -_lean.x * max_lean)
