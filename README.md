# Kelpie Herders — Game Spec

> Working title. Replace once something better turns up.

## 1. Concept

A team-based multiplayer 3D herding game. Two teams — **Shearers** (blue) and
**Butchers** (red) — each control a pack of kelpie dogs. A shared flock of
sheep wanders the map. Each team's kelpies try to herd as many sheep as
possible into their own capture zone before time runs out:

- **Shearers** drive sheep into the **Barn** (sheared, released back onto
  the map afterwards — see open question in §6).
- **Butchers** drive sheep into the **Butcher's block** (removed from play
  permanently).

The tension: both teams are working the *same* flock. A sheep herded toward
the barn can be intercepted and redirected toward the butcher's block by an
opposing kelpie, and vice versa. Whoever reads the flock and positions
better wins the sheep, not whoever clicks fastest.

## 2. Core gameplay loop

1. Match starts. Sheep spawn in the center of the map, idle/wandering.
2. Each player controls one kelpie (5+ players per team).
3. Player moves their **camera** with WASD, independent of their kelpie.
4. Player **right-clicks** a point on the terrain to send their kelpie
   there (RTS-style point-and-click order, not direct character control).
5. Sheep within a kelpie's influence radius flee away from it. No direct
   "grab" mechanic — all influence is positional pressure.
6. Players use kelpie positioning to peel sheep off the flock and push them
   toward their zone, ideally while blocking the opposing team from doing
   the same.
7. A sheep that enters a capture zone is removed from the open flock and
   scored for that team.
8. Match ends on a timer. Most sheep captured wins.

## 3. Controls

| Input | Action |
|---|---|
| W/A/S/D | Move camera rig across the terrain |
| Mouse drag / edge pan (TBD) | Rotate or pan camera |
| Right-click on terrain | Order own kelpie to move to that point |
| (Possible later) Left-click | Select own kelpie if multiple are ever allowed per player — not in v1 |

Each player controls exactly **one kelpie** in v1. Camera and kelpie
movement are decoupled — you can look around without moving your dog.

## 4. Entities

### Sheep
- Simple flocking agent (boids: separation, cohesion, alignment).
- Flees from any kelpie within a radius, regardless of team.
- No individual sheep AI beyond flocking + flee — intentionally dumb.
  Emergent herding difficulty comes from flock *behavior*, not scripted
  sheep intelligence.
- States: `Idle/Wandering → Fleeing → Captured`.

### Kelpie
- One per player.
- Moves via pathfinding to a right-clicked world point.
- Has a fixed influence radius (sheep within it feel flee pressure).
- No abilities beyond movement in v1 — bark/sprint/etc. are stretch goals
  (see §6).

### Capture zones
- Barn (Shearer scoring zone) and Butcher's block (Butcher scoring zone).
- Fixed locations, likely on opposite sides of the map.
- Sheep entering either zone are removed from the simulated flock and
  tallied to the owning team.

## 5. Scale & technical targets

These numbers drive architecture decisions, so they're treated as fixed
requirements rather than flavor:

- **Players per match:** 10+ (5v5 or larger).
- **Sheep per match:** ~50 for prototype; scale up later.
- **Dimension:** 3D, top-down/angled RTS-style camera.
- **Networking model:** Listen-server (one player hosts), written so the
  simulation logic is server-authoritative throughout — portable to a
  dedicated headless server build later without a rewrite.
- **Engine:** Godot 4.x.

Architectural approach: sheep are individual `CharacterBody3D` scene
instances with boid behaviour composed from `BoidForce` resources; kelpies
are also individual scene instances. A `MultiMeshInstance3D` / spatial-grid
approach is a future optimisation if 50-sheep prototype performance warrants
it — not a current requirement.

## 6. Open questions / design TBD

These are flagged so they don't get silently decided by accident as code
gets written — worth a deliberate call before they're load-bearing:

- **Does the barn return sheep to the map after shearing?** If yes, sheep
  become a renewable resource and the match dynamic shifts toward sustained
  control of barn-adjacent territory. If no (sheared sheep are also
  removed, just scored differently than butchered ones), it's a pure
  race to deplete a fixed flock. Affects pacing significantly — decide
  before tuning match length.
- **Do kelpies on the same team interfere with each other?** I.e. does
  overlapping flee-radius from two friendly kelpies cause sheep to scatter
  unpredictably? Leaning toward **yes, let it happen** — it's a great
  emergent skill ceiling (team coordination matters, not just individual
  herding) — but worth confirming once it's playable, since it could also
  just feel like friendly-fire frustration.
