class_name BoidForce
extends Resource

@export var group: StringName = &"sheep"
@export var weight: float = 1.0
@export var enabled: bool = true

func _compute(agent: Node3D, neighbours: Array[Node3D]) -> Vector3:
	return Vector3.ZERO
	
func compute(agent: Node3D, neighbours: Array[Node3D]) -> Vector3:
	if not enabled:
		return Vector3.ZERO
	return _compute(agent, neighbours) * weight

func _filter_group(agent: Node3D, neighbours: Array[Node3D], group: StringName) -> Array[Node3D]:
	return neighbours.filter(func(n): return n != agent and n.is_in_group(group))
