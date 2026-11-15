class_name VillageBuilder
extends RefCounted
## VillageBuilder - Costruttore completo del Borgo San Carlo (stile semi-cartoon unico, zero clipping).

const SHOP_SCRIPT = preload("res://scripts/world/shop_interactable.gd")
const REST_SCRIPT = preload("res://scripts/world/rest_interactable.gd")
const FRIDGE_SCRIPT = preload("res://scripts/world/fridge_interactable.gd")
const MARIO_SCRIPT = preload("res://scripts/world/mario_interactable.gd")
const ELENA_SCRIPT = preload("res://scripts/world/elena_interactable.gd")
const DAVIDE_SCRIPT = preload("res://scripts/world/davide_interactable.gd")
const BELLINI_SCRIPT = preload("res://scripts/world/bellini_interactable.gd")
const FACTORY_ITEM_SCRIPT = preload("res://scripts/world/factory_interactable.gd")
const FACTORY_SYNC_SCRIPT = preload("res://scripts/world/factory_venue_sync.gd")
const SIDEJOB_SCRIPT = preload("res://scripts/world/side_job_interactable.gd")
const OGR_GATE_SYNC_SCRIPT = preload("res://scripts/world/ogr_gate_sync.gd")
const OGR_VIALE_SCRIPT = preload("res://scripts/world/ogr_viale_interactable.gd")

# ------------------------------------------------------------------ STUDIO
static func build_studio(studio: Node3D) -> void:
	if studio.has_node("BorgoStudio"):
		return
	# Rimuove la vecchia stanza e le vecchie collisioni grezze
	for old_name in ["StudioRoomModel", "Collisions"]:
		var old := studio.get_node_or_null(old_name)
		if old:
			old.name = old_name + "_Legacy"
			old.queue_free()

	var sm := StyleMesh.new()
	VillageProps.add_studio_shell(sm)
	VillageProps.add_bed(sm, Vector3(3.10, 0.0, -0.75), 0.0)
	VillageProps.add_fridge(sm, Vector3(-3.22, 0.0, 1.98), PI * 0.5)
	# Tavola legno e insegna esterna ben sopra la tenda blu (tenda arriva a Y=2.59)
	sm.box("wood_dark", Vector3(0, 2.94, 2.79), Vector3(3.4, 0.42, 0.08))

	var holder := VillageProps.spawn_mesh_and_collisions(studio, "BorgoStudio", sm, "wood")

	# Insegna esterna sopra la porta dello Studio
	_add_sign(holder, "STUDIO TECH · Borgo San Carlo", Vector3(0, 2.94, 2.85), 0.0, 26, Color(1.0, 0.94, 0.74))

	# Area interattiva Letto (riposo)
	var rest_body := StaticBody3D.new()
	rest_body.name = "BedInteractable"
	rest_body.position = Vector3(3.10, 0.35, -0.75)
	rest_body.set_script(REST_SCRIPT)
	var rest_cs := CollisionShape3D.new()
	var rest_box := BoxShape3D.new()
	rest_box.size = Vector3(1.0, 0.65, 1.9)
	rest_cs.shape = rest_box
	rest_body.add_child(rest_cs)
	holder.add_child(rest_body)

	# Area interattiva Frigo
	var fridge_body := StaticBody3D.new()
	fridge_body.name = "FridgeInteractable"
	fridge_body.position = Vector3(-3.22, 0.72, 1.98)
	fridge_body.set_script(FRIDGE_SCRIPT)
	var fridge_cs := CollisionShape3D.new()
	var fridge_box := BoxShape3D.new()
	fridge_box.size = Vector3(0.75, 1.45, 0.75)
	fridge_cs.shape = fridge_box
	fridge_body.add_child(fridge_cs)
	holder.add_child(fridge_body)

# ------------------------------------------------------------------ PIZZERIA DA MARIO
static func build_pizzeria(pizzeria: Node3D) -> void:
	if pizzeria.has_node("BorgoPizzeria"):
		return
	for ch in pizzeria.get_children():
		ch.name = ch.name + "_Legacy"
		ch.queue_free()

	var sm := StyleMesh.new()
	VillageProps.add_shop_building(sm, Vector3.ZERO, 8.2, 6.4, {
		"wall": "plaster_terracotta",
		"floor": "tile_rc",
		"awning": "awning_red",
		"roof": "roof_terracotta",
		"counter_top": "stone_counter",
		"counter_base": "wood_plank"
	})
	# Forno a legna cupolato e fiamme sul fondo-sinistra
	VillageProps.add_pizzeria_oven(sm, Vector3(-2.85, 0.04, -2.20), 0.30)
	# Tavolini rotondi rossi con piedistallo in ghisa e sedie ai lati (corridoio ingresso libero!)
	VillageProps.add_pizzeria_table_set(sm, Vector3(-2.35, 0.04, 1.35), 0.15)
	VillageProps.add_pizzeria_table_set(sm, Vector3(2.35, 0.04, 1.35), -0.15)
	# Lavagna menu e mensola oli/vini sulla parete posteriore destra
	sm.box("wood_dark", Vector3(0.45, 2.02, -2.92), Vector3(2.15, 0.96, 0.05))
	sm.box("iron", Vector3(0.45, 2.02, -2.89), Vector3(1.92, 0.78, 0.02))
	sm.box("wood_dark", Vector3(2.85, 1.48, -2.80), Vector3(1.32, 0.07, 0.28))
	for bi in range(4):
		var b_mat: String = ["jar_green", "jar_jam", "tin_gold", "jar_green"][bi]
		sm.cyl(b_mat, Vector3(2.40 + float(bi) * 0.28, 1.52, -2.80), 0.045, 0.036, 0.24, 8)

	var holder := VillageProps.spawn_mesh_and_collisions(pizzeria, "BorgoPizzeria", sm, "tile")
	_add_sign(holder, "PIZZERIA DA MARIO", Vector3(0, 3.12, 3.37), 0.0, 34, Color(1.0, 0.92, 0.65))
	VillageProps.add_oven_smoke_particles(holder, Vector3(-2.64, 1.58, -1.52))

	# Mario NPC sulla pedana rialzata dietro il bancone (rif. 2: camicia lino crema mezza manica, grembiule rosso, toque pieghettato)
	var mario := _spawn_npc(pizzeria, "MarioNPC", Vector3(0.0, 0.18, -1.95), 0.0, MARIO_SCRIPT, {
		"shirt": "shirt_linen_cream", "pants": "pants_charcoal", "shoes": "shoe_black",
		"hair": "hair_brown", "iris": "iris_brown",
		"apron": "apron_red", "hat": "chef", "mustache": true, "short_sleeves": true, "neck_style": "open_v"
	}, "Mario Esposito\n★ Pizzeria Da Mario ★", Color(1.0, 0.9, 0.3))
	mario.name = "MarioNPC"

	# Cassa / Menu Pizzeria per comprare cibo (a fianco sul bancone)
	_spawn_shop_trigger(holder, "PizzeriaShop", Vector3(1.5, 0.96, -1.15), "pizzeria", "Pizzeria Da Mario", Vector3(1.1, 0.9, 0.9))

	# Luce calda interna, riverbero arancione vivo del forno a legna & key/rim light ritratto su Mario
	_add_omni(holder, Vector3(0, 2.52, 0.75), Color(1.0, 0.89, 0.74), 0.36, 9.5)
	_add_omni(holder, Vector3(-2.35, 1.12, -1.55), Color(1.0, 0.58, 0.22), 1.12, 5.2)

