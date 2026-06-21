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
