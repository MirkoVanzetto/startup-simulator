extends Node
## Capture in-game Pause Menu

var frame_count: int = 0

func _process(_delta: float) -> void:
	frame_count += 1
	
	if frame_count == 10:
		var menu = get_tree().root.find_child("MainMenu", true, false)
		if menu:
			menu.visible = false
		GameManager.start_new_game()
		print("Started new game in 3D.")
		
	if frame_count == 25:
		# Simulate pressing ESC to open pause menu
		var pause_menu = get_tree().root.find_child("PauseMenu", true, false)
		if pause_menu:
			pause_menu.open_pause_menu()
			GameManager.change_state(GameManager.GameState.PAUSED)
			print("State: In-game Pause Menu opened via ESC.")
			
	if frame_count >= 40:
		var image = get_viewport().get_texture().get_image()
		if image:
			image.save_png("/home/antigravity/startup_simulator_pause_menu.png")
			print("✔ Pause Menu Screenshot Captured.")
		get_tree().quit(0)
