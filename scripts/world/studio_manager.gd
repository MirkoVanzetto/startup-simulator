extends Node3D
## StudioManager - Controls studio interactive elements, lighting, upgrades, employee workstation, and physical decor mode

@onready var monitor_upgrade: Node3D = $Upgrades/MonitorUpgradeProp
@onready var chair_office: Node3D = $Furniture/ChairOfficeProp
@onready var chair_gaming: Node3D = $Upgrades/ChairGamingUpgradeProp
@onready var plant_aloe: Node3D = $Upgrades/PlantAloeUpgrade
@onready var server_rack_upgrade: Node3D = $Upgrades/ServerRackUpgradeProp
@onready var employee_workstation: Node3D = $EmployeeWorkstation
@onready var employee_nametag: Label3D = $EmployeeWorkstation/EmployeeNameTag
@onready var placed_container: Node3D = $PlacedFurniture

# Interactive Decor Mode State
var is_decor_mode: bool = false
var current_item_id: String = "plant_aloe_upgrade"
var current_rotation_y: float = 0.0
var grid_snap_enabled: bool = true
var grid_size: float = 0.25
var current_ghost_pos: Vector3 = Vector3.ZERO
var is_current_placement_valid: bool = false
var available_item_ids: Array[String] = []
var current_item_index: int = 0

# Ghost preview nodes and materials
var ghost_root: Node3D = null
var ghost_mesh_holder: Node3D = null
var ghost_valid_mat: StandardMaterial3D = null
var ghost_invalid_mat: StandardMaterial3D = null

func _ready() -> void:
	VillageBuilder.build_studio(self)
	if not placed_container:
		placed_container = Node3D.new()
		placed_container.name = "PlacedFurniture"
		add_child(placed_container)

	_init_ghost_preview()
	_init_available_items()

	EventBus.item_purchased.connect(_on_item_purchased)
	EventBus.employee_hired.connect(_on_employee_changed)
	EventBus.employee_fired.connect(_on_employee_changed)

	update_installed_upgrades()
	update_employee_workstation()
	rebuild_placed_furniture()

func _init_ghost_preview() -> void:
	ghost_valid_mat = StandardMaterial3D.new()
	ghost_valid_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ghost_valid_mat.albedo_color = Color(0.2, 0.9, 0.3, 0.55)
	ghost_valid_mat.emission_enabled = true
	ghost_valid_mat.emission = Color(0.2, 0.9, 0.3)
	ghost_valid_mat.emission_energy_multiplier = 0.4
	ghost_valid_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	ghost_invalid_mat = StandardMaterial3D.new()
	ghost_invalid_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ghost_invalid_mat.albedo_color = Color(0.9, 0.2, 0.2, 0.55)
	ghost_invalid_mat.emission_enabled = true
	ghost_invalid_mat.emission = Color(0.9, 0.2, 0.2)
	ghost_invalid_mat.emission_energy_multiplier = 0.4
	ghost_invalid_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	ghost_root = Node3D.new()
	ghost_root.name = "GhostPreview"
	ghost_root.visible = false
	add_child(ghost_root)

	ghost_mesh_holder = Node3D.new()
	ghost_mesh_holder.name = "ModelHolder"
	ghost_root.add_child(ghost_mesh_holder)

func _init_available_items() -> void:
	available_item_ids.clear()
	# Check pending purchased items first
	for it in FurniturePlacementManager.get_pending_furniture():
		if not it in available_item_ids:
			available_item_ids.append(it)

	# Add standard catalog items
	var catalog = FurniturePlacementManager.get_catalog()
	for cat_key in catalog.keys():
		if not cat_key in available_item_ids:
			available_item_ids.append(cat_key)

	if not available_item_ids.is_empty():
		current_item_index = 0
		current_item_id = available_item_ids[0]

