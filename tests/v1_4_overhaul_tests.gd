extends Node
## v1.4.0–v1.5.0 Comprehensive Overhaul Test Suite:
## UpgradeManager ★ (6 alberi, moltiplicatori neutri a Rank 0, spese/hosting/bandi, Save/Load),
## Ciclo Giorno/Notte (DayNightController + lampioni + cielo stellato),
## MakeHuman CC0 (.glb) NPCs + PBR Leggero (zero SSS/Heightmap/Detail, zero luci extra, forno fumo CPUParticles3D, Borgo Po/Molo sul Po),
## Officina Bellini clearance interazioni 3D (raycast mask 3 su stazioni, zone & Bellini),
## OGR Tech Hub gate fisico, corridor raycasts, Bay 01 vs Pod chiusi, Appalti Enterprise Tier I-IV,
## WorldMap zoom/pan/resize continuo senza blocco (19 POI), TO-OS 26.4 UI Containment su 4 risoluzioni,
## e KnowledgeManager R&D (4 rami post-Bellini, sblocco progressivo, commesse specialistiche, Save/Load).

const GameWorldScene := preload("res://scenes/world/game_world.tscn")
const WorldMapMenuScene := preload("res://scenes/ui/world_map_menu.tscn")
const ComputerScreenScene := preload("res://scenes/ui/computer_screen.tscn")
const WebForgeScene := preload("res://scenes/ui/minigames/web_forge.tscn")
const ContractGenerator := preload("res://scripts/contracts/contract_generator.gd")
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
	print("=== v1.4.0–v1.5.0 OVERHAUL SUITE: MAKEHUMAN, BORGO PO, KNOWLEDGE & OGR ===")
	print("======================================================================")

	test_upgrade_manager_math_and_saveload()
	await test_day_night_cycle_and_streetlamps()
	await test_officina_clearance_and_character_anatomy()
	await test_ogr_gate_corridors_and_enterprise()
	await test_world_map_zoom_pan_and_resize()
	await test_to_os_desktop_and_ui_4res()
	await test_knowledge_manager_and_specialty_contracts()

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

	# Verifica gerarchia MakeHuman CC0 (.glb), PBR leggero (#10): zero SSS/Heightmap/Detail, normal condivisa solo su tessuti, rim volume, zero luci extra
	var no_tex_surfaces: Array[String] = ["skin", "lip", "hair", "eyebrow", "hat"]
	var cloth_surfaces: Array[String] = ["shirt", "pants", "apron", "vest", "tie", "ribbon"]
	var eye_surfaces: Array[String] = ["eye_white", "iris", "limbal_dark"]
	var shared_fabric_tex := VillageMaterials.FABRIC_NORMAL_TEX as NoiseTexture2D
	check(shared_fabric_tex != null and shared_fabric_tex.width <= 256 and shared_fabric_tex.noise != null and shared_fabric_tex.noise.frequency <= 0.025,
		"Shared fabric_normal.tres loaded once (%s, freq=%.3f <= 0.025)" % [
			str(shared_fabric_tex.width) if shared_fabric_tex else "null",
			shared_fabric_tex.noise.frequency if (shared_fabric_tex and shared_fabric_tex.noise) else -1.0
		])

	var standing_npcs: Array[String] = ["TorrefattoreNPC", "BrunoNPC", "RosaNPC", "ElenaNPC", "DavideNPC", "SabrinaNPC", "BelliniNPC", "AndreaVialeNPC", "FerreroNPC", "ChiaraNPC"]
	for nname in standing_npcs:
		var npc: Node = world.find_child(nname, true, false)
		var model: Node = npc.get_node_or_null("Model") if npc else null
		var skel: Skeleton3D = model.find_child("Skeleton3D", true, false) as Skeleton3D if model else null
		var head_pivot: BoneAttachment3D = skel.get_node_or_null("HeadPivot") as BoneAttachment3D if skel else null
		var body_mi: MeshInstance3D = model.find_child("BodyMesh", true, false) as MeshInstance3D if model else null
		var ap: AnimationPlayer = model.find_child("AnimationPlayer", true, false) as AnimationPlayer if model else null
		var has_legacy_parts: bool = model != null and (model.get_node_or_null("ArmLPivot") != null or model.get_node_or_null("HeadPivot/HeadMesh") != null)
		var face_len: int = body_mi.mesh.get_faces().size() if (body_mi and body_mi.mesh) else 0
		var pbr_ok: bool = body_mi != null and body_mi.mesh != null and body_mi.mesh.get_surface_count() >= 4
		var bad_detail := ""

		if pbr_ok:
			for si in range(body_mi.mesh.get_surface_count()):
				var sname: String = body_mi.mesh.surface_get_name(si)
				var smat: Material = body_mi.mesh.surface_get_material(si)
				if not (smat is StandardMaterial3D):
					pbr_ok = false
					bad_detail = "%s not StandardMaterial3D" % sname
					break
				var pbr: StandardMaterial3D = smat as StandardMaterial3D
				if pbr.subsurf_scatter_enabled or pbr.subsurf_scatter_skin_mode or pbr.heightmap_enabled or pbr.detail_enabled or pbr.roughness_texture != null:
					pbr_ok = false
					bad_detail = "%s has SSS/Height/Detail/RoughTex enabled" % sname
					break
				if sname in eye_surfaces:
					if not pbr.clearcoat_enabled or pbr.normal_enabled or pbr.normal_texture != null or pbr.rim_enabled:
						pbr_ok = false
						bad_detail = "%s eye rule mismatch" % sname
						break
				elif sname in cloth_surfaces:
					if (not pbr.normal_enabled) or pbr.normal_texture != VillageMaterials.FABRIC_NORMAL_TEX or pbr.uv1_scale != Vector3.ONE or not is_equal_approx(pbr.normal_scale, 0.15) or not is_equal_approx(pbr.roughness, 0.75) or not pbr.rim_enabled or not is_equal_approx(pbr.rim, 0.25) or not is_equal_approx(pbr.rim_tint, 0.5):
						pbr_ok = false
						bad_detail = "%s cloth PBR rule mismatch" % sname
						break
				elif sname in no_tex_surfaces:
					if pbr.normal_enabled or pbr.normal_texture != null or not is_equal_approx(pbr.roughness, 0.75) or not pbr.rim_enabled or not is_equal_approx(pbr.rim, 0.25) or not is_equal_approx(pbr.rim_tint, 0.5):
						pbr_ok = false
						bad_detail = "%s skin/hair/hat PBR rule mismatch" % sname
						break
				else:
					if pbr.normal_enabled or not pbr.rim_enabled or not is_equal_approx(pbr.rim, 0.25) or not is_equal_approx(pbr.rim_tint, 0.5):
						pbr_ok = false
						bad_detail = "%s accessory PBR rule mismatch" % sname
						break

		check(model != null and skel != null and head_pivot != null and head_pivot.bone_name == "head" and ap != null and ap.has_animation("Idle") and not has_legacy_parts and face_len >= 7500 and face_len < 36000,
			"%s uses lightweight rigged MakeHuman .glb (%d tris, Skeleton3D+HeadPivot, Idle)" % [nname, face_len / 3])
		check(pbr_ok,
			"%s follows Request #10 light PBR rules (zero SSS/Height/Detail, shared fabric normal, rim=0.25) (%s)" % [nname, bad_detail if bad_detail != "" else "ok"])

	var mario_npc: Node = world.find_child("MarioNPC", true, false)
	var mario_model: Node = mario_npc.get_node_or_null("Model") if mario_npc else null
	var mario_custom: Node3D = mario_model.get_node_or_null("CustomVisual") as Node3D if mario_model else null
	var mario_ap: AnimationPlayer = mario_model.find_child("AnimationPlayer", true, false) as AnimationPlayer if mario_model else null
	var mario_mis: Array[Node] = mario_custom.find_children("*", "MeshInstance3D", true, false) if mario_custom else []
	var mario_tex_ok := false
	for mm in mario_mis:
		var mi := mm as MeshInstance3D
		if mi and mi.mesh:
			for si in range(mi.mesh.get_surface_count()):
				var sm := mi.mesh.surface_get_material(si)
				if sm is StandardMaterial3D and (sm as StandardMaterial3D).albedo_texture != null:
					mario_tex_ok = true
	var mario_h := mario_custom.scale.y if mario_custom else 0.0
	check(mario_custom != null and mario_mis.size() >= 1 and mario_tex_ok and mario_h >= 1.65 and mario_ap != null and mario_ap.has_animation("Idle"),
		"MarioNPC uses custom pizzaiolo GLB (CustomVisual=%s, meshes=%d, textured=%s, scale=%.2f, Idle=%s)" % [
			str(mario_custom != null), mario_mis.size(), str(mario_tex_ok), mario_h, str(mario_ap != null and mario_ap.has_animation("Idle"))
		])

	var cw_seated: Node = world.find_child("CoworkerSeated", true, false)
	var cw_ap: AnimationPlayer = cw_seated.find_child("AnimationPlayer", true, false) as AnimationPlayer if cw_seated else null
	check(cw_seated != null and cw_ap != null and cw_ap.has_animation("Sit_Chair_Idle") and cw_ap.has_animation("Sit_Typing") and cw_ap.current_animation == "Sit_Typing",
		"OGR CoworkerSeated uses MakeHuman seated .glb rig playing Sit_Typing")

	var luca_emp: Node = world.find_child("EmployeeModel", true, false)
	var luca_body: MeshInstance3D = luca_emp.find_child("BodyMesh", true, false) as MeshInstance3D if luca_emp else null
	check(luca_body != null and luca_body.mesh != null and luca_body.mesh.get_surface_count() >= 4,
		"Studio Luca Workstation EmployeeModel built with MakeHuman multi-surface PBR rig")

	var portrait_lights: Array[Node] = get_tree().get_nodes_in_group("npc_portrait_light")
	check(portrait_lights.is_empty(), "Zero extra npc_portrait_light spotlights spawned on NPCs (got %d)" % portrait_lights.size())

	# Pizzeria Da Mario: fumo forno a legna con CPUParticles3D morbide (nessuna sfera mesh statica smoke_soft!)
	var oven_smoke: CPUParticles3D = world.find_child("OvenSmokeParticles", true, false) as CPUParticles3D
	var piz_mesh: MeshInstance3D = world.find_child("BorgoPizzeriaMesh", true, false) as MeshInstance3D
	var has_smoke_blob: bool = false
	if piz_mesh and piz_mesh.mesh:
		for si in range(piz_mesh.mesh.get_surface_count()):
			if piz_mesh.mesh.surface_get_name(si) == "smoke_soft":
				has_smoke_blob = true
	check(oven_smoke != null and oven_smoke.emitting and oven_smoke.amount >= 10 and not has_smoke_blob,
		"Pizzeria oven uses emitting CPUParticles3D volumetric smoke without static sphere blobs")

	# Borgo Po / Lungo Po / Molo sul Po: corridoio arco sud libero + pavimento legno sul Molo
	var borgopo_arch_hit: Dictionary = _ray_hit(space, Vector3(8.2, 1.0, 34.0), Vector3(8.2, 1.0, 56.0), 1)
	check(borgopo_arch_hit.is_empty(),
		"Borgo Po South Archway & promenade corridor clear (hit: %s)" % (str(borgopo_arch_hit["collider"].name) if not borgopo_arch_hit.is_empty() else "none"))
	var molo_hit: Dictionary = _ray_hit(space, Vector3(16.0, 1.5, 68.5), Vector3(16.0, -0.5, 68.5), 1)
	var molo_surf: String = str(molo_hit["collider"].get_meta("surface", "")) if not molo_hit.is_empty() and molo_hit["collider"].has_meta("surface") else ""
	check(not molo_hit.is_empty() and molo_surf == "wood",
		"Molo sul Po pier has walkable 'wood' footstep collider (got '%s')" % molo_surf)

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
	check(MapData.get_pois().size() == 20, "WorldMapData defines all 20 POIs incl. Miniera Alpina, OGR Tech Hub & Borgo Po")

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
	check(all_focus_none and wmap._view_buttons.has("miniera") and wmap._view_buttons.has("borgopo") and wmap._zoom_in_btn.focus_mode == Control.FOCUS_NONE and wmap._close_btn.focus_mode == Control.FOCUS_NONE,
		"All 7 WorldMap filter tabs (incl. 'miniera' & 'borgopo') & toolbar buttons use FOCUS_NONE")

	# Seleziona distretti (Miniera Alpina + Borgo Po + Mercato OGR) prima e dopo il resize
	wmap._set_view("miniera")
	wmap.select_poi("miniera_alpina")
	check(wmap.selected_poi_id == "miniera_alpina", "Miniera Alpina view & 'miniera_alpina' POI selectable cleanly")
	wmap._set_view("borgopo")
	wmap.select_poi("molo_po")
	check(wmap.selected_poi_id == "molo_po", "Borgo Po view & 'molo_po' POI selectable cleanly")
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
	print("\n[Suite 6] TO-OS 26.4 Desktop Grid (11 Apps incl. Knowledge), Window Chrome & 4-Res Strict UI Containment")
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

		# 1) Desktop Grid & 12-button Dock
		var desk_off: Array[String] = []
		_walk_ui_bounds(comp, Vector2.ZERO, res, desk_off)
		check(comp.desktop_area.visible and comp.desktop_apps_grid.get_child_count() == 11 and desk_off.is_empty(),
			"TO-OS Desktop 11-app grid + BottomDock strictly contained at %dx%d (%s)" % [int(res.x), int(res.y), ", ".join(desk_off)])

		# 2) Finestre TO-OS (incluse Upgrades ★, Conoscenza R&D, OGR Enterprise, Freelance, Shop, Rack, Talent, Mail, Bank)
		for app_id in ["upgrades", "knowledge", "ogr", "freelance", "shop", "rack", "talent", "mail", "bank"]:
			comp.open_app(app_id)
			await get_tree().process_frame
			await get_tree().process_frame
			var win_off: Array[String] = []
			_walk_ui_bounds(comp, Vector2.ZERO, res, win_off)
			check(win_off.is_empty(),
				"TO-OS app '%s' strictly contained at %dx%d (%s)" % [app_id, int(res.x), int(res.y), ", ".join(win_off)])

		# 3) Test Window Chrome MaxBtn (Compact toggle) at 1280x720 + Knowledge Unlocked containment
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

			ContractManager.completed_contracts.append("factory_bellini")
			ContractManager.factory_state["completed"] = true
			GameManager.reputation_points = 120
			KnowledgeManager.study("web_architecture")
			comp.open_app("knowledge")
			await get_tree().process_frame
			await get_tree().process_frame
			var k_off: Array[String] = []
			_walk_ui_bounds(comp, Vector2.ZERO, res, k_off)
			check(comp.knowledge_window.visible and k_off.is_empty(),
				"TO-OS unlocked Conoscenza R&D window strictly contained at 1280x720 (%s)" % ", ".join(k_off))

		comp.queue_free()
		vp.queue_free()
		await get_tree().process_frame

