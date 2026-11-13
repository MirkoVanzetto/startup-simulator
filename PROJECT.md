# Project: Startup Simulator — Turin Architectural & PBR World Overhaul

## Architecture
Startup Simulator is built in Godot Engine 4.3 Stable (Linux x86_64, GL Compatibility Renderer).
Key systems:
- **Core / Singletons**: `GameManager`, `EconomyManager`, `EmployeeManager`, `ContractManager`, `SaveManager`, `EventBus`, `SoundManager`, `CalendarSystem`, `QuestManager`.
- **Procedural PBR & Asset Pipeline**: `tools/generate_pbr_pipeline.py` (NumPy + PIL procedural PBR texture authoring), `tools/generate_turin_district.py` (modular 3D architectural kit generation), `assets/textures/pbr/`, `assets/materials/`.
- **World 3D Scenes**: `game_world.tscn`, `street.tscn`, `studio.tscn`, `pizzeria.tscn`, `cafe.tscn`, `tech_shop.tscn`, character models (`mario_npc.tscn`, `elena_npc.tscn`, `davide_npc.tscn`).
- **Interior & Placement**: `scripts/world/furniture_placement_manager.gd`, `scripts/world/studio_manager.gd`.
- **Test Infrastructure**: `scenes/test_runner.tscn`, `tests/test_runner.gd`, `scenes/adversarial_workflows_runner.tscn`.

## Feature Inventory
| # | Feature | Description | Milestone | Source |
|---|---------|-------------|-----------|--------|
| 1 | Procedural PBR Texture Suite | Pure Python (NumPy + PIL) generator creating 11+ high-res 1024x1024 PBR sets (Albedo, Normal via Sobel, Roughness, AO, Metallic, ORM, Emissive). | M1 | Survey Explorer 2 |
| 2 | Godot StandardMaterial3D Pipeline | Authoring `.tres` materials with triplanar mapping (`uv1_triplanar = true`) and executing headless editor import. | M1 | Survey Explorer 2 |
| 3 | Wide Turin Boulevard (Via Po / Via Roma) | Expand road from 5.2m to 10.0m with 2 travel lanes, embedded tram tracks, and lateral parking bays. | M2 | Survey Explorer 1 |
| 4 | Monumental Vaulted Porticoes | Continuous 4.6m deep pedestrian arcades on both sides with classical granite pillars, groin vaults, and Luserna flagstones. | M2 | Survey Explorer 1 |
| 5 | Neoclassical Savoy Facades | 4-story palazzi with rusticated bugnato base, French windows, pediments (timpani), balconies, and slate mansard roofs. | M2 | Survey Explorer 1 |
| 6 | Piazza San Carlo Expansion | Grand civic plaza ($23\text{m} \times 32\text{m}$ extending to $Z=45\text{m}$) with central monument pedestal, twin colonnade returns, and outdoor dehors. | M2 | Survey Explorer 1 |
| 7 | Turin Street Lighting Rig | Warm 2700K incandescent portico lanterns, cast-iron streetlamps, neon signage, and golden-hour sun atmosphere. | M2 | Survey Explorer 1 |
| 8 | High-Tech Startup Studio Staging | Dual 27" screens with glowing code, mid-tower PC case, mechanical keyboard, task lamp, cable management spine, 42U server rack, architecture whiteboard. | M3 | Survey Explorer 3 |
| 9 | Pizzeria Da Mario Anti-Clipping | Eliminate car/table penetration, add front collision walls, align Mario NPC upright with apron at $Y=0.0$. | M3 | Survey Explorer 3 |
| 10 | Caffè San Carlo & Tech Shop Realignment | Carve out palazzo building overlaps, align Elena and Davide NPCs upright behind counters facing customers, remove duplicate furniture. | M3 | Survey Explorer 3 |
| 11 | Furniture Placement AABB Validation | Replace point check with full AABB footprint validation against walls, fixed obstacles, dynamic items, and doorway egress; fix double-spawn bug. | M3 | Survey Explorer 3 |
| 12 | Collision Integrity & Navigation Corridors | Step-free sidewalk transitions ($Y=0.16\text{m}$), precise car colliders, outer boundary walls, and validation of 9 pedestrian raycast corridors. | M4 | Survey Explorer 1 & 3 |
| 13 | Full E2E & Adversarial Stress Testing | 100% pass across all 106+ unit/integration tests and 9 physics navigation corridors, plus visual multi-camera verification. | M5 | Survey Explorer 1 & 3 |
| 14 | Windows Build & GitHub Push | Build `build/StartupSimulator.exe` and `build/StartupSimulator_Windows_x86_64.zip`, commit and push to GitHub repository. | M6 | ORIGINAL_REQUEST §Follow-up |

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| M1 | Procedural PBR Texture & Material Library | Python generator for 11+ PBR materials, Godot `.tres` authoring, headless editor import | none | DONE |
| M2 | Architectural City Boulevard & Piazza San Carlo | Modular 3D kit, 10m roadway, continuous porticoes, Neoclassical facades, Piazza San Carlo, 2700K lighting | M1 | DONE |
| M3 | Interior Staging, Tech Office & Zero-Clipping | Studio tech staging (dual monitors, cables, 42U rack, whiteboard), Pizzeria/Cafe/Shop anti-clipping, FurniturePlacementManager AABB fix | M1 | DONE |
| M4 | Physics Collision & Navigation Corridors | Sidewalk steps, car bounding boxes, boundary perimeter, 9 direct SpaceState raycasts | M2, M3 | DONE |
| M5 | Automated E2E & Adversarial Verification | Full test runner, adversarial raycast runner, camera captures, challenger verification, forensic audit | M4 | DONE |
| M6 | Windows Release & GitHub Push | Export Windows binary & zip, commit all assets and code, push to origin main | M5 | DONE |

