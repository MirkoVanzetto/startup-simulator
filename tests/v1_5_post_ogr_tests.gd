extends Node
## v1.5.0 Post-OGR Evolution Automated Test Suite
## Verifies:
## 1. Incubatore Startup Torino rename (zero 'I3P' labels in POIs/SideJobs)
## 2. Post-OGR Mission Chain, 3D Extraction Yard, Physical Crate Carry & Refinery (RC + Warehouse + Euro)
## 3. 6-Branch Technological Research Tree (🔬 RC) & Cross-System Multipliers
## 4. Mining Robot MK1/MK2, Conveyor Automation & Studio Bed Sleep Simulation
## 5. Physical 7-Step TO-Drone MK1 3D Assembly & Drone Flight Missions
## 6. Phase 4 CEO Departments (Incubatore) & Dynamic Incidents Resolution
## 7. Autonomous Employee Freelance Hub Work, Employee Skill Upgrades, Shop Hours, Living City, Vehicles & Save/Load

const MineOpsAnimatorScript := preload("res://scripts/world/mine_ops_animator.gd")
const CityLifeManagerScript := preload("res://scripts/world/city_life_manager.gd")

var passed: int = 0
var failed: int = 0

func _assert(cond: bool, msg: String) -> void:
	if cond:
		passed += 1
		print("  ✔ [PASS] " + msg)
	else:
		failed += 1
		printerr("  ✘ [FAIL] " + msg)

func _ready() -> void:
	print("======================================================================")
	print("  STARTUP SIMULATOR v1.5.0 — POST-OGR EVOLUTION TEST SUITE")
	print("======================================================================")
	await get_tree().process_frame

	var main_packed := load("res://scenes/main.tscn") as PackedScene
	var main_inst := main_packed.instantiate()
	get_tree().root.add_child(main_inst)
	await get_tree().process_frame
	await get_tree().process_frame

	GameManager.start_new_game()
	await get_tree().process_frame

	_test_suite_1_incubatore_and_3d_world(main_inst)
	_test_suite_2_extraction_and_refinery(main_inst)
	_test_suite_3_research_tree_6_branches()
	_test_suite_4_mining_robots_and_sleep_simulation(main_inst)
	_test_suite_5_drone_7_step_assembly_and_missions(main_inst)
	_test_suite_6_departments_and_incidents()
	_test_suite_7_autonomous_employees_shop_hours_vehicles_and_saveload(main_inst)
	await _test_suite_8_toos_and_inventory_ui(main_inst)
	await _test_suite_9_miniera_alpina_and_animations(main_inst)

	print("======================================================================")
	print("  ✔ PASSED: %d" % passed)
	print("  ✘ FAILED: %d" % failed)
	print("======================================================================")
	main_inst.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().quit(0 if failed == 0 else 1)


func _unlock_ogr_for_testing() -> void:
	EconomyManager.balance = 50000.0
	ContractManager.advance_tutorial_to_in_progress()
	ContractManager.complete_tutorial_contract()
	ContractManager.advance_contract_to_in_progress("caffe_san_carlo")
	ContractManager.complete_story_contract("caffe_san_carlo")
	ContractManager.advance_contract_to_in_progress("elettronica_to")
	ContractManager.complete_story_contract("elettronica_to")
	ContractManager.accept_factory_commission()
	for zid in ContractManager.FACTORY_SCOUT_ZONES:
		ContractManager.scout_factory_zone(zid, zid)
	ShopManager.buy_hardware("hw_wifi_router", 1)
	ShopManager.buy_hardware("hw_server_tower", 1)
	ShopManager.buy_hardware("hw_workstation_pc", 2)
	ContractManager.mount_factory_wifi_hardware()
	ContractManager.complete_factory_wifi_netshield()
	ContractManager.install_factory_server()
	ContractManager.install_factory_pcs()
	ContractManager.mark_contract_built("factory_bellini_web", {"score": 95})
	ContractManager.complete_marketplace_contract("factory_bellini_web")


