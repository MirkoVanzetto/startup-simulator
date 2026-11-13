extends Node
## v1.0.0 Comprehensive Test Suite:
## Covers paced B2B leads, employee roles (Luca & Sara), Hardware Shop (-20% Davide discount),
## WebForge 4.0 (spoiler-free brief, debug tickets, responsive mobile preview, genuine build timer),
## NetShield dynamic levels, Borgo Valdocco + Officina Bellini 3D expansion & E2E appalto,
## JSON Vector2i save/load roundtrip, and multi-resolution UI containment.

const GameWorldScene = preload("res://scenes/world/game_world.tscn")
const ComputerScreenScene = preload("res://scenes/ui/computer_screen.tscn")
const WebForgeScene = preload("res://scenes/ui/minigames/web_forge.tscn")
const FirewallScene = preload("res://scenes/ui/minigames/firewall_router.tscn")
const ContractGenerator = preload("res://scripts/contracts/contract_generator.gd")

var passed_count: int = 0
var failed_count: int = 0

func _ready() -> void:
	await get_tree().process_frame
	print("======================================================================")
	print("=== v1.0.0 EXPANSION TEST SUITE (BORGO VALDOCCO & WEBFORGE 4.0) ===")
	print("======================================================================")

	test_paced_leads_and_luca_role()
	test_hardware_shop_and_b2b_delivery()
	await test_sara_role_webforge_and_rack()
	await test_webforge_v4_reinvention()
	await test_freelance_hub_and_netshield()
	await test_world_expansion_and_officina_bellini()
	await test_save_load_v1_roundtrip()
	await test_ui_containment_v1()

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
# 1. PACED LEADS & LUCA VIANELLO (CLIENT SCOUT) ROLE
# ------------------------------------------------------------------------------
func test_paced_leads_and_luca_role() -> void:
	print("\n[Suite 1] Paced Periodic Leads & Luca Vianello Scout Role")
	GameManager.start_new_game()

	check(ContractManager.marketplace_contracts.is_empty(), "Day 1 starts with 0 Freelance Hub marketplace leads")
	check(ContractManager.get_max_marketplace_pool() == 0, "Pre-Mario marketplace cap is 0")
	check(ContractManager.get_lead_interval_minutes() == 0, "Pre-Mario lead timer interval is paused (0)")

	for _t in range(1000):
		ContractManager._on_time_tick(12, 0, 1)
	check(ContractManager.marketplace_contracts.is_empty(), "No random leads spawn before finishing Mario")

	ContractManager.advance_tutorial_to_in_progress()
	ContractManager.mark_tutorial_website_built({"quality": 95.0})
	ContractManager.complete_tutorial_contract()

	check(ContractManager.marketplace_contracts.size() == 1, "Finishing Mario spawns 1 starter B2B lead")
	check(ContractManager.get_max_marketplace_pool() == 2, "Post-Mario marketplace cap is 2")
	check(ContractManager.get_lead_interval_minutes() == 720, "Post-Mario pre-Davide lead interval is 720m (12h)")

	for _t in range(720):
		ContractManager._on_time_tick(14, 0, 1)
	check(ContractManager.marketplace_contracts.size() == 2, "720 in-game ticks discover 2nd lead (cap 2)")

	for _t in range(900):
		ContractManager._on_time_tick(15, 0, 2)
	check(ContractManager.marketplace_contracts.size() == 2, "Paced pool respects cap 2 without flooding")

	# Complete Elena + Davide -> interval 360m, cap 3
	ContractManager.advance_contract_to_in_progress("caffe_san_carlo")
	ContractManager.complete_story_contract("caffe_san_carlo")
	ContractManager.advance_contract_to_in_progress("elettronica_to")
	ContractManager.complete_story_contract("elettronica_to")

	check(ContractManager.get_lead_interval_minutes() == 360, "Post-Davide interval improves to 360m (6h)")
	check(ContractManager.get_max_marketplace_pool() == 3, "Post-Davide marketplace cap improves to 3")
	ContractManager._on_day_passed(3)
	check(ContractManager.marketplace_contracts.size() == 3, "Day pass overnight discovery fills up to cap 3")

	# Hire Luca -> +2 immediate leads, 2h interval, cap 5, +15% budget
	GameManager.company_tier = 2
	GameManager.reputation_points = 80
	EconomyManager.balance = 3000.0
	var hired_luca := EmployeeManager.hire_employee("emp_luca")
	check(hired_luca, "Luca Vianello hired at Tier 2 with Rep >= 50")
	check(ContractManager.get_lead_interval_minutes() == 120, "Luca lowers lead interval to 120m (2h)")
	check(ContractManager.get_max_marketplace_pool() == 5, "Luca increases marketplace cap to 5")
	check(ContractManager.marketplace_contracts.size() == 5, "Hiring Luca immediately scouts +2 leads (3 -> 5)")

	var sample_std := ContractGenerator.generate_random_contract(42, 1.0)
	var sample_boost := ContractGenerator.generate_random_contract(42, 1.15)
	check(float(sample_boost["budget"]) >= float(sample_std["budget"]) * 1.10, "Luca +15%% budget multiplier increases generated B2B contract payout")