# ------------------------------------------------------------------ BORGO SAN CARLO + PARCO VALENTINO + VALDOCCO & MERCATO OGR + BORGO PO
static func build_village(street: Node3D) -> void:
	if street.has_node("BorgoTerrain"):
		return
	for ch in street.get_children():
		ch.name = ch.name + "_Legacy"
		ch.queue_free()

	# 1. Terreno e pavimentazioni a strati non sovrapposti (tutti top a Y=0.0, spessore sotto Y=0)
	var terrain_sm := StyleMesh.new()
	# Prato di base esteso da Parco Valentino Ovest (-68) a OGR Est (+132), diviso attorno al letto del Fiume Po (Z=65.8..77.2)
	terrain_sm.box("grass", Vector3(32.0, -0.24, 21.9), Vector3(200.0, 0.40, 87.8), {"col": true, "surface": "grass"})
	terrain_sm.box("grass", Vector3(32.0, -0.24, 87.6), Vector3(200.0, 0.40, 20.8), {"col": true, "surface": "grass"})
	# Via del Borgo (Z: 2.5 .. 13.5, X: -4.2 .. 4.2) top Y=0.0
	terrain_sm.box("cobble", Vector3(0, -0.05, 8.0), Vector3(8.4, 0.10, 11.2), {"col": true, "surface": "stone"})
	# Piazzetta San Carlo (Z: 13.5 .. 27.5, X: -10.5 .. 10.5) top Y=0.0
	terrain_sm.box("cobble", Vector3(0, -0.05, 20.5), Vector3(21.0, 0.10, 14.0), {"col": true, "surface": "stone"})
	# Marciapiedi laterali in lastre davanti allo Studio e ai negozi
	terrain_sm.box("slabs", Vector3(0, -0.04, 3.6), Vector3(7.4, 0.10, 2.0), {"col": true, "surface": "stone"})
	terrain_sm.box("slabs", Vector3(-4.5, -0.04, 8.5), Vector3(1.6, 0.10, 9.5), {"col": true, "surface": "stone"})
	terrain_sm.box("slabs", Vector3(4.5, -0.04, 8.5), Vector3(1.6, 0.10, 9.5), {"col": true, "surface": "stone"})
	# Piazzole parcheggio in asfalto libere dagli edifici
	terrain_sm.box("asphalt", Vector3(-15.2, -0.045, 11.8), Vector3(7.6, 0.09, 5.4), {"col": true, "surface": "asphalt"})
	terrain_sm.box("asphalt", Vector3(15.2, -0.045, 11.8), Vector3(7.6, 0.09, 5.4), {"col": true, "surface": "asphalt"})
	# Sentieri parchetto San Carlo & Raccordo Parco Valentino Ovest (varco ovest Z=36.8!)
	terrain_sm.box("gravel", Vector3(-7.5, -0.04, 30.0), Vector3(4.2, 0.08, 6.0), {"col": true, "surface": "stone"})
	terrain_sm.box("gravel", Vector3(-11.8, -0.04, 35.8), Vector3(4.8, 0.08, 4.4), {"col": true, "surface": "stone"})
	terrain_sm.box("gravel", Vector3(-31.0, -0.04, 36.8), Vector3(38.0, 0.08, 4.4), {"col": true, "surface": "stone"})
	terrain_sm.box("gravel", Vector3(-37.5, -0.04, 27.0), Vector3(4.2, 0.08, 19.6), {"col": true, "surface": "stone"})
	terrain_sm.box("gravel", Vector3(-42.5, -0.04, 21.2), Vector3(9.0, 0.08, 3.2), {"col": true, "surface": "stone"})
	terrain_sm.box("gravel", Vector3(-42.5, -0.04, 32.5), Vector3(9.0, 0.08, 3.2), {"col": true, "surface": "stone"})

	# Raccordo in acciottolato + Strada Asfaltata Est verso Borgo Valdocco (asse Z=28.0)
	terrain_sm.box("cobble", Vector3(8.25, -0.05, 29.1), Vector3(4.5, 0.10, 3.2), {"col": true, "surface": "stone"})
	terrain_sm.box("cobble", Vector3(17.25, -0.05, 28.0), Vector3(13.5, 0.10, 5.4), {"col": true, "surface": "stone"})
	terrain_sm.box("asphalt", Vector3(43.0, -0.045, 28.0), Vector3(38.0, 0.09, 5.4), {"col": true, "surface": "asphalt"})
	# Cordoli individuali in pietra/granito smussati lungo entrambi i lati di Viale Est (collisione continua preservata)
	terrain_sm.add_collider_box(Vector3(43.0, 0.07, 25.05), Vector3(37.6, 0.14, 0.42), 0.0, "stone")
	terrain_sm.add_collider_box(Vector3(43.0, 0.07, 30.95), Vector3(37.6, 0.14, 0.42), 0.0, "stone")
	for bi in range(47):
		var cx := 24.6 + float(bi) * 0.80
		var curb_k := "stone_trim" if bi % 7 == 2 else "slabs"
		terrain_sm.beveled_curb_block(curb_k, Vector3(cx, 0.0, 25.05), 0.76, 0.42, 0.14, 0.0)
		var curb_k2 := "stone_trim" if (bi + 3) % 7 == 2 else "slabs"
		terrain_sm.beveled_curb_block(curb_k2, Vector3(cx, 0.0, 30.95), 0.76, 0.42, 0.14, 0.0)
	for rx in range(26, 61, 4):
		terrain_sm.box("road_line", Vector3(float(rx), 0.006, 28.0), Vector3(1.9, 0.012, 0.18))
	terrain_sm.box("gravel", Vector3(41.5, -0.04, 22.8), Vector3(8.6, 0.08, 3.8), {"col": true, "surface": "stone"})

	# Piazza di Borgo Valdocco + Connessione Nord & Piazza del Mercato / Coworking OGR
	terrain_sm.box("cobble", Vector3(71.0, -0.05, 28.0), Vector3(18.0, 0.10, 20.0), {"col": true, "surface": "stone"})
	terrain_sm.box("cobble", Vector3(79.0, -0.05, 16.0), Vector3(6.4, 0.10, 5.0), {"col": true, "surface": "stone"})
	terrain_sm.box("cobble", Vector3(78.5, -0.05, 5.65), Vector3(19.0, 0.10, 17.7), {"col": true, "surface": "stone"})
	terrain_sm.box("slabs", Vector3(64.8, -0.04, 11.4), Vector3(9.0, 0.10, 3.6), {"col": true, "surface": "stone"})
	terrain_sm.box("slabs", Vector3(92.25, -0.04, 2.75), Vector3(8.7, 0.08, 6.2), {"col": true, "surface": "stone"})

	# BORGO PO / LUNGO PO (varco Sud X=5.0..11.4, Piazza Borgo Po, Viale Lungo Po, Promenade & Molo sul Po)
	terrain_sm.box("cobble", Vector3(8.2, -0.05, 36.25), Vector3(4.4, 0.10, 14.5), {"col": true, "surface": "stone"})
	terrain_sm.box("cobble", Vector3(8.2, -0.05, 49.15), Vector3(14.4, 0.10, 12.3), {"col": true, "surface": "stone"})
	terrain_sm.box("slabs", Vector3(-13.5, -0.04, 53.2), Vector3(8.6, 0.08, 4.2), {"col": true, "surface": "stone"})
	terrain_sm.box("slabs", Vector3(24.0, -0.04, 53.2), Vector3(7.6, 0.08, 4.2), {"col": true, "surface": "stone"})
	terrain_sm.box("slabs", Vector3(41.5, -0.04, 53.2), Vector3(7.6, 0.08, 4.2), {"col": true, "surface": "stone"})
	terrain_sm.box("asphalt", Vector3(16.0, -0.045, 58.0), Vector3(77.0, 0.09, 5.4), {"col": true, "surface": "asphalt"})
	for rx_s in range(-19, 53, 4):
		if rx_s >= 5 and rx_s <= 11:
			continue
		terrain_sm.box("road_line", Vector3(float(rx_s), 0.006, 58.0), Vector3(1.9, 0.012, 0.18))
	for zx in [6.4, 7.6, 8.8, 10.0]:
		terrain_sm.box("road_line", Vector3(zx, 0.007, 58.0), Vector3(0.45, 0.012, 3.6))
	# Cordoli sul lato Nord di Viale Lungo Po (lascia aperti Piazza Borgo Po X=1..15.4 & sagrati I3P/Droni/Torrefazione)
	for curb_seg in [[-18.0, 10.0], [19.2, 7.2]]:
		var c_cx := float(curb_seg[0])
		var c_w := float(curb_seg[1])
		terrain_sm.add_collider_box(Vector3(c_cx, 0.07, 55.12), Vector3(c_w, 0.14, 0.36), 0.0, "stone")
		terrain_sm.beveled_curb_block("stone_trim", Vector3(c_cx, 0.0, 55.12), c_w, 0.36, 0.14, 0.0)
	terrain_sm.add_collider_box(Vector3(50.2, 0.07, 55.12), Vector3(8.4, 0.14, 0.36), 0.0, "stone")
	terrain_sm.beveled_curb_block("stone_trim", Vector3(50.2, 0.0, 55.12), 8.4, 0.36, 0.14, 0.0)

	# Promenade pedonale sui Murazzi / Lungo Po + Balustrade + Molo sul Po in legno + Fiume Po
	terrain_sm.box("slabs", Vector3(16.0, -0.04, 63.25), Vector3(80.0, 0.08, 5.1), {"col": true, "surface": "stone"})
	terrain_sm.box("ashlar", Vector3(32.0, -0.45, 65.85), Vector3(200.0, 0.85, 0.6))
	terrain_sm.box("ashlar", Vector3(32.0, -0.45, 77.25), Vector3(200.0, 0.85, 0.8))
	terrain_sm.box("stone_dark", Vector3(32.0, -0.66, 71.5), Vector3(200.0, 0.24, 11.8))
	terrain_sm.box("water", Vector3(32.0, -0.32, 71.5), Vector3(200.0, 0.06, 11.4))
	# Balustrade lungofiume divise all'imbocco del Molo sul Po (X=13.8..18.2 aperto!)
	_add_garden_wall(terrain_sm, Vector3(-5.1, 0.50, 65.8), Vector3(37.8, 1.0, 0.42))
	_add_garden_wall(terrain_sm, Vector3(37.1, 0.50, 65.8), Vector3(37.8, 1.0, 0.42))
	# Molo sul Po (asse X=16.0, Z=65.8..71.2, superficie legno per passi!) + barchetta ormeggiata
	terrain_sm.box("wood_light", Vector3(16.0, 0.02, 68.5), Vector3(4.4, 0.08, 5.4), {"col": true, "surface": "wood"})
	for px_m in [14.0, 18.0]:
		for pz_m in [66.2, 68.5, 70.9]:
			terrain_sm.cyl("wood_dark", Vector3(px_m, -0.60, pz_m), 0.12, 0.10, 1.48, 8)
		terrain_sm.box("wood_dark", Vector3(px_m, 0.46, 68.55), Vector3(0.10, 0.08, 4.90), {"col": true, "surface": "wood"})
	terrain_sm.box("wood_dark", Vector3(16.0, 0.46, 71.08), Vector3(4.2, 0.08, 0.10), {"col": true, "surface": "wood"})
	terrain_sm.add_collider_box(Vector3(13.8, 0.75, 68.55), Vector3(0.22, 1.2, 5.2), 0.0, "wood")
	terrain_sm.add_collider_box(Vector3(18.2, 0.75, 68.55), Vector3(0.22, 1.2, 5.2), 0.0, "wood")
	terrain_sm.add_collider_box(Vector3(16.0, 0.75, 71.18), Vector3(4.6, 1.2, 0.25), 0.0, "wood")
	VillageProps.add_riverside_rowboat(terrain_sm, Vector3(20.6, -0.34, 69.2), 0.28)

	# Muretti perimetrali in mattoni & intonaco San Carlo (varco Est Z=24.8..31.2, varco Ovest Z=33.6..40.0, varco Sud Borgo Po X=5.0..11.4)
	_add_garden_wall(terrain_sm, Vector3(0, 0.65, -9.0), Vector3(48.0, 1.3, 0.5))
	_add_garden_wall(terrain_sm, Vector3(-9.5, 0.65, 42.0), Vector3(29.0, 1.3, 0.5))
	_add_garden_wall(terrain_sm, Vector3(17.7, 0.65, 42.0), Vector3(12.6, 1.3, 0.5))
	_add_garden_wall(terrain_sm, Vector3(-24.0, 0.65, 12.3), Vector3(0.5, 1.3, 42.6))
	_add_garden_wall(terrain_sm, Vector3(-24.0, 0.65, 41.0), Vector3(0.5, 1.3, 2.0))
	_add_garden_wall(terrain_sm, Vector3(24.0, 0.65, 7.9), Vector3(0.5, 1.3, 33.8))
	_add_garden_wall(terrain_sm, Vector3(24.0, 0.65, 36.6), Vector3(0.5, 1.3, 10.8))

	# Muretti perimetrali Borgo Po / Lungo Po (X: -24..56, Z: 42..66)
	_add_garden_wall(terrain_sm, Vector3(40.0, 0.65, 42.0), Vector3(32.0, 1.3, 0.5))
	_add_garden_wall(terrain_sm, Vector3(-24.0, 0.65, 54.0), Vector3(0.5, 1.3, 24.0))
	_add_garden_wall(terrain_sm, Vector3(56.0, 0.65, 54.0), Vector3(0.5, 1.3, 24.0))

	# Muretti Parco Valentino Ovest (X: -56 .. -24, Z: 12 .. 42)
	_add_garden_wall(terrain_sm, Vector3(-40.0, 0.65, 12.0), Vector3(32.0, 1.3, 0.5))
	_add_garden_wall(terrain_sm, Vector3(-40.0, 0.65, 42.0), Vector3(32.0, 1.3, 0.5))
	_add_garden_wall(terrain_sm, Vector3(-56.0, 0.65, 27.0), Vector3(0.5, 1.3, 30.0))

	# Muretti Borgo Valdocco (muro Nord diviso attorno al varco X=75.8..82.2!)
	_add_garden_wall(terrain_sm, Vector3(67.4, 0.65, 14.0), Vector3(16.8, 1.3, 0.5))
	_add_garden_wall(terrain_sm, Vector3(89.6, 0.65, 14.0), Vector3(14.8, 1.3, 0.5))
	_add_garden_wall(terrain_sm, Vector3(78.0, 0.65, 42.0), Vector3(38.0, 1.3, 0.5))
	_add_garden_wall(terrain_sm, Vector3(96.75, 0.65, 28.5), Vector3(0.5, 1.3, 27.0))
	_add_garden_wall(terrain_sm, Vector3(59.0, 0.65, 19.4), Vector3(0.5, 1.3, 10.8))
	_add_garden_wall(terrain_sm, Vector3(59.0, 0.65, 36.6), Vector3(0.5, 1.3, 10.8))

	# Muretti Piazza Mercato Nord & Ingresso OGR Torino (X: 59 .. 96.2, Z: -10 .. 15, varco OGR Z=0.35..5.15)
	_add_garden_wall(terrain_sm, Vector3(78.0, 0.65, -10.0), Vector3(38.0, 1.3, 0.5))
	_add_garden_wall(terrain_sm, Vector3(59.0, 0.65, 2.0), Vector3(0.5, 1.3, 24.0))
	_add_garden_wall(terrain_sm, Vector3(96.20, 0.65, -4.825), Vector3(0.44, 1.3, 10.35))
	_add_garden_wall(terrain_sm, Vector3(96.20, 0.65, 10.075), Vector3(0.44, 1.3, 9.85))

	# Ciuffi d'erba e fiori di campo (zero collider) lungo muretti, cordoli, parco & lastricato
	_scatter_grass_tufts(terrain_sm)

	# Archi stradali & parchi + cartelli + pozzo storico
	VillageProps.add_archway_gate(terrain_sm, Vector3(24.0, 0.0, 28.0), 6.4, 3.7, PI * 0.5)
	VillageProps.add_archway_gate(terrain_sm, Vector3(-24.0, 0.0, 36.8), 6.4, 3.7, PI * 0.5)
	VillageProps.add_archway_gate(terrain_sm, Vector3(79.0, 0.0, 14.0), 6.4, 3.7, 0.0)
	VillageProps.add_archway_gate(terrain_sm, Vector3(8.2, 0.0, 42.0), 6.4, 3.7, 0.0)
	VillageProps.add_road_sign(terrain_sm, Vector3(21.8, 0.0, 24.0), -PI * 0.5)
	VillageProps.add_road_sign(terrain_sm, Vector3(61.5, 0.0, 24.4), -PI * 0.5)
	VillageProps.add_road_sign(terrain_sm, Vector3(-21.2, 0.0, 32.8), PI * 0.5)
	VillageProps.add_road_sign(terrain_sm, Vector3(74.4, 0.0, 15.8), 0.0)
	VillageProps.add_road_sign(terrain_sm, Vector3(4.5, 0.0, 39.8), 0.0)
	VillageProps.add_well(terrain_sm, Vector3(68.5, 0.0, 22.8))

	# Corona lontana delle Alpi Piemontesi + alberi sullo sfondo fuori dai muretti perimetrali & oltre Po
	VillageProps.add_alpine_backdrop(terrain_sm)
	for tx in [-52.0, -40.0, -28.0]:
		VillageProps.add_tree(terrain_sm, Vector3(tx, 0.0, 45.5), int(absf(tx)) + 30, 1.45)
	for tx_po in [-20.0, -8.0, 4.0, 16.0, 28.0, 40.0, 52.0]:
		VillageProps.add_tree(terrain_sm, Vector3(tx_po, 0.0, 80.2), int(absf(tx_po)) + 150, 1.45)
	for tx2 in [-16.0, -4.0, 8.0, 20.0]:
		VillageProps.add_tree(terrain_sm, Vector3(tx2, 0.0, -12.5), int(absf(tx2)) + 60, 1.35)
	for px in [-52.0, -39.0, -29.0]:
		VillageProps.add_tree(terrain_sm, Vector3(px, 0.0, 9.0), int(absf(px)) + 88, 1.35)
	for pz in [15.5, 27.5, 39.5]:
		VillageProps.add_tree(terrain_sm, Vector3(-59.5, 0.0, pz), int(pz) + 120, 1.45)
	for vx in [32.0, 44.0, 56.0]:
		VillageProps.add_tree(terrain_sm, Vector3(vx, 0.0, 10.5), int(vx) + 12, 1.35)
	for vx2 in [68.0, 80.0, 92.0]:
		VillageProps.add_tree(terrain_sm, Vector3(vx2, 0.0, -13.2), int(vx2) + 74, 1.35)
	for vx3 in [68.0, 80.0, 92.0]:
		VillageProps.add_tree(terrain_sm, Vector3(vx3, 0.0, 45.5), int(vx3) + 44, 1.40)

	VillageProps.spawn_mesh_and_collisions(street, "BorgoTerrain", terrain_sm, "stone")

	_add_sign(street, "➔ BORGO VALDOCCO · OFFICINA BELLINI", Vector3(23.72, 3.52, 28.0), -PI * 0.5, 24, Color(1.0, 0.90, 0.52))
	_add_sign(street, "BORGO SAN CARLO ➔", Vector3(24.28, 3.52, 28.0), PI * 0.5, 24, Color(1.0, 0.90, 0.52))
	_add_sign(street, "← PARCO VALENTINO · VILLE", Vector3(-23.72, 3.52, 36.8), PI * 0.5, 24, Color(0.74, 0.96, 0.72))
	_add_sign(street, "BORGO SAN CARLO ➔", Vector3(-24.28, 3.52, 36.8), -PI * 0.5, 24, Color(1.0, 0.90, 0.52))
	_add_sign(street, "▲ MERCATO NORD · POSTE · OGR", Vector3(79.0, 3.52, 14.28), 0.0, 22, Color(0.84, 0.94, 1.0))
	_add_sign(street, "▼ BORGO VALDOCCO · OFFICINA", Vector3(79.0, 3.52, 13.72), PI, 22, Color(1.0, 0.90, 0.52))
	_add_sign(street, "▼ BORGO PO · LUNGO PO · I3P", Vector3(8.2, 3.52, 41.72), PI, 22, Color(0.68, 0.94, 1.0))
	_add_sign(street, "▲ BORGO SAN CARLO", Vector3(8.2, 3.52, 42.28), 0.0, 22, Color(1.0, 0.90, 0.52))
	_add_sign(street, "BORGO VALDOCCO ➔\nOfficina Bellini (40m)", Vector3(21.70, 2.05, 24.0), -PI * 0.5, 20, Color(1.0, 0.95, 0.80))
	_add_sign(street, "★ BORGO VALDOCCO ★\nOfficina Bellini", Vector3(61.40, 2.05, 24.4), -PI * 0.5, 20, Color(1.0, 0.95, 0.72))
	_add_sign(street, "← PARCO VALENTINO\nLaghetto & Ville", Vector3(-21.10, 2.05, 32.8), PI * 0.5, 20, Color(0.82, 0.98, 0.78))
	_add_sign(street, "MERCATO & OGR ➔\nUfficio Postale", Vector3(74.4, 2.05, 15.92), 0.0, 20, Color(0.88, 0.96, 1.0))
	_add_sign(street, "BORGO PO & FIUME PO ▼\nI3P · Lab Droni · Molo", Vector3(4.5, 2.05, 39.68), PI, 19, Color(0.76, 0.95, 1.0))
	_add_sign(street, "★ MOLO SUL PO ★", Vector3(16.0, 1.15, 65.80), PI, 22, Color(0.84, 0.95, 1.0))

	# 2. Contenitore Collisions compatibilità
	var cols_node := Node3D.new()
	cols_node.name = "Collisions"
	street.add_child(cols_node)

	# 3. Negozi principali sulla Piazzetta (CafeVenue & TechShopVenue con nomi preservati)
	var cafe_venue := Node3D.new()
	cafe_venue.name = "CafeVenue"
	cafe_venue.position = Vector3(-13.8, 0, 20.5)
	cafe_venue.rotation.y = PI * 0.5
	street.add_child(cafe_venue)
	var cafe_sm := StyleMesh.new()
	VillageProps.add_shop_building(cafe_sm, Vector3.ZERO, 7.6, 5.8, {
		"wall": "plaster_cream", "floor": "tile_cafe", "awning": "awning_red", "roof": "roof_slate"
	})
	# Macchina espresso + macinacaffè, vetrinetta cornetti in vetro/acciaio, lavagnetta menu, quadri e tavolini interni sotto vetrina
	cafe_sm.box("steel", Vector3(1.15, 1.18, -1.04), Vector3(0.56, 0.44, 0.42))
	cafe_sm.box("iron", Vector3(1.15, 1.04, -0.82), Vector3(0.46, 0.14, 0.10))
	cafe_sm.box("iron", Vector3(0.58, 1.06, -1.06), Vector3(0.24, 0.22, 0.24))
	cafe_sm.cyl("glass_cool", Vector3(0.58, 1.18, -1.06), 0.11, 0.08, 0.22, 10)
	cafe_sm.cyl("brass", Vector3(0.58, 1.40, -1.06), 0.11, 0.11, 0.03, 10)
	# Vetrinetta pasticceria con brioches/cornetti sul lato sinistro del banco
	cafe_sm.box("steel", Vector3(-1.45, 0.96, -1.04), Vector3(0.84, 0.04, 0.46))
	cafe_sm.box("steel", Vector3(-1.45, 1.16, -1.25), Vector3(0.84, 0.36, 0.03))
	cafe_sm.box("glass_cool", Vector3(-1.45, 1.16, -0.82), Vector3(0.82, 0.34, 0.025))
	cafe_sm.box("glass_cool", Vector3(-1.45, 1.34, -1.04), Vector3(0.84, 0.025, 0.44))
	cafe_sm.box("glass_cool", Vector3(-1.86, 1.15, -1.04), Vector3(0.025, 0.34, 0.42))
	cafe_sm.box("glass_cool", Vector3(-1.04, 1.15, -1.04), Vector3(0.025, 0.34, 0.42))
	for px_c in [-1.68, -1.45, -1.22]:
		cafe_sm.ellipsoid("bread", Vector3(px_c, 1.02, -1.02), Vector3(0.085, 0.048, 0.065), 4, 8)
	cafe_sm.cyl("lemon", Vector3(-1.55, 1.15, -1.06), 0.08, 0.08, 0.045, 10)
	cafe_sm.box("wood_dark", Vector3(0.0, 2.05, -2.62), Vector3(2.2, 0.92, 0.06))
	cafe_sm.box("iron", Vector3(0.0, 2.05, -2.58), Vector3(1.96, 0.74, 0.03))
	cafe_sm.box("wood_dark", Vector3(-1.95, 1.98, -2.62), Vector3(0.82, 0.64, 0.05))
	cafe_sm.box("plaster_ochre", Vector3(-1.95, 1.98, -2.59), Vector3(0.68, 0.50, 0.02))
	cafe_sm.box("wood_dark", Vector3(1.75, 1.35, -2.48), Vector3(1.45, 0.08, 0.34))
	cafe_sm.cyl("tin_red", Vector3(1.25, 1.47, -2.48), 0.08, 0.08, 0.16, 10)
	cafe_sm.cyl("tin_gold", Vector3(1.48, 1.48, -2.48), 0.08, 0.08, 0.18, 10)
	cafe_sm.cyl("tin_blue", Vector3(2.08, 1.47, -2.48), 0.08, 0.08, 0.16, 10)
	for cx in [1.35, 1.75, 2.15]:
		cafe_sm.cyl("apron_white", Vector3(cx, 1.39, -2.48), 0.07, 0.08, 0.14, 8)
	for ix in [-2.68, 2.68]:
		cafe_sm.cyl("iron", Vector3(ix, 0.04, 1.18), 0.24, 0.18, 0.05, 10)
		cafe_sm.cyl("iron", Vector3(ix, 0.09, 1.18), 0.04, 0.04, 0.66, 8)
		cafe_sm.cyl("stone_counter", Vector3(ix, 0.75, 1.18), 0.42, 0.42, 0.045, 14)
		cafe_sm.cyl("apron_white", Vector3(ix, 0.80, 1.18), 0.05, 0.06, 0.09, 8)
	VillageProps.add_table_set(cafe_sm, Vector3(-2.4, 0.0, 4.3), "fabric_cream")
	VillageProps.add_parasol(cafe_sm, Vector3(-2.4, 0.0, 4.3), "fabric_cream")
	VillageProps.add_table_set(cafe_sm, Vector3(2.4, 0.0, 4.3), "fabric_cream")
	VillageProps.add_parasol(cafe_sm, Vector3(2.4, 0.0, 4.3), "fabric_cream")
	VillageProps.spawn_mesh_and_collisions(cafe_venue, "CafeMesh", cafe_sm, "tile")
	_add_sign(cafe_venue, "CAFFÈ SAN CARLO", Vector3(0, 3.12, 3.06), 0.0, 32, Color(1.0, 0.92, 0.70))
	var elena := _spawn_npc(cafe_venue, "ElenaNPC", Vector3(-0.7, 0.18, -1.86), 0.0, ELENA_SCRIPT, {
		"shirt": "shirt_burgundy", "pants": "pants_charcoal", "shoes": "shoe_black",
		"hair": "hair_blonde", "iris": "iris_green",
		"apron": "apron_white", "female": true, "hair_style": "ponytail", "neck_style": "crew"
	}, "Elena Rossi\n★ Caffè San Carlo ★", Color(1.0, 0.85, 0.45))
	elena.name = "ElenaNPC"
	_spawn_shop_trigger(cafe_venue, "CafeShop", Vector3(1.2, 0.96, -1.05), "cafe", "Caffè San Carlo", Vector3(1.2, 0.9, 0.9))
	_add_omni(cafe_venue, Vector3(0, 2.52, 0.75), Color(1.0, 0.88, 0.68), 0.34, 8.5)

	var tech_venue := Node3D.new()
	tech_venue.name = "TechShopVenue"
	tech_venue.position = Vector3(13.8, 0, 20.5)
	tech_venue.rotation.y = -PI * 0.5
	street.add_child(tech_venue)
	var tech_sm := StyleMesh.new()
	VillageProps.add_shop_building(tech_sm, Vector3.ZERO, 7.6, 5.8, {
		"wall": "plaster_sky", "floor": "tile_gray", "awning": "awning_blue", "roof": "roof_slate",
		"counter_top": "steel", "counter_base": "iron"
	})
	# Scaffali hardware interni + scaffalatura dx espositiva componenti + pannello schema tecnico + terminale banco
	tech_sm.box("iron", Vector3(-2.6, 1.0, -0.4), Vector3(0.5, 2.0, 2.4), {"col": true})
	tech_sm.box("glass_cool", Vector3(-2.33, 1.35, -0.4), Vector3(0.05, 0.4, 1.8))
	tech_sm.box("iron", Vector3(-1.8, 1.05, -1.05), Vector3(0.75, 0.24, 0.34))
	tech_sm.box("cyan_accent", Vector3(-1.8, 1.18, -1.00), Vector3(0.58, 0.22, 0.06))
	# Scaffale espositivo parete destra con box router, workstation & nas
	tech_sm.box("iron", Vector3(3.12, 1.02, -0.35), Vector3(0.46, 2.04, 2.2), {"col": true})
	for sy_t in [0.58, 1.12, 1.66]:
		tech_sm.box("wood_plank", Vector3(3.10, sy_t, -0.35), Vector3(0.44, 0.05, 2.12))
	tech_sm.box("cyan_accent", Vector3(3.04, 0.74, -0.95), Vector3(0.28, 0.28, 0.36))
	tech_sm.box("gaming_black", Vector3(3.04, 1.28, -0.25), Vector3(0.28, 0.26, 0.42))
	tech_sm.box("steel", Vector3(3.04, 1.82, -0.85), Vector3(0.28, 0.26, 0.38))
	tech_sm.box("tin_blue", Vector3(3.04, 1.82, 0.20), Vector3(0.26, 0.24, 0.32))
	# Schema motherboard / rete retroilluminato sulla parete di fondo + bobina cavo blu
	tech_sm.box("wood_dark", Vector3(0.0, 2.05, -2.62), Vector3(2.2, 0.94, 0.06))
	tech_sm.box("iron", Vector3(0.0, 2.05, -2.58), Vector3(1.98, 0.76, 0.03))
	tech_sm.box("cyan_accent", Vector3(-0.45, 2.05, -2.55), Vector3(0.55, 0.38, 0.02))
	tech_sm.box("glass_cool", Vector3(0.48, 2.05, -2.55), Vector3(0.62, 0.44, 0.02))
	tech_sm.cyl("tin_blue", Vector3(2.55, 0.22, -2.25), 0.22, 0.22, 0.36, 12)
	tech_sm.cyl("steel", Vector3(2.55, 0.41, -2.25), 0.25, 0.25, 0.03, 12)
	VillageProps.spawn_mesh_and_collisions(tech_venue, "TechMesh", tech_sm, "tile")
	_add_sign(tech_venue, "ELETTRONICA TO", Vector3(0, 3.12, 3.06), 0.0, 32, Color(0.78, 0.94, 1.0))
	var davide := _spawn_npc(tech_venue, "DavideNPC", Vector3(0.0, 0.18, -1.86), 0.0, DAVIDE_SCRIPT, {
		"shirt": "shirt_sky", "pants": "denim", "shoes": "sneaker_white",
		"hair": "hair_dark", "iris": "iris_brown",
		"hair_style": "quiff", "glasses": true, "vest": "vest_charcoal"
	}, "Davide Ferrero\n★ Elettronica TO ★", Color(0.65, 0.88, 1.0))
	davide.name = "DavideNPC"
	_spawn_shop_trigger(tech_venue, "TechHardwareShop", Vector3(-1.8, 0.96, -1.05), "elettronica_componenti", "Elettronica TO — Hardware Clienti", Vector3(1.6, 1.0, 1.0))
	_add_omni(tech_venue, Vector3(0, 2.52, 0.75), Color(0.85, 0.94, 1.0), 0.34, 8.5)

	# 4. Negozi del Borgo: Forno Bruno, Alimentari Rosa, Edicola Sabrina
	var panificio := Node3D.new()
	panificio.name = "PanificioVenue"
	panificio.position = Vector3(-8.2, 0, 7.8)
	panificio.rotation.y = PI * 0.5
	street.add_child(panificio)
	var pan_sm := StyleMesh.new()
	VillageProps.add_shop_building(pan_sm, Vector3.ZERO, 6.2, 5.2, {
		"wall": "plaster_cream", "floor": "wood_light", "awning": "awning_yellow", "roof": "roof_terracotta",
		"counter_top": "marble_dark", "counter_base": "wood_dark", "shutter": "fabric_green"
	})
	# Tre pagnotte artigianali dorate posate direttamente sul marmo venato scuro + briciole e spolverata organica (zero piattini bianchi!)
	for bi in range(3):
		var bx: float = [-1.22, 0.0, 1.22][bi]
		pan_sm.ellipsoid("bread", Vector3(bx, 1.01, -0.92), Vector3(0.24, 0.13, 0.20), 6, 12)
		# Sottili incisioni dorate in crosta e piccoli granelli di farina / briciole sparse sul marmo
		pan_sm.capsule_seg("bread", Vector3(bx - 0.11, 1.125, -0.97), Vector3(bx + 0.11, 1.125, -0.87), 0.008, 0.008, 5)
		pan_sm.capsule_seg("flour", Vector3(bx + 0.09, 1.130, -0.96), Vector3(bx - 0.09, 1.130, -0.88), 0.004, 0.004, 5)
		for ci in range(4):
			var c_ang := float(bi * 5 + ci * 2) * 1.37
			var cr := 0.25 + float(ci % 3) * 0.06
			pan_sm.ellipsoid("flour", Vector3(bx + cos(c_ang) * cr, 0.943, -0.92 + sin(c_ang) * cr * 0.72), Vector3(0.032 + float(ci % 2) * 0.016, 0.003, 0.024), 3, 6)
			pan_sm.ellipsoid("bread", Vector3(bx + cos(c_ang + 0.9) * (cr - 0.03), 0.944, -0.92 + sin(c_ang + 0.9) * cr * 0.65), Vector3(0.014, 0.008, 0.012), 3, 5)
	# Doppie mensole posteriori sinistra/destra con michette, filoni e pagnotte verticali + lavagna listino centrale + pala fornaio
	for sx in [-1.72, 1.72]:
		pan_sm.box("wood_dark", Vector3(sx, 1.38, -2.20), Vector3(1.38, 0.07, 0.32))
		pan_sm.box("wood_dark", Vector3(sx, 1.88, -2.20), Vector3(1.38, 0.07, 0.32))
		for lx in [-0.42, 0.0, 0.42]:
			pan_sm.ellipsoid("bread", Vector3(sx + lx, 1.47, -2.19), Vector3(0.16, 0.085, 0.13), 5, 10)
		pan_sm.ellipsoid("bread", Vector3(sx - 0.30, 1.97, -2.19), Vector3(0.28, 0.08, 0.12), 5, 10)
		pan_sm.ellipsoid("bread", Vector3(sx + 0.16, 2.02, -2.19), Vector3(0.11, 0.13, 0.11), 5, 10)
		pan_sm.box("bread", Vector3(sx + 0.46, 1.98, -2.19), Vector3(0.18, 0.16, 0.18))
	pan_sm.box("wood_dark", Vector3(0.0, 2.08, -2.32), Vector3(1.65, 0.84, 0.06))
	pan_sm.box("iron", Vector3(0.0, 2.08, -2.28), Vector3(1.45, 0.68, 0.03))
	pan_sm.capsule_seg("wood_plank", Vector3(2.68, 0.42, -1.45), Vector3(2.74, 1.98, -1.45), 0.025, 0.022, 8)
	pan_sm.box("wood_plank", Vector3(2.67, 0.36, -1.45), Vector3(0.04, 0.46, 0.34))
	# Ceste di vimini ben in vista sul lato sinistro del banco con pani dentro + cesta vetrina sx
	for wk in [
		[Vector3(-2.36, 0.04, -1.78), 0.24, 0.29, 0.32, true],
		[Vector3(-2.02, 0.04, -1.98), 0.20, 0.25, 0.25, true],
		[Vector3(-2.40, 0.04, -1.18), 0.22, 0.27, 0.28, true],
		[Vector3(-2.18, 0.04, 1.18), 0.26, 0.32, 0.36, true]
	]:
		pan_sm.cyl("wicker", wk[0], wk[1], wk[2], wk[3], 12, {"smooth": false})
		if wk[4]:
			pan_sm.ellipsoid("bread", wk[0] + Vector3(0.0, wk[3] - 0.01, 0.0), Vector3(wk[1] * 0.72, 0.09, wk[1] * 0.62), 5, 8)
	# Sacco di iuta aperto con bordo arrotolato morbido e farina annidata all'interno
	pan_sm.lathe_oval("burlap", Vector3(2.38, 0.04, -1.12), [
		Vector2(0.24, 0.0), Vector2(0.27, 0.18), Vector2(0.24, 0.38), Vector2(0.16, 0.48), Vector2(0.19, 0.535), Vector2(0.165, 0.545), Vector2(0.135, 0.51)
	], 1.0, 0.92, 14)
	pan_sm.cyl("wood_dark", Vector3(2.38, 0.475, -1.12), 0.145, 0.145, 0.02, 12)
	pan_sm.ellipsoid("flour", Vector3(2.38, 0.500, -1.12), Vector3(0.110, 0.042, 0.100), 5, 10)
	VillageProps.spawn_mesh_and_collisions(panificio, "PanificioMesh", pan_sm, "wood")
	_add_sign(panificio, "FORNO BRUNO", Vector3(0, 3.12, 2.76), 0.0, 30, Color(1.0, 0.92, 0.60))
	_spawn_npc(panificio, "BrunoNPC", Vector3(0.0, 0.18, -1.75), 0.0, SHOP_SCRIPT, {
		"shirt": "shirt_oatmeal", "pants": "pants_charcoal", "shoes": "leather",
		"skin": "skin_warm", "hair": "hair_brown", "iris": "iris_brown",
		"apron": "apron_cream", "hat": "baker", "mustache": true, "rolled_sleeves": true, "neck_style": "open_v"
	}, "Bruno\n★ Forno Bruno ★", Color(1.0, 0.88, 0.50), {"shop_id": "panificio", "shop_title": "Forno Bruno"})
	_spawn_shop_trigger(panificio, "PanificioShop", Vector3(0.0, 0.96, -0.9), "panificio", "Forno Bruno", Vector3(2.8, 0.9, 0.9))
	_add_omni(panificio, Vector3(0.0, 2.52, 0.75), Color(1.0, 0.87, 0.65), 0.36, 9.5)

	var alimentari := Node3D.new()
	alimentari.name = "AlimentariVenue"
	alimentari.position = Vector3(8.2, 0, 7.8)
	alimentari.rotation.y = -PI * 0.5
	street.add_child(alimentari)
	var ali_sm := StyleMesh.new()
	VillageProps.add_shop_building(ali_sm, Vector3.ZERO, 6.2, 5.2, {
		"wall": "plaster_sage", "floor": "tile_bw", "awning": "awning_green", "roof": "roof_terracotta",
		"counter_top": "stone_counter", "counter_base": "wood_plank"
	})
	# Cassetta esterna davanti alla vetrina sinistra (lascia libero il corridoio centrale)
	VillageProps.add_alimentari_crates(ali_sm, Vector3(-1.82, 0.0, 3.06), 0.08)
	# Doppie mensole piene di barattoli colorati e frutta fresca sulla parete di fondo + lavagnetta centrale
	VillageProps.add_alimentari_shelves(ali_sm, Vector3(-1.78, 0.0, -2.22), 0.0)
	VillageProps.add_alimentari_shelves(ali_sm, Vector3(1.78, 0.0, -2.22), 0.0)
	ali_sm.box("wood_dark", Vector3(0.0, 2.08, -2.32), Vector3(1.55, 0.80, 0.06))
	ali_sm.box("iron", Vector3(0.0, 2.08, -2.28), Vector3(1.36, 0.64, 0.03))
	# Bilancia d'ottone tradizionale e barattoli olio/marmellata sul lato sinistro del banco
	ali_sm.box("brass", Vector3(-1.52, 0.975, -0.94), Vector3(0.28, 0.04, 0.20))
	ali_sm.cyl("brass", Vector3(-1.52, 1.09, -0.94), 0.025, 0.022, 0.22, 8)
	ali_sm.box("brass", Vector3(-1.52, 1.19, -0.94), Vector3(0.30, 0.025, 0.03))
	ali_sm.cyl("brass", Vector3(-1.66, 1.14, -0.94), 0.07, 0.05, 0.02, 10)
	ali_sm.cyl("brass", Vector3(-1.38, 1.14, -0.94), 0.07, 0.05, 0.02, 10)
	ali_sm.cyl("jar_green", Vector3(-1.86, 1.04, -1.04), 0.055, 0.055, 0.17, 10)
	ali_sm.cyl("jar_jam", Vector3(-1.74, 1.02, -0.84), 0.05, 0.05, 0.13, 10)
	# Cassette in legno ai lati del bancone e banco frutta interno sotto finestra destra
	VillageProps.add_alimentari_crates(ali_sm, Vector3(-2.36, 0.04, -1.78), 0.14)
	VillageProps.add_alimentari_crates(ali_sm, Vector3(2.36, 0.04, -1.78), -0.14)
	ali_sm.box("wood_plank", Vector3(2.18, 0.36, 1.18), Vector3(0.76, 0.64, 0.56), {"col": true})
	ali_sm.ellipsoid("apple", Vector3(1.98, 0.72, 1.12), Vector3(0.065, 0.06, 0.065), 4, 8)
	ali_sm.ellipsoid("orange", Vector3(2.18, 0.73, 1.20), Vector3(0.07, 0.065, 0.07), 4, 8)
	ali_sm.ellipsoid("lemon", Vector3(2.38, 0.72, 1.14), Vector3(0.065, 0.055, 0.055), 4, 8)
	VillageProps.spawn_mesh_and_collisions(alimentari, "AlimentariMesh", ali_sm, "tile")
	_add_sign(alimentari, "ALIMENTARI ROSA", Vector3(0, 3.12, 2.76), 0.0, 28, Color(0.84, 1.0, 0.84))
	_spawn_npc(alimentari, "RosaNPC", Vector3(0.0, 0.18, -1.75), 0.0, SHOP_SCRIPT, {
		"shirt": "shirt_olive_sage", "pants": "pants_charcoal", "shoes": "shoe_black",
		"hair": "hair_chestnut", "iris": "iris_brown",
		"apron": "apron_white", "female": true, "hair_style": "updo_wavy", "skirt": true, "neck_style": "crew"
	}, "Rosa\n★ Alimentari Rosa ★", Color(0.75, 1.0, 0.75), {"shop_id": "alimentari", "shop_title": "Alimentari Rosa"})
	_spawn_shop_trigger(alimentari, "AlimentariShop", Vector3(0.0, 0.96, -0.9), "alimentari", "Alimentari Rosa", Vector3(2.8, 0.9, 0.9))
	_add_omni(alimentari, Vector3(0.0, 2.52, 0.75), Color(1.0, 0.91, 0.74), 0.35, 9.0)

	var edicola := Node3D.new()
	edicola.name = "EdicolaVenue"
	edicola.position = Vector3(6.8, 0, 14.5)
	edicola.rotation.y = -PI * 0.25
	street.add_child(edicola)
	var edi_sm := StyleMesh.new()
	VillageProps.add_edicola(edi_sm, Vector3.ZERO, 0.0)
	VillageProps.spawn_mesh_and_collisions(edicola, "EdicolaMesh", edi_sm, "stone")
	_add_sign(edicola, "EDICOLA SABRINA", Vector3(0, 2.40, 1.74), 0.0, 24, Color(0.85, 0.95, 1.0))
	_spawn_npc(edicola, "SabrinaNPC", Vector3(0.0, 0.24, 0.08), 0.0, SHOP_SCRIPT, {
		"shirt": "shirt_linen_cream", "pants": "denim", "shoes": "shoe_black",
		"hair": "hair_auburn", "iris": "iris_blue",
		"vest": "vest_charcoal", "female": true, "hair_style": "bob", "glasses": true, "neck_style": "collar"
	}, "Sabrina\n★ Edicola ★", Color(0.80, 0.92, 1.0), {"shop_id": "edicola", "shop_title": "Edicola Sabrina"})
	_spawn_shop_trigger(edicola, "EdicolaShop", Vector3(0, 1.1, 0.95), "edicola", "Edicola Sabrina", Vector3(2.2, 1.4, 1.2))

	# 4b. OFFICINA MECCANICA BELLINI (Borgo Valdocco Est, accessibile da Ovest)
	var factory_venue := Node3D.new()
	factory_venue.name = "FactoryVenue"
	factory_venue.position = Vector3(85.0, 0, 27.5)
	factory_venue.rotation.y = -PI * 0.5
	factory_venue.set_script(FACTORY_SYNC_SCRIPT)
	street.add_child(factory_venue)

	var fac_sm := StyleMesh.new()
	VillageProps.add_factory_building(fac_sm, Vector3.ZERO, 12.0, 9.6, 0.0)
	VillageProps.spawn_mesh_and_collisions(factory_venue, "FactoryMesh", fac_sm, "tile")
	_add_sign(factory_venue, "OFFICINA MECCANICA BELLINI", Vector3(0, 3.44, 4.96), 0.0, 32, Color(1.0, 0.88, 0.30))

	_spawn_npc(factory_venue, "BelliniNPC", Vector3(2.10, 0.04, -1.80), -0.35, BELLINI_SCRIPT, {
		"shirt": "shirt_ochre", "pants": "pants_charcoal", "shoes": "shoe_black",
		"skin": "skin_warm", "hair": "hair_salt", "iris": "iris_brown",
		"vest": "vest_charcoal", "hat": "hardhat", "mustache": true, "glasses": true, "rolled_sleeves": true
	}, "Ing. Gianluca Bellini\n★ Officina Valdocco ★", Color(1.0, 0.84, 0.32))

	# 4 Zone Sopralluogo (perlustrazione fabbrica senza sovrapposizione con le stazioni hardware)
	_spawn_factory_interactable(factory_venue, "ScoutZone_Ingresso", Vector3(-1.45, 1.05, 2.40), {
		"mode": "scout", "zone_id": "scout_ingresso", "zone_title": "Ingresso & Quadro Rete Wi-Fi"
	}, true)
	_spawn_factory_interactable(factory_venue, "ScoutZone_Magazzino", Vector3(-0.8, 1.05, -2.18), {
		"mode": "scout", "zone_id": "scout_magazzino", "zone_title": "Magazzino & Banco Server"
	}, true)
	_spawn_factory_interactable(factory_venue, "ScoutZone_Ufficio", Vector3(2.25, 1.05, 1.45), {
		"mode": "scout", "zone_id": "scout_ufficio", "zone_title": "Ufficio Tecnico CAD"
	}, true)
	_spawn_factory_interactable(factory_venue, "ScoutZone_Vetrina", Vector3(-3.0, 1.05, -1.6), {
		"mode": "scout", "zone_id": "scout_vetrina", "zone_title": "Vetrina CNC & Catalogo Web"
	}, true)

	# 3 Stazioni Installazione Hardware ampie e avanzate verso i pad calpestabili (zero clipping sul muro)
	_spawn_factory_interactable(factory_venue, "InstallStation_Wifi", Vector3(-2.45, 1.32, 3.72), {"mode": "wifi"}, false, Vector3(1.7, 1.85, 1.50))
	_spawn_factory_interactable(factory_venue, "InstallStation_Server", Vector3(-0.8, 1.05, -3.60), {"mode": "server"}, false, Vector3(1.7, 1.9, 1.6))
	_spawn_factory_interactable(factory_venue, "InstallStation_PCs", Vector3(3.75, 1.05, -0.75), {"mode": "pcs"}, false, Vector3(2.1, 1.7, 2.55))

	# Ologrammi 3D Blueprint semi-trasparenti (visibili dopo 4/4 sopralluogo e spariscono a montaggio completato!)
	_spawn_factory_ghost(factory_venue, "GhostWifi",
		func(sm: StyleMesh): VillageProps.add_factory_ghost_wifi(sm, Vector3(-2.45, 1.38, 4.15), "ghost_ready"),
		func(sm: StyleMesh): VillageProps.add_factory_ghost_wifi(sm, Vector3(-2.45, 1.38, 4.15), "ghost_locked")
	)
	_spawn_factory_ghost(factory_venue, "GhostServer",
		func(sm: StyleMesh): VillageProps.add_factory_ghost_server(sm, Vector3(-0.8, 0.18, -4.10), "ghost_ready"),
		func(sm: StyleMesh): VillageProps.add_factory_ghost_server(sm, Vector3(-0.8, 0.18, -4.10), "ghost_locked")
	)
	_spawn_factory_ghost(factory_venue, "GhostPCs",
		func(sm: StyleMesh):
			VillageProps.add_factory_ghost_pcs(sm, Vector3(4.65, 0.81, -2.6), Vector3(4.65, 0.81, 0.55), PI * 0.5, "ghost_ready"),
		func(sm: StyleMesh):
			VillageProps.add_factory_ghost_pcs(sm, Vector3(4.65, 0.81, -2.6), Vector3(4.65, 0.81, 0.55), PI * 0.5, "ghost_locked")
	)

	# Prop visuali hardware installato (sincronizzati da FactoryVenueSync)
	var wifi_sm := StyleMesh.new()
	VillageProps.add_factory_installed_wifi(wifi_sm, Vector3(-2.45, 1.38, 4.15))
	var wifi_node := VillageProps.spawn_mesh_and_collisions(factory_venue, "InstalledWifi", wifi_sm, "metal")
	wifi_node.visible = false

	var srv_sm := StyleMesh.new()
	VillageProps.add_factory_installed_server(srv_sm, Vector3(-0.8, 0.18, -4.10))
	var srv_node := VillageProps.spawn_mesh_and_collisions(factory_venue, "InstalledServer", srv_sm, "metal")
	srv_node.visible = false

	var pcs_sm := StyleMesh.new()
	VillageProps.add_workstation_pc_prop(pcs_sm, Vector3(4.65, 0.81, -2.6), PI * 0.5)
	VillageProps.add_workstation_pc_prop(pcs_sm, Vector3(4.65, 0.81, 0.55), PI * 0.5)
	var pcs_node := VillageProps.spawn_mesh_and_collisions(factory_venue, "InstalledPCs", pcs_sm, "metal")
	pcs_node.visible = false

	factory_venue.call("_refresh")

	_add_omni(factory_venue, Vector3(0, 3.25, 1.4), Color(1.0, 0.95, 0.86), 1.05, 13.5)
	_add_omni(factory_venue, Vector3(0, 3.25, -2.4), Color(0.92, 0.97, 1.0), 1.05, 13.5)

	# 5. Case dei quattro Quartieri + Parco Valentino + Piazza del Mercato & OGR + Arredo urbano
	var houses_sm := StyleMesh.new()
	# San Carlo
	VillageProps.add_house(houses_sm, Vector3(-8.5, 0, 0.0), 6.2, 5.4, 2, {"wall": "plaster_rose", "roof": "roof_terracotta", "shutter": "fabric_green"})
	VillageProps.add_house(houses_sm, Vector3(8.5, 0, 0.0), 6.2, 5.4, 2, {"wall": "plaster_cream", "roof": "roof_slate", "shutter": "fabric_blue"})
	VillageProps.add_house(houses_sm, Vector3(-14.5, 0, 29.5), 6.5, 5.6, 2, {"wall": "plaster_ochre", "roof": "roof_terracotta", "rot": PI * 0.2})
	VillageProps.add_house(houses_sm, Vector3(15.5, 0, 36.2), 6.5, 5.6, 2, {"wall": "plaster_sage", "roof": "roof_slate", "rot": -PI * 0.15})
	VillageProps.add_house(houses_sm, Vector3(-15.5, 0, 5.5), 5.6, 5.4, 2, {"wall": "plaster_cream", "roof": "roof_terracotta", "rot": PI * 0.5})
	VillageProps.add_house(houses_sm, Vector3(15.5, 0, 5.5), 5.6, 5.4, 2, {"wall": "plaster_rose", "roof": "roof_terracotta", "rot": -PI * 0.5})
	# Borgo Valdocco
	VillageProps.add_house(houses_sm, Vector3(68.0, 0, 16.5), 6.2, 4.8, 2, {"wall": "plaster_ochre", "roof": "roof_terracotta", "shutter": "fabric_green"})
	VillageProps.add_house(houses_sm, Vector3(66.5, 0, 39.2), 5.8, 4.8, 2, {"wall": "plaster_cream", "roof": "roof_slate", "shutter": "fabric_blue", "rot": PI})
	VillageProps.add_house(houses_sm, Vector3(74.2, 0, 39.2), 5.6, 4.8, 2, {"wall": "plaster_terracotta", "roof": "roof_terracotta", "shutter": "fabric_green", "rot": PI})

	# Borgo Po / Lungo Po Meridionale (I3P PoliTO, Residenze, Lab Droni Torino, Torrefazione Po)
	VillageProps.add_i3p_incubator(houses_sm, Vector3(-13.5, 0.0, 48.0), 0.0)
	_add_sign(street, "INCUBATORE POLITO · I3P", Vector3(-13.5, 4.45, 51.34), 0.0, 24, Color(0.68, 0.94, 1.0))
	VillageProps.add_house(houses_sm, Vector3(-2.6, 0.0, 48.2), 6.0, 5.2, 2, {"wall": "plaster_rose", "roof": "roof_terracotta", "shutter": "fabric_green"})
	VillageProps.add_drone_lab(houses_sm, Vector3(24.0, 0.0, 48.2), 0.0)
	_add_sign(street, "LAB DRONI TORINO · AERO R&D", Vector3(24.0, 3.65, 51.32), 0.0, 22, Color(0.76, 0.95, 1.0))
	VillageProps.add_shop_building(houses_sm, Vector3(41.5, 0.0, 48.2), 7.6, 5.8, {
		"wall": "plaster_ochre", "floor": "tile_cafe", "awning": "awning_red", "roof": "roof_terracotta"
	})
	VillageProps.add_table_set(houses_sm, Vector3(39.1, 0.0, 53.0), "fabric_cream")
	VillageProps.add_parasol(houses_sm, Vector3(39.1, 0.0, 53.0), "fabric_cream")
	VillageProps.add_table_set(houses_sm, Vector3(43.9, 0.0, 53.0), "fabric_cream")
	VillageProps.add_parasol(houses_sm, Vector3(43.9, 0.0, 53.0), "fabric_cream")
	_add_sign(street, "TORREFAZIONE PO · STORICA", Vector3(41.5, 3.12, 51.26), 0.0, 24, Color(1.0, 0.92, 0.65))
	VillageProps.add_house(houses_sm, Vector3(51.2, 0.0, 48.2), 5.8, 5.2, 2, {"wall": "plaster_cream", "roof": "roof_slate", "shutter": "fabric_blue"})

	# Parco Valentino Ovest (Laghetto delle anatre, Gazebo in ferro, 2 Ville + Dehor con ombrelloni)
	VillageProps.add_park_pond(houses_sm, Vector3(-47.5, 0, 26.8), 4.0, 3.0)
	VillageProps.add_gazebo(houses_sm, Vector3(-47.5, 0, 17.0), 2.4)
	VillageProps.add_house(houses_sm, Vector3(-34.0, 0, 16.0), 6.8, 5.6, 2, {"wall": "plaster_cream", "roof": "roof_terracotta", "shutter": "fabric_green"})
	VillageProps.add_house(houses_sm, Vector3(-28.0, 0, 26.5), 6.2, 5.2, 2, {"wall": "plaster_rose", "roof": "roof_slate", "shutter": "fabric_blue", "rot": -PI * 0.5})
	for p_tab in [Vector3(-42.5, 0, 15.0), Vector3(-40.2, 0, 14.8), Vector3(-42.8, 0, 17.2)]:
		VillageProps.add_table_set(houses_sm, p_tab, "fabric_cream")
		VillageProps.add_parasol(houses_sm, p_tab, "fabric_cream")

	# Piazza del Mercato Nord, Ufficio Postale & Coworking OGR Torino
	VillageProps.add_post_office(houses_sm, Vector3(64.8, 0, 6.2), 0.0)
	_add_sign(street, "UFFICIO POSTALE TORINO NORD", Vector3(64.8, 2.75, 9.10), 0.0, 24, Color(1.0, 0.90, 0.25))
	VillageProps.add_market_stall(houses_sm, Vector3(73.2, 0, -4.2), 0.0, "awning_red", "fruit")
	VillageProps.add_market_stall(houses_sm, Vector3(78.5, 0, -4.2), 0.0, "awning_yellow", "books")
	VillageProps.add_market_stall(houses_sm, Vector3(83.8, 0, -4.2), 0.0, "awning_blue", "tech")
	_add_sign(street, "MERCATO RIONALE TORINO", Vector3(78.5, 3.28, -3.55), 0.0, 26, Color(1.0, 0.94, 0.70))
	VillageProps.add_ogr_hall(houses_sm, Vector3(110.25, 0.0, 2.75), 0.0)
	_add_sign(street, "OGR TECH HUB TORINO", Vector3(96.26, 4.65, 2.75), -PI * 0.5, 30, Color(0.68, 0.94, 1.0))
	_add_sign(street, "BAY 01 · STARTUP APERTA", Vector3(102.65, 2.62, 9.06), PI, 18, Color(0.55, 1.0, 0.72))
	_add_sign(street, "POD 02 · CHIUSO (RISERVATO)", Vector3(104.05, 2.62, -3.66), 0.0, 17, Color(1.0, 0.68, 0.45))
	_add_sign(street, "POD 03 · CHIUSO (CONSORZIO)", Vector3(112.45, 2.62, -3.66), 0.0, 17, Color(1.0, 0.68, 0.45))
	_add_sign(street, "POD 04 · CHIUSO (FINTECH)", Vector3(116.65, 2.62, 9.06), PI, 17, Color(1.0, 0.68, 0.45))

	# Cancello fisico di accesso OGR (chiuso finché non completi Via Po + Officina Bellini)
	var ogr_gate := Node3D.new()
	ogr_gate.name = "OGRGateBarrier"
	ogr_gate.position = Vector3(96.15, 0.0, 2.75)

	var ogr_gate_body := StaticBody3D.new()
	ogr_gate_body.name = "OGRGateBody"
	ogr_gate_body.collision_layer = 1
	ogr_gate_body.collision_mask = 0
	var ogr_gate_col := CollisionShape3D.new()
	ogr_gate_col.name = "Collider"
	ogr_gate_col.position = Vector3(0.0, 1.4, 0.0)
	var ogr_gate_box := BoxShape3D.new()
	ogr_gate_box.size = Vector3(0.35, 2.8, 4.9)
	ogr_gate_col.shape = ogr_gate_box
	ogr_gate_body.add_child(ogr_gate_col)
	ogr_gate.add_child(ogr_gate_body)

	var gate_vis := Node3D.new()
	gate_vis.name = "GateVisual"
	var g_sm := StyleMesh.new()
	g_sm.box("iron", Vector3(0.0, 0.85, -2.25), Vector3(0.14, 1.70, 0.14))
	g_sm.box("iron", Vector3(0.0, 0.85, 2.25), Vector3(0.14, 1.70, 0.14))
	g_sm.box("safety_yellow", Vector3(0.0, 0.78, 0.0), Vector3(0.10, 0.14, 4.50))
	g_sm.box("safety_yellow", Vector3(0.0, 1.28, 0.0), Vector3(0.10, 0.14, 4.50))
	g_sm.box("fabric_red", Vector3(-0.08, 1.38, 0.0), Vector3(0.06, 0.42, 1.65))
	var g_mi := MeshInstance3D.new()
	g_mi.mesh = g_sm.to_mesh(Callable(VillageMaterials, "mat"))
	gate_vis.add_child(g_mi)
	_add_sign(gate_vis, "ACCESSO OGR BLOCCATO\nCompleta Via Po & Officina Bellini", Vector3(-0.22, 1.95, 0.0), -PI * 0.5, 20, Color(1.0, 0.58, 0.42))
	ogr_gate.add_child(gate_vis)

	var open_banner := Label3D.new()
	open_banner.name = "OpenBanner"
	open_banner.text = "★ OGR TECH HUB APERTO ★"
	open_banner.position = Vector3(-0.20, 3.35, 0.0)
	open_banner.rotation.y = -PI * 0.5
	open_banner.font_size = 20
	open_banner.pixel_size = 0.008
	open_banner.modulate = Color(0.45, 0.96, 1.0)
	open_banner.outline_size = 6
	open_banner.outline_modulate = Color(0.06, 0.08, 0.12, 1.0)
	ogr_gate.add_child(open_banner)

	ogr_gate.set_script(OGR_GATE_SYNC_SCRIPT)
	street.add_child(ogr_gate)

	# Referente OGR Enterprise (Ing. Andrea Viale) & 2 coworker ambientali interni
	_spawn_npc(street, "AndreaVialeNPC", Vector3(104.8, 0.04, 2.2), -PI * 0.5, OGR_VIALE_SCRIPT, {
		"shirt": "shirt_white", "pants": "suit_navy", "shoes": "shoe_black",
		"vest": "suit_navy", "tie": "shirt_sky",
		"hair": "hair_salt", "iris": "iris_blue", "glasses": true
	}, "Ing. Andrea Viale\n★ OGR Tech Hub ★", Color(0.55, 0.94, 1.0))

	var ogr_cw := Node3D.new()
	ogr_cw.name = "OGRCoworkers"
	street.add_child(ogr_cw)
	var cw1 := Node3D.new()
	cw1.name = "CoworkerSeated"
	cw1.position = Vector3(107.27, 0.04, -2.47)
	cw1.rotation.y = 0.0
	ogr_cw.add_child(cw1)
	VillageProps.add_npc_model(cw1, {"seated": true, "female": true, "shirt": "shirt_ruby", "pants": "denim", "hair": "hair_auburn", "hair_style": "ponytail"})
	var cw2 := Node3D.new()
	cw2.name = "CoworkerPod1"
	cw2.position = Vector3(103.6, 0.04, 10.35)
	cw2.rotation.y = PI * 0.85
	ogr_cw.add_child(cw2)
	VillageProps.add_npc_model(cw2, {"shirt": "hoodie_teal", "pants": "denim", "shoes": "sneaker_white", "hair": "hair_dark", "hair_style": "quiff", "glasses": true})

	# Luce diffusa dai lucernari della navata OGR
	for lx in [103.0, 110.5, 118.0]:
		_add_omni(street, Vector3(lx, 5.4, 2.75), Color(0.95, 0.98, 1.0), 0.72, 20.0)

	# Fontana al centro della Piazzetta San Carlo (0, 0, 21.0)
	VillageProps.add_fountain(houses_sm, Vector3(0, 0, 21.0))

	# Panchine e tavolini nei cinque quartieri + Lungo Po Murazzi
	VillageProps.add_bench(houses_sm, Vector3(-4.2, 0, 21.0), PI * 0.5)
	VillageProps.add_bench(houses_sm, Vector3(4.2, 0, 21.0), -PI * 0.5)
	VillageProps.add_bench(houses_sm, Vector3(0.0, 0, 16.8), 0.0)
	VillageProps.add_bench(houses_sm, Vector3(-7.5, 0, 29.5), 0.0)
	VillageProps.add_bench(houses_sm, Vector3(4.3, 0, 35.6), PI * 0.5)
	VillageProps.add_bench(houses_sm, Vector3(65.2, 0, 22.8), PI * 0.5)
	VillageProps.add_bench(houses_sm, Vector3(71.8, 0, 22.8), -PI * 0.5)
	VillageProps.add_bench(houses_sm, Vector3(-41.0, 0, 26.8), PI * 0.5)
	VillageProps.add_bench(houses_sm, Vector3(-42.5, 0, 33.8), 0.0)
	VillageProps.add_bench(houses_sm, Vector3(-34.5, 0, 34.4), 0.0)
	VillageProps.add_bench(houses_sm, Vector3(73.5, 0, 2.2), PI * 0.5)
	VillageProps.add_bench(houses_sm, Vector3(2.4, 0, 47.0), PI * 0.5)
	VillageProps.add_bench(houses_sm, Vector3(14.0, 0, 47.0), -PI * 0.5)
	for bx_po in [-12.0, 0.0, 26.0, 39.0]:
		VillageProps.add_bench(houses_sm, Vector3(bx_po, 0, 64.0), 0.0)
	VillageProps.add_table_set(houses_sm, Vector3(86.2, 0, -0.5), "fabric_blue")
	VillageProps.add_parasol(houses_sm, Vector3(86.2, 0, -0.5), "fabric_cream")

	# Lampioni torinesi lungo tutti i quartieri (incl. Viale Lungo Po & Murazzi)
	for lp in [
		Vector3(-3.6, 0, 4.8), Vector3(3.6, 0, 4.8),
		Vector3(-3.6, 0, 11.8), Vector3(3.6, 0, 11.8),
		Vector3(-8.6, 0, 16.0), Vector3(8.6, 0, 24.4),
		Vector3(-8.6, 0, 26.0),
		Vector3(23.0, 0, 24.6), Vector3(32.0, 0, 24.6), Vector3(43.0, 0, 31.4),
		Vector3(54.0, 0, 24.6), Vector3(63.5, 0, 24.6), Vector3(63.5, 0, 31.4),
		Vector3(77.5, 0, 23.0), Vector3(77.5, 0, 32.5),
		Vector3(-35.2, 0, 34.2), Vector3(-43.0, 0, 22.8), Vector3(-40.5, 0, 18.2), Vector3(-52.5, 0, 32.8),
		Vector3(70.5, 0, 12.2), Vector3(85.2, 0, 12.2), Vector3(71.5, 0, -1.5), Vector3(85.5, 0, -1.5),
		Vector3(2.6, 0, 44.5), Vector3(13.8, 0, 44.5),
		Vector3(-18.0, 0, 60.9), Vector3(-5.0, 0, 60.9), Vector3(5.0, 0, 60.9),
		Vector3(19.0, 0, 60.9), Vector3(32.0, 0, 60.9), Vector3(46.0, 0, 60.9)
	]:
		VillageProps.add_lamp(houses_sm, lp)
		_add_omni(street, lp + Vector3(0, 3.4, 0), Color(1.0, 0.88, 0.62), 0.0, 9.5, "day_night_lamp")

	# Alberi e cespugli (San Carlo, Valdocco, Parco Valentino, Mercato Nord, Borgo Po)
	var trees := [
		[Vector3(-5.8, 0, 15.2), 11, 1.05],
		[Vector3(-8.5, 0, 26.5), 12, 1.15],
		[Vector3(4.4, 0, 39.5), 13, 1.10],
		[Vector3(-10.8, 0, 31.5), 14, 1.25],
		[Vector3(13.8, 0, 26.2), 15, 1.20],
		[Vector3(-12.5, 0, -4.5), 16, 1.15],
		[Vector3(12.5, 0, -4.5), 17, 1.10],
		[Vector3(-19.0, 0, 20.5), 18, 1.30],
		[Vector3(19.0, 0, 20.5), 19, 1.25],
		[Vector3(29.0, 0, 22.4), 21, 1.15],
		[Vector3(37.5, 0, 33.8), 22, 1.20],
		[Vector3(49.5, 0, 22.4), 23, 1.15],
		[Vector3(56.0, 0, 33.8), 24, 1.25],
		[Vector3(64.2, 0, 20.0), 25, 1.05],
		[Vector3(72.6, 0, 19.6), 26, 1.10],
		[Vector3(84.5, 0, 17.5), 27, 1.25],
		[Vector3(84.5, 0, 38.5), 28, 1.20],
		[Vector3(-52.8, 0, 20.5), 31, 1.25],
		[Vector3(-52.8, 0, 33.5), 32, 1.30],
		[Vector3(-41.5, 0, 14.8), 33, 1.15],
		[Vector3(-33.5, 0, 23.5), 34, 1.10],
		[Vector3(-41.5, 0, 39.8), 35, 1.25],
		[Vector3(-28.0, 0, 39.8), 36, 1.18],
		[Vector3(63.2, 0, -4.5), 41, 1.20],
		[Vector3(67.2, 0, -6.5), 42, 1.15],
		[Vector3(90.5, 0, -6.2), 43, 1.25],
		[Vector3(91.5, 0, 11.4), 44, 1.15],
		[Vector3(-21.2, 0, 52.5), 51, 1.20],
		[Vector3(16.6, 0, 46.5), 52, 1.15],
		[Vector3(33.0, 0, 46.5), 53, 1.20],
		[Vector3(53.2, 0, 52.5), 54, 1.15]
	]
	for t in trees:
		VillageProps.add_tree(houses_sm, t[0], t[1], t[2])
	for bp in [
		Vector3(-3.4, 0, 14.5), Vector3(3.4, 0, 14.5),
		Vector3(-5.5, 0, 28.2), Vector3(4.4, 0, 38.8),
		Vector3(-11.2, 0, 15.6), Vector3(11.2, 0, 15.6),
		Vector3(27.0, 0, 32.4), Vector3(51.5, 0, 24.0),
		Vector3(64.5, 0, 33.5),
		Vector3(-42.5, 0, 18.8), Vector3(-34.2, 0, 32.8),
		Vector3(68.2, 0, -1.8), Vector3(87.0, 0, -6.2),
		Vector3(-18.5, 0, 64.5), Vector3(12.2, 0, 64.5), Vector3(19.8, 0, 64.5), Vector3(48.5, 0, 64.5)
	]:
		VillageProps.add_bush(houses_sm, bp, int(absf(bp.x) * 3), 0.95)

	VillageProps.spawn_mesh_and_collisions(street, "BorgoPropsAndHouses", houses_sm, "stone")

	# 6. Auto parcheggiate affiancate nei due slarghi laterali + Furgone Consegne Valdocco + Viale Lungo Po
	var street_props := Node3D.new()
	street_props.name = "StreetProps"
	street.add_child(street_props)

	var cars := [
		{"name": "CarHatchback", "pos": Vector3(-13.6, 0.0, 11.8), "rot": 0.0, "color": "car_red", "van": false},
		{"name": "CarSedan", "pos": Vector3(-16.6, 0.0, 11.8), "rot": PI, "color": "car_blue", "van": false},
		{"name": "CarTaxi", "pos": Vector3(13.6, 0.0, 11.8), "rot": 0.0, "color": "car_cream", "van": false},
		{"name": "CarStationWagon", "pos": Vector3(16.6, 0.0, 11.8), "rot": PI, "color": "car_sage", "van": false},
		{"name": "DeliveryVanValdocco", "pos": Vector3(43.0, 0.0, 22.8), "rot": PI * 0.5, "color": "car_cream", "van": true},
		{"name": "CarBorgopoBlue", "pos": Vector3(-9.5, 0.0, 56.8), "rot": PI * 0.5, "color": "car_blue", "van": false},
		{"name": "CarBorgopoRed", "pos": Vector3(33.5, 0.0, 59.2), "rot": -PI * 0.5, "color": "car_red", "van": false},
	]
	for c in cars:
		var c_sm := StyleMesh.new()
		if c.get("van", false):
			VillageProps.add_delivery_van(c_sm, Vector3.ZERO, c["rot"], c["color"])
		else:
			VillageProps.add_car(c_sm, Vector3.ZERO, c["rot"], c["color"])
		var c_node := VillageProps.spawn_mesh_and_collisions(street_props, c["name"], c_sm, "stone")
		c_node.position = c["pos"]

	# 7. Bacheche Lavori Rapidi + 24 Punti Attività Ripetibili (SideJobs)
	_build_side_jobs_world(street)

	# Luci su fontana, pozzo, laghetto Parco Valentino & Mercato OGR
	_add_omni(street, Vector3(0, 2.6, 21.0), Color(0.68, 0.88, 1.0), 0.42, 9.0)
	_add_omni(street, Vector3(68.5, 2.8, 22.8), Color(1.0, 0.92, 0.72), 0.85, 10.0)
	_add_omni(street, Vector3(-47.5, 2.4, 26.8), Color(0.68, 0.88, 1.0), 0.38, 10.0)
	_add_omni(street, Vector3(78.5, 3.0, 3.0), Color(1.0, 0.92, 0.76), 1.0, 12.0)

