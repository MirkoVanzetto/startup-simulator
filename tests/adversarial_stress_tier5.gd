extends Node
## Challenger Tier 5-1: Comprehensive Adversarial Stress Test Suite
## Empirical Verification Across 7 Target Systems & Edge-Cases

var total_assertions: int = 0
var passed_assertions: int = 0
var failed_assertions: int = 0
var failure_log: Array[String] = []

const RESOLUTIONS = [
	Vector2(1280, 720),
	Vector2(1920, 1080),
	Vector2(1024, 520),
	Vector2(1366, 768),
	Vector2(800, 600)
]

func _ready() -> void:
	print("\n" + "=".repeat(70))
	print(">>> STARTUP SIMULATOR — CHALLENGER TIER 5-1 ADVERSARIAL STRESS SUITE <<<")
	print("=".repeat(70) + "\n")
	
	await test_area_1_webforge_3_adversarial()
	await test_area_2_dynamic_objectives_adversarial()
	await test_area_3_furniture_placement_boundaries_and_corruption()
	await test_area_4_employee_gating_and_payroll_stress()
	await test_area_5_city_map_portici_and_raycasts()
	await test_area_6_multi_resolution_ui_containment()
	
	print("\n" + "=".repeat(70))
	print(">>> CHALLENGER TIER 5-1 STRESS SUITE SUMMARY <<<")
	print("=".repeat(70))
	print("  TOTAL ADVERSARIAL ASSERTIONS: %d" % total_assertions)
	print("  ✔ PASSED:                     %d" % passed_assertions)
	print("  ✘ FAILED:                     %d" % failed_assertions)
	print("-".repeat(70))
	
	if failure_log.size() > 0:
		printerr("\n>>> CONFIRMED FAILURE MODES / BUGS DETECTED (%d) <<<" % failure_log.size())
		for i in range(failure_log.size()):
			printerr("  [%d] %s" % [i + 1, failure_log[i]])
		print("=".repeat(70) + "\n")
		get_tree().quit(1)
	else:
		print("\n>>> ALL ADVERSARIAL STRESS TESTS PASSED EMPIRICALLY! <<<")
		print("=".repeat(70) + "\n")
		get_tree().quit(0)

func assert_test(condition: bool, test_name: String, error_msg: String = "") -> bool:
	total_assertions += 1
	if condition:
		passed_assertions += 1
		print("  ✔ [PASS] %s" % test_name)
		return true
	else:
		failed_assertions += 1
		var full_msg = "%s -> %s" % [test_name, error_msg if error_msg != "" else "Assertion condition failed"]
		printerr("  ✘ [FAIL] %s" % full_msg)
		failure_log.append(full_msg)
		return false