# ------------------------------------------------------------------------------
# 2. HARDWARE SHOP, DAVIDE -20% DISCOUNT & B2B HARDWARE DELIVERY
# ------------------------------------------------------------------------------
func test_hardware_shop_and_b2b_delivery() -> void:
	print("\n[Suite 2] Client Hardware Shop, Davide -20% Discount & B2B Delivery")
	GameManager.start_new_game()
	EconomyManager.balance = 50.0

	var p_pre := ShopManager.get_price("elettronica_componenti", "hw_server_tower")
	check(is_equal_approx(p_pre, 520.0), "Pre-Davide base Server Tower price is € 520.00 (got %.2f)" % p_pre)
	check(not ShopManager.buy_hardware("hw_server_tower", 1), "Insufficient funds rejects hardware purchase")
	check(ShopManager.get_hardware_count("hw_server_tower") == 0, "Stock remains 0 on failed hardware purchase")

	# Complete electronics shop quest to unlock Davide's permanent -20% discount
	ContractManager.advance_tutorial_to_in_progress()
	ContractManager.complete_tutorial_contract()
	ContractManager.advance_contract_to_in_progress("caffe_san_carlo")
	ContractManager.complete_story_contract("caffe_san_carlo")
	ContractManager.advance_contract_to_in_progress("elettronica_to")
	ContractManager.complete_story_contract("elettronica_to")

	var expected_mult := (1.0 - FameManager.get_discount()) * 0.80
	var p_post := ShopManager.get_price("elettronica_componenti", "hw_server_tower")
	check(is_equal_approx(p_post, snappedf(520.0 * expected_mult, 0.01)), "Post-Davide Server price includes -20%% partner discount (got %.2f)" % p_post)

	var p_pizza := ShopManager.get_price("pizzeria", "pizza_intera")
	check(is_equal_approx(p_pizza, snappedf(8.0 * (1.0 - FameManager.get_discount()), 0.01)), "Non-hardware shops do NOT get hardware partner discount")

	# Inject a B2B hardware contract and test accept -> fail missing stock -> buy -> deliver
	var hw_cid := "test_hw_b2b"
	ContractManager.marketplace_contracts.append({
		"id": hw_cid,
		"title": "Fornitura Server + Firewall B2B",
		"client": "Studio Test Torino",
		"category": "Hardware & Infrastruttura",
		"execution_type": "hardware",
		"required_hardware": {"hw_server_tower": 1, "hw_firewall_appliance": 1},
		"budget": 950.0,
		"reputation_reward": 20,
		"difficulty": 2,
		"deadline_days": 3,
		"status": "available",
		"requirements": ["1x Server Tower", "1x Firewall UTM"]
	})
	check(ContractManager.accept_marketplace_contract(hw_cid), "Accepted B2B hardware contract from marketplace")
	check(not ContractManager.deliver_hardware_contract(hw_cid), "Delivering hardware contract without stock fails cleanly")

	EconomyManager.balance = 5000.0
	check(ShopManager.buy_hardware("hw_server_tower", 1), "Bought 1x hw_server_tower")
	check(ShopManager.buy_hardware("hw_firewall_appliance", 1), "Bought 1x hw_firewall_appliance")
	var bal_before := EconomyManager.balance
	var rep_before := GameManager.reputation_points
	check(ContractManager.deliver_hardware_contract(hw_cid), "Delivering hardware contract succeeds with required stock")
	check(ShopManager.get_hardware_count("hw_server_tower") == 0 and ShopManager.get_hardware_count("hw_firewall_appliance") == 0, "Hardware stock consumed after delivery")
	check(ContractManager.is_contract_completed(hw_cid), "Hardware contract marked completed")
	check(EconomyManager.balance > bal_before and GameManager.reputation_points >= rep_before + 20, "Hardware B2B contract paid budget and awarded reputation")