- **Can sheep be stolen mid-herd?** I.e. can a Butcher kelpie cut off a
  flock already being pushed toward the barn and redirect it? Current
  assumption is yes by default (no special mechanic needed — it falls out
  naturally from flee-from-any-kelpie behavior), but confirm this feels
  good in practice rather than chaotic.
- **Match length and win condition exact numbers** — timer length, sheep
  count, score-to-win vs most-at-timeout. Needs playtesting, not a desk
  decision.
- **Terrain variation** — flat plane for v1 (confirmed), but is hilly/
  obstacle terrain a v2 goal? Affects nav-mesh baking complexity and
  whether sheep boids need line-of-sight checks around obstacles.
- **Kelpie abilities beyond movement** — bark (wider/stronger fear pulse),
  sprint (temporary speed boost with cooldown), or similar. Not in v1
  scope; flagged here so the kelpie class can be built in a way that's
  easy to extend rather than needing rework if these get added.
- **Cosmetic/identity layer** — per-player kelpie color/skin so teammates
  and opponents are visually distinguishable beyond team color. Not
  functionally important but worth a placeholder (e.g. a colored collar)
  early so playtesting with friends isn't confusing about who's who.

## 7. Non-goals (v1)

Explicitly out of scope for the first playable version, to keep early
development focused:

- Ranked/competitive matchmaking, persistent accounts, progression systems.
- More than two teams.
- Sheep breeds/variation, multiple animal types.
- Mobile or controller input.
- Hilly/complex terrain, weather, day-night cycle.
- Voice chat or in-game text chat (assume external comms for playtesting).

---

## 8. Implementation status

> This section tracks what is built, what matches the spec, and what is outstanding.

### ✅ Implemented

| Feature | Spec ref | Notes |
|---|---|---|
| Sheep flocking (boids) | §4 Sheep | Separation, cohesion, alignment, random jitter, flee from kelpie; composable `BoidForce` resources |
| Navmesh-constrained sheep movement | §5 | Sheep position clamped to NavigationRegion3D every tick |
| Kelpie pathfinding | §4 Kelpie | `NavigationAgent3D`; right-click sends kelpie to terrain point |
| RTS camera | §3 | WASD pan, Q/E rotate, scroll / pinch zoom, middle-mouse drag-pan |
| Two capture zones | §4 Zones | Barn (farmer) and Butcher's block; sheep that enter are scored and removed |
| Score HUD | §2 step 7 | Live score label; updates on all clients via RPC |
| Listen-server networking | §5 | ENet, one player hosts; portable to dedicated server later |
| Server-authoritative simulation | §5 | All sheep boids and kelpie pathfinding run **only** on the server |
| Position sync (server → clients) | §5 | `MultiplayerSynchronizer` per entity; kelpies every frame, sheep at 10 Hz |
| Client physics strip | §5 | Collision layers zeroed on clients — no per-sheep overlap checks off-server |
| Move orders via RPC | §3 | Right-click → `request_move.rpc_id(1, pos)`; server validates sender owns that kelpie |
| Lobby (host / join / role select) | §2 | ENet connect/listen; player selects Farmer or Butcher before game starts |
| `GameState` singleton | §5 | Autoloaded; persists `player_roles` across scene changes |
| `NetEntity` base class | §5 | Replication, client strip, `capture()` / `_rpc_despawn` shared by all entity types |
| Data-driven spawning (`SpawnConfig`) | §5 | New animal type = new `.tres` file + inspector entry, no code change |

### ⚠️ Partial / diverges from spec

| Item | Spec | Current state |
|---|---|---|
| Team names | "Shearers" and "Butchers" | Role keys in code are `"farmer"` and `"butcher"` (rename pending) |
| Players per match | 5v5 (10 total) | Lobby starts match when **2** players are ready (1 per role). Multi-player-per-team support needs lobby rework |

### ❌ Not yet implemented

| Feature | Spec ref |
|---|---|
| Match timer + win condition | §2 step 8, §6 |
| Barn returning sheep to map (open question) | §6 |
| Kelpie influence radius (fear pulse) | §4 Kelpie — flee is driven by sheep-side `BoidForce_Avoidance`, not a kelpie-emitted event |
| Team colors / cosmetic identity | §6 |
| Camera edge-pan | §3 TBD |
| Multiple kelpies per team player | §3 parenthetical |
| Bark / sprint kelpie abilities | §6 |

---

## 9. Architecture

### Scene layout

```text
scenes/gameplay/MainScene.tscn  (MainScene : Node3D)
├── scripts/core/MainSceneController.gd        — spawn, score, server orchestration
├── scenes/camera/RTSCameraRig.tscn            — camera + move-order input
├── NavigationRegion3D           — navmesh (flat plane, pre-baked)
├── barn   (scenes/world/CaptureArea.tscn)     — farmer scoring zone
├── butcher (scenes/world/CaptureArea.tscn)    — butcher scoring zone
├── CanvasLayer / ScoreLabel
└── [runtime] Sheep_N, Kelpie_N  — spawned by MultiplayerSpawner
```

