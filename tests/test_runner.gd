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
	all_passed = run_vertical_slice_integration() and all_passed
	
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
	
	# Step 7: Final Save Verification
	SaveManager.save_game()
	passed = assert_true(SaveManager.has_save_file(), "9. Vertical slice progress saved successfully") and passed
	
	return passed
