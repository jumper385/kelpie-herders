## Describes one batch of world entities for WorldController to spawn.
##
## To add a new animal or plant:
##   1. Create its scene and script (extending NetEntity).
##   2. Duplicate this resource (or create a new one) and point 'scene' at the new scene.
##   3. Add the resource to WorldController's 'world_spawn_configs' array in the editor.
##   That's it — no code changes needed.
class_name SpawnConfig
extends Resource

## Identifier used in spawn data packets. Must be unique across all configs.
@export var type_id: String = ""

## The PackedScene to instantiate for each member of this batch.
@export var scene: PackedScene

## How many instances to spawn at game start.
@export var count: int = 0

## Half-width of the random scatter area (XZ plane) around the world origin.
@export var spawn_radius: float = 10.0

## Y position to place each spawned instance at.
@export var spawn_height: float = 2.0
