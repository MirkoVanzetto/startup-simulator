class_name VillageBuilder
extends RefCounted
## VillageBuilder - Costruttore completo del Borgo San Carlo (stile semi-cartoon unico, zero clipping).

const SHOP_SCRIPT = preload("res://scripts/world/shop_interactable.gd")
const REST_SCRIPT = preload("res://scripts/world/rest_interactable.gd")
const FRIDGE_SCRIPT = preload("res://scripts/world/fridge_interactable.gd")
const MARIO_SCRIPT = preload("res://scripts/world/mario_interactable.gd")
const ELENA_SCRIPT = preload("res://scripts/world/elena_interactable.gd")
const DAVIDE_SCRIPT = preload("res://scripts/world/davide_interactable.gd")

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
	# Tavola legno sotto l'insegna esterna dello Studio
	sm.box("wood_dark", Vector3(0, 2.86, 2.78), Vector3(3.4, 0.44, 0.08))

	var holder := VillageProps.spawn_mesh_and_collisions(studio, "BorgoStudio", sm, "wood")

	# Insegna esterna sopra la porta dello Studio
	_add_sign(holder, "STUDIO TECH · Borgo San Carlo", Vector3(0, 2.86, 2.84), 0.0, 26, Color(1.0, 0.94, 0.74))

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
		"roof": "roof_terracotta"
	})
	# Forno a legna interno sul fondo-sinistra (canna fumaria a filo sotto soffitto 3.2m)
	sm.box("brick", Vector3(-2.6, 0.9, -2.1), Vector3(1.6, 1.8, 1.45), {"col": true})
	sm.cyl("brick", Vector3(-2.6, 1.8, -2.1), 0.34, 0.24, 1.32, 8)
	sm.box("ember_glow", Vector3(-2.6, 0.75, -1.36), Vector3(0.75, 0.45, 0.08))
	# Tavolini interni
	VillageProps.add_table_set(sm, Vector3(2.2, 0.04, 0.8), "fabric_red")
	VillageProps.add_table_set(sm, Vector3(-2.2, 0.04, 0.8), "fabric_red")

	var holder := VillageProps.spawn_mesh_and_collisions(pizzeria, "BorgoPizzeria", sm, "tile")
	_add_sign(holder, "PIZZERIA DA MARIO", Vector3(0, 3.12, 3.37), 0.0, 34, Color(1.0, 0.92, 0.65))

	# Mario NPC sulla pedana rialzata dietro il bancone
	var mario := _spawn_npc(pizzeria, "MarioNPC", Vector3(0.0, 0.18, -1.95), 0.0, MARIO_SCRIPT, {
		"shirt": "white", "pants": "iron", "hair": "hair_brown", "iris": "iris_brown",
		"apron": "fabric_red", "hat": "chef", "mustache": true, "rolled_sleeves": true
	}, "Mario Esposito\n★ Pizzeria Da Mario ★", Color(1.0, 0.9, 0.3))
	mario.name = "MarioNPC"

	# Cassa / Menu Pizzeria per comprare cibo (a fianco sul bancone)
	_spawn_shop_trigger(holder, "PizzeriaShop", Vector3(1.5, 0.96, -1.15), "pizzeria", "Pizzeria Da Mario", Vector3(1.1, 0.9, 0.9))

	# Luce calda interna
	_add_omni(holder, Vector3(0, 2.75, 0), Color(1.0, 0.88, 0.72), 0.55, 8.5)

