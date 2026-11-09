extends Node
## Adversarial Workflows & Physics Challenger Test Harness
## Author: Challenger Tier 5-2 (Workflow & Physics Challenger)
## Target: Startup Simulator (Godot 4.3 Stable)
## Architecture: Real-World Workflows, Collision Clearance, Geometry & Boundary Auditing

var total_assertions: int = 0
var passed_assertions: int = 0
var failed_assertions: int = 0
var failure_details: Array[String] = []

func record_assertion(passed: bool, name: String, detail: String = "") -> bool:
	total_assertions += 1
	if passed:
		passed_assertions += 1
		print("  ✔ [PASS] " + name)
		return true
	else:
		failed_assertions += 1
		var msg = name
		if detail != "":
			msg += " -> " + detail
		failure_details.append(msg)
		printerr("  ✘ [FAIL] " + msg)
		return false

func _ready() -> void:
	print("\n" + "=".repeat(70))
	print(">>> STARTUP SIMULATOR - ADVERSARIAL WORKFLOW & PHYSICS CHALLENGER <<<")
	print(">>> CHALLENGER TIER 5-2 EMPIRICAL VERIFICATION SUITE <<<")
	print("=".repeat(70) + "\n")
	
	# Execute the 4 adversarial challenge suites sequentially
	await run_challenge_workflow_1_turin_founder()
	await run_challenge_workflow_2_netshield_compact()
	await run_challenge_workflow_3_startup_expansion_recruitment()
	await run_challenge_workflow_4_walkable_turin_physics()
	
	print("\n" + "=".repeat(70))
	print(">>> ADVERSARIAL WORKFLOW CHALLENGE SUMMARY <<<")
	print("=".repeat(70))
	print("  TOTAL ASSERTIONS:  %d" % total_assertions)
	print("  ✔ PASSED:         %d" % passed_assertions)
	print("  ✘ FAILED:         %d" % failed_assertions)
	print("-".repeat(70))
	
	if failure_details.size() > 0:
		printerr("\n>>> EMPIRICAL DEFECTS ENCOUNTERED (%d) <<<" % failure_details.size())
		for i in range(failure_details.size()):
			printerr("  [%d] %s" % [i + 1, failure_details[i]])
		print("=".repeat(70) + "\n")
		get_tree().quit(1)
	else:
		print("\n>>> ALL ADVERSARIAL WORKFLOW & PHYSICS CHALLENGES PASSED EMPIRICALLY! <<<")
		print("=".repeat(70) + "\n")
		get_tree().quit(0)

