extends Node3D

@export var camera: Camera3D
@export var character_obj: CharacterBody3D

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("move_to_target"):
		var target_position = get_mouse_floor_position()
		
		if target_position != null:
			print("Clicked Floor at: ", target_position)
		else:
			print("Did not click floor")
	
func get_mouse_floor_position():
	var mouse_pos = get_viewport().get_mouse_position()
	print("Clicked...")
	var ray_origin = camera.project_ray_origin(mouse_pos)
	var ray_direction = camera.project_ray_normal(mouse_pos)
	
	var ray_length = 1000.0
	var ray_end = ray_origin + ray_direction * ray_length
	
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	var result = get_world_3d().direct_space_state.intersect_ray(query)
	
	if result.is_empty():
		return null
		
	var collider = result["collider"]
	
	if collider.is_in_group("floor"):
		return result["position"]
	
	return null
	