static func _build_side_jobs_world(street: Node3D) -> void:
	var sj_holder := Node3D.new()
	sj_holder.name = "SideJobsWorld"
	street.add_child(sj_holder)

	var props_sm := StyleMesh.new()
	var bacheche := [
		{"name": "BachecaSanCarlo", "pos": Vector3(7.2, 0.0, 18.0), "rot": -PI * 0.35},
		{"name": "BachecaMercato", "pos": Vector3(74.2, 0.0, 10.6), "rot": PI * 0.18}
	]
	for b in bacheche:
		VillageProps.add_bacheca(props_sm, b["pos"], b["rot"])
		_add_sign(sj_holder, "★ BACHECA LAVORI ★", b["pos"] + Vector3(0, 2.60, 0), b["rot"], 20, Color(1.0, 0.92, 0.45))
		var bb := StaticBody3D.new()
		bb.name = b["name"]
		bb.position = b["pos"] + Vector3(0, 1.15, 0)
		bb.rotation.y = b["rot"]
		bb.set_script(SIDEJOB_SCRIPT)
		bb.set("spot_kind", "bacheca")
		var cs := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(1.8, 1.6, 0.9)
		cs.shape = box
		bb.add_child(cs)
		sj_holder.add_child(bb)

	var spot_rots := {
		"mailbox_sancarlo_ovest": 0.0,
		"mailbox_sancarlo_est": 0.0,
		"mailbox_parco_villa_nord": 0.0,
		"mailbox_parco_villa_sud": -PI * 0.5,
		"mailbox_valdocco_casa": 0.0,
		"mailbox_mercato_nord": -PI * 0.5,
		"mailbox_borgopo_i3p": 0.0,
		"mailbox_torrefazione_po": 0.0,
		"repair_cab_via_po": PI * 0.5,
		"repair_cab_parco": PI,
		"repair_cab_valdocco": PI * 0.5,
		"repair_cab_mercato": PI * 0.5,
		"repair_cab_borgopo": 0.0,
		"crate_hub_poste": 0.2,
		"crate_drop_mercato": 0.0,
		"crate_hub_furgone": PI * 0.5,
		"crate_drop_officina": -PI * 0.5
	}

	for spot_id in SideJobManager.DEFAULT_SPOTS:
		var info: Dictionary = SideJobManager.DEFAULT_SPOTS[spot_id]
		var pos: Vector3 = info["pos"]
		var kind: String = str(info["kind"])
		var lbl: String = str(info["label"])
		var rot: float = float(spot_rots.get(spot_id, 0.0))

		if kind == "mailbox":
			VillageProps.add_mailbox(props_sm, pos, rot)
		elif kind == "repair":
			VillageProps.add_fiber_cabinet(props_sm, pos, rot)
		elif kind == "crate_pickup":
			VillageProps.add_cargo_pallet(props_sm, pos, rot, false)
		elif kind == "crate_drop":
			VillageProps.add_cargo_pallet(props_sm, pos, rot, true)

		var sb := StaticBody3D.new()
		sb.name = "SideSpot_" + str(spot_id)
		sb.position = pos + Vector3(0, 0.95, 0)
		sb.set_script(SIDEJOB_SCRIPT)
		sb.set("spot_kind", "spot")
		sb.set("spot_id", str(spot_id))
		sb.set("spot_title", lbl)
		sb.set("spot_type", kind)

		var cs := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(1.5, 1.8, 1.5)
		cs.shape = box
		sb.add_child(cs)

		var beacon := Node3D.new()
		beacon.name = "Beacon"
		var bsm := StyleMesh.new()
		bsm.cyl("ghost_pad", Vector3(0, -0.89, 0), 0.58, 0.58, 0.06, 12)
		bsm.ellipsoid("cyan_accent", Vector3(0, 0.95, 0), Vector3(0.18, 0.28, 0.18), 6, 10)
		var bmi := MeshInstance3D.new()
		bmi.mesh = bsm.to_mesh(Callable(VillageMaterials, "mat"))
		beacon.add_child(bmi)
		beacon.visible = false
		sb.add_child(beacon)
		sb.set("beacon_path", NodePath("Beacon"))

		sj_holder.add_child(sb)

	VillageProps.spawn_mesh_and_collisions(sj_holder, "SideJobPropsMesh", props_sm, "stone")