## Interface Contracts
### PBR Generator ↔ Godot Materials
- Textures output to `res://assets/textures/pbr/<material_name>/<material_name>_<channel>.png`
- StandardMaterial3D output to `res://assets/materials/<material_name>.tres`
- Headless import command: `/home/antigravity/bin/godot --headless --editor --quit`

### Architectural Modular Kit ↔ Scenes
- `tools/generate_turin_district.py` outputs `.glb` files into `res://assets/models/turin/`
- Node hierarchy in `scenes/world/street.tscn`:
  - `BoulevardRoadway`: $X \in [-5.0, +5.0]$, length $28\text{m}$.
  - `PorticoWest`: $X \in [-9.6, -5.0]$, elevation $Y=0.16\text{m}$, vault height $4.8\text{m}$.
  - `PorticoEast`: $X \in [+5.0, +9.6]$, elevation $Y=0.16\text{m}$, vault height $4.8\text{m}$.
  - `PiazzaSanCarlo`: $Z \in [22.0, 45.0]$, $X \in [-16.0, +16.0]$.

### FurniturePlacementManager ↔ Studio
- `validate_placement_position(pos: Vector3, item_id: String = "") -> bool`
  - Validates full item footprint against `ROOM_MIN_X/Z`, `ROOM_MAX_X/Z`, `FIXED_OBSTACLES`, and `_placed_furniture`.
- `studio_manager.gd`: Only `FurniturePlacementManager.place_furniture()` calls `spawn_placed_item_node()`. Redundant call removed from `_commit_placement()`.

### Test Runner ↔ Physics DirectSpaceState
- Direct raycast queries across the 9 pedestrian corridors must return 0 collisions:
  - $(0, 1.0, 1.0) \to (0, 1.0, 16.0)$ (Central Via Po corridor).
  - $(-4.8, 1.0, 14.0) \to (-4.8, 1.0, 21.0)$ (West sidewalk).
  - $(+4.8, 1.0, 14.0) \to (+4.8, 1.0, 21.0)$ (East sidewalk).
  - $(-4.5, 1.0, 24.2) \to (+4.5, 1.0, 24.2)$ (Via Bogino crosswalk).
  - $(0, 1.0, 22.0) \to (0, 1.0, 26.0)$ (Piazza San Carlo walkway).
  - $(0, 1.0, 8.4) \to (-4.5, 1.0, 8.4)$ (Tech Shop approach).
  - $(0, 1.0, 9.5) \to (+4.5, 1.0, 9.5)$ (Cafe approach).
  - $(-2.8, 1.0, 3.0) \to (-2.8, 1.0, 7.5)$ (West Portici arcade).
  - $(+2.8, 1.0, 3.0) \to (+2.8, 1.0, 7.5)$ (East Portici arcade).

## Code Layout
- `tools/`: Procedural asset generators (`generate_pbr_pipeline.py`, `generate_turin_district.py`, `asset_generator.py`).
- `assets/textures/pbr/`: Generated 1024x1024 PBR texture maps (Albedo, Normal, Roughness, AO, Metallic, ORM, Emissive).
- `assets/materials/`: Generated Godot `StandardMaterial3D` resources (`.tres`).
- `assets/models/turin/`: Generated 3D modular architectural models (`.glb`).
- `scenes/world/`: 3D environment scenes (`street.tscn`, `studio.tscn`, `pizzeria.tscn`, `cafe.tscn`, `tech_shop.tscn`, `game_world.tscn`).
- `scripts/world/`: 3D world controllers (`studio_manager.gd`, `furniture_placement_manager.gd`, `city_manager.gd`).
- `tests/`: Automated unit, integration, and adversarial stress tests (`test_runner.gd`, `adversarial_workflows_challenger.gd`).
- `build/`: Windows release artifacts (`StartupSimulator.exe`, `StartupSimulator_Windows_x86_64.zip`).

## v0.9.0 — Borgo San Carlo (Rielaborazione 3D & Gameplay)
- **Stile 3D Unificato**: `assets/shaders/toon.gdshader` (3 bande morbide + rim + `wind_sway`), 23 texture procedurali tileable in `assets/textures/village/` (`tools/generate_village_textures.py`), libreria materiali `scripts/world/village_materials.gd`, geometria + collisioni accoppiate `scripts/world/style_mesh.gd`, `scripts/world/village_props.gd`, `scripts/world/village_builder.gd`.
- **Negozi & Cibo**: `ShopManager` (`pizzeria`, `cafe`, `panificio`, `alimentari`, `edicola`, `fridge`), `ShopMenu` (`scenes/ui/shop_menu.tscn`, responsive su tutti i viewport), `ShopInteractable`, `FridgeInteractable`, `RestInteractable`.
- **Fame & Energia**: `NeedsManager` con decay reale, malus velocità sotto 30%/10%, barre HUD, superficie passi dinamica (`wood`, `stone`, `grass`, `tile`, `asphalt`), salvataggio in `SaveManager`.
- **Notorietà**: `FameManager` con 6 livelli di fama, sconti negozi 0%–20%, bonus contratti 1.0x–1.25x, +1 Rep ogni € 25 spesi nei negozi locali e al primo dialogo con i clienti.
