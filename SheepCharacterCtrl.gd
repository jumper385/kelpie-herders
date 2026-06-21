extends CharacterBody3D

@export var move_speed: float = 2.0
@export var gravity: float = 20.0
@export var kelpie_avoid_radius: float = 5.0

# boid configs
@export var separation_weight: float = 5
@export var boid_sep_radius: float = 8
@export var alignment_weight: float = 0.2
@export var cohesion_weight: float =  0.4
@export var avoidance_weight: float = 10.0
@export var random_weight: float = 0.1
@export var boid_radius: float = 8

@onready var neighbour_area: Area3D = $NeighbourDetection

var nav_ready := false
var nav_map: RID


func _ready() -> void:
	randomize()
	nav_map = get_world_3d().navigation_map
	await wait_for_nav_map_ready()
	nav_ready = true


func wait_for_nav_map_ready() -> void:
	while NavigationServer3D.map_get_iteration_id(nav_map) == 0:
		await get_tree().physics_frame
	await NavigationServer3D.map_changed


func calculate_separation(neighbours: Array[Node3D]) -> Vector3:
	var dir := Vector3.ZERO
	var count := 0
	for sheep in neighbours:
		var d := global_position.distance_to(sheep.global_position)
		if d < boid_sep_radius and d > 0:
			var diff := (global_position - sheep.global_position)
			diff.y = 0
			diff = diff.normalized()
			diff /= d
			dir += diff
			count += 1
	if count > 0:
		dir /= count
	return dir

func calculate_threat(neighbours: Array[Node3D]) -> Vector3:
	var dir := Vector3.ZERO
	var count := 0
	for kelpie in neighbours:
		var d = global_position.distance_to(kelpie.global_position)
		if d < kelpie_avoid_radius and d > 0:
			var diff := (global_position - kelpie.global_position)
			diff.y = 0
			diff = diff.normalized()
			diff /= d
			dir += diff
			count += 1
	if count > 0:
		dir /= count
		
	return dir


func calculate_alignment(neighbours: Array[Node3D]) -> Vector3:
	var dir := Vector3.ZERO
	var count := 0

	for sheep in neighbours:
		count += 1
		dir += sheep.velocity

	if count > 0:
		dir /= count
		dir.y = 0
		dir = dir.normalized() * move_speed
		dir = (dir - velocity).limit_length(2.5)

	return dir


func calculate_cohesion(neighbours: Array[Node3D]) -> Vector3:
	var center := Vector3.ZERO
	var count := 0

	for sheep in neighbours:
		center += sheep.global_position
		count += 1

	if count > 0:
		center /= count
		var desired := (center - global_position)
		desired.y = 0
		desired = desired.normalized() * move_speed
		return (desired - velocity).limit_length(2.5)

	return Vector3.ZERO


func calculate_boid_vector(neighbours: Array[Node3D]) -> Vector3:
	
	var good_neighbours = neighbours.filter(func(body): return body != self and body.is_in_group("sheep"))
	var bad_neighbours = neighbours.filter(func(body): return body != self and body.is_in_group("kelpie"))
	
	var threat_v = calculate_threat(bad_neighbours)
	
	var sep_v := calculate_separation(good_neighbours)
	var align_v := calculate_alignment(good_neighbours)
	var cohes_v := calculate_cohesion(good_neighbours)
	
	var random_v = Vector3(
		randf_range(-1, 1),
		0,
		randf_range(-1,1),
	)
	var good_sep = sep_v * separation_weight + align_v * alignment_weight + cohes_v * cohesion_weight + random_v * random_weight
	var bad_sep = threat_v * avoidance_weight
	
	return good_sep + bad_sep

func _physics_process(delta: float) -> void:
	if not nav_ready:
		return

	var neighbours := neighbour_area.get_overlapping_bodies()
	var boid_v := calculate_boid_vector(neighbours)

	# boid_v IS the velocity now — no path-following, no destination
	var target_velocity := Vector3(boid_v.x, 0, boid_v.z) * 3
	velocity.x = lerp(velocity.x, target_velocity.x, 5.0 * delta)
	velocity.z = lerp(velocity.z, target_velocity.z, 5.0 * delta)

	if not is_on_floor():
		velocity.y -= gravity * delta

	# Constrain the intended next position back onto the navmesh
	var intended_pos := global_position + velocity * delta
	var clamped_pos := NavigationServer3D.map_get_closest_point(nav_map, intended_pos)
	# Only correct horizontally — let gravity/move_and_slide still own vertical movement
	var correction := clamped_pos - intended_pos
	correction.y = 0
	velocity.x += correction.x / delta
	velocity.z += correction.z / delta

	if velocity.length() > 0.05:
		var target_angle := atan2(velocity.x, velocity.z)
		rotation.y = lerp_angle(rotation.y, target_angle, 8.0 * delta)

	move_and_slide()