# ==============================================================================
# AREA 1: WEBFORGE 3.0 ADVERSARIAL STRESS
# ==============================================================================
func test_area_1_webforge_3_adversarial() -> void:
	print("\n--- [AREA 1] WebForge 3.0 Adversarial Stress & Edge Cases ---")
	var wf_scene = load("res://scenes/ui/minigames/web_forge.tscn")
	assert_test(wf_scene != null, "Area 1: Load web_forge.tscn")
	if not wf_scene:
		return
		
	var wf = wf_scene.instantiate()
	add_child(wf)
	await get_tree().process_frame
	
	ContractManager.init_tutorial_contract()
	ContractManager.advance_tutorial_to_in_progress()
	wf._on_minigame_started("web_forge")
	
	# 1. Edge Case: 0 components slotted audit calculation
	for k in wf.SLOT_KEYS:
		wf.slotted_components[k] = null
	var zero_audit = wf.calculate_lighthouse_score()
	assert_test(zero_audit is Dictionary, "WebForge 0-slots: returns valid Dictionary")
	assert_test(zero_audit["slots_filled"] == 0, "WebForge 0-slots: slots_filled == 0")
	assert_test(zero_audit["total"] >= 0.0 and zero_audit["total"] <= 100.0, "WebForge 0-slots: total score clamped between 0 and 100 (%0.1f)" % zero_audit["total"])
	assert_test(zero_audit["grade"] == "C", "WebForge 0-slots: grade is C")
	
	# 2. Compile button disabled with 0 slots
	wf._update_lighthouse_display()
	assert_test(wf.compile_btn.disabled == true, "WebForge 0-slots: compile button is disabled")
	
	# 3. Attempt to trigger compile with < 5 slots
	wf.is_compiling = false
	wf._on_compile_pressed()
	assert_test(wf.is_compiling == false, "WebForge <5-slots: _on_compile_pressed() safely rejected compile")
	
	# 4. Partial slot configurations (1, 2, 3, 4 slots)
	wf.slotted_components["header"] = "header_mole"
	assert_test(wf.calculate_lighthouse_score()["slots_filled"] == 1, "WebForge 1-slot: audit calculates 1 slot")
	wf.slotted_components["hero"] = "hero_oven"
	assert_test(wf.calculate_lighthouse_score()["slots_filled"] == 2, "WebForge 2-slots: audit calculates 2 slots")
	wf.slotted_components["body"] = "body_pizza"
	assert_test(wf.calculate_lighthouse_score()["slots_filled"] == 3, "WebForge 3-slots: audit calculates 3 slots")
	wf.slotted_components["widget"] = "widget_booking"
	assert_test(wf.calculate_lighthouse_score()["slots_filled"] == 4, "WebForge 4-slots: audit calculates 4 slots")
	wf._update_lighthouse_display()
	assert_test(wf.compile_btn.disabled == true, "WebForge 4-slots: compile button still disabled")
	
	# 5. Full 5/5 slots configuration
	wf.slotted_components["footer"] = "footer_mario"
	var full_audit = wf.calculate_lighthouse_score()
	assert_test(full_audit["slots_filled"] == 5, "WebForge 5-slots: all 5 slots populated")
	wf._update_lighthouse_display()
	assert_test(wf.compile_btn.disabled == false, "WebForge 5-slots: compile button enabled")
	
	# 6. Tag Affinity & Palette Match Bonus
	wf.current_palette_idx = 0 # Terracotta (Pizzeria match)
	wf.opt_minify = true
	wf.opt_webp = true
	wf.opt_meta = true
	var perfect_audit = wf.calculate_lighthouse_score()
	assert_test(perfect_audit["total"] >= 95.0, "WebForge Perfect Build: achieves >= 95 score (%0.1f)" % perfect_audit["total"])
	assert_test(perfect_audit["grade"] == "A+", "WebForge Perfect Build: achieves A+ rating")
	
	# 7. Mismatched Palette Penalty
	wf.current_palette_idx = 2 # Cyan (misaligned for Pizzeria)
	var mismatched_audit = wf.calculate_lighthouse_score()
	assert_test(mismatched_audit["total"] < perfect_audit["total"], "WebForge Mismatched Palette: score lower than perfect palette (%0.1f < %0.1f)" % [mismatched_audit["total"], perfect_audit["total"]])
	
	# 8. All component IDs across all slots load cleanly in catalog
	var all_ids_valid = true
	for s_key in wf.SLOT_KEYS:
		var items = wf.COMPONENT_CATALOG.get(s_key, [])
		if items.is_empty():
			all_ids_valid = false
		for it in items:
			if not it.has("id") or not it.has("tags"):
				all_ids_valid = false
	assert_test(all_ids_valid, "WebForge Catalog: all components in all 5 categories have valid IDs and tags")
	
	# 9. Hardware compilation boosts
	GameManager.studio_upgrades_installed.clear()
	wf._calculate_compilation_speed()
	var base_dur = wf.compile_target_duration
	assert_test(base_dur >= 5.0, "WebForge Toolchain: baseline compilation duration >= 5.0s (%0.1fs)" % base_dur)
	
	GameManager.studio_upgrades_installed.append("monitor_upgrade")
	GameManager.studio_upgrades_installed.append("chair_gaming_upgrade")
	wf._calculate_compilation_speed()
	var upgraded_dur = wf.compile_target_duration
	assert_test(upgraded_dur <= (base_dur - 2.0), "WebForge Toolchain: monitor + chair reduce duration by >= 2.0s (%0.1fs -> %0.1fs)" % [base_dur, upgraded_dur])
	
	# 10. Tip award logic
	wf._finish_compilation()
	assert_test(wf.is_build_completed == true, "WebForge Build: build completed flag set")
	assert_test(wf.deliver_btn.visible == true, "WebForge Delivery: deliver button visible")
	
	GameManager.studio_upgrades_installed.clear()
	wf.queue_free()

