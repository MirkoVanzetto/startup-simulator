extends Node
## Adversarial Empirical Probe for Milestone 1 (Physics & Geometry)
## Author: Challenger 1 (challenger_m1_1)
## Probes:
##   1. Vehicle boundaries, Pizzeria dining/entrance overlap, subterranean wheel Y, and vehicle solidity / anti-ghosting.
##   2. Elena counter occlusion & multi-angle sightline visibility from customer area.
##   3. Studio door-to-desk walkway clearance, chair collision bounds, laptop interactability.
##   4. Pedestrian corridor and venue entrance clearances in GameWorld.

var total_assertions: int = 0
var passed_assertions: int = 0
var failed_assertions: int = 0
var failure_details: Array[String] = []

func _ready() -> void:
	print("============================================================")
	print(">>> RUNNING ADVERSARIAL EMPIRICAL PROBES FOR MILESTONE 1 <<<")
	print("============================================================\n")
	
	await run_probe_1_vehicle_boundaries_and_collision()
	await run_probe_2_elena_sightlines_and_counter_visibility()
	await run_probe_3_studio_walkway_clearance_and_interaction()
	await run_probe_4_street_district_corridors_and_venues()
	
	print("\n============================================================")
	print(">>> ADVERSARIAL PROBE RESULTS SUMMARY <<<")
	print("============================================================")
	print("  TOTAL ASSERTIONS:  %d" % total_assertions)
	print("  PASSED ASSERTIONS: %d" % passed_assertions)
	print("  FAILED ASSERTIONS: %d" % failed_assertions)
	
	if failure_details.size() > 0:
		print("\n--- DETAILED FAILURE BREAKDOWN ---")
		for f in failure_details:
			print("  [FAIL] %s" % f)
		print("-----------------------------------")
	else:
		print("\n>>> ALL ADVERSARIAL PROBES PASSED EMPIRICALLY! <<<")
	print("============================================================\n")
	
	if failed_assertions > 0:
		get_tree().quit(1)
	else:
		get_tree().quit(0)

func record_assertion(passed: bool, name: String, detail: String = "") -> bool:
	total_assertions += 1
	if passed:
		passed_assertions += 1
		print("  ✔ [PASS] %s" % name)
		return true
	else:
		failed_assertions += 1
		var msg = "%s -> %s" % [name, detail]
		failure_details.append(msg)
		print("  ✘ [FAIL] %s" % msg)
		return false

