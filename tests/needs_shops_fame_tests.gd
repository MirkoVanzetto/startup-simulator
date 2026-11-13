extends Node
## Test completi per NeedsManager, ShopManager, FameManager, ShopMenu responsive e Borgo San Carlo 3D.

var passed_count: int = 0
var failed_count: int = 0

func _ready() -> void:
	print("=== NEEDS, SHOPS, FAME & BORGO SAN CARLO TEST SUITE ===")
	await get_tree().process_frame
	_test_needs_manager()
	_test_fame_manager()
	_test_shop_manager()
	await _test_shop_menu_responsive()
	await _test_borgo_3d_integrity()
	print("\n=== RISULTATO: %d PASS, %d FAIL ===" % [passed_count, failed_count])
	get_tree().quit(0 if failed_count == 0 else 1)

func _check(cond: bool, label: String) -> void:
	if cond:
		passed_count += 1
		print("[PASS] " + label)
	else:
		failed_count += 1
		print("[FAIL] " + label)

func _test_needs_manager() -> void:
	print("\n-- NeedsManager --")
	NeedsManager.reset()
	_check(is_equal_approx(NeedsManager.get_hunger(), 100.0), "Needs reset hunger = 100")
	_check(is_equal_approx(NeedsManager.get_energy(), 100.0), "Needs reset energy = 100")
	_check(is_equal_approx(NeedsManager.get_speed_multiplier(), 1.0), "Full needs speed mult = 1.0")

	# Decay in MAIN_MENU = 0
	GameManager.current_state = GameManager.GameState.MAIN_MENU
	NeedsManager.tick(60.0)
	_check(is_equal_approx(NeedsManager.get_hunger(), 100.0), "No hunger decay in MAIN_MENU")

	# Decay in FIRST_PERSON = 1.0x
	GameManager.current_state = GameManager.GameState.FIRST_PERSON
	NeedsManager.tick(100.0)
	_check(NeedsManager.get_hunger() < 100.0 and NeedsManager.get_hunger() > 80.0, "Hunger decays slowly in FIRST_PERSON")
	var h_fp := NeedsManager.get_hunger()

	# Decay in COMPUTER = 0.5x
	NeedsManager.reset()
	GameManager.current_state = GameManager.GameState.COMPUTER
	NeedsManager.tick(100.0)
	var lost_pc := 100.0 - NeedsManager.get_hunger()
	var lost_fp := 100.0 - h_fp
	_check(is_equal_approx(lost_pc, lost_fp * 0.5), "Computer hunger decay is half of FIRST_PERSON")

	# Malus velocita'
	NeedsManager.set_hunger(25.0)
	NeedsManager.set_energy(100.0)
	_check(is_equal_approx(NeedsManager.get_speed_multiplier(), 0.85), "Hungry (<30) gives -15% speed")
	NeedsManager.set_hunger(5.0)
	_check(is_equal_approx(NeedsManager.get_speed_multiplier(), 0.65), "Starving (<10) gives -35% speed")
	NeedsManager.set_energy(20.0)
	_check(NeedsManager.get_speed_multiplier() >= 0.5 and NeedsManager.get_speed_multiplier() < 0.65, "Hungry + tired clamps >= 0.5")

	# Clamp 0..100 & eat/rest/sleep
	NeedsManager.set_hunger(95.0)
	_check(NeedsManager.eat("pizza_intera"), "eat('pizza_intera') returns true")
	_check(is_equal_approx(NeedsManager.get_hunger(), 100.0), "eat clamps hunger to 100")
	_check(not NeedsManager.eat("cibo_inesistente"), "eat unknown food returns false")

	NeedsManager.set_hunger(50.0)
	NeedsManager.set_energy(20.0)
	NeedsManager.rest(4.0)
	_check(is_equal_approx(NeedsManager.get_energy(), 70.0), "rest(4h) restores +50 energy")
	_check(NeedsManager.get_hunger() < 50.0, "rest(4h) consumes some hunger")

	NeedsManager.sleep_full()
	_check(is_equal_approx(NeedsManager.get_energy(), 100.0), "sleep_full restores energy to 100")

	# Serialization roundtrip
	NeedsManager.set_hunger(42.5)
	NeedsManager.set_energy(63.25)
	var ser := NeedsManager.serialize()
	NeedsManager.reset()
	NeedsManager.deserialize(ser)
	_check(is_equal_approx(NeedsManager.get_hunger(), 42.5), "NeedsManager deserialize hunger")
	_check(is_equal_approx(NeedsManager.get_energy(), 63.25), "NeedsManager deserialize energy")

