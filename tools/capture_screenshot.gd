extends Node
## Multi-screen capture utility for v1.0.0 Visual QA (Borgo San Carlo, Borgo Valdocco & WebForge 4.0)

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

func _process(_delta: float) -> void:
	frame_count += 1

	if frame_count == 5:
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

	if frame_count == 20:
		_cap("startup_simulator_studio_3d.png", "Studio 3D Interior")
		# Studio front door facade close-up looking North (-Z)
		_set_cam(Vector3(0.0, 1.45, 7.2), Vector3(0, 0, 0), Vector3(-2, 0, 0))

	if frame_count == 32:
		_cap("startup_simulator_studio_facade.png", "Studio Front Door Facade")
		# Via del Borgo looking South toward Piazza
		_set_cam(Vector3(0.0, 0.16, 5.0), Vector3(0, 180, 0), Vector3(-4, 0, 0))

	if frame_count == 44:
		_cap("startup_simulator_street_3d.png", "Via del Borgo San Carlo")
		# Piazza San Carlo
		_set_cam(Vector3(-1.8, 0.1, 13.5), Vector3(0, 168, 0), Vector3(-6, 0, 0))

	if frame_count == 56:
		_cap("startup_simulator_piazza_san_carlo.png", "Piazza San Carlo")
		# East connecting road looking East (-90 deg Y) through archway toward Borgo Valdocco
		_set_cam(Vector3(12.5, 1.85, 28.0), Vector3(0, -90, 0), Vector3(-6, 0, 0))

	if frame_count == 68:
		_cap("startup_simulator_east_road.png", "East Road & Archway to Borgo Valdocco")
		# Borgo Valdocco Plaza looking East toward well, houses & Officina Bellini
		_set_cam(Vector3(62.2, 1.85, 27.5), Vector3(0, -86, 0), Vector3(-6, 0, 0))

	if frame_count == 80:
		_cap("startup_simulator_valdocco_plaza.png", "Borgo Valdocco Plaza & Officina Exterior")
		# Install factory hardware so interior showcases Bellini, CNC, Wifi, Server Xeon & 2 CAD PCs
		ContractManager.accept_factory_commission()
		for zid in ContractManager.FACTORY_SCOUT_ZONES:
			ContractManager.scout_factory_zone(zid, zid)
		ShopManager.buy_hardware("hw_wifi_router", 1)
		ShopManager.buy_hardware("hw_server_tower", 1)
		ShopManager.buy_hardware("hw_workstation_pc", 2)
		ContractManager.mount_factory_wifi_hardware()
		ContractManager.install_factory_server()
		ContractManager.install_factory_pcs()
		# Look inside Officina Bellini (center at 85.0, 0, 27.5 rot -PI/2; doorway West side ~80.2)
		_set_cam(Vector3(80.8, 1.75, 29.6), Vector3(0, -74, 0), Vector3(-8, 0, 0))

	if frame_count == 92:
		_cap("startup_simulator_factory_interior.png", "Officina Bellini Interior & Hardware Installed")
		# Pizzeria Da Mario
		_set_cam(Vector3(0.0, 0.1, 29.2), Vector3(0, 180, 0), Vector3(-8, 0, 0))

	if frame_count == 104:
		_cap("startup_simulator_pizzeria_3d.png", "Pizzeria Da Mario Interior")
		# Elettronica TO facing Davide & hardware counter
		_set_cam(Vector3(11.6, 0.1, 20.5), Vector3(0, -90, 0), Vector3(-6, 0, 0))

	if frame_count == 116:
		_cap("startup_simulator_tech_shop_3d.png", "Elettronica TO Interior")
		# Caffe San Carlo facing Elena
		_set_cam(Vector3(-11.8, 0.1, 20.5), Vector3(0, 90, 0), Vector3(-5, 0, 0))

	if frame_count == 128:
		_cap("startup_simulator_cafe_3d.png", "Caffe San Carlo Interior")
		EventBus.shop_opened.emit("alimentari")

	if frame_count == 138:
		_cap("startup_simulator_shop_menu.png", "Borgo ShopMenu Alimentari")
		# Also capture Hardware Shop Menu (Elettronica TO Componenti)
		ShopManager.buy_hardware("hw_wifi_router", 1)
		EventBus.shop_opened.emit("elettronica_componenti")

	if frame_count == 148:
		_cap("startup_simulator_shop_hardware.png", "Borgo Hardware Component ShopMenu")
		# Populate realistic mid-game Freelance Hub state before TO-OS captures
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

	if frame_count == 158:
		_cap("startup_simulator_freelance_hub.png", "TO-OS Freelance Hub Cards & Officina Tracker")
		var comp = get_tree().root.find_child("ComputerScreen", true, false)
		if comp:
			comp._open_window(comp.rack_window)

	if frame_count == 168:
		_cap("startup_simulator_rack_manager.png", "TO-OS Rack Manager")
		var comp = get_tree().root.find_child("ComputerScreen", true, false)
		if comp:
			comp._open_window(comp.shop_window)

	if frame_count == 178:
		_cap("startup_simulator_shop.png", "TorinoHardware & Client Hardware Grid")
		var comp = get_tree().root.find_child("ComputerScreen", true, false)
		if comp:
			comp._open_window(comp.talent_window)

	if frame_count == 188:
		_cap("startup_simulator_talent_hub.png", "Talent Hub HR")
		# Open WebForge 4.0 on Officina Bellini Web project + Sara Debug hints
		EmployeeManager.fire_employee("emp_luca")
		EmployeeManager.hire_employee("emp_sara")
		ContractManager.preferred_webforge_contract_id = "factory_bellini_web"
		EventBus.minigame_started.emit("web_forge")

	if frame_count == 198:
		var wf = get_tree().root.find_child("WebForge", true, false)
		if wf:
			wf._on_palette_selected(5)
			wf._on_component_chosen("header", "header_officina")
			wf._on_component_chosen("hero", "hero_officina")
			wf._on_component_chosen("body", "body_officina")

	if frame_count == 206:
		_cap("startup_simulator_webforge.png", "WebForge 4.0 Spoiler-Free & Responsive Preview")
		var wf = get_tree().root.find_child("WebForge", true, false)
		if wf:
			wf._on_opt_minify_pressed()

	if frame_count == 216:
		_cap("startup_simulator_webforge_debug.png", "WebForge 4.0 Code Debug Tickets")
		# Firewall Router (should show Officina Bellini VLAN too!)
		EventBus.minigame_started.emit("firewall_router")

	if frame_count == 228:
		_cap("startup_simulator_firewall.png", "NetShield Firewall Router")
		EventBus.computer_opened.emit()

	if frame_count == 240:
		_cap("startup_simulator_to_os.png", "TO-OS Desktop")
		get_tree().quit(0)
