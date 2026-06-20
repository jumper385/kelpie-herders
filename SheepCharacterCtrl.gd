extends CharacterBody3D

@export var move_speed: float = 2.0
@export var wander_radius: float = 12.0
@export var wait_time_min: float = 0.5
@export var wait_time_max: float = 2.0
@export var gravity: float = 20.0

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D

var waiting := false
var nav_ready := false


func _ready() -> void:
	randomize()

	nav_agent.path_desired_distance = 1
	nav_agent.target_desired_distance = 1

	await wait_for_nav_map_ready()

	nav_ready = true
	pick_new_wander_target()


func wait_for_nav_map_ready() -> void:
	var map := get_world_3d().navigation_map

	while NavigationServer3D.map_get_iteration_id(map) == 0:
		await get_tree().physics_frame
		
	await NavigationServer3D.map_changed

	print("Navigation map is ready")


func pick_new_wander_target() -> void:
	var random_offset := Vector3(
		randf_range(-wander_radius, wander_radius),
		0.0,
		randf_range(-wander_radius, wander_radius)
	)

	var raw_target := global_position + random_offset
	var map := get_world_3d().navigation_map
	var map_target := NavigationServer3D.map_get_closest_point(map, raw_target)

	nav_agent.target_position = map_target

	print("Sheep wandering to: ", map_target)


func _physics_process(delta: float) -> void:
	if not nav_ready:
		return

	if waiting:
		return

	if nav_agent.is_navigation_finished():
		wait_then_pick_new_target()
		return

	var next_path_position := nav_agent.get_next_path_position()

	var direction := next_path_position - global_position
	direction.y = 0.0

	if direction.length() < 0.05:
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		return

	direction = direction.normalized()

	velocity.x = direction.x * move_speed
	velocity.z = direction.z * move_speed

	if not is_on_floor():
		velocity.y -= gravity * delta

	move_and_slide()


func wait_then_pick_new_target() -> void:
	waiting = true

	velocity.x = 0.0
	velocity.z = 0.0

	var wait_time := randf_range(wait_time_min, wait_time_max)
	await get_tree().create_timer(wait_time).timeout

	pick_new_wander_target()
	waiting = false
