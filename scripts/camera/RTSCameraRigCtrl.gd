extends Node3D

@export var move_speed := 20
@export var rotate_speed := 2.0
@export var mouse_sensitivity := 0.005
@export var zoom_speed := 1.0
@export var min_zoom := 0.1
@export var max_zoom := 400
@export var pan_speed := 1.0
@export var camera: Camera3D
@export var controlled_character: KelpieCharacterCtrl

var panning_with_mouse := false
var zoom_distance := 10.0  # starting distance, will sync to camera's actual pos in _ready

func _ready() -> void:
	add_to_group("camera_rig")
	if camera:
		zoom_distance = camera.position.length()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("move_to_target"):
		var target_position = get_mouse_floor_position()
		if target_position == null:
			print("Did not click floor")
			return
		if controlled_character == null:
			print("No attached control character")
			return
		if multiplayer.is_server():
			controlled_character.set_move_target(target_position)
		else:
			controlled_character.request_move.rpc_id(1, target_position)

	# --- Middle mouse button drag-to-pan ---
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			panning_with_mouse = event.pressed

		# --- Scroll wheel zoom ---
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_distance = clamp(zoom_distance - zoom_speed, min_zoom, max_zoom)
			_apply_zoom()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_distance = clamp(zoom_distance + zoom_speed, min_zoom, max_zoom)
			_apply_zoom()

	# --- Trackpad pinch-to-zoom ---
	if event is InputEventMagnifyGesture:
		zoom_distance = clamp(zoom_distance / event.factor, min_zoom, max_zoom)
		_apply_zoom()

	if event is InputEventMouseMotion and panning_with_mouse:
		var pan_scale = zoom_distance * pan_speed * mouse_sensitivity
		var right = global_transform.basis.x
		right.y = 0
		if right.length() > 0.001:
			right = right.normalized()
		var fwd = -global_transform.basis.z
		fwd.y = 0
		if fwd.length() > 0.001:
			fwd = fwd.normalized()
		global_position += right * event.relative.x * pan_scale
		global_position -= fwd * event.relative.y * pan_scale

func _apply_zoom() -> void:
	if camera:
		camera.position = camera.position.normalized() * zoom_distance

func get_mouse_floor_position():
	var mouse_pos = get_viewport().get_mouse_position()
	var ray_origin = camera.project_ray_origin(mouse_pos)
	var ray_direction = camera.project_ray_normal(mouse_pos)
	var ray_end = ray_origin + ray_direction * 1000.0
	var space = get_world_3d().direct_space_state
	var exclude: Array[RID] = []
	for i in 32:
		var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
		query.exclude = exclude
		var result = space.intersect_ray(query)
		if result.is_empty():
			return null
		if result["collider"].is_in_group("floor"):
			return result["position"]
		exclude.append(result["rid"])
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