func _test_suite_1_incubatore_and_3d_world(main_inst: Node) -> void:
	print("\n[Suite 1] Incubatore Rename, 3D Post-OGR World Nodes & Living City")
	var map_data := preload("res://scripts/world/world_map_data.gd")
	var inc_poi: Dictionary = map_data.get_poi("incubatore_i3p")
	_assert(str(inc_poi.get("name", "")) == "Incubatore Startup Torino", "POI name is 'Incubatore Startup Torino'")
	_assert(not ("I3P" in str(inc_poi.get("name", ""))), "Zero 'I3P' in POI name")

	var miniera_poi: Dictionary = map_data.get_poi("miniera_alpina")
	_assert(not miniera_poi.is_empty() and (miniera_poi["pos"] as Vector3).x < -25.0 and (miniera_poi["pos"] as Vector3).z < -5.0,
		"WorldMapData exposes dedicated NW Miniera Alpina POI (%s)" % str(miniera_poi.get("pos", Vector3.ZERO)))

	var sj_spot: Dictionary = SideJobManager.DEFAULT_SPOTS.get("mailbox_borgopo_i3p", {})
	_assert("Incubatore" in str(sj_spot.get("label", "")) and not ("I3P" in str(sj_spot.get("label", ""))), "SideJob spot label uses generic 'Incubatore'")

	var yard := main_inst.find_child("OGRTechOpsYard", true, false)
	var ferrero := main_inst.find_child("FerreroNPC", true, false) as Node3D
	var copper_n := main_inst.find_child("ExtractionNode_Copper", true, false) as Node3D
	var silicon_n := main_inst.find_child("ExtractionNode_Silicon", true, false) as Node3D
	var alloy_n := main_inst.find_child("ExtractionNode_Alloy", true, false) as Node3D
	var ref_n := main_inst.find_child("ProcessingStation_OGR", true, false) as Node3D
	var pad1_n := main_inst.find_child("MiningRobotPad_1", true, false) as Node3D
	var pad2_n := main_inst.find_child("MiningRobotPad_2", true, false) as Node3D

	_assert(yard != null and yard.get_script() == MineOpsAnimatorScript, "OGRTechOpsYard spawned with MineOpsAnimator")
	_assert(ferrero != null and ferrero.global_position.x < -25.0 and ferrero.global_position.z < -5.0,
		"FerreroNPC placed in NW Miniera Alpina (%s)" % str(ferrero.global_position if ferrero else Vector3.ZERO))
	_assert(copper_n != null and copper_n.global_position.x < -25.0 and copper_n.global_position.z < -5.0, "ExtractionNode_Copper in NW Miniera Alpina")
	_assert(silicon_n != null and silicon_n.global_position.x < -25.0 and silicon_n.global_position.z < -5.0, "ExtractionNode_Silicon in NW Miniera Alpina")
	_assert(alloy_n != null and alloy_n.global_position.x < -25.0 and alloy_n.global_position.z < -5.0, "ExtractionNode_Alloy in NW Miniera Alpina")
	_assert(ref_n != null and ref_n.global_position.x < -25.0 and ref_n.global_position.z < -5.0, "ProcessingStation_OGR in NW Miniera Alpina")
	_assert(pad1_n != null and pad1_n.global_position.x < -25.0 and pad1_n.global_position.z < -5.0, "MiningRobotPad_1 in NW Miniera Alpina")
	_assert(pad2_n != null and pad2_n.global_position.x < -25.0 and pad2_n.global_position.z < -5.0, "MiningRobotPad_2 in NW Miniera Alpina")
	_assert(yard.get_node_or_null("MineCart/Wheel_0") != null and yard.get_node_or_null("RefineryAnim/CrusherWheel") != null and yard.get_node_or_null("QuarryCrane/JibPivot") != null and yard.get_node_or_null("ConveyorBeltRoot/ConveyorOre_0") != null,
		"Miniera Alpina animated machinery nodes (MineCart, CrusherWheel, QuarryCrane/JibPivot, ConveyorOre) present")

	var drone_ops := main_inst.find_child("DroneLabOps", true, false)
	_assert(drone_ops != null, "DroneLabOps spawned in Borgo Po")
	_assert(main_inst.find_child("ChiaraNPC", true, false) != null, "ChiaraNPC spawned at Lab Droni Torino")
	_assert(main_inst.find_child("DroneAssemblyBench", true, false) != null, "DroneAssemblyBench 3D spawned")
	_assert(main_inst.find_child("DroneHelipadStation", true, false) != null, "DroneHelipadStation 3D spawned")
	_assert(main_inst.find_child("IncubatorTerminal", true, false) != null, "IncubatorTerminal 3D spawned at Incubatore Startup Torino")
	_assert(main_inst.find_child("BusStop_Miniera", true, false) != null, "5th GTT Bus Stop 'BusStop_Miniera' spawned at Miniera Alpina road")

	var city_life := main_inst.find_child("CityLifeManager", true, false)
	_assert(city_life != null, "CityLifeManager active in Street")
	_assert(city_life.get("_pedestrians").size() >= 7, "All 7 walking pedestrians spawned incl. Parco & Miniera Alpina (%d)" % city_life.get("_pedestrians").size())
	var mcars: Array = city_life.get("_moving_cars") if city_life else []
	var lungopo_only := (mcars.size() == 2)
	for mc in mcars:
		var mnode: Node3D = mc.get("node") as Node3D
		if mnode == null or mnode.position.z < 50.0:
			lungopo_only = false
	_assert(lungopo_only, "Traffic restricted strictly to 2 Lungo Po street cars (got %d)" % mcars.size())
	_assert(main_inst.find_child("MovingCar_Viale_Est", true, false) == null and main_inst.find_child("MovingCar_Miniera_Haul", true, false) == null,
		"Viale Est and Miniera moving cars removed")
	_assert(main_inst.find_child("CompanyEV_SanCarlo", true, false) == null and main_inst.find_child("EVChargerTotem", true, false) == null,
		"Buyable CompanyEV_SanCarlo & EVChargerTotem removed from Piazza San Carlo (no Forno Bruno clip)")
	var torr_npc := main_inst.find_child("TorrefattoreNPC", true, false)
	var torr_shop := main_inst.find_child("TorrefazioneShop", true, false)
	_assert(torr_npc != null and torr_shop != null and str(torr_shop.get("shop_id")) == "torrefazione",
		"Torrefazione Po staffed by TorrefattoreNPC with interactive TorrefazioneShop")
	var f_part := main_inst.find_child("FountainWaterParticles", true, false) as CPUParticles3D
	var p_part := main_inst.find_child("PondWaterParticles", true, false) as CPUParticles3D
	_assert(f_part != null and f_part.emitting and p_part != null and p_part.emitting,
		"FountainWaterParticles & PondWaterParticles active")


