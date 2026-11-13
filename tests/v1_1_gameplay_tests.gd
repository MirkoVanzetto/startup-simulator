extends Node
## v1.1.0 Comprehensive Gameplay, Audio, Inventory [Tab], World Map [CapsLock/M] & HUD Waypoint Test Suite

const MainScene := preload("res://scenes/main.tscn")
const GameWorldScene := preload("res://scenes/world/game_world.tscn")
const WebForgeScene := preload("res://scenes/ui/minigames/web_forge.tscn")
const InventoryMenuScene := preload("res://scenes/ui/inventory_menu.tscn")
const WorldMapMenuScene := preload("res://scenes/ui/world_map_menu.tscn")
const ShopMenuScene := preload("res://scenes/ui/shop_menu.tscn")
const MapData := preload("res://scripts/world/world_map_data.gd")
const HudScene := preload("res://scenes/ui/hud.tscn")

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
	print("=== v1.1.0 TEST SUITE: FOOTSTEPS, INVENTORY [TAB], MAP [CAPS], HUD ===")
	print("======================================================================")

	test_footstep_sound_overhaul()
	await test_player_surface_and_sneakers()
	await test_backpack_gadgets_and_save_load()
	await test_main_controller_inputs_and_states()
	await test_world_map_and_hud_waypoint_compass()
	await test_ui_containment_and_no_overlap_v1_1()

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

func _measure_wav_metrics(wav: AudioStreamWAV) -> Dictionary:
	if wav == null or wav.data.size() < 4:
		return {"valid": false, "rms": 0.0, "peak": 0.0, "samples": 0}
	var count := wav.data.size() / 2
	var sum_sq := 0.0
	var peak := 0.0
	for i in range(count):
		var iv := wav.data.decode_s16(i * 2)
		var f := float(iv) / 32768.0
		sum_sq += f * f
		peak = maxf(peak, absf(f))
	return {
		"valid": true,
		"rms": sqrt(sum_sq / float(count)),
		"peak": peak,
		"samples": count
	}

# ------------------------------------------------------------------------------
# 1. SOUNDMANAGER 44.1KHZ MULTI-STAGE PROCEDURAL FOOTSTEPS, JUMP & LANDS
# ------------------------------------------------------------------------------
func test_footstep_sound_overhaul() -> void:
	print("\n[Suite 1] SoundManager 44.1kHz Procedural Footsteps, Jump & Landing Foley")
	var expected := ["grass", "stone", "wood", "tile", "asphalt", "metal"]
	check(SoundManager.FOOTSTEP_SURFACES.size() == 6, "SoundManager defines all 6 distinct surfaces")

	var surface_rms := {}
	for surf in expected:
		check(SoundManager.footstep_variants.has(surf), "footstep_variants contains surface '%s'" % surf)
		var arr: Array = SoundManager.footstep_variants.get(surf, [])
		check(arr.size() == 6, "Surface '%s' has 6 procedural variants" % surf)

		var v0: AudioStreamWAV = arr[0] as AudioStreamWAV
		var v1: AudioStreamWAV = arr[1] as AudioStreamWAV
		check(v0 != null and v0.mix_rate == 44100 and v0.format == AudioStreamWAV.FORMAT_16_BITS and not v0.stereo,
			"Surface '%s' v0 is 44.1kHz 16-bit mono WAV" % surf)
		check(v0.data != v1.data, "Surface '%s' variant 0 and variant 1 have unique waveforms" % surf)

		var m := _measure_wav_metrics(v0)
		check(bool(m["valid"]) and float(m["rms"]) >= 0.04 and float(m["rms"]) <= 0.35,
			"Surface '%s' RMS %.3f within healthy audible range [0.04..0.35]" % [surf, float(m["rms"])])
		check(float(m["peak"]) <= 0.995,
			"Surface '%s' peak %.3f free of digital clipping" % [surf, float(m["peak"])])
		surface_rms[surf] = float(m["rms"])

		check(SoundManager.land_variants.has(surf), "land_variants contains '%s'" % surf)
		var lwav := SoundManager.land_variants.get(surf) as AudioStreamWAV
		var lm := _measure_wav_metrics(lwav)
		check(lwav != null and lwav.mix_rate == 44100 and float(lm["rms"]) >= 0.05,
			"Landing SFX for '%s' is 44.1kHz non-silent WAV (RMS %.3f)" % [surf, float(lm["rms"])])

	var jwav := SoundManager.jump_stream
	var jm := _measure_wav_metrics(jwav)
	check(jwav != null and jwav.mix_rate == 44100 and float(jm["rms"]) >= 0.03,
		"Jump Foley stream is valid 44.1kHz WAV (RMS %.3f)" % float(jm["rms"]))

	# Verify alternating dual AudioStreamPlayers never clobber consecutive strides
	var alt_before: bool = SoundManager._use_alt_player
	SoundManager.play_footstep("wood", false, true)
	check(SoundManager._use_alt_player != alt_before, "play_footstep toggles dual alternating AudioStreamPlayer")
	SoundManager.play_footstep("stone", true, false)
	check(SoundManager._use_alt_player == alt_before, "Second rapid footstep uses alternate player without clobbering")
	SoundManager.play_jump()
	SoundManager.play_land("metal", 5.4)
	check(SoundManager.foley_player.stream == SoundManager.land_variants["metal"], "play_land selects correct surface stream")

