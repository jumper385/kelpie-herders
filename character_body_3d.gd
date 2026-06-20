extends CharacterBody3D

@export var speed = 14;
@export var fall_accel = 75;
@export var isDisabled = false;

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D

func set_move_target(pos: Vector3) -> void:
	nav_agent.target_position = pos
	print("Move Target set to ", pos)

func _physics_process(delta: float) -> void:
	
	if isDisabled:
		return
		
	if nav_agent.is_navigation_finished():
		velocity.x = 0
		velocity.y = 0
		move_and_slide()
		
	var next_path_position = nav_agent.get_next_path_position()
	
	var direction = next_path_position - global_position
	direction.y = 0
	direction = direction.normalized()
	
	velocity.x = direction.x * speed;
	velocity.z = direction.z * speed;
	
	if not is_on_floor():
		velocity.y -= fall_accel * delta
	else:
		velocity.y = 0
	
	move_and_slide();
