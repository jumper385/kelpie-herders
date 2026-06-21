class_name BoidForce_Avoidance
extends BoidForce

@export var radius: float = 5.0
 
func _compute(agent: Node3D, neighbours: Array[Node3D]) -> Vector3:
	var threats := _filter_group(agent, neighbours, group)
	var positions := BoidMath.positions_of(threats)
	return BoidMath.avoid(agent.global_position, positions, radius)