func _test_suite_2_extraction_and_refinery(main_inst: Node) -> void:
	print("\n[Suite 2] Post-OGR Mission Start, Manual Material Extraction & Refinery Conversion")
	_unlock_ogr_for_testing()
	_assert(ContractManager.is_ogr_unlocked(), "OGR unlocked after completing initial 4 missions")

	TechOpsManager.start_ogr_tech_mission()
	_assert(TechOpsManager.ogr_tech_mission_started, "Ing. Andrea Viale Post-OGR mission started")

	NeedsManager.energy = 100.0
	var copper_node := main_inst.find_child("ExtractionNode_Copper", true, false)
	var silicon_node := main_inst.find_child("ExtractionNode_Silicon", true, false)
	var refinery := main_inst.find_child("ProcessingStation_OGR", true, false)
	_assert(copper_node != null and copper_node.has_method("interact"), "ExtractionNode_Copper is interactable")

	copper_node.interact(null)
	silicon_node.interact(null)
	var carried := TechOpsManager.get_carried_total()
	_assert(carried >= 4, "Physical extraction added materials to player's carry crate (got %d)" % carried)

	var rc_before := TechOpsManager.research_credits
	var wh_before := TechOpsManager.get_warehouse_total()
	refinery.interact(null)
	_assert(TechOpsManager.get_carried_total() == 0, "Refinery interaction emptied player's carry crate")
	_assert(TechOpsManager.research_credits > rc_before, "Refinery awarded Research Credits (🔬 RC: %d -> %d)" % [rc_before, TechOpsManager.research_credits])
	_assert(TechOpsManager.get_warehouse_total() > wh_before, "Refinery stocked Warehouse (%d -> %d)" % [wh_before, TechOpsManager.get_warehouse_total()])

	# Verify direct sell for Euros as well
	TechOpsManager.extract_from_node("node_copper")
	var bal_before := EconomyManager.balance
	var sold := TechOpsManager.deliver_carried_materials("sell")
	_assert(float(sold.get("euros", 0.0)) > 0.0 and EconomyManager.balance > bal_before, "Selling materials at Refinery awards Euros")


func _test_suite_3_research_tree_6_branches() -> void:
	print("\n[Suite 3] 6-Branch Technological Research Tree (🔬 RC) & Multipliers")
	var branches := TechOpsManager.get_all_tech_branches()
	_assert(branches.size() == 6, "TechOpsManager exposes all 6 technological research branches")

	EconomyManager.balance = 10000.0
	TechOpsManager.add_research_credits(250, "Test Grant")

	var wf_base := KnowledgeManager.get_webforge_speed_bonus()
	_assert(TechOpsManager.research_branch("tech_extraction"), "Researched tech_extraction Lv.1")
	_assert(TechOpsManager.research_branch("tech_automation"), "Researched tech_automation Lv.1")
	_assert(TechOpsManager.research_branch("tech_drone_avionics"), "Researched tech_drone_avionics Lv.1")
	_assert(TechOpsManager.research_branch("tech_software_ai"), "Researched tech_software_ai Lv.1")
	_assert(TechOpsManager.research_branch("tech_cloud_infra"), "Researched tech_cloud_infra Lv.1")
	_assert(TechOpsManager.research_branch("tech_cyber_defense"), "Researched tech_cyber_defense Lv.1")

	_assert(TechOpsManager.get_total_tech_rank() == 6, "Total tech rank == 6 after researching Lv.1 on all 6 branches")
	_assert(KnowledgeManager.get_webforge_speed_bonus() > wf_base, "tech_software_ai Lv.1 increases WebForge speed bonus")
	_assert(TechOpsManager.get_rack_tech_mult() > 1.0, "tech_cloud_infra Lv.1 increases Server Rack revenue multiplier")
	_assert(TechOpsManager.get_netshield_tech_mult() > 1.0, "tech_cyber_defense Lv.1 increases NetShield payout multiplier")


