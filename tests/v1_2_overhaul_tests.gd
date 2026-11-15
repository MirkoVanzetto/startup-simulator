extends Node
## v1.2.0 Comprehensive Overhaul Test Suite:
## Economy & Bills, Tier 2 Gate, SideJobs (4 Repeatables + Bacheche + 20 World Spots),
## Officina Bellini 3D Hologram Blueprints, WebForge 5.0 (DOM Reorder / Bento / KB Slider / Click-to-Patch AST),
## Parco Valentino & Mercato Nord Raycast Clearance, and 4-Resolution UI Containment.

const MainScene := preload("res://scenes/main.tscn")
const GameWorldScene := preload("res://scenes/world/game_world.tscn")
const WebForgeScene := preload("res://scenes/ui/minigames/web_forge.tscn")
const WorldMapMenuScene := preload("res://scenes/ui/world_map_menu.tscn")
const ComputerScreenScene := preload("res://scenes/ui/computer_screen.tscn")
const HudScene := preload("res://scenes/ui/hud.tscn")
const MapData := preload("res://scripts/world/world_map_data.gd")

const RESOLUTIONS := [
	Vector2(800, 600),
	Vector2(1024, 520),
	Vector2(1280, 720),
	Vector2(1920, 1080)
]

var passed_count: int = 0
var failed_count: int = 0

func _ready() -> void:
	await get_tree().process_frame
	print("======================================================================")
	print("=== v1.2.0 OVERHAUL SUITE: PACING, SIDEJOBS, WEBFORGE 5, HOLOGRAMS ===")
	print("======================================================================")

	test_economy_bills_and_tier2_gate()
	await test_side_jobs_bacheche_world_and_saveload()
	await test_factory_hologram_blueprints()
	await test_webforge_5_architecture_and_ast()
	await test_expanded_districts_clearance_and_ui_4res()

	print("======================================================================")
	print("  ✔ PASSED: %d" % passed_count)
	print("  ✘ FAILED: %d" % failed_count)
	print("======================================================================")
	get_tree().quit(0 if failed_count == 0 else 1)

func check(cond: bool, msg: String) -> void:
	if cond:
		passed_count += 1
		print("  ✔ [PASS] " + msg)
	else:
		failed_count += 1
		printerr("  ✘ [FAIL] " + msg)

# ------------------------------------------------------------------------------
# 1. ECONOMY PACING, DAILY BILLS (SOFTLOCK-SAFE) & TIER 2 GATE
# ------------------------------------------------------------------------------
func test_economy_bills_and_tier2_gate() -> void:
	print("\n[Suite 1] Economy Pacing (€120 Start), €48/day Bills (Softlock-Safe) & Tier 2 Gate")
	GameManager.start_new_game()
	check(is_equal_approx(EconomyManager.balance, 120.0), "New game starts with realistic tight capital € 120.00")
	check(GameManager.company_tier == 1, "New game starts at Tier 1")

	# Story contracts early rebalance
	var mario := ContractManager.get_contract("pizzeria_da_mario")
	check(is_equal_approx(float(mario.get("budget", 0.0)), 260.0) and int(mario.get("reputation_reward", 0)) == 12,
		"Pizzeria Da Mario rebalanced to € 260 (+12 Rep)")
	ContractManager.advance_tutorial_to_in_progress()
	ContractManager.complete_tutorial_contract()

	check(ContractManager.get_lead_interval_minutes() == 780,
		"Slow B2B lead cadence post-Mario without Davide/Luca = 780m (got %d)" % ContractManager.get_lead_interval_minutes())

	var elena := ContractManager.get_contract("caffe_san_carlo")
	check(is_equal_approx(float(elena.get("budget", 0.0)), 540.0) and int(elena.get("reputation_reward", 0)) == 20,
		"Caffe San Carlo rebalanced to € 540 (+20 Rep)")
	ContractManager.advance_contract_to_in_progress("caffe_san_carlo")
	ContractManager.complete_story_contract("caffe_san_carlo")

	var davide := ContractManager.get_contract("elettronica_to")
	check(is_equal_approx(float(davide.get("budget", 0.0)), 860.0) and int(davide.get("reputation_reward", 0)) == 28,
		"Elettronica TO rebalanced to € 860 (+28 Rep)")
	ContractManager.advance_contract_to_in_progress("elettronica_to")
	ContractManager.complete_story_contract("elettronica_to")

	check(ContractManager.get_lead_interval_minutes() == 420,
		"Slow B2B lead cadence post-Davide without Luca = 420m (got %d)" % ContractManager.get_lead_interval_minutes())

	# Daily overhead (€30 + €10 + €8 = €48)
	var overhead := CalendarSystem.DAILY_RENT + CalendarSystem.DAILY_UTILITIES + CalendarSystem.DAILY_INTERNET
	check(is_equal_approx(overhead, 48.0), "Daily overhead equals € 48.00 (€30 rent + €10 utilities + €8 fiber)")
	EconomyManager.balance = 200.0
	CalendarSystem._bill_daily_expenses()
	check(is_equal_approx(EconomyManager.balance, 152.0), "Full daily bills deduct € 48.00 (200 -> 152)")

	# Softlock-safe partial payment when cash < €48
	EconomyManager.balance = 15.0
	CalendarSystem._bill_daily_expenses()
	check(is_equal_approx(EconomyManager.balance, 0.0), "Partial daily bill drains to € 0.00 cleanly without negative balance")

	# Grace period at €0
	CalendarSystem._bill_daily_expenses()
	check(is_equal_approx(EconomyManager.balance, 0.0), "Zero cash day keeps € 0.00 cleanly (grace period)")

	# Tier 2 Expansion Gate (Rep >= 65, Cap >= 1800, Cost 950)
	EconomyManager.balance = 2000.0
	GameManager.reputation_points = 64
	check(not bool(GameManager.can_upgrade_company_tier().get("allowed", true)), "Tier 2 locked at 64 Rep (<65)")

	GameManager.reputation_points = 65
	EconomyManager.balance = 1799.0
	check(not bool(GameManager.can_upgrade_company_tier().get("allowed", true)), "Tier 2 locked at € 1,799 (<€ 1,800)")

	EconomyManager.balance = 1800.0
	var tier_chk: Dictionary = GameManager.can_upgrade_company_tier()
	check(bool(tier_chk.get("allowed", false)) and is_equal_approx(float(tier_chk.get("cost", 0.0)), 950.0),
		"Tier 2 unlocks cleanly at 65 Rep + € 1,800 Cap for cost € 950")
	check(GameManager.upgrade_company_tier(), "Upgraded company to Tier 2")
	check(GameManager.company_tier == 2 and is_equal_approx(EconomyManager.balance, 850.0),
		"Tier 2 deducts € 950 (1800 -> 850) and increments company_tier to 2")

	EmployeeManager.hire_employee("emp_luca")
	check(ContractManager.get_lead_interval_minutes() == 150,
		"Luca Scout active reduces B2B lead cadence to 150m (got %d)" % ContractManager.get_lead_interval_minutes())