# ------------------------------------------------------------------------------
# 3. SARA BELLINI (FULL-STACK & DEVOPS) ROLE: WEBFORGE + RACK
# ------------------------------------------------------------------------------
func test_sara_role_webforge_and_rack() -> void:
	print("\n[Suite 3] Sara Bellini Role: WebForge Build Speed, Hints & Rack Zero-Overheat")
	GameManager.start_new_game()
	ContractManager.advance_tutorial_to_in_progress()

	ServerRackManager.unlock_server_rack()
	ServerRackManager.rack_tier = 1
	ServerRackManager.hosted_domains.clear()
	ServerRackManager.add_hosted_client("a.it", "A", 40.0)
	ServerRackManager.add_hosted_client("b.it", "B", 60.0)
	var rev_base := ServerRackManager.calculate_daily_hosting_revenue()

	var wf := WebForgeScene.instantiate()
	add_child(wf)
	await get_tree().process_frame
	EventBus.minigame_started.emit("web_forge")
	await get_tree().process_frame

	var dur_no_sara: float = wf.compile_target_duration
	var brief_no_sara: String = wf.client_prefs.text
	var hint_vis_no_sara: bool = wf.sara_hint_label.visible
	check(is_equal_approx(dur_no_sara, 5.5), "Starter laptop WebForge compile time without Sara is 5.5s")
	check(not ("Nota Sara:" in brief_no_sara), "Brief hides Sara tip when Sara is not hired")
	check(not hint_vis_no_sara, "Debug Sara hint label is hidden when Sara is not hired")

	# Hire Sara (Tier 2+, Rep >= 100)
	GameManager.company_tier = 2
	GameManager.reputation_points = 120
	EconomyManager.balance = 1000.0
	check(EmployeeManager.hire_employee("emp_sara"), "Hired Sara Bellini at Tier 2 with Rep >= 100")

	EventBus.minigame_started.emit("web_forge")
	await get_tree().process_frame
	var dur_with_sara: float = wf.compile_target_duration
	check(is_equal_approx(dur_with_sara, 3.0), "Sara reduces WebForge compile duration by -2.5s (5.5s -> 3.0s)")
	check("Nota Sara:" in wf.client_prefs.text, "Sara adds component & palette guidance to WebForge brief")
	check(wf.sara_hint_label.visible, "Debug Sara hint label becomes visible when Sara is hired")

	var rev_sara := ServerRackManager.calculate_daily_hosting_revenue()
	check(is_equal_approx(rev_sara, rev_base * 1.35), "Sara increases daily Server Rack hosting revenue by +35%%")

	# Add overload domains & verify Sara prevents overheat / thermal_throttle
	ServerRackManager.add_hosted_client("c.it", "C", 40.0)
	ServerRackManager.add_hosted_client("d.it", "D", 40.0)
	ServerRackManager.add_hosted_client("e.it", "E", 40.0)
	for _i in range(12):
		ServerRackManager._on_time_tick(14, _i, 1)
	check(ServerRackManager.temperature_celsius <= 58.0, "Sara keeps rack temperature <= 58C under heavy load (got %.1fC)" % ServerRackManager.temperature_celsius)
	check(ServerRackManager.active_incident != "thermal_throttle" and ServerRackManager.active_incident != "overload_cacoso", "Sara prevents rack overheat incident under load")

	wf.queue_free()
	await get_tree().process_frame

