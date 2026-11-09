extends Node
## TestRunner - Automated test harness for Startup Simulator
## Covers Milestones 1 through 6: Economy, Contracts, Infrastructure, Employees, World & Anti-clipping

func _ready() -> void:
	print("\n==================================================")
	print(">>> STARTUP SIMULATOR - AUTOMATED QA TEST SUITE <<<")
	print("==================================================\n")
	
	var all_passed = true
	all_passed = run_economy_tests() and all_passed
	all_passed = run_contract_tests() and all_passed
	all_passed = run_save_tests() and all_passed
	all_passed = run_calendar_tests() and all_passed
	all_passed = run_marketplace_tests() and all_passed
	all_passed = run_server_rack_tests() and all_passed
	all_passed = run_server_tier_and_overload_tests() and all_passed
	all_passed = run_employee_recruitment_tests() and all_passed
	all_passed = run_story_progression_tests() and all_passed
	all_passed = run_ui_screen_containment_tests() and all_passed
	all_passed = run_firewall_routing_tests() and all_passed
	all_passed = run_timed_compilation_tests() and all_passed
	all_passed = run_vertical_slice_integration() and all_passed
	all_passed = run_world_navigation_tests() and all_passed
	
	print("\n==================================================")
	if all_passed:
		print(">>> ALL TESTS PASSED! QUALITY CRITERIA MET. <<<")
		print("==================================================\n")
		get_tree().quit(0)
	else:
		printerr(">>> SOME TESTS FAILED! CHECK OUTPUT ABOVE. <<<")
		print("==================================================\n")
		get_tree().quit(1)

func assert_true(condition: bool, test_name: String) -> bool:
	if condition:
		print("  ✔ [PASS] %s" % test_name)
		return true
	else:
		printerr("  ✘ [FAIL] %s" % test_name)
		return false

func run_economy_tests() -> bool:
	print("--- Running EconomyManager Unit Tests ---")
	var passed = true
	
	EconomyManager.reset_economy(250.0)
	passed = assert_true(EconomyManager.balance == 250.0, "Starting balance is € 250.00") and passed
	passed = assert_true(EconomyManager.can_afford(200.0), "Can afford € 200.00") and passed
	passed = assert_true(not EconomyManager.can_afford(300.0), "Cannot afford € 300.00 with € 250.00") and passed
	
	var spent = EconomyManager.spend(50.0, "Test Spesa")
	passed = assert_true(spent and EconomyManager.balance == 200.0, "Spend deduction correctly updates balance") and passed
	
	EconomyManager.earn(100.0, "Test Entrata")
	passed = assert_true(EconomyManager.balance == 300.0, "Earn addition correctly updates balance") and passed
	passed = assert_true(EconomyManager.ledger.size() >= 3, "Ledger logs transactions accurately") and passed
	
	return passed

func run_contract_tests() -> bool:
	print("\n--- Running ContractManager Unit Tests ---")
	var passed = true
	
	ContractManager.init_tutorial_contract()
	var tut = ContractManager.get_tutorial_contract()
	passed = assert_true(tut.get("status") == "available", "Tutorial contract initialized as 'available'") and passed
	passed = assert_true(tut.get("budget") == 650.0, "Pizzeria Da Mario budget is € 650.00") and passed
	
	ContractManager.advance_tutorial_to_in_progress()
	tut = ContractManager.get_tutorial_contract()
	passed = assert_true(tut.get("status") == "in_progress", "Contract status advanced to 'in_progress'") and passed
	
	var build_data = {"quality": 100.0, "components": 5}
	ContractManager.mark_tutorial_website_built(build_data)
	tut = ContractManager.get_tutorial_contract()
	passed = assert_true(tut.get("status") == "built", "Contract status marked as 'built'") and passed
	
	var bal_before = EconomyManager.balance
	ContractManager.complete_tutorial_contract()
	tut = ContractManager.get_tutorial_contract()
	passed = assert_true(tut.get("status") == "completed", "Contract status completed") and passed
	passed = assert_true(EconomyManager.balance == bal_before + 650.0, "Reward of € 650.00 credited") and passed
	passed = assert_true(GameManager.reputation_points >= 15, "Reputation reward awarded (+15)") and passed
	
	return passed

