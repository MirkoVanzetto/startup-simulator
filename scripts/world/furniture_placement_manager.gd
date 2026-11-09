class_name FurniturePlacementManager
extends Node
## FurniturePlacementManager - Validates, manages, and persists 3D furniture placement in the Studio
## Supports room bounds validation, desk overlap detection, grid snapping, and savegame persistence.

signal furniture_placed(item_data: Dictionary)
signal furniture_removed(item_data: Dictionary)
signal placed_furniture_reloaded()
signal decor_mode_toggled(is_active: bool)

# Studio room placement bounds (inclusive)
const ROOM_MIN_X: float = -2.8
const ROOM_MAX_X: float = 2.8
const ROOM_MIN_Z: float = -2.2
const ROOM_MAX_Z: float = 2.2
const EPSILON: float = 0.001

# Player primary desk footprint at (0, 0, -1.5)
const DESK_CENTER: Vector3 = Vector3(0.0, 0.0, -1.5)
const DESK_HALF_WIDTH: float = 0.85
const DESK_HALF_DEPTH: float = 0.55

# Shared persistent state across manager instances
static var _placed_furniture: Array = []
static var _pending_items: Array = []
static var _connected_to_event_bus: bool = false
static var _instance: FurniturePlacementManager = null

# Known catalog of placeable furniture assets
const CATALOG: Dictionary = {
	"plant_aloe_upgrade": {
		"name": "Pianta Succulenta d'Arredo",
		"model_path": "res://assets/models/furniture/cactus_medium_A.gltf",
		"scale": Vector3(0.9, 0.9, 0.9),
		"category": "decor",
		"collision_size": Vector3(0.5, 0.8, 0.5)
	},
	"plant_aloe": {
		"name": "Pianta Succulenta d'Arredo",
		"model_path": "res://assets/models/furniture/cactus_medium_A.gltf",
		"scale": Vector3(0.9, 0.9, 0.9),
		"category": "decor",
		"collision_size": Vector3(0.5, 0.8, 0.5)
	},
	"chair_gaming_upgrade": {
		"name": "Poltrona Gaming Ergonomica Pro",
		"model_path": "res://scenes/props/chair_gaming_upgrade_prop.tscn",
		"scale": Vector3(1.0, 1.0, 1.0),
		"category": "seating",
		"collision_size": Vector3(0.7, 1.1, 0.7)
	},
	"chair_office_01": {
		"name": "Sedia da Ufficio Modulare",
		"model_path": "res://scenes/props/chair_office_prop.tscn",
		"scale": Vector3(1.0, 1.0, 1.0),
		"category": "seating",
		"collision_size": Vector3(0.65, 1.0, 0.65)
	},
	"armchair": {
		"name": "Poltrona Relax in Pelle",
		"model_path": "res://assets/models/furniture/armchair.gltf",
		"scale": Vector3(0.9, 0.9, 0.9),
		"category": "seating",
		"collision_size": Vector3(0.8, 0.8, 0.8)
	},
	"couch": {
		"name": "Divanetto Ospiti Torino Tech",
		"model_path": "res://assets/models/furniture/couch.gltf",
		"scale": Vector3(0.9, 0.9, 0.9),
		"category": "seating",
		"collision_size": Vector3(1.6, 0.8, 0.8)
	},
	"lamp_standing": {
		"name": "Lampada da Terra Minimal",
		"model_path": "res://assets/models/furniture/lamp_standing.gltf",
		"scale": Vector3(0.9, 0.9, 0.9),
		"category": "lighting",
		"collision_size": Vector3(0.4, 1.6, 0.4)
	},
	"lamp_table": {
		"name": "Lampada da Tavolo",
		"model_path": "res://assets/models/furniture/lamp_table.gltf",
		"scale": Vector3(0.8, 0.8, 0.8),
		"category": "lighting",
		"collision_size": Vector3(0.3, 0.5, 0.3)
	},
	"bookshelf": {
		"name": "Libreria Modulare Torino",
		"model_path": "res://assets/models/furniture/shelf_B_large_decorated.gltf",
		"scale": Vector3(0.85, 0.85, 0.85),
		"category": "storage",
		"collision_size": Vector3(1.0, 1.8, 0.45)
	},
	"cabinet": {
		"name": "Mobiletto Archivio Contabile",
		"model_path": "res://assets/models/furniture/cabinet_medium_decorated.gltf",
		"scale": Vector3(0.85, 0.85, 0.85),
		"category": "storage",
		"collision_size": Vector3(0.9, 0.9, 0.5)
	},
	"rug": {
		"name": "Tappeto d'Arredo Soft",
		"model_path": "res://assets/models/furniture/rug_rectangle_A.gltf",
		"scale": Vector3(1.1, 1.0, 1.1),
		"category": "decor",
		"collision_size": Vector3(1.4, 0.05, 1.0)
	},
	"cactus_small": {
		"name": "Cactus Piccolo Decorativo",
		"model_path": "res://assets/models/furniture/cactus_small_A.gltf",
		"scale": Vector3(0.7, 0.7, 0.7),
		"category": "decor",
		"collision_size": Vector3(0.3, 0.4, 0.3)
	},
	"table_coffee": {
		"name": "Tavolino Basso da Caffè",
		"model_path": "res://assets/models/furniture/table_coffee.gltf",
		"scale": Vector3(0.85, 0.85, 0.85),
		"category": "tables",
		"collision_size": Vector3(0.9, 0.45, 0.6)
	},
	"server_rack_upgrade": {
		"name": "Server Rack 4U Enterprise",
		"model_path": "res://assets/models/hardware/server_rack.glb",
		"scale": Vector3(1.2, 1.2, 1.2),
		"category": "tech",
		"collision_size": Vector3(0.9, 1.8, 0.9)
	},
	"monitor_upgrade": {
		"name": "Monitor Ultrawide 27\"",
		"model_path": "res://scenes/props/monitor_upgrade_prop.tscn",
		"scale": Vector3(1.0, 1.0, 1.0),
		"category": "tech",
		"collision_size": Vector3(0.65, 0.5, 0.25)
	}
}

