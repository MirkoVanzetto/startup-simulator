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
		GameManager.reputation_points = 35
		EconomyManager.balance = 1200.0
		EmployeeManager.hire_employee("emp_luca")
		
		var studio_mgr = get_tree().root.find_child("Studio", true, false)
		if studio_mgr and studio_mgr.has_method("update_installed_upgrades"):
			studio_mgr.update_installed_upgrades()

			studio_mgr.update_employee_workstation()
			
		player = get_tree().root.find_child("PlayerCharacter", true, false)
		if player:
			# Look across studio to see player desk with monitor & employee workstation with Luca
			player.global_position = Vector3(1.4, 0.1, 0.8)
			player.rotation_degrees = Vector3(0, 50, 0) # Look toward (-1.8, 0, 0.6)
			var neck = player.get_node_or_null("Neck")
			if neck:
				neck.rotation_degrees = Vector3(-6, 0, 0)
		print("State: In Studio 3D with Hired Employee & Server Rack.")
		
	if frame_count == 20:
		var image = get_viewport().get_texture().get_image()
		if image:
			image.save_png("/home/antigravity/startup_simulator_studio_3d.png")
			print("✔ Studio 3D with Employee Screen Captured.")
			
		# Teleport player into street looking toward Elettronica TO and Caffè San Carlo at Z=8.4
		if player:
			player.global_position = Vector3(0.0, 0.1, 4.5)
			player.rotation_degrees = Vector3(0, 180, 0)
			var neck = player.get_node_or_null("Neck")
			if neck:
				neck.rotation_degrees = Vector3(0, 0, 0)
		print("State: In Street 3D facing TechShop & Cafe.")
		
	if frame_count == 35:
		var image = get_viewport().get_texture().get_image()
		if image:
			image.save_png("/home/antigravity/startup_simulator_street_3d.png")
			print("✔ Street 3D with New Venues Screen Captured.")
			
		# Teleport player inside Elettronica TO facing Davide behind counter
		# Shop is at (-6.2, 0, 8.4) rotated -90 deg. Counter is at world X=-5.4, Z=9.0. Davide is at X=-4.75, Z=9.0
		if player:
			player.global_position = Vector3(-5.0, 0.1, 8.4)
			player.rotation_degrees = Vector3(0, -90, 0)
			var neck = player.get_node_or_null("Neck")
			if neck:
				neck.rotation_degrees = Vector3(-5, 0, 0)
		print("State: Inside Elettronica TO facing Davide.")
		
	if frame_count == 50:
		var image = get_viewport().get_texture().get_image()
		if image:
			image.save_png("/home/antigravity/startup_simulator_tech_shop_3d.png")
			print("✔ Elettronica TO Tech Shop Screen Captured.")
			
		# Teleport player inside Caffè San Carlo facing Elena behind bar
		# Cafe is at (+6.2, 0, 8.4) rotated +90 deg.
		if player:
			player.global_position = Vector3(5.0, 0.1, 8.4)
			player.rotation_degrees = Vector3(0, 90, 0)
			var neck = player.get_node_or_null("Neck")
			if neck:
				neck.rotation_degrees = Vector3(-5, 0, 0)
		print("State: Inside Caffè San Carlo facing Elena.")
		
	if frame_count == 65:
		var image = get_viewport().get_texture().get_image()
		if image:
			image.save_png("/home/antigravity/startup_simulator_cafe_3d.png")
			print("✔ Caffè San Carlo Screen Captured.")
			
		# Open TO-OS Desktop and display RackManager
		EventBus.computer_opened.emit()
		var comp = get_tree().root.find_child("ComputerScreen", true, false)
		if comp:
			comp._open_window(comp.rack_window)
		print("State: TO-OS Desktop - RackManager Window.")
		
	if frame_count == 80:
		var image = get_viewport().get_texture().get_image()
		if image:
			image.save_png("/home/antigravity/startup_simulator_rack_manager.png")
			print("✔ Rack Manager Screen Captured.")
			
		var comp = get_tree().root.find_child("ComputerScreen", true, false)
		if comp:
			comp._open_window(comp.talent_window)
		print("State: TO-OS Desktop - TalentHub Window.")
		
	if frame_count == 95:
		var image = get_viewport().get_texture().get_image()
		if image:
			image.save_png("/home/antigravity/startup_simulator_talent_hub.png")
			print("✔ Talent Hub Screen Captured.")
		get_tree().quit(0)