# ------------------------------------------------------------------------------
# 2. SIDE JOBS (4 REPEATABLES, WORLD NODES, BONUSES, COOLDOWNS, COMPASS & SAVE)
# ------------------------------------------------------------------------------
func test_side_jobs_bacheche_world_and_saveload() -> void:
	print("\n[Suite 2] SideJobManager (4 Activities), Bacheche & 24 World Spots, Beacons & Save/Load")
	GameManager.start_new_game()
	var world := GameWorldScene.instantiate()
	add_child(world)
	await get_tree().physics_frame
	await get_tree().process_frame

	var sj_world := world.find_child("SideJobsWorld", true, false)
	check(sj_world != null, "SideJobsWorld container created inside BorgoStreet")
	var b1 := world.find_child("BachecaSanCarlo", true, false)
	var b2 := world.find_child("BachecaMercato", true, false)
	check(b1 != null and b2 != null, "Both BachecaSanCarlo & BachecaMercato interactables exist")
	check(SideJobManager.registered_spots.size() == 24,
		"All 24 SideSpot interactables registered in SideJobManager (got %d)" % SideJobManager.registered_spots.size())

	# Check all 24 beacons hidden initially
	var any_beacon_init := false
	for sid in SideJobManager.DEFAULT_SPOTS.keys():
		var spot := world.find_child("SideSpot_" + str(sid), true, false)
		if spot:
			var beacon := spot.get_node_or_null("Beacon") as Node3D
			if beacon and beacon.visible:
				any_beacon_init = true
	check(not any_beacon_init, "All 24 SideSpot Beacons hidden when no job active")

	# Test cancellation safety
	check(SideJobManager.start_job("volantinaggio"), "Started Volantinaggio Quartiere")
	check(SideJobManager.has_active_job(), "SideJobManager reports active job")
	check(str(GameManager.active_waypoint.get("id", "")).begins_with("sidejob_"),
		"Active SideJob automatically syncs GameManager.active_waypoint ('%s')" % str(GameManager.active_waypoint.get("id", "")))

	var cur_tid := SideJobManager.get_current_target_id()
	var cur_spot := world.find_child("SideSpot_" + cur_tid, true, false)
	var cur_beacon := cur_spot.get_node_or_null("Beacon") as Node3D if cur_spot else null
	check(cur_beacon != null and cur_beacon.visible, "Beacon enabled ONLY on current target spot '%s'" % cur_tid)

	SideJobManager.cancel_active_job()
	await get_tree().process_frame
	check(not SideJobManager.has_active_job() and GameManager.active_waypoint.is_empty(),
		"cancel_active_job() clears active_job and sidejob_* compass waypoint")
	check(cur_beacon != null and not cur_beacon.visible, "Beacon turns off immediately upon cancel")
	check(not SideJobManager.is_job_on_cooldown("volantinaggio"), "Cancelled SideJob applies zero cooldown penalty")

	# 1) Complete Volantinaggio (5 steps) + verify speed bonus + sneakers bonus + cooldown
	EconomyManager.balance = 500.0
	ShopManager.buy_gadget("elettronica_componenti", "gadget_scarpe_pro")
	var bal0 := EconomyManager.balance
	var rep0 := GameManager.reputation_points
	check(SideJobManager.start_job("volantinaggio"), "Re-started volantinaggio for full run")
	for step_i in range(5):
		var target := SideJobManager.get_current_target_id()
		check(target != "" and SideJobManager.can_interact_target(target), "Volantinaggio step %d target '%s' valid" % [step_i, target])
		if step_i == 4:
			SideJobManager._elapsed_active_sec = 45.0 # Fast run <= 180s
		check(SideJobManager.interact_target(target), "Completed volantinaggio step %d/5" % (step_i + 1))

	check(not SideJobManager.has_active_job(), "Volantinaggio clears active_job upon final step")
	check(is_equal_approx(EconomyManager.balance - bal0, 54.0),
		"Volantinaggio payout = 42 base + 6 speed bonus + 6 Sneakers = € 54.00 (got %.2f)" % (EconomyManager.balance - bal0))
	check(GameManager.reputation_points - rep0 == 4, "Volantinaggio awards +4 Rep")
	check(SideJobManager.get_cooldown_remaining_minutes("volantinaggio") == 90, "Volantinaggio triggers 90m cooldown")
	check(not SideJobManager.start_job("volantinaggio"), "Starting volantinaggio on cooldown is blocked")

	# 2) Complete Corriere Espresso (4 steps: pickup + 3 drops)
	bal0 = EconomyManager.balance
	NeedsManager.energy = 100.0
	check(SideJobManager.start_job("corriere_espresso"), "Started Corriere Espresso (4 steps)")
	check("Ritira" in SideJobManager.get_active_step_instruction(), "Corriere Espresso step 0 starts at food pickup")
	for step_i in range(4):
		if step_i == 3:
			SideJobManager._elapsed_active_sec = 60.0 # Fast <= 150s
		check(SideJobManager.interact_target(SideJobManager.get_current_target_id()), "Corriere step %d/4 done" % (step_i + 1))
	check(is_equal_approx(EconomyManager.balance - bal0, 72.0),
		"Corriere Espresso payout = 58 base + 14 speed bonus = € 72.00 (got %.2f)" % (EconomyManager.balance - bal0))

	# 3) Complete Ripristino Fibra (3 steps) with Scanner Wi-Fi 6 (+12 bonus)
	EconomyManager.balance = 1000.0
	ShopManager.buy_gadget("elettronica_componenti", "gadget_scanner_wifi")
	bal0 = EconomyManager.balance
	NeedsManager.energy = 100.0
	check(SideJobManager.start_job("riparazione_rapida"), "Started Ripristino Quadri Fibra (3 steps)")
	for step_i in range(3):
		if step_i == 2:
			SideJobManager._elapsed_active_sec = 60.0 # Fast <= 210s
		check(SideJobManager.interact_target(SideJobManager.get_current_target_id()), "Fibra step %d/3 done" % (step_i + 1))
	check(is_equal_approx(EconomyManager.balance - bal0, 94.0),
		"Riparazione Fibra payout = 72 base + 10 speed + 12 Scanner Wi-Fi = € 94.00 (got %.2f)" % (EconomyManager.balance - bal0))

	# 4) Complete Logistica Merci (4 steps: hub->drop, hub->drop)
	bal0 = EconomyManager.balance
	NeedsManager.energy = 100.0
	check(SideJobManager.start_job("logistica_merci"), "Started Scarico Merci & Logistica (4 steps)")
	check("Preleva" in SideJobManager.get_active_step_instruction(), "Logistica step 0 instructs pickup")
	SideJobManager.interact_target(SideJobManager.get_current_target_id())
	check("Scarica" in SideJobManager.get_active_step_instruction(), "Logistica step 1 instructs dropoff")
	SideJobManager.interact_target(SideJobManager.get_current_target_id())
	SideJobManager.interact_target(SideJobManager.get_current_target_id())
	SideJobManager._elapsed_active_sec = 80.0 # Fast <= 190s
	SideJobManager.interact_target(SideJobManager.get_current_target_id())
	check(is_equal_approx(EconomyManager.balance - bal0, 80.0),
		"Logistica payout = 68 base + 12 speed bonus = € 80.00 (got %.2f)" % (EconomyManager.balance - bal0))
	check(SideJobManager.get_completed_total() == 4, "Completed total SideJobs = 4")

	# 5) Save/Load roundtrip with active job & cooldowns
	SideJobManager.cooldowns_until["volantinaggio"] = 99999 # Preserve explicit cooldown integer
	CalendarSystem.current_day = 2 # Reset cooldown only if past 90m -> start logistica again after clearing its cooldown
	SideJobManager.cooldowns_until.erase("logistica_merci")
	NeedsManager.energy = 90.0
	check(SideJobManager.start_job("logistica_merci"), "Started active SideJob prior to save")
	SideJobManager.interact_target(SideJobManager.get_current_target_id()) # advance to step 1
	var saved_tid := SideJobManager.get_current_target_id()
	var saved_earned := SideJobManager.total_earned
	check(SaveManager.save_game(), "Saved game with active SideJob step 1 and cooldowns")

	SideJobManager.reset()
	check(not SideJobManager.has_active_job() and SideJobManager.get_completed_total() == 0,
		"SideJobManager wiped clean before Load test")

	check(SaveManager.load_game(), "Loaded game state")
	check(SideJobManager.has_active_job() and str(SideJobManager.active_job.get("id", "")) == "logistica_merci",
		"SideJob active_job id restored across Save/Load")
	check(int(SideJobManager.active_job.get("step", -1)) == 1 and SideJobManager.get_current_target_id() == saved_tid,
		"SideJob step=1 and current target restored across Save/Load")
	check(is_equal_approx(SideJobManager.total_earned, saved_earned) and SideJobManager.get_completed_total() == 4,
		"SideJob total_earned & completed_counts restored faithfully")

	world.queue_free()
	await get_tree().process_frame