# ------------------------------------------------------------------ Helpers nodi
static func _add_sign(parent: Node3D, txt: String, pos: Vector3, rot_y: float, font_sz: int, col: Color) -> void:
	var lbl := Label3D.new()
	lbl.text = txt
	lbl.position = pos
	lbl.rotation.y = rot_y
	lbl.font_size = font_sz
	lbl.pixel_size = 0.008
	lbl.modulate = col
	lbl.outline_size = 6
	lbl.outline_modulate = Color(0.08, 0.06, 0.05, 1.0)
	lbl.double_sided = false
	parent.add_child(lbl)

static func _add_omni(parent: Node3D, pos: Vector3, col: Color, energy: float, rng: float, group_name: String = "") -> void:
	var l := OmniLight3D.new()
	l.position = pos
	l.light_color = col
	l.light_energy = energy
	l.omni_range = rng
	if group_name != "":
		l.add_to_group(group_name)
	parent.add_child(l)

static func _spawn_shop_trigger(parent: Node3D, node_name: String, pos: Vector3, shop_id: String, shop_title: String, size: Vector3) -> void:
	var sb := StaticBody3D.new()
	sb.name = node_name
	sb.position = pos
	sb.set_script(SHOP_SCRIPT)
	sb.set("shop_id", shop_id)
	sb.set("shop_title", shop_title)
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	cs.shape = box
	sb.add_child(cs)
	parent.add_child(sb)