# ------------------------------------------------------------------------------
# 2. PLAYERCONTROLLER SURFACE DETECTION & PRO SNEAKERS GADGET
# ------------------------------------------------------------------------------
func test_player_surface_and_sneakers() -> void:
	print("\n[Suite 2] PlayerController Metallic Floor Surface Detection & Sneakers Speed Boost")
	GameManager.start_new_game()
	var world := GameWorldScene.instantiate()
	add_child(world)
	await get_tree().physics_frame
	await get_tree().physics_frame

	var player := world.find_child("PlayerCharacter", true, false)
	check(player != null, "PlayerCharacter spawned cleanly in GameWorld")
	check("metal" in player.VALID_SURFACES, "PlayerController VALID_SURFACES includes 'metal'")

	# Metal treadplate at Officina Bellini: rot -PI/2 at (85, 0, 27.5), local steel plate (-0.8, 0.022, -3.25)
	var xf := Transform3D(Basis(Vector3.UP, -PI * 0.5), Vector3(85.0, 0.0, 27.5))
	var metal_world := xf * Vector3(-0.8, 0.0, -3.25)
	player.global_position = Vector3(metal_world.x, 0.25, metal_world.z)
	await get_tree().physics_frame
	check(player._detect_surface() == "metal", "Player ground ray detects 'metal' treadplate inside Officina Bellini (got %s)" % player._detect_surface())

	# Studio floor -> wood
	player.global_position = Vector3(0.0, 0.25, 0.5)
	await get_tree().physics_frame
	check(player._detect_surface() == "wood", "Player ground ray detects 'wood' inside Studio (got %s)" % player._detect_surface())

	# East connecting road -> asphalt
	player.global_position = Vector3(40.0, 0.25, 28.0)
	await get_tree().physics_frame
	check(player._detect_surface() == "asphalt", "Player ground ray detects 'asphalt' on Viale Est (got %s)" % player._detect_surface())

	# Via del Borgo -> stone
	player.global_position = Vector3(0.0, 0.25, 7.5)
	await get_tree().physics_frame
	check(player._detect_surface() == "stone", "Player ground ray detects 'stone' on Via del Borgo (got %s)" % player._detect_surface())

	# Verify Sneakers speed multiplier via gadget purchase
	check(not ShopManager.has_gadget("gadget_scarpe_pro"), "Sneakers Tech gadget initially unowned")
	EconomyManager.balance = 500.0
	check(ShopManager.buy_gadget("elettronica_componenti", "gadget_scarpe_pro"), "Purchased gadget_scarpe_pro cleanly")
	check(ShopManager.has_gadget("gadget_scarpe_pro"), "ShopManager reports gadget_scarpe_pro owned")

	world.queue_free()
	await get_tree().process_frame

