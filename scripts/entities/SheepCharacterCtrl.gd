extends NetEntity

@export var move_speed: float = 2.0
@export var gravity: float = 20.0
@export var forces: Array[BoidForce] = []

@onready var neighbour_area: Area3D = $NeighbourDetection

var nav_ready := false
var nav_map: RID


# ── NetEntity hooks ───────────────────────────────────────────────────────────

func _get_sync_interval() -> float:
	return 0.02  # 60 Hz — enough for flocking visuals


func _on_spawn(data: Dictionary) -> void:
	add_to_group("sheep")
	position = Vector3(data.get("x", 0.0), data.get("spawn_height", 2.0), data.get("z", 0.0))


func _net_disable_physics() -> void:
	super()  # zeros self collision_layer / collision_mask
	neighbour_area.collision_layer = 0
	neighbour_area.collision_mask = 0


func _net_ready() -> void:
	if not multiplayer.is_server():
		return
	randomize()
	nav_map = get_world_3d().navigation_map
	await wait_for_nav_map_ready()
	nav_ready = true


func _on_captured() -> void:
	remove_from_group("sheep")


# ── Navigation helpers ────────────────────────────────────────────────────────

func wait_for_nav_map_ready() -> void:
	while NavigationServer3D.map_get_iteration_id(nav_map) == 0:
		await get_tree().physics_frame
	await NavigationServer3D.map_changed


func calculate_boid_vector(neighbours: Array[Node3D]) -> Vector3:
	var total := Vector3.ZERO
	for force in forces:
		if force == null:
			continue
		total += force.compute(self, neighbours)
	return total


# ── Physics (server only) ─────────────────────────────────────────────────────

func _physics_process(delta: float) -> void:
	if not multiplayer.is_server():
		return
	if not nav_ready:
		return

	var neighbours: Array[Node3D] = []
	neighbours.assign(neighbour_area.get_overlapping_bodies())
	var boid_v := calculate_boid_vector(neighbours)

	var target_velocity := Vector3(boid_v.x, 0, boid_v.z) * move_speed
	velocity.x = lerp(velocity.x, target_velocity.x, 5.0 * delta)
	velocity.z = lerp(velocity.z, target_velocity.z, 5.0 * delta)

	if not is_on_floor():
		velocity.y -= gravity * delta

	# Constrain the intended next position back onto the navmesh
	var intended_pos := global_position + velocity * delta
	var clamped_pos := NavigationServer3D.map_get_closest_point(nav_map, intended_pos)
	var correction := clamped_pos - intended_pos
	correction.y = 0
	velocity.x += correction.x / delta
	velocity.z += correction.z / delta

	if velocity.length() > 0.05:
		var target_angle := atan2(velocity.x, velocity.z)
		rotation.y = lerp_angle(rotation.y, target_angle, 8.0 * delta)

	move_and_slide()