# ==============================================================================
# PROBE 1: VEHICLE BOUNDARIES, PIZZERIA OVERLAP & COLLISION SOLIDITY
# ==============================================================================
func run_probe_1_vehicle_boundaries_and_collision() -> void:
	print("\n--- PROBE 1: VEHICLE BOUNDARIES, PIZZERIA OVERLAP & SOLIDITY ---")
	
	var world_scene = load("res://scenes/world/game_world.tscn")
	if not world_scene:
		record_assertion(false, "Load game_world.tscn", "Scene could not be loaded")
		return
		
	var world = world_scene.instantiate()
	add_child(world)
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	var street = world.get_node_or_null("Street")
	var pizzeria = world.get_node_or_null("Pizzeria")
	var player = world.get_node_or_null("PlayerCharacter")
	
	record_assertion(street != null, "Street scene instantiated in GameWorld")
	record_assertion(pizzeria != null, "Pizzeria scene instantiated in GameWorld")
	record_assertion(player != null, "PlayerCharacter instantiated in GameWorld")
	
	var props = street.get_node_or_null("StreetProps")
	record_assertion(props != null, "StreetProps exists")
	
	# Pizzeria in GameWorld is at Z = 18.0, rotated 180 deg around Y.
	# Entrance threshold is at world Z = 14.9.
	# Dining area spans world Z from 14.9 to 21.1, X from -3.6 to +3.6.
	var PIZZERIA_ENTRANCE_Z = 14.9
	var vehicles = ["CarSedan", "CarTaxi", "CarStationWagon", "CarHatchback"]
	
	for v_name in vehicles:
		var car = props.get_node_or_null(v_name)
		if not car:
			record_assertion(false, "Vehicle %s exists" % v_name, "Vehicle node missing from StreetProps")
			continue
			
		var car_global_pos = car.global_position
		
		# 1. Asphalt alignment check: tires must sit on asphalt (Y between 0.05 and 0.15)
		record_assertion(
			car_global_pos.y >= 0.05 and car_global_pos.y <= 0.15,
			"%s asphalt alignment (Y=%0.3f in [0.05, 0.15])" % [v_name, car_global_pos.y],
			"Car Y=%0.3f indicates subterranean wheel clipping or hovering" % car_global_pos.y
		)
		
		# 2. Collision Body Check
		var static_body: StaticBody3D = car.find_child("StaticBody3D", true, false)
		if not static_body and car is StaticBody3D:
			static_body = car
		
		record_assertion(static_body != null, "%s has StaticBody3D" % v_name, "Missing StaticBody3D")
		
		if static_body:
			record_assertion(
				(static_body.collision_layer & 1) != 0,
				"%s StaticBody3D collision_layer includes layer 1 (world collision)" % v_name,
				"collision_layer is %d, does not include bit 1" % static_body.collision_layer
			)
			
			var col_shape: CollisionShape3D = static_body.find_child("CollisionShape3D", true, false)
			record_assertion(col_shape != null, "%s has CollisionShape3D" % v_name, "Missing CollisionShape3D")
			
			if col_shape and col_shape.shape is BoxShape3D:
				var box: BoxShape3D = col_shape.shape
				var col_global_pos = col_shape.global_position
				var col_global_scale = col_shape.global_basis.get_scale()
				var half_size = (box.size * col_global_scale).abs() * 0.5
				
				var max_z = col_global_pos.z + half_size.z
				var min_z = col_global_pos.z - half_size.z
				var max_x = col_global_pos.x + half_size.x
				var min_x = col_global_pos.x - half_size.x
				
				# Check overlap with Pizzeria entrance Z=14.9
				var penetrates_pizzeria = (max_z >= PIZZERIA_ENTRANCE_Z and max_x > -3.6 and min_x < 3.6)
				record_assertion(
					not penetrates_pizzeria,
					"%s collision bounds [Z=%0.2f..%0.2f] do NOT penetrate Pizzeria entrance (Z >= %0.1f)" % [v_name, min_z, max_z, PIZZERIA_ENTRANCE_Z],
					"Collision box penetrates Pizzeria by %0.2f meters!" % (max_z - PIZZERIA_ENTRANCE_Z)
				)
				
				# Check collision box is reasonably sized (width >= 1.2, length >= 2.2, height >= 1.0)
				var eff_size = (box.size * col_global_scale).abs()
				record_assertion(
					eff_size.x >= 1.2 and eff_size.z >= 2.2 and eff_size.y >= 0.9,
					"%s collision volume (%0.2fx%0.2fx%0.2f) adequately covers car size" % [v_name, eff_size.x, eff_size.y, eff_size.z],
					"Collision box is too small (%0.2fx%0.2fx%0.2f), player could clip" % [eff_size.x, eff_size.y, eff_size.z]
				)
				
		# 3. Visual Mesh AABB bounds check against Pizzeria
		var meshes = car.find_children("", "MeshInstance3D", true, false)
		var combined_visual_max_z = -9999.0
		for m in meshes:
			var mi: MeshInstance3D = m
			if mi.mesh:
				var m_aabb = mi.mesh.get_aabb()
				var global_tf = mi.global_transform
				for corner_idx in range(8):
					var corner = m_aabb.get_endpoint(corner_idx)
					var world_pt = global_tf * corner
					if world_pt.z > combined_visual_max_z:
						combined_visual_max_z = world_pt.z
						
		if combined_visual_max_z > -9000.0:
			record_assertion(
				combined_visual_max_z < PIZZERIA_ENTRANCE_Z,
				"%s visual mesh max Z=%0.2f is clear of Pizzeria entrance (Z=%0.1f)" % [v_name, combined_visual_max_z, PIZZERIA_ENTRANCE_Z],
				"Visual mesh penetrates Pizzeria entrance by %0.2f meters!" % (combined_visual_max_z - PIZZERIA_ENTRANCE_Z)
			)
			
		# 4. Empirical Physics Test: Can player walk / ghost through this car?
		var test_body = CharacterBody3D.new()
		var test_shape = CollisionShape3D.new()
		var capsule = CapsuleShape3D.new()
		capsule.radius = 0.4
		capsule.height = 1.8
		test_shape.shape = capsule
		test_shape.position = Vector3(0, 0.9, 0)
		test_body.add_child(test_shape)
		test_body.collision_mask = 5 # Layer 1 & 3
		world.add_child(test_body)
		await get_tree().physics_frame
		
		# Test sweep from outside into car center from North, South, East, West
		var car_center = car_global_pos + Vector3(0, 0.6, 0)
		var directions = [
			Vector3(1, 0, 0),  # Sweeping from West (+X towards car)
			Vector3(-1, 0, 0), # Sweeping from East (-X towards car)
			Vector3(0, 0, 1),  # Sweeping from North (+Z towards car)
			Vector3(0, 0, -1)  # Sweeping from South (-Z towards car)
		]
		
		var blocked_count = 0
		for dir in directions:
			var start_pos = car_center - dir * 2.5
			start_pos.y = 0.1
			test_body.global_position = start_pos
			var motion = dir * 3.0
			var collision = test_body.test_move(test_body.global_transform, motion)
			if collision:
				blocked_count += 1
			else:
				print("    [Ghost Warning] Player did not collide with %s moving along %s from %s" % [v_name, dir, start_pos])
				
		record_assertion(
			blocked_count == 4,
			"%s blocks player penetration on all 4 approach vectors (4/4 blocked)" % v_name,
			"Player ghosted through vehicle on %d approach vectors!" % (4 - blocked_count)
		)
		
		test_body.queue_free()

	world.queue_free()