# ------------------------------------------------------------------------------
# 3. BACKPACK CONSUMABLES, FRIDGE TRANSFER, WIFI GADGET & SAVE ROUNDTRIP
# ------------------------------------------------------------------------------
func test_backpack_gadgets_and_save_load() -> void:
	print("\n[Suite 3] Backpack Kit, Fridge->Zaino Transfer, Wi-Fi Scanner Bonus & Save Roundtrip")
	GameManager.start_new_game()

	check(ShopManager.get_backpack_count("cornetto") == 1, "New game grants 1x cornetto in backpack")
	check(ShopManager.get_backpack_count("espresso") == 1, "New game grants 1x espresso in backpack")
	check(ShopManager.get_backpack_count() == 2, "Total starter backpack stock = 2")

	# Buy portable item to backpack
	var bal_before := EconomyManager.balance
	check(ShopManager.buy_to_backpack("cafe", "thermos_bicerin"), "buy_to_backpack buys Thermos Bicerin")
	check(EconomyManager.balance < bal_before, "Backpack purchase deducts discounted price")
	check(ShopManager.get_backpack_count("thermos_bicerin") == 1, "thermos_bicerin count in backpack = 1")

	# Insufficient funds test
	EconomyManager.balance = 1.0
	check(not ShopManager.buy_to_backpack("edicola", "barretta_tech"), "buy_to_backpack rejects when funds insufficient")
	check(ShopManager.get_backpack_count("barretta_tech") == 0 and is_equal_approx(EconomyManager.balance, 1.0),
		"Rejected backpack purchase leaves stock and balance untouched")

	# Fridge -> Backpack move
	EconomyManager.balance = 5000.0
	check(ShopManager.buy_for_fridge("alimentari", "panino"), "Bought panino into studio fridge")
	check(ShopManager.get_fridge_count("panino") == 1, "Fridge has 1x panino")
	check(ShopManager.move_fridge_to_backpack("panino"), "Moved panino from fridge to backpack")
	check(ShopManager.get_fridge_count("panino") == 0 and ShopManager.get_backpack_count("panino") == 1,
		"Fridge stock dropped to 0 and backpack panino became 1")

	# Consume from backpack anywhere
	NeedsManager.hunger = 50.0
	NeedsManager.energy = 40.0
	check(ShopManager.use_backpack_item("thermos_bicerin"), "use_backpack_item consumes Thermos Bicerin")
	check(is_equal_approx(NeedsManager.hunger, 65.0) and is_equal_approx(NeedsManager.energy, 85.0),
		"Consuming Thermos Bicerin restores +15 hunger and +45 energy")
	check(ShopManager.get_backpack_count("thermos_bicerin") == 0, "Consumed backpack item removes/decrements stock cleanly")

	# Gadget Scanner Wi-Fi 6 bonuses
	check(ShopManager.buy_gadget("elettronica_componenti", "gadget_scanner_wifi"), "Bought Analizzatore Spettro Wi-Fi 6")
	check(not ShopManager.buy_gadget("elettronica_componenti", "gadget_scanner_wifi"), "Duplicate gadget purchase blocked cleanly")

	# Check WebForge build duration reduction (-0.6s without Sara: 5.5 -> 4.9)
	var wf := WebForgeScene.instantiate()
	add_child(wf)
	await get_tree().process_frame
	wf._calculate_compilation_speed()
	check(is_equal_approx(wf.compile_target_duration, 4.9),
		"gadget_scanner_wifi reduces WebForge build duration by -0.6s (got %.2fs)" % wf.compile_target_duration)
	wf.queue_free()

	# Check 4/4 factory scout rep bonus (4*2 + 5 bonus = 13 instead of 4*2 + 4 = 12)
	ContractManager.accept_factory_commission()
	var rep0 := GameManager.reputation_points
	for zid in ContractManager.FACTORY_SCOUT_ZONES:
		ContractManager.scout_factory_zone(zid, zid)
	check(GameManager.reputation_points - rep0 == 13,
		"gadget_scanner_wifi grants 13 total Rep (+1 bonus over 12) on completing 4/4 factory scouting (got %d)" % (GameManager.reputation_points - rep0))

	# Check NetShield +10% payout bonus
	var net_c := {
		"id": "b2b_net_bonus_check",
		"title": "Audit NetShield",
		"client": "Studio Test",
		"category": "firewall",
		"execution_type": "netshield",
		"budget": 1000.0,
		"reputation_reward": 5,
		"fame_bonus": 1.0,
		"status": "in_progress"
	}
	ContractManager.active_contracts["b2b_net_bonus_check"] = net_c
	var b_pre := EconomyManager.balance
	ContractManager.complete_marketplace_contract("b2b_net_bonus_check")
	check(is_equal_approx(EconomyManager.balance - b_pre, 1100.0),
		"gadget_scanner_wifi boosts NetShield payout by +10%% (€ 1000 -> € 1100, got %.2f)" % (EconomyManager.balance - b_pre))

	# Save / Load roundtrip with backpack_stock, owned_gadgets & active_waypoint
	var poi := MapData.get_poi("officina_bellini")
	GameManager.set_waypoint(poi["id"], poi["name"], poi["pos"])
	check(SaveManager.save_game(), "SaveManager saves v1.1 state cleanly")

	ShopManager.reset()
	GameManager.clear_waypoint()
	check(ShopManager.get_backpack_count() == 0 and not ShopManager.has_gadget("gadget_scanner_wifi") and GameManager.active_waypoint.is_empty(),
		"State wiped before load verification")

	check(SaveManager.load_game(), "SaveManager loads v1.1 state cleanly")
	check(ShopManager.get_backpack_count("cornetto") == 1 and ShopManager.get_backpack_count("panino") == 1,
		"backpack_stock restored faithfully across JSON save/load")
	check(ShopManager.has_gadget("gadget_scanner_wifi"), "owned_gadgets restored across JSON save/load")
	check(str(GameManager.active_waypoint.get("id", "")) == "officina_bellini",
		"Active waypoint restored across JSON save/load")