# ==============================================================================
# AREA 2: DYNAMIC OBJECTIVES (QUESTMANAGER) ADVERSARIAL STRESS
# ==============================================================================
func test_area_2_dynamic_objectives_adversarial() -> void:
	print("\n--- [AREA 2] Dynamic Objectives (QuestManager) Adversarial Stress ---")
	var qm = QuestManager.new()
	add_child(qm)
	await get_tree().process_frame
	
	# Scenario A: Buying upgrades BEFORE accepting contracts
	ContractManager.init_tutorial_contract()
	GameManager.company_tier = 1
	GameManager.studio_upgrades_installed = ["monitor_upgrade"]
	
	# While Mario contract is active, objective must focus on Mario despite pre-purchased upgrade
	var obj_mario = qm.get_current_objective()
	assert_test("Mario" in obj_mario, "QuestManager Priority 1: Focuses on Mario contract while incomplete")
	
	# Complete Mario contract
	ContractManager.complete_story_contract("pizzeria_da_mario")
	
	# State-aware check: Because monitor_upgrade is ALREADY purchased, it MUST NOT prompt for TorinoHardware!
	var obj_post_mario = qm.get_current_objective()
	assert_test(not ("TorinoHardware" in obj_post_mario), "QuestManager State-Aware: Bypasses store visit prompt because monitor_upgrade was pre-purchased")
	assert_test("San Carlo" in obj_post_mario or "Elena" in obj_post_mario, "QuestManager Advance: Automatically advances to Caffè San Carlo")
	
	# Scenario B: What if studio_upgrades_installed is empty?
	GameManager.studio_upgrades_installed.clear()
	var obj_empty_upg = qm.get_current_objective()
	assert_test("TorinoHardware" in obj_empty_upg, "QuestManager Empty Upgrades: Prompts to visit TorinoHardware when 0 upgrades installed")
	
	# Scenario C: EventBus purchase signal updates objective dynamically
	EventBus.item_purchased.emit("chair_gaming_upgrade", 350.0)
	var obj_after_event = qm.get_current_objective()
	assert_test(not ("TorinoHardware" in obj_after_event), "QuestManager EventBus: item_purchased immediately cleared store upgrade objective")
	assert_test("San Carlo" in obj_after_event or "Elena" in obj_after_event, "QuestManager EventBus: Transitions directly to Elena")
	
	# Scenario D: Story completion progression
	ContractManager.complete_story_contract("caffe_san_carlo")
	var obj_davide = qm.get_current_objective()
	assert_test("Davide" in obj_davide or "Elettronica TO" in obj_davide, "QuestManager Advance: Advances to Davide at Elettronica TO")
	
	ContractManager.complete_story_contract("elettronica_to")
	
	# Scenario E: All story completed, company tier 1 -> requests expansion
	GameManager.company_tier = 1
	var obj_expansion = qm.get_current_objective()
	assert_test("espansione aziendale" in obj_expansion or "Reputazione" in obj_expansion, "QuestManager Tier Gating: Requests company expansion after story completion")
	
	# Scenario F: Upgraded to Tier 2 -> switches to freelance marketplace
	GameManager.company_tier = 2
	var obj_freelance = qm.get_current_objective()
	assert_test("marketplace" in obj_freelance or "B2B" in obj_freelance or "TO-OS" in obj_freelance, "QuestManager Post-Expansion: Prompts for B2B freelance contracts")
	
	# Reset state
	ContractManager.init_tutorial_contract()
	GameManager.company_tier = 1
	GameManager.studio_upgrades_installed.clear()
	qm.queue_free()