func _test_fame_manager() -> void:
	print("\n-- FameManager --")
	FameManager.reset()
	GameManager.reputation_points = 0
	FameManager.sync_silently()
	_check(FameManager.get_tier_index() == 0, "0 rep -> tier 0")
	_check(FameManager.get_tier_name() == "Sconosciuto", "0 rep -> Sconosciuto")
	_check(is_equal_approx(FameManager.get_discount(), 0.0), "Tier 0 discount = 0%")
	_check(is_equal_approx(FameManager.get_contract_bonus(), 1.0), "Tier 0 contract bonus = 1.0")

	GameManager.reputation_points = 15
	_check(FameManager.get_tier_index() == 2 and FameManager.get_tier_name() == "Freelance Apprezzato", "15 rep -> tier 2")
	_check(FameManager.get_discount_percent() == 6, "Tier 2 discount = 6%")

	GameManager.reputation_points = 130
	_check(FameManager.get_tier_index() == 5 and FameManager.get_tier_name() == "Leggenda del Tech", "130 rep -> tier 5")
	_check(FameManager.get_discount_percent() == 20, "Tier 5 discount = 20%")
	_check(is_equal_approx(FameManager.get_contract_bonus(), 1.25), "Tier 5 contract bonus = 1.25")
	_check(FameManager.get_next_threshold() == -1, "Max tier next threshold = -1")

	# Spend -> +1 rep per 25 EUR
	GameManager.reputation_points = 0
	FameManager.reset()
	var g1 := FameManager.register_shop_spend(24.0)
	_check(g1 == 0, "24 EUR spent gives 0 rep")
	var g2 := FameManager.register_shop_spend(2.0)
	_check(g2 == 1 and GameManager.reputation_points == 1, "Crossing 25 EUR gives +1 rep")

	# Talk once
	_check(FameManager.register_talk("mario") and not FameManager.register_talk("mario"), "register_talk awards +1 rep once per NPC")

	# Roundtrip
	var fser := FameManager.serialize()
	FameManager.reset()
	FameManager.deserialize(fser)
	_check(is_equal_approx(FameManager.shop_spent_total, 26.0), "FameManager deserialize shop_spent_total")
	_check("mario" in FameManager.talked_to, "FameManager deserialize talked_to")

func _test_shop_manager() -> void:
	print("\n-- ShopManager --")
	ShopManager.reset()
	FameManager.reset()
	NeedsManager.reset()
	GameManager.reputation_points = 0
	FameManager.sync_silently()

	for sid in ["pizzeria", "cafe", "panificio", "alimentari", "edicola", "fridge"]:
		_check(ShopManager.has_shop(sid), "Shop exists: " + sid)

	# Insufficient funds -> no state change
	EconomyManager.balance = 1.0
	NeedsManager.set_hunger(40.0)
	var bought_fail := ShopManager.buy("pizzeria", "pizza_intera")
	_check(not bought_fail, "buy() fails when balance < price")
	_check(is_equal_approx(EconomyManager.balance, 1.0), "Balance unchanged on failed buy")
	_check(is_equal_approx(NeedsManager.get_hunger(), 40.0), "Hunger unchanged on failed buy")

	# Valid buy with tier discount (tier 3 = 10% off -> 3.50 * 0.9 = 3.15)
	GameManager.reputation_points = 35
	FameManager.sync_silently()
	_check(is_equal_approx(ShopManager.get_price("pizzeria", "trancio_margherita"), 3.15), "Tier 3 discount applied to pizza slice (3.15)")
	EconomyManager.balance = 50.0
	NeedsManager.set_hunger(40.0)
	var bought_ok := ShopManager.buy("pizzeria", "trancio_margherita")
	_check(bought_ok, "buy() succeeds with enough funds")
	_check(is_equal_approx(EconomyManager.balance, 46.85), "Balance deducted by discounted price")
	_check(is_equal_approx(NeedsManager.get_hunger(), 75.0), "Hunger increased by +35")

	# Fridge stock from alimentari
	var stocked := ShopManager.buy_for_fridge("alimentari", "panino")
	_check(stocked and ShopManager.get_fridge_count("panino") == 1, "buy_for_fridge adds panino to studio fridge")
	NeedsManager.set_hunger(20.0)
	var from_fridge := ShopManager.buy("fridge", "panino")
	_check(from_fridge and ShopManager.get_fridge_count("panino") == 0, "Consuming from fridge decrements stock")
	_check(is_equal_approx(NeedsManager.get_hunger(), 52.0), "Consuming panino from fridge restores +32 hunger")

	# Rivista tech once per day
	CalendarSystem.current_day = 3
	var rep_before := GameManager.reputation_points
	ShopManager.buy("edicola", "rivista_tech")
	_check(GameManager.reputation_points == rep_before + 1, "Rivista tech grants +1 Rep first time today")
	ShopManager.buy("edicola", "rivista_tech")
	_check(GameManager.reputation_points == rep_before + 1, "Rivista tech does NOT grant extra Rep same day")

	# Serialization
	ShopManager.buy_for_fridge("alimentari", "frutta")
	var sser := ShopManager.serialize()
	ShopManager.reset()
	ShopManager.deserialize(sser)
	_check(ShopManager.get_fridge_count("frutta") == 1 and ShopManager.magazine_day == 3, "ShopManager serialize/deserialize roundtrip")