# ------------------------------------------------------------------------------
# 3. OFFICINA BELLINI 3D HOLOGRAM BLUEPRINTS (LOCKED AMBER -> READY CYAN -> INSTALLED)
# ------------------------------------------------------------------------------
func test_factory_hologram_blueprints() -> void:
	print("\n[Suite 3] Officina Bellini 3D Holograms (Amber Locked -> Cyan Ready -> Solid Hardware)")
	GameManager.start_new_game()
	EconomyManager.balance = 5000.0
	var world := GameWorldScene.instantiate()
	add_child(world)
	await get_tree().physics_frame
	await get_tree().process_frame

	var factory := world.find_child("FactoryVenue", true, false)
	check(factory != null, "FactoryVenue present in GameWorld")

	var g_wifi := factory.get_node_or_null("GhostWifi") as Node3D
	var g_srv := factory.get_node_or_null("GhostServer") as Node3D
	var g_pcs := factory.get_node_or_null("GhostPCs") as Node3D
	var i_wifi := factory.get_node_or_null("InstalledWifi") as Node3D
	var i_srv := factory.get_node_or_null("InstalledServer") as Node3D
	var i_pcs := factory.get_node_or_null("InstalledPCs") as Node3D

	check(g_wifi != null and g_srv != null and g_pcs != null, "GhostWifi, GhostServer, GhostPCs nodes created")
	check(i_wifi != null and i_srv != null and i_pcs != null, "InstalledWifi, InstalledServer, InstalledPCs nodes created")

	# Initial state before scouting: ghosts visible with Locked.visible=true, Ready.visible=false
	check(g_wifi.visible and (g_wifi.get_node("Locked") as Node3D).visible and not (g_wifi.get_node("Ready") as Node3D).visible,
		"GhostWifi starts visible in Locked (amber) state")
	check(g_srv.visible and (g_srv.get_node("Locked") as Node3D).visible and not (g_srv.get_node("Ready") as Node3D).visible,
		"GhostServer starts visible in Locked (amber) state")
	check(g_pcs.visible and (g_pcs.get_node("Locked") as Node3D).visible and not (g_pcs.get_node("Ready") as Node3D).visible,
		"GhostPCs starts visible in Locked (amber) state")
	check(not i_wifi.visible and not i_srv.visible and not i_pcs.visible,
		"All solid Installed hardware meshes hidden initially")

	# Scout 3 of 4 zones -> still Locked
	ContractManager.accept_factory_commission()
	for i in range(3):
		ContractManager.scout_factory_zone(ContractManager.FACTORY_SCOUT_ZONES[i], "Zone %d" % i)
	await get_tree().process_frame
	check((g_wifi.get_node("Locked") as Node3D).visible and not (g_wifi.get_node("Ready") as Node3D).visible,
		"After 3/4 scouting, GhostWifi remains Locked until 4/4")

	# Scout 4th zone -> Ready cyan holograms active!
	ContractManager.scout_factory_zone(ContractManager.FACTORY_SCOUT_ZONES[3], "Zone 4")
	await get_tree().process_frame
	check((g_wifi.get_node("Ready") as Node3D).visible and not (g_wifi.get_node("Locked") as Node3D).visible,
		"At 4/4 scouting, GhostWifi switches to Ready (cyan) blueprint")
	check((g_srv.get_node("Ready") as Node3D).visible and not (g_srv.get_node("Locked") as Node3D).visible,
		"At 4/4 scouting, GhostServer switches to Ready (cyan) blueprint")
	check((g_pcs.get_node("Ready") as Node3D).visible and not (g_pcs.get_node("Locked") as Node3D).visible,
		"At 4/4 scouting, GhostPCs switches to Ready (cyan) blueprint")

	# Buy & install hardware -> respective Ghost hides and solid Installed mesh appears!
	ShopManager.buy_hardware("hw_wifi_router", 1)
	ShopManager.buy_hardware("hw_server_tower", 1)
	ShopManager.buy_hardware("hw_workstation_pc", 2)

	check(ContractManager.mount_factory_wifi_hardware(), "Mounted Wi-Fi router on factory hologram")
	await get_tree().process_frame
	check(i_wifi.visible and not g_wifi.visible, "InstalledWifi visible and GhostWifi hidden after mounting Wi-Fi")
	check(g_srv.visible and g_pcs.visible, "Uninstalled GhostServer & GhostPCs remain visible")

	check(ContractManager.install_factory_server(), "Installed Server Xeon on factory hologram")
	await get_tree().process_frame
	check(i_srv.visible and not g_srv.visible, "InstalledServer visible and GhostServer hidden after installing Server")

	check(ContractManager.install_factory_pcs(), "Installed 2x PC CAD on factory hologram")
	await get_tree().process_frame
	check(i_pcs.visible and not g_pcs.visible, "InstalledPCs visible and GhostPCs hidden after installing PCs")

	world.queue_free()
	await get_tree().process_frame

