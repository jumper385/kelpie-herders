extends Node

## Autoload singleton — shared game state across lobby and main scene.
var player_roles: Dictionary = {}  # peer_id (int) -> role (StringName: "farmer" | "butcher")