# ==============================================================================
# CHALLENGE 1: WORKFLOW A — 'THE TURIN FOUNDER' COMPLETE E2E PIPELINE
# Start -> Accept Mario -> Walk Via Po -> Talk Mario -> Assemble WebForge site ->
# Deliver release -> TorinoHardware -> Place furniture in studio -> Advance objective
# ==============================================================================
func run_challenge_workflow_1_turin_founder() -> void:
	print("\n--- [CHALLENGE 1] WORKFLOW A: 'The Turin Founder' Complete E2E Pipeline ---")
	
	# Step 1: Initialize New Game
	GameManager.start_new_game()
	record_assertion(EconomyManager.balance == 250.0, "W1.1: Starting capital is exactly € 250.00")
	record_assertion(GameManager.company_tier == 1, "W1.1: Starting company tier is 1 (Freelance nel Garage)")
	record_assertion(GameManager.studio_upgrades_installed.is_empty(), "W1.1: No studio upgrades pre-installed at start")
	
	# Step 2: Story Contract 1 initialization and Quest state
	ContractManager.init_tutorial_contract()
	var tut = ContractManager.get_tutorial_contract()
	record_assertion(tut.get("status") == "available", "W1.2: Pizzeria Da Mario contract initialized in available status")
	
	var qm_script = load("res://scripts/core/quest_manager.gd") as GDScript
	var qm = qm_script.new()
	add_child(qm)
	var initial_obj = qm.get_current_objective()
	record_assertion("Mario" in initial_obj and "Pizzeria" in initial_obj, "W1.2: Quest objective directs player to Pizzeria Da Mario in Via Po", "Got: '%s'" % initial_obj)
	record_assertion(qm.get_current_category() == "Storia", "W1.2: Quest category is 'Storia'")
	
	# Step 3: Pedestrian Navigation Corridor to Pizzeria
	var world_scene = load("res://scenes/world/game_world.tscn") as PackedScene
	record_assertion(world_scene != null, "W1.3: GameWorld scene loaded")
	var world = world_scene.instantiate()
	add_child(world)
	await get_tree().physics_frame
	
	var space_state = world.get_world_3d().direct_space_state
	# Raycast from Studio exit (0, 1.0, 1.0) along Via Po corridor to Pizzeria entrance (0, 1.0, 16.0)
	var ray_query = PhysicsRayQueryParameters3D.create(Vector3(0, 1.0, 1.0), Vector3(0, 1.0, 16.0))
	var ray_result = space_state.intersect_ray(ray_query)
	record_assertion(ray_result.is_empty(), "W1.3: Pedestrian corridor from Studio to Pizzeria entrance is 100% unobstructed")
	
	# Inspect Mario NPC in Pizzeria
	var pizzeria = world.get_node_or_null("Pizzeria")
	record_assertion(pizzeria != null, "W1.3: Pizzeria venue present in GameWorld")
	var mario = pizzeria.get_node_or_null("MarioNPC") if pizzeria else null
	record_assertion(mario != null, "W1.3: Mario NPC instantiated inside Pizzeria")
	if mario:
		record_assertion(mario is Interactable3D, "W1.3: Mario NPC has active Interactable3D area")
		var mario_model = mario.get_node_or_null("Model")
		var mario_model_path = mario_model.scene_file_path if (mario_model and mario_model.scene_file_path) else ""
		record_assertion(not ("character-male" in mario_model_path), "W1.3: Mario does not use legacy cubic mesh")
	
	# Step 4: Dialogue interaction with Mario and contract acceptance
	ContractManager.advance_tutorial_to_in_progress()
	record_assertion(ContractManager.get_tutorial_contract().get("status") == "in_progress", "W1.4: Contract transitioned to in_progress")
	var obj_in_progress = qm.get_current_objective()
	record_assertion("WebForge" in obj_in_progress or "studio" in obj_in_progress, "W1.4: Quest objective updates to WebForge studio development", "Got: '%s'" % obj_in_progress)
	
	# Step 5: WebForge 3.0 Modular Assembly & Compilation
	var wf_scene = load("res://scenes/ui/minigames/web_forge.tscn") as PackedScene
	record_assertion(wf_scene != null, "W1.5: WebForge scene loaded")
	var wf = wf_scene.instantiate()
	add_child(wf)
	await get_tree().process_frame
	
	# Configure WebForge for Pizzeria Da Mario
	wf.active_contract_id = "pizzeria_da_mario"
	wf.current_palette_idx = 0 # Terracotta Napoletana (Mario's preferred palette)
	wf.slotted_components = {
		"header": "header_mole",
		"hero": "hero_oven",
		"body": "body_pizza",
		"widget": "widget_booking",
		"footer": "footer_mario"
	}
	wf.opt_minify = true
	wf.opt_webp = true
	wf.opt_meta = true
	
	var audit = wf.calculate_lighthouse_score()
	record_assertion(audit["total"] >= 95.0, "W1.5: Perfect modular match achieves Lighthouse score >= 95/100 (Got: %0.1f, Grado %s)" % [audit["total"], audit["grade"]])
	record_assertion(audit["matching_tags"] >= 4, "W1.5: Client tag affinity matching satisfies client requirements (matching tags: %d)" % audit["matching_tags"])
	
	# Test compilation finish and bundling
	wf._finish_compilation()
	record_assertion(wf.is_build_completed, "W1.5: WebForge build marked completed")
	record_assertion(ContractManager.get_tutorial_contract().get("status") == "built", "W1.5: Contract status updated to 'built'")
	record_assertion(wf.last_calculated_tip > 0.0, "W1.5: 20%% excellence tip bonus awarded (€ %0.2f)" % wf.last_calculated_tip)
	
	var obj_built = qm.get_current_objective()
	record_assertion("Consegna" in obj_built or "release" in obj_built, "W1.5: Quest objective updates to release delivery", "Got: '%s'" % obj_built)
	
	# Step 6: Deliver Release & Collect Payment
	var bal_before_delivery = EconomyManager.balance
	wf._on_deliver_pressed()
	
	record_assertion(ContractManager.is_contract_completed("pizzeria_da_mario"), "W1.6: Pizzeria Da Mario contract completed")
	record_assertion(EconomyManager.balance >= bal_before_delivery + 650.0 + wf.last_calculated_tip, "W1.6: Base payment (€650) + Tip (€%0.2f) credited (Balance: €%0.2f)" % [wf.last_calculated_tip, EconomyManager.balance])
	record_assertion(GameManager.reputation_points >= 15, "W1.6: Reputation reward credited (Rep: %d)" % GameManager.reputation_points)
	
	# Step 7: Objective advances to Studio Hardware Upgrade
	var obj_upgrade = qm.get_current_objective()
	record_assertion("TorinoHardware" in obj_upgrade, "W1.7: Quest objective dynamically requests TorinoHardware upgrade", "Got: '%s'" % obj_upgrade)
	record_assertion(qm.get_current_category() == "Upgrade", "W1.7: Quest category is 'Upgrade'")
	
	# Step 8: Purchase upgrade from TorinoHardware and place in Studio
	var bought_item = EconomyManager.spend(120.0, "Poltrona Gaming Torino")
	record_assertion(bought_item, "W1.8: Purchased studio furniture (€ 120.00)")
	EventBus.item_purchased.emit("chair_gaming_upgrade", 120.0)
	
	# Check FurniturePlacementManager
	var fpm_script = load("res://scripts/world/furniture_placement_manager.gd") as GDScript
	record_assertion(fpm_script != null, "W1.8: FurniturePlacementManager class loaded")
	var placed_ok = fpm_script.place_furniture("chair_gaming_upgrade", Vector3(1.2, 0.0, 0.5), 0.0)
	record_assertion(placed_ok, "W1.8: FurniturePlacementManager placed chair at valid coordinate (1.2, 0, 0.5)")
	
	# Verify out-of-bounds rejection
	var invalid_bounds = fpm_script.place_furniture("chair_gaming_upgrade", Vector3(4.5, 0.0, 0.0), 0.0)
	record_assertion(not invalid_bounds, "W1.8: Out-of-bounds placement (4.5, 0, 0) strictly rejected")
	
	# Verify player desk overlap rejection at (0, 0, -1.5)
	var invalid_desk = fpm_script.place_furniture("chair_gaming_upgrade", Vector3(0.0, 0.0, -1.5), 0.0)
	record_assertion(not invalid_desk, "W1.8: Primary player desk overlap at (0, 0, -1.5) strictly rejected")
	
	# Step 9: Verify state-aware objective automatically clears TorinoHardware prompt
	var obj_post_purchase = qm.get_current_objective()
	record_assertion(not ("TorinoHardware" in obj_post_purchase), "W1.9: Quest objective immediately clears TorinoHardware prompt once upgrade owned")
	record_assertion("Elena" in obj_post_purchase or "Caffè San Carlo" in obj_post_purchase, "W1.9: Quest objective advances to next story mission (Caffè San Carlo)", "Got: '%s'" % obj_post_purchase)
	
	# Clean up challenge 1
	wf.queue_free()
	world.queue_free()
	qm.queue_free()
	await get_tree().process_frame