# ------------------------------------------------------------------ BORGO SAN CARLO (Street)
static func build_village(street: Node3D) -> void:
	if street.has_node("BorgoTerrain"):
		return
	for ch in street.get_children():
		ch.name = ch.name + "_Legacy"
		ch.queue_free()

	# 1. Terreno e pavimentazioni a strati non sovrapposti (tutti top a Y=0.0, spessore sotto Y=0)
	var terrain_sm := StyleMesh.new()
	# Prato di base ampio tutto intorno al borgo
	terrain_sm.box("grass", Vector3(0, -0.24, 18.0), Vector3(96.0, 0.40, 96.0), {"col": true, "surface": "grass"})
	# Via del Borgo (Z: 2.5 .. 13.5, X: -4.2 .. 4.2) top Y=0.0
	terrain_sm.box("cobble", Vector3(0, -0.05, 8.0), Vector3(8.4, 0.10, 11.2), {"col": true, "surface": "stone"})
	# Piazzetta San Carlo (Z: 13.5 .. 27.5, X: -10.5 .. 10.5) top Y=0.0
	terrain_sm.box("cobble", Vector3(0, -0.05, 20.5), Vector3(21.0, 0.10, 14.0), {"col": true, "surface": "stone"})
	# Marciapiedi laterali in lastre davanti allo Studio e ai negozi
	terrain_sm.box("slabs", Vector3(0, -0.04, 3.6), Vector3(7.4, 0.10, 2.0), {"col": true, "surface": "stone"})
	terrain_sm.box("slabs", Vector3(-4.5, -0.04, 8.5), Vector3(1.6, 0.10, 9.5), {"col": true, "surface": "stone"})
	terrain_sm.box("slabs", Vector3(4.5, -0.04, 8.5), Vector3(1.6, 0.10, 9.5), {"col": true, "surface": "stone"})
	# Piazzole parcheggio in asfalto libere dagli edifici (X:[11.4..19.0], Z:[9.1..14.5])
	terrain_sm.box("asphalt", Vector3(-15.2, -0.045, 11.8), Vector3(7.6, 0.09, 5.4), {"col": true, "surface": "asphalt"})
	terrain_sm.box("asphalt", Vector3(15.2, -0.045, 11.8), Vector3(7.6, 0.09, 5.4), {"col": true, "surface": "asphalt"})
	# Sentieri parchetto in ghiaia
	terrain_sm.box("gravel", Vector3(-7.5, -0.04, 30.0), Vector3(4.2, 0.08, 6.0), {"col": true, "surface": "stone"})
	terrain_sm.box("gravel", Vector3(7.5, -0.04, 30.0), Vector3(4.2, 0.08, 6.0), {"col": true, "surface": "stone"})

	# Muretti perimetrali in pietra del borgo
	terrain_sm.box("ashlar", Vector3(0, 0.65, -9.0), Vector3(48.0, 1.3, 0.5), {"col": true})
	terrain_sm.box("ashlar", Vector3(0, 0.65, 42.0), Vector3(48.0, 1.3, 0.5), {"col": true})
	terrain_sm.box("ashlar", Vector3(-24.0, 0.65, 16.5), Vector3(0.5, 1.3, 51.0), {"col": true})
	terrain_sm.box("ashlar", Vector3(24.0, 0.65, 16.5), Vector3(0.5, 1.3, 51.0), {"col": true})

	# Alberi sullo sfondo fuori dal muretto perimetro
	for tx in [-28.0, -16.0, -4.0, 8.0, 20.0]:
		VillageProps.add_tree(terrain_sm, Vector3(tx, 0.0, 45.5), int(absf(tx)) + 30, 1.45)
		VillageProps.add_tree(terrain_sm, Vector3(tx, 0.0, -12.5), int(absf(tx)) + 60, 1.35)

	VillageProps.spawn_mesh_and_collisions(street, "BorgoTerrain", terrain_sm, "stone")

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
	# Macchina espresso sul bancone lato dx + lavagnetta menu e mensola sulla parete di fondo
	cafe_sm.box("steel", Vector3(1.15, 1.18, -1.04), Vector3(0.56, 0.44, 0.42))
	cafe_sm.box("iron", Vector3(1.15, 1.04, -0.82), Vector3(0.46, 0.14, 0.10))
	cafe_sm.box("wood_dark", Vector3(0.0, 2.05, -2.62), Vector3(2.2, 0.92, 0.06))
	cafe_sm.box("iron", Vector3(0.0, 2.05, -2.58), Vector3(1.96, 0.74, 0.03))
	cafe_sm.box("wood_dark", Vector3(1.75, 1.35, -2.48), Vector3(1.45, 0.08, 0.34))
	for cx in [1.35, 1.75, 2.15]:
		cafe_sm.cyl("apron_white", Vector3(cx, 1.39, -2.48), 0.07, 0.08, 0.14, 8)
	VillageProps.add_table_set(cafe_sm, Vector3(-2.4, 0.0, 4.3), "fabric_cream")
	VillageProps.add_table_set(cafe_sm, Vector3(2.4, 0.0, 4.3), "fabric_cream")
	VillageProps.spawn_mesh_and_collisions(cafe_venue, "CafeMesh", cafe_sm, "tile")
	_add_sign(cafe_venue, "CAFFÈ SAN CARLO", Vector3(0, 3.12, 3.06), 0.0, 32, Color(1.0, 0.92, 0.70))
	var elena := _spawn_npc(cafe_venue, "ElenaNPC", Vector3(-0.7, 0.18, -1.86), 0.0, ELENA_SCRIPT, {
		"shirt": "fabric_red", "pants": "iron", "hair": "hair_blonde", "iris": "iris_green",
		"apron": "white", "female": true, "hair_style": "ponytail"
	}, "Elena Rossi\n★ Caffè San Carlo ★", Color(1.0, 0.85, 0.45))
	elena.name = "ElenaNPC"
	_spawn_shop_trigger(cafe_venue, "CafeShop", Vector3(1.2, 0.96, -1.05), "cafe", "Caffè San Carlo", Vector3(1.2, 0.9, 0.9))
	_add_omni(cafe_venue, Vector3(0, 2.7, 0.5), Color(1.0, 0.88, 0.68), 0.55, 8.5)

	var tech_venue := Node3D.new()
	tech_venue.name = "TechShopVenue"
	tech_venue.position = Vector3(13.8, 0, 20.5)
	tech_venue.rotation.y = -PI * 0.5
	street.add_child(tech_venue)
	var tech_sm := StyleMesh.new()
	VillageProps.add_shop_building(tech_sm, Vector3.ZERO, 7.6, 5.8, {
		"wall": "plaster_sky", "floor": "tile_gray", "awning": "awning_blue", "roof": "roof_slate"
	})
	# Scaffali hardware interni
	tech_sm.box("iron", Vector3(-2.6, 1.0, -0.4), Vector3(0.5, 2.0, 2.4), {"col": true})
	tech_sm.box("glass_cool", Vector3(-2.33, 1.35, -0.4), Vector3(0.05, 0.4, 1.8))
	VillageProps.spawn_mesh_and_collisions(tech_venue, "TechMesh", tech_sm, "tile")
	_add_sign(tech_venue, "ELETTRONICA TO", Vector3(0, 3.12, 3.06), 0.0, 32, Color(0.78, 0.94, 1.0))
	var davide := _spawn_npc(tech_venue, "DavideNPC", Vector3(0.0, 0.18, -1.86), 0.0, DAVIDE_SCRIPT, {
		"shirt": "fabric_blue", "pants": "denim", "hair": "hair_dark", "iris": "iris_brown",
		"hair_style": "quiff", "glasses": true, "vest": "vest_charcoal"
	}, "Davide Ferrero\n★ Elettronica TO ★", Color(0.65, 0.88, 1.0))
	davide.name = "DavideNPC"
	_add_omni(tech_venue, Vector3(0, 2.7, 0.5), Color(0.85, 0.94, 1.0), 0.55, 8.5)

	# 4. Negozi del Borgo: Forno Bruno, Alimentari Rosa, Edicola Sabrina
	var panificio := Node3D.new()
	panificio.name = "PanificioVenue"
	panificio.position = Vector3(-8.2, 0, 7.8)
	panificio.rotation.y = PI * 0.5
	street.add_child(panificio)
	var pan_sm := StyleMesh.new()
	VillageProps.add_shop_building(pan_sm, Vector3.ZERO, 6.2, 5.2, {
		"wall": "plaster_ochre", "floor": "wood_light", "awning": "awning_yellow", "roof": "roof_terracotta"
	})
	# Pagnotte sul bancone (top ~0.935) + mensole pane a muro laterali
	for bx in [-0.8, 0.0, 0.8]:
		pan_sm.blob("bread", Vector3(bx, 1.03, -0.94), Vector3(0.24, 0.12, 0.18), 3, 7, 0.06, int(bx * 10) + 5)
	for sx in [-1.85, 1.85]:
		pan_sm.box("wood_dark", Vector3(sx, 1.50, -2.22), Vector3(1.25, 0.07, 0.30))
		for lx in [-0.36, 0.0, 0.36]:
			pan_sm.blob("bread", Vector3(sx + lx, 1.62, -2.22), Vector3(0.16, 0.09, 0.12), 3, 6, 0.05, int((sx + lx) * 9))
	VillageProps.spawn_mesh_and_collisions(panificio, "PanificioMesh", pan_sm, "wood")
	_add_sign(panificio, "FORNO BRUNO", Vector3(0, 3.12, 2.76), 0.0, 30, Color(1.0, 0.92, 0.60))
	_spawn_npc(panificio, "BrunoNPC", Vector3(0.0, 0.18, -1.75), 0.0, SHOP_SCRIPT, {
		"shirt": "shirt_ochre", "pants": "denim", "hair": "hair_salt", "iris": "iris_brown",
		"apron": "white", "hat": "baker", "mustache": true, "rolled_sleeves": true
	}, "Bruno\n★ Forno Bruno ★", Color(1.0, 0.88, 0.50), {"shop_id": "panificio", "shop_title": "Forno Bruno"})
	_spawn_shop_trigger(panificio, "PanificioShop", Vector3(0.0, 0.96, -0.9), "panificio", "Forno Bruno", Vector3(2.8, 0.9, 0.9))

	var alimentari := Node3D.new()
	alimentari.name = "AlimentariVenue"
	alimentari.position = Vector3(8.2, 0, 7.8)
	alimentari.rotation.y = -PI * 0.5
	street.add_child(alimentari)
	var ali_sm := StyleMesh.new()
	VillageProps.add_shop_building(ali_sm, Vector3.ZERO, 6.2, 5.2, {
		"wall": "plaster_sage", "floor": "tile_gray", "awning": "awning_green", "roof": "roof_terracotta"
	})
	# Cassette di frutta davanti + mensole laterali con frutta fresca
	ali_sm.box("wood_light", Vector3(-1.8, 0.35, 3.1), Vector3(1.1, 0.65, 0.55), {"col": true})
	ali_sm.blob("apple", Vector3(-2.0, 0.72, 3.1), Vector3(0.18, 0.14, 0.18), 3, 6, 0.08, 1)
	ali_sm.blob("orange", Vector3(-1.6, 0.72, 3.1), Vector3(0.18, 0.14, 0.18), 3, 6, 0.08, 2)
	for sx in [-1.85, 1.85]:
		ali_sm.box("wood_light", Vector3(sx, 1.48, -2.22), Vector3(1.25, 0.07, 0.30))
		ali_sm.blob("apple", Vector3(sx - 0.35, 1.60, -2.22), Vector3(0.14, 0.12, 0.14), 3, 6, 0.06, 4)
		ali_sm.blob("lemon", Vector3(sx, 1.60, -2.22), Vector3(0.14, 0.11, 0.14), 3, 6, 0.06, 7)
		ali_sm.blob("orange", Vector3(sx + 0.35, 1.60, -2.22), Vector3(0.14, 0.12, 0.14), 3, 6, 0.06, 9)
	VillageProps.spawn_mesh_and_collisions(alimentari, "AlimentariMesh", ali_sm, "tile")
	_add_sign(alimentari, "ALIMENTARI ROSA", Vector3(0, 3.12, 2.76), 0.0, 28, Color(0.84, 1.0, 0.84))
	_spawn_npc(alimentari, "RosaNPC", Vector3(0.0, 0.18, -1.75), 0.0, SHOP_SCRIPT, {
		"shirt": "vest_sage", "pants": "iron", "hair": "hair_chestnut", "iris": "iris_brown",
		"apron": "white", "female": true, "hair_style": "bob", "skirt": true
	}, "Rosa\n★ Alimentari Rosa ★", Color(0.75, 1.0, 0.75), {"shop_id": "alimentari", "shop_title": "Alimentari Rosa"})
	_spawn_shop_trigger(alimentari, "AlimentariShop", Vector3(0.0, 0.96, -0.9), "alimentari", "Alimentari Rosa", Vector3(2.8, 0.9, 0.9))

	# Edicola Sabrina (chiosco in Piazzetta angolo Nord-Est con Sabrina affacciata allo sportello aperto)
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
		"shirt": "fabric_cream", "pants": "denim", "hair": "hair_auburn", "iris": "iris_blue",
		"vest": "vest_charcoal", "female": true, "hair_style": "bob", "glasses": true
	}, "Sabrina\n★ Edicola ★", Color(0.80, 0.92, 1.0), {"shop_id": "edicola", "shop_title": "Edicola Sabrina"})
	_spawn_shop_trigger(edicola, "EdicolaShop", Vector3(0, 1.1, 0.95), "edicola", "Edicola Sabrina", Vector3(2.2, 1.4, 1.2))

	# 5. Case del Borgo attorno allo Studio e alla Piazzetta
	var houses_sm := StyleMesh.new()
	VillageProps.add_house(houses_sm, Vector3(-8.5, 0, 0.0), 6.2, 5.4, 2, {"wall": "plaster_rose", "roof": "roof_terracotta", "shutter": "fabric_green"})
	VillageProps.add_house(houses_sm, Vector3(8.5, 0, 0.0), 6.2, 5.4, 2, {"wall": "plaster_cream", "roof": "roof_slate", "shutter": "fabric_blue"})
	VillageProps.add_house(houses_sm, Vector3(-14.5, 0, 29.5), 6.5, 5.6, 2, {"wall": "plaster_ochre", "roof": "roof_terracotta", "rot": PI * 0.2})
	VillageProps.add_house(houses_sm, Vector3(14.5, 0, 29.5), 6.5, 5.6, 2, {"wall": "plaster_sage", "roof": "roof_slate", "rot": -PI * 0.2})
	VillageProps.add_house(houses_sm, Vector3(-15.5, 0, 5.5), 5.6, 5.4, 2, {"wall": "plaster_cream", "roof": "roof_terracotta", "rot": PI * 0.5})
	VillageProps.add_house(houses_sm, Vector3(15.5, 0, 5.5), 5.6, 5.4, 2, {"wall": "plaster_rose", "roof": "roof_terracotta", "rot": -PI * 0.5})

	# Fontana al centro della Piazzetta San Carlo (0, 0, 21.0)
	VillageProps.add_fountain(houses_sm, Vector3(0, 0, 21.0))

	# Panchine attorno alla fontana e nel parchetto
	VillageProps.add_bench(houses_sm, Vector3(-4.2, 0, 21.0), PI * 0.5)
	VillageProps.add_bench(houses_sm, Vector3(4.2, 0, 21.0), -PI * 0.5)
	VillageProps.add_bench(houses_sm, Vector3(0.0, 0, 16.8), 0.0)
	VillageProps.add_bench(houses_sm, Vector3(-7.5, 0, 29.5), 0.0)
	VillageProps.add_bench(houses_sm, Vector3(7.5, 0, 29.5), 0.0)

	# Lampioni torinesi lungo la via e la piazzetta
	for lp in [
		Vector3(-3.6, 0, 4.8), Vector3(3.6, 0, 4.8),
		Vector3(-3.6, 0, 11.8), Vector3(3.6, 0, 11.8),
		Vector3(-8.6, 0, 16.0), Vector3(8.6, 0, 26.0),
		Vector3(-8.6, 0, 26.0)
	]:
		VillageProps.add_lamp(houses_sm, lp)
		_add_omni(street, lp + Vector3(0, 3.4, 0), Color(1.0, 0.88, 0.62), 0.9, 8.5)

	# Alberi e cespugli nel borgo
	var trees := [
		[Vector3(-5.8, 0, 15.2), 11, 1.05],
		[Vector3(-8.5, 0, 26.5), 12, 1.15],
		[Vector3(8.5, 0, 26.5), 13, 1.10],
		[Vector3(-10.8, 0, 31.5), 14, 1.25],
		[Vector3(10.8, 0, 31.5), 15, 1.20],
		[Vector3(-12.5, 0, -4.5), 16, 1.15],
		[Vector3(12.5, 0, -4.5), 17, 1.10],
		[Vector3(-19.0, 0, 20.5), 18, 1.30],
		[Vector3(19.0, 0, 20.5), 19, 1.25],
	]
	for t in trees:
		VillageProps.add_tree(houses_sm, t[0], t[1], t[2])
	for bp in [
		Vector3(-3.4, 0, 14.5), Vector3(3.4, 0, 14.5),
		Vector3(-5.5, 0, 28.2), Vector3(5.5, 0, 28.2),
		Vector3(-11.2, 0, 15.6), Vector3(11.2, 0, 15.6)
	]:
		VillageProps.add_bush(houses_sm, bp, int(absf(bp.x) * 3), 0.95)

	VillageProps.spawn_mesh_and_collisions(street, "BorgoPropsAndHouses", houses_sm, "stone")

	# 6. Auto parcheggiate affiancate nei due slarghi laterali (fuori dai muri di Caffè ed Elettronica!)
	var street_props := Node3D.new()
	street_props.name = "StreetProps"
	street.add_child(street_props)

	var cars := [
		{"name": "CarHatchback", "pos": Vector3(-13.6, 0.0, 11.8), "rot": 0.0, "color": "car_red"},
		{"name": "CarSedan", "pos": Vector3(-16.6, 0.0, 11.8), "rot": PI, "color": "car_blue"},
		{"name": "CarTaxi", "pos": Vector3(13.6, 0.0, 11.8), "rot": 0.0, "color": "car_cream"},
		{"name": "CarStationWagon", "pos": Vector3(16.6, 0.0, 11.8), "rot": PI, "color": "car_sage"},
	]
	for c in cars:
		var c_sm := StyleMesh.new()
		VillageProps.add_car(c_sm, Vector3.ZERO, c["rot"], c["color"])
		var c_node := VillageProps.spawn_mesh_and_collisions(street_props, c["name"], c_sm, "stone")
		c_node.position = c["pos"]

	# Luce sulla fontana
	_add_omni(street, Vector3(0, 2.6, 21.0), Color(0.75, 0.92, 1.0), 1.1, 10.0)

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
	parent.add_child(lbl)

static func _add_omni(parent: Node3D, pos: Vector3, col: Color, energy: float, rng: float) -> void:
	var l := OmniLight3D.new()
	l.position = pos
	l.light_color = col
	l.light_energy = energy
	l.omni_range = rng
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