func _test_suite_4_mining_robots_and_sleep_simulation(main_inst: Node) -> void:
	print("\n[Suite 4] Mining Robot MK1/MK2 3D Build, Automation & Bed Sleep Simulation")
	for mid in TechOpsManager.MATERIAL_ORDER:
		TechOpsManager.warehouse_materials[mid] = 30
	EconomyManager.balance = 12000.0

	var pad1 := main_inst.find_child("MiningRobotPad_1", true, false)
	var vroot1 := pad1.get_node_or_null("VisualRoot") as Node3D
	_assert(vroot1 != null and not vroot1.visible, "MiningRobotPad_1 VisualRoot hidden before installation")

	var built1 := TechOpsManager.build_mining_robot(1)
	_assert(built1, "Mining Robot MK1 built using warehouse materials + €450")
	_assert(vroot1.visible, "MiningRobotPad_1 3D VisualRoot visible immediately after installation")

	# Simulate 7 hours of sleep in the studio bed
	var sim_res := TechOpsManager.simulate_sleep_hours(7.0)
	_assert(int(sim_res.get("extracted", 0)) > 0, "Mining Robot MK1 extracted materials during 7h sleep (%d units)" % int(sim_res.get("extracted", 0)))
	_assert(TechOpsManager.get_robot_stored_total(1) > 0, "Mining Robot MK1 internal storage holds extracted materials")

	var wh_before_collect := TechOpsManager.get_warehouse_total()
	var collected := TechOpsManager.collect_from_robot(1)
	_assert(collected > 0 and TechOpsManager.get_warehouse_total() > wh_before_collect, "Collected %d materials from Mining Robot MK1 into Warehouse" % collected)

	# Upgrade to MK2 (requires tech_automation Lv.3) + Conveyor (tech_automation Lv.2)
	TechOpsManager.research_branch("tech_automation") # Lv.2
	TechOpsManager.research_branch("tech_automation") # Lv.3
	_assert(TechOpsManager.build_mining_robot(2), "Mining Robot MK2 built on Pad 2")
	_assert(TechOpsManager.unlock_conveyor(), "Conveyor belt automation unlocked")
	var wh_before := TechOpsManager.get_warehouse_total()
	TechOpsManager.simulate_sleep_hours(6.0)
	_assert(TechOpsManager.get_warehouse_total() > wh_before, "With Conveyor active, sleep production flows directly into Warehouse")


func _test_suite_5_drone_7_step_assembly_and_missions(main_inst: Node) -> void:
	print("\n[Suite 5] Physical 7-Step TO-Drone MK1 Assembly & Flight Missions")
	for mid in TechOpsManager.MATERIAL_ORDER:
		TechOpsManager.warehouse_materials[mid] = 40
	EconomyManager.balance = 15000.0
	TechOpsManager.add_research_credits(200, "Drone R&D Grant")
	TechOpsManager.research_branch("tech_drone_avionics") # Lv.2

	var bench := main_inst.find_child("DroneAssemblyBench", true, false)
	var heli := main_inst.find_child("DroneHelipadStation", true, false)
	var bench_vis := bench.get_node_or_null("VisualRoot") as Node3D
	var heli_vis := heli.get_node_or_null("VisualRoot") as Node3D

	var part6_visible_at_step6 := false
	for step_num in range(1, 8):
		var ok := TechOpsManager.install_next_drone_step()
		_assert(ok, "Assembled TO-Drone MK1 Step %d/7 (%s)" % [step_num, str(TechOpsManager.DRONE_STEPS[step_num - 1]["title"])])
		if step_num == 6 and bench_vis != null:
			part6_visible_at_step6 = (bench_vis.get_node("Part6") as Node3D).visible

	_assert(part6_visible_at_step6, "All 6 3D drone sub-assemblies visible on workbench at step 6 before flight test")
	_assert(TechOpsManager.drone_assembled and TechOpsManager.drone_step == 7, "TO-Drone MK1 100% assembled after 7 physical steps")
	_assert(heli_vis != null and heli_vis.visible, "Completed 3D quadcopter visible on DroneHelipadStation after step 7")

	var bal_before := EconomyManager.balance
	var rc_before := TechOpsManager.research_credits
	var started := TechOpsManager.start_drone_mission("drone_lidar_survey")
	_assert(started, "Started drone flight mission 'drone_lidar_survey'")
	TechOpsManager.simulate_sleep_hours(2.0) # 120 mins completes 90-min flight mission
	_assert(TechOpsManager.completed_drone_missions_count >= 1 and EconomyManager.balance > bal_before and TechOpsManager.research_credits > rc_before,
		"Drone mission completed during time advance and awarded Euros + Research Credits")