func run_save_tests() -> bool:
	print("\n--- Running SaveManager Unit Tests ---")
	var passed = true
	
	EconomyManager.balance = 850.0
	GameManager.studio_upgrades_installed = ["monitor_upgrade"]
	GameManager.reputation_points = 25
	
	var saved = SaveManager.save_game()
	passed = assert_true(saved and SaveManager.has_save_file(), "Save file successfully written to disk") and passed
	
	# Tamper with current state
	EconomyManager.balance = 0.0
	GameManager.studio_upgrades_installed.clear()
	GameManager.reputation_points = 0
	
	# Load
	var loaded = SaveManager.load_game()
	passed = assert_true(loaded, "Save file parsed and loaded cleanly") and passed
	passed = assert_true(EconomyManager.balance == 850.0, "Balance restored correctly from save") and passed
	passed = assert_true(GameManager.reputation_points == 25, "Reputation restored correctly") and passed
	passed = assert_true("monitor_upgrade" in GameManager.studio_upgrades_installed, "Installed upgrades restored") and passed
	
	return passed

func run_calendar_tests() -> bool:
	print("\n--- Running CalendarSystem & Daily Expenses Unit Tests ---")
	var passed = true
	
	CalendarSystem.current_hour = 23
	CalendarSystem.current_minute = 59
	CalendarSystem.current_day = 1
	var bal_before = EconomyManager.balance
	
	# Simulate midnight rollover
	CalendarSystem._advance_minute()
	passed = assert_true(CalendarSystem.current_hour == 0, "Hour reset to 00:00 at midnight") and passed
	passed = assert_true(CalendarSystem.current_day == 2, "Day advanced to Day 2") and passed
	passed = assert_true(EconomyManager.balance <= bal_before - 38.0, "Daily overhead expenses deducted") and passed
	
	return passed

func run_marketplace_tests() -> bool:
	print("\n--- Running Procedural Marketplace Unit Tests ---")
	var passed = true
	
	ContractManager.refresh_marketplace()
	passed = assert_true(ContractManager.marketplace_contracts.size() >= 4, "Marketplace generated at least 4 tech commissions") and passed
	
	var first_c = ContractManager.marketplace_contracts[0]
	var c_id = str(first_c["id"])
	var c_budget = float(first_c["budget"])
	var bal_before = EconomyManager.balance
	
	var accepted = ContractManager.accept_marketplace_contract(c_id)
	passed = assert_true(accepted, "Accepted marketplace contract: " + first_c["title"]) and passed
	passed = assert_true(ContractManager.active_contracts.has(c_id), "Contract moved into active_contracts") and passed
	
	var completed = ContractManager.complete_marketplace_contract(c_id)
	passed = assert_true(completed, "Marketplace contract completed and delivered") and passed
	passed = assert_true(EconomyManager.balance == bal_before + c_budget, "Commissions reward credited") and passed
	
	return passed

func run_server_rack_tests() -> bool:
	print("\n--- Running Milestone 5 ServerRackManager Unit Tests ---")
	var passed = true
	
	ServerRackManager.unlock_server_rack()
	passed = assert_true(ServerRackManager.is_rack_unlocked, "Server rack unlocked successfully") and passed
	
	ServerRackManager.set_cooling_mode("boost")
	passed = assert_true(ServerRackManager.cooling_mode == "boost", "Cooling mode set to Boost") and passed
	passed = assert_true(ServerRackManager.fan_speed_rpm == 4500, "Fan RPM boosted to 4500") and passed
	
	ServerRackManager.set_cooling_mode("auto")
	passed = assert_true(ServerRackManager.cooling_mode == "auto", "Cooling mode reverted to Auto") and passed
	
	# Add client domain
	ServerRackManager.add_hosted_client("testdomain.it", "Test Client", 50.0)
	var rev = ServerRackManager.calculate_daily_hosting_revenue()
	passed = assert_true(rev >= 50.0, "Daily hosting revenue calculated accurately (+€ %0.2f)" % rev) and passed
	
	# Physical maintenance
	ServerRackManager.trigger_incident("thermal_throttle", "Surriscaldamento", "Test")
	passed = assert_true(ServerRackManager.active_incident == "thermal_throttle", "Incident triggered") and passed
	ServerRackManager.resolve_physical_maintenance()
	passed = assert_true(ServerRackManager.active_incident == "", "Physical maintenance cleared active incident") and passed
	
	return passed

