## Base class for every networked physics entity (sheep, kelpie, future animals…).
##
## What it does once so subclasses never have to:
##   • Adds a MultiplayerSynchronizer that replicates position/rotation server→clients.
##   • Strips all collision layers on clients so the physics engine ignores them.
##   • Provides capture() / _rpc_despawn for anything a CaptureZone can consume.
##
## Authoring a new entity:
##   1. Create a CharacterBody3D scene, attach a script that extends NetEntity.
##   2. Override _get_sync_interval() if you want throttled sync (e.g. 0.1 for 10 Hz).
##   3. Override _on_spawn(data)  — called before add_child, set initial position/state.
##   4. Override _net_ready()     — called inside _ready(), after node is in the tree.
##   5. Override _net_disable_physics() if you have extra Area3D children to silence.
##   6. Override _on_captured()   if you need cleanup before the node is freed.
class_name NetEntity
extends CharacterBody3D


# ── Interpolation state ──────────────────────────────────────────────────────

## Last position/rotation received from the server (written by the synchronizer).
## Clients lerp their visual position toward these each render frame.
var _net_pos: Vector3 = Vector3.ZERO
var _net_rot: Vector3 = Vector3.ZERO


# ── Virtual hooks ─────────────────────────────────────────────────────────────

## Properties to sync every interval. Override to change or extend the list.
func _get_sync_properties() -> Array[String]:
	return ["_net_pos", "_net_rot"]


## Replication interval in seconds. 0 = every physics frame.
## Override to throttle (e.g. return 0.1 for 10 Hz).
func _get_sync_interval() -> float:
	return 0.0


## Called by the spawner on ALL peers, before add_child, with the raw spawn dict.
## Use this to set initial position, peer ownership, groups, etc.
## Do NOT call get_tree() here — the node is not yet in the scene tree.
func _on_spawn(_data: Dictionary) -> void:
	pass


## Runs at the end of _ready() on all peers.
## The node is in the scene tree here — safe to call get_tree(), get_node(), etc.
func _net_ready() -> void:
	pass


## Called on clients in _ready() to disable physics participation.
## Override to also silence child Area3D nodes (see SheepCharacterCtrl for example).
func _net_disable_physics() -> void:
	collision_layer = 0
	collision_mask = 0


## Called by CaptureZone.capture() on the server just before this node is freed.
## Override to remove groups, emit signals, etc.
func _on_captured() -> void:
	pass


# ── Engine entry point ────────────────────────────────────────────────────────

func _ready() -> void:
	# Seed staging vars from the spawn position so the first lerp is a no-op.
	_net_pos = global_position
	_net_rot = rotation
	_net_setup_replication()
	if not multiplayer.is_server():
		_net_disable_physics()
	_net_ready()


func _process(delta: float) -> void:
	if multiplayer.is_server():
		# Keep staging vars current so the synchronizer always sends fresh data.
		_net_pos = global_position
		_net_rot = rotation
	else:
		# For throttled entities (e.g. sheep at 10 Hz), smoothly chase the last
		# received position instead of snapping, eliminating visible jitter.
		if _get_sync_interval() > 0.0:
			var t := clamp(delta * 20.0, 0.0, 1.0)
			global_position = global_position.lerp(_net_pos, t)
			rotation.y = lerp_angle(rotation.y, _net_rot.y, t)
		else:
			# Full-rate entities (e.g. kelpie): snap directly, no added lag.
			global_position = _net_pos
			rotation = _net_rot


# ── Replication (internal) ────────────────────────────────────────────────────

func _net_setup_replication() -> void:
	var config := SceneReplicationConfig.new()
	for prop in _get_sync_properties():
		var path := NodePath(".:" + prop)
		config.add_property(path)
		config.property_set_spawn(path, true)
		config.property_set_replication_mode(path, SceneReplicationConfig.REPLICATION_MODE_ALWAYS)
	var sync := MultiplayerSynchronizer.new()
	sync.replication_config = config
	var interval := _get_sync_interval()
	if interval > 0.0:
		sync.replication_interval = interval
	add_child(sync)


# ── Capture / despawn ─────────────────────────────────────────────────────────

## Called by CaptureZone when this entity enters a capture area (server only).
func capture() -> void:
	if not multiplayer.is_server():
		return
	_on_captured()
	_rpc_despawn.rpc()
	queue_free()


## Removes this entity on all clients when captured.
@rpc("authority", "call_remote", "reliable")
func _rpc_despawn() -> void:
	queue_free()
