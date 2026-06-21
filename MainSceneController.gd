extends Node3D

@export var sheep_scene: PackedScene
@export var sheep_count: int = 10
@export var spawn_radius: float = 10.0 

var farmers_score := 0
var butchers_score := 0

@export var farmer_capture_area: CaptureZone
@export var butcher_capture_area: CaptureZone
@export var score_label: Label

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	farmer_capture_area.sheep_captured.connect(_on_sheep_captured)
	butcher_capture_area.sheep_captured.connect(_on_sheep_captured)

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
		
	update_score_text()
		
func _process(delta: float) -> void:
	pass

func _on_sheep_captured(team: StringName) -> void:
	if team == &"farmers":
		farmers_score += 1
	else:
		butchers_score += 1
	print("Score — Farmers: %d  Butchers: %d" % [farmers_score, butchers_score])

	update_score_text()

func update_score_text() -> void:
	score_label.text = "Farmers: %d  Butchers: %d" % [
		farmers_score,
		butchers_score
	]