# ==============================================================================
# AREA 3: FURNITURE PLACEMENT BOUNDARIES & CORRUPTION STRESS
# ==============================================================================
func test_area_3_furniture_placement_boundaries_and_corruption() -> void:
	print("\n--- [AREA 3] Furniture Placement Boundaries & Save Corruption ---")
	var fpm_script = load("res://scripts/world/furniture_placement_manager.gd")
	assert_test(fpm_script != null, "Area 3: Load furniture_placement_manager.gd")
	
	# 1. Room exact corner boundaries
	assert_test(fpm_script.validate_placement_position(Vector3(-2.8, 0.0, -2.2)) == true, "Furniture Bounds: (-2.8, 0, -2.2) valid")
	assert_test(fpm_script.validate_placement_position(Vector3(2.8, 0.0, -2.2)) == true, "Furniture Bounds: (2.8, 0, -2.2) valid")
	assert_test(fpm_script.validate_placement_position(Vector3(-2.8, 0.0, 2.2)) == true, "Furniture Bounds: (-2.8, 0, 2.2) valid")
	assert_test(fpm_script.validate_placement_position(Vector3(2.8, 0.0, 2.2)) == true, "Furniture Bounds: (2.8, 0, 2.2) valid")
	
	# 2. Strict boundary violations (0.01m outside room perimeter)
	assert_test(fpm_script.validate_placement_position(Vector3(2.82, 0.0, 0.0)) == false, "Furniture Bounds: X=2.82 rejected")
	assert_test(fpm_script.validate_placement_position(Vector3(-2.82, 0.0, 0.0)) == false, "Furniture Bounds: X=-2.82 rejected")
	assert_test(fpm_script.validate_placement_position(Vector3(0.0, 0.0, 2.22)) == false, "Furniture Bounds: Z=2.22 rejected")
	assert_test(fpm_script.validate_placement_position(Vector3(0.0, 0.0, -2.22)) == false, "Furniture Bounds: Z=-2.22 rejected")
	
	# 3. Extreme coordinate outliers
	assert_test(fpm_script.validate_placement_position(Vector3(9999.0, 0.0, 0.0)) == false, "Furniture Bounds: Extreme positive X rejected")
	assert_test(fpm_script.validate_placement_position(Vector3(0.0, 0.0, -9999.0)) == false, "Furniture Bounds: Extreme negative Z rejected")
	
	# 4. Desk collision overlap
	# Desk footprint is centered at (0, 0, -1.5) with half_width 0.85, half_depth 0.55
	assert_test(fpm_script.validate_placement_position(Vector3(0.0, 0.0, -1.5)) == false, "Desk Overlap: Desk center (0, 0, -1.5) rejected")
	assert_test(fpm_script.validate_placement_position(Vector3(0.5, 0.0, -1.5)) == false, "Desk Overlap: Inside desk width (0.5, 0, -1.5) rejected")
	assert_test(fpm_script.validate_placement_position(Vector3(0.0, 0.0, -1.8)) == false, "Desk Overlap: Inside desk depth (0, 0, -1.8) rejected")
	assert_test(fpm_script.validate_placement_position(Vector3(1.0, 0.0, -1.5)) == true, "Desk Clearance: Outside desk footprint (1.0, 0, -1.5) accepted")
	
	# 5. Grid Snapping
	var snapped1 = fpm_script.snap_to_grid(Vector3(1.12, 0.0, 0.38), 0.25)
	assert_test(abs(snapped1.x - 1.0) < 0.001 and abs(snapped1.z - 0.5) < 0.001, "Grid Snap: (1.12, 0, 0.38) snaps to (1.0, 0, 0.5)")
	var snapped_zero_grid = fpm_script.snap_to_grid(Vector3(1.23, 0.0, 4.56), 0.0)
	assert_test(snapped_zero_grid == Vector3(1.23, 0.0, 4.56), "Grid Snap: grid_size=0 returns original position safely")
	
	# 6. Save Data Corruption Resilience
	fpm_script.clear_placed_furniture()
	var corrupted_save_data = [
		null,
		42,
		"corrupted_entry",
		{},
		{"id": "plant_aloe_upgrade"}, # Missing position
		{"position": [0, 0, 0]},      # Missing id
		{"id": "plant_aloe_upgrade", "position": [1.0, 0.0, 0.5], "rotation_y": 0.5}, # Valid!
		{"id": "chair_gaming_upgrade", "position": [-1.0, 0.0, 1.0], "rotation_y": 0.0} # Valid!
	]
	fpm_script.load_placed_furniture(corrupted_save_data)
	var loaded = fpm_script.get_placed_furniture()
	assert_test(loaded.size() == 2, "Save Corruption: Filters out invalid/corrupt entries (loaded exactly 2 valid items)")
	assert_test(loaded[0]["id"] == "plant_aloe_upgrade", "Save Corruption: Preserved first valid item ID")
	assert_test(loaded[1]["id"] == "chair_gaming_upgrade", "Save Corruption: Preserved second valid item ID")
	
	# 7. Studio physical model instancing from loaded items
	var studio_scene = load("res://scenes/world/studio.tscn")
	var studio = studio_scene.instantiate()
	add_child(studio)
	await get_tree().process_frame
	
	var placed_node = studio.get_node_or_null("PlacedFurniture")
	assert_test(placed_node != null, "Studio PlacedFurniture node exists")
	assert_test(placed_node.get_child_count() == 2, "Studio instantiates physical objects for loaded items (found 2)")
	
	# Clean up
	fpm_script.clear_placed_furniture()
	studio.queue_free()