func update_installed_upgrades() -> void:
	var has_monitor = "monitor_upgrade" in GameManager.studio_upgrades_installed
	var has_gaming_chair = "chair_gaming_upgrade" in GameManager.studio_upgrades_installed
	var has_plant = "plant_aloe" in GameManager.studio_upgrades_installed or "plant_aloe_upgrade" in GameManager.studio_upgrades_installed
	var has_server = "server_rack_upgrade" in GameManager.studio_upgrades_installed

	if monitor_upgrade:
		monitor_upgrade.visible = has_monitor
		monitor_upgrade.process_mode = Node.PROCESS_MODE_INHERIT if has_monitor else Node.PROCESS_MODE_DISABLED

	if chair_gaming and chair_office:
		chair_gaming.visible = has_gaming_chair
		chair_gaming.process_mode = Node.PROCESS_MODE_INHERIT if has_gaming_chair else Node.PROCESS_MODE_DISABLED
		chair_office.visible = not has_gaming_chair
		chair_office.process_mode = Node.PROCESS_MODE_DISABLED if has_gaming_chair else Node.PROCESS_MODE_INHERIT

	if plant_aloe:
		plant_aloe.visible = has_plant
		plant_aloe.process_mode = Node.PROCESS_MODE_INHERIT if has_plant else Node.PROCESS_MODE_DISABLED

	if server_rack_upgrade:
		server_rack_upgrade.visible = has_server
		server_rack_upgrade.process_mode = Node.PROCESS_MODE_INHERIT if has_server else Node.PROCESS_MODE_DISABLED

func update_employee_workstation() -> void:
	if not employee_workstation:
		return

	var hired = EmployeeManager.get_hired_employees()
	if hired.size() > 0:
		employee_workstation.visible = true
		employee_workstation.process_mode = Node.PROCESS_MODE_INHERIT
		if employee_nametag:
			var emp = hired[0]
			employee_nametag.text = "%s\n★ %s ★\n[In Studio - Operativo]" % [emp["name"], emp["role"]]
	else:
		employee_workstation.visible = false
		employee_workstation.process_mode = Node.PROCESS_MODE_DISABLED

func _on_item_purchased(item_id: String, _cost: float) -> void:
	update_installed_upgrades()
	_init_available_items()
	if is_decor_mode:
		current_item_id = item_id
		_update_ghost_model()

func _on_employee_changed(_emp_id: String, _emp_name: String = "") -> void:
	update_employee_workstation()

# ==============================================================================
# PHYSICAL FURNITURE SPAWNING & REBUILDING
# ==============================================================================

func rebuild_placed_furniture() -> void:
	if not placed_container:
		return

	for child in placed_container.get_children():
		child.queue_free()

	var placed = FurniturePlacementManager.get_placed_furniture()
	for entry in placed:
		if entry is Dictionary:
			spawn_placed_item_node(entry)

func spawn_placed_item_node(item_entry: Dictionary) -> Node3D:
	if not placed_container:
		return null

	var item_id = item_entry.get("id", "")
	var model_path = item_entry.get("model_path", "")
	if model_path == "":
		model_path = FurniturePlacementManager.get_model_path_for_item(item_id)

	var pos_arr = item_entry.get("position", [0.0, 0.0, 0.0])
	var pos = Vector3(float(pos_arr[0]), float(pos_arr[1]), float(pos_arr[2]))
	var rot_y = float(item_entry.get("rotation_y", 0.0))

	var catalog = FurniturePlacementManager.get_catalog()
	var item_info = catalog.get(item_id, {})
	var item_scale = item_info.get("scale", Vector3.ONE)
	var fallback_size = item_info.get("collision_size", Vector3(0.6, 0.8, 0.6))

	var body = StaticBody3D.new()
	body.name = "Placed_" + item_id + "_" + str(placed_container.get_child_count())
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = pos
	body.rotation.y = rot_y

	var model_res = load(model_path)
	if model_res:
		var model_inst = model_res.instantiate()
		model_inst.scale = item_scale
		body.add_child(model_inst)

		var aabb = _calculate_node_aabb(model_inst)
		var col_shape = BoxShape3D.new()
		var col_node = CollisionShape3D.new()
		if aabb.size.length() > 0.1:
			col_shape.size = aabb.size
			col_node.shape = col_shape
			col_node.position = aabb.position + aabb.size * 0.5
		else:
			col_shape.size = fallback_size
			col_node.shape = col_shape
			col_node.position = Vector3(0, fallback_size.y * 0.5, 0)
		body.add_child(col_node)

	placed_container.add_child(body)
	return body

