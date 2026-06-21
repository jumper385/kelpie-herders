class_name BoidForce_RandomJitter
extends BoidForce

func _compute(agent: Node3D, neighbours: Array[Node3D]) -> Vector3:
	return BoidMath.jitter()