# ==============================================================================
# AREA 4: COMPANY TIER & EMPLOYEE GATING ADVERSARIAL STRESS
# ==============================================================================
func test_area_4_employee_gating_and_payroll_stress() -> void:
	print("\n--- [AREA 4] Employee Progression Gating & Payroll Stress ---")
	
	# 1. Tier 1 starter garage: Hiring strictly blocked
	GameManager.company_tier = 1
	var check_tier1 = EmployeeManager.can_hire_employee("emp_luca")
	assert_test(check_tier1["allowed"] == false, "Employee Gating: Hiring Luca blocked in Tier 1 garage")
	assert_test("Garage" in check_tier1["reason"] or "Startup Emergente" in check_tier1["reason"], "Employee Gating: Clear feedback mentioning Garage/Startup requirement")
	
	# 2. Direct hire_employee call in Tier 1 must fail safely
	var direct_hire_ok = EmployeeManager.hire_employee("emp_luca")
	assert_test(direct_hire_ok == false, "Employee Gating: hire_employee() call rejected in Tier 1")
	assert_test(EmployeeManager.is_employee_hired("emp_luca") == false, "Employee Gating: Luca is NOT in hired roster")
	
	# 3. Non-existent candidate
	var check_fake = EmployeeManager.can_hire_employee("emp_non_existent")
	assert_test(check_fake["allowed"] == false, "Employee Roster: Non-existent candidate rejected gracefully")
	
	# 4. Salary Affordability Stress
	GameManager.company_tier = 2
	GameManager.reputation_points = 60
	EconomyManager.balance = 10.0 # Less than Luca's daily salary of 55 EUR
	
	var check_broke = EmployeeManager.can_hire_employee("emp_luca")
	assert_test(check_broke["allowed"] == false, "Employee Affordability: Blocked when company balance < daily salary")
	assert_test("insufficienti" in check_broke["reason"].to_lower(), "Employee Affordability: Clear insufficient funds explanation")
	
	# 5. Sufficient funds -> Hiring succeeds
	EconomyManager.balance = 500.0
	var hire_success = EmployeeManager.hire_employee("emp_luca")
	assert_test(hire_success == true, "Employee Recruitment: Luca successfully recruited with sufficient funds in Tier 2")
	assert_test(EmployeeManager.is_employee_hired("emp_luca") == true, "Employee Recruitment: Luca status is active")
	assert_test(EconomyManager.balance == 445.0, "Employee Recruitment: Initial day salary €55.00 deducted (Balance €445.00)")
	
	# 6. Capacity limit enforcement (Tier 2 allows max 1 employee)
	var check_second = EmployeeManager.can_hire_employee("emp_sara")
	assert_test(check_second["allowed"] == false, "Employee Capacity: Second employee blocked in Tier 2 (max slots = 1)")
	assert_test("esaurite" in check_second["reason"].to_lower() or "postazioni" in check_second["reason"].to_lower(), "Employee Capacity: Clear workstation capacity warning")
	
	# 7. Daily Payroll Negative Spend Stress
	# Ensure EconomyManager.spend rejects spending more than balance without creating negative balances
	EconomyManager.balance = 20.0
	var payroll_spend_result = EconomyManager.spend(55.0, "Test Payroll Overdraft")
	assert_test(payroll_spend_result == false, "Payroll Overdraft: Spend exceeding balance rejected")
	assert_test(EconomyManager.balance == 20.0, "Payroll Overdraft: Balance remains non-negative (€20.00)")
	
	# 8. Clean dismissal
	var fire_ok = EmployeeManager.fire_employee("emp_luca")
	assert_test(fire_ok == true, "Employee Lifecycle: Luca dismissed cleanly")
	assert_test(EmployeeManager.is_employee_hired("emp_luca") == false, "Employee Lifecycle: Roster empty after dismissal")
	
	# Reset
	GameManager.company_tier = 1
	GameManager.reputation_points = 0
	EconomyManager.reset_economy(250.0)