static func _spawn_factory_ghost(parent: Node3D, node_name: String, build_ready: Callable, build_locked: Callable) -> Node3D:
	var holder := Node3D.new()
	holder.name = node_name
	parent.add_child(holder)

	var sm_r := StyleMesh.new()
	build_ready.call(sm_r)
	var mi_r := MeshInstance3D.new()
	mi_r.name = "Ready"
	mi_r.mesh = sm_r.to_mesh(Callable(VillageMaterials, "mat"))
	mi_r.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi_r.visible = false
	holder.add_child(mi_r)

	var sm_l := StyleMesh.new()
	build_locked.call(sm_l)
	var mi_l := MeshInstance3D.new()
	mi_l.name = "Locked"
	mi_l.mesh = sm_l.to_mesh(Callable(VillageMaterials, "mat"))
	mi_l.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi_l.visible = true
	holder.add_child(mi_l)
	return holder

static func _spawn_factory_interactable(parent: Node3D, node_name: String, pos: Vector3, props: Dictionary, with_beacon: bool, box_size: Vector3 = Vector3(1.1, 1.25, 1.1)) -> StaticBody3D:
	var sb := StaticBody3D.new()
	sb.name = node_name
	sb.position = pos
	sb.set_script(FACTORY_ITEM_SCRIPT)
	for k in props:
		sb.set(k, props[k])
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = box_size
	cs.shape = box
	sb.add_child(cs)

	if with_beacon:
		var beacon := Node3D.new()
		beacon.name = "Beacon"
		var bsm := StyleMesh.new()
		bsm.cyl("safety_yellow", Vector3(0, -1.00, 0), 0.34, 0.34, 0.05, 12)
		bsm.ellipsoid("cyan_accent", Vector3(0, 0.15, 0), Vector3(0.14, 0.22, 0.14), 6, 10)
		var bmi := MeshInstance3D.new()
		bmi.mesh = bsm.to_mesh(Callable(VillageMaterials, "mat"))
		beacon.add_child(bmi)
		sb.add_child(beacon)
		sb.set("beacon_path", NodePath("Beacon"))

	parent.add_child(sb)
	return sb