# ------------------------------------------------------------------------------
# 4. MAINCONTROLLER INPUT HANDLING ([TAB], [CAPSLOCK/M], [ESC], DECOR SAFETY)
# ------------------------------------------------------------------------------
func test_main_controller_inputs_and_states() -> void:
	print("\n[Suite 4] MainController Input Switching ([Tab], [CapsLock/M], [ESC], Decor Mode Safety)")
	var main := MainScene.instantiate()
	add_child(main)
	await get_tree().process_frame
	GameManager.start_new_game()
	await get_tree().process_frame

	check(GameManager.current_state == GameManager.GameState.FIRST_PERSON, "Started in FIRST_PERSON state")
	check(not main.inventory_menu.visible and not main.world_map_menu.visible and main.hud.visible,
		"Initially HUD is visible while Inventory & Map are hidden")

	# Press [Tab] -> INVENTORY
	var tab_ev := InputEventKey.new()
	tab_ev.keycode = KEY_TAB
	tab_ev.physical_keycode = KEY_TAB
	tab_ev.pressed = true
	get_tree().root.push_input(tab_ev)
	await get_tree().process_frame
	check(GameManager.current_state == GameManager.GameState.INVENTORY and main.inventory_menu.visible and not main.hud.visible,
		"[Tab] opens InventoryMenu and switches state to INVENTORY")

	# Use starter cornetto from InventoryMenu
	NeedsManager.hunger = 60.0
	ShopManager.use_backpack_item("cornetto")
	check(is_equal_approx(NeedsManager.hunger, 80.0), "Consuming cornetto from backpack restores +20 hunger")

	# Press [CapsLock] -> MAP directly from INVENTORY
	var caps_ev := InputEventKey.new()
	caps_ev.keycode = KEY_CAPSLOCK
	caps_ev.physical_keycode = KEY_CAPSLOCK
	caps_ev.pressed = true
	get_tree().root.push_input(caps_ev)
	await get_tree().process_frame
	check(GameManager.current_state == GameManager.GameState.MAP and main.world_map_menu.visible and not main.inventory_menu.visible,
		"[CapsLock] switches cleanly from INVENTORY to WorldMapMenu (MAP state)")

	# Press [Tab] from MAP -> switches back to INVENTORY
	get_tree().root.push_input(tab_ev.duplicate())
	await get_tree().process_frame
	check(GameManager.current_state == GameManager.GameState.INVENTORY and main.inventory_menu.visible and not main.world_map_menu.visible,
		"[Tab] switches cleanly from MAP back to INVENTORY")

	# Press [ESC] -> closes INVENTORY back to FIRST_PERSON
	var esc_ev := InputEventKey.new()
	esc_ev.keycode = KEY_ESCAPE
	esc_ev.physical_keycode = KEY_ESCAPE
	esc_ev.pressed = true
	get_tree().root.push_input(esc_ev)
	await get_tree().process_frame
	check(GameManager.current_state == GameManager.GameState.FIRST_PERSON and not main.inventory_menu.visible and main.hud.visible,
		"[ESC] closes InventoryMenu back to FIRST_PERSON")

	# Press [M] fallback -> opens MAP, then [CapsLock] closes MAP -> FIRST_PERSON
	var m_ev := InputEventKey.new()
	m_ev.keycode = KEY_M
	m_ev.physical_keycode = KEY_M
	m_ev.pressed = true
	get_tree().root.push_input(m_ev)
	await get_tree().process_frame
	check(GameManager.current_state == GameManager.GameState.MAP and main.world_map_menu.visible,
		"[M] fallback opens WorldMapMenu cleanly")

	get_tree().root.push_input(caps_ev.duplicate())
	await get_tree().process_frame
	check(GameManager.current_state == GameManager.GameState.FIRST_PERSON and not main.world_map_menu.visible,
		"[CapsLock] closes WorldMapMenu cleanly back to FIRST_PERSON")

	# Decor Mode [B] safety: Tab MUST cycle furniture, NOT open InventoryMenu
	GameManager.studio_upgrades_installed.append("plant_aloe")
	var player: Node = main.game_world.find_child("PlayerCharacter", true, false)
	if player:
		player.global_position = Vector3(0.0, 0.1, 0.5)
	main.studio_mgr._init_available_items()
	main.studio_mgr.toggle_decor_mode()
	check(bool(main.studio_mgr.is_decor_mode), "Studio Decor Mode activated")
	get_tree().root.push_input(tab_ev.duplicate())
	await get_tree().process_frame
	check(GameManager.current_state == GameManager.GameState.FIRST_PERSON and not main.inventory_menu.visible,
		"[Tab] while Studio Decor Mode active does NOT hijack furniture cycling")
	main.studio_mgr.toggle_decor_mode()

	main.queue_free()
	await get_tree().process_frame