# ==============================================================================
# PROBE 2: ELENA COUNTER VISIBILITY & SIGHTLINES
# ==============================================================================
func run_probe_2_elena_sightlines_and_counter_visibility() -> void:
	print("\n--- PROBE 2: ELENA COUNTER VISIBILITY & SIGHTLINES ---")
	
	var cafe_scene = load("res://scenes/world/cafe.tscn")
	if not cafe_scene:
		record_assertion(false, "Load cafe.tscn", "Cannot load cafe scene")
		return
		
	var cafe = cafe_scene.instantiate()
	add_child(cafe)
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	var elena: Node3D = cafe.get_node_or_null("ElenaNPC")
	var platform: StaticBody3D = cafe.get_node_or_null("BaristaPlatform")
	record_assertion(elena != null, "ElenaNPC present in cafe scene")
	record_assertion(platform != null, "BaristaPlatform present in cafe scene")
	
	if not elena:
		cafe.queue_free()
		return
		
	# Check platform geometry
	if platform:
		var p_pos = platform.global_position
		record_assertion(
			p_pos.y >= 0.08 and p_pos.y <= 0.25,
			"Barista platform elevation Y=%0.2f provides physical step-up" % p_pos.y,
			"Barista platform Y=%0.2f out of expected elevation range" % p_pos.y
		)
		
	# Elena elevation & scale
	var elena_pos = elena.global_position
	record_assertion(
		elena_pos.y >= 0.18,
		"Elena feet elevated at Y=%0.2f (on platform behind counter)" % elena_pos.y,
		"Elena feet at Y=%0.2f, too low behind counter" % elena_pos.y
	)
	
	var elena_scale = elena.scale
	var model = elena.get_node_or_null("Model")
	var model_scale = model.scale if model else Vector3.ONE
	var combined_scale_y = elena_scale.y * model_scale.y
	record_assertion(
		combined_scale_y >= 2.2,
		"Elena combined vertical scale %0.2f gives proper human proportions" % combined_scale_y,
		"Elena scale %0.2f is undersized" % combined_scale_y
	)
	
	# Elena eye-level height in cafe space:
	# Base Y (0.20) + model height (~1.4m at scale 2.5) -> Head center is around Y = 1.60m - 1.70m
	var elena_head_pt = elena_pos + Vector3(0, 1.45, 0)
	var elena_chest_pt = elena_pos + Vector3(0, 1.05, 0)
	var elena_nametag_pt = elena_pos + Vector3(0, 2.25, 0)
	
	print("  [Info] Elena Head Target:    %s" % str(elena_head_pt))
	print("  [Info] Elena Chest Target:   %s" % str(elena_chest_pt))
	print("  [Info] Elena NameTag Target: %s" % str(elena_nametag_pt))
	
	# The counter top slab is at Y = 1.15m - 1.18m.
	# We conduct an adversarial multi-angle camera sightline test:
	# Grid of customer viewing positions in customer area:
	# X from -2.0 to +2.0 (step 0.5)
	# Z from -0.2 to +1.8 (step 0.5)
	# Eye height Y = 1.65 (player standard standing eye level) and Y = 1.40 (crouched / lower)
	var space_state = cafe.get_world_3d().direct_space_state
	record_assertion(space_state != null, "Cafe World3D direct_space_state is active")
	
	if not space_state:
		cafe.queue_free()
		return
		
	var customer_x_samples = [-2.0, -1.5, -1.0, -0.5, 0.0, 0.5, 1.0, 1.5, 2.0]
	var customer_z_samples = [-0.2, 0.3, 0.8, 1.3, 1.8]
	var camera_heights = [1.65, 1.40]
	
	var total_sightlines = 0
	var head_visible_sightlines = 0
	var nametag_visible_sightlines = 0
	var completely_hidden_count = 0
	
	for y_cam in camera_heights:
		for x_cam in customer_x_samples:
			for z_cam in customer_z_samples:
				total_sightlines += 1
				var cam_pos = Vector3(x_cam, y_cam, z_cam)
				
				# Ray to Elena's head
				var q_head = PhysicsRayQueryParameters3D.create(cam_pos, elena_head_pt)
				q_head.collision_mask = 1 # Only world obstacles (counter, walls)
				var hit_head = space_state.intersect_ray(q_head)
				var head_visible = hit_head.is_empty()
				if head_visible:
					head_visible_sightlines += 1
					
				# Ray to NameTag
				var q_name = PhysicsRayQueryParameters3D.create(cam_pos, elena_nametag_pt)
				q_name.collision_mask = 1
				var hit_name = space_state.intersect_ray(q_name)
				var name_visible = hit_name.is_empty()
				if name_visible:
					nametag_visible_sightlines += 1
					
				if not head_visible and not name_visible:
					completely_hidden_count += 1
					
	# Adversarial assertions:
	# 1. Zero customer angles where Elena is completely hidden
	record_assertion(
		completely_hidden_count == 0,
		"Elena is NEVER completely hidden from customer area (0/%d blind spots)" % total_sightlines,
		"Elena completely occluded from %d customer camera angles!" % completely_hidden_count
	)
	
	# 2. Standing head sightlines from primary customer zone (opposite counter X in [-1.0, 0.0])
	var primary_head_visible = true
	for z_cam in customer_z_samples:
		for x_cam in [-1.0, -0.5, 0.0]:
			var cam_pos = Vector3(x_cam, 1.65, z_cam)
			var q_head = PhysicsRayQueryParameters3D.create(cam_pos, elena_head_pt)
			q_head.collision_mask = 1
			var hit = space_state.intersect_ray(q_head)
			if not hit.is_empty():
				primary_head_visible = false
				print("    [Warning] Primary sightline hit at %s -> %s" % [cam_pos, hit.collider.name])
				
	record_assertion(
		primary_head_visible,
		"Elena head is 100% visible from all standing primary customer positions (X in [-1.0..0.0])",
		"Counter or prop occludes Elena head along central customer counter"
	)
	
	cafe.queue_free()