func run_employee_recruitment_tests() -> bool:
	print("\n--- Running Milestone 6 EmployeeManager Unit Tests ---")
	var passed = true
	
	var all_cand = EmployeeManager.get_all_candidates()
	passed = assert_true(all_cand.size() >= 3, "Candidate pool has at least 3 candidates (Luca, Sara, Marco)") and passed
	
	# Give reputation and funds to hire Luca Vianello
	GameManager.reputation_points = 50
	EconomyManager.balance = 500.0
	
	var hired_luca = EmployeeManager.hire_employee("emp_luca")
	passed = assert_true(hired_luca, "Hired candidate Luca Vianello") and passed
	passed = assert_true(EmployeeManager.is_employee_hired("emp_luca"), "Luca registered as hired") and passed
	
	var payroll = EmployeeManager.calculate_daily_payroll()
	passed = assert_true(payroll == 45.0, "Daily payroll calculated accurately (€ 45.00)") and passed
	
	var revenue = EmployeeManager.calculate_employee_revenue()
	passed = assert_true(revenue == 95.0, "Employee passive productivity revenue calculated (€ 95.00)") and passed
	
	# Fire Luca
	var fired = EmployeeManager.fire_employee("emp_luca")
	passed = assert_true(fired, "Fired employee cleanly") and passed
	passed = assert_true(not EmployeeManager.is_employee_hired("emp_luca"), "Luca removed from active team") and passed
	passed = assert_true(EmployeeManager.calculate_daily_payroll() == 0.0, "Payroll zeroed after termination") and passed
	
	return passed

func run_story_progression_tests() -> bool:
	print("\n--- Running Sequential Story Progression (Mario -> Elena -> Davide) ---")
	var passed = true
	
	ContractManager.init_tutorial_contract()
	passed = assert_true(ContractManager.active_contracts.has("pizzeria_da_mario"), "Mission 1 active") and passed
	
	# Complete Mission 1
	ContractManager.advance_tutorial_to_in_progress()
	ContractManager.mark_tutorial_website_built({"quality": 100})
	ContractManager.complete_tutorial_contract()
	
	# Check Mission 2 Unlocked
	passed = assert_true(ContractManager.active_contracts.has("caffe_san_carlo"), "Mission 2 (Caffè San Carlo) unlocked after Mario") and passed
	var cafe = ContractManager.get_contract("caffe_san_carlo")
	passed = assert_true(cafe.get("budget") == 1250.0, "Caffè San Carlo budget is € 1.250,00") and passed
	
	# Advance and complete Mission 2
	ContractManager.advance_contract_to_in_progress("caffe_san_carlo")
	ContractManager.mark_contract_built("caffe_san_carlo", {"quality": 100})
	ContractManager.complete_story_contract("caffe_san_carlo")
	
	# Check Mission 3 Unlocked
	passed = assert_true(ContractManager.active_contracts.has("elettronica_to"), "Mission 3 (Elettronica TO) unlocked after Elena") and passed
	var tech = ContractManager.get_contract("elettronica_to")
	passed = assert_true(tech.get("budget") == 1850.0, "Elettronica TO budget is € 1.850,00") and passed
	
	return passed

