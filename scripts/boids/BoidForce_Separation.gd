class_name BoidForce_Separation
extends BoidForce

@export var radius: float = 8.0

func _compute(agent: Node3D, neighbours: Array[Node3D]) -> Vector3:
	var flockmates = _filter_group(agent, neighbours, group)
	var positions = BoidMath.positions_of(flockmates)
	return BoidMath.separation(agent.global_position, positions, radius)
