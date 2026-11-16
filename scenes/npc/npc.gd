class_name NPC
extends Actor
## Neutral NPC. Wanders around its home position (where it was spawned),
## walking to random points and idling in between. Steers around other
## characters (NPCs and the player) instead of getting stuck on them.

@export_group("Wander")
## How far from home the NPC will wander.
@export var wander_radius: float = 6.0
@export var min_idle_time: float = 1.0
@export var max_idle_time: float = 4.0
## Give up on a walk target after this long.
@export var max_walk_time: float = 6.0
@export var arrive_distance: float = 0.4

@export_group("Avoidance")
## How strongly nearby characters push this NPC away (radius comes from PersonalSpace's shape).
@export var separation_strength: float = 1.6
## Sideways steering when someone is in the way, so NPCs walk around each other.
@export var sidestep_strength: float = 0.8
## While idle, only shuffle away if someone is closer than this fraction of the personal space.
@export_range(0.0, 1.0) var idle_crowding_threshold: float = 0.35
## If the NPC moved less than this in one progress check while walking, it's stuck.
@export var stuck_distance: float = 0.25
@export var stuck_check_interval: float = 0.6

var home_position: Vector3

var _target: Vector3
var _is_walking: bool = false
var _state_timer: float = 0.0
var _neighbors: Array[Node3D] = []
var _space_radius: float = 1.3
var _stuck_timer: float = 0.0
var _last_check_position: Vector3
var _stuck_count: int = 0

@onready var _personal_space: Area3D = $PersonalSpace


func _ready() -> void:
	home_position = global_position
	var shape := ($PersonalSpace/CollisionShape3D as CollisionShape3D).shape
	if shape is CylinderShape3D:
		_space_radius = shape.radius
	elif shape is SphereShape3D:
		_space_radius = shape.radius
	_personal_space.body_entered.connect(_on_body_entered)
	_personal_space.body_exited.connect(_on_body_exited)
	_start_idle()


func _get_move_direction(delta: float) -> Vector3:
	_state_timer -= delta
	var separation := _get_separation()

	if not _is_walking:
		if _state_timer <= 0.0:
			_start_walk()
			return Vector3.ZERO
		# Shuffle apart when crowded, otherwise stand still.
		if separation.length() > idle_crowding_threshold:
			return (separation * separation_strength).limit_length(0.6)
		return Vector3.ZERO

	var to_target := _target - global_position
	to_target.y = 0.0
	if to_target.length() <= arrive_distance or _state_timer <= 0.0:
		_start_idle()
		return Vector3.ZERO

	if _check_stuck(delta):
		return Vector3.ZERO

	var desired := to_target.normalized()
	if separation != Vector3.ZERO:
		# Sidestep on whichever side is closer to where we want to go.
		var side := Vector3(-separation.z, 0.0, separation.x)
		if side.dot(desired) < 0.0:
			side = -side
		desired += separation * separation_strength + side * sidestep_strength
	return desired.limit_length(1.0)


## Sum of push-away vectors from nearby characters, stronger the closer they are.
func _get_separation() -> Vector3:
	var push := Vector3.ZERO
	for other in _neighbors:
		if not is_instance_valid(other):
			continue
		var offset := global_position - other.global_position
		offset.y = 0.0
		var distance := offset.length()
		if distance < 0.001:
			# Exactly overlapping: pick a random direction to split up.
			offset = Vector3.RIGHT.rotated(Vector3.UP, randf() * TAU)
			distance = 0.001
		push += offset / distance * (1.0 - clampf(distance / _space_radius, 0.0, 1.0))
	return push


## Returns true if we gave up on the current target because we aren't making progress.
func _check_stuck(delta: float) -> bool:
	_stuck_timer -= delta
	if _stuck_timer > 0.0:
		return false
	_stuck_timer = stuck_check_interval
	var moved := global_position.distance_to(_last_check_position)
	_last_check_position = global_position
	if moved >= stuck_distance:
		_stuck_count = 0
		return false

	_stuck_count += 1
	if _stuck_count >= 3:
		# Repeatedly blocked: take a breather before trying again.
		_start_idle()
	else:
		# Head off in a new direction, away from whatever blocked us.
		var away := _get_separation()
		if is_on_wall():
			away += get_wall_normal()
		_start_walk(away)
	return true


func _start_idle() -> void:
	_is_walking = false
	_stuck_count = 0
	_state_timer = randf_range(min_idle_time, max_idle_time)


## Picks a random target near home. If `prefer_direction` is given, the target
## is chosen in that general direction (within ±60°).
func _start_walk(prefer_direction: Vector3 = Vector3.ZERO) -> void:
	prefer_direction.y = 0.0
	var offset: Vector3
	if prefer_direction.length_squared() > 0.0001:
		var angle := randf_range(-PI / 3.0, PI / 3.0)
		offset = prefer_direction.normalized().rotated(Vector3.UP, angle) * randf_range(1.5, 3.5)
		var candidate := global_position + offset - home_position
		candidate.y = 0.0
		# Stay inside the wander area.
		_target = home_position + candidate.limit_length(wander_radius)
	else:
		var angle := randf() * TAU
		var distance := sqrt(randf()) * wander_radius
		_target = home_position + Vector3(cos(angle), 0.0, sin(angle)) * distance
	_is_walking = true
	_state_timer = max_walk_time
	_stuck_timer = stuck_check_interval
	_last_check_position = global_position


func _on_body_entered(body: Node3D) -> void:
	if body != self and body is Actor and not _neighbors.has(body):
		_neighbors.append(body)


func _on_body_exited(body: Node3D) -> void:
	_neighbors.erase(body)
