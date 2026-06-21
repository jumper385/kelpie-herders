class_name BoidForce_Alignment
extends BoidForce

@export var desired_speed: float = 2.0
@export var max_steer: float = 2.5

func _compute(agent: Node3D, neighbours: Array[Node3D]) -> Vector3:
	var flockmates = _filter_group(agent, neighbours, group)
	var velocities = BoidMath.velocities_of(flockmates)
	return BoidMath.alignment(agent.velocity, velocities, desired_speed, max_steer)