# ------------------------------------------------------------------------------
# 4. WEBFORGE 4.0: SPOILER-FREE BRIEF, DEBUG TICKETS, MOBILE PREVIEW, TIMER
# ------------------------------------------------------------------------------
func test_webforge_v4_reinvention() -> void:
	print("\n[Suite 4] WebForge 4.0 Reinvention: Spoiler-Free UI, Debug Tickets, Responsive Preview & Timer")
	GameManager.start_new_game()
	ContractManager.accept_factory_commission()
	ContractManager.preferred_webforge_contract_id = "factory_bellini_web"

	var wf := WebForgeScene.instantiate()
	add_child(wf)
	await get_tree().process_frame
	EventBus.minigame_started.emit("web_forge")
	await get_tree().process_frame

	check(wf.active_contract_id == "factory_bellini_web", "WebForge opens selected contract (factory_bellini_web)")
	check(wf.current_palette_idx == 4, "WebForge starts on neutral Monochrome palette (idx 4), no auto-win theme")
	check(not ("[Match]" in wf.palette_affinity_badge.text), "Palette badge contains zero '[Match]' spoiler text")

	var found_spoiler := false
	for btn in wf.component_tray_vbox.get_children():
		if btn is Button and "[Match]" in btn.text:
			found_spoiler = true
	check(not found_spoiler, "Component buttons contain zero '[Match]' spoiler tags")

	# Verify opt shortcut buttons open Debug tab instead of auto-toggling booleans!
	wf._on_opt_minify_pressed()
	await get_tree().process_frame
	check(wf.debug_area.visible and not wf.opt_minify, "Clicking opt shortcut opens Code Debug ticket #1 rather than free checkmark")

	# Try wrong fix first -> rejected; then pick the correct fix for each of 3 tickets
	for tidx in range(3):
		wf._select_debug_ticket(tidx)
		await get_tree().process_frame
		var wrong_btn: Button = null
		var right_btn: Button = null
		var opts: Array = wf.DEBUG_TICKETS[tidx]["options"]
		var btns: Array = wf.fixes_vbox.get_children()
		for i in range(mini(opts.size(), btns.size())):
			if btns[i] is Button:
				if bool(opts[i]["correct"]):
					right_btn = btns[i]
				elif wrong_btn == null:
					wrong_btn = btns[i]
		if wrong_btn != null:
			wrong_btn.pressed.emit()
			await get_tree().process_frame
		check(not wf._is_ticket_solved(tidx), "Ticket #%d rejects wrong debug patch" % (tidx + 1))
		if right_btn != null:
			right_btn.pressed.emit()
			await get_tree().process_frame
		check(wf._is_ticket_solved(tidx), "Ticket #%d solved cleanly after choosing correct patch" % (tidx + 1))

	check(wf.opt_minify and wf.opt_webp and wf.opt_meta, "All 3 debug optimizations activated via Code Debug tickets")

	# Pick Amber industrial palette & Officina components + toggle Mobile preview
	wf._on_palette_selected(5)
	wf._on_component_chosen("header", "header_officina")
	wf._on_component_chosen("hero", "hero_officina")
	wf._on_component_chosen("body", "body_officina")
	wf._on_component_chosen("widget", "widget_officina")
	wf._on_component_chosen("footer", "footer_officina")
	wf.preview_mode = "mobile"
	wf._update_website_preview()
	wf._show_canvas_tab("preview")
	await get_tree().process_frame

	var audit: Dictionary = wf.calculate_lighthouse_score()
	check(int(audit["total"]) == 100 and str(audit["grade"]) == "A+", "Officina Bellini Amber + Officina slots + 3 Debug patches = 100/100 (A+)")
	check(wf.preview_vbox.get_child_count() >= 2, "Mobile responsive wireframe rendered inside PreviewVBox")

	# Run real _process(delta) timer compilation
	wf._on_compile_pressed()
	check(wf.is_compiling and wf.terminal_area.visible, "Compile starts real timed build on Terminal tab")
	var steps := 0
	while wf.is_compiling and steps < 120:
		wf._process(0.1)
		steps += 1
	check(not wf.is_compiling and wf.is_build_completed, "Real _process timer finishes compilation cleanly")
	check(ContractManager.get_contract("factory_bellini_web").get("status") == "built", "Compilation marks contract as 'built'")

	var bal_pre := EconomyManager.balance
	wf._on_deliver_pressed()
	check(ContractManager.is_contract_completed("factory_bellini_web"), "Delivering WebForge build completes contract")
	check(bool(ContractManager.factory_state.get("web_done", false)), "Officina Bellini Web pillar marked done on delivery")
	check(EconomyManager.balance > bal_pre + 950.0, "Delivery paid base budget + Lighthouse 20%% tip")

	wf.queue_free()
	await get_tree().process_frame

