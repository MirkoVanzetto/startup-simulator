extends Node
## Capture Pizzeria Interior with Mario and the Wood-Fired Oven

var frame_count: int = 0

func _process(_delta: float) -> void:
	frame_count += 1
	
	if frame_count == 5:
		var menu = get_tree().root.find_child("MainMenu", true, false)
		if menu:
			menu.visible = false
		GameManager.start_new_game()
		
		# Move player to inside Pizzeria Da Mario facing Mario and the counter
		var player = GameManager.player_node
		if player:
			player.global_position = Vector3(0.0, 0.1, 16.5)
			player.rotation.y = deg_to_rad(0) # Face south into the pizzeria
			var neck = player.get_node_or_null("Neck")
			if neck:
				neck.rotation.x = deg_to_rad(-5) # Slight tilt
		print("Player teleported inside Pizzeria Da Mario.")
		
	if frame_count >= 40:
		var image = get_viewport().get_texture().get_image()
		if image:
			image.save_png("/home/antigravity/startup_simulator_pizzeria_3d.png")
			print("✔ Pizzeria 3D Screenshot Captured.")
		get_tree().quit(0)
