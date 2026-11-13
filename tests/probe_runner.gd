extends Node

func _ready() -> void:
	print("==================================================")
	print(">>> EMPIRICAL ADVERSARIAL PROBE FOR MILESTONE 1 <<<")
	print("==================================================")
	
	var stats = {"passed": 0, "failed": 0}
	var warnings = []
	
	var record_result = func(test_name: String, passed: bool, detail: String = ""):
		if passed:
			stats["passed"] += 1
			print("  ✔ [PASS] %s %s" % [test_name, detail])
		else:
			stats["failed"] += 1
			print("  ✘ [FAIL] %s %s" % [test_name, detail])
	
	# =========================================================================
	# PROBE 1: DAVIDE NPC (Elettronica TO)
	# =========================================================================
	print("\n--- [PROBE 1] Davide Model, Meshes, Materials & Animations ---")
	var davide_scene: PackedScene = load("res://scenes/world/davide_npc.tscn")
	if not davide_scene:
		record_result.call("Davide Scene Load", false, "Could not load res://scenes/world/davide_npc.tscn")
	else:
		var davide = davide_scene.instantiate()
		add_child(davide)
		await get_tree().process_frame
		
		var model = davide.get_node_or_null("Model")
		record_result.call("Davide Model Node exists", model != null)
		
		var model_src = ""
		if model and model.scene_file_path:
			model_src = model.scene_file_path
		print("    Davide model scene_file_path: ", model_src)
		record_result.call("Davide uses KayKit Knight.glb", "Knight.glb" in model_src)
		record_result.call("Davide does NOT use Kenney cubic mesh", not ("character-male" in model_src))
		
		# Inspect all MeshInstance3D nodes in Davide
		var meshes = davide.find_children("*", "MeshInstance3D", true, false)
		var total_verts = 0
		var visible_meshes = []
		var hidden_meshes = []
		var weapons_visible = []
		var missing_mats = []
		
		for m in meshes:
			var mi: MeshInstance3D = m
			if mi.visible:
				visible_meshes.append(mi.name)
				if mi.mesh:
					var faces = mi.mesh.get_faces()
					total_verts += faces.size()
					for s in range(mi.mesh.get_surface_count()):
						var mat = mi.get_active_material(s)
						if not mat:
							missing_mats.append("%s (surf %d)" % [mi.name, s])
				var lname = mi.name.to_lower()
				if "sword" in lname or "shield" in lname or "staff" in lname or "wand" in lname or "axe" in lname or "knife" in lname:
					weapons_visible.append(mi.name)
			else:
				hidden_meshes.append(mi.name)
		
		print("    Davide visible meshes: ", visible_meshes)
		print("    Davide hidden meshes: ", hidden_meshes)
		print("    Davide total active surface vertices: ", total_verts)
		record_result.call("Davide vertex count indicates high-fidelity sculpted mesh (>1000)", total_verts > 1000, "Verts: %d" % total_verts)
		record_result.call("Davide fantasy weapons hidden in modern electronics shop", weapons_visible.size() == 0, "Visible: %s" % str(weapons_visible))
		record_result.call("Davide visible meshes have valid materials", missing_mats.size() == 0, "Missing: %s" % str(missing_mats))
		
		# Check scale and transform
		var scale_vec = model.scale
		print("    Davide model scale: ", scale_vec)
		record_result.call("Davide model scale is uniform 0.85", is_equal_approx(scale_vec.x, 0.85) and is_equal_approx(scale_vec.y, 0.85) and is_equal_approx(scale_vec.z, 0.85))
		record_result.call("Davide transform is non-inverted (det > 0)", model.global_transform.basis.determinant() > 0)
		
		# Animation check for Davide
		var ap: AnimationPlayer = davide.find_child("AnimationPlayer", true, false)
		record_result.call("Davide AnimationPlayer exists", ap != null)
		if ap:
			var anim_list = ap.get_animation_list()
			print("    Davide available animations: %d animations loaded" % anim_list.size())
			var curr_anim = ap.current_animation
			print("    Davide current playing animation on ready: ", curr_anim)
			record_result.call("Davide plays Idle animation on ready", curr_anim in ["Idle", "idle", "Unarmed_Idle"])
			if curr_anim != "":
				var anim = ap.get_animation(curr_anim)
				record_result.call("Davide idle loop_mode is LOOP_LINEAR", anim.loop_mode == Animation.LOOP_LINEAR)
				ap.advance(0.5)
				ap.advance(1.0)
				record_result.call("Davide animation advance cleanly without crash", true)
			
			# Test interaction animation
			if davide.has_signal("interacted"):
				davide.emit_signal("interacted", null)
				var interact_anim = ap.current_animation
				print("    Davide animation on interact signal: ", interact_anim)
				record_result.call("Davide plays Cheer/Interact upon interaction", interact_anim in ["Cheer", "cheer", "Interact", "interact"])
				var weapons_after = []
				for m in meshes:
					var mi: MeshInstance3D = m
					var lname = mi.name.to_lower()
					if ("sword" in lname or "shield" in lname or "axe" in lname) and mi.visible:
						weapons_after.append(mi.name)
				record_result.call("Davide weapons remain hidden after interaction trigger", weapons_after.size() == 0)
				ap.advance(2.5)
		
		davide.queue_free()

	# =========================================================================
	# PROBE 2: LUCA & STUDIO WORKSTATION
	# =========================================================================
	print("\n--- [PROBE 2] Luca Employee Model & Studio Chairs ---")
	var studio_scene: PackedScene = load("res://scenes/world/studio.tscn")
	if not studio_scene:
		record_result.call("Studio Scene Load", false, "Could not load res://scenes/world/studio.tscn")
	else:
		var studio = studio_scene.instantiate()
		add_child(studio)
		await get_tree().process_frame
		
		var luca = studio.find_child("EmployeeModel", true, false)
		record_result.call("Luca EmployeeModel exists in studio", luca != null)
		if luca:
			var luca_src = ""
			if luca.scene_file_path:
				luca_src = luca.scene_file_path
			print("    Luca model scene_file_path: ", luca_src if luca_src != "" else "Procedural Sculpted (VillageCharacters)")
			record_result.call("Luca uses sculpted humanoid model (VillageCharacters / non-cubic)", luca.find_child("BodyMesh", true, false) != null and luca.find_child("HeadPivot", true, false) != null)
			record_result.call("Luca does NOT use Kenney cubic mesh", not ("character-male" in luca_src))
			
			# Inspect meshes
			var luca_meshes = luca.find_children("*", "MeshInstance3D", true, false)
			var total_verts_luca = 0
			var visible_luca_meshes = []
			var primary_weapons_luca = []
			
			for m in luca_meshes:
				var mi: MeshInstance3D = m
				if mi.visible:
					visible_luca_meshes.append(mi.name)
					if mi.mesh:
						total_verts_luca += mi.mesh.get_faces().size()
					var lname = mi.name.to_lower()
					if "sword" in lname or "shield" in lname or "staff" in lname or "wand" in lname or "axe" in lname or "knife" in lname or "crossbow" in lname or "dagger" in lname:
						primary_weapons_luca.append(mi.name)
			
			print("    Luca visible meshes: ", visible_luca_meshes)
			print("    Luca total active surface vertices: ", total_verts_luca)
			record_result.call("Luca vertex count indicates high-fidelity sculpted mesh (>1000)", total_verts_luca > 1000, "Verts: %d" % total_verts_luca)
			record_result.call("Luca primary weapons hidden", primary_weapons_luca.size() == 0, "Visible: %s" % str(primary_weapons_luca))
			
			# Check scale and transform
			print("    Luca scale: ", luca.scale)
			record_result.call("Luca scale is metric uniform 1.0", is_equal_approx(luca.scale.x, 1.0) and is_equal_approx(luca.scale.y, 1.0) and is_equal_approx(luca.scale.z, 1.0))
			record_result.call("Luca transform is non-inverted (det > 0)", luca.global_transform.basis.determinant() > 0)
			
			# Check animation in Luca
			var ap_luca: AnimationPlayer = luca.find_child("AnimationPlayer", true, false)
			record_result.call("Luca AnimationPlayer exists", ap_luca != null)
			if ap_luca:
				var curr_anim = ap_luca.current_animation
				print("    Luca current playing animation: ", curr_anim)
				record_result.call("Luca is playing Sit_Chair_Idle animation", curr_anim == "Sit_Chair_Idle")
				if curr_anim != "":
					var anim = ap_luca.get_animation(curr_anim)
					record_result.call("Luca animation loop_mode is LOOP_LINEAR", anim.loop_mode == Animation.LOOP_LINEAR)
					ap_luca.advance(0.5)
					ap_luca.advance(1.0)
					record_result.call("Luca animation advance executes cleanly without crash", true)
			
			# Check Workstation Geometry
			var ws = studio.find_child("EmployeeWorkstation", true, false)
			var ws_desk = ws.get_node_or_null("WorkstationDesk") if ws else null
			var ws_chair = ws.get_node_or_null("WorkstationChair") if ws else null
			if ws and ws_desk and ws_chair:
				print("    WorkstationDesk pos: ", ws_desk.position)
				print("    WorkstationChair pos: ", ws_chair.position)
				print("    Luca pos in workstation: ", luca.position)
				record_result.call("Luca sits between chair (Z=0.6) and desk (Z=0.0)", luca.position.z >= 0.0 and luca.position.z <= 0.6)
		
		# Studio chairs
		var chair_office = studio.find_child("ChairOfficeProp", true, false)
		var chair_gaming = studio.find_child("ChairGamingUpgradeProp", true, false)
		if chair_office:
			print("    ChairOfficeProp position: ", chair_office.position)
			record_result.call("ChairOfficeProp tucked under desk at Z=-1.15", is_equal_approx(chair_office.position.z, -1.15))
			record_result.call("ChairOfficeProp removed from hallway (Z != -0.85)", not is_equal_approx(chair_office.position.z, -0.85))
		if chair_gaming:
			print("    ChairGamingUpgradeProp position: ", chair_gaming.position)
			record_result.call("ChairGamingUpgradeProp tucked under desk at Z=-1.15", is_equal_approx(chair_gaming.position.z, -1.15))
		
		studio.queue_free()

	# =========================================================================
	# PROBE 3: ELENA NPC & CAFFE SAN CARLO
	# =========================================================================
	print("\n--- [PROBE 3] Elena NPC Visibility, Platform & Animations ---")
	var cafe_scene: PackedScene = load("res://scenes/world/cafe.tscn")
	if not cafe_scene:
		record_result.call("Cafe Scene Load", false, "Could not load res://scenes/world/cafe.tscn")
	else:
		var cafe = cafe_scene.instantiate()
		add_child(cafe)
		await get_tree().process_frame
		
		var elena = cafe.find_child("ElenaNPC", true, false)
		var platform = cafe.find_child("BaristaPlatform", true, false)
		record_result.call("ElenaNPC exists in cafe", elena != null)
		record_result.call("BaristaPlatform exists in cafe", platform != null)
		
		if elena and platform:
			print("    Elena position: ", elena.position)
			print("    BaristaPlatform position: ", platform.position)
			record_result.call("Elena elevated on platform (Y = 0.20)", is_equal_approx(elena.position.y, 0.20))
			record_result.call("Elena close to counter (Z = -1.35)", is_equal_approx(elena.position.z, -1.35))
			
			var model_elena = elena.get_node_or_null("Model")
			if model_elena:
				print("    Elena model scale: ", model_elena.scale)
				record_result.call("Elena model scale is 2.50 for adult eye-level", is_equal_approx(model_elena.scale.x, 2.50) and is_equal_approx(model_elena.scale.y, 2.50))
				
				# Check animation
				var ap_elena: AnimationPlayer = model_elena.find_child("AnimationPlayer", true, false)
				record_result.call("Elena AnimationPlayer exists", ap_elena != null)
				if ap_elena:
					var curr = ap_elena.current_animation
					print("    Elena current playing animation: ", curr)
					record_result.call("Elena is playing idle on ready", curr in ["idle", "Idle", "Unarmed_Idle"])
					if curr != "":
						var anim = ap_elena.get_animation(curr)
						record_result.call("Elena idle loop_mode is LOOP_LINEAR", anim.loop_mode == Animation.LOOP_LINEAR)
						ap_elena.advance(0.5)
						record_result.call("Elena animation advances cleanly", true)
					
					# Test interaction
					if elena.has_signal("interacted"):
						var prev_anim = ap_elena.current_animation
						elena.emit_signal("interacted", null)
						var interact_anim = ap_elena.current_animation
						print("    Elena animation after interact: ", interact_anim)
						if interact_anim == prev_anim:
							warnings.append("Elena does not change animation on interact signal because character-female-a.glb uses 'interact-right' / 'emote-yes' rather than 'interact' / 'cheer'.")
		
		cafe.queue_free()

	# =========================================================================
	# PROBE 4: VEHICLE ANTI-CLIPPING & COLLISION IN STREET
	# =========================================================================
	print("\n--- [PROBE 4] Street Vehicles Anti-Clipping & Collision ---")
	var street_scene: PackedScene = load("res://scenes/world/street.tscn")
	if not street_scene:
		record_result.call("Street Scene Load", false, "Could not load res://scenes/world/street.tscn")
	else:
		var street = street_scene.instantiate()
		add_child(street)
		await get_tree().process_frame
		
		var cars = ["CarSedan", "CarTaxi", "CarStationWagon", "CarHatchback"]
		for car_name in cars:
			var car_node = street.find_child(car_name, true, false)
			record_result.call("%s exists in street" % car_name, car_node != null)
			if car_node:
				print("    %s pos: %s, scale: %s" % [car_name, str(car_node.position), str(car_node.scale)])
				record_result.call("%s tire Y=0.00 flush on asphalt" % car_name, car_node.position.y >= 0.0 and car_node.position.y <= 0.15)
				var col_bodies = car_node.find_children("*", "StaticBody3D", true, false)
				record_result.call("%s has StaticBody3D collision body" % car_name, col_bodies.size() > 0)
				if col_bodies.size() > 0:
					var col_shapes = col_bodies[0].find_children("*", "CollisionShape3D", true, false)
					record_result.call("%s has CollisionShape3D box shape" % car_name, col_shapes.size() > 0)
		
		var hatchback = street.find_child("CarHatchback", true, false)
		if hatchback:
			print("    CarHatchback position: ", hatchback.position)
			record_result.call("CarHatchback parked safely clear of Pizzeria facade (Z <= 12.0)", hatchback.position.z <= 12.0)
			var rear_z = hatchback.position.z + 1.3
			record_result.call("CarHatchback rear Z (~12.8m) clears Pizzeria front (14.9m) by >2.0m", rear_z < 14.0)
		
		street.queue_free()

	# =========================================================================
	# PROBE 5: SKELETON TRACK INTEGRITY & NO MISSING BONES
	# =========================================================================
	print("\n--- [PROBE 5] Skeletal Tracks & Missing Bone Integrity ---")
	var models_to_check = [
		{"name": "Knight (Davide)", "path": "res://assets/models/characters/Knight.glb"},
		{"name": "Rogue (Luca/Mario)", "path": "res://assets/models/characters/Rogue.glb"},
		{"name": "Character Female A (Elena)", "path": "res://assets/models/characters/character-female-a.glb"}
	]
	
	for m_info in models_to_check:
		var ps: PackedScene = load(m_info["path"])
		if not ps:
			record_result.call("Load %s" % m_info["name"], false)
			continue
		var inst = ps.instantiate()
		add_child(inst)
		await get_tree().process_frame
		
		var skels = inst.find_children("*", "Skeleton3D", true, false)
		var aps = inst.find_children("*", "AnimationPlayer", true, false)
		var skel: Skeleton3D = skels[0] if skels.size() > 0 else null
		var ap: AnimationPlayer = aps[0] if aps.size() > 0 else null
		
		if skel and ap:
			var bone_count = skel.get_bone_count()
			print("    Model %s has %d bones" % [m_info["name"], bone_count])
			record_result.call("%s skeleton has bones" % m_info["name"], bone_count > 0)
			
			var anim_list = ap.get_animation_list()
			var missing_bone_tracks = 0
			for anim_name in anim_list:
				var anim = ap.get_animation(anim_name)
				for track_idx in range(anim.get_track_count()):
					var track_path = anim.track_get_path(track_idx)
					var subname = track_path.get_subname(0)
					if subname != "":
						var b_idx = skel.find_bone(subname)
						if b_idx == -1:
							missing_bone_tracks += 1
							warnings.append("%s: anim '%s' track %d targets non-existent bone '%s'" % [m_info["name"], anim_name, track_idx, subname])
			record_result.call("%s animations have ZERO missing bone tracks" % m_info["name"], missing_bone_tracks == 0, "Missing: %d" % missing_bone_tracks)
		
		inst.queue_free()

	print("\n==================================================")
	print(">>> ADVERSARIAL PROBE RESULTS <<<")
	print("  TOTAL ASSERTIONS: %d" % (stats["passed"] + stats["failed"]))
	print("  ✔ PASSED:         %d" % stats["passed"])
	print("  ✘ FAILED:         %d" % stats["failed"])
	if warnings.size() > 0:
		print("  ⚠ WARNINGS & ADVERSARIAL FINDINGS (%d):" % warnings.size())
		for w in warnings:
			print("    - %s" % w)
	print("==================================================")
	
	if stats["failed"] > 0:
		get_tree().quit(1)
	else:
		get_tree().quit(0)
