extends Node3D

## Scenes for player-controlled entities (one per role, not data-driven).
@export var kelpie_scene: PackedScene

## Data-driven world entities. Add a SpawnConfig resource here for every new
## animal or object type — no code change required.
@export var world_spawn_configs: Array[SpawnConfig] = []

var farmers_score := 0
var butchers_score := 0

@export var farmer_capture_area: CaptureZone
@export var butcher_capture_area: CaptureZone
@export var score_label: Label

var _spawner: MultiplayerSpawner
## type_id -> PackedScene, built from world_spawn_configs at startup.
var _scene_registry: Dictionary = {}


func _ready() -> void:
	# Build scene registry so _do_spawn can look up scenes by type string.
	for cfg: SpawnConfig in world_spawn_configs:
		_scene_registry[cfg.type_id] = cfg.scene

	# All peers need the spawner to receive server-spawned nodes.
	_spawner = MultiplayerSpawner.new()
	_spawner.name = "Spawner"
	_spawner.spawn_function = _do_spawn
	add_child(_spawner)
	_spawner.spawn_path = NodePath("..")

	update_score_text()

	if not multiplayer.is_server():
		return

	# ── Server only ───────────────────────────────────────
	farmer_capture_area.entity_captured.connect(_on_entity_captured)
	butcher_capture_area.entity_captured.connect(_on_entity_captured)

	# Spawn all world entities from the config array.
	for cfg: SpawnConfig in world_spawn_configs:
		for i in range(cfg.count):
			_spawner.spawn({
				"type": cfg.type_id,
				"index": i,
				"x": randf_range(-cfg.spawn_radius, cfg.spawn_radius),
				"z": randf_range(-cfg.spawn_radius, cfg.spawn_radius),
				"spawn_height": cfg.spawn_height,
			})

	# Spawn one kelpie per player who has chosen a team.
	var team_indices: Dictionary = {}  # team -> count spawned so far
	for peer_id: int in GameState.player_teams:
		var team: StringName = GameState.player_teams[peer_id]
		if team == &"" or team == &"spectator":
			continue
		var idx: int = team_indices.get(team, 0)
		team_indices[team] = idx + 1
		_spawner.spawn({
			"type": "kelpie",
			"peer_id": peer_id,
			"team": str(team),
			"team_index": idx,
		})


## Called on ALL peers by the spawner. Looks up the scene by type and delegates
## initial setup to the entity via _on_spawn().
## To support a new entity type: add its SpawnConfig to world_spawn_configs —
## this function does not need to change.
func _do_spawn(data: Dictionary) -> Node:
	var type: String = data["type"]

	if type == "kelpie":
		return _spawn_kelpie(data)

	if not _scene_registry.has(type):
		push_error("Unknown spawn type '%s'. Add a SpawnConfig to world_spawn_configs." % type)
		return null

	var node: Node = (_scene_registry[type] as PackedScene).instantiate()
	node.name = "%s_%d" % [type.capitalize(), data.get("index", 0)]
	if node is NetEntity:
		(node as NetEntity)._on_spawn(data)
	return node


func _spawn_kelpie(data: Dictionary) -> KelpieCharacterCtrl:
	var kelpie: KelpieCharacterCtrl = kelpie_scene.instantiate()
	kelpie.name = "Kelpie_%d" % data["peer_id"]
	kelpie._on_spawn(data)
	return kelpie


# ── Score ─────────────────────────────────────────────────────────────────────

func _on_entity_captured(team: StringName) -> void:
	if team == &"farmers":
		farmers_score += 1
	else:
		butchers_score += 1
	print("Score — Farmers: %d  Butchers: %d" % [farmers_score, butchers_score])
	_rpc_sync_score.rpc(farmers_score, butchers_score)


@rpc("authority", "call_local", "reliable")
func _rpc_sync_score(farmers: int, butchers: int) -> void:
	farmers_score = farmers
	butchers_score = butchers
	update_score_text()


func update_score_text() -> void:
	score_label.text = "Farmers: %d  Butchers: %d" % [farmers_score, butchers_score]
