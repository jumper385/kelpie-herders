class_name KelpieCharacterCtrl
extends CharacterBody3D

@export var speed: float = 14.0
@export var fall_accel: float = 75.0
@export var is_disabled: bool = false

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D

func set_move_target(pos: Vector3) -> void:
	nav_agent.target_position = pos

func _physics_process(delta: float) -> void:
	if is_disabled:
		return

	if nav_agent.is_navigation_finished():
		velocity.x = 0
		velocity.y = 0
		move_and_slide()
		return

	var next_path_position := nav_agent.get_next_path_position()
	var direction := (next_path_position - global_position)
	direction.y = 0
	direction = direction.normalized()

	velocity.x = direction.x * speed
	velocity.z = direction.z * speed

	if not is_on_floor():
		velocity.y -= fall_accel * delta
	else:
		velocity.y = 0

	move_and_slide()
