extends Node
## Multi-screen capture utility for visual QA documentation

var frame_count: int = 0
var player = null

func _process(_delta: float) -> void:
	frame_count += 1
	
	if frame_count == 5:
		var menu = get_tree().root.find_child("MainMenu", true, false)
		if menu:
			menu.visible = false
		var intro = get_tree().root.find_child("IntroMonologue", true, false)
		if intro:
			intro.start_intro()
		print("State: Intro Monologue displayed.")
		
	if frame_count == 15:
		var image = get_viewport().get_texture().get_image()
		if image:
			image.save_png("/home/antigravity/startup_simulator_intro.png")
			print("✔ Intro Monologue Screen Captured.")
			
		var intro = get_tree().root.find_child("IntroMonologue", true, false)
		if intro:
			intro.visible = false
		GameManager.start_new_game()
		player = get_tree().root.find_child("PlayerCharacter", true, false)
		if player:
			# Look directly at desk, laptop, and diploma (along negative Z)
			player.global_position = Vector3(0, 0.1, 0.6)
			player.rotation_degrees = Vector3(0, 0, 0)
			var neck = player.get_node_or_null("Neck")
			if neck:
				neck.rotation_degrees = Vector3(-12, 0, 0) # slight tilt down at desk
		print("State: In Studio 3D facing desk & laptop.")
		
	if frame_count == 30:
		var image = get_viewport().get_texture().get_image()
		if image:
			image.save_png("/home/antigravity/startup_simulator_studio_3d.png")
			print("✔ Studio 3D Screen Captured.")
			
		# Teleport player into street looking south towards Pizzeria (along positive Z)
		if player:
			player.global_position = Vector3(0, 0.1, 4.5)
			player.rotation_degrees = Vector3(0, 180, 0)
			var neck = player.get_node_or_null("Neck")
			if neck:
				neck.rotation_degrees = Vector3(0, 0, 0)
		print("State: In Street 3D facing Via Po and Pizzeria.")
		
	if frame_count == 45:
		var image = get_viewport().get_texture().get_image()
		if image:
			image.save_png("/home/antigravity/startup_simulator_street_3d.png")
			print("✔ Street 3D Screen Captured.")
			
		# Teleport player inside Pizzeria facing Mario, Counter, and Oven (along positive Z)
		if player:
			player.global_position = Vector3(-0.8, 0.1, 16.2)
			player.rotation_degrees = Vector3(0, 180, 0)
			var neck = player.get_node_or_null("Neck")
			if neck:
				neck.rotation_degrees = Vector3(-8, 0, 0)
		print("State: Inside Pizzeria 3D facing Mario.")
		
	if frame_count == 60:
		var image = get_viewport().get_texture().get_image()
		if image:
			image.save_png("/home/antigravity/startup_simulator_pizzeria_3d.png")
			print("✔ Pizzeria 3D Screen Captured.")
			
		# Advance tutorial to in_progress and open WebForge
		ContractManager.advance_tutorial_to_in_progress()
		EventBus.minigame_started.emit("web_forge")
		var wf = get_tree().root.find_child("WebForge", true, false)
		if wf:
			wf.chk_header.button_pressed = true
			wf.chk_hero.button_pressed = true
			wf.chk_menu.button_pressed = true
			wf.chk_hours.button_pressed = true
			wf.chk_booking.button_pressed = true
			wf._update_website_preview()
		print("State: WebForge IDE open with 5 components.")
		
	if frame_count == 75:
		var image = get_viewport().get_texture().get_image()
		if image:
			image.save_png("/home/antigravity/startup_simulator_webforge.png")
			print("✔ WebForge Screen Captured.")
		get_tree().quit(0)