# ------------------------------------------------------------------------------
# 4. WEBFORGE 5.0 (DOM REORDER, LAYOUTS, MOBILE STACK, KB SLIDER & AST INSPECTOR)
# ------------------------------------------------------------------------------
func test_webforge_5_architecture_and_ast() -> void:
	print("\n[Suite 4] WebForge 5.0 Composer, Grid Layouts, Payload KB Slider & Click-to-Patch AST")
	GameManager.start_new_game()
	ContractManager.advance_tutorial_to_in_progress()
	EmployeeManager.hire_employee("emp_sara")

	var wf := WebForgeScene.instantiate()
	add_child(wf)
	await get_tree().process_frame
	EventBus.minigame_started.emit("web_forge")
	await get_tree().process_frame

	# 1. DOM reordering (move_block / clear_block / is_dom_order_valid)
	check(wf.block_order == ["header", "hero", "body", "widget", "footer"] and wf.is_dom_order_valid(),
		"WebForge 5 starts with valid 5-block DOM order")

	# Fill all 5 matching blocks for Mario + Terracotta palette
	wf._on_palette_selected(0) # terracotta
	wf._on_component_chosen("header", "header_mole")
	wf._on_component_chosen("hero", "hero_oven")
	wf._on_component_chosen("body", "body_pizza")
	wf._on_component_chosen("widget", "widget_booking")
	wf._on_component_chosen("footer", "footer_mario")
	await get_tree().process_frame

	var valid_audit: Dictionary = wf.calculate_lighthouse_score()
	wf.move_block("header", 1) # header drops to index 1 -> invalid DOM!
	check(not wf.is_dom_order_valid() and wf.block_order[0] == "hero" and wf.block_order[1] == "header",
		"move_block('header', +1) swaps blocks and marks DOM order invalid")
	var invalid_audit: Dictionary = wf.calculate_lighthouse_score()
	check(float(invalid_audit["accessibility"]) < float(valid_audit["accessibility"]),
		"Invalid DOM order penalizes Lighthouse A11y score (%.0f -> %.0f)" % [float(valid_audit["accessibility"]), float(invalid_audit["accessibility"])])
	wf.move_block("header", -1)
	check(wf.is_dom_order_valid(), "move_block('header', -1) restores valid DOM order")

	# Test clear_block
	wf.clear_block("widget")
	check(wf.slotted_components["widget"] == null and int(wf.calculate_lighthouse_score()["slots_filled"]) == 4 and wf.compile_btn.disabled,
		"clear_block empties slot, drops filled count to 4, and disables compile button")
	wf._on_component_chosen("widget", "widget_booking")

	# 2. Grid Architecture & Mobile stack
	wf.set_grid_layout_mode("bento")
	check(wf.grid_layout_mode == "bento", "Grid switcher accepts 'bento'")
	var b_audit: Dictionary = wf.calculate_lighthouse_score()
	check(not bool(b_audit["layout_match"]), "Mario brief flags 'bento' as layout mismatch")
	wf.set_grid_layout_mode("split")
	check(wf.grid_layout_mode == "split", "Grid switcher accepts 'split'")
	wf.set_grid_layout_mode("classic")
	check(wf.grid_layout_mode == "classic" and bool(wf.calculate_lighthouse_score()["layout_match"]),
		"Grid switcher 'classic' matches Mario's 1-Col Classic brief")

	# Toggle Bento + Mobile -> check Mobile phone shell text rendered in preview_vbox
	wf.set_grid_layout_mode("bento")
	wf.preview_mode = "mobile"
	wf._update_website_preview()
	await get_tree().process_frame
	var found_mob_shell: bool = wf.preview_vbox.find_children("*", "Label", true, false).any(
		func(l): return "Mobile Viewport" in (l as Label).text
	)
	check(found_mob_shell, "Mobile responsive toggle renders 390x844 Mobile Viewport 1-Col Stack inside Preview")
	wf.preview_mode = "desktop"
	wf.set_grid_layout_mode("classic")

	# 3. Payload KB Budget Slider effects (before/after debug patches)
	wf.budget_slider.value = 920.0
	await get_tree().process_frame
	check(float(wf.get_effective_payload_kb()) > 420.0, "Heavy 920KB unpatched media produces >420KB effective payload")
	var heavy_perf := float(wf.calculate_lighthouse_score()["performance"])

	wf.budget_slider.value = 140.0
	await get_tree().process_frame
	var lowres_a11y := float(wf.calculate_lighthouse_score()["accessibility"])
	check(lowres_a11y < float(valid_audit["accessibility"]),
		"Under-budgeting images (<200KB = 140KB) triggers Lighthouse A11y quality penalty")

	wf.budget_slider.value = 340.0 # sweet spot
	await get_tree().process_frame

	# 4. Click-to-Patch Code Inspector (CodeLinesVBox + AST click + Git Patches)
	wf._show_canvas_tab("debug")
	wf._select_debug_ticket(0)
	await get_tree().process_frame
	check(wf.code_lines_vbox.get_child_count() == 4, "CodeLinesVBox displays all 4 AST code lines")
	# Click clean line 0
	(wf.code_lines_vbox.get_child(0) as Button).pressed.emit()
	await get_tree().process_frame
	check(not wf.inspected_bug_line, "Clicking clean AST line does not falsely mark bug inspected")
	# Click buggy line 2 (index 2, line 03)
	(wf.code_lines_vbox.get_child(2) as Button).pressed.emit()
	await get_tree().process_frame
	check(wf.inspected_bug_line and "ISPEZIONATA" in (wf.code_lines_vbox.get_child(2) as Button).text,
		"Clicking buggy line 03 highlights AST line as ISPEZIONATA")

	# Wrong patch rejected
	(wf.fixes_vbox.get_child(1) as Button).pressed.emit()
	check(not wf.opt_minify, "Wrong Git Patch is rejected and keeps opt_minify false")
	# Correct patch accepted
	(wf.fixes_vbox.get_child(0) as Button).pressed.emit()
	check(wf.opt_minify, "Correct Git Patch #1 unlocks opt_minify")

	# Patch #2 (WebP - option 1 correct) & Patch #3 (Meta - option 2 correct)
	wf._select_debug_ticket(1)
	(wf.code_lines_vbox.get_child(2) as Button).pressed.emit()
	(wf.fixes_vbox.get_child(1) as Button).pressed.emit()
	check(wf.opt_webp, "Correct Git Patch #2 unlocks opt_webp")

	wf._select_debug_ticket(2)
	(wf.code_lines_vbox.get_child(1) as Button).pressed.emit()
	(wf.fixes_vbox.get_child(2) as Button).pressed.emit()
	check(wf.opt_meta, "Correct Git Patch #3 unlocks opt_meta")

	var final_audit: Dictionary = wf.calculate_lighthouse_score()
	check(float(final_audit["total"]) >= 95.0 and str(final_audit["grade"]) == "A+" and float(final_audit["performance"]) > heavy_perf,
		"Full matching Composer + Classic Grid + Optimal KB + 3 Git Patches hits >=95 Grade A+ (got %d %s)" % [int(final_audit["total"]), str(final_audit["grade"])])

	wf.queue_free()
	await get_tree().process_frame

