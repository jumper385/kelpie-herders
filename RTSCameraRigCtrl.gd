extends Node3D

@export var move_speed := 20
@export var rotate_speed := 2.0
@export var mouse_sensitivity := 0.005
@export var zoom_speed := 1.0
@export var min_zoom := 2.0
@export var max_zoom := 40.0
@export var camera: Camera3D
@export var controlled_character: CharacterBody3D

var rotating_with_mouse := false
var pitch := 0.0
var zoom_distance := 10.0  # starting distance, will sync to camera's actual pos in _ready

func _ready() -> void:
	if camera:
		# assume camera sits behind/above rig looking at origin along -Z
		zoom_distance = -camera.position.z

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("move_to_target"):
		var target_position = get_mouse_floor_position()
		if target_position == null:
			print("Did not click floor")
			return
		if controlled_character == null:
			print("No attached control character")
			return
		controlled_character.set_move_target(target_position)

	# --- Middle mouse button drag-to-rotate ---
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			rotating_with_mouse = event.pressed
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED if event.pressed else Input.MOUSE_MODE_VISIBLE)

		# --- Scroll wheel zoom ---
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_distance = clamp(zoom_distance - zoom_speed, min_zoom, max_zoom)
			_apply_zoom()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_distance = clamp(zoom_distance + zoom_speed, min_zoom, max_zoom)
			_apply_zoom()

	if event is InputEventMouseMotion and rotating_with_mouse:
		rotate_y(-event.relative.x * mouse_sensitivity)

		pitch -= event.relative.y * mouse_sensitivity
		pitch = clamp(pitch, -1.4, 1.4)
		if camera:
			camera.rotation.x = pitch

func _apply_zoom() -> void:
	if camera:
		camera.position.z = -zoom_distance

func get_mouse_floor_position():
	var mouse_pos = get_viewport().get_mouse_position()
	var ray_origin = camera.project_ray_origin(mouse_pos)
	var ray_direction = camera.project_ray_normal(mouse_pos)
	var ray_end = ray_origin + ray_direction * 1000.0
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	var result = get_world_3d().direct_space_state.intersect_ray(query)
	if result.is_empty():
		return null
	var collider = result["collider"]
	if collider.is_in_group("floor"):
		return result["position"]
	return null

func _process(delta: float) -> void:
	var input_dir := Vector3.ZERO
	if Input.is_action_pressed("cam_fwd"):
		input_dir.z -= 1
	if Input.is_action_pressed("cam_back"):
		input_dir.z += 1
	if Input.is_action_pressed("cam_left"):
		input_dir.x -= 1
	if Input.is_action_pressed("cam_right"):
		input_dir.x += 1
	input_dir = input_dir.normalized()

	var move_dir := global_transform.basis * input_dir
	move_dir.y = 0
	move_dir = move_dir.normalized()
	global_position += move_dir * move_speed * delta

	if Input.is_action_pressed("cam_rotate_left"):
		rotate_y(rotate_speed * delta)
	if Input.is_action_pressed("cam_rotate_right"):
		rotate_y(-rotate_speed * delta)