static func _spawn_npc(parent: Node3D, node_name: String, pos: Vector3, rot_y: float, script_res: Script, style: Dictionary, tag_txt: String, tag_col: Color, extra_props: Dictionary = {}) -> StaticBody3D:
	var npc := StaticBody3D.new()
	npc.name = node_name
	npc.position = pos
	npc.rotation.y = rot_y
	npc.collision_layer = 3
	npc.collision_mask = 0
	npc.set_script(script_res)
	for k in extra_props:
		npc.set(k, extra_props[k])
	var cs := CollisionShape3D.new()
	cs.position = Vector3(0, 0.95, 0)
	var cap := CapsuleShape3D.new()
	cap.radius = 0.40
	cap.height = 1.90
	cs.shape = cap
	npc.add_child(cs)

	VillageProps.add_npc_model(npc, style)

	var tag := Label3D.new()
	tag.name = "NameTag"
	tag.position = Vector3(0, 2.05, 0)
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.text = tag_txt
	tag.font_size = 18
	tag.modulate = tag_col
	tag.outline_size = 5
	tag.outline_modulate = Color(0.1, 0.1, 0.1, 1.0)
	npc.add_child(tag)

	parent.add_child(npc)
	return npc

static func _add_garden_wall(sm: StyleMesh, center: Vector3, size: Vector3) -> void:
	sm.box("wall_garden", center, size, {"col": true, "surface": "stone"})
	var cap_sx := size.x if size.x >= size.z else size.x + 0.14
	var cap_sz := size.z + 0.14 if size.x >= size.z else size.z
	sm.box("brick", Vector3(center.x, center.y + size.y * 0.5 + 0.045, center.z), Vector3(cap_sx, 0.09, cap_sz))