func _init() -> void:
	_instance = self
	_ensure_event_connection()

func _ready() -> void:
	_ensure_event_connection()

static func _ensure_event_connection() -> void:
	if _connected_to_event_bus:
		return
	var tree = Engine.get_main_loop() as SceneTree
	if tree and tree.root and tree.root.has_node("EventBus"):
		var bus = tree.root.get_node("EventBus")
		var cb = Callable(FurniturePlacementManager, "_on_item_purchased_static")
		if not bus.item_purchased.is_connected(cb):
			bus.item_purchased.connect(cb)
			_connected_to_event_bus = true

static func _on_item_purchased_static(item_id: String, _cost: float) -> void:
	queue_furniture_placement(item_id)

## Returns true if the position is within room bounds and doesn't overlap restricted obstacles
static func validate_placement_position(pos: Vector3, item_id: String = "") -> bool:
	var half_w: float = 0.0
	var half_d: float = 0.0
	if item_id != "" and CATALOG.has(item_id):
		var c_size: Vector3 = CATALOG[item_id].get("collision_size", Vector3(0.5, 0.8, 0.5))
		half_w = c_size.x * 0.5
		half_d = c_size.z * 0.5

	# 1. Bounds check with epsilon tolerance for corner points
	if (pos.x - half_w) < (ROOM_MIN_X - EPSILON) or (pos.x + half_w) > (ROOM_MAX_X + EPSILON):
		return false
	if (pos.z - half_d) < (ROOM_MIN_Z - EPSILON) or (pos.z + half_d) > (ROOM_MAX_Z + EPSILON):
		return false

	# 2. Rejection of player primary desk overlap at (0, 0, -1.5)
	var dx = abs(pos.x - DESK_CENTER.x)
	var dz = abs(pos.z - DESK_CENTER.z)
	var desk_margin_x = DESK_HALF_WIDTH + (half_w * 0.5)
	var desk_margin_z = DESK_HALF_DEPTH + (half_d * 0.5)
	if dx < desk_margin_x and dz < desk_margin_z:
		return false

	# 3. Dynamic AABB overlap check against already placed furniture items
	if half_w > 0.0 and half_d > 0.0:
		for placed in _placed_furniture:
			if placed is Dictionary and placed.has("position"):
				var p_pos = placed["position"]
				var px = float(p_pos[0])
				var pz = float(p_pos[2])
				var p_id = placed.get("id", "")
				var p_hw = 0.3
				var p_hd = 0.3
				if CATALOG.has(p_id):
					var p_col: Vector3 = CATALOG[p_id].get("collision_size", Vector3(0.6, 0.8, 0.6))
					p_hw = p_col.x * 0.5
					p_hd = p_col.z * 0.5
				var min_dist_x = (half_w + p_hw) * 0.85
				var min_dist_z = (half_d + p_hd) * 0.85
				if abs(pos.x - px) < min_dist_x and abs(pos.z - pz) < min_dist_z:
					return false

	return true