# ------------------------------------------------------------------------------
# 5. FREELANCE HUB ACQUISITION & NETSHIELD DYNAMIC B2B LEVELS
# ------------------------------------------------------------------------------
func test_freelance_hub_and_netshield() -> void:
	print("\n[Suite 5] Interactive Freelance Hub Acquisition & NetShield Dynamic Levels")
	GameManager.start_new_game()
	EconomyManager.balance = 2000.0

	var ns_cid := "b2b_netshield_custom"
	ContractManager.marketplace_contracts.append({
		"id": ns_cid,
		"title": "Audit Firewall Perimetrale & DMZ",
		"client": "Torneria Mirafiori",
		"category": "Cybersecurity & Rete",
		"execution_type": "netshield",
		"netshield_checkpoints": {
			Vector2i(0, 0): 1,
			Vector2i(0, 2): 2,
			Vector2i(2, 2): 3
		},
		"budget": 1100.0,
		"reputation_reward": 25,
		"difficulty": 3,
		"deadline_days": 4,
		"status": "available",
		"requirements": ["Instradamento 1->2->3"]
	})

	var comp := ComputerScreenScene.instantiate()
	add_child(comp)
	await get_tree().process_frame
	EventBus.computer_opened.emit()
	comp._open_window(comp.freelance_window)
	await get_tree().process_frame

	# Find the Accept button generated on the marketplace card and click it!
	var accept_btn := _find_button_with_prefix(comp.freelance_cards, "✓ Accetta")
	check(accept_btn != null, "FreelanceWindow renders interactive '✓ Accetta' button for B2B marketplace offer")
	if accept_btn != null:
		accept_btn.pressed.emit()
		await get_tree().process_frame

	check(ContractManager.active_contracts.has(ns_cid), "Clicking Accept moves contract to active_contracts")
	var launch_ns_btn := _find_button_with_prefix(comp.freelance_cards, "🛡 Configura su NetShield")
	check(launch_ns_btn != null, "Accepted NetShield contract shows '🛡 Configura su NetShield Cyber' action button")

	var fw := FirewallScene.instantiate()
	add_child(fw)
	await get_tree().process_frame
	if launch_ns_btn != null:
		launch_ns_btn.pressed.emit()
	await get_tree().process_frame

	var loaded_lvl: Dictionary = fw.levels[fw.current_level_idx]
	check(str(loaded_lvl.get("contract_id", "")) == ns_cid, "NetShield opens the selected B2B NetShield contract automatically")
	check(int(loaded_lvl.get("max_checkpoint", 0)) == 3, "NetShield reads custom netshield_checkpoints max_checkpoint (3)")

	# Route path 1 (0,0) -> (0,1) -> 2 (0,2) -> (1,2) -> 3 (2,2)
	for pos in [Vector2i(0, 1), Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2)]:
		fw._on_cell_clicked(pos)
	check(fw.is_level_completed, "NetShield circuit 1->2->3 solved on custom topology")
	var bal_pre := EconomyManager.balance
	fw._on_deploy_pressed()
	check(ContractManager.is_contract_completed(ns_cid), "NetShield deploy completes active B2B contract")
	check(is_equal_approx(EconomyManager.balance - bal_pre, 1100.0), "NetShield paid full € 1.100 B2B payout")

	fw.queue_free()
	comp.queue_free()
	await get_tree().process_frame

func _find_button_with_prefix(root: Node, prefix: String) -> Button:
	for ch in root.get_children():
		if ch is Button and ch.text.begins_with(prefix):
			return ch
		var sub := _find_button_with_prefix(ch, prefix)
		if sub != null:
			return sub
	return null

