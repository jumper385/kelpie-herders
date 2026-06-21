class_name BoidMath
extends RefCounted

## Steers away from nearby neighbours, stronger the closer they are.
## radius: only neighbours within this distance contribute.
static func separation(
	self_pos: Vector3,
	neighbour_positions: Array[Vector3],
	radius: float
) -> Vector3:
	var dir := Vector3.ZERO
	var count := 0
	for pos in neighbour_positions:
		var d := self_pos.distance_to(pos)
		if d < radius and d > 0:
			var diff := (self_pos - pos)
			diff.y = 0
			diff = diff.normalized() / d
			dir += diff
			count += 1
	if count > 0:
		dir /= count
	return dir


## Steers toward the average heading/speed of neighbours.
## self_velocity is used to compute a smooth delta rather than snapping.
static func alignment(
	self_velocity: Vector3,
	neighbour_velocities: Array[Vector3],
	desired_speed: float,
	max_steer: float
) -> Vector3:
	var dir := Vector3.ZERO
	var count := 0
	for vel in neighbour_velocities:
		dir += vel
		count += 1
	if count == 0:
		return Vector3.ZERO
	dir /= count
	dir.y = 0
	dir = dir.normalized() * desired_speed
	return (dir - self_velocity).limit_length(max_steer)


## Steers toward the centroid of neighbours.
static func cohesion(
	self_pos: Vector3,
	self_velocity: Vector3,
	neighbour_positions: Array[Vector3],
	desired_speed: float,
	max_steer: float
) -> Vector3:
	if neighbour_positions.is_empty():
		return Vector3.ZERO
	var center := Vector3.ZERO
	for pos in neighbour_positions:
		center += pos
	center /= neighbour_positions.size()
	var desired := (center - self_pos)
	desired.y = 0
	desired = desired.normalized() * desired_speed
	return (desired - self_velocity).limit_length(max_steer)


## Steers away from threats within radius. Same shape as separation but
## kept distinct since "threat" semantics (predators, hazards) often diverge
## from "separation" (flockmates) — e.g. different radius, different falloff.
static func avoid(
	self_pos: Vector3,
	threat_positions: Array[Vector3],
	radius: float
) -> Vector3:
	var dir := Vector3.ZERO
	var count := 0
	for pos in threat_positions:
		var d := self_pos.distance_to(pos)
		if d < radius and d > 0:
			var diff := (self_pos - pos)
			diff.y = 0
			diff = diff.normalized() / d
			dir += diff
			count += 1
	if count > 0:
		dir /= count
	return dir


## A flat random vector in the XZ plane, magnitude in [0, 1] per axis.
static func jitter() -> Vector3:
	return Vector3(randf_range(-1.0, 1.0), 0.0, randf_range(-1.0, 1.0))


## Small shared helper: pull global_position out of a list of nodes.
static func positions_of(nodes: Array[Node3D]) -> Array[Vector3]:
	var out: Array[Vector3] = []
	for n in nodes:
		out.append(n.global_position)
	return out


## Small shared helper: pull `velocity` out of a list of CharacterBody3D-ish nodes.
static func velocities_of(nodes: Array[Node3D]) -> Array[Vector3]:
	var out: Array[Vector3] = []
	for n in nodes:
		out.append(n.velocity)
	return out