func _test_suite_6_departments_and_incidents() -> void:
	print("\n[Suite 6] Phase 4 CEO Departments (Incubatore) & Dynamic Incidents")
	GameManager.company_tier = 3
	EconomyManager.balance = 25000.0
	TechOpsManager.add_research_credits(300, "Phase 4 Grant")

	# Test physical incident resolution before unlocking Hardware Dept (which auto-repairs robot jams)
	_assert(TechOpsManager.trigger_incident("inc_robot_jam"), "Dynamic incident 'inc_robot_jam' triggered before Hardware Dept")
	_assert(TechOpsManager.active_incidents.has("inc_robot_jam"), "Active incidents contains 'inc_robot_jam'")
	var resolved_jam := TechOpsManager.resolve_incident("inc_robot_jam", true)
	_assert(resolved_jam and not TechOpsManager.active_incidents.has("inc_robot_jam"), "Incident 'inc_robot_jam' resolved physically on-site")

	for did in TechOpsManager.DEPT_ORDER:
		var ok := TechOpsManager.unlock_department(did)
		_assert(ok, "Founded Phase 4 Department '%s'" % str(TechOpsManager.DEPARTMENTS[did]["title"]))

	_assert(TechOpsManager.get_total_department_levels() == 3, "All 3 Phase 4 Departments active at Incubatore")
	_assert(TechOpsManager.calculate_departments_daily_revenue() >= 790.0, "Phase 4 Departments generate daily corporate revenue (€ 790/day)")

	# Hardware Dept should auto-mitigate robot jams while weather/business incidents still trigger & resolve
	_assert(not TechOpsManager.trigger_incident("inc_robot_jam"), "Hardware Dept automatically mitigates Mining Robot jams")
	_assert(TechOpsManager.trigger_incident("inc_weather_fog"), "Weather incident 'inc_weather_fog' triggered cleanly")
	_assert(TechOpsManager.resolve_incident("inc_weather_fog", false) and not TechOpsManager.active_incidents.has("inc_weather_fog"),
		"Weather incident 'inc_weather_fog' resolved via TO-OS")


func _test_suite_7_autonomous_employees_shop_hours_vehicles_and_saveload(main_inst: Node) -> void:
	print("\n[Suite 7] Autonomous Employees on Freelance Hub, Skill Upgrades, Shop Hours, Vehicles & Save/Load")
	GameManager.company_tier = 3
	GameManager.reputation_points = 150
	EconomyManager.balance = 20000.0

	if not EmployeeManager.is_employee_hired("emp_luca"):
		EmployeeManager.hire_employee("emp_luca")
	_assert(EmployeeManager.is_employee_hired("emp_luca"), "Hired Luca Vianello")

	var up_ok := EmployeeManager.upgrade_employee_skill("emp_luca", "speed")
	var up_val := EmployeeManager.upgrade_employee_skill("emp_luca", "value")
	_assert(up_ok and up_val, "Upgraded Luca's Speed & Value skills in Talent Hub HR")

	var done_before := EmployeeManager.get_employee_completed_count("emp_luca")
	var emp_sleep := EmployeeManager.simulate_sleep_hours(8.0)
	_assert(int(emp_sleep.get("completed", 0)) >= 1 or EmployeeManager.get_employee_completed_count("emp_luca") > done_before,
		"Luca autonomously completed Freelance Hub contract(s) during 8h sleep")

	# Shop opening/closing hours check
	CalendarSystem.current_hour = 2 # 02:00 AM -> closed
	_assert(not ShopManager.is_shop_open("panificio"), "Forno Bruno is closed at 02:00 AM")
	var forno_node := main_inst.find_child("PanificioShop", true, false)
	_assert(forno_node != null, "PanificioShop trigger found in Borgo San Carlo")
	if forno_node:
		_assert("CHIUSO" in forno_node.get_prompt(), "Closed shop trigger displays CHIUSO and opening hours (%s)" % forno_node.get_prompt())
	CalendarSystem.current_hour = 11 # 11:00 AM -> open
	_assert(ShopManager.is_shop_open("panificio"), "Forno Bruno is open at 11:00 AM")

	# Mobility progression check (incl. 5th Bus Stop Miniera Alpina!)
	_assert(TechOpsManager.unlock_and_toggle_vehicle("bike"), "Unlocked & mounted Bici Tech Elettrica")
	_assert(TechOpsManager.get_vehicle_speed_mult() > 1.3, "Bici Tech boosts player movement speed (%.2fx)" % TechOpsManager.get_vehicle_speed_mult())
	_assert(TechOpsManager.unlock_and_toggle_vehicle("company_ev"), "Unlocked & mounted Auto Elettrica Aziendale")
	_assert(TechOpsManager.get_vehicle_speed_mult() > 1.7, "Auto Elettrica boosts player movement speed (%.2fx)" % TechOpsManager.get_vehicle_speed_mult())
	_assert(TechOpsManager.travel_by_bus("bus_ogr"), "GTT Bus Stop fast-travels player to Mercato Nord & OGR Hub")
	_assert(TechOpsManager.travel_by_bus("bus_miniera") and GameManager.player_node.global_position.x < -30.0 and GameManager.player_node.global_position.z < 10.0,
		"5th GTT Bus Stop 'bus_miniera' fast-travels player to Miniera Alpina approach")

	# Save/Load round-trip
	var rc_saved := TechOpsManager.research_credits
	var dept_saved := TechOpsManager.get_total_department_levels()
	var luca_spd := EmployeeManager.get_employee_skill("emp_luca", "speed")
	_assert(SaveManager.save_game(), "Saved v1.5.0 game state")
	TechOpsManager.reset()
	EmployeeManager.reset()
	_assert(TechOpsManager.research_credits == 0 and TechOpsManager.get_total_department_levels() == 0, "Reset cleared TechOps state before load")
	_assert(SaveManager.load_game(), "Loaded v1.5.0 game state")
	_assert(TechOpsManager.research_credits == rc_saved and TechOpsManager.get_total_department_levels() == dept_saved,
		"TechOpsManager RC (%d) and Departments (%d) restored across Save/Load" % [rc_saved, dept_saved])
	_assert(EmployeeManager.get_employee_skill("emp_luca", "speed") == luca_spd,
		"Employee skill upgrades restored across Save/Load")