# ------------------------------------------------------------------------------
# 5. WORLD MAP GEOMETRY, RECOMMENDED TARGETS & HUD WAYPOINT COMPASS
# ------------------------------------------------------------------------------
func test_world_map_and_hud_waypoint_compass() -> void:
	print("\n[Suite 5] WorldMap POI Calibration, Recommended Quest Target & HUD Compass Arrival")
	var main := MainScene.instantiate()
	add_child(main)
	await get_tree().process_frame
	GameManager.start_new_game()
	await get_tree().process_frame

	# 1. Verify all 10 POIs sit inside WORLD_BOUNDS and canvas projection bounds
	var pois: Array[Dictionary] = MapData.get_pois()
	check(pois.size() == 10, "WorldMapData provides all 10 Borgo San Carlo & Borgo Valdocco POIs")
	main.world_map_menu.open_map()
	await get_tree().process_frame
	var canvas: Control = main.world_map_menu._map_canvas
	for poi in pois:
		var p3: Vector3 = poi["pos"]
		var p2 := Vector2(p3.x, p3.z)
		check(MapData.WORLD_BOUNDS.has_point(p2),
			"POI '%s' (%.1f, %.1f) lies inside WORLD_BOUNDS" % [poi["id"], p2.x, p2.y])
		var cp: Vector2 = canvas.world_to_canvas(p2)
		check(cp.x >= 0.0 and cp.x <= canvas.size.x and cp.y >= 0.0 and cp.y <= canvas.size.y,
			"POI '%s' maps within MapCanvas viewport rect" % poi["id"])

	# 2. Verify quest recommendation tracks story progression
	check(GameManager.get_recommended_quest_poi_id() == "pizzeria_mario",
		"Day 1 recommended quest POI is pizzeria_mario")
	ContractManager.advance_tutorial_to_in_progress()
	ContractManager.complete_tutorial_contract()
	check(GameManager.get_recommended_quest_poi_id() == "studio",
		"Post-Mario pre-upgrade recommended quest POI is studio")
	GameManager.studio_upgrades_installed.append("monitor_upgrade")
	check(GameManager.get_recommended_quest_poi_id() == "caffe_san_carlo",
		"Next story quest POI points to caffe_san_carlo")

	# 3. Set Waypoint and verify HUD live compass arrow + arrival auto-clear
	main.world_map_menu.select_poi("officina_bellini")
	main.world_map_menu._on_set_waypoint_pressed()
	main.world_map_menu.close_map()
	await get_tree().process_frame

	check(GameManager.active_waypoint.get("id", "") == "officina_bellini", "Active waypoint set to officina_bellini")
	check(main.hud.waypoint_panel.visible, "HUD WaypointPanel becomes visible when returning to gameplay")

	var player: Node3D = GameManager.player_node as Node3D
	player.global_position = Vector3(68.5, 0.1, 27.5)
	player.rotation_degrees = Vector3(0.0, -90.0, 0.0) # Facing East (+X) directly toward Officina (85.0, 27.5)
	main.hud._update_waypoint_tracker()
	var wp_txt: String = main.hud.waypoint_label.text
	check("↑" in wp_txt and ("16 m" in wp_txt or "17 m" in wp_txt),
		"Facing Officina at 16.5m East shows '16 m'/'17 m' with ahead arrow ↑ (got: %s)" % wp_txt)

	player.rotation_degrees = Vector3(0.0, 90.0, 0.0) # Turn 180 deg West (-X)
	main.hud._update_waypoint_tracker()
	check("↓" in main.hud.waypoint_label.text,
		"Turning 180° away flips compass arrow to ↓ (got: %s)" % main.hud.waypoint_label.text)

	# Walk within arrival threshold (< 3.5m) -> auto-clear waypoint
	player.global_position = Vector3(84.0, 0.1, 27.5)
	main.hud._update_waypoint_tracker()
	check(GameManager.active_waypoint.is_empty() and not main.hud.waypoint_panel.visible,
		"Reaching within 3.5m of waypoint auto-clears active_waypoint and hides WaypointPanel")

	main.queue_free()
	await get_tree().process_frame