# ==============================================================================
# CHALLENGE 2: WORKFLOW B — 'CYBERSECURITY NETSHIELD ON COMPACT DISPLAY' (1024x520)
# Assert DeployButton is strictly visible with >=16px margin on 1024x520 display
# ==============================================================================
func run_challenge_workflow_2_netshield_compact() -> void:
	print("\n--- [CHALLENGE 2] WORKFLOW B: 'Cybersecurity NetShield on Compact Display' (1024x520) ---")
	
	var fw_scene = load("res://scenes/ui/minigames/firewall_router.tscn") as PackedScene
	record_assertion(fw_scene != null, "W2.1: firewall_router.tscn loaded successfully")
	if not fw_scene:
		return
		
	# Create isolated SubViewport at exactly 1024x520 compact aspect
	var vp = SubViewport.new()
	vp.size = Vector2(1024, 520)
	add_child(vp)
	
	var fw = fw_scene.instantiate()
	vp.add_child(fw)
	fw.visible = true
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Check DeployButton bounds
	var deploy_btn = fw.get_node_or_null("Main/Footer/HBox/DeployButton") as Button
	record_assertion(deploy_btn != null, "W2.1: DeployButton node exists")
	
	if deploy_btn:
		var btn_pos = deploy_btn.global_position - fw.global_position
		var btn_size = deploy_btn.size
		var btn_bottom = btn_pos.y + btn_size.y
		var btn_right = btn_pos.x + btn_size.x
		var bottom_margin = 520.0 - btn_bottom
		
		print("    DeployButton bounds at 1024x520: Pos=(%0.1f, %0.1f), Size=(%0.1f, %0.1f), Bottom=%0.1f, BottomMargin=%0.1fpx" % [
			btn_pos.x, btn_pos.y, btn_size.x, btn_size.y, btn_bottom, bottom_margin
		])
		
		record_assertion(btn_bottom <= 520.0, "W2.1: DeployButton does not overflow 520px viewport height (Y_end: %0.1f)" % btn_bottom)
		record_assertion(bottom_margin >= 16.0, "W2.1: DeployButton has >= 16px bottom margin clearance on 1024x520 (Actual margin: %0.1fpx)" % bottom_margin)
		record_assertion(btn_right <= 1024.0, "W2.1: DeployButton does not overflow 1024px viewport width (X_end: %0.1f)" % btn_right)
		record_assertion(btn_pos.y >= 0.0 and btn_pos.x >= 0.0, "W2.1: DeployButton top/left bounds valid within viewport")
		
	# Test Matrix Button sizes (ensure compact 56x56 buttons)
	var matrix_buttons = fw.find_children("", "Button", true, false)
	var max_btn_height: float = 0.0
	var cell_count = 0
	for b in matrix_buttons:
		if b.get_parent() is GridContainer:
			cell_count += 1
			if b.custom_minimum_size.y > max_btn_height:
				max_btn_height = b.custom_minimum_size.y
	record_assertion(cell_count == 25, "W2.2: 5x5 network security matrix contains 25 interactive cells")
	record_assertion(max_btn_height <= 60.0, "W2.2: Matrix buttons configured to compact size (<= 60px, actual: %0.1fpx)" % max_btn_height)
	
	# Test Level 1 Circuit Routing (Studio Notarile Cavour)
	fw._load_level(0)
	record_assertion(deploy_btn.disabled, "W2.3: DeployButton starts disabled before circuit routing")
	
	# Verify Adjacency and Collision Rules
	# Invalid move: non-adjacent jump from (0,0) to (2,2)
	fw._on_cell_clicked(Vector2i(2, 2))
	record_assertion(fw.active_path.size() == 1, "W2.3: Non-adjacent cell click rejected (Manhattan dist > 1)")
	
	# Invalid move: wrong checkpoint order (clicking checkpoint 3 at (3,3) before checkpoint 2)
	fw._on_cell_clicked(Vector2i(3, 3))
	record_assertion(fw.active_path.size() == 1, "W2.3: Out-of-order checkpoint rejected")
	
	# Valid routing from Checkpoint 1 (0,0) -> 2 (0,3) -> 3 (3,3) -> 4 (3,0)
	var valid_steps = [
		Vector2i(0, 1), Vector2i(0, 2), Vector2i(0, 3), # Checkpoint 2 reached
		Vector2i(1, 3), Vector2i(2, 3), Vector2i(3, 3), # Checkpoint 3 reached
		Vector2i(3, 2), Vector2i(3, 1), Vector2i(3, 0)  # Checkpoint 4 reached
	]
	for step in valid_steps:
		fw._on_cell_clicked(step)
		
	# Verify line crossing rejection (clicking (0, 2) which is already in active path)
	var path_len_before = fw.active_path.size()
	fw._on_cell_clicked(Vector2i(0, 2))
	record_assertion(fw.active_path.size() == path_len_before, "W2.3: Self-intersecting line crossing rejected")
	
	record_assertion(fw.is_level_completed, "W2.3: Level 1 circuit 1->2->3->4 verified complete")
	record_assertion(not deploy_btn.disabled, "W2.3: DeployButton enabled upon valid circuit completion")
	
	# Deploy Security Rules & Collect Payout
	var bal_before_deploy = EconomyManager.balance
	fw._on_deploy_pressed()
	record_assertion(EconomyManager.balance == bal_before_deploy + 850.0, "W2.4: NetShield client payout credited (€ 850.00, Balance: € %0.2f)" % EconomyManager.balance)
	
	vp.queue_free()
	await get_tree().process_frame

