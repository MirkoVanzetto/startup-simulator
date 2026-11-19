extends Node
## Multi-screen capture utility for Visual QA (fast cadence for Mesa llvmpipe)
## Covers: Borgo San Carlo, Parco Valentino Ovest, Viale Est, Borgo Valdocco,
## Mercato Nord / OGR / Poste, Borgo Po / Viale Lungo Po / Molo sul Po / Incubatore / Lab Droni,
## Officina Bellini 3D Holograms vs Installed Hardware, MakeHuman CC0 NPCs + light PBR,
## Pizzeria oven CPUParticles3D smoke, SideJob HUD + Beacon, WorldMap 19 POIs,
## TO-OS Conoscenza R&D & WebForge 5.0.

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

	if "--v16-only" in OS.get_cmdline_user_args():
		_process_v16_only()
		return
	if "--v16-part2" in OS.get_cmdline_user_args():
		_process_v16_part2()
		return

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

	if frame_count == 16:
		_cap("startup_simulator_studio_facade.png", "Studio Front Door Facade")
		_set_cam(Vector3(0.0, 0.16, 5.0), Vector3(0, 180, 0), Vector3(-4, 0, 0))

	if frame_count == 22:
		_cap("startup_simulator_street_3d.png", "Via del Borgo San Carlo")
		_set_cam(Vector3(-2.6, 0.25, 13.8), Vector3(0, -148, 0), Vector3(-6, 0, 0))

	if frame_count == 28:
		_cap("startup_simulator_piazza_san_carlo.png", "Piazza San Carlo & Bacheca Lavori")
		_look_at_flat(Vector3(-48.5, 0.35, 36.4), Vector3(-40.5, 0.0, 21.0), -6.0)

	if frame_count == 34:
		_cap("startup_simulator_parco_valentino.png", "Parco Valentino Ovest (Laghetto & Gazebo)")
		_look_at_flat(Vector3(56.5, 0.35, 30.2), Vector3(37.5, 0.0, 22.8), -3.5)

	if frame_count == 40:
		_cap("startup_simulator_east_road.png", "East Road & Archway to Borgo Valdocco")
		_set_cam(Vector3(62.2, 1.85, 27.5), Vector3(0, -86, 0), Vector3(-6, 0, 0))

	if frame_count == 46:
		_cap("startup_simulator_valdocco_plaza.png", "Borgo Valdocco Plaza & Officina Exterior")
		_set_cam(Vector3(78.6, 1.25, 15.6), Vector3(0, 2, 0), Vector3(-5, 0, 0))

	if frame_count == 52:
		_cap("startup_simulator_mercato_ogr.png", "Mercato Nord, Poste & OGR Facade")
		# OGR Gate Locked shot BEFORE unlocking Via Po & Officina Bellini
		_look_at_flat(Vector3(90.5, 0.08, 3.65), Vector3(96.3, 1.5, 2.75), -2.0)

	if frame_count == 58:
		_cap("startup_simulator_ogr_locked_gate.png", "OGR Locked Physical Gate Barrier")
		# Officina Bellini Stage 1: Accept + 4/4 Scouting complete -> CYAN 3D Hologram Blueprints Ready!
		ContractManager.accept_factory_commission()
		for zid in ContractManager.FACTORY_SCOUT_ZONES:
			ContractManager.scout_factory_zone(zid, zid)
		_set_cam(Vector3(80.8, 1.75, 29.6), Vector3(0, -74, 0), Vector3(-8, 0, 0))

	if frame_count == 64:
		_cap("startup_simulator_factory_holograms.png", "Officina Bellini 3D Cyan Hologram Blueprints (Before Install)")
		# Officina Bellini Stage 2: Install solid hardware replacing holograms
		ShopManager.buy_hardware("hw_wifi_router", 1)
		ShopManager.buy_hardware("hw_server_tower", 1)
		ShopManager.buy_hardware("hw_workstation_pc", 2)
		ContractManager.mount_factory_wifi_hardware()
		ContractManager.install_factory_server()
		ContractManager.install_factory_pcs()
		_set_cam(Vector3(80.8, 1.75, 29.6), Vector3(0, -74, 0), Vector3(-8, 0, 0))

	if frame_count == 70:
		_cap("startup_simulator_factory_interior.png", "Officina Bellini Interior & Hardware Installed")
		# Complete all 4 initial missions so OGR physical gate & Conoscenza R&D unlock!
		ContractManager.advance_tutorial_to_in_progress()
		ContractManager.complete_tutorial_contract()
		ContractManager.advance_contract_to_in_progress("caffe_san_carlo")
		ContractManager.complete_story_contract("caffe_san_carlo")
		ContractManager.advance_contract_to_in_progress("elettronica_to")
		ContractManager.complete_story_contract("elettronica_to")
		ContractManager.complete_factory_wifi_netshield()
		ContractManager.mark_contract_built("factory_bellini_web", {"score": 98})
		ContractManager.complete_marketplace_contract("factory_bellini_web")
		# Inside Unlocked OGR Tech Hub Torino (27.5m x 24.5m hall, Bay 01, Closed Pods, Coworkers & Ing. Andrea Viale)
		_look_at_flat(Vector3(97.8, 0.08, 1.8), Vector3(111.0, 1.5, 3.4), -2.5)

	if frame_count == 78:
		_cap("startup_simulator_ogr_hall_3d.png", "OGR Tech Hub Unlocked Interior & Bay 01")
		# MakeHuman Character Closeup: Ing. Andrea Viale inside sunlit OGR hall
		_look_at_flat(Vector3(103.35, -0.14, 2.52), Vector3(104.8, 1.45, 2.2), -5.0)

	if frame_count == 85:
		_cap("startup_simulator_character_closeup.png", "MakeHuman CC0 NPC & Light PBR Closeup (Ing. Andrea Viale)")
		# Pizzeria Da Mario interior: domed wood-fired brick oven with CPUParticles3D smoke & Mario MakeHuman rig
		_look_at_flat(Vector3(-0.65, 0.06, 27.95), Vector3(1.55, 1.48, 32.65), -1.0)

	if frame_count == 93:
		_cap("startup_simulator_pizzeria_3d.png", "Pizzeria Da Mario Interior (Oven CPUParticles3D Smoke)")
		# Alimentari Rosa interior: loaded jar/fruit shelves, crates, kraft bags & tile_bw floor
		_look_at_flat(Vector3(5.95, 0.05, 7.8), Vector3(10.2, 0.95, 7.8), -10.0)

	if frame_count == 100:
		_cap("startup_simulator_alimentari_3d.png", "Alimentari Rosa Interior (Shelves, Crates & B/W Tiles)")
		# Borgo Po / Viale Lungo Po / Molo sul Po / Fiume Po panoramic view
		_look_at_flat(Vector3(11.8, 0.90, 61.6), Vector3(17.8, 0.15, 69.2), -7.0)

	if frame_count == 107:
		_cap("startup_simulator_borgopo_3d.png", "Borgo Po, Viale Lungo Po, Lab Droni & Molo sul Fiume Po")
		# Night Sky & Streetlamps across Borgo San Carlo (22:30 starry Torino night + moon)
		var dnc = get_tree().root.find_child("DayNightController", true, false)
		if dnc:
			dnc.set_debug_hour(22.5)
		_look_at_flat(Vector3(2.8, 0.08, 25.5), Vector3(-5.0, 2.0, 8.0), 11.5)

	if frame_count == 114:
		_cap("startup_simulator_night_3d.png", "Borgo San Carlo Night Cycle (22:30 Stars, Moon & Streetlamps)")
		var dnc = get_tree().root.find_child("DayNightController", true, false)
		if dnc:
			dnc.clear_debug_hour()
		# Active SideJob HUD + BachecaSanCarlo + glowing 3D Beacon
		SideJobManager.start_job("volantinaggio")
		SideJobManager.active_job["targets"][0] = "mailbox_sancarlo_est"
		SideJobManager._sync_active_waypoint()
		EventBus.side_job_started.emit("volantinaggio", SideJobManager.active_job.duplicate(true))
		_look_at_flat(Vector3(6.8, 1.45, 24.8), Vector3(8.5, 0.85, 16.5), -6.0)

	if frame_count == 121:
		_cap("startup_simulator_sidejob_hud.png", "Active SideJob HUD + Waypoint + 3D Beacon")
		SideJobManager.cancel_active_job()
		# Elettronica TO facing Davide
		_set_cam(Vector3(11.6, 0.1, 20.5), Vector3(0, -90, 0), Vector3(-6, 0, 0))

	if frame_count == 127:
		_cap("startup_simulator_tech_shop_3d.png", "Elettronica TO Interior")
		# Caffe San Carlo facing Elena
		_set_cam(Vector3(-11.8, 0.1, 20.5), Vector3(0, 90, 0), Vector3(-5, 0, 0))

	if frame_count == 133:
		_cap("startup_simulator_cafe_3d.png", "Caffe San Carlo Interior")
		# Forno Bruno facing marble counter, scored loaves, wicker baskets & flour sack
		_look_at_flat(Vector3(-5.80, 0.12, 7.72), Vector3(-9.60, 0.0, 7.82), -10.5)

	if frame_count == 139:
		_cap("startup_simulator_forno_3d.png", "Forno Bruno Interior")
		EventBus.shop_opened.emit("alimentari")

	if frame_count == 145:
		_cap("startup_simulator_shop_menu.png", "Borgo ShopMenu Alimentari (+ Zaino)")
		ShopManager.buy_to_backpack("cafe", "thermos_bicerin")
		ShopManager.buy_to_backpack("edicola", "barretta_tech")
		ShopManager.buy_hardware("hw_wifi_router", 1)
		ShopManager.buy_gadget("elettronica_componenti", "gadget_scarpe_pro")
		ShopManager.buy_gadget("elettronica_componenti", "gadget_scanner_wifi")
		var inv = get_tree().root.find_child("InventoryMenu", true, false)
		if inv:
			inv.open_inventory()

	if frame_count == 151:
		_cap("startup_simulator_inventory.png", "Zaino & Dotazioni Startup [Tab]")
		var inv = get_tree().root.find_child("InventoryMenu", true, false)
		if inv:
			inv.visible = false
		_set_cam(Vector3(15.5, 1.85, 28.0), Vector3(0, -90, 0), Vector3(-5, 0, 0))
		var wmap = get_tree().root.find_child("WorldMapMenu", true, false)
		if wmap:
			wmap.open_map()
			wmap._set_view("all")
			wmap.select_poi("miniera_alpina")

	if frame_count == 157:
		_cap("startup_simulator_world_map.png", "World Map All 20 POIs (Miniera Alpina, Parco, San Carlo, Valdocco, OGR, Borgo Po)")
		var wmap = get_tree().root.find_child("WorldMapMenu", true, false)
		if wmap:
			wmap.close_map()
		EventBus.shop_opened.emit("elettronica_componenti")

	if frame_count == 163:
		_cap("startup_simulator_shop_hardware.png", "Borgo Hardware Component ShopMenu")
		EconomyManager.balance = 6000.0
		GameManager.reputation_points = 120
		KnowledgeManager.study("web_architecture")
		KnowledgeManager.study("cloud_devops")
		ContractManager.discover_new_lead(false)
		ContractManager.discover_new_lead(false)
		UpgradeManager.add_stars(4, "")
		EventBus.computer_opened.emit()

	if frame_count == 169:
		_cap("startup_simulator_to_os_desktop.png", "TO-OS 26.4 Desktop Workspace & 11-App Grid")
		var comp = get_tree().root.find_child("ComputerScreen", true, false)
		if comp:
			UpgradeManager.purchase("agility")
			comp.open_app("upgrades")

	if frame_count == 175:
		_cap("startup_simulator_upgrades.png", "TO-OS Potenziamenti ★ Skill Tree")
		var comp = get_tree().root.find_child("ComputerScreen", true, false)
		if comp:
			comp.open_app("knowledge")

	if frame_count == 181:
		_cap("startup_simulator_knowledge.png", "TO-OS Conoscenza R&D Unlocked (4 Tracks)")
		var comp = get_tree().root.find_child("ComputerScreen", true, false)
		if comp:
			comp.open_app("ogr")

	if frame_count == 187:
		_cap("startup_simulator_ogr_enterprise.png", "TO-OS OGR Enterprise Tenders")
		var comp = get_tree().root.find_child("ComputerScreen", true, false)
		if comp:
			comp.open_app("freelance")

	if frame_count == 193:
		_cap("startup_simulator_freelance_hub.png", "TO-OS Freelance Hub Cards (+ R&D Specialty)")
		var comp = get_tree().root.find_child("ComputerScreen", true, false)
		if comp:
			comp.open_app("rack")

	if frame_count == 199:
		_cap("startup_simulator_rack_manager.png", "TO-OS Rack Manager (+ Cloud R&D)")
		var comp = get_tree().root.find_child("ComputerScreen", true, false)
		if comp:
			comp.open_app("mail")

	if frame_count == 205:
		_cap("startup_simulator_to_os.png", "TO-OS Mail Over Wallpaper")
		var web_cid := ""
		for mc in ContractManager.marketplace_contracts:
			if mc is Dictionary and str(mc.get("execution_type", "webforge")) == "webforge":
				web_cid = str(mc.get("id", ""))
				ContractManager.accept_marketplace_contract(web_cid)
				break
		if web_cid == "":
			for ec in ContractManager.enterprise_contracts:
				if ec is Dictionary and str(ec.get("execution_type", "webforge")) == "webforge":
					web_cid = str(ec.get("id", ""))
					ContractManager.accept_enterprise_contract(web_cid)
					break
		ContractManager.preferred_webforge_contract_id = web_cid
		EventBus.minigame_started.emit("web_forge")

	if frame_count == 211:
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

	if frame_count == 217:
		_cap("startup_simulator_webforge.png", "WebForge 5.0 Bento Grid & 5-Block Composer")
		EventBus.minigame_started.emit("firewall_router")

	if frame_count == 223:
		_cap("startup_simulator_firewall.png", "NetShield Firewall Router")
		# Chiude tutte le UI modali ed entra in gameplay per catturare pedoni, Miniera Alpina & Drone in volo!
		for ui_name in ["FirewallRouter", "WebForge", "ComputerScreen", "ShopMenu", "InventoryMenu", "WorldMapMenu", "DialogueOverlay"]:
			var unode = get_tree().root.find_child(ui_name, true, false)
			if unode:
				unode.visible = false
		GameManager.change_state(GameManager.GameState.FIRST_PERSON)
		# Popola TechOps (Robot MK1/MK2, Nastro Trasportatore & TO-Drone MK1 in volo attivo!)
		EconomyManager.balance = 40000.0
		TechOpsManager.start_ogr_tech_mission()
		TechOpsManager.add_research_credits(250, "Visual QA")
		for m in TechOpsManager.MATERIAL_ORDER:
			TechOpsManager.materials_storage[m] = 35
		TechOpsManager.research_branch("tech_automation")
		TechOpsManager.research_branch("tech_automation")
		TechOpsManager.research_branch("tech_automation")
		TechOpsManager.research_branch("tech_drone_avionics")
		TechOpsManager.research_branch("tech_drone_avionics")
		TechOpsManager.build_mining_robot(1)
		TechOpsManager.build_mining_robot(2)
		TechOpsManager.unlock_conveyor()
		for _step in range(7):
			TechOpsManager.install_next_drone_step()
		TechOpsManager.start_drone_mission("drone_lidar_survey")
		# Avanza leggermente animazioni città e macchinari
		var city_life = get_tree().root.find_child("CityLifeManager", true, false)
		var yard = get_tree().root.find_child("OGRTechOpsYard", true, false)
		for _k in range(12):
			if city_life:
				city_life._process(0.12)
			if yard:
				yard._process(0.12)
		# Inquadra pedone in Piazza San Carlo (camminata reale su suolo Y=0)
		var ped = get_tree().root.find_child("Pedestrian_Piazza_2", true, false) as Node3D
		if ped:
			var ppos: Vector3 = ped.global_position
			_look_at_flat(ppos + Vector3(3.6, 0.25, 3.6), ppos + Vector3(0.0, 1.05, 0.0), -6.0)
		else:
			_look_at_flat(Vector3(-3.5, 0.25, 22.0), Vector3(-7.5, 1.0, 18.0), -6.0)

	if frame_count == 234:
		_cap("startup_simulator_pedestrians_walk.png", "Walking Pedestrians (MakeHuman Walk Cycle & Grounded)")
		if player:
			player.set_physics_process(false)
		# Vista panoramica elevata da Parco Valentino verso l'arco Nord e tutta la Miniera Alpina con le Alpi
		_look_at_flat(Vector3(-41.5, 5.2, 18.5), Vector3(-46.0, 1.8, -26.0), -11.0)

	if frame_count == 242:
		_cap("startup_simulator_mine_overview.png", "Parco Archway & Miniera Alpina Val di Susa Overview")
		# Galleria Estrattiva 01, carrello minerario sui binari, gru di cava e filoni cristallini
		_look_at_flat(Vector3(-42.2, 0.35, -23.0), Vector3(-46.5, 1.5, -36.5), -3.5)

	if frame_count == 250:
		_cap("startup_simulator_mine_tunnel_veins.png", "Miniera Alpina Galleria 01, MineCart, QuarryCrane & Veins")
		# Zona operativa: FerreroNPC in caschetto, Mining Robot MK1/MK2, Nastro Trasportatore & Raffineria con camino fumante
		_look_at_flat(Vector3(-48.5, 0.55, -10.5), Vector3(-42.5, 1.0, -19.5), -5.5)

	if frame_count == 258:
		_cap("startup_simulator_mine_robots_refinery.png", "Miniera Alpina FerreroNPC, Mining Robots MK1/2, Conveyor & Refinery")
		# Lab Droni Borgo Po: Dr.ssa Chiara Conti & TO-Drone MK1 in volo circolare sopra Piazzola H!
		_look_at_flat(Vector3(23.2, 0.25, 60.4), Vector3(24.0, 2.0, 52.8), 2.5)

	if frame_count == 268:
		_cap("startup_simulator_drone_flight.png", "Borgo Po Lab Droni · Flying TO-Drone MK1 & ChiaraNPC")
		if player:
			player.set_physics_process(true)
		var wmap = get_tree().root.find_child("WorldMapMenu", true, false)
		if wmap:
			wmap.open_map()
			wmap._set_view("miniera")
			wmap.select_poi("miniera_alpina")

	if frame_count == 275:
		_cap("startup_simulator_world_map_miniera.png", "World Map Miniera Alpina District Focus")
		get_tree().quit(0)