## Instance alias for validate_placement_position
func is_valid_position(pos: Vector3, item_id: String = "") -> bool:
	return validate_placement_position(pos, item_id)

## Snaps coordinates to the nearest multiple of grid_size (default: 0.25m)
static func snap_to_grid(pos: Vector3, grid_size: float = 0.25) -> Vector3:
	if grid_size <= 0.0:
		return pos
	return Vector3(
		snapped(pos.x, grid_size),
		pos.y,
		snapped(pos.z, grid_size)
	)

## Adds an item to the placed furniture collection
static func place_furniture(item_id: String, pos: Vector3, rot_y: float = 0.0) -> bool:
	if not validate_placement_position(pos, item_id):
		return false

	var model_path = get_model_path_for_item(item_id)
	var item_entry: Dictionary = {
		"id": item_id,
		"model_path": model_path,
		"position": [pos.x, pos.y, pos.z],
		"rotation_y": rot_y
	}
	_placed_furniture.append(item_entry)

	# Remove from pending queue if present
	var idx = _pending_items.find(item_id)
	if idx != -1:
		_pending_items.remove_at(idx)

	if _instance and is_instance_valid(_instance):
		_instance.furniture_placed.emit(item_entry)

	# Notify studio if in tree
	var tree = Engine.get_main_loop() as SceneTree
	if tree and tree.root:
		var studios = tree.root.find_children("", "StudioManager", true, false)
		for s in studios:
			if s.has_method("spawn_placed_item_node"):
				s.spawn_placed_item_node(item_entry)

	return true

## Removes placed furniture entry at index
static func remove_placed_furniture(index: int) -> bool:
	if index < 0 or index >= _placed_furniture.size():
		return false
	var removed = _placed_furniture[index]
	_placed_furniture.remove_at(index)
	if _instance and is_instance_valid(_instance):
		_instance.furniture_removed.emit(removed)
	return true

## Clears all placed furniture
static func clear_placed_furniture() -> void:
	_placed_furniture.clear()

## Returns copy of placed furniture entries
static func get_placed_furniture() -> Array:
	return _placed_furniture.duplicate(true)

## Loads saved furniture array
static func load_placed_furniture(data: Array) -> void:
	_placed_furniture.clear()
	for entry in data:
		if entry is Dictionary and entry.has("id") and entry.has("position"):
			_placed_furniture.append(entry.duplicate(true))
	if _instance and is_instance_valid(_instance):
		_instance.placed_furniture_reloaded.emit()

## Queue an item for placement upon purchase
static func queue_furniture_placement(item_id: String) -> void:
	if not item_id in _pending_items:
		_pending_items.append(item_id)

## Returns queue of pending items to place
static func get_pending_furniture() -> Array:
	return _pending_items.duplicate(true)

## Resolves model resource path for a given item_id
static func get_model_path_for_item(item_id: String) -> String:
	if CATALOG.has(item_id):
		return CATALOG[item_id]["model_path"]
	# Fallback checks
	var generic_path = "res://assets/models/furniture/%s.gltf" % item_id
	if ResourceLoader.exists(generic_path):
		return generic_path
	return "res://assets/models/furniture/chair_A.gltf"

## Returns catalog dictionary
static func get_catalog() -> Dictionary:
	return CATALOG