# ------------------------------------------------------------------------------
# 6. 3D WORLD EXPANSION, CORRIDORS & FULL OFFICINA BELLINI PIPELINE
# ------------------------------------------------------------------------------
func test_world_expansion_and_officina_bellini() -> void:
	print("\n[Suite 6] 3D Expansion (East Road, Valdocco) & Full Officina Bellini Appalto")
	GameManager.start_new_game()
	EconomyManager.balance = 5000.0
	GameManager.company_tier = 2
	GameManager.reputation_points = 50

	var world := GameWorldScene.instantiate()
	add_child(world)
	await get_tree().physics_frame
	await get_tree().physics_frame

	var street := world.find_child("Street", true, false)
	var tech_hw := world.find_child("TechHardwareShop", true, false)
	var factory := world.find_child("FactoryVenue", true, false)
	var bellini := world.find_child("BelliniNPC", true, false)
	var van := world.find_child("DeliveryVanValdocco", true, false)

	check(street != null, "Street district node loaded")
	check(tech_hw != null, "TechHardwareShop trigger exists inside Elettronica TO")
	check(factory != null, "FactoryVenue (Officina Bellini) exists at Borgo Valdocco")
	check(bellini != null, "BelliniNPC exists inside Officina Bellini")
	if bellini != null:
		check(bellini.find_child("BodyMesh", true, false) != null and bellini.find_child("HeadPivot", true, false) != null, "BelliniNPC uses sculpted VillageCharacters model")
	check(van != null, "DeliveryVanValdocco exists along East connecting road")

	# Physics corridor raycasts (collision_mask = 1)
	var space: PhysicsDirectSpaceState3D = world.get_world_3d().direct_space_state
	check(_ray_clear(space, Vector3(8.0, 1.0, 24.0), Vector3(24.0, 1.0, 28.0)), "Corridor clear: San Carlo Piazzetta -> East Archway Gate")
	check(_ray_clear(space, Vector3(24.0, 1.0, 28.0), Vector3(64.0, 1.0, 28.0)), "Corridor clear: East Gate -> Connecting Road -> Borgo Valdocco")
	check(_ray_clear(space, Vector3(64.0, 1.0, 27.5), Vector3(79.5, 1.0, 27.5)), "Corridor clear: Valdocco Square -> Officina Bellini entrance")
	check(_ray_clear(space, Vector3(78.5, 1.0, 27.5), Vector3(87.0, 1.0, 27.5)), "Corridor clear: Entering Officina Bellini doorway into main hall")

	var scout_names := ["ScoutZone_Ingresso", "ScoutZone_Magazzino", "ScoutZone_Ufficio", "ScoutZone_Vetrina"]
	var scouts: Array = []
	for sn in scout_names:
		var z = world.find_child(sn, true, false)
		scouts.append(z)
		check(z != null and (z.collision_layer & 2) != 0 and z.is_interactable, "Scout node %s active on layer 2" % sn)

	var st_wifi = world.find_child("InstallStation_Wifi", true, false)
	var st_srv = world.find_child("InstallStation_Server", true, false)
	var st_pcs = world.find_child("InstallStation_PCs", true, false)
	var vis_wifi = world.find_child("InstalledWifi", true, false) as Node3D
	var vis_srv = world.find_child("InstalledServer", true, false) as Node3D
	var vis_pcs = world.find_child("InstalledPCs", true, false) as Node3D
	check(st_wifi != null and st_srv != null and st_pcs != null, "All 3 hardware install stations exist inside Officina")
	check(vis_wifi != null and not vis_wifi.visible and vis_srv != null and not vis_srv.visible and vis_pcs != null and not vis_pcs.visible, "Installed 3D hardware meshes start invisible prior to installation")

	# Accept commission via ContractManager & verify pre-scout install lock
	ContractManager.accept_factory_commission()
	check(not ContractManager.mount_factory_wifi_hardware(), "Cannot mount Wi-Fi before scouting 4/4 factory zones")

	# Interact with all 4 ScoutZones in 3D scene
	for z in scouts:
		if z != null:
			z._on_interact(null)
	await get_tree().process_frame
	check(ContractManager.is_factory_all_scouted(), "Scouting all 4 3D ScoutZones completes factory scouting (4/4)")
	for z in scouts:
		if z != null:
			var b = z.get_node_or_null("Beacon") as Node3D
			check(not z.is_interactable and (b == null or not b.visible), "%s disables interaction & hides Beacon after scouting" % z.name)

	# Attempt server install before owning hardware -> rejected
	st_srv._on_interact(null)
	check(not bool(ContractManager.factory_state.get("server_done", false)), "Server install blocked when hw_server_tower not in stock")

	# Buy needed hardware components (1 Router, 1 Server, 2 PCs)
	check(ShopManager.buy_hardware("hw_wifi_router", 1), "Bought 1x Router Wi-Fi 6 for Officina")
	check(ShopManager.buy_hardware("hw_server_tower", 1), "Bought 1x Server Tower Xeon for Officina")
	check(ShopManager.buy_hardware("hw_workstation_pc", 2), "Bought 2x Workstation PC for Officina")

	# Mount Wi-Fi 6 hardware -> InstalledWifi visible, not done until NetShield
	st_wifi._on_interact(null)
	await get_tree().process_frame
	check(bool(ContractManager.factory_state.get("wifi_hardware_mounted", false)), "Wi-Fi router hardware mounted in factory")
	check(vis_wifi.visible and not bool(ContractManager.factory_state.get("wifi_done", false)), "3D InstalledWifi appears; Wi-Fi pillar awaits NetShield VLAN")

	# Complete VLAN via FirewallRouter
	var fw := FirewallScene.instantiate()
	add_child(fw)
	await get_tree().process_frame
	ContractManager.preferred_netshield_contract_id = "factory_bellini_wifi"
	EventBus.minigame_started.emit("firewall_router")
	await get_tree().process_frame
	var f_lvl: Dictionary = fw.levels[fw.current_level_idx]
	check(str(f_lvl.get("contract_id", "")) == "factory_bellini_wifi", "FirewallRouter exposes factory_bellini_wifi level after mounting router")
	# Path for factory_bellini_wifi: (0,0)=1 -> ... -> (0,3)=2 -> (2,3)=3 -> (2,1)=4 -> (4,1)=5 -> (4,4)=6
	var f_path := [
		Vector2i(0,1), Vector2i(0,2), Vector2i(0,3),
		Vector2i(1,3), Vector2i(2,3),
		Vector2i(2,2), Vector2i(2,1),
		Vector2i(3,1), Vector2i(4,1),
		Vector2i(4,2), Vector2i(4,3), Vector2i(4,4)
	]
	for p in f_path:
		fw._on_cell_clicked(p)
	check(fw.is_level_completed, "NetShield VLAN circuit for Officina Bellini completed")
	fw._on_deploy_pressed()
	check(bool(ContractManager.factory_state.get("wifi_done", false)), "NetShield deploy marks Officina Wi-Fi pillar complete")
	fw.queue_free()

	# Complete Web pillar (complete_marketplace_contract("factory_bellini_web"))
	ContractManager.complete_marketplace_contract("factory_bellini_web")
	check(bool(ContractManager.factory_state.get("web_done", false)), "Completing factory_bellini_web marks Web pillar complete")

	# Install Server & 2 PCs
	st_srv._on_interact(null)
	await get_tree().process_frame
	check(bool(ContractManager.factory_state.get("server_done", false)) and vis_srv.visible, "Server pillar complete and InstalledServer 3D mesh visible")

	var bal_pre_grand := EconomyManager.balance
	var rep_pre_grand := GameManager.reputation_points
	st_pcs._on_interact(null)
	await get_tree().process_frame
	check(bool(ContractManager.factory_state.get("pcs_done", false)) and vis_pcs.visible, "2x PCs pillar complete and InstalledPCs 3D mesh visible")

	# Verify Grand Completion bonus (+960 PCs +1500 bonus, +18+40 Rep)
	check(bool(ContractManager.factory_state.get("completed", false)), "Officina Bellini grand appalto marked completed")
	check(ContractManager.is_contract_completed("factory_bellini"), "factory_bellini added to completed_contracts")
	check(EconomyManager.balance >= bal_pre_grand + 960.0 + 1500.0 - 0.1, "Grand completion awarded both PC payout and € 1.500 final bonus")
	check(GameManager.reputation_points >= rep_pre_grand + 58, "Grand completion awarded +18 (PCs) and +40 grand Rep bonus")

	world.queue_free()
	await get_tree().process_frame