func _setup_v16_demo_state() -> void:
	for ui_name in ["FirewallRouter", "WebForge", "ComputerScreen", "ShopMenu", "InventoryMenu", "WorldMapMenu", "DialogueOverlay"]:
		var unode = get_tree().root.find_child(ui_name, true, false)
		if unode:
			unode.visible = false
	GameManager.change_state(GameManager.GameState.FIRST_PERSON)
	EconomyManager.balance = 40000.0
	ContractManager.advance_tutorial_to_in_progress()
	ContractManager.complete_tutorial_contract()
	ContractManager.advance_contract_to_in_progress("caffe_san_carlo")
	ContractManager.complete_story_contract("caffe_san_carlo")
	ContractManager.advance_contract_to_in_progress("elettronica_to")
	ContractManager.complete_story_contract("elettronica_to")
	ContractManager.accept_factory_commission()
	for zid in ContractManager.FACTORY_SCOUT_ZONES:
		ContractManager.scout_factory_zone(zid, zid)
	ShopManager.buy_hardware("hw_wifi_router", 1)
	ShopManager.buy_hardware("hw_server_tower", 1)
	ShopManager.buy_hardware("hw_workstation_pc", 2)
	ContractManager.mount_factory_wifi_hardware()
	ContractManager.complete_factory_wifi_netshield()
	ContractManager.install_factory_server()
	ContractManager.install_factory_pcs()
	ContractManager.mark_contract_built("factory_bellini_web", {"score": 98})
	ContractManager.complete_marketplace_contract("factory_bellini_web")

	TechOpsManager.start_ogr_tech_mission()
	TechOpsManager.add_research_credits(400, "Visual QA")
	for m in TechOpsManager.MATERIAL_ORDER:
		TechOpsManager.materials_storage[m] = 35
	TechOpsManager.research_branch("tech_automation")
	TechOpsManager.research_branch("tech_automation")
	TechOpsManager.research_branch("tech_automation")
	TechOpsManager.research_branch("tech_drone_avionics")
	TechOpsManager.research_branch("tech_drone_avionics")
	TechOpsManager.build_mining_robot(1)
	TechOpsManager.build_mining_robot(2)
	TechOpsManager.unlock_conveyor()
	for _step in range(7):
		TechOpsManager.install_next_drone_step()
	TechOpsManager.start_drone_mission("drone_lidar_survey")
	var dnc = get_tree().root.find_child("DayNightController", true, false)
	if dnc:
		dnc.set_debug_hour(11.5)
	var hud = get_tree().root.find_child("HUD", true, false)
	if hud and hud.get("toast_container"):
		for tc in hud.toast_container.get_children():
			tc.queue_free()
	EventBus.tech_ops_updated.emit()

	var city_life = get_tree().root.find_child("CityLifeManager", true, false)
	var yard = get_tree().root.find_child("OGRTechOpsYard", true, false)
	var heli = get_tree().root.find_child("DroneHelipadStation", true, false)
	for _k in range(18):
		if city_life:
			city_life._process(0.12)
		if yard:
			yard._process(0.12)
		if heli:
			heli._process(0.12)