# ==============================================================================
# PROBE 3: STUDIO WALKWAY CLEARANCE & INTERACTION
# ==============================================================================
func run_probe_3_studio_walkway_clearance_and_interaction() -> void:
	print("\n--- PROBE 3: STUDIO WALKWAY CLEARANCE & INTERACTION ---")
	
	var studio_scene = load("res://scenes/world/studio.tscn")
	if not studio_scene:
		record_assertion(false, "Load studio.tscn", "Cannot load studio scene")
		return
		
	var studio = studio_scene.instantiate()
	add_child(studio)
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	var desk = studio.get_node_or_null("Furniture/DeskProp")
	var chair_office = studio.get_node_or_null("Furniture/ChairOfficeProp")
	var chair_gaming = studio.get_node_or_null("Upgrades/ChairGamingUpgradeProp")
	var laptop = studio.get_node_or_null("Furniture/LaptopProp")
	
	record_assertion(desk != null, "DeskProp exists in studio")
	record_assertion(chair_office != null, "ChairOfficeProp exists in studio")
	record_assertion(laptop != null, "LaptopProp exists in studio")
	
	# 1. Chair position check: must NOT be at (0, 0, -0.85) blocking walkway
	var chair_pos = chair_office.transform.origin
	record_assertion(
		chair_pos.z <= -1.10,
		"Chair tucked under desk at Z=%0.2f (Z <= -1.10, clear of old blocking Z=-0.85)" % chair_pos.z,
		"Chair is placed at Z=%0.2f, obstructing walkway" % chair_pos.z
	)
	
	# 2. Check gaming chair position if present
	if chair_gaming:
		var g_pos = chair_gaming.transform.origin
		record_assertion(
			g_pos.z <= -1.10,
			"Gaming chair upgrade aligned under desk at Z=%0.2f (Z <= -1.10)" % g_pos.z,
			"Gaming chair placed at Z=%0.2f, obstructing walkway" % g_pos.z
		)
		
	# 3. Walkway Corridor Clearance Raycasts & Sweeps:
	# Door is at Z = 2.5, Desk is at Z = -1.5.
	# Corridor from door Z=2.3 to front of workstation Z=-0.75 along X = 0.
	var space_state = studio.get_world_3d().direct_space_state
	record_assertion(space_state != null, "Studio World3D direct_space_state is active")
	
	# Raycast sweep along center line at player foot (0.2m), waist (0.9m), eye (1.65m)
	var heights = [0.2, 0.9, 1.65]
	var corridor_clear = true
	for h in heights:
		var start = Vector3(0, h, 2.3)
		var end = Vector3(0, h, -0.75)
		var q = PhysicsRayQueryParameters3D.create(start, end)
		q.collision_mask = 1
		var hit = space_state.intersect_ray(q)
		if not hit.is_empty():
			corridor_clear = false
			print("    [Obstruction] Ray at Y=%0.2f hit %s at %s" % [h, hit.collider.name, hit.position])
			
	record_assertion(
		corridor_clear,
		"Central corridor from door (Z=2.3) to workstation (Z=-0.75) is 100% raycast clear",
		"Corridor is obstructed by static collision"
	)
	
	# Character sweep test: player walks from door Z=2.2 to front of workstation chair at Z=-0.45
	var test_player = CharacterBody3D.new()
	var test_col = CollisionShape3D.new()
	var cap = CapsuleShape3D.new()
	cap.radius = 0.35 # Realistic collision radius for indoor corridor navigation
	cap.height = 1.8
	test_col.shape = cap
	test_col.position = Vector3(0, 0.9, 0)
	test_player.add_child(test_col)
	test_player.collision_mask = 5
	studio.add_child(test_player)
	await get_tree().physics_frame
	
	test_player.global_position = Vector3(0, 0.1, 2.2)
	# Move 2.65m forward (-Z) to arrive directly at workstation chair (stopping at Z=-0.45)
	var walk_collision = test_player.test_move(test_player.global_transform, Vector3(0, 0, -2.65))
	record_assertion(
		not walk_collision,
		"Player capsule walks cleanly from door (Z=2.2) to workstation chair (Z=-0.45) without snagging",
		"Player capsule snagged on obstacle during door-to-chair transit"
	)
	
	# Verify that advancing further than Z=-0.475 correctly encounters the solid chair
	var chair_block = test_player.test_move(Transform3D(Basis(), Vector3(0, 0.1, -0.45)), Vector3(0, 0, -0.5))
	record_assertion(
		chair_block,
		"Office chair is physically solid (blocks player from clipping through chair to Z < -0.80)",
		"Chair lacks physical collision (ghost chair allows walking through it)"
	)
	
	# 4. Laptop interactability from workstation position (Z = -0.75)
	var laptop_pos = laptop.global_position
	var player_reach_dist = Vector3(0, 1.65, -0.75).distance_to(laptop_pos)
	record_assertion(
		player_reach_dist <= 2.2,
		"Laptop is within comfortable interaction distance (%0.2fm <= 2.2m) from workstation position",
		"Laptop is too far (%0.2fm) to interact comfortably"
	)
	
	# 5. Upgrades & Workstation isolation:
	# Verify EmployeeWorkstation does not encroach on central corridor X in [-0.5, 0.5]
	var emp_station = studio.get_node_or_null("EmployeeWorkstation")
	if emp_station:
		var emp_pos = emp_station.position
		record_assertion(
			emp_pos.x <= -1.2 or emp_pos.x >= 1.2,
			"EmployeeWorkstation is offset to side at X=%0.2f (leaves central aisle open)" % emp_pos.x,
			"EmployeeWorkstation encroaches on central corridor at X=%0.2f" % emp_pos.x
		)
		
	test_player.queue_free()
	studio.queue_free()