static func _scatter_grass_tufts(sm: StyleMesh) -> void:
	var rnd := RandomNumberGenerator.new()
	rnd.seed = 202611

	# 1. Parco Valentino: lungo muretti, alberi, laghetto e sentieri in ghiaia (come Rif 1)
	for px in range(-54, -25, 3):
		sm.grass_tuft("grass_tuft", Vector3(float(px) + rnd.randf_range(-0.4, 0.4), 0.0, 12.45), rnd.randf_range(0.75, 1.15), rnd.randf() * TAU)
		sm.grass_tuft("grass_tuft", Vector3(float(px) + rnd.randf_range(-0.4, 0.4), 0.0, 41.50), rnd.randf_range(0.75, 1.15), rnd.randf() * TAU)
	for pz in range(14, 41, 3):
		sm.grass_tuft("grass_tuft", Vector3(-55.52, 0.0, float(pz) + rnd.randf_range(-0.4, 0.4)), rnd.randf_range(0.80, 1.18), rnd.randf() * TAU)
	for k in range(18):
		var a := TAU * float(k) / 18.0
		if cos(a) > 0.65:
			continue # lascia libero il pontile in legno a Est (+X)
		var rp := Vector3(-47.5 + cos(a) * 4.65, 0.0, 26.8 + sin(a) * 4.55)
		sm.grass_tuft("grass_tuft", rp, rnd.randf_range(0.72, 1.12), a + 0.4)
	for wp in [
		Vector3(-52.8, 0, 34.4), Vector3(-51.6, 0, 35.1), Vector3(-53.4, 0, 33.2),
		Vector3(-42.5, 0, 34.2), Vector3(-39.6, 0, 32.8), Vector3(-35.2, 0, 33.5),
		Vector3(-42.0, 0, 22.8), Vector3(-40.2, 0, 19.3), Vector3(-52.2, 0, 21.4)
	]:
		sm.grass_tuft("grass_tuft", wp, rnd.randf_range(0.85, 1.25), rnd.randf() * TAU)

	# 2. Viale Est: ciuffi ai piedi dei cordoli stradali in granito & slargo ghiaia (come Rif 5)
	for vx in range(25, 61, 2):
		var fx := float(vx) + rnd.randf_range(-0.25, 0.25)
		if fx < 36.8 or fx > 46.2:
			sm.grass_tuft("grass_tuft", Vector3(fx, 0.0, 24.76), rnd.randf_range(0.46, 0.72), rnd.randf() * TAU)
		sm.grass_tuft("grass_tuft", Vector3(fx, 0.0, 31.24), rnd.randf_range(0.46, 0.72), rnd.randf() * TAU)
	for gx in range(36, 47, 2):
		sm.grass_tuft("grass_tuft", Vector3(float(gx), 0.0, 20.82), rnd.randf_range(0.58, 0.85), rnd.randf() * TAU)

	# 3. Piazzetta San Carlo & Borgo Po: ciuffetti discreti lungo muretti (esclude varco Sud X=4..12)
	for cp in [
		Vector3(-6.8, 0, 17.8), Vector3(-2.8, 0, 24.8), Vector3(3.8, 0, 23.6),
		Vector3(7.6, 0, 24.4), Vector3(1.6, 0, 14.3), Vector3(-8.4, 0, 22.6),
		Vector3(-4.4, 0, 22.2), Vector3(4.5, 0, 19.6), Vector3(-6.2, 0, 28.4),
		Vector3(68.2, 0, 23.9), Vector3(69.1, 0, 21.8), Vector3(72.0, 0, 31.8)
	]:
		sm.grass_tuft("grass_tuft", cp, rnd.randf_range(0.42, 0.60), rnd.randf() * TAU)
	for kx in range(-22, 23, 5):
		sm.grass_tuft("grass_tuft", Vector3(float(kx), 0.0, -8.52), rnd.randf_range(0.68, 0.95), rnd.randf() * TAU)
		if kx >= 4 and kx <= 12:
			continue
		sm.grass_tuft("grass_tuft", Vector3(float(kx), 0.0, 41.52), rnd.randf_range(0.68, 0.95), rnd.randf() * TAU)
	for kx_bp in range(-20, 55, 6):
		if kx_bp >= 4 and kx_bp <= 12:
			continue
		sm.grass_tuft("grass_tuft", Vector3(float(kx_bp), 0.0, 42.48), rnd.randf_range(0.64, 0.92), rnd.randf() * TAU)
	for vx_po in [-16.0, -4.0, 18.0, 31.0, 47.0]:
		sm.grass_tuft("grass_tuft", Vector3(vx_po, 0.0, 54.82), rnd.randf_range(0.52, 0.80), rnd.randf() * TAU)