# ==============================================================================
# CHALLENGE 3: WORKFLOW C — 'STARTUP EXPANSION & TALENT RECRUITMENT'
# Garage freelance stage -> Earn Rep & Capital -> Expand to Tier 2 -> Recruit Luca
# ==============================================================================
func run_challenge_workflow_3_startup_expansion_recruitment() -> void:
	print("\n--- [CHALLENGE 3] WORKFLOW C: 'Startup Expansion & Talent Recruitment' ---")
	
	# Reset candidate state
	for c in EmployeeManager.get_all_candidates():
		EmployeeManager.fire_employee(c["id"])
		
	# Phase 1: Garage Stage (Company Tier 1)
	GameManager.company_tier = 1
	GameManager.reputation_points = 20
	EconomyManager.balance = 500.0
	
	var hire_attempt_t1 = EmployeeManager.can_hire_employee("emp_luca")
	record_assertion(not hire_attempt_t1["allowed"], "W3.1: Hiring blocked in Company Tier 1 (Garage Stage)")
	record_assertion("Garage" in hire_attempt_t1["reason"] or "Solo Freelance" in hire_attempt_t1["reason"] or "Startup Emergente" in hire_attempt_t1["reason"], "W3.1: Rejection provides explanatory reason ('%s')" % hire_attempt_t1["reason"])
	
	var hire_exec_t1 = EmployeeManager.hire_employee("emp_luca")
	record_assertion(not hire_exec_t1, "W3.1: EmployeeManager.hire_employee returns false in Tier 1")
	record_assertion(not EmployeeManager.is_employee_hired("emp_luca"), "W3.1: Luca is NOT in active staff roster")
	
	# Phase 2: Reputation and Capital Gating Stress
	GameManager.company_tier = 2 # Upgraded to Startup Emergente
	GameManager.reputation_points = 30 # Below Luca's requirement of 50
	var hire_rep_blocked = EmployeeManager.can_hire_employee("emp_luca")
	record_assertion(not hire_rep_blocked["allowed"], "W3.2: Hiring blocked when reputation is below requirement (30 < 50)")
	record_assertion("Reputazione" in hire_rep_blocked["reason"], "W3.2: Rejection explains reputation requirement")
	
	# Insufficient capital test
	GameManager.reputation_points = 60 # Rep met
	EconomyManager.balance = 20.0 # Cannot afford daily salary (€55.00)
	var hire_funds_blocked = EmployeeManager.can_hire_employee("emp_luca")
	record_assertion(not hire_funds_blocked["allowed"], "W3.2: Hiring blocked when balance is below daily salary (€20 < €55)")
	
	# Phase 3: Successful Expansion & Recruitment
	EconomyManager.earn(2500.0, "Contract Earnings")
	GameManager.reputation_points = 60
	record_assertion(GameManager.get_max_employee_slots() == 1, "W3.3: Company Tier 2 has exactly 1 employee desk slot")
	
	var can_hire_luca = EmployeeManager.can_hire_employee("emp_luca")
	record_assertion(can_hire_luca["allowed"], "W3.3: Hiring Luca approved under Company Tier 2, 60 Rep, € 2500+ capital")
	
	var hired_luca = EmployeeManager.hire_employee("emp_luca")
	record_assertion(hired_luca, "W3.3: Luca Vianello recruited successfully")
	record_assertion(EmployeeManager.is_employee_hired("emp_luca"), "W3.3: Luca is active in company roster")
	
	var daily_salary = EmployeeManager.calculate_daily_payroll()
	var daily_revenue = EmployeeManager.calculate_employee_revenue()
	record_assertion(daily_salary == 55.00, "W3.3: Daily salary active (€ 55.00/day)")
	record_assertion(daily_revenue == 70.00, "W3.3: Employee daily passive revenue active (€ 70.00/day)")
	
	# Phase 4: Desk Capacity Limits (Attempt to hire second employee without Tier 3 expansion)
	var hire_sara_blocked = EmployeeManager.can_hire_employee("emp_sara")
	record_assertion(not hire_sara_blocked["allowed"], "W3.4: Hiring 2nd employee blocked by desk capacity (1/1)")
	record_assertion("Postazioni" in hire_sara_blocked["reason"] or "esaurite" in hire_sara_blocked["reason"], "W3.4: Rejection explains desk workstation capacity limit")
	
	# Phase 5: Workstation 3D Avatar Rendering in Studio
	var studio_scene = load("res://scenes/world/studio.tscn") as PackedScene
	record_assertion(studio_scene != null, "W3.5: Studio scene loaded")
	var studio = studio_scene.instantiate()
	add_child(studio)
	await get_tree().process_frame
	
	var ws = studio.get_node_or_null("EmployeeWorkstation")
	record_assertion(ws != null and ws.visible, "W3.5: Employee workstation visible in studio when Luca is hired")
	if ws:
		var emp_model = ws.get_node_or_null("EmployeeModel")
		record_assertion(emp_model != null, "W3.5: Employee 3D model node present")
		var nametag = ws.get_node_or_null("EmployeeNameTag") as Label3D
		record_assertion(nametag != null and "Luca Vianello" in nametag.text, "W3.5: 3D nametag identifies Luca Vianello")
		
	# Clean up challenge 3
	EmployeeManager.fire_employee("emp_luca")
	studio.queue_free()
	GameManager.company_tier = 1
	await get_tree().process_frame