func run_vertical_slice_integration() -> bool:
	print("\n--- Running Vertical Slice Full Gameplay Integration ---")
	var passed = true
	
	GameManager.start_new_game()
	passed = assert_true(EconomyManager.balance == 250.0, "1. New Game started with € 250.00") and passed
	passed = assert_true(GameManager.studio_upgrades_installed.is_empty(), "2. Upgrades empty at start") and passed
	
	var tut = ContractManager.get_tutorial_contract()
	passed = assert_true(tut.get("status") == "available", "3. Pizzeria mission discovered") and passed
	
	ContractManager.advance_tutorial_to_in_progress()
	passed = assert_true(ContractManager.get_tutorial_contract().get("status") == "in_progress", "4. Spoke with Mario: contract accepted") and passed
	
	var web_data = {
		"theme": "red",
		"quality": 100.0,
		"components": ["header", "hero", "menu", "hours", "booking"]
	}
	ContractManager.mark_tutorial_website_built(web_data)
	passed = assert_true(ContractManager.get_tutorial_contract().get("status") == "built", "5. WebForge website compiled") and passed
	
	ContractManager.complete_tutorial_contract()
	passed = assert_true(EconomyManager.balance == 900.0, "6. Payment of € 650 received (Total balance: € 900.00)") and passed
	
	var buy_monitor = EconomyManager.spend(350.0, "Acquisto Monitor 27\" Ultrawide")
	passed = assert_true(buy_monitor and EconomyManager.balance == 550.0, "7. Monitor purchased for € 350.00") and passed
	EventBus.item_purchased.emit("monitor_upgrade", 350.0)
	passed = assert_true("monitor_upgrade" in GameManager.studio_upgrades_installed, "8. Monitor upgrade registered in studio") and passed
	
	SaveManager.save_game()
	passed = assert_true(SaveManager.has_save_file(), "9. Vertical slice progress saved successfully") and passed
	
	return passed

func run_world_navigation_tests() -> bool:
	print("\n--- Running 3D World Navigation, Venues & Clearance Tests ---")
	var passed = true
	
	var world_scene = load("res://scenes/world/game_world.tscn")
	passed = assert_true(world_scene != null, "game_world.tscn loads properly") and passed
	
	var world_inst = world_scene.instantiate()
	add_child(world_inst)
	
	var player = world_inst.get_node_or_null("PlayerCharacter")
	passed = assert_true(player != null, "PlayerCharacter exists in game world") and passed
	
	var studio = world_inst.get_node_or_null("Studio")
	passed = assert_true(studio != null, "Studio exists in game world") and passed
	
	# Verify Studio anti-clipping: DeskPlant is clear of MonitorUpgradeProp
	var desk_plant = studio.get_node_or_null("Furniture/DeskPlant")
	var monitor = studio.get_node_or_null("Upgrades/MonitorUpgradeProp")
	if desk_plant and monitor:
		var dist = desk_plant.transform.origin.distance_to(monitor.transform.origin)
		passed = assert_true(dist > 0.8, "Studio DeskPlant is placed safely on the left (dist=%0.2fm from Monitor, ZERO clipping)" % dist) and passed
		
	# Verify Employee Workstation exists
	var emp_workstation = studio.get_node_or_null("EmployeeWorkstation")
	passed = assert_true(emp_workstation != null, "2nd Employee workstation node exists in Studio") and passed
	
	# Verify Server Rack interactable exists
	var rack_interact = studio.get_node_or_null("Upgrades/ServerRackUpgradeProp/RackInteractable")
	passed = assert_true(rack_interact != null, "Server Rack physical interactable exists in Studio") and passed
	
	var street = world_inst.get_node_or_null("Street")
	passed = assert_true(street != null, "Street district exists in game world") and passed
	
	# Verify TechShop and Cafe exist on the street
	var tech_shop = street.get_node_or_null("TechShopVenue")
	var cafe = street.get_node_or_null("CafeVenue")
	passed = assert_true(tech_shop != null, "TechShop (Elettronica TO) venue exists in street") and passed
	passed = assert_true(cafe != null, "Cafe (Caffè San Carlo) venue exists in street") and passed
	
	var pizzeria = world_inst.get_node_or_null("Pizzeria")
	passed = assert_true(pizzeria != null, "Pizzeria exists in game world") and passed
	
	# Verify doorway collision has clear passage:
	var space_state = player.get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(Vector3(0, 1.0, 1.0), Vector3(0, 1.0, 4.0))
	var result = space_state.intersect_ray(query)
	passed = assert_true(result.is_empty(), "Doorway at Z=2.6 to 3.4 is completely clear! Player can walk outside!") and passed
	
	# Verify street corridor
	var street_query = PhysicsRayQueryParameters3D.create(Vector3(0, 1.0, 4.0), Vector3(0, 1.0, 16.0))
	var street_result = space_state.intersect_ray(street_query)
	passed = assert_true(street_result.is_empty(), "Street corridor is unobstructed all the way to Pizzeria!") and passed
	
	world_inst.queue_free()
	return passed

