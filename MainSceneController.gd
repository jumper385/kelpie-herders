extends Node3D

@export var sheep_scene: PackedScene
@export var sheep_count: int = 10
@export var spawn_radius: float = 10.0 

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for i in range(sheep_count):
		var sheep := sheep_scene.instantiate()
		add_child(sheep)
		
		var offset := Vector3(
			randf_range(-spawn_radius, spawn_radius), 
			2,
			randf_range(-spawn_radius, spawn_radius)
		)
		
		sheep.global_position = global_position + offset
		sheep.add_to_group("sheep")
		
func _process(delta: float) -> void:
	pass