func _process_v16_only() -> void:
	if frame_count == 3:
		var menu = get_tree().root.find_child("MainMenu", true, false)
		if menu:
			menu.visible = false
		GameManager.start_new_game()
		player = get_tree().root.find_child("PlayerCharacter", true, false)
		_setup_v16_demo_state()
		var ped = get_tree().root.find_child("Pedestrian_Piazza_2", true, false) as Node3D
		if ped:
			var ppos: Vector3 = ped.global_position
			_look_at_flat(ppos + Vector3(3.4, 0.20, 3.4), ppos + Vector3(0.0, 1.05, 0.0), -6.0)
		else:
			_look_at_flat(Vector3(-3.5, 0.20, 22.0), Vector3(-7.5, 1.0, 18.0), -6.0)

	if frame_count == 7:
		_cap("startup_simulator_pedestrians_walk.png", "Walking Pedestrians (MakeHuman Walk Cycle & Grounded)")
		if player:
			player.set_physics_process(false)
		_look_at_flat(Vector3(-41.5, 5.2, 18.5), Vector3(-46.0, 1.8, -26.0), -11.0)

	if frame_count == 11:
		_cap("startup_simulator_mine_overview.png", "Parco Archway & Miniera Alpina Val di Susa Overview")
		_look_at_flat(Vector3(-42.2, 0.35, -23.0), Vector3(-46.5, 1.5, -36.5), -3.5)

	if frame_count == 15:
		_cap("startup_simulator_mine_tunnel_veins.png", "Miniera Alpina Galleria 01, MineCart, QuarryCrane & Veins")
		_look_at_flat(Vector3(-48.5, 0.55, -10.5), Vector3(-42.5, 1.0, -19.5), -5.5)

	if frame_count == 19:
		_cap("startup_simulator_mine_robots_refinery.png", "Miniera Alpina FerreroNPC, Mining Robots MK1/2, Conveyor & Refinery")
		_look_at_flat(Vector3(23.2, 0.25, 60.4), Vector3(24.0, 2.0, 52.8), 2.5)

	if frame_count == 23:
		_cap("startup_simulator_drone_flight.png", "Borgo Po Lab Droni · Flying TO-Drone MK1 & ChiaraNPC")
		if player:
			player.set_physics_process(true)
		var wmap = get_tree().root.find_child("WorldMapMenu", true, false)
		if wmap:
			wmap.open_map()
			wmap._set_view("all")
			wmap.select_poi("miniera_alpina")

	if frame_count == 27:
		_cap("startup_simulator_world_map.png", "World Map All 20 POIs (Miniera Alpina, Parco, San Carlo, Valdocco, OGR, Borgo Po)")
		var wmap = get_tree().root.find_child("WorldMapMenu", true, false)
		if wmap:
			wmap._set_view("miniera")
			wmap.select_poi("miniera_alpina")

	if frame_count == 31:
		_cap("startup_simulator_world_map_miniera.png", "World Map Miniera Alpina District Focus")
		get_tree().quit(0)