func run_server_tier_and_overload_tests() -> bool:
	print("\n--- Running Server Rack Tiers & 3-Domain Overload Tests ---")
	var passed = true
	
	ServerRackManager.unlock_server_rack()
	ServerRackManager.rack_tier = 1
	ServerRackManager.active_incident = ""
	ServerRackManager.hosted_domains.clear()
	
	passed = assert_true(ServerRackManager.get_max_safe_domains() == 3, "Tier 1 starter rack has max 3 safe domains") and passed
	
	# Add exactly 3 domains
	ServerRackManager.add_hosted_client("client1.it", "Client 1", 30.0)
	ServerRackManager.add_hosted_client("client2.it", "Client 2", 30.0)
	ServerRackManager.add_hosted_client("client3.it", "Client 3", 30.0)
	
	ServerRackManager._on_time_tick(12, 0, 1)
	passed = assert_true(ServerRackManager.active_incident == "", "3 domains run safely on Tier 1 without overload") and passed
	
	# Add 4th domain -> triggers overload
	ServerRackManager.add_hosted_client("client4.it", "Client 4", 30.0)
	ServerRackManager._on_time_tick(12, 1, 1)
	passed = assert_true(ServerRackManager.active_incident == "overload_cacoso", "4th domain triggers 'overload_cacoso' on Tier 1 mini-rack") and passed
	passed = assert_true(ServerRackManager.status_health == "critical", "Status health critical when overloaded") and passed
	
	# Upgrade to Tier 2 (Blade 12U Enterprise)
	EconomyManager.balance = 1000.0
	var upgraded = ServerRackManager.upgrade_rack_tier(2)
	passed = assert_true(upgraded, "Successfully upgraded to Tier 2: Blade 12U Enterprise (€ 750)") and passed
	passed = assert_true(ServerRackManager.rack_tier == 2, "Rack Tier updated to 2") and passed
	passed = assert_true(ServerRackManager.get_max_safe_domains() == 8, "Tier 2 capacity increased to 8 safe domains") and passed
	passed = assert_true(ServerRackManager.active_incident == "", "Overload incident resolved by upgrading to Tier 2") and passed
	
	return passed

func run_ui_screen_containment_tests() -> bool:
	print("\n--- Running UI Screen Containment & Overflow Tests ---")
	var passed = true
	
	var cs_scene = load("res://scenes/ui/computer_screen.tscn")
	passed = assert_true(cs_scene != null, "computer_screen.tscn loads properly") and passed
	
	var cs = cs_scene.instantiate()
	add_child(cs)
	
	# Check Shop layout containment
	var shop_scroll = cs.get_node_or_null("Windows/ShopWindow/Margin/VBox/ShopScroll")
	passed = assert_true(shop_scroll != null, "ShopWindow contains ShopScroll (ScrollContainer)") and passed
	if shop_scroll:
		passed = assert_true(shop_scroll.horizontal_scroll_mode == 0, "Horizontal scroll is disabled (NO lateral overflow)") and passed
		var grid = shop_scroll.get_node_or_null("Grid")
		passed = assert_true(grid != null and grid.columns == 2, "Shop grid arranges cards in 2 columns") and passed
		
	# Check Rack upgrade buttons exist
	var tier2_btn = cs.get_node_or_null("Windows/RackWindow/Margin/VBox/Split/ModulesPanel/VBox/UpgradeTier2Btn")
	var tier3_btn = cs.get_node_or_null("Windows/RackWindow/Margin/VBox/Split/ModulesPanel/VBox/UpgradeTier3Btn")
	passed = assert_true(tier2_btn != null and tier3_btn != null, "RackWindow has Tier 2 and Tier 3 upgrade buttons") and passed
	
	# Check Firewall desktop icon exists
	var fw_icon = cs.get_node_or_null("DesktopIcons/VBox/FirewallIcon")
	passed = assert_true(fw_icon != null, "DesktopIcons contains NetShield Cyber Firewall button") and passed
	
	cs.queue_free()
	return passed

