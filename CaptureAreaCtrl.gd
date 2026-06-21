class_name CaptureZone
extends Area3D

@export var team: StringName = &"farmers"
@export var group: StringName = &"sheep"

signal entity_captured(team: StringName)

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if not multiplayer.is_server():
		return
	if not body.is_in_group(group):
		return
	if not body is NetEntity:
		return
	print(team, " captured an entity")
	(body as NetEntity).capture()
	entity_captured.emit(team)