func _ray_clear(space: PhysicsDirectSpaceState3D, from_pt: Vector3, to_pt: Vector3) -> bool:
	var q := PhysicsRayQueryParameters3D.create(from_pt, to_pt, 1)
	var hit := space.intersect_ray(q)
	if not hit.is_empty():
		print("    [Ray hit] from=%s to=%s hit=%s collider=%s" % [str(from_pt), str(to_pt), str(hit.get("position")), str(hit.get("collider"))])
	return hit.is_empty()

# ------------------------------------------------------------------------------
# 7. SAVE/LOAD ROUNDTRIP + VECTOR2I RECOVERY FOR NETSHIELD
# ------------------------------------------------------------------------------
func test_save_load_v1_roundtrip() -> void:
	print("\n[Suite 7] Save/Load Roundtrip (Hardware Stock, Leads, Factory State, Vector2i Checkpoints)")
	GameManager.start_new_game()
	EconomyManager.balance = 4200.0
	GameManager.company_tier = 2
	GameManager.reputation_points = 75

	ShopManager.buy_hardware("hw_wifi_router", 2)
	ShopManager.buy_hardware("hw_workstation_pc", 3)
	EmployeeManager.hire_employee("emp_luca")
	ContractManager.accept_factory_commission()
	ContractManager.scout_factory_zone("scout_ingresso", "Ingresso")
	ContractManager.lead_timer_minutes = 88

	var ns_id := "saved_ns_test"
	ContractManager.active_contracts[ns_id] = {
		"id": ns_id,
		"title": "Saved NetShield Circuit",
		"client": "Saved Client",
		"category": "Cybersecurity & Rete",
		"execution_type": "netshield",
		"netshield_checkpoints": {Vector2i(0, 0): 1, Vector2i(0, 4): 2, Vector2i(4, 4): 3},
		"budget": 1200.0,
		"reputation_reward": 20,
		"status": "in_progress"
	}

	check(SaveManager.save_game(), "SaveManager.save_game() writes JSON successfully")
	# Scramble in-memory state before loading
	GameManager.start_new_game()
	check(ShopManager.get_hardware_count() == 0, "State reset before load verification")

	check(SaveManager.load_game(), "SaveManager.load_game() restores JSON successfully")
	check(ShopManager.get_hardware_count("hw_wifi_router") == 2 and ShopManager.get_hardware_count("hw_workstation_pc") == 3, "hardware_stock restored across save/load")
	check(ContractManager.lead_timer_minutes == 88, "lead_timer_minutes restored across save/load")
	check(EmployeeManager.is_employee_hired("emp_luca"), "hired_employee_ids restored across save/load")
	check(ContractManager.is_factory_zone_scouted("scout_ingresso"), "factory_state scouted zones restored across save/load")

	var loaded_ns: Dictionary = ContractManager.get_contract(ns_id)
	var cp: Dictionary = loaded_ns.get("netshield_checkpoints", {})
	var has_v2i := cp.has(Vector2i(0, 0)) and int(cp.get(Vector2i(4, 4), 0)) == 3
	check(has_v2i, "NetShield JSON string checkpoint keys normalized back into Vector2i keys")