func _test_shop_menu_responsive() -> void:
	print("\n-- ShopMenu Viewport Containment --")
	var scene := load("res://scenes/ui/shop_menu.tscn") as PackedScene
	var menu := scene.instantiate() as Control
	get_tree().root.add_child(menu)
	await get_tree().process_frame

	for vp_size in [Vector2i(1280, 720), Vector2i(1920, 1080), Vector2i(1024, 520), Vector2i(1366, 768), Vector2i(800, 600)]:
		get_window().size = vp_size
		get_tree().root.content_scale_size = vp_size
		await get_tree().process_frame
		menu.open_shop("alimentari")
		await get_tree().process_frame
		var panel := menu.get("_panel") as Control
		var rect := panel.get_global_rect()
		var fits := rect.position.x >= 0.0 and rect.position.y >= 0.0 and (rect.position.x + rect.size.x) <= float(vp_size.x) + 1.0 and (rect.position.y + rect.size.y) <= float(vp_size.y) + 1.0
		_check(fits, "ShopMenu fits inside viewport %dx%d (panel=%s)" % [vp_size.x, vp_size.y, str(rect.size)])
	get_tree().root.content_scale_size = Vector2i(1280, 720)
	get_window().size = Vector2i(1280, 720)
	menu.queue_free()
	await get_tree().process_frame

func _test_borgo_3d_integrity() -> void:
	print("\n-- Borgo San Carlo 3D Integrity --")
	var gw_scene := load("res://scenes/world/game_world.tscn") as PackedScene
	var world := gw_scene.instantiate() as Node3D
	get_tree().root.add_child(world)
	await get_tree().process_frame
	await get_tree().physics_frame

	var studio := world.get_node_or_null("Studio")
	var street := world.get_node_or_null("Street")
	var pizzeria := world.get_node_or_null("Pizzeria")
	_check(studio != null and studio.has_node("BorgoStudio"), "BorgoStudio generated")
	_check(street != null and street.has_node("BorgoTerrain"), "BorgoTerrain generated")
	_check(pizzeria != null and pizzeria.has_node("BorgoPizzeria"), "BorgoPizzeria generated")

	# Nuovi interactables nel Borgo
	_check(studio.find_child("BedInteractable", true, false) != null, "BedInteractable present in Studio")
	_check(studio.find_child("FridgeInteractable", true, false) != null, "FridgeInteractable present in Studio")
	_check(street.find_child("PanificioShop", true, false) != null, "Forno Bruno shop trigger present")
	_check(street.find_child("AlimentariShop", true, false) != null, "Alimentari Rosa shop trigger present")
	_check(street.find_child("EdicolaShop", true, false) != null, "Edicola Sabrina shop trigger present")
	_check(street.find_child("CafeShop", true, false) != null, "Caffè San Carlo shop trigger present")
	_check(pizzeria.find_child("PizzeriaShop", true, false) != null, "Pizzeria Da Mario shop trigger present")

	# Corridoi pedonali liberi (Studio -> Via del Borgo -> Piazzetta -> Negozi)
	var space := world.get_world_3d().direct_space_state
	var corridors := [
		["Studio -> Via del Borgo", Vector3(0, 1.0, 0.5), Vector3(0, 1.0, 14.0)],
		["Via -> Forno Bruno", Vector3(0, 1.0, 7.8), Vector3(-4.8, 1.0, 7.8)],
		["Via -> Alimentari Rosa", Vector3(0, 1.0, 7.8), Vector3(4.8, 1.0, 7.8)],
		["Piazzetta West -> Cafe", Vector3(-4.8, 1.0, 20.5), Vector3(-10.0, 1.0, 20.5)],
		["Piazzetta East -> TechShop", Vector3(4.8, 1.0, 20.5), Vector3(10.0, 1.0, 20.5)],
		["Piazzetta -> Pizzeria", Vector3(0, 1.0, 24.5), Vector3(0, 1.0, 27.6)]
	]
	for c in corridors:
		var q := PhysicsRayQueryParameters3D.create(c[1], c[2], 1)
		var hit := space.intersect_ray(q)
		_check(hit.is_empty(), "Corridor clear: " + str(c[0]))

	world.queue_free()
	await get_tree().process_frame
