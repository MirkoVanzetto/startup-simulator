extends Node
## TestRunner - Automated test harness for Startup Simulator

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
	passed = assert_true(EconomyManager.balance == bal_before - 38.0, "Daily overhead expenses (€ 38.00) deducted") and passed
	
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
	passed = assert_true(EconomyManager.balance == bal_before + c_budget, "Commissions reward (€ %0.2f) credited" % c_budget) and passed
	
	return passed

func run_vertical_slice_integration() -> bool:
	print("\n--- Running Vertical Slice Full Gameplay Integration ---")
	var passed = true
	
	# Step 1: Start New Game
	GameManager.start_new_game()
	passed = assert_true(EconomyManager.balance == 250.0, "1. New Game started with € 250.00") and passed
	passed = assert_true(GameManager.studio_upgrades_installed.is_empty(), "2. Upgrades empty at start") and passed
	
	# Step 2: Check Tutorial Mission
	var tut = ContractManager.get_tutorial_contract()
	passed = assert_true(tut.get("status") == "available", "3. Pizzeria mission discovered") and passed
	
	# Step 3: Speak with Mario (Accept contract)
	ContractManager.advance_tutorial_to_in_progress()
	passed = assert_true(ContractManager.get_tutorial_contract().get("status") == "in_progress", "4. Spoke with Mario: contract accepted") and passed
	
	# Step 4: WebForge Minigame Development
	var web_data = {
		"theme": "red",
		"quality": 100.0,
		"components": ["header", "hero", "menu", "hours", "booking"]
	}
	ContractManager.mark_tutorial_website_built(web_data)
	passed = assert_true(ContractManager.get_tutorial_contract().get("status") == "built", "5. WebForge website compiled") and passed
	
	# Step 5: Deliver & Receive Payment
	ContractManager.complete_tutorial_contract()
	passed = assert_true(EconomyManager.balance == 900.0, "6. Payment of € 650 received (Total balance: € 900.00)") and passed
	
	# Step 6: TorinoHardware Upgrade Purchase (Secondary Monitor 27" for € 350)
	var buy_monitor = EconomyManager.spend(350.0, "Acquisto Monitor 27\" Ultrawide")
	passed = assert_true(buy_monitor and EconomyManager.balance == 550.0, "7. Monitor purchased for € 350.00") and passed
	EventBus.item_purchased.emit("monitor_upgrade", 350.0)
	passed = assert_true("monitor_upgrade" in GameManager.studio_upgrades_installed, "8. Monitor upgrade registered in studio") and passed
	
	# Step 7: Plant Upgrade Purchase (€ 35.00)
	var buy_plant = EconomyManager.spend(35.0, "Acquisto Pianta Succulenta d'Arredo")
	passed = assert_true(buy_plant and EconomyManager.balance == 515.0, "9. Plant purchased for € 35.00") and passed
	EventBus.item_purchased.emit("plant_aloe", 35.0)
	passed = assert_true("plant_aloe" in GameManager.studio_upgrades_installed, "10. Plant upgrade registered in studio") and passed
	
	# Step 8: Final Save Verification
	SaveManager.save_game()
	passed = assert_true(SaveManager.has_save_file(), "11. Vertical slice progress saved successfully") and passed
	
	return passed

func run_world_navigation_tests() -> bool:
	print("\n--- Running 3D World Navigation & Doorway Clearance Tests ---")
	var passed = true
	
	var world_scene = load("res://scenes/world/game_world.tscn")
	passed = assert_true(world_scene != null, "game_world.tscn loads properly") and passed
	
	var world_inst = world_scene.instantiate()
	add_child(world_inst)
	
	var player = world_inst.get_node_or_null("PlayerCharacter")
	passed = assert_true(player != null, "PlayerCharacter exists in game world") and passed
	
	var studio = world_inst.get_node_or_null("Studio")
	passed = assert_true(studio != null, "Studio exists in game world") and passed
	
	var street = world_inst.get_node_or_null("Street")
	passed = assert_true(street != null, "Street district exists in game world") and passed
	
	var pizzeria = world_inst.get_node_or_null("Pizzeria")
	passed = assert_true(pizzeria != null, "Pizzeria exists in game world") and passed
	
	# Verify doorway collision has clear passage:
	# Raycast from Studio interior (0, 1.0, 1.0) through doorway to street (0, 1.0, 4.0)
	var space_state = player.get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(Vector3(0, 1.0, 1.0), Vector3(0, 1.0, 4.0))
	var result = space_state.intersect_ray(query)
	passed = assert_true(result.is_empty(), "Doorway at Z=2.6 to 3.4 is completely clear! Player can walk outside!") and passed
	
	# Verify street passage from doorway (0, 1.0, 4.0) to Pizzeria entrance (0, 1.0, 16.0)
	var street_query = PhysicsRayQueryParameters3D.create(Vector3(0, 1.0, 4.0), Vector3(0, 1.0, 16.0))
	var street_result = space_state.intersect_ray(street_query)
	passed = assert_true(street_result.is_empty(), "Street corridor is unobstructed all the way to Pizzeria!") and passed
	
	world_inst.queue_free()
	return passed