# ------------------------------------------------------------------------------
# 5. PARCO VALENTINO & MERCATO NORD CORRIDORS + 4-RESOLUTION UI CONTAINMENT
# ------------------------------------------------------------------------------
func _ray_clear(space: PhysicsDirectSpaceState3D, from: Vector3, to: Vector3) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(from, to, 1)
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		return {"clear": true, "collider": ""}
	var cname := str(hit["collider"].name) if hit.has("collider") and hit["collider"] else "unknown"
	return {"clear": false, "collider": cname}

func test_expanded_districts_clearance_and_ui_4res() -> void:
	print("\n[Suite 5] Parco Valentino & Mercato Nord Raycast Clearance + 4-Res UI Containment")
	GameManager.start_new_game()
	EconomyManager.balance = 5000.0
	var world: Node3D = GameWorldScene.instantiate() as Node3D
	add_child(world)
	await get_tree().physics_frame
	await get_tree().physics_frame

	var space: PhysicsDirectSpaceState3D = world.get_world_3d().direct_space_state
	var corridors := [
		{"name": "Parco Valentino West Archway (-12,1,36.8 -> -36,1,36.8)", "from": Vector3(-12.0, 1.0, 36.8), "to": Vector3(-36.0, 1.0, 36.8)},
		{"name": "Parco Valentino Villa Promenade (-37.5,1,36.8 -> -37.5,1,20.0)", "from": Vector3(-37.5, 1.0, 36.8), "to": Vector3(-37.5, 1.0, 20.0)},
		{"name": "Parco Pond East Dock Approach (-37.5,1,26.8 -> -41.5,1,26.8)", "from": Vector3(-37.5, 1.0, 26.8), "to": Vector3(-41.5, 1.0, 26.8)},
		{"name": "Valdocco -> Mercato Nord Gate (79.0,1,24.0 -> 79.0,1,2.0)", "from": Vector3(79.0, 1.0, 24.0), "to": Vector3(79.0, 1.0, 2.0)},
		{"name": "Mercato Nord Lateral Plaza (69.5,1,2.0 -> 86.0,1,2.0)", "from": Vector3(69.5, 1.0, 2.0), "to": Vector3(86.0, 1.0, 2.0)}
	]
	for cor in corridors:
		var r := _ray_clear(space, cor["from"], cor["to"])
		check(bool(r["clear"]), "Corridor clear: %s%s" % [cor["name"], "" if bool(r["clear"]) else " (hit: %s)" % r["collider"]])

	world.queue_free()
	await get_tree().process_frame

	# Multi-Resolution UI containment checks for HUD (with SideJobPanel + WaypointPanel active),
	# WorldMapMenu (all 5 district views), WebForge 5.0 (Preview Bento + Debug AST), ComputerScreen (Freelance Hub)
	ContractManager.advance_tutorial_to_in_progress()
	ContractManager.accept_factory_commission()
	ContractManager.discover_new_lead(false)
	SideJobManager.start_job("volantinaggio")

	for res in RESOLUTIONS:
		var vp := SubViewport.new()
		vp.size = Vector2i(int(res.x), int(res.y))
		add_child(vp)

		# A) HUD with active SideJobPanel + WaypointPanel + rapid toasts
		var hud: Control = HudScene.instantiate()
		vp.add_child(hud)
		hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		hud.visible = true
		for ti in range(6):
			hud._on_notification_posted("Notifica #%d" % (ti + 1), "Messaggio verifica SideJobPanel & Waypoint su viewport %dx%d." % [int(res.x), int(res.y)], "info")
		hud._update_waypoint_tracker()
		hud._update_side_job_panel()
		hud._update_hints_label()
		await get_tree().process_frame
		await get_tree().process_frame

		check(hud.side_job_panel.visible and hud.waypoint_panel.visible,
			"HUD SideJobPanel & WaypointPanel both visible during active SideJob at %dx%d" % [int(res.x), int(res.y)])
		var hud_off: Array[String] = []
		_walk_ui_bounds(hud, Vector2.ZERO, res, hud_off)
		check(hud_off.is_empty(), "HUD + SideJobPanel strictly contained at %dx%d (%s)" % [int(res.x), int(res.y), ", ".join(hud_off)])

		var obj_r: Rect2 = hud.get_node("TopLeft/TopLeftVBox/ObjectivePanel").get_global_rect()
		var wp_r: Rect2 = hud.waypoint_panel.get_global_rect()
		var sj_r: Rect2 = hud.side_job_panel.get_global_rect()
		var toast_r: Rect2 = hud.toast_container.get_global_rect()
		var hints_r: Rect2 = hud.get_node("BottomRight/HintsPanel").get_global_rect()
		check(not obj_r.intersects(sj_r) and not wp_r.intersects(sj_r),
			"HUD SideJobPanel never overlaps ObjectivePanel or WaypointPanel at %dx%d (obj=%s wp=%s sj=%s)" % [int(res.x), int(res.y), str(obj_r), str(wp_r), str(sj_r)])
		check(not sj_r.intersects(toast_r) and not toast_r.intersects(hints_r),
			"HUD SideJobPanel & HintsPanel never overlap BottomLeft ToastContainer at %dx%d (sj=%s toast=%s hints=%s)" % [int(res.x), int(res.y), str(sj_r), str(toast_r), str(hints_r)])
		hud.queue_free()
		await get_tree().process_frame

		# B) WorldMapMenu across all 5 district filter tabs
		var wmap: Control = WorldMapMenuScene.instantiate()
		vp.add_child(wmap)
		wmap.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		wmap.visible = true
		wmap.open_map()
		await get_tree().process_frame
		for vid in ["all", "parco", "sancarlo", "valdocco", "mercato", "borgopo"]:
			wmap._set_view(vid)
			await get_tree().process_frame
			var wm_off: Array[String] = []
			_walk_ui_bounds(wmap, Vector2.ZERO, res, wm_off)
			check(wm_off.is_empty(), "WorldMapMenu view '%s' strictly contained at %dx%d" % [vid, int(res.x), int(res.y)])
		wmap.queue_free()
		await get_tree().process_frame

		# C) WebForge 5.0 (Bento Desktop + AST Code Inspector)
		var wf: Control = WebForgeScene.instantiate()
		vp.add_child(wf)
		wf.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		EventBus.minigame_started.emit("web_forge")
		await get_tree().process_frame
		wf.set_grid_layout_mode("bento")
		wf._on_component_chosen("header", "header_officina")
		wf._on_component_chosen("hero", "hero_officina")
		wf._on_component_chosen("body", "body_officina")
		wf._on_component_chosen("widget", "widget_officina")
		wf._on_component_chosen("footer", "footer_officina")
		await get_tree().process_frame
		var wf_off: Array[String] = []
		_walk_ui_bounds(wf, Vector2.ZERO, res, wf_off)
		check(wf_off.is_empty(), "WebForge 5.0 Bento Preview strictly contained at %dx%d (%s)" % [int(res.x), int(res.y), ", ".join(wf_off)])

		wf._show_canvas_tab("debug")
		await get_tree().process_frame
		var wf_dbg_off: Array[String] = []
		_walk_ui_bounds(wf, Vector2.ZERO, res, wf_dbg_off)
		check(wf_dbg_off.is_empty(), "WebForge 5.0 AST Code Inspector strictly contained at %dx%d (%s)" % [int(res.x), int(res.y), ", ".join(wf_dbg_off)])
		wf.queue_free()
		await get_tree().process_frame

		# D) ComputerScreen Freelance Hub
		var comp: Control = ComputerScreenScene.instantiate()
		vp.add_child(comp)
		comp.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		EventBus.computer_opened.emit()
		comp._open_window(comp.freelance_window)
		await get_tree().process_frame
		await get_tree().process_frame
		var comp_off: Array[String] = []
		_walk_ui_bounds(comp, Vector2.ZERO, res, comp_off)
		check(comp_off.is_empty(), "ComputerScreen Freelance Hub strictly contained at %dx%d (%s)" % [int(res.x), int(res.y), ", ".join(comp_off)])
		comp.queue_free()
		await get_tree().process_frame

		vp.queue_free()
		await get_tree().process_frame

