# Marooned on Mars (Godot 4.3+)

1. Install Godot 4.3 or newer (standard build, GDScript only).
2. Godot Project Manager > Import > pick this folder's `project.godot` > Import & Edit.
3. Press F5. Click Begin.

Controls: WASD walk, Shift sprint, Space jump, E interact, M places/teleport list, T thought, N day/night, mouse look, wheel zoom, Esc frees the mouse.

## Layout
- `scripts/world_data.gd`  landmark list, terrain height function, gravity zones (edit LM to add places)
- `scripts/terrain.gd`     builds the terrain mesh and collision
- `scripts/sites.gd`       builds base, greenhouse, crashed ship, anomaly, hollow, pads, ridge, rover, spring
- `scripts/player.gd`      astronaut model, movement, Mars gravity, camera
- `scripts/ui.gd`, `map_view.gd`  HUD, minimap, Places list with Teleport and Waypoint
- `scripts/main.gd`        game loop, oxygen, goals, thought bubbles, day/night
- `scripts/autotest.gd`    optional: `godot --path . -- --autotest` saves screenshots

Everything is built from code, so there are no asset files. To use Blender models instead, export glTF
and replace the matching function in `sites.gd` with an instantiated scene.