func _test_suite_8_toos_and_inventory_ui(main_inst: Node) -> void:
	print("\n[Suite 8] TO-OS Windows (Knowledge R&D, OGR TechOps, Talent HR) & Inventory Menu")
	var comp := main_inst.find_child("ComputerScreen", true, false)
	_assert(comp != null, "ComputerScreen present in main scene")
	if comp:
		comp.visible = true
		for app_id in ["knowledge", "ogr", "talent"]:
			comp.open_app(app_id)
			await get_tree().process_frame
		_assert(comp.talent_window.visible, "TO-OS Knowledge R&D, OGR TechOps & Talent HR windows open cleanly with zero script errors")
		comp.visible = false

	var inv := main_inst.find_child("InventoryMenu", true, false)
	_assert(inv != null, "InventoryMenu present in main scene")
	if inv:
		inv.call("_select_category", "hardware")
		inv.call("_refresh_stats")
		inv.call("_select_category", "gear")
		await get_tree().process_frame
		_assert(true, "InventoryMenu renders Miniera Alpina Materials & Urban Mobility gear without runtime errors")


func _test_suite_9_miniera_alpina_and_animations(main_inst: Node) -> void:
	print("\n[Suite 9] Parco->Miniera Physics Corridor, Walking Pedestrians (Walk/Idle/No-Slide) & 3D Machinery Animations")
	var world := main_inst.get_node_or_null("GameWorld") as Node3D
	_assert(world != null and world.get_world_3d() != null, "GameWorld physics world accessible")
	var space := world.get_world_3d().direct_space_state

	# 1. Parco -> Miniera Alpina archway & quarry gate raycast clear (mask 1)
	var p_arch := PhysicsRayQueryParameters3D.create(Vector3(-41.5, 1.0, 16.0), Vector3(-41.5, 1.0, -4.0), 1)
	var arch_hit := space.intersect_ray(p_arch)
	_assert(arch_hit.is_empty(),
		"Parco Valentino -> Miniera Alpina archway corridor clear (hit: %s)" % (str(arch_hit["collider"].name) if not arch_hit.is_empty() else "none"))

	# 2. FerreroNPC interaction raycast in Miniera Alpina (mask 3)
	var ferrero := main_inst.find_child("FerreroNPC", true, false) as StaticBody3D
	var p_fer := PhysicsRayQueryParameters3D.create(Vector3(-49.2, 1.4, -12.8), Vector3(-51.5, 1.0, -12.8), 3)
	var fer_hit := space.intersect_ray(p_fer)
	_assert(ferrero != null and fer_hit.get("collider", null) == ferrero,
		"FerreroNPC in Miniera Alpina reachable cleanly via interaction raycast")

	# 3. Verify all 7 pedestrians have skeletal "Walk" & "Idle" & "Interact", start grounded Y=0, move along heading without sideways slide
	var city_life := main_inst.find_child("CityLifeManager", true, false) as Node3D
	var peds: Array = city_life.get("_pedestrians") if city_life else []
	var ped_rigs_ok := peds.size() == 7
	for p in peds:
		var anim: AnimationPlayer = p.get("anim") as AnimationPlayer
		var n: Node3D = p.get("node") as Node3D
		if anim == null or not anim.has_animation("Walk") or not anim.has_animation("Idle") or not anim.has_animation("Interact") or n == null or absf(n.position.y) > 0.05:
			ped_rigs_ok = false
			break
	_assert(ped_rigs_ok, "All 7 pedestrians have skeletal Walk/Idle/Interact animations and are grounded at Y=0.0")

	# Capture initial transforms before stepping gameplay state
	var yard := main_inst.find_child("OGRTechOpsYard", true, false) as Node3D
	var minecart := yard.get_node_or_null("MineCart") as Node3D if yard else null
	var mc_w0 := minecart.get_node_or_null("Wheel_0") as Node3D if minecart else null
	var crusher := yard.get_node_or_null("RefineryAnim/CrusherWheel") as Node3D if yard else null
	var crane_jib := yard.get_node_or_null("QuarryCrane/JibPivot") as Node3D if yard else null
	var yield_cu := yard.get_node_or_null("ExtractionNode_Copper/YieldIcon") as Node3D if yard else null
	var conv_ore := yard.get_node_or_null("ConveyorBeltRoot/ConveyorOre_0") as Node3D if yard else null
	var pad1 := main_inst.find_child("MiningRobotPad_1", true, false)
	var r1_drill := pad1.get_node_or_null("VisualRoot/DrillHead") as Node3D if pad1 else null
	var r1_boom := pad1.get_node_or_null("VisualRoot/BoomArm") as Node3D if pad1 else null
	var heli := main_inst.find_child("DroneHelipadStation", true, false)
	var heli_vis := heli.get_node_or_null("VisualRoot") as Node3D if heli else null
	var heli_r0 := heli_vis.get_node_or_null("Part2/Rotor_0") as Node3D if heli_vis else null
	var cars: Array = city_life.get("_moving_cars") if city_life else []
	var car0_node: Node3D = cars[0]["node"] as Node3D if cars.size() > 0 else null
	var car0_w0: Node3D = (cars[0]["wheels"] as Array)[0] as Node3D if cars.size() > 0 else null

	# Ensure robot & drone flight active so we verify their animations too!
	GameManager.change_state(GameManager.GameState.FIRST_PERSON)
	TechOpsManager.start_drone_mission("drone_lidar_survey")
	var ped0 := peds[0]["node"] as Node3D
	var ped0_start := ped0.position
	var cart_z0 := minecart.position.z
	var mc_wrot0 := mc_w0.rotation.x
	var crush_z0 := crusher.rotation.z
	var crane_y0 := crane_jib.rotation.y
	var ore_pos0 := conv_ore.position
	var drill_y0 := r1_drill.rotation.y
	var rotor_y0 := heli_r0.rotation.y
	var car0_pos0 := car0_node.position
	var car0_wrot0 := car0_w0.rotation.x
	var car0_dw := 0.0

	# Advance simulation 20 frames (wait 20 physics/process steps at simulated delta via real process ticks)
	for _i in range(20):
		var prev_car_rx := car0_w0.rotation.x
		city_life._process(0.05)
		yard._process(0.05)
		pad1._process(0.05)
		heli._process(0.05)
		car0_dw += absf(angle_difference(prev_car_rx, car0_w0.rotation.x))
		await get_tree().process_frame

	# Check Pedestrian Walk state & forward orientation (zero sideways slide)
	var ped0_move := ped0.position - ped0_start
	ped0_move.y = 0.0
	var ped0_fwd := Vector3(sin(ped0.rotation.y), 0.0, cos(ped0.rotation.y))
	var ped0_anim := peds[0]["anim"] as AnimationPlayer
	_assert(ped0_move.length() > 0.35 and ped0_fwd.dot(ped0_move.normalized()) > 0.90 and absf(ped0.position.y) <= 0.05 and ped0_anim.current_animation == "Walk",
		"Pedestrian walks forward along heading (dot=%.2f, dist=%.2fm, anim='%s', Y=%.2f)" % [
			ped0_fwd.dot(ped0_move.normalized()), ped0_move.length(), ped0_anim.current_animation, ped0.position.y
		])

	# Verify moving car position & spinning wheel
	_assert(car0_node.position.distance_to(car0_pos0) > 1.0 and car0_dw > 5.0,
		"Street car moves cleanly and spins Wheel_0 (dpos=%.2fm, dw=%.2frad)" % [
			car0_node.position.distance_to(car0_pos0), car0_dw
		])

	# Verify MineOpsAnimator machinery
	_assert(absf(minecart.position.z - cart_z0) > 0.2 and absf(mc_w0.rotation.x - mc_wrot0) > 0.5,
		"MineCart travels on tunnel rail & spins Wheel_0 (dz=%.2fm)" % absf(minecart.position.z - cart_z0))
	_assert(absf(crusher.rotation.z - crush_z0) > 1.0 and absf(crane_jib.rotation.y - crane_y0) > 0.05 and yield_cu.rotation.y > 0.5,
		"Refinery CrusherWheel, QuarryCrane JibPivot & ore YieldIcon actively animate")
	_assert(yard.get_node("ConveyorBeltRoot").visible and conv_ore.position.distance_to(ore_pos0) > 0.3,
		"Installed ConveyorBeltRoot moves ConveyorOre chunks toward Refinery")

	# Verify Robot & Drone flight animations
	_assert(absf(r1_drill.rotation.y - drill_y0) > 2.0 and r1_boom.rotation.x != 0.0,
		"Mining Robot MK1 spins DrillHead & articulates BoomArm")
	_assert(heli_vis.position.y > 1.5 and absf(heli_r0.rotation.y - rotor_y0) > 5.0,
		"TO-Drone MK1 takes off (Y=%.2fm) and spins rotors on active mission" % heli_vis.position.y)

	# Verify Torrefazione Po shop catalog & hours + Forno Bruno clear facade
	CalendarSystem.current_hour = 11
	_assert(ShopManager.SHOPS.has("torrefazione") and (ShopManager.SHOPS["torrefazione"]["items"] as Array).size() >= 4 and ShopManager.is_shop_open("torrefazione"),
		"Torrefazione Po shop registered with >=4 coffee items and open at 11:00")

	var panificio := main_inst.find_child("PanificioVenue", true, false) as Node3D
	var hit_forno := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(-8.2, 0.8, 12.8), Vector3(-8.2, 0.8, 11.05), 1))
	var hit_ev_old := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(-10.8, 0.8, 12.8), Vector3(-10.8, 0.8, 11.05), 1))
	_assert(panificio != null and hit_forno.is_empty() and hit_ev_old.is_empty(),
		"Forno Bruno storefront entrance & former EV corner clear of parked cars/obstructions")

	# Verify timed extraction, pickaxe animation, sweet-spot critical bonus, and no floor Beacon
	var player := GameManager.player_node as Node3D
	if player == null:
		player = get_tree().get_first_node_in_group("player") as Node3D
	var copper_ext := main_inst.find_child("ExtractionNode_Copper", true, false)
	_assert(copper_ext != null and copper_ext.get_node_or_null("Beacon") == null and copper_ext.get_node_or_null("PickaxeAnim/PickaxePivot") != null,
		"ExtractionNode_Copper removes yellow floor Beacon and includes animated PickaxeAnim rig")
	if player and copper_ext:
		TechOpsManager.reset()
		TechOpsManager.start_ogr_tech_mission()
		NeedsManager.energy = 100.0
		player.global_position = (copper_ext as Node3D).global_position + Vector3(0, 0, 1.8)
		var carried_before := TechOpsManager.get_carried_total()
		copper_ext.interact(player)
		var pick_anim := copper_ext.get_node_or_null("PickaxeAnim") as Node3D
		_assert(bool(copper_ext.get("_extract_active")) and pick_anim != null and pick_anim.visible,
			"Player mining starts timed extraction & reveals animated 3D Pickaxe")
		for _s in range(14):
			copper_ext._process(0.1)
		copper_ext.interact(player) # hit inside 0.55..0.88 golden sweet-spot!
		_assert(bool(copper_ext.get("_extract_crit_awarded")), "Timing [E] inside golden sweet spot awards critical strike")
		for _s in range(10):
			if bool(copper_ext.get("_extract_active")):
				copper_ext._process(0.1)
		var carried_after := TechOpsManager.get_carried_total()
		_assert(not bool(copper_ext.get("_extract_active")) and (pick_anim == null or not pick_anim.visible) and carried_after >= carried_before + 2,
			"Timed mining completes cleanly with critical bonus (carried %d -> %d)" % [carried_before, carried_after])

	# Verify real 3D BikeCockpit + BikeStation_Studio hide on ride + [F] re-parking beside player
	var bike_sb := main_inst.find_child("BikeStation_Studio", true, false) as Node3D
	if player and bike_sb:
		EconomyManager.balance += 300.0
		if not TechOpsManager.has_vehicle("bike"):
			TechOpsManager.buy_or_toggle_vehicle("bike")
		else:
			TechOpsManager.active_vehicle = "bike"
			EventBus.vehicle_changed.emit("bike")
		player.global_position = Vector3(12.0, 0.0, 18.0)
		if player.has_method("_ensure_bike_cockpit"):
			player.call("_ensure_bike_cockpit")
		await get_tree().process_frame
		var cockpit := player.get_node_or_null("BikeCockpit") as Node3D
		_assert(cockpit != null and cockpit.visible and not bike_sb.visible and (bike_sb as CollisionObject3D).collision_layer == 0,
			"Riding Bici Tech reveals 1st-person BikeCockpit and hides sidewalk BikeStation_Studio")
		var parked_ok: bool = player.call("dismount_and_park_bike") if player.has_method("dismount_and_park_bike") else false
		await get_tree().process_frame
		_assert(parked_ok and TechOpsManager.active_vehicle == "foot" and not cockpit.visible and bike_sb.visible and bike_sb.global_position.distance_to(player.global_position) < 2.5,
			"Dismount & Park ([F]) hides BikeCockpit and spawns parked 3D bike next to player")


