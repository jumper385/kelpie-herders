extends Node

## Autoload singleton — shared game state across lobby and main scene.
## team values: &"farmers" | &"butchers" | &"" (not yet chosen)
var player_teams: Dictionary = {}  # peer_id (int) -> team (StringName)