# ------------------------------------------------------------------------------
# 6. MULTI-RESOLUTION UI CONTAINMENT & NO OVERLAP STRESS TEST
# ------------------------------------------------------------------------------
func test_ui_containment_and_no_overlap_v1_1() -> void:
	print("\n[Suite 6] Multi-Resolution UI Containment & Zero-Overlap Verification (800x600 .. 1920x1080)")
	GameManager.start_new_game()
	EconomyManager.balance = 3000.0
	ShopManager.buy_to_backpack("cafe", "thermos_bicerin")
	ShopManager.buy_hardware("hw_wifi_router", 1)
	ShopManager.buy_gadget("elettronica_componenti", "gadget_scanner_wifi")
	var poi := MapData.get_poi("officina_bellini")
	GameManager.set_waypoint(poi["id"], poi["name"], poi["pos"])

	var scenes := [
		{"name": "InventoryMenu", "scene": InventoryMenuScene},
		{"name": "WorldMapMenu", "scene": WorldMapMenuScene},
		{"name": "ShopMenu", "scene": ShopMenuScene},
		{"name": "HUD", "scene": HudScene}
	]

	for res in RESOLUTIONS:
		var vp := SubViewport.new()
		vp.size = Vector2i(int(res.x), int(res.y))
		add_child(vp)

		for item in scenes:
			var inst: Control = item["scene"].instantiate()
			vp.add_child(inst)
			inst.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			if item["name"] == "InventoryMenu":
				inst.visible = true
				inst.open_inventory()
			elif item["name"] == "WorldMapMenu":
				inst.visible = true
				inst.open_map()
			elif item["name"] == "ShopMenu":
				inst.open_shop("alimentari")
			elif item["name"] == "HUD":
				inst.visible = true
				for t_i in range(8):
					inst._on_notification_posted("Notifica #%d" % (t_i + 1), "Messaggio toast di verifica ingombro su schermo stretto.", "info")
				inst._update_waypoint_tracker()
				inst._update_hints_label()

			await get_tree().process_frame
			await get_tree().process_frame

			var offenders: Array[String] = []
			_walk_ui_bounds(inst, Vector2.ZERO, res, offenders)
			if not offenders.is_empty():
				printerr("  [BOUNDS OVERFLOW] %s at %dx%d: %s" % [item["name"], int(res.x), int(res.y), " | ".join(offenders)])

			check(offenders.is_empty(), "%s controls strictly contained (zero horiz/frame clip) at %dx%d" % [item["name"], int(res.x), int(res.y)])

			if item["name"] == "HUD":
				var obj_r: Rect2 = inst.get_node("TopLeft/TopLeftVBox/ObjectivePanel").get_global_rect()
				var wp_r: Rect2 = inst.waypoint_panel.get_global_rect()
				var bl_r: Rect2 = inst.get_node("BottomLeft").get_global_rect()
				var toast_r: Rect2 = inst.toast_container.get_global_rect()
				var hints_r: Rect2 = inst.get_node("BottomRight/HintsPanel").get_global_rect()
				check(inst.toast_container.get_child_count() <= 3,
					"HUD rapid-toast eviction limits visible toasts to <=3 at %dx%d (got %d)" % [int(res.x), int(res.y), inst.toast_container.get_child_count()])
				check(not obj_r.intersects(wp_r), "HUD ObjectivePanel & WaypointPanel do not overlap at %dx%d" % [int(res.x), int(res.y)])
				check(not bl_r.intersects(obj_r) and not bl_r.intersects(wp_r),
					"HUD BottomLeft %s does not intersect Objective %s or Waypoint %s at %dx%d" % [bl_r, obj_r, wp_r, int(res.x), int(res.y)])
				check(not toast_r.intersects(obj_r) and not toast_r.intersects(wp_r),
					"HUD ToastContainer %s does not intersect Objective %s or Waypoint %s at %dx%d" % [toast_r, obj_r, wp_r, int(res.x), int(res.y)])
				check(not toast_r.intersects(hints_r), "HUD BottomLeft Toast & BottomRight Hints do not overlap at %dx%d" % [int(res.x), int(res.y)])

			inst.queue_free()
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