# ------------------------------------------------------------------------------
# 8. MULTI-RESOLUTION UI CONTAINMENT (800x600, 1024x520, 1280x720)
# ------------------------------------------------------------------------------
func test_ui_containment_v1() -> void:
	print("\n[Suite 8] Multi-Resolution UI Containment (800x600, 1024x520, 1280x720)")
	GameManager.start_new_game()
	EconomyManager.balance = 5000.0
	ContractManager.advance_tutorial_to_in_progress()
	ContractManager.accept_factory_commission()
	ContractManager.discover_new_lead(false)

	var test_sizes: Array[Vector2i] = [Vector2i(800, 600), Vector2i(1024, 520), Vector2i(1280, 720)]

	for sz in test_sizes:
		var vp := SubViewport.new()
		vp.size = sz
		add_child(vp)

		var comp := ComputerScreenScene.instantiate() as Control
		vp.add_child(comp)
		comp.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

		var wf := WebForgeScene.instantiate() as Control
		vp.add_child(wf)
		wf.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		await get_tree().process_frame
		await get_tree().process_frame

		# ComputerScreen -> FreelanceWindow
		wf.visible = false
		EventBus.computer_opened.emit()
		comp._open_window(comp.freelance_window)
		await get_tree().process_frame
		check(_check_controls_in_bounds(comp, Vector2(sz)), "FreelanceWindow controls contained within %dx%d" % [sz.x, sz.y])

		# ComputerScreen -> ShopWindow (Studio + HwGrid)
		comp._open_window(comp.shop_window)
		await get_tree().process_frame
		check(_check_controls_in_bounds(comp, Vector2(sz)), "ShopWindow (Studio + Hardware Clienti) contained within %dx%d" % [sz.x, sz.y])

		# WebForge -> Preview (Mobile) & Debug
		comp.visible = false
		EventBus.minigame_started.emit("web_forge")
		wf.preview_mode = "mobile"
		wf._update_website_preview()
		wf._show_canvas_tab("preview")
		await get_tree().process_frame
		check(_check_controls_in_bounds(wf, Vector2(sz)), "WebForge Mobile Preview contained within %dx%d" % [sz.x, sz.y])

		wf._show_canvas_tab("debug")
		await get_tree().process_frame
		check(_check_controls_in_bounds(wf, Vector2(sz)), "WebForge Debug tab contained within %dx%d" % [sz.x, sz.y])

		comp.queue_free()
		wf.queue_free()
		vp.queue_free()
		await get_tree().process_frame

func _check_controls_in_bounds(root: Control, vp_size: Vector2) -> bool:
	var offenders: Array[String] = []
	_walk_control_bounds(root, Vector2.ZERO, vp_size, offenders)
	if not offenders.is_empty():
		print("    [Bounds Overflow] " + " | ".join(offenders))
	return offenders.is_empty()

func _walk_control_bounds(node: Node, sc_x_bounds: Vector2, vp_size: Vector2, offenders: Array[String]) -> void:
	if node is Control and not node.visible:
		return
	if node is ScrollContainer:
		var sc: ScrollContainer = node
		var sr := sc.get_global_rect()
		if sr.position.x < -1.0 or sr.end.x > vp_size.x + 1.0 or sr.position.y < -1.0 or sr.end.y > vp_size.y + 1.0:
			offenders.append("%s(%s)" % [sc.name, str(sr)])
		var child_x_bounds := Vector2(sr.position.x, sr.end.x)
		for ch in sc.get_children():
			_walk_control_bounds(ch, child_x_bounds, vp_size, offenders)
		return
	if node is Control:
		var c: Control = node
		var r := c.get_global_rect()
		if sc_x_bounds.y > 0.0:
			if r.position.x < sc_x_bounds.x - 1.5 or r.end.x > sc_x_bounds.y + 1.5:
				offenders.append("%s_HClip(%.0f..%.0f vs %.0f..%.0f)" % [c.name, r.position.x, r.end.x, sc_x_bounds.x, sc_x_bounds.y])
		else:
			if r.position.x < -1.5 or r.end.x > vp_size.x + 1.5 or r.position.y < -1.5 or r.end.y > vp_size.y + 1.5:
				offenders.append("%s(%.0f..%.0f, %.0f..%.0f)" % [c.name, r.position.x, r.end.x, r.position.y, r.end.y])
	for ch in node.get_children():
		_walk_control_bounds(ch, sc_x_bounds, vp_size, offenders)