func _calculate_node_aabb(node: Node3D) -> AABB:
	var total_aabb = AABB()
	var first = true
	var meshes = node.find_children("*", "MeshInstance3D", true, false)
	for m in meshes:
		if m is MeshInstance3D and m.mesh:
			var m_aabb = m.transform * m.mesh.get_aabb()
			if first:
				total_aabb = m_aabb
				first = false
			else:
				total_aabb = total_aabb.merge(m_aabb)
	return total_aabb

# ==============================================================================
# INTERACTIVE DECOR MODE (GHOST PREVIEW, ROTATION, GRID SNAP, COMMIT)
# ==============================================================================

func toggle_decor_mode() -> void:
	is_decor_mode = not is_decor_mode

	if is_decor_mode:
		_init_available_items()
		# Prioritize pending items
		var pending = FurniturePlacementManager.get_pending_furniture()
		if not pending.is_empty():
			current_item_id = pending[0]
			current_item_index = available_item_ids.find(current_item_id)
			if current_item_index == -1:
				current_item_index = 0
				current_item_id = available_item_ids[0]

		_update_ghost_model()
		ghost_root.visible = true
		_update_decor_prompt()
		EventBus.notification_posted.emit("Modalità Arredo Attiva", "Punta il pavimento per posizionare arredi nello studio.", "info")
	else:
		if ghost_root:
			ghost_root.visible = false
		EventBus.prompt_changed.emit("")
		EventBus.notification_posted.emit("Modalità Arredo Chiusa", "Tornato alla modalità visuale libera.", "info")

func _update_decor_prompt() -> void:
	var item_name = current_item_id
	var catalog = FurniturePlacementManager.get_catalog()
	if catalog.has(current_item_id):
		item_name = catalog[current_item_id].get("name", current_item_id)

	var snap_str = "0.25m ON" if grid_snap_enabled else "OFF"
	var text = "[B] Esci | [LMB] Posiziona: %s | [R/Wheel] Ruota | [G] Griglia (%s) | [Tab] Cambia" % [
		item_name, snap_str
	]
	EventBus.prompt_changed.emit(text)

func _update_ghost_model() -> void:
	if not ghost_mesh_holder:
		return

	for child in ghost_mesh_holder.get_children():
		child.queue_free()

	var model_path = FurniturePlacementManager.get_model_path_for_item(current_item_id)
	var model_res = load(model_path)
	if model_res:
		var model_inst = model_res.instantiate()
		var catalog = FurniturePlacementManager.get_catalog()
		var item_info = catalog.get(current_item_id, {})
		model_inst.scale = item_info.get("scale", Vector3.ONE)
		ghost_mesh_holder.add_child(model_inst)
		_apply_ghost_material_to_node(ghost_mesh_holder, ghost_valid_mat)

func _apply_ghost_material_to_node(node: Node, mat: Material) -> void:
	var meshes = node.find_children("*", "MeshInstance3D", true, false)
	for m in meshes:
		if m is MeshInstance3D:
			m.material_override = mat

func _cycle_next_item() -> void:
	if available_item_ids.is_empty():
		return
	current_item_index = (current_item_index + 1) % available_item_ids.size()
	current_item_id = available_item_ids[current_item_index]
	_update_ghost_model()
	_update_decor_prompt()

func _update_ghost_transform() -> void:
	if ghost_root:
		ghost_root.position = current_ghost_pos
		ghost_root.rotation.y = current_rotation_y