# ==============================================================================
# CHALLENGE 4: WORKFLOW D — 'WALKABLE TURIN NEIGHBORHOOD TOUR' & PHYSICS CLEARANCE
# Unobstructed navigation along Via Po, portici, cross-street intersection,
# piazza dehors, Caffè San Carlo, Elettronica TO, anti-clipping & NPC fidelity
# ==============================================================================
func run_challenge_workflow_4_walkable_turin_physics() -> void:
	print("\n--- [CHALLENGE 4] WORKFLOW D: 'Walkable Turin Neighborhood Tour' & Physics Clearance ---")
	
	var world_scene = load("res://scenes/world/game_world.tscn") as PackedScene
	record_assertion(world_scene != null, "W4.1: GameWorld scene loaded")
	var world = world_scene.instantiate()
	add_child(world)
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	var space_state = world.get_world_3d().direct_space_state
	
	# 1. Removal of stacked rooftop buildings ("case sui tetti")
	var street = world.get_node_or_null("Street")
	record_assertion(street != null, "W4.1: Street district instantiated in world")
	if street:
		var bldg_b_upper = street.find_child("BuildingB_Upper", true, false)
		var bldg_e_upper = street.find_child("BuildingE_Upper", true, false)
		record_assertion(bldg_b_upper == null, "W4.1: BuildingB_Upper stacked rooftop house permanently removed")
		record_assertion(bldg_e_upper == null, "W4.1: BuildingE_Upper stacked rooftop house permanently removed")
		
	# 2. Comprehensive Pedestrian Path Raycasts across Turin
	var test_routes = [
		{"name": "Route 1: Via Po Central Corridor (Z=1.0 to Z=16.0 from Studio to Pizzeria)", "from": Vector3(0, 1.0, 1.0), "to": Vector3(0, 1.0, 16.0)},
		{"name": "Route 2: West Sidewalk Bypass around Pizzeria (Z=14.0 to Z=21.0 at X=-4.8)", "from": Vector3(-4.8, 1.0, 14.0), "to": Vector3(-4.8, 1.0, 21.0)},
		{"name": "Route 3: East Sidewalk Bypass around Pizzeria (Z=14.0 to Z=21.0 at X=4.8)", "from": Vector3(4.8, 1.0, 14.0), "to": Vector3(4.8, 1.0, 21.0)},
		{"name": "Route 4: Via Bogino Pedestrian Crosswalk (X=-4.5 to X=4.5 at Z=24.2)", "from": Vector3(-4.5, 1.0, 24.2), "to": Vector3(4.5, 1.0, 24.2)},
		{"name": "Route 5: Piazza San Carlo Dehors Walkway (Z=22.0 to Z=26.0 at X=0)", "from": Vector3(0, 1.0, 22.0), "to": Vector3(0, 1.0, 26.0)},
		{"name": "Route 6: Approach to TechShop / Elettronica TO (X=0 to X=-4.5 at Z=8.4)", "from": Vector3(0, 1.0, 8.4), "to": Vector3(-4.5, 1.0, 8.4)},
		{"name": "Route 7: Pedestrian Crosswalk Approach to Caffè San Carlo (X=0 to X=4.5 at Z=9.5)", "from": Vector3(0, 1.0, 9.5), "to": Vector3(4.5, 1.0, 9.5)},
		{"name": "Route 8: West Portici Arcade Corridor (Z=3.0 to Z=7.5 at X=-2.8)", "from": Vector3(-2.8, 1.0, 3.0), "to": Vector3(-2.8, 1.0, 7.5)},
		{"name": "Route 9: East Portici Arcade Corridor (Z=3.0 to Z=7.5 at X=2.8)", "from": Vector3(2.8, 1.0, 3.0), "to": Vector3(2.8, 1.0, 7.5)}
	]
	
	for r in test_routes:
		var q = PhysicsRayQueryParameters3D.create(r["from"], r["to"])
		var res = space_state.intersect_ray(q)
		var col_name = res["collider"].name if not res.is_empty() else ""
		record_assertion(res.is_empty(), "W4.2: " + r["name"] + " is unobstructed", "Collided with: " + col_name)
		
	# 3. Vehicle Anti-Clipping & Physical Collision Verification
	if street:
		var parked_cars = [
			{"node_name": "CarHatchback", "max_z": 12.0, "min_y": 0.08},
			{"node_name": "CarSedan", "max_z": 30.0, "min_y": 0.08},
			{"node_name": "CarTaxi", "max_z": 30.0, "min_y": 0.08},
			{"node_name": "CarStationWagon", "max_z": 30.0, "min_y": 0.08}
		]
		for c_info in parked_cars:
			var car_node = street.find_child(c_info["node_name"], true, false) as Node3D
			record_assertion(car_node != null, "W4.3: Parked vehicle '" + c_info["node_name"] + "' present in scene")
			if car_node:
				var car_pos = car_node.position
				record_assertion(car_pos.y >= (c_info["min_y"] - 0.005), "W4.3: %s tires seated on asphalt (Y=%0.2f >= %0.2f)" % [c_info["node_name"], car_pos.y, c_info["min_y"]])
				if c_info["node_name"] == "CarHatchback":
					record_assertion(car_pos.z <= c_info["max_z"], "W4.3: CarHatchback does not clip into Pizzeria facade (Z=%0.2f <= %0.2f)" % [car_pos.z, c_info["max_z"]])
				
				# Check physical collision body
				var col_body = car_node.find_child("*Body3D*", true, false)
				if not col_body:
					col_body = car_node.get_parent().find_child(c_info["node_name"] + "Col", true, false)
				if not col_body:
					# Check Collisions container
					var cols = street.get_node_or_null("Collisions")
					if cols:
						col_body = cols.find_child("*" + c_info["node_name"] + "*", true, false)
				record_assertion(col_body != null, "W4.3: " + c_info["node_name"] + " has physical collision geometry")
				
	# 4. NPC & Venue Fidelity (Elena in Cafe, Davide in Tech Shop, Mario in Pizzeria)
	var cafe = street.get_node_or_null("CafeVenue") if street else null
	record_assertion(cafe != null, "W4.4: Caffè San Carlo venue instantiated in Street")
	if cafe:
		var elena = cafe.get_node_or_null("ElenaNPC")
		record_assertion(elena != null, "W4.4: Elena NPC present in Caffè San Carlo")
		if elena:
			record_assertion(elena.position.y >= 0.15, "W4.4: Elena elevated on barista platform (Y=%0.2f >= 0.15m)" % elena.position.y)
			var elena_model = elena.get_node_or_null("Model")
			var elena_scale_y = elena_model.scale.y if elena_model else elena.scale.y
			record_assertion(elena_scale_y >= 2.2, "W4.4: Elena model scale is full humanoid (scale Y=%0.2f >= 2.2)" % elena_scale_y)
			record_assertion(elena.position.z >= -1.45, "W4.4: Elena positioned immediately behind counter (Z=%0.2f)" % elena.position.z)
			
	var tech_shop = street.get_node_or_null("TechShopVenue") if street else null
	record_assertion(tech_shop != null, "W4.4: Elettronica TO venue instantiated in Street")
	if tech_shop:
		var davide = tech_shop.get_node_or_null("DavideNPC")
		record_assertion(davide != null, "W4.4: Davide NPC present in Elettronica TO")
		if davide:
			var d_model = davide.get_node_or_null("Model")
			var d_src = d_model.scene_file_path if (d_model and d_model.scene_file_path) else ""
			record_assertion(not ("character-male" in d_src), "W4.4: Davide does not use blocky cubic mesh")
			record_assertion("Knight.glb" in d_src, "W4.4: Davide upgraded to KayKit Knight model")
			
	world.queue_free()
	await get_tree().process_frame
