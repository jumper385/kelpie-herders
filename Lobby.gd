extends Control

const PORT = 7777
const MAIN_SCENE = "res://node_3d.tscn"

var _connection_panel: Control
var _role_panel: Control
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
	vbox.custom_minimum_size = Vector2(320, 0)
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

	# ── Role panel (shown after connection) ───────────────
	_role_panel = VBoxContainer.new()
	_role_panel.add_theme_constant_override("separation", 8)
	_role_panel.visible = false
	vbox.add_child(_role_panel)

	var role_lbl := Label.new()
	role_lbl.text = "Choose Your Role:"
	role_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_role_panel.add_child(role_lbl)

	var farmer_btn := Button.new()
	farmer_btn.text = "Farmer  (herd sheep into the barn)"
	farmer_btn.pressed.connect(_on_role_selected.bind(&"farmer"))
	_role_panel.add_child(farmer_btn)

	var butcher_btn := Button.new()
	butcher_btn.text = "Butcher  (herd sheep to the slaughterhouse)"
	butcher_btn.pressed.connect(_on_role_selected.bind(&"butcher"))
	_role_panel.add_child(butcher_btn)


# ── Networking ────────────────────────────────────────────────────────────────

func _on_host_pressed() -> void:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(PORT)
	if err != OK:
		_status_label.text = "Failed to host (error %d)" % err
		return
	multiplayer.multiplayer_peer = peer
	_connection_panel.visible = false
	_role_panel.visible = true
	_status_label.text = "Hosting on port %d — waiting for opponent..." % PORT


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
	_role_panel.visible = true
	_status_label.text = "Connected! Choose your role."


func _on_connection_failed() -> void:
	_connection_panel.visible = true
	_role_panel.visible = false
	_status_label.text = "Connection failed."


func _on_peer_connected(id: int) -> void:
	_status_label.text = "Player %d joined." % id


func _on_peer_disconnected(id: int) -> void:
	_status_label.text = "Player %d disconnected." % id


# ── Role selection ────────────────────────────────────────────────────────────

func _on_role_selected(role: StringName) -> void:
	_role_panel.visible = false
	_status_label.text = "Role chosen — waiting for other player..."
	if multiplayer.is_server():
		_receive_role(1, role)
	else:
		_rpc_submit_role.rpc_id(1, role)


## Clients call this on the server to submit their role choice.
@rpc("any_peer", "call_remote", "reliable")
func _rpc_submit_role(role: StringName) -> void:
	if not multiplayer.is_server():
		return
	_receive_role(multiplayer.get_remote_sender_id(), role)


func _receive_role(peer_id: int, role: StringName) -> void:
	GameState.player_roles[peer_id] = role
	print("Player %d chose: %s  (total ready: %d)" % [peer_id, role, GameState.player_roles.size()])
	if GameState.player_roles.size() >= 2:
		_rpc_start_game.rpc()


## Server broadcasts: start the match.
@rpc("authority", "call_local", "reliable")
func _rpc_start_game() -> void:
	get_tree().change_scene_to_file(MAIN_SCENE)