### Key scripts

| Script | Extends | Role |
|---|---|---|
| `NetEntity.gd` | `CharacterBody3D` | Base for every networked physics entity. Owns replication setup, client physics strip, `capture()`, `_rpc_despawn`. |
| `SpawnConfig.gd` | `Resource` | Data asset describing one spawn batch (`type_id`, `scene`, `count`, `spawn_radius`, `spawn_height`). |
| `SheepCharacterCtrl.gd` | `NetEntity` | Boid simulation (server only); 10 Hz sync; mutes all collision on clients. |
| `KelpieCharacterCtrl.gd` | `NetEntity` | NavAgent pathfinding (server only); `request_move` RPC with sender validation; auto-assigns local camera on spawn. |
| `CaptureAreaCtrl.gd` (`CaptureZone`) | `Area3D` | Server-only body detection; calls `NetEntity.capture()`; emits `entity_captured(team)`. |
| `MainSceneController.gd` | `Node3D` | Builds scene registry from `world_spawn_configs`, drives `MultiplayerSpawner`, receives score signals and RPC-broadcasts score. |
| `Lobby.gd` | `Control` | ENet host/join, role selection, transitions to main scene when both roles are filled. |
| `GameState.gd` | `Node` | Autoload singleton — `player_roles: Dictionary` (peer_id → role). Survives scene changes. |

### Boid force system

Forces are `BoidForce` resources attached to each sheep in the inspector. They are computed and summed each physics tick:

| Resource | Effect |
|---|---|
| `BoidForce_Separation` | Push away from nearby sheep |
| `BoidForce_Cohesion` | Drift toward local flock centre |
| `BoidForce_Alignment` | Match velocity with neighbours |
| `BoidForce_RandomJitter` | Random noise to prevent lock-step |
| `BoidForce_Avoidance` | Flee from bodies in a named group (default `"kelpie"`) |

New forces: create a script extending `BoidForce`, override `_compute(agent, neighbours) -> Vector3`, attach as a resource on the sheep scene.

### Networking data flow

```
Client                           Server
  │                                │
  │── right-click ──────────────►  │
  │   request_move.rpc_id(1, pos)  │  validates sender == kelpie.player_peer_id
  │                                │  sets nav_agent.target_position
  │                                │
  │                                │  _physics_process (sheep boids + kelpie nav)
  │                                │  move_and_slide()
  │                                │
  │  ◄── MultiplayerSynchronizer ──│  broadcasts global_position + rotation
  │       (kelpies: every frame)   │  (sheep: 10 Hz)
  │                                │
  │  ◄── _rpc_sync_score ──────────│  on capture event
  │  ◄── _rpc_despawn ─────────────│  on sheep captured (frees node on client)
```

---

## 10. Running the project

1. Open in **Godot 4.7** (Forward Plus).
2. Press **Run** — the Lobby scene loads.
3. On one machine (or two terminals / Godot instances):
   - First player clicks **Host Game**, selects a role.
   - Second player enters the first player's IP, clicks **Join Game**, selects the other role.
4. Match starts automatically when both roles are filled.

Default port: **7777 UDP** (ENet). Ensure it is open / forwarded for LAN or internet play.

---

## 11. Adding a new entity type

No changes to existing code are required. Steps:

1. **Create the scene** — `CharacterBody3D` (or any node) with a script extending `NetEntity`.

2. **Override the hooks you need:**
   ```gdscript
   extends NetEntity

   func _get_sync_interval() -> float: return 0.1   # 10 Hz

   func _on_spawn(data: Dictionary) -> void:
       add_to_group("cattle")
       position = Vector3(data["x"], data["spawn_height"], data["z"])

   func _on_captured() -> void:
       remove_from_group("cattle")

   func _net_ready() -> void:
       pass  # tree is available here; start AI, connect signals, etc.

   func _net_disable_physics() -> void:
       super()  # zeros self collision_layer/mask
       $NeighbourArea.collision_layer = 0   # silence any extra Area3D children
   ```

3. **Create a SpawnConfig resource** — in Godot editor: *New Resource → SpawnConfig*. Set `type_id` (e.g. `"cattle"`), point `scene` at your new scene, set `count`, `spawn_radius`, `spawn_height`.

4. **Add the resource** to the `world_spawn_configs` array on the `MainScene` node in `scenes/gameplay/MainScene.tscn`.

That's it. The entity will be spawned by the server and replicated to all clients automatically.
