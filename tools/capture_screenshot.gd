extends Node
## Multi-screen capture utility for v1.2.0 Visual QA (fast 4-frame cadence for Mesa llvmpipe)
## Covers: Borgo San Carlo, Parco Valentino Ovest, Viale Est, Borgo Valdocco,
## Mercato Nord / OGR / Poste, Officina Bellini 3D Holograms vs Installed Hardware,
## SideJob HUD + Beacon, WorldMap 14 POIs, WebForge 5.0 Bento & AST Click-to-Patch.

var frame_count: int = 0
var player = null

func _cap(filename: String, label: String) -> void:
	var image = get_viewport().get_texture().get_image()
	if image:
		image.save_png("/home/antigravity/" + filename)
		print("✔ " + label + " (" + filename + ")")

func _set_cam(pos: Vector3, rot_deg: Vector3, neck_deg: Vector3) -> void:
	if player:
		player.global_position = pos
		player.rotation_degrees = rot_deg
		var neck = player.get_node_or_null("Neck")
		if neck:
			neck.rotation_degrees = neck_deg

func _look_at_flat(from_pos: Vector3, target_pos: Vector3, pitch_deg: float = -6.0) -> void:
	var dir := target_pos - from_pos
	dir.y = 0.0
	if dir.length_squared() < 0.01:
		_set_cam(from_pos, Vector3.ZERO, Vector3(pitch_deg, 0, 0))
		return
	var yaw_rad := atan2(-dir.x, -dir.z)
	_set_cam(from_pos, Vector3(0, rad_to_deg(yaw_rad), 0), Vector3(pitch_deg, 0, 0))