# ------------------------------------------------------------------------------
# 7. KNOWLEDGE MANAGER (POST-BELLINI R&D, SPECIALTY CONTRACTS, BONUSES & SAVE/LOAD)
# ------------------------------------------------------------------------------
func test_knowledge_manager_and_specialty_contracts() -> void:
	print("\n[Suite 7] KnowledgeManager R&D (Pre-Bellini Lock, Rank 0 Neutrality, Specialty Contracts, WebForge/Rack/Payout & Save/Load)")
	GameManager.start_new_game()
	EconomyManager.balance = 5000.0
	GameManager.reputation_points = 100

	# 1) Blocco rigoroso prima di completare Officina Bellini + neutralità totale a Rank 0
	check(not KnowledgeManager.is_unlocked(), "KnowledgeManager locked cleanly before Officina Bellini completion")
	check(KnowledgeManager.get_unlocked_specialties().is_empty(), "Rank 0 returns empty unlocked specialties")
	check(is_equal_approx(KnowledgeManager.get_webforge_speed_bonus(), 0.0), "Rank 0 WebForge speed bonus == 0.0")
	check(is_equal_approx(KnowledgeManager.get_rack_hosting_mult(), 1.0), "Rank 0 Rack hosting mult == 1.0")
	check(is_equal_approx(KnowledgeManager.get_contract_payout_mult({"execution_type": "webforge"}), 1.0), "Rank 0 contract payout mult == 1.0")
	check(not KnowledgeManager.study("web_architecture"), "Cannot study R&D track before Bellini completion even with funds & Rep")

	# 2) Completa tutti e 4 i pilastri di Officina Bellini -> Sblocco Conoscenza R&D!
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
	check(KnowledgeManager.is_unlocked(), "Completing Officina Bellini unlocks KnowledgeManager R&D!")

	# 3) Verifica soglie Reputazione & EUR
	GameManager.reputation_points = 10
	EconomyManager.balance = 5000.0
	check(not KnowledgeManager.study("web_architecture"), "R&D study rejected when Reputation < rep_req (10 < 40)")

	GameManager.reputation_points = 160
	EconomyManager.balance = 50.0
	check(not KnowledgeManager.study("web_architecture"), "R&D study rejected when balance < cost (50 < 380)")

	# 4) Studio progressivo & verifica moltiplicatori (WebForge speed, Rack hosting, Payout specialistico)
	EconomyManager.balance = 10000.0
	ServerRackManager.unlock_server_rack()
	ServerRackManager.rack_tier = 2
	ServerRackManager.hosted_domains.clear()
	ServerRackManager.add_hosted_client("test.it", "Client Test", 100.0)
	var base_rack_rev: float = ServerRackManager.calculate_daily_hosting_revenue()
	check(is_equal_approx(base_rack_rev, 100.0), "Baseline Rack hosting revenue before cloud_devops == € 100.00 (got %.2f)" % base_rack_rev)

	var bal_pre_study: float = EconomyManager.balance
	check(KnowledgeManager.study("web_architecture") and KnowledgeManager.get_rank("web_architecture") == 1,
		"Studied web_architecture Lv.1 (cost €380)")
	check(is_equal_approx(bal_pre_study - EconomyManager.balance, 380.0), "EconomyManager deducted €380 for web_architecture Lv.1")
	check(is_equal_approx(KnowledgeManager.get_webforge_speed_bonus(), 0.30), "web_architecture Lv.1 grants -0.30s WebForge speed bonus")

	ContractManager.advance_tutorial_to_in_progress()
	var wf: Control = WebForgeScene.instantiate() as Control
	add_child(wf)
	await get_tree().process_frame
	EventBus.minigame_started.emit("web_forge")
	await get_tree().process_frame
	check(is_equal_approx(wf.compile_target_duration, 5.2),
		"WebForge compile duration reduced from 5.5s to 5.2s with web_architecture Lv.1 (got %.2fs)" % wf.compile_target_duration)
	wf.queue_free()
	await get_tree().process_frame

	check(KnowledgeManager.study("cloud_devops") and KnowledgeManager.get_rank("cloud_devops") == 1,
		"Studied cloud_devops Lv.1 (cost €420)")
	var rack_rev_rd: float = ServerRackManager.calculate_daily_hosting_revenue()
	check(is_equal_approx(rack_rev_rd, 110.0),
		"cloud_devops Lv.1 boosts ServerRackManager hosting revenue +10%% (€100 -> €110, got %.2f)" % rack_rev_rd)

	check(KnowledgeManager.study("cyber_governance") and KnowledgeManager.study("ai_automation"),
		"Studied cyber_governance Lv.1 & ai_automation Lv.1")

	# 5) Generazione commessa specialistica AI & Payout R&D (+12% a Lv.1)
	var spec_c: Dictionary = ContractGenerator.generate_specialty_contract("ai_automation", 77, 1.0)
	check(bool(spec_c.get("is_knowledge_specialty", false)) and str(spec_c.get("knowledge_track", "")) == "ai_automation",
		"ContractGenerator creates tagged specialty contract for unlocked 'ai_automation' track")
	check(is_equal_approx(KnowledgeManager.get_contract_payout_mult(spec_c), 1.12),
		"Matching AI contract receives 1.12x R&D payout multiplier at Lv.1")

	var has_spec_in_pool: bool = false
	for mc in ContractManager.marketplace_contracts:
		if mc is Dictionary and bool(mc.get("is_knowledge_specialty", false)):
			has_spec_in_pool = true
			break
	check(has_spec_in_pool, "Studying R&D auto-injects specialty contracts into Freelance Marketplace pool")

	spec_c["id"] = "test_rd_ai_spec"
	spec_c["budget"] = 1000.0
	spec_c["fame_bonus"] = 1.0
	spec_c["status"] = "in_progress"
	ContractManager.active_contracts["test_rd_ai_spec"] = spec_c
	var bal_pre_pay: float = EconomyManager.balance
	check(ContractManager.complete_marketplace_contract("test_rd_ai_spec"), "Completed specialty AI contract")
	check(is_equal_approx(EconomyManager.balance - bal_pre_pay, 1120.0),
		"Completed specialty AI contract paid €1120.00 (1000 * 1.12x R&D, got %.2f)" % (EconomyManager.balance - bal_pre_pay))

	# 6) Save/Load Roundtrip + New Game Reset
	var saved_rd: Dictionary = KnowledgeManager.ranks.duplicate()
	check(SaveManager.save_game(), "Saved game with active KnowledgeManager R&D ranks")
	KnowledgeManager.reset()
	check(KnowledgeManager.get_total_rank() == 0, "KnowledgeManager.reset() zeroes all ranks before Load")
	check(SaveManager.load_game(), "Loaded saved game with KnowledgeManager R&D ranks")
	check(KnowledgeManager.ranks == saved_rd and KnowledgeManager.get_total_rank() == 4,
		"KnowledgeManager ranks cleanly restored across Save/Load (total=%d)" % KnowledgeManager.get_total_rank())

	GameManager.start_new_game()
	check(KnowledgeManager.get_total_rank() == 0 and not KnowledgeManager.is_unlocked(),
		"GameManager.start_new_game() resets KnowledgeManager ranks to 0 and locks R&D cleanly")

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
