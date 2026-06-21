class_name CaptureZone
extends Area3D

@export var team: StringName = &"farmers"
@export var group: StringName = &"sheep"

signal sheep_captured(team: StringName)

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group(group):
		return
	print(team, " Captured a Sheep")
	body.capture()
	sheep_captured.emit(team)