func _walk_ui_bounds(node: Node, sc_x_bounds: Vector2, vp_size: Vector2, offenders: Array[String]) -> void:
	if node is Control and not node.visible:
		return
	if node is ScrollContainer:
		var sc := node as ScrollContainer
		var sr := sc.get_global_rect()
		if sr.position.x < -1.5 or sr.end.x > vp_size.x + 1.5 or sr.position.y < -1.5 or sr.end.y > vp_size.y + 1.5:
			offenders.append("Scroll:%s(%.0f..%.0f, %.0f..%.0f)" % [sc.name, sr.position.x, sr.end.x, sr.position.y, sr.end.y])
		var x_bounds := Vector2(sr.position.x, sr.end.x)
		for ch in sc.get_children():
			_walk_ui_bounds(ch, x_bounds, vp_size, offenders)
		return
	if node is Control:
		var c := node as Control
		var r := c.get_global_rect()
		if sc_x_bounds.y > 0.0:
			if r.position.x < sc_x_bounds.x - 1.5 or r.end.x > sc_x_bounds.y + 1.5:
				offenders.append("HClip:%s(%.0f..%.0f vs %.0f..%.0f)" % [c.name, r.position.x, r.end.x, sc_x_bounds.x, sc_x_bounds.y])
		else:
			if r.position.x < -1.5 or r.end.x > vp_size.x + 1.5 or r.position.y < -1.5 or r.end.y > vp_size.y + 1.5:
				offenders.append("%s(%.0f..%.0f, %.0f..%.0f)" % [c.name, r.position.x, r.end.x, r.position.y, r.end.y])
	for ch in node.get_children():
		_walk_ui_bounds(ch, sc_x_bounds, vp_size, offenders)
