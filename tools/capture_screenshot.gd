extends Node
## Multi-screen capture utility for Milestones 5 & 6 visual QA documentation

var frame_count: int = 0
var player = null

func _process(_delta: float) -> void:
	frame_count += 1
	
	if frame_count == 5:
		var menu = get_tree().root.find_child("MainMenu", true, false)
		if menu:
			menu.visible = false
		GameManager.start_new_game()
		
		# Upgrade studio: Add monitor, aloe plant, server rack, and hire Luca Vianello
		GameManager.studio_upgrades_installed.append("monitor_upgrade")
		GameManager.studio_upgrades_installed.append("plant_aloe")
		GameManager.studio_upgrades_installed.append("server_rack_upgrade")
		ServerRackManager.unlock_server_rack()
		GameManager.company_tier = 2
		GameManager.reputation_points = 55
		EconomyManager.balance = 1200.0
		EmployeeManager.hire_employee("emp_luca")
		
		var studio_mgr = get_tree().root.find_child("Studio", true, false)
		if studio_mgr and studio_mgr.has_method("update_installed_upgrades"):
			studio_mgr.update_installed_upgrades()
			studio_mgr.update_employee_workstation()
			
		player = get_tree().root.find_child("PlayerCharacter", true, false)
		if player:
			# Frame across expanded 7.4x5.8m Studio from SE toward Player Desk, Cabinet, and Luca Workstation
			player.global_position = Vector3(2.1, 0.12, 1.45)
			player.rotation_degrees = Vector3(0, 44, 0)
			var neck = player.get_node_or_null("Neck")
			if neck:
				neck.rotation_degrees = Vector3(-11, 0, 0)
		print("State: In Studio 3D with Hired Employee & Server Rack.")
		
	if frame_count == 20:
		var image = get_viewport().get_texture().get_image()
		if image:
			image.save_png("/home/antigravity/startup_simulator_studio_3d.png")
			print("✔ Studio 3D with High-Tech Staging Screen Captured.")
			
		# Teleport player into street looking south down the wide Via Po Boulevard & Porticoes
		if player:
			player.global_position = Vector3(0.0, 0.16, 5.0)
			player.rotation_degrees = Vector3(0, 180, 0)
			var neck = player.get_node_or_null("Neck")
			if neck:
				neck.rotation_degrees = Vector3(-4, 0, 0)
		print("State: On Via Po Boulevard facing South towards Cross Street & Piazza.")
		
	if frame_count == 35:
		var image = get_viewport().get_texture().get_image()
		if image:
			image.save_png("/home/antigravity/startup_simulator_street_3d.png")
			print("✔ Via Po Boulevard & Porticoes Screen Captured.")
			
		# Teleport player into Piazza San Carlo facing Fontana, Edicola, Cafe, TechShop & Pizzeria
		if player:
			player.global_position = Vector3(-1.8, 0.1, 13.5)
			player.rotation_degrees = Vector3(0, 168, 0)
			var neck = player.get_node_or_null("Neck")
			if neck:
				neck.rotation_degrees = Vector3(-6, 0, 0)
		print("State: In Piazza San Carlo facing Fontana & Borgo.")
		
	if frame_count == 50:
		var image = get_viewport().get_texture().get_image()
		if image:
			image.save_png("/home/antigravity/startup_simulator_piazza_san_carlo.png")
			print("✔ Piazza San Carlo Screen Captured.")
			
		# Teleport player inside Pizzeria Da Mario (at Z=30.8 rot 180) facing Mario NPC
		if player:
			player.global_position = Vector3(0.0, 0.1, 29.2)
			player.rotation_degrees = Vector3(0, 180, 0)
			var neck = player.get_node_or_null("Neck")
			if neck:
				neck.rotation_degrees = Vector3(-8, 0, 0)
		print("State: Inside Pizzeria Da Mario facing Mario NPC.")

	if frame_count == 65:
		var image = get_viewport().get_texture().get_image()
		if image:
			image.save_png("/home/antigravity/startup_simulator_pizzeria_3d.png")
			print("✔ Pizzeria Da Mario Screen Captured.")
			
		# Teleport player inside Elettronica TO (+13.8, 0, 20.5) facing Davide
		if player:
			player.global_position = Vector3(11.8, 0.1, 20.5)
			player.rotation_degrees = Vector3(0, -90, 0)
			var neck = player.get_node_or_null("Neck")
			if neck:
				neck.rotation_degrees = Vector3(-5, 0, 0)
		print("State: Inside Elettronica TO facing Davide.")
		
	if frame_count == 80:
		var image = get_viewport().get_texture().get_image()
		if image:
			image.save_png("/home/antigravity/startup_simulator_tech_shop_3d.png")
			print("✔ Elettronica TO Tech Shop Screen Captured.")
			
		# Teleport player inside Caffè San Carlo (-13.8, 0, 20.5) facing Elena
		if player:
			player.global_position = Vector3(-11.8, 0.1, 20.5)
			player.rotation_degrees = Vector3(0, 90, 0)
			var neck = player.get_node_or_null("Neck")
			if neck:
				neck.rotation_degrees = Vector3(-5, 0, 0)
		print("State: Inside Caffè San Carlo facing Elena.")
		
	if frame_count == 95:
		var image = get_viewport().get_texture().get_image()
		if image:
			image.save_png("/home/antigravity/startup_simulator_cafe_3d.png")
			print("✔ Caffè San Carlo Screen Captured.")
			
		# Open Borgo ShopMenu (Alimentari Rosa)
		EventBus.shop_opened.emit("alimentari")
		print("State: ShopMenu Alimentari Rosa.")

	if frame_count == 103:
		var image = get_viewport().get_texture().get_image()
		if image:
			image.save_png("/home/antigravity/startup_simulator_shop_menu.png")
			print("✔ Borgo ShopMenu Screen Captured.")
			
		# Open TO-OS Desktop and display RackManager
		EventBus.computer_opened.emit()
		var comp = get_tree().root.find_child("ComputerScreen", true, false)
		if comp:
			comp._open_window(comp.rack_window)
		print("State: TO-OS Desktop - RackManager Window.")
		
	if frame_count == 110:
		var image = get_viewport().get_texture().get_image()
		if image:
			image.save_png("/home/antigravity/startup_simulator_rack_manager.png")
			print("✔ Rack Manager Screen Captured.")
			
		var comp = get_tree().root.find_child("ComputerScreen", true, false)
		if comp:
			comp._open_window(comp.shop_window)
		print("State: TO-OS Desktop - Shop Window.")
		
	if frame_count == 125:
		var image = get_viewport().get_texture().get_image()
		if image:
			image.save_png("/home/antigravity/startup_simulator_shop.png")
			print("✔ TorinoHardware 2-Column Shop Screen Captured.")
			
		var comp = get_tree().root.find_child("ComputerScreen", true, false)
		if comp:
			comp._open_window(comp.talent_window)
		print("State: TO-OS Desktop - TalentHub Window.")
		
	if frame_count == 140:
		var image = get_viewport().get_texture().get_image()
		if image:
			image.save_png("/home/antigravity/startup_simulator_talent_hub.png")
			print("✔ Talent Hub Screen Captured.")
			
		# Open WebForge IDE
		ContractManager.init_tutorial_contract()
		ContractManager.advance_tutorial_to_in_progress()
		EventBus.minigame_started.emit("web_forge")
		print("State: WebForge IDE v2.0.")
		
	if frame_count == 155:
		var image = get_viewport().get_texture().get_image()
		if image:
			image.save_png("/home/antigravity/startup_simulator_webforge.png")
			print("✔ WebForge IDE v2.0 Screen Captured.")
			
		# Open Firewall Router
		EventBus.minigame_started.emit("firewall_router")
		print("State: NetShield Firewall Router.")
		
	if frame_count == 170:
		var image = get_viewport().get_texture().get_image()
		if image:
			image.save_png("/home/antigravity/startup_simulator_firewall.png")
			print("✔ NetShield Firewall Routing Screen Captured.")
			
		# Return to Desktop
		EventBus.computer_opened.emit()
		print("State: TO-OS Desktop.")
		
	if frame_count == 185:
		var image = get_viewport().get_texture().get_image()
		if image:
			image.save_png("/home/antigravity/startup_simulator_to_os.png")
			print("✔ TO-OS Desktop Screen Captured.")
		get_tree().quit(0)