func _get_floor_intersection() -> Dictionary:
	var camera: Camera3D = null
	if GameManager.player_node and is_instance_valid(GameManager.player_node):
		camera = GameManager.player_node.get_node_or_null("Neck/Camera3D")
	if not camera:
		var vp = get_viewport()
		if vp:
			camera = vp.get_camera_3d()
	if not camera:
		return {"hit": false, "position": Vector3.ZERO}

	var ray_origin = camera.global_position
	var ray_dir = -camera.global_transform.basis.z.normalized()

	# Floor is at Y = 0.0 (Floor normal: (0, 1, 0))
	if abs(ray_dir.y) < 0.001:
		return {"hit": false, "position": Vector3.ZERO}

	var t = -ray_origin.y / ray_dir.y
	if t <= 0.0 or t > 18.0:
		return {"hit": false, "position": Vector3.ZERO}

	var hit_pos = ray_origin + ray_dir * t
	return {"hit": true, "position": hit_pos}

func _process(_delta: float) -> void:
	if not is_decor_mode:
		if ghost_root and ghost_root.visible:
			ghost_root.visible = false
		return

	var inter = _get_floor_intersection()
	if not inter.get("hit", false):
		if ghost_root:
			ghost_root.visible = false
		return

	var raw_pos = inter.get("position", Vector3.ZERO)
	var pos = raw_pos
	if grid_snap_enabled:
		pos = FurniturePlacementManager.snap_to_grid(pos, grid_size)
	pos.y = 0.0

	current_ghost_pos = pos
	is_current_placement_valid = FurniturePlacementManager.validate_placement_position(pos, current_item_id)

	if ghost_root:
		ghost_root.visible = true
		ghost_root.position = pos
		ghost_root.rotation.y = current_rotation_y
		var mat = ghost_valid_mat if is_current_placement_valid else ghost_invalid_mat
		_apply_ghost_material_to_node(ghost_mesh_holder, mat)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_B:
			if is_player_in_studio() or is_decor_mode:
				toggle_decor_mode()
				get_viewport().set_input_as_handled()
				return

		if is_decor_mode:
			if event.keycode == KEY_R:
				current_rotation_y = fmod(current_rotation_y + deg_to_rad(45.0), TAU)
				_update_ghost_transform()
				get_viewport().set_input_as_handled()
			elif event.keycode == KEY_G:
				grid_snap_enabled = not grid_snap_enabled
				_update_decor_prompt()
				EventBus.notification_posted.emit("Griglia", "Snapping a griglia: %s" % ("0.25m" if grid_snap_enabled else "OFF"), "info")
				get_viewport().set_input_as_handled()
			elif event.keycode == KEY_TAB:
				_cycle_next_item()
				get_viewport().set_input_as_handled()
			elif event.keycode == KEY_ESCAPE:
				toggle_decor_mode()
				get_viewport().set_input_as_handled()

	if is_decor_mode and event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			current_rotation_y = fmod(current_rotation_y + deg_to_rad(45.0), TAU)
			_update_ghost_transform()
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			current_rotation_y = fmod(current_rotation_y - deg_to_rad(45.0) + TAU, TAU)
			_update_ghost_transform()
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_LEFT:
			_commit_placement()
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			toggle_decor_mode()
			get_viewport().set_input_as_handled()

func _commit_placement() -> void:
	if not is_current_placement_valid:
		EventBus.notification_posted.emit("Posizione Non Valida", "Spazio occupato o fuori dai confini dello studio!", "warning")
		SoundManager.play_ui_error()
		return

	var success = FurniturePlacementManager.place_furniture(current_item_id, current_ghost_pos, current_rotation_y)
	if success:
		SoundManager.play_ui_click()
		SaveManager.save_game()
		EventBus.notification_posted.emit("Arredo Posizionato", "Elemento d'arredo posizionato nello studio con successo!", "success")
		_init_available_items()
		_update_decor_prompt()
	else:
		EventBus.notification_posted.emit("Errore", "Impossibile posizionare l'oggetto.", "warning")

func is_player_in_studio() -> bool:
	if is_instance_valid(GameManager.player_node):
		var p_pos = GameManager.player_node.global_position
		return abs(p_pos.x) <= 3.8 and p_pos.z <= 2.8 and p_pos.z >= -3.4
	return true