# ==============================================================================
# PROBE 4: STREET DISTRICT CORRIDORS & VENUE CLEARANCES
# ==============================================================================
func run_probe_4_street_district_corridors_and_venues() -> void:
	print("\n--- PROBE 4: STREET DISTRICT CORRIDORS & VENUE ACCESS ---")
	
	var world_scene = load("res://scenes/world/game_world.tscn")
	if not world_scene:
		record_assertion(false, "Load game_world.tscn for street check", "Cannot load")
		return
		
	var world = world_scene.instantiate()
	add_child(world)
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	var street = world.get_node_or_null("Street")
	record_assertion(street != null, "Street exists in GameWorld")
	
	var space_state = world.get_world_3d().direct_space_state
	record_assertion(space_state != null, "GameWorld space_state is active")
	
	# 1. Pedestrian corridor along X = 0 from Studio exit (Z = 1.0) to Pizzeria front (Z = 14.5)
	var z_checkpoints = [1.0, 3.0, 5.0, 7.0, 9.0, 11.0, 13.0, 14.5]
	var street_walkway_clear = true
	for i in range(z_checkpoints.size() - 1):
		var p1 = Vector3(0, 1.0, z_checkpoints[i])
		var p2 = Vector3(0, 1.0, z_checkpoints[i + 1])
		var q = PhysicsRayQueryParameters3D.create(p1, p2)
		q.collision_mask = 1
		var hit = space_state.intersect_ray(q)
		if not hit.is_empty():
			street_walkway_clear = false
			print("    [Street Obstacle] Corridor segment [%0.1f..%0.1f] blocked by %s" % [z_checkpoints[i], z_checkpoints[i + 1], hit.collider.name])
			
	record_assertion(
		street_walkway_clear,
		"Pedestrian street boulevard corridor (Z=1.0..14.5) is 100% unobstructed along centerline",
		"Street centerline contains collision obstruction"
	)
	
	# 2. TechShop Entrance corridor: crossing street from (0, 1.0, 8.4) to (-4.5, 1.0, 8.4)
	var q_tech = PhysicsRayQueryParameters3D.create(Vector3(0, 1.0, 8.4), Vector3(-4.5, 1.0, 8.4))
	q_tech.collision_mask = 1
	var hit_tech = space_state.intersect_ray(q_tech)
	record_assertion(
		hit_tech.is_empty(),
		"Crosswalk approach to TechShop venue is unobstructed",
		"TechShop approach blocked by %s" % (hit_tech.collider.name if not hit_tech.is_empty() else "unknown")
	)
	
	# 3. Cafe Entrance and Sidewalk Access:
	# Note: CarTaxi is parked along the eastern road curb at (1.6, 0.08, 8.2).
	# Because CarTaxi has genuine physical collision, a direct line from (0, 1.0, 8.4) to (4.5, 1.0, 8.4)
	# correctly hits the vehicle side. We verify:
	# a) CarTaxi blocks direct road crossing at Z=8.4 (confirming it is solid, not ghosted)
	var q_cafe_direct = PhysicsRayQueryParameters3D.create(Vector3(0, 1.0, 8.4), Vector3(4.5, 1.0, 8.4))
	q_cafe_direct.collision_mask = 1
	var hit_direct = space_state.intersect_ray(q_cafe_direct)
	record_assertion(
		not hit_direct.is_empty() and "CarTaxi" in hit_direct.collider.get_parent().name,
		"Parked CarTaxi at (1.6, 0.08, 8.2) is physically solid along east curb lane",
		"CarTaxi failed to provide solid curb collision"
	)
	
	# b) North crossway approach around CarTaxi (Z = 6.5) from street to sidewalk (X = 3.6) is clear
	var q_cafe_north = PhysicsRayQueryParameters3D.create(Vector3(0, 1.0, 6.5), Vector3(3.6, 1.0, 6.5))
	q_cafe_north.collision_mask = 1
	var hit_north = space_state.intersect_ray(q_cafe_north)
	record_assertion(
		hit_north.is_empty(),
		"Pedestrian street crossing north of CarTaxi (Z=6.5) to East sidewalk is 100% unobstructed",
		"North crossing blocked by %s" % (hit_north.collider.name if not hit_north.is_empty() else "unknown")
	)
	
	# c) South crossway approach around CarTaxi (Z = 10.0) from street to sidewalk (X = 3.6) is clear
	var q_cafe_south = PhysicsRayQueryParameters3D.create(Vector3(0, 1.0, 10.0), Vector3(3.6, 1.0, 10.0))
	q_cafe_south.collision_mask = 1
	var hit_south = space_state.intersect_ray(q_cafe_south)
	record_assertion(
		hit_south.is_empty(),
		"Pedestrian street crossing south of CarTaxi (Z=10.0) to East sidewalk is 100% unobstructed",
		"South crossing blocked by %s" % (hit_south.collider.name if not hit_south.is_empty() else "unknown")
	)
	
	# d) East sidewalk pedestrian corridor (X = 3.6) into Caffè San Carlo entrance (3.6, 1.0, 8.4)
	var q_sidewalk_n = PhysicsRayQueryParameters3D.create(Vector3(3.6, 1.0, 6.5), Vector3(3.6, 1.0, 8.4))
	q_sidewalk_n.collision_mask = 1
	var hit_sw_n = space_state.intersect_ray(q_sidewalk_n)
	record_assertion(
		hit_sw_n.is_empty(),
		"East sidewalk approach from north into Cafe entrance is 100% unobstructed",
		"East sidewalk blocked from north by %s" % (hit_sw_n.collider.name if not hit_sw_n.is_empty() else "unknown")
	)
	
	var q_sidewalk_s = PhysicsRayQueryParameters3D.create(Vector3(3.6, 1.0, 10.0), Vector3(3.6, 1.0, 8.4))
	q_sidewalk_s.collision_mask = 1
	var hit_sw_s = space_state.intersect_ray(q_sidewalk_s)
	record_assertion(
		hit_sw_s.is_empty(),
		"East sidewalk approach from south into Cafe entrance is 100% unobstructed",
		"East sidewalk blocked from south by %s" % (hit_sw_s.collider.name if not hit_sw_s.is_empty() else "unknown")
	)
	
	world.queue_free()