func _process(_delta: float) -> void:
	frame_count += 1

	if frame_count == 4:
		var menu = get_tree().root.find_child("MainMenu", true, false)
		if menu:
			menu.visible = false
		GameManager.start_new_game()

		GameManager.studio_upgrades_installed.append("monitor_upgrade")
		GameManager.studio_upgrades_installed.append("plant_aloe")
		GameManager.studio_upgrades_installed.append("server_rack_upgrade")
		ServerRackManager.unlock_server_rack()
		GameManager.company_tier = 2
		GameManager.reputation_points = 110
		EconomyManager.balance = 4500.0
		EmployeeManager.hire_employee("emp_luca")

		var studio_mgr = get_tree().root.find_child("Studio", true, false)
		if studio_mgr and studio_mgr.has_method("update_installed_upgrades"):
			studio_mgr.update_installed_upgrades()
			studio_mgr.update_employee_workstation()

		player = get_tree().root.find_child("PlayerCharacter", true, false)
		_set_cam(Vector3(2.1, 0.12, 1.45), Vector3(0, 44, 0), Vector3(-11, 0, 0))

	if frame_count == 10:
		_cap("startup_simulator_studio_3d.png", "Studio 3D Interior")
		_set_cam(Vector3(0.0, 1.45, 7.2), Vector3(0, 0, 0), Vector3(-2, 0, 0))

	if frame_count == 15:
		_cap("startup_simulator_studio_facade.png", "Studio Front Door Facade")
		_set_cam(Vector3(0.0, 0.16, 5.0), Vector3(0, 180, 0), Vector3(-4, 0, 0))

	if frame_count == 20:
		_cap("startup_simulator_street_3d.png", "Via del Borgo San Carlo")
		# Piazza San Carlo framing Fontana, BachecaSanCarlo, Edicola e Elettronica TO
		_set_cam(Vector3(-2.6, 0.25, 13.8), Vector3(0, -148, 0), Vector3(-6, 0, 0))

	if frame_count == 25:
		_cap("startup_simulator_piazza_san_carlo.png", "Piazza San Carlo & Bacheca Lavori")
		# Parco Valentino Ovest (Laghetto delle anatre, Gazebo, Ville & Alpi)
		_set_cam(Vector3(-36.0, 0.75, 35.8), Vector3(0, 36, 0), Vector3(-7, 0, 0))

	if frame_count == 30:
		_cap("startup_simulator_parco_valentino.png", "Parco Valentino Ovest (Laghetto & Gazebo)")
		# East connecting road looking East toward Valdocco
		_set_cam(Vector3(12.5, 1.85, 28.0), Vector3(0, -90, 0), Vector3(-6, 0, 0))

	if frame_count == 35:
		_cap("startup_simulator_east_road.png", "East Road & Archway to Borgo Valdocco")
		# Borgo Valdocco Plaza
		_set_cam(Vector3(62.2, 1.85, 27.5), Vector3(0, -86, 0), Vector3(-6, 0, 0))

	if frame_count == 40:
		_cap("startup_simulator_valdocco_plaza.png", "Borgo Valdocco Plaza & Officina Exterior")
		# Mercato Nord, Ufficio Postale, BachecaMercato & Coworking OGR (vista attraverso Arco Nord)
		_set_cam(Vector3(78.6, 1.25, 15.6), Vector3(0, 2, 0), Vector3(-5, 0, 0))

	if frame_count == 45:
		_cap("startup_simulator_mercato_ogr.png", "Mercato Nord, Poste & Coworking OGR")
		# Officina Bellini Stage 1: Accept + 4/4 Scouting complete -> CYAN 3D Hologram Blueprints Ready!
		ContractManager.accept_factory_commission()
		for zid in ContractManager.FACTORY_SCOUT_ZONES:
			ContractManager.scout_factory_zone(zid, zid)
		_set_cam(Vector3(80.8, 1.75, 29.6), Vector3(0, -74, 0), Vector3(-8, 0, 0))

	if frame_count == 51:
		_cap("startup_simulator_factory_holograms.png", "Officina Bellini 3D Cyan Hologram Blueprints (Before Install)")
		# Officina Bellini Stage 2: Install solid hardware replacing holograms
		ShopManager.buy_hardware("hw_wifi_router", 1)
		ShopManager.buy_hardware("hw_server_tower", 1)
		ShopManager.buy_hardware("hw_workstation_pc", 2)
		ContractManager.mount_factory_wifi_hardware()
		ContractManager.install_factory_server()
		ContractManager.install_factory_pcs()
		_set_cam(Vector3(80.8, 1.75, 29.6), Vector3(0, -74, 0), Vector3(-8, 0, 0))

	if frame_count == 57:
		_cap("startup_simulator_factory_interior.png", "Officina Bellini Interior & Hardware Installed")
		# Active SideJob HUD + BachecaSanCarlo + glowing 3D Beacon
		SideJobManager.start_job("volantinaggio")
		SideJobManager.active_job["targets"][0] = "mailbox_sancarlo_est"
		SideJobManager._sync_active_waypoint()
		EventBus.side_job_started.emit("volantinaggio", SideJobManager.active_job.duplicate(true))
		_look_at_flat(Vector3(6.8, 1.45, 24.8), Vector3(8.5, 0.85, 16.5), -6.0)

	if frame_count == 63:
		_cap("startup_simulator_sidejob_hud.png", "Active SideJob HUD + Waypoint + 3D Beacon")
		SideJobManager.cancel_active_job()
		# Pizzeria Da Mario
		_set_cam(Vector3(0.0, 0.1, 29.2), Vector3(0, 180, 0), Vector3(-8, 0, 0))

	if frame_count == 68:
		_cap("startup_simulator_pizzeria_3d.png", "Pizzeria Da Mario Interior")
		# Elettronica TO facing Davide
		_set_cam(Vector3(11.6, 0.1, 20.5), Vector3(0, -90, 0), Vector3(-6, 0, 0))

	if frame_count == 73:
		_cap("startup_simulator_tech_shop_3d.png", "Elettronica TO Interior")
		# Caffe San Carlo facing Elena
		_set_cam(Vector3(-11.8, 0.1, 20.5), Vector3(0, 90, 0), Vector3(-5, 0, 0))

	if frame_count == 78:
		_cap("startup_simulator_cafe_3d.png", "Caffe San Carlo Interior")
		EventBus.shop_opened.emit("alimentari")

	if frame_count == 83:
		_cap("startup_simulator_shop_menu.png", "Borgo ShopMenu Alimentari (+ Zaino)")
		ShopManager.buy_to_backpack("cafe", "thermos_bicerin")
		ShopManager.buy_to_backpack("edicola", "barretta_tech")
		ShopManager.buy_hardware("hw_wifi_router", 1)
		ShopManager.buy_gadget("elettronica_componenti", "gadget_scarpe_pro")
		ShopManager.buy_gadget("elettronica_componenti", "gadget_scanner_wifi")
		var inv = get_tree().root.find_child("InventoryMenu", true, false)
		if inv:
			inv.open_inventory()

	if frame_count == 88:
		_cap("startup_simulator_inventory.png", "Zaino & Dotazioni Startup [Tab]")
		var inv = get_tree().root.find_child("InventoryMenu", true, false)
		if inv:
			inv.visible = false
		_set_cam(Vector3(15.5, 1.85, 28.0), Vector3(0, -90, 0), Vector3(-5, 0, 0))
		var wmap = get_tree().root.find_child("WorldMapMenu", true, false)
		if wmap:
			wmap.open_map()
			wmap._set_view("all")
			wmap.select_poi("officina_bellini")
			wmap._on_set_waypoint_pressed()

	if frame_count == 93:
		_cap("startup_simulator_world_map.png", "Mappa del Territorio 4 Quartieri / 14 POI")
		var wmap = get_tree().root.find_child("WorldMapMenu", true, false)
		if wmap:
			wmap.close_map()
		_set_cam(Vector3(15.5, 1.85, 28.0), Vector3(0, -90, 0), Vector3(-5, 0, 0))

	if frame_count == 98:
		_cap("startup_simulator_hud_waypoint.png", "HUD Segnavia Bussola & Comandi Rapidi")
		GameManager.clear_waypoint()
		ShopManager.buy_hardware("hw_wifi_router", 1)
		EventBus.shop_opened.emit("elettronica_componenti")

	if frame_count == 103:
		_cap("startup_simulator_shop_hardware.png", "Borgo Hardware Component ShopMenu")
		ContractManager.advance_tutorial_to_in_progress()
		ContractManager.complete_tutorial_contract()
		ContractManager.advance_contract_to_in_progress("caffe_san_carlo")
		ContractManager.complete_story_contract("caffe_san_carlo")
		ContractManager.advance_contract_to_in_progress("elettronica_to")
		ContractManager.complete_story_contract("elettronica_to")
		ContractManager.discover_new_lead(false)
		ContractManager.discover_new_lead(false)
		EventBus.computer_opened.emit()
		var comp = get_tree().root.find_child("ComputerScreen", true, false)
		if comp:
			comp._open_window(comp.freelance_window)

	if frame_count == 108:
		_cap("startup_simulator_freelance_hub.png", "TO-OS Freelance Hub Cards & Officina Tracker (v1.2)")
		var comp = get_tree().root.find_child("ComputerScreen", true, false)
		if comp:
			comp._open_window(comp.rack_window)

	if frame_count == 113:
		_cap("startup_simulator_rack_manager.png", "TO-OS Rack Manager")
		var comp = get_tree().root.find_child("ComputerScreen", true, false)
		if comp:
			comp._open_window(comp.shop_window)

	if frame_count == 118:
		_cap("startup_simulator_shop.png", "TorinoHardware & Client Hardware Grid")
		var comp = get_tree().root.find_child("ComputerScreen", true, false)
		if comp:
			comp._open_window(comp.talent_window)

	if frame_count == 123:
		_cap("startup_simulator_talent_hub.png", "Talent Hub HR")
		EmployeeManager.fire_employee("emp_luca")
		EmployeeManager.hire_employee("emp_sara")
		ContractManager.preferred_webforge_contract_id = "factory_bellini_web"
		EventBus.minigame_started.emit("web_forge")

	if frame_count == 128:
		var wf = get_tree().root.find_child("WebForge", true, false)
		if wf:
			wf.set_grid_layout_mode("bento")
			wf._on_palette_selected(5)
			wf.budget_slider.value = 340.0
			wf._on_component_chosen("header", "header_officina")
			wf._on_component_chosen("hero", "hero_officina")
			wf._on_component_chosen("body", "body_officina")
			wf._on_component_chosen("widget", "widget_officina")
			wf._on_component_chosen("footer", "footer_officina")

	if frame_count == 133:
		_cap("startup_simulator_webforge.png", "WebForge 5.0 Bento Grid, Asset Budget & 5-Block Composer")
		var wf = get_tree().root.find_child("WebForge", true, false)
		if wf:
			wf._on_opt_minify_pressed()
			if wf.code_lines_vbox.get_child_count() > 2:
				(wf.code_lines_vbox.get_child(2) as Button).pressed.emit()

	if frame_count == 138:
		_cap("startup_simulator_webforge_debug.png", "WebForge 5.0 Click-to-Patch AST Code Inspector")
		EventBus.minigame_started.emit("firewall_router")

	if frame_count == 143:
		_cap("startup_simulator_firewall.png", "NetShield Firewall Router")
		EventBus.computer_opened.emit()

	if frame_count == 148:
		_cap("startup_simulator_to_os.png", "TO-OS Desktop")
		get_tree().quit(0)