# ==============================================================================
# AREA 5: CITY MAP, PORTICI & VEHICLE COLLISION STRESS
# ==============================================================================
func test_area_5_city_map_portici_and_raycasts() -> void:
	print("\n--- [AREA 5] City Map Ground Expansion, Portici & Vehicle Collisions ---")
	var world_scene = load("res://scenes/world/game_world.tscn")
	assert_test(world_scene != null, "Area 5: Load game_world.tscn")
	if not world_scene:
		return
		
	var world = world_scene.instantiate()
	add_child(world)
	await get_tree().physics_frame
	await get_tree().physics_frame
	
	var street = world.get_node_or_null("Street")
	assert_test(street != null, "GameWorld contains Street district")
	
	# 1. Verification: No stacked rooftop buildings ("case sui tetti")
	var bld_b_up = street.get_node_or_null("Buildings/BuildingB_Upper")
	var bld_e_up = street.get_node_or_null("Buildings/BuildingE_Upper")
	assert_test(bld_b_up == null, "Rooftop Buildings: BuildingB_Upper completely eliminated from street")
	assert_test(bld_e_up == null, "Rooftop Buildings: BuildingE_Upper completely eliminated from street")
	
	# Check all building elevations
	var buildings_node = street.get_node_or_null("Buildings")
	var all_ground_level = true
	if buildings_node:
		for b in buildings_node.get_children():
			if b is Node3D and b.position.y > 1.0:
				all_ground_level = false
				printerr("  Building %s has elevated Y=%0.2f" % [b.name, b.position.y])
	assert_test(all_ground_level, "City Buildings: All commercial buildings sit firmly on ground level (Y <= 1.0m)")
	
	# 2. Parked vehicles collision physics and anti-clipping
	var props = street.get_node_or_null("StreetProps")
	var cars = ["CarSedan", "CarTaxi", "CarStationWagon", "CarHatchback"]
	var all_cars_solid = true
	var all_tires_on_asphalt = true
	
	for cn in cars:
		var car = props.get_node_or_null(cn)
		if car:
			var col_shapes = car.find_children("", "CollisionShape3D", true, false)
			if col_shapes.is_empty():
				all_cars_solid = false
			if car.global_position.y < 0.05:
				all_tires_on_asphalt = false
		else:
			all_cars_solid = false
			
	assert_test(all_cars_solid, "Vehicles: All 4 parked cars have active physical collision bodies")
	assert_test(all_tires_on_asphalt, "Vehicles: All vehicle tires sit properly on asphalt without sinking (Y >= 0.05m)")
	
	# Check CarHatchback specific threshold
	var car_h = props.get_node_or_null("CarHatchback")
	if car_h:
		assert_test(car_h.global_position.z <= 12.0, "Vehicles: CarHatchback positioned at Z=%0.2f, safely clear of Pizzeria entrance (Z=14.9)" % car_h.global_position.z)
		
	# 3. Pedestrian Raycast Corridor: Clear unobstructed path from Studio exit to Pizzeria
	var space_state = world.get_world_3d().direct_space_state
	var ray_query = PhysicsRayQueryParameters3D.create(
		Vector3(0.0, 1.0, 1.0),
		Vector3(0.0, 1.0, 14.5)
	)
	var ray_result = space_state.intersect_ray(ray_query)
	assert_test(ray_result.is_empty(), "Street Walkability: Pedestrian corridor (Z=1.0 to Z=14.5) 100% unobstructed by geometry or cars")
	
	# 4. Venues Accessibility
	var tech_shop = street.get_node_or_null("TechShopVenue")
	var cafe = street.get_node_or_null("CafeVenue")
	assert_test(tech_shop != null, "City Venues: TechShopVenue present and accessible on street")
	assert_test(cafe != null, "City Venues: CafeVenue present and accessible on street")
	
	world.queue_free()