func _process_v16_part2() -> void:
	if frame_count == 3:
		var menu = get_tree().root.find_child("MainMenu", true, false)
		if menu:
			menu.visible = false
		GameManager.start_new_game()
		GameManager.studio_upgrades_installed.append("monitor_upgrade")
		GameManager.studio_upgrades_installed.append("server_rack_upgrade")
		player = get_tree().root.find_child("PlayerCharacter", true, false)
		_setup_v16_demo_state()
		var wmap = get_tree().root.find_child("WorldMapMenu", true, false)
		if wmap:
			wmap.open_map()
			wmap._set_view("all")
			wmap.select_poi("miniera_alpina")

	if frame_count == 5:
		_cap("startup_simulator_world_map.png", "World Map All 20 POIs (Miniera Alpina, Parco, San Carlo, Valdocco, OGR, Borgo Po)")
		var wmap = get_tree().root.find_child("WorldMapMenu", true, false)
		if wmap:
			wmap._set_view("miniera")
			wmap.select_poi("miniera_alpina")

	if frame_count == 8:
		_cap("startup_simulator_world_map_miniera.png", "World Map Miniera Alpina District Focus")
		var wmap = get_tree().root.find_child("WorldMapMenu", true, false)
		if wmap:
			if wmap.has_method("close_map"):
				wmap.close_map()
			else:
				wmap.visible = false
		if player:
			player.set_physics_process(false)
		# Lab Droni Borgo Po: Dr.ssa Chiara Conti & TO-Drone MK1 in volo circolare sopra Piazzola H
		_look_at_flat(Vector3(18.8, 0.35, 55.5), Vector3(24.0, 2.0, 52.5), 2.5)

	if frame_count == 12:
		_cap("startup_simulator_drone_flight.png", "Borgo Po Lab Droni · Flying TO-Drone MK1 & ChiaraNPC")
		if player:
			player.set_physics_process(true)
		get_tree().quit(0)
