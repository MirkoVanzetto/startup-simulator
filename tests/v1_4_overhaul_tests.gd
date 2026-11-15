extends Node
## v1.4.0 Comprehensive Overhaul Test Suite:
## UpgradeManager ★ (6 alberi, moltiplicatori neutri a Rank 0, spese/hosting/bandi, Save/Load),
## Ciclo Giorno/Notte (DayNightController + lampioni + cielo stellato),
## Anatomia NPC scolpiti (VillageCharacters),
## Officina Bellini clearance interazioni 3D (raycast mask 3 su stazioni, zone & Bellini),
## OGR Tech Hub gate fisico, corridor raycasts, Bay 01 vs Pod chiusi, Appalti Enterprise Tier I-IV,
## WorldMap zoom/pan/resize continuo senza blocco e TO-OS 26.4 UI Containment su 4 risoluzioni.

const GameWorldScene := preload("res://scenes/world/game_world.tscn")
const WorldMapMenuScene := preload("res://scenes/ui/world_map_menu.tscn")
const ComputerScreenScene := preload("res://scenes/ui/computer_screen.tscn")
const MapData := preload("res://scripts/world/world_map_data.gd")

const RESOLUTIONS: Array[Vector2] = [
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
	print("=== v1.4.0 OVERHAUL SUITE: TO-OS 26.4, STARS, OGR, DAY/NIGHT & MAP ===")
	print("======================================================================")

	test_upgrade_manager_math_and_saveload()
	await test_day_night_cycle_and_streetlamps()
	await test_officina_clearance_and_character_anatomy()
	await test_ogr_gate_corridors_and_enterprise()
	await test_world_map_zoom_pan_and_resize()
	await test_to_os_desktop_and_ui_4res()

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
# 1. UPGRADE MANAGER (RANK 0 NEUTRALITY, ECONOMY/HOSTING/PAYOUTS, SAVE/LOAD)
# ------------------------------------------------------------------------------
func test_upgrade_manager_math_and_saveload() -> void:
	print("\n[Suite 1] UpgradeManager ★ Tree (Rank 0 Neutral, Costs/Caps, Discounts, Save/Load)")
	GameManager.start_new_game()

	# Neutralità esatta a Rank 0 (preserva bilanciamento v1.2.0)
	check(UpgradeManager.get_stars() == 0, "New game starts with 0 Upgrade Stars")
	check(is_equal_approx(UpgradeManager.get_speed_mult(), 1.0), "Rank 0 speed mult == 1.0")
	check(is_equal_approx(UpgradeManager.get_sprint_drain_mult(), 1.0), "Rank 0 sprint drain mult == 1.0")
	check(is_equal_approx(UpgradeManager.get_interaction_reach_bonus(), 0.0), "Rank 0 interaction reach bonus == 0.0")
	check(is_equal_approx(UpgradeManager.get_side_job_pay_mult(), 1.0), "Rank 0 side job pay mult == 1.0")
	check(is_equal_approx(UpgradeManager.get_webforge_speed_bonus(), 0.0), "Rank 0 WebForge speed bonus == 0.0")
	check(is_equal_approx(UpgradeManager.get_contract_payout_mult(), 1.0), "Rank 0 contract payout mult == 1.0")
	check(is_equal_approx(UpgradeManager.get_hosting_bonus_mult(), 1.0), "Rank 0 hosting bonus mult == 1.0")
	check(is_equal_approx(UpgradeManager.get_overhead_discount_mult(), 1.0), "Rank 0 overhead discount mult == 1.0")
	check(UpgradeManager.get_enterprise_tier() == 1, "Rank 0 enterprise tier == 1")
	check(is_equal_approx(UpgradeManager.get_enterprise_payout_mult(), 1.0), "Rank 0 enterprise payout mult == 1.0")

	# Acquisto bloccato con 0 stelle
	check(not UpgradeManager.can_purchase("agility") and not UpgradeManager.purchase("agility"),
		"Cannot purchase upgrade with 0 stars")

	# Aggiunta stelle & acquisto fino al Rank 3 (costi 1 + 2 + 3 = 6★)
	UpgradeManager.add_stars(10, "Test Suite")
	check(UpgradeManager.get_stars() == 10, "add_stars(10) sets stars == 10")
	check(UpgradeManager.purchase("agility") and UpgradeManager.get_rank("agility") == 1 and UpgradeManager.get_stars() == 9,
		"Purchase agility Lv.1 costs 1★ (9★ left)")
	check(UpgradeManager.purchase("agility") and UpgradeManager.get_rank("agility") == 2 and UpgradeManager.get_stars() == 7,
		"Purchase agility Lv.2 costs 2★ (7★ left)")
	check(UpgradeManager.purchase("agility") and UpgradeManager.get_rank("agility") == 3 and UpgradeManager.get_stars() == 4,
		"Purchase agility Lv.3 costs 3★ (4★ left)")
	check(not UpgradeManager.can_purchase("agility") and UpgradeManager.get_next_cost("agility") == -1 and not UpgradeManager.purchase("agility"),
		"agility capped cleanly at Max Rank 3")
	check(is_equal_approx(UpgradeManager.get_speed_mult(), 1.24), "Agility Lv.3 gives +24% speed mult (1.24x)")
	check(is_equal_approx(UpgradeManager.get_sprint_drain_mult(), 0.64), "Agility Lv.3 lowers sprint drain mult to 0.64x")

	# Verifica efficienza spese studio su CalendarSystem (€48 * 0.88 = €42.24)
	check(UpgradeManager.purchase("efficiency") and is_equal_approx(UpgradeManager.get_overhead_discount_mult(), 0.88),
		"efficiency Lv.1 sets overhead mult to 0.88")
	EconomyManager.balance = 200.0
	CalendarSystem._bill_daily_expenses()
	check(is_equal_approx(EconomyManager.balance, 157.76),
		"Daily expenses reduced cleanly by 12%% overhead discount (200 -> 157.76, got %.2f)" % EconomyManager.balance)

	# Verifica Cluster Hosting Cloud bonus su ServerRackManager (€30 * 1.20 = €36)
	ServerRackManager.unlock_server_rack()
	check(is_equal_approx(ServerRackManager.calculate_daily_hosting_revenue(), 30.0),
		"Baseline hosting revenue with Rank 0 hosting == € 30.00")
	UpgradeManager.add_stars(4, "")
	check(UpgradeManager.purchase("hosting") and is_equal_approx(UpgradeManager.get_hosting_bonus_mult(), 1.20),
		"hosting Lv.1 grants 1.20x mult")
	check(is_equal_approx(ServerRackManager.calculate_daily_hosting_revenue(), 36.0),
		"Rack hosting revenue increases +20%% with hosting Lv.1 (€30 -> €36, got %.2f)" % ServerRackManager.calculate_daily_hosting_revenue())

	# Verifica Optics + Pipeline su payouts & Save/Load
	UpgradeManager.add_stars(5, "")
	check(UpgradeManager.purchase("optics") and is_equal_approx(UpgradeManager.get_interaction_reach_bonus(), 0.40) and is_equal_approx(UpgradeManager.get_side_job_pay_mult(), 1.15),
		"optics Lv.1 grants +0.4m reach and 1.15x SideJob pay")
	check(UpgradeManager.purchase("pipeline") and is_equal_approx(UpgradeManager.get_webforge_speed_bonus(), 0.70) and is_equal_approx(UpgradeManager.get_contract_payout_mult(), 1.12),
		"pipeline Lv.1 grants -0.7s WebForge build time and 1.12x contract payout mult")

	ContractManager.active_contracts["test_pip_contract"] = {
		"id": "test_pip_contract",
		"title": "Test Pipeline Contract",
		"budget": 500.0,
		"reputation_reward": 5,
		"star_reward": 1,
		"status": "in_progress",
		"is_enterprise": false,
		"fame_bonus": 1.0
	}
	var pre_bal: float = EconomyManager.balance
	check(ContractManager.complete_marketplace_contract("test_pip_contract"), "Completed marketplace contract with pipeline Lv.1")
	check(is_equal_approx(EconomyManager.balance - pre_bal, 560.0),
		"Pipeline Lv.1 multiplied €500 contract payout to €560.00 (got %.2f)" % (EconomyManager.balance - pre_bal))

	CalendarSystem.current_day = 4
	CalendarSystem.current_hour = 21
	CalendarSystem.current_minute = 35
	var saved_stars: int = UpgradeManager.get_stars()
	var saved_ranks: Dictionary = UpgradeManager.ranks.duplicate()
	check(SaveManager.save_game(), "Saved v1.4.0 state with stars, ranks and night clock")

	UpgradeManager.reset()
	CalendarSystem.current_day = 1
	CalendarSystem.current_hour = 9
	CalendarSystem.current_minute = 0
	check(UpgradeManager.get_stars() == 0 and UpgradeManager.get_rank("agility") == 0,
		"UpgradeManager reset cleared state prior to Load")
	check(SaveManager.load_game(), "Loaded v1.4.0 state")
	check(UpgradeManager.get_stars() == saved_stars and UpgradeManager.ranks == saved_ranks,
		"UpgradeManager stars (%d) & all ranks restored across Save/Load" % saved_stars)
	check(CalendarSystem.current_day == 4 and CalendarSystem.current_hour == 21 and CalendarSystem.current_minute == 35,
		"Calendar clock restored cleanly across Save/Load (Day 4 21:35)")

# ------------------------------------------------------------------------------
# 2. DAY/NIGHT CONTROLLER (SKY SHADER, SUNLIGHT & TORINO STREETLAMPS)
# ------------------------------------------------------------------------------
func test_day_night_cycle_and_streetlamps() -> void:
	print("\n[Suite 2] DayNightController & Sky Shader (Morning, Sunset & Starry Night + Streetlamps)")
	GameManager.start_new_game()
	var world: Node3D = GameWorldScene.instantiate() as Node3D
	add_child(world)
	await get_tree().physics_frame
	await get_tree().process_frame

	var dnc: DayNightController = world.find_child("DayNightController", true, false) as DayNightController
	var sun: DirectionalLight3D = world.find_child("SunLight", true, false) as DirectionalLight3D
	var wenv: WorldEnvironment = world.find_child("WorldEnvironment", true, false) as WorldEnvironment
	check(dnc != null and sun != null and wenv != null, "DayNightController, SunLight & WorldEnvironment present in GameWorld")

	var lamps: Array[Node] = get_tree().get_nodes_in_group("day_night_lamp")
	check(lamps.size() >= 20, "At least 20 Torino streetlamps registered in 'day_night_lamp' group (got %d)" % lamps.size())

	var sky_mat: ShaderMaterial = wenv.environment.sky.sky_material as ShaderMaterial if (wenv and wenv.environment and wenv.environment.sky) else null
	check(sky_mat != null, "Torino Sky ShaderMaterial active on WorldEnvironment")

	# 09:00 Mattino limpido
	dnc.set_debug_hour(9.0)
	await get_tree().process_frame
	var day_lamp_max: float = 0.0
	for ln in lamps:
		if ln is OmniLight3D:
			day_lamp_max = maxf(day_lamp_max, (ln as OmniLight3D).light_energy)
	var day_nf: float = float(sky_mat.get_shader_parameter("night_factor"))
	check(sun.light_energy >= 1.20 and is_equal_approx(day_lamp_max, 0.0) and is_equal_approx(day_nf, 0.0),
		"At 09:00 morning: Sun bright (%.2f >= 1.2), lamps off (%.2f), night_factor == 0" % [sun.light_energy, day_lamp_max])

	# 18:30 Tramonto dorato
	dnc.set_debug_hour(18.5)
	await get_tree().process_frame
	var sunset_f: float = float(sky_mat.get_shader_parameter("sunset_factor"))
	check(sunset_f >= 0.45 and sun.light_energy < 1.20,
		"At 18:30 sunset: warm sunset_factor active (%.2f) & sun softened (%.2f)" % [sunset_f, sun.light_energy])

	# 22:30 Notte stellata & lampioni accesi
	dnc.set_debug_hour(22.5)
	await get_tree().process_frame
	var night_lamp_min: float = 99.0
	for ln in lamps:
		if ln is OmniLight3D:
			night_lamp_min = minf(night_lamp_min, (ln as OmniLight3D).light_energy)
	var night_nf: float = float(sky_mat.get_shader_parameter("night_factor"))
	check(night_nf >= 0.90 and night_lamp_min >= 2.5 and sun.light_energy <= 0.40,
		"At 22:30 night: night_factor=%.2f, all streetlamps lit (min %.2f), moonlight dim (%.2f)" % [night_nf, night_lamp_min, sun.light_energy])

	dnc.clear_debug_hour()
	await get_tree().process_frame
	check(sun.light_energy >= 1.20, "clear_debug_hour() restores CalendarSystem morning sun")

	world.queue_free()
	await get_tree().process_frame

# ------------------------------------------------------------------------------
# 3. OFFICINA BELLINI INTERACTION CLEARANCE & SEMI-REALISTIC CHARACTER ANATOMY
# ------------------------------------------------------------------------------
func _ray_hit(space: PhysicsDirectSpaceState3D, from: Vector3, to: Vector3, mask: int) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(from, to, mask)
	return space.intersect_ray(query)

func test_officina_clearance_and_character_anatomy() -> void:
	print("\n[Suite 3] Officina Bellini 3D Raycast Clearance & VillageCharacters Anatomy")
	GameManager.start_new_game()
	var world: Node3D = GameWorldScene.instantiate() as Node3D
	add_child(world)
	await get_tree().physics_frame
	await get_tree().physics_frame

	var factory: Node3D = world.find_child("FactoryVenue", true, false) as Node3D
	check(factory != null, "FactoryVenue present in GameWorld")
	var space: PhysicsDirectSpaceState3D = world.get_world_3d().direct_space_state

	# 1. Verifica che Bellini e tutte le 4 zone sopralluogo siano colpibili direttamente dal corridoio interno!
	var scout_targets: Array[Dictionary] = [
		{"node": "BelliniNPC", "from_local": Vector3(0.95, 1.55, -0.75), "to_local": Vector3(2.10, 1.05, -1.80)},
		{"node": "ScoutZone_Ingresso", "from_local": Vector3(0.0, 1.55, 2.40), "to_local": Vector3(-1.45, 1.05, 2.40)},
		{"node": "ScoutZone_Magazzino", "from_local": Vector3(0.4, 1.55, -1.60), "to_local": Vector3(-0.8, 1.05, -2.18)},
		{"node": "ScoutZone_Ufficio", "from_local": Vector3(0.7, 1.55, 1.45), "to_local": Vector3(2.25, 1.05, 1.45)},
		{"node": "ScoutZone_Vetrina", "from_local": Vector3(-1.3, 1.55, -1.2), "to_local": Vector3(-3.0, 1.05, -1.6)}
	]
	for t in scout_targets:
		var tnode: StaticBody3D = factory.get_node_or_null(str(t["node"])) as StaticBody3D
		var hit: Dictionary = _ray_hit(space, factory.to_global(t["from_local"]), factory.to_global(t["to_local"]), 3)
		var hit_node = hit.get("collider", null)
		check(tnode != null and (tnode.collision_layer & 2) != 0 and hit_node == tnode,
			"Officina raycast (mask=3) hits '%s' first with zero obstruction (got %s)" % [
				str(t["node"]), str(hit_node.name) if hit_node else "null"
			])

	# 2. Completa il sopralluogo 4/4: le zone concluse disattivano i propri collider lasciando campo libero agli ologrammi!
	ContractManager.accept_factory_commission()
	for zid in ContractManager.FACTORY_SCOUT_ZONES:
		ContractManager.scout_factory_zone(zid, zid)
	await get_tree().physics_frame

	var hw_targets: Array[Dictionary] = [
		{"node": "InstallStation_Wifi", "from_local": Vector3(-2.45, 1.55, 2.10), "to_local": Vector3(-2.45, 1.32, 3.72)},
		{"node": "InstallStation_Server", "from_local": Vector3(-0.20, 1.55, -1.60), "to_local": Vector3(-0.80, 1.05, -3.60)},
		{"node": "InstallStation_PCs", "from_local": Vector3(1.85, 1.55, -0.75), "to_local": Vector3(3.75, 1.05, -0.75)}
	]
	for t in hw_targets:
		var tnode: StaticBody3D = factory.get_node_or_null(str(t["node"])) as StaticBody3D
		var hit: Dictionary = _ray_hit(space, factory.to_global(t["from_local"]), factory.to_global(t["to_local"]), 3)
		var hit_node = hit.get("collider", null)
		check(tnode != null and (tnode.collision_layer & 2) != 0 and hit_node == tnode,
			"Post-scout Officina raycast (mask=3) hits '%s' first with zero obstruction (got %s)" % [
				str(t["node"]), str(hit_node.name) if hit_node else "null"
			])

	# Verifica gerarchia anatomica VillageCharacters, materiali StandardMaterial3D PBR, SSS solo su pelle e NoiseTexture2D
	var skin_keys: Array[String] = ["skin", "skin_warm", "skin_cheek", "skin_crevice", "lip_warm", "lip_rose"]
	var eye_keys: Array[String] = ["eye_white", "iris_brown", "iris_blue", "iris_green", "limbal_dark", "eye_glint", "badge_cyan"]
	var standing_npcs: Array[String] = ["MarioNPC", "BrunoNPC", "RosaNPC", "ElenaNPC", "DavideNPC", "SabrinaNPC", "BelliniNPC", "AndreaVialeNPC"]
	for nname in standing_npcs:
		var npc: Node = world.find_child(nname, true, false)
		var model: Node = npc.get_node_or_null("Model") if npc else null
		var body_mi: MeshInstance3D = model.get_node_or_null("BodyMesh") as MeshInstance3D if model else null
		var head_mi: MeshInstance3D = model.get_node_or_null("HeadPivot/HeadMesh") as MeshInstance3D if model else null
		var arml_mi: MeshInstance3D = model.get_node_or_null("ArmLPivot/Mesh") as MeshInstance3D if model else null
		var armr_mi: MeshInstance3D = model.get_node_or_null("ArmRPivot/Mesh") as MeshInstance3D if model else null
		var ap: AnimationPlayer = model.get_node_or_null("AnimationPlayer") as AnimationPlayer if model else null
		var face_count: int = 0
		var all_char_pbr: bool = true
		var sss_rule_ok: bool = true
		var noise_tex_ok: bool = true
		var bad_detail := ""
		var rig_meshes: Array[MeshInstance3D] = [body_mi, head_mi, arml_mi, armr_mi]
		for mi in rig_meshes:
			if mi == null or mi.mesh == null:
				continue
			if mi == body_mi or mi == head_mi:
				face_count += mi.mesh.get_faces().size()
			for si in range(mi.mesh.get_surface_count()):
				var sname: String = mi.mesh.surface_get_name(si)
				var smat: Material = mi.mesh.surface_get_material(si)
				if not (smat is StandardMaterial3D):
					all_char_pbr = false
					bad_detail = "%s:%s not StandardMaterial3D" % [mi.name, sname]
					break
				var pbr: StandardMaterial3D = smat as StandardMaterial3D
				var is_skin: bool = sname in skin_keys
				var is_eye: bool = sname in eye_keys
				if is_skin:
					if not pbr.subsurf_scatter_enabled or not pbr.subsurf_scatter_skin_mode:
						sss_rule_ok = false
						bad_detail = "%s:%s missing SSS" % [mi.name, sname]
				else:
					if pbr.subsurf_scatter_enabled:
						sss_rule_ok = false
						bad_detail = "%s:%s has SSS enabled on non-skin" % [mi.name, sname]
				if is_eye:
					if not pbr.clearcoat_enabled:
						noise_tex_ok = false
						bad_detail = "%s:%s missing eye clearcoat" % [mi.name, sname]
				else:
					var nt := pbr.normal_texture as NoiseTexture2D
					var rt := pbr.roughness_texture as NoiseTexture2D
					if nt == null or rt == null or nt.width > 512 or rt.width > 512:
						noise_tex_ok = false
						bad_detail = "%s:%s invalid NoiseTexture2D" % [mi.name, sname]
		check(model != null and body_mi != null and head_mi != null and arml_mi != null and armr_mi != null and ap != null and face_count > 3500,
			"%s uses high-detail sculpted VillageCharacters rig (%d tri vertices, rig complete)" % [nname, face_count / 3])
		check(all_char_pbr and sss_rule_ok and noise_tex_ok,
			"%s uses 100%% StandardMaterial3D PBR, skin-only SSS & <=512 NoiseTexture2D (%s)" % [nname, bad_detail if bad_detail != "" else "ok"])

	var cw_seated: Node = world.find_child("CoworkerSeated", true, false)
	var cw_ap: AnimationPlayer = cw_seated.get_node_or_null("Model/AnimationPlayer") as AnimationPlayer if cw_seated else null
	check(cw_seated != null and cw_ap != null and cw_ap.has_animation("Sit_Chair_Idle"),
		"OGR CoworkerSeated uses seated VillageCharacters rig with Sit_Chair_Idle")

	var luca_emp: Node = world.find_child("EmployeeModel", true, false)
	var luca_body: MeshInstance3D = luca_emp.get_node_or_null("Model/BodyMesh") as MeshInstance3D if luca_emp else null
	check(luca_body != null and luca_body.mesh != null and luca_body.mesh.get_surface_count() >= 4,
		"Studio Luca Workstation EmployeeModel built with sculpted multi-surface PBR rig")

	var portrait_lights: Array[Node] = get_tree().get_nodes_in_group("npc_portrait_light")
	var spot_cnt: int = 0
	for pl in portrait_lights:
		if pl is SpotLight3D:
			spot_cnt += 1
	check(spot_cnt >= 18, "At least 18 portrait Key/Rim SpotLight3Ds configured across Borgo/Studio/OGR NPCs (got %d)" % spot_cnt)

	world.queue_free()
	await get_tree().process_frame

# ------------------------------------------------------------------------------
# 4. OGR GATE LOCK/UNLOCK, CORRIDOR RAYCASTS & ENTERPRISE APPALTI (TIERS I-IV)
# ------------------------------------------------------------------------------
func test_ogr_gate_corridors_and_enterprise() -> void:
	print("\n[Suite 4] OGR Gate Lock/Unlock, Hall Corridors, Bay 01 vs Closed Pods & Enterprise Tiers")
	GameManager.start_new_game()
	EconomyManager.balance = 50000.0

	var world: Node3D = GameWorldScene.instantiate() as Node3D
	add_child(world)
	await get_tree().physics_frame
	await get_tree().physics_frame

	var gate: Node3D = world.find_child("OGRGateBarrier", true, false) as Node3D
	var gate_col: CollisionShape3D = gate.get_node_or_null("OGRGateBody/Collider") as CollisionShape3D if gate else null
	var gate_vis: Node3D = gate.get_node_or_null("GateVisual") as Node3D if gate else null
	var open_ban: Node3D = gate.get_node_or_null("OpenBanner") as Node3D if gate else null
	check(gate != null and gate_col != null and gate_vis != null and open_ban != null,
		"OGRGateBarrier with Collider, GateVisual & OpenBanner exists in Mercato Est")

	# Stato iniziale: chiuso fisicamente e bandi OGR bloccati!
	check(not ContractManager.is_ogr_unlocked() and not gate_col.disabled and gate_vis.visible and not open_ban.visible,
		"Initially OGR is locked: collider active, GateVisual shown, OpenBanner hidden")
	check(not ContractManager.accept_enterprise_contract("ogr_fiat_telemetria"),
		"accept_enterprise_contract rejected while OGR is locked")

	var space: PhysicsDirectSpaceState3D = world.get_world_3d().direct_space_state
	var lock_hit: Dictionary = _ray_hit(space, Vector3(93.5, 1.0, 2.75), Vector3(99.0, 1.0, 2.75), 1)
	check(not lock_hit.is_empty() and str(lock_hit["collider"].name) == "OGRGateBody",
		"Locked gate physically blocks corridor into OGR (hit: %s)" % (str(lock_hit["collider"].name) if not lock_hit.is_empty() else "none"))

	# Completa solo le 3 di Via Po -> OGR resta bloccata finché manca Officina Bellini!
	ContractManager.advance_tutorial_to_in_progress()
	ContractManager.complete_tutorial_contract()
	ContractManager.advance_contract_to_in_progress("caffe_san_carlo")
	ContractManager.complete_story_contract("caffe_san_carlo")
	ContractManager.advance_contract_to_in_progress("elettronica_to")
	ContractManager.complete_story_contract("elettronica_to")
	check(not ContractManager.is_ogr_unlocked() and not gate_col.disabled,
		"After Via Po 3/3 (without Officina Bellini), OGR remains strictly locked")

	# Completa tutti i 4 pilastri di Officina Bellini -> sblocco automatico OGR!
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
	ContractManager.mark_contract_built("factory_bellini_web", {"score": 96})
	ContractManager.complete_marketplace_contract("factory_bellini_web")

	await get_tree().physics_frame
	await get_tree().process_frame

	check(ContractManager.is_ogr_unlocked() and gate_col.disabled and not gate_vis.visible and open_ban.visible,
		"Completing Via Po + Officina Bellini unlocks OGR, disables gate collider, shows OpenBanner")

	# Verifica corridoi liberi dentro OGR e Pod 02 chiuso
	var nav_hit: Dictionary = _ray_hit(space, Vector3(88.0, 1.0, 2.75), Vector3(119.0, 1.0, 2.75), 1)
	check(nav_hit.is_empty(),
		"Unlocked OGR central corridor clear from Mercato Promenade (X=88..119)%s" % ("" if nav_hit.is_empty() else " (hit: %s)" % nav_hit["collider"].name))

	var bay1_hit: Dictionary = _ray_hit(space, Vector3(102.65, 1.0, 7.2), Vector3(102.65, 1.0, 10.6), 1)
	check(bay1_hit.is_empty(), "Bay 01 glass entrance is physically OPEN and walkable")

	var pod2_hit: Dictionary = _ray_hit(space, Vector3(104.05, 1.0, -2.2), Vector3(104.05, 1.0, -5.4), 1)
	check(not pod2_hit.is_empty(), "Pod 02 entrance is physically CLOSED (reserved glass barrier blocks entry)")

	var viale_npc: StaticBody3D = world.find_child("AndreaVialeNPC", true, false) as StaticBody3D
	var viale_hit: Dictionary = _ray_hit(space, Vector3(101.8, 1.55, 2.2), Vector3(104.8, 1.05, 2.2), 3)
	check(viale_npc != null and viale_hit.get("collider", null) == viale_npc,
		"AndreaVialeNPC inside OGR reachable cleanly via interaction raycast")

	# Enterprise Tier Gating & Lifecycle (Accept -> Cancel -> Accept & Complete w/ 1.45x Tier 4 mult)
	var max_t_r0: int = 0
	for ec in ContractManager.enterprise_contracts:
		max_t_r0 = maxi(max_t_r0, int(ec.get("tier", 1)))
	check(ContractManager.enterprise_contracts.size() >= 2 and max_t_r0 == 1,
		"At UpgradeManager enterprise Rank 0, OGR Enterprise offers strictly Tier 1 tenders (max tier=%d)" % max_t_r0)

	UpgradeManager.add_stars(20, "Enterprise Tier Upgrade")
	check(UpgradeManager.purchase("enterprise") and UpgradeManager.purchase("enterprise") and UpgradeManager.purchase("enterprise"),
		"Upgraded 'enterprise' to Max Rank 3 (Tier IV · +45%%)")
	check(UpgradeManager.get_enterprise_tier() == 4 and is_equal_approx(UpgradeManager.get_enterprise_payout_mult(), 1.45),
		"Enterprise Rank 3 unlocks Tier 4 and 1.45x payout multiplier")

	var has_t4: bool = false
	for ec in ContractManager.enterprise_contracts:
		if int(ec.get("tier", 1)) == 4:
			has_t4 = true
	check(has_t4, "Tier 4 OGR Enterprise Elite tender populated automatically after upgrading")

	check(ContractManager.accept_enterprise_contract("ogr_pininfarina_cluster"), "Accepted Tier 2 hardware tender ogr_pininfarina_cluster")
	check(ContractManager.active_contracts.has("ogr_pininfarina_cluster"), "Active enterprise contract stored")
	check(ContractManager.cancel_active_contract("ogr_pininfarina_cluster") and not ContractManager.active_contracts.has("ogr_pininfarina_cluster"),
		"cancel_active_contract() cleanly drops enterprise tender and refreshes pool")

	check(ContractManager.accept_enterprise_contract("ogr_fiat_telemetria"), "Accepted Tier 1 tender ogr_fiat_telemetria")
	var raw_budget: float = float(ContractManager.active_contracts["ogr_fiat_telemetria"]["budget"])
	var fame_mult: float = float(ContractManager.active_contracts["ogr_fiat_telemetria"].get("fame_bonus", 1.0))
	ContractManager.mark_contract_built("ogr_fiat_telemetria", {"score": 98})
	var bal_before: float = EconomyManager.balance
	var stars_before: int = UpgradeManager.get_stars()
	check(ContractManager.complete_marketplace_contract("ogr_fiat_telemetria"), "Completed ogr_fiat_telemetria")
	var expected_pay: float = raw_budget * fame_mult * 1.45
	check(is_equal_approx(EconomyManager.balance - bal_before, expected_pay),
		"Tier 4 enterprise bonus pays 1.45x (€%.2f * %.2fx * 1.45 = €%.2f, got %.2f)" % [raw_budget, fame_mult, expected_pay, EconomyManager.balance - bal_before])
	check(UpgradeManager.get_stars() == stars_before + 3,
		"OGR tender grants +3★ bonus reward")

	world.queue_free()
	await get_tree().process_frame

# ------------------------------------------------------------------------------
# 5. WORLD MAP ZOOM / PAN / RESIZE CONTINUO (FIX BLOCCO POST-SELEZIONE)
# ------------------------------------------------------------------------------
func test_world_map_zoom_pan_and_resize() -> void:
	print("\n[Suite 5] WorldMap Zoom, Pan Clamp, District Selection & Viewport Resize Fix")
	GameManager.start_new_game()
	check(MapData.get_pois().size() == 14, "WorldMapData defines all 14 POIs incl. OGR Tech Hub")

	var vp := SubViewport.new()
	vp.size = Vector2i(1280, 720)
	add_child(vp)

	var wmap: Control = WorldMapMenuScene.instantiate() as Control
	vp.add_child(wmap)
	wmap.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wmap.open_map()
	await get_tree().process_frame
	await get_tree().process_frame

	# Tutti i filtri distretto & pulsanti devono avere FOCUS_NONE per non bloccare mai input o resize
	var all_focus_none: bool = true
	for k in wmap._view_buttons:
		var btn: Button = wmap._view_buttons[k] as Button
		if btn.focus_mode != Control.FOCUS_NONE:
			all_focus_none = false
	check(all_focus_none and wmap._zoom_in_btn.focus_mode == Control.FOCUS_NONE and wmap._close_btn.focus_mode == Control.FOCUS_NONE,
		"All WorldMap filter tabs & toolbar buttons use FOCUS_NONE")

	# Seleziona un distretto (bug riportato: dopo aver selezionato una zona non si poteva ridimensionare!)
	wmap._set_view("mercato")
	wmap.select_poi("coworking_ogr")
	await get_tree().process_frame
	var size_1280: Vector2 = wmap._panel.size

	# Zoom in, cursor zoom_at & pan clamp
	wmap.zoom_in()
	var z1: float = wmap._map_canvas.get_zoom()
	wmap.zoom_in()
	var z2: float = wmap._map_canvas.get_zoom()
	check(z1 > 1.15 and z2 > z1, "WorldMap zoom_in increases canvas zoom progressively (1.0 -> %.2f -> %.2f)" % [z1, z2])

	wmap._map_canvas.zoom_at(Vector2(260, 220), 2.8)
	var z3: float = wmap._map_canvas.get_zoom()
	check(is_equal_approx(z3, 2.8) and wmap._map_canvas.get_pan_world().length() > 0.1,
		"Cursor-centered zoom_at updates zoom (%.2f) and pan offset cleanly" % z3)

	# Simula ridimensionamento finestra DOPO aver selezionato zona e zoomato
	vp.size = Vector2i(860, 520)
	wmap.size = Vector2(860, 520)
	await get_tree().process_frame
	await get_tree().process_frame
	var size_860: Vector2 = wmap._panel.size
	check(size_860.x < size_1280.x and size_860.y < size_1280.y and size_860.x <= 830.0 and size_860.y <= 505.0,
		"After district selection, shrinking viewport dynamically shrinks WorldMap panel (%s -> %s)" % [str(size_1280), str(size_860)])

	vp.size = Vector2i(1440, 880)
	wmap.size = Vector2(1440, 880)
	await get_tree().process_frame
	await get_tree().process_frame
	var size_1440: Vector2 = wmap._panel.size
	check(size_1440.x > size_860.x and size_1440.y > size_860.y,
		"After shrinking, growing viewport smoothly expands WorldMap panel again (%s -> %s)" % [str(size_860), str(size_1440)])

	wmap.reset_zoom()
	check(is_equal_approx(wmap._map_canvas.get_zoom(), 1.0) and is_equal_approx(wmap._map_canvas.get_pan_world().length(), 0.0),
		"reset_zoom() restores exact 100%% zoom & zero pan")

	wmap.queue_free()
	vp.queue_free()
	await get_tree().process_frame

# ------------------------------------------------------------------------------
# 6. TO-OS 26.4 DESKTOP, WINDOW CHROME & 4-RESOLUTION UI CONTAINMENT
# ------------------------------------------------------------------------------
func test_to_os_desktop_and_ui_4res() -> void:
	print("\n[Suite 6] TO-OS 26.4 Desktop Grid, Window Chrome & 4-Res Strict UI Containment")
	GameManager.start_new_game()
	EconomyManager.balance = 12000.0
	UpgradeManager.add_stars(8, "")
	ContractManager.advance_tutorial_to_in_progress()
	ContractManager.complete_tutorial_contract()
	ContractManager.advance_contract_to_in_progress("caffe_san_carlo")
	ContractManager.complete_story_contract("caffe_san_carlo")
	ContractManager.advance_contract_to_in_progress("elettronica_to")
	ContractManager.complete_story_contract("elettronica_to")
	ContractManager.discover_new_lead(false)

	for res in RESOLUTIONS:
		var vp := SubViewport.new()
		vp.size = Vector2i(int(res.x), int(res.y))
		add_child(vp)

		var comp: Control = ComputerScreenScene.instantiate() as Control
		vp.add_child(comp)
		comp.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		EventBus.computer_opened.emit()
		await get_tree().process_frame
		await get_tree().process_frame

		var min_sz: Vector2 = comp.get_combined_minimum_size()
		check(min_sz.x <= 800.0 and min_sz.y <= 520.0,
			"TO-OS ComputerScreen combined_minimum_size (%s) fits small viewports at %dx%d" % [str(min_sz), int(res.x), int(res.y)])

		# 1) Desktop Grid & Dock
		var desk_off: Array[String] = []
		_walk_ui_bounds(comp, Vector2.ZERO, res, desk_off)
		check(comp.desktop_area.visible and comp.desktop_apps_grid.get_child_count() == 10 and desk_off.is_empty(),
			"TO-OS Desktop 10-app grid + BottomDock strictly contained at %dx%d (%s)" % [int(res.x), int(res.y), ", ".join(desk_off)])

		# 2) Finestre TO-OS (incluse Upgrades ★, OGR Enterprise, Freelance, Shop, Rack, Talent, Mail, Bank)
		for app_id in ["upgrades", "ogr", "freelance", "shop", "rack", "talent", "mail", "bank"]:
			comp.open_app(app_id)
			await get_tree().process_frame
			await get_tree().process_frame
			var win_off: Array[String] = []
			_walk_ui_bounds(comp, Vector2.ZERO, res, win_off)
			check(win_off.is_empty(),
				"TO-OS app '%s' strictly contained at %dx%d (%s)" % [app_id, int(res.x), int(res.y), ", ".join(win_off)])

		# 3) Test Window Chrome MaxBtn (Compact toggle) at 1280x720
		if int(res.x) == 1280:
			comp.open_app("upgrades")
			await get_tree().process_frame
			var full_w: float = comp.upgrades_window.size.x
			comp._toggle_window_compact(comp.upgrades_window)
			await get_tree().process_frame
			var compact_w: float = comp.upgrades_window.size.x
			comp._toggle_window_compact(comp.upgrades_window)
			await get_tree().process_frame
			var restored_w: float = comp.upgrades_window.size.x
			check(compact_w < full_w - 40.0 and is_equal_approx(restored_w, full_w),
				"Window chrome MaxBtn toggles compact mode (%.0f -> %.0f -> %.0f)" % [full_w, compact_w, restored_w])

		comp.queue_free()
		vp.queue_free()
		await get_tree().process_frame

func _walk_ui_bounds(node: Node, sc_x_bounds: Vector2, vp_size: Vector2, offenders: Array[String]) -> void:
	if node is Control and not (node as Control).visible:
		return
	if node is ScrollContainer:
		var sc: ScrollContainer = node as ScrollContainer
		var sr: Rect2 = sc.get_global_rect()
		if sr.position.x < -1.5 or sr.end.x > vp_size.x + 1.5 or sr.position.y < -1.5 or sr.end.y > vp_size.y + 1.5:
			offenders.append("Scroll:%s(%.0f..%.0f, %.0f..%.0f)" % [sc.name, sr.position.x, sr.end.x, sr.position.y, sr.end.y])
		var x_bounds := Vector2(sr.position.x, sr.end.x)
		for ch in sc.get_children():
			_walk_ui_bounds(ch, x_bounds, vp_size, offenders)
		return
	if node is Control:
		var c: Control = node as Control
		var r: Rect2 = c.get_global_rect()
		if sc_x_bounds.y > 0.0:
			if r.position.x < sc_x_bounds.x - 1.5 or r.end.x > sc_x_bounds.y + 1.5:
				offenders.append("HClip:%s(%.0f..%.0f vs %.0f..%.0f)" % [c.name, r.position.x, r.end.x, sc_x_bounds.x, sc_x_bounds.y])
		else:
			if r.position.x < -1.5 or r.end.x > vp_size.x + 1.5 or r.position.y < -1.5 or r.end.y > vp_size.y + 1.5:
				offenders.append("%s(%.0f..%.0f, %.0f..%.0f)" % [c.name, r.position.x, r.end.x, r.position.y, r.end.y])
	for ch in node.get_children():
		_walk_ui_bounds(ch, sc_x_bounds, vp_size, offenders)