# ==============================================================================
# AREA 6: MULTI-RESOLUTION UI CONTAINMENT
# ==============================================================================
func test_area_6_multi_resolution_ui_containment() -> void:
	print("\n--- [AREA 6] Multi-Resolution UI Containment Across 5 Screen Sizes ---")
	var ui_scenes = [
		{"path": "res://scenes/ui/hud.tscn", "name": "HUD"},
		{"path": "res://scenes/ui/computer_screen.tscn", "name": "ComputerScreen"},
		{"path": "res://scenes/ui/minigames/web_forge.tscn", "name": "WebForge"},
		{"path": "res://scenes/ui/minigames/firewall_router.tscn", "name": "NetShield"},
		{"path": "res://scenes/ui/dialogue_overlay.tscn", "name": "DialogueOverlay"},
		{"path": "res://scenes/ui/main_menu.tscn", "name": "MainMenu"},
		{"path": "res://scenes/ui/pause_menu.tscn", "name": "PauseMenu"},
		{"path": "res://scenes/ui/intro_monologue.tscn", "name": "IntroMonologue"}
	]
	
	for scn_info in ui_scenes:
		var packed = load(scn_info["path"])
		assert_test(packed != null, "UI Scene Load: %s" % scn_info["name"])
		if not packed:
			continue
			
		for res in RESOLUTIONS:
			var inst = packed.instantiate()
			if not (inst is Control):
				inst.queue_free()
				continue
				
			var vp = SubViewport.new()
			vp.size = Vector2i(int(res.x), int(res.y))
			add_child(vp)
			vp.add_child(inst)
			inst.position = Vector2.ZERO
			inst.size = res
			await get_tree().process_frame
			
			var is_contained = true
			var min_size = inst.get_combined_minimum_size()
			if min_size.x > res.x + 1.0 or min_size.y > res.y + 1.0:
				is_contained = false
				
			var buttons = inst.find_children("", "Button", true, false)
			for b in buttons:
				if b.is_visible_in_tree():
					var b_pos = b.global_position - inst.global_position
					var b_bottom = b_pos.y + b.size.y
					var b_right = b_pos.x + b.size.x
					if b_bottom > (res.y + 1.0) or b_right > (res.x + 1.0):
						is_contained = false
						printerr("  Clipping button '%s' in %s at %0.0fx%0.0f: b_pos=%s, size=%s, b_bottom=%0.1f vs vp_y=%0.1f" % [
							b.text, scn_info["name"], res.x, res.y, str(b_pos), str(b.size), b_bottom, res.y
						])
						break
						
			assert_test(is_contained, "%s Containment: Fully contained at %0.0fx%0.0f" % [scn_info["name"], res.x, res.y])
			
			# If MainMenu at 1024x520, also check dialog panels (Settings, Credits, Multiplayer)
			if scn_info["name"] == "MainMenu" and res == Vector2(1024, 520):
				for panel_name in ["SettingsPanel", "CreditsPanel", "MultiplayerPanel"]:
					var panel = inst.get_node_or_null(panel_name)
					if panel:
						panel.visible = true
						await get_tree().process_frame
						var p_min = panel.get_combined_minimum_size()
						var p_contained = (panel.position.y + panel.size.y <= res.y + 1.0) and (panel.position.x + panel.size.x <= res.x + 1.0)
						assert_test(p_contained, "MainMenu %s: Fully contained at 1024x520" % panel_name)
						panel.visible = false
			
			inst.queue_free()
			vp.queue_free()
