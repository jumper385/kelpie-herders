class_name KelpieCharacterCtrl
extends NetEntity

@export var speed: float = 14.0
@export var fall_accel: float = 75.0
@export var is_disabled: bool = false

## Peer whose inputs drive this kelpie. Set via _on_spawn before add_child.
var player_peer_id: int = 1

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D


# ── NetEntity hooks ───────────────────────────────────────────────────────────

func _on_spawn(data: Dictionary) -> void:
	player_peer_id = data.get("peer_id", 1)
	add_to_group("kelpie")
	var team: String = data.get("team", "farmers")
	var idx: int = data.get("team_index", 0)
	# Stagger multiple kelpies on the same team so they don't overlap.
	var offset := Vector3(idx * 3.0, 0.0, idx * 3.0)
	if team == "farmers":
		position = Vector3(-30.0, 1.0, -30.0) + offset
	else:
		position = Vector3(30.0, 1.0, 30.0) - offset


func _net_ready() -> void:
	# Attach to the local camera rig if this kelpie belongs to this peer.
	if player_peer_id == multiplayer.get_unique_id():
		var rig := get_tree().get_first_node_in_group("camera_rig")
		if rig:
			rig.controlled_character = self


# ── Movement target (server-side) ─────────────────────────────────────────────

func set_move_target(pos: Vector3) -> void:
	nav_agent.target_position = pos


## Clients call this (via rpc_id(1, …)) to ask the server to move their kelpie.
@rpc("any_peer", "call_remote", "reliable")
func request_move(pos: Vector3) -> void:
	if multiplayer.get_remote_sender_id() != player_peer_id:
		return
	nav_agent.target_position = pos


# ── Physics (server only) ─────────────────────────────────────────────────────

func _physics_process(delta: float) -> void:
	if not multiplayer.is_server():
		return
	if is_disabled:
		return

	if nav_agent.is_navigation_finished():
		velocity.x = 0
		velocity.y = 0
		move_and_slide()

	var next_path_position := nav_agent.get_next_path_position()
	var direction := (next_path_position - global_position)
	direction.y = 0
	direction = direction.normalized()

	velocity.x = direction.x * speed
	velocity.z = direction.z * speed

	if not is_on_floor():
		velocity.y -= fall_accel * delta
	else:
		velocity.y = 0

	move_and_slide()
