extends Node
## Multi-screen capture utility for visual QA documentation

var frame_count: int = 0

func _process(_delta: float) -> void:
	frame_count += 1
	
	if frame_count == 10:
		# Start game & open computer
		var menu = get_tree().root.find_child("MainMenu", true, false)
		if menu:
			menu.visible = false
		GameManager.start_new_game()
		EventBus.computer_opened.emit()
		print("State: Computer TO-OS opened.")
		
	if frame_count == 25:
		var image = get_viewport().get_texture().get_image()
		if image:
			image.save_png("/home/antigravity/startup_simulator_to_os.png")
			print("✔ TO-OS Screen Captured.")
		# Now launch WebForge
		EventBus.minigame_started.emit("web_forge")
		print("State: WebForge IDE launched.")
		
	if frame_count == 40:
		# Check all 5 components in WebForge
		var wf = get_tree().root.find_child("WebForge", true, false)
		if wf:
			wf.chk_header.button_pressed = true
			wf.chk_hero.button_pressed = true
			wf.chk_menu.button_pressed = true
			wf.chk_hours.button_pressed = true
			wf.chk_booking.button_pressed = true
			wf._update_website_preview()
			print("State: WebForge all 5 components activated.")
			
	if frame_count == 55:
		var image = get_viewport().get_texture().get_image()
		if image:
			image.save_png("/home/antigravity/startup_simulator_webforge.png")
			print("✔ WebForge Screen Captured.")
		get_tree().quit(0)
