extends Control

const PORT = 7777
const MAIN_SCENE = "res://node_3d.tscn"

var _connection_panel: Control
var _lobby_panel: Control
var _start_btn: Button
var _player_list_container: VBoxContainer
var _ip_input: LineEdit
var _status_label: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()

	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)


func _build_ui() -> void:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var vbox := VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(400, 0)
	vbox.add_theme_constant_override("separation", 12)
	center.add_child(vbox)

	var title := Label.new()
	title.text = "Kelpie Herders"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	_status_label = Label.new()
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_status_label)

	# ── Connection panel ──────────────────────────────────
	_connection_panel = VBoxContainer.new()
	_connection_panel.add_theme_constant_override("separation", 8)
	vbox.add_child(_connection_panel)

	_ip_input = LineEdit.new()
	_ip_input.placeholder_text = "Server IP (leave blank for localhost)"
	_ip_input.text = "127.0.0.1"
	_connection_panel.add_child(_ip_input)

	var host_btn := Button.new()
	host_btn.text = "Host Game"
	host_btn.pressed.connect(_on_host_pressed)
	_connection_panel.add_child(host_btn)

	var join_btn := Button.new()
	join_btn.text = "Join Game"
	join_btn.pressed.connect(_on_join_pressed)
	_connection_panel.add_child(join_btn)

	# ── Lobby panel (shown after connection) ──────────────
	_lobby_panel = VBoxContainer.new()
	_lobby_panel.add_theme_constant_override("separation", 8)
	_lobby_panel.visible = false
	vbox.add_child(_lobby_panel)

	var players_lbl := Label.new()
	players_lbl.text = "Players in Lobby:"
	players_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lobby_panel.add_child(players_lbl)

	_player_list_container = VBoxContainer.new()
	_player_list_container.add_theme_constant_override("separation", 4)
	_lobby_panel.add_child(_player_list_container)

	_lobby_panel.add_child(HSeparator.new())

	var team_lbl := Label.new()
	team_lbl.text = "Choose Your Team:"
	team_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lobby_panel.add_child(team_lbl)

	var team_hbox := HBoxContainer.new()
	team_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	team_hbox.add_theme_constant_override("separation", 12)
	_lobby_panel.add_child(team_hbox)

	var farmers_btn := Button.new()
	farmers_btn.text = "Join Farmers"
	farmers_btn.pressed.connect(_on_team_selected.bind(&"farmers"))
	team_hbox.add_child(farmers_btn)

	var butchers_btn := Button.new()
	butchers_btn.text = "Join Butchers"
	butchers_btn.pressed.connect(_on_team_selected.bind(&"butchers"))
	team_hbox.add_child(butchers_btn)

	var spectate_btn := Button.new()
	spectate_btn.text = "Spectate"
	spectate_btn.pressed.connect(_on_team_selected.bind(&"spectator"))
	team_hbox.add_child(spectate_btn)

	_start_btn = Button.new()
	_start_btn.text = "Start Game"
	_start_btn.visible = false
	_start_btn.pressed.connect(_on_start_pressed)
	_lobby_panel.add_child(_start_btn)


# ── Networking ────────────────────────────────────────────────────────────────

func _on_host_pressed() -> void:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(PORT)
	if err != OK:
		_status_label.text = "Failed to host (error %d)" % err
		return
	multiplayer.multiplayer_peer = peer
	GameState.player_teams[1] = &""
	_connection_panel.visible = false
	_lobby_panel.visible = true
	_start_btn.visible = true
	_status_label.text = "Hosting on port %d — waiting for players..." % PORT
	_refresh_player_list()


func _on_join_pressed() -> void:
	var ip := _ip_input.text.strip_edges()
	if ip.is_empty():
		ip = "127.0.0.1"
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(ip, PORT)
	if err != OK:
		_status_label.text = "Failed to connect (error %d)" % err
		return
	multiplayer.multiplayer_peer = peer
	_connection_panel.visible = false
	_status_label.text = "Connecting to %s..." % ip


func _on_connected_to_server() -> void:
	_lobby_panel.visible = true
	_status_label.text = "Connected! Choose your team."


func _on_connection_failed() -> void:
	_connection_panel.visible = true
	_lobby_panel.visible = false
	_status_label.text = "Connection failed."


func _on_peer_connected(id: int) -> void:
	if multiplayer.is_server():
		GameState.player_teams[id] = &""
		_broadcast_lobby_state()


func _on_peer_disconnected(id: int) -> void:
	GameState.player_teams.erase(id)
	if multiplayer.is_server():
		_broadcast_lobby_state()


# ── Team selection ────────────────────────────────────────────────────────────

func _on_team_selected(team: StringName) -> void:
	if multiplayer.is_server():
		_receive_team(1, team)
	else:
		_rpc_submit_team.rpc_id(1, team)


## Clients send their team choice to the server.
@rpc("any_peer", "call_remote", "reliable")
func _rpc_submit_team(team: StringName) -> void:
	if not multiplayer.is_server():
		return
	_receive_team(multiplayer.get_remote_sender_id(), team)


func _receive_team(peer_id: int, team: StringName) -> void:
	GameState.player_teams[peer_id] = team
	_broadcast_lobby_state()


func _broadcast_lobby_state() -> void:
	var ids: Array = GameState.player_teams.keys()
	var teams: Array = GameState.player_teams.values()
	_rpc_update_lobby.rpc(ids, teams)


## Server pushes the full lobby state to all peers (including itself).
@rpc("authority", "call_local", "reliable")
func _rpc_update_lobby(ids: Array, teams: Array) -> void:
	GameState.player_teams.clear()
	for i in range(ids.size()):
		GameState.player_teams[ids[i]] = teams[i]
	_refresh_player_list()


func _refresh_player_list() -> void:
	for child in _player_list_container.get_children():
		child.queue_free()
	var my_id := multiplayer.get_unique_id()
	for peer_id: int in GameState.player_teams:
		var team: StringName = GameState.player_teams[peer_id]
		var row := Label.new()
		var name_str := "Player %d" % peer_id
		if peer_id == 1:
			name_str += " (Host)"
		if peer_id == my_id:
			name_str += " (You)"
		var team_str: String = team if team != &"" else "no team"
		row.text = "%s — %s" % [name_str, team_str]
		_player_list_container.add_child(row)


# ── Start game (host only) ────────────────────────────────────────────────────

func _on_start_pressed() -> void:
	if not multiplayer.is_server():
		return
	var has_player := false
	for team: StringName in GameState.player_teams.values():
		if team == &"farmers" or team == &"butchers":
			has_player = true
			break
	if not has_player:
		_status_label.text = "At least one player must join Farmers or Butchers before starting."
		return
	_rpc_start_game.rpc()


## Server broadcasts: everyone loads the main scene.
@rpc("authority", "call_local", "reliable")
func _rpc_start_game() -> void:
	get_tree().change_scene_to_file(MAIN_SCENE)