func run_firewall_routing_tests() -> bool:
	print("\n--- Running NetShield Firewall Circuit Routing Puzzle Tests ---")
	var passed = true
	
	var fw_scene = load("res://scenes/ui/minigames/firewall_router.tscn")
	passed = assert_true(fw_scene != null, "firewall_router.tscn loads properly") and passed
	
	var fw = fw_scene.instantiate()
	add_child(fw)
	
	passed = assert_true(fw.levels.size() == 3, "Firewall router has 3 client contracts (Studio Cavour, AutoTorino, TechLab)") and passed
	
	# Test Level 1: Studio Notarile Cavour
	fw._load_level(0)
	passed = assert_true(fw.active_path.size() == 1, "Level starts with Checkpoint 1 in path") and passed
	passed = assert_true(fw.next_required_checkpoint == 2, "Next required checkpoint is 2") and passed
	
	# Trace path: (0,0)->(0,1)->(0,2)->(0,3) [hits 2] -> (1,3)->(2,3)->(3,3) [hits 3] -> (3,2)->(3,1)->(3,0) [hits 4]
	var steps = [
		Vector2i(0, 1), Vector2i(0, 2), Vector2i(0, 3), # hits Checkpoint 2
		Vector2i(1, 3), Vector2i(2, 3), Vector2i(3, 3), # hits Checkpoint 3
		Vector2i(3, 2), Vector2i(3, 1), Vector2i(3, 0)  # hits Checkpoint 4
	]
	
	for s in steps:
		fw._on_cell_clicked(s)
		
	passed = assert_true(fw.is_level_completed, "Level 1 circuit completed successfully connecting 1->2->3->4 without crossing!") and passed
	passed = assert_true(not fw.deploy_btn.disabled, "Deploy button enabled upon circuit verification") and passed
	
	# Test non-crossing prevention: try clicking an already visited cell
	var prev_path_len = fw.active_path.size()
	fw.is_level_completed = false
	fw._on_cell_clicked(Vector2i(0, 1))
	passed = assert_true(fw.active_path.size() == prev_path_len, "Non-crossing rule prevents re-visiting already traversed cells") and passed
	
	fw.queue_free()
	return passed

func run_timed_compilation_tests() -> bool:
	print("\n--- Running WebForge Timed Compilation & Speed Boost Tests ---")
	var passed = true
	
	var wf_scene = load("res://scenes/ui/minigames/web_forge.tscn")
	passed = assert_true(wf_scene != null, "web_forge.tscn loads properly") and passed
	
	var wf = wf_scene.instantiate()
	add_child(wf)
	
	# Ensure story contract is accepted
	ContractManager.init_tutorial_contract()
	ContractManager.advance_tutorial_to_in_progress()
	
	wf._on_minigame_started("web_forge")
	
	# Verify checkboxes start UNCHECKED (not pre-selected)
	passed = assert_true(not wf.chk_header.button_pressed, "Header checkbox starts unchecked") and passed
	passed = assert_true(not wf.chk_hero.button_pressed, "Hero checkbox starts unchecked") and passed
	passed = assert_true(not wf.chk_menu.button_pressed, "Menu checkbox starts unchecked") and passed
	passed = assert_true(not wf.chk_hours.button_pressed, "Hours checkbox starts unchecked") and passed
	passed = assert_true(not wf.chk_booking.button_pressed, "Booking checkbox starts unchecked") and passed
	passed = assert_true(wf.compile_btn.disabled, "Compile button disabled when nothing is selected (0/5)") and passed
	
	# Check speed calculation on starter laptop
	GameManager.studio_upgrades_installed.clear()
	wf._calculate_compilation_speed()
	passed = assert_true(wf.compile_target_duration == 6.5, "Base compilation duration is 6.5s on starter laptop") and passed
	
	# Add monitor and employee boosts
	GameManager.studio_upgrades_installed.append("monitor_upgrade")
	EmployeeManager.hire_employee("emp_luca")
	wf._calculate_compilation_speed()
	passed = assert_true(wf.compile_target_duration < 3.0, "Compilation duration reduced to %0.1fs with Dual Monitor (-1.5s) and Luca Dev (-2.2s)" % wf.compile_target_duration) and passed
	
	# Clean up employee
	EmployeeManager.fire_employee("emp_luca")
	wf.queue_free()
	return passed
