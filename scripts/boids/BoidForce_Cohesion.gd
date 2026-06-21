class_name BoidForce_Cohesion
extends BoidForce
 
@export var desired_speed: float = 2.0
@export var max_steer: float = 2.5
 
 
func _compute(agent: Node3D, neighbours: Array[Node3D]) -> Vector3:
	var flockmates := _filter_group(agent, neighbours, group)
	var positions := BoidMath.positions_of(flockmates)
	return BoidMath.cohesion(agent.global_position, agent.velocity, positions, desired_speed, max_steer)
