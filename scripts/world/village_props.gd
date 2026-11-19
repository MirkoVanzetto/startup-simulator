class_name VillageProps
extends RefCounted
## VillageProps - Costruttori modulari StyleMesh v1.3 (Torino semi-realistico PBR).
## Ogni componente genera mesh e collisioni accoppiate, con Y=0 come piano di appoggio.

static func spawn_mesh_and_collisions(parent: Node3D, node_name: String, sm: StyleMesh, default_surface: String = "stone") -> Node3D:
	var holder := Node3D.new()
	holder.name = node_name
	parent.add_child(holder)

	if not sm.is_empty():
		var mi := MeshInstance3D.new()
		mi.name = node_name + "Mesh"
		mi.mesh = sm.to_mesh(Callable(VillageMaterials, "mat"))
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		holder.add_child(mi)

	# Raggruppa i collider per surface meta così il PlayerController riconosce i passi
	var bodies: Dictionary = {}
	for c in sm.colliders:
		var surf: String = str(c.get("surface", ""))
		if surf == "":
			surf = default_surface
		if not bodies.has(surf):
			var sb := StaticBody3D.new()
			sb.name = "Col_" + surf
			sb.collision_layer = 1
			sb.collision_mask = 0
			sb.set_meta("surface", surf)
			holder.add_child(sb)
			bodies[surf] = sb
		var body: StaticBody3D = bodies[surf]
		var cs := CollisionShape3D.new()
		var pos: Vector3 = c["pos"]
		var rot: float = float(c.get("rot", 0.0))
		cs.transform = Transform3D(Basis(Vector3.UP, rot), pos)
		if c["type"] == "box":
			var box_shape := BoxShape3D.new()
			box_shape.size = c["size"]
			cs.shape = box_shape
		elif c["type"] == "cyl":
			var cyl_shape := CylinderShape3D.new()
			cyl_shape.radius = float(c["r"])
			cyl_shape.height = float(c["h"])
			cs.shape = cyl_shape
		body.add_child(cs)
	return holder

# ------------------------------------------------------------------ Helper tenda inclinata con mantovana
static func _add_sloped_awning(m: StyleMesh, key: String, cx: float, top_y: float, z_wall: float, w: float, proj: float, drop: float = 0.28) -> void:
	var p_front_y := top_y - drop
	var p_front_z := z_wall + proj
	var thick := 0.06
	var hw := w * 0.5
	var p0 := Vector3(cx - hw, top_y - thick, z_wall)
	var p1 := Vector3(cx + hw, top_y - thick, z_wall)
	var p2 := Vector3(cx + hw, p_front_y - thick, p_front_z)
	var p3 := Vector3(cx - hw, p_front_y - thick, p_front_z)
	var p4 := Vector3(cx - hw, top_y, z_wall)
	var p5 := Vector3(cx + hw, top_y, z_wall)
	var p6 := Vector3(cx + hw, p_front_y, p_front_z)
	var p7 := Vector3(cx - hw, p_front_y, p_front_z)
	m.hexa(key, [p0, p1, p2, p3, p4, p5, p6, p7])
	# Mantovana frontale verticale + braccetti laterali in ferro
	m.box(key, Vector3(cx, p_front_y - 0.10, p_front_z - 0.02), Vector3(w, 0.18, 0.03))
	m.box("iron", Vector3(cx - hw + 0.06, p_front_y - 0.02, z_wall + proj * 0.48), Vector3(0.04, 0.04, proj * 0.96))
	m.box("iron", Vector3(cx + hw - 0.06, p_front_y - 0.02, z_wall + proj * 0.48), Vector3(0.04, 0.04, proj * 0.96))

# ------------------------------------------------------------------ Studio Shell (interno + esterno)
## Costruisce lo Studio/Garage espanso, interno X:[-3.7, 3.7], Z:[-3.3, 2.5], porta Sud X:[-0.9, 0.9].
static func add_studio_shell(sm: StyleMesh) -> void:
	var wt := 0.24
	var h := 3.2
	var cx := 0.0
	var cz := -0.4
	var iw := 7.4
	var id := 5.8
	# Pavimento legno (top a Y=0)
	sm.box("wood_light", Vector3(cx, -0.1, cz), Vector3(iw + wt * 2.0, 0.2, id + wt * 2.0), {"col": true, "surface": "wood"})
	# Soffitto interno con travi a vista
	sm.box("plaster_cream", Vector3(cx, h + 0.08, cz), Vector3(iw + wt * 2.0, 0.16, id + wt * 2.0), {"col": true})
	for bx in [-2.3, 0.0, 2.3]:
		sm.box("wood_dark", Vector3(bx, h - 0.08, cz), Vector3(0.18, 0.16, id - 0.1))
	# Faretti a soffitto discreti
	sm.box("led_white", Vector3(0.0, h - 0.02, -0.4), Vector3(1.15, 0.04, 0.24))
	# Pareti (retro Z=-3.3, sinistra X=-3.7, destra X=+3.7)
	sm.box("plaster_studio", Vector3(0, h * 0.5, -3.3 - wt * 0.5), Vector3(iw + wt * 2.0, h, wt), {"col": true})
	sm.box("plaster_studio", Vector3(-3.7 - wt * 0.5, h * 0.5, cz), Vector3(wt, h, id), {"col": true})
	sm.box("plaster_studio", Vector3(3.7 + wt * 0.5, h * 0.5, cz), Vector3(wt, h, id), {"col": true})
	# Parete frontale (+Z = 2.5) con porta aperta X:[-0.9, 0.9], alta 2.35m
	sm.box("plaster_studio", Vector3(-2.42, h * 0.5, 2.5 + wt * 0.5), Vector3(3.04, h, wt), {"col": true})
	sm.box("plaster_studio", Vector3(2.42, h * 0.5, 2.5 + wt * 0.5), Vector3(3.04, h, wt), {"col": true})
	sm.box("plaster_studio", Vector3(0, 2.35 + (h - 2.35) * 0.5, 2.5 + wt * 0.5), Vector3(1.8, h - 2.35, wt), {"col": true})
	# Stipiti porta modanati + soglia in pietra di Luserna
	sm.box("wood_dark", Vector3(-0.95, 1.175, 2.5 + wt * 0.5), Vector3(0.11, 2.35, wt + 0.09))
	sm.box("wood_dark", Vector3(0.95, 1.175, 2.5 + wt * 0.5), Vector3(0.11, 2.35, wt + 0.09))
	sm.box("wood_dark", Vector3(0, 2.39, 2.5 + wt * 0.5), Vector3(2.02, 0.12, wt + 0.09))
	sm.box("stone_trim", Vector3(0, 0.02, 2.5 + wt * 0.5), Vector3(1.98, 0.04, wt + 0.16))
	# Battente porta a vetri aperto verso l'interno (lato sx, non ostruisce il passaggio)
	sm.box("wood_dark", Vector3(-0.90, 1.16, 2.02), Vector3(0.06, 2.28, 0.88), {"rot": 0.22})
	sm.box("glass_exterior", Vector3(-0.90, 1.38, 2.02), Vector3(0.075, 1.18, 0.64), {"rot": 0.22})
	sm.box("brass", Vector3(-0.81, 1.05, 1.66), Vector3(0.10, 0.05, 0.12), {"rot": 0.22})
	# Applique lampioncini in ferro & ottone ai lati dell'ingresso
	for lx in [-1.24, 1.24]:
		sm.box("iron", Vector3(lx, 1.98, 2.77), Vector3(0.08, 0.08, 0.10))
		sm.box("lamp_glow", Vector3(lx, 1.94, 2.84), Vector3(0.14, 0.22, 0.14))
		sm.hip_roof("iron", Vector3(lx, 2.06, 2.84), 0.18, 0.18, 0.08)
	# Battiscopa interno + fascia boiserie a mezza parete + lesene angolari
	sm.box("wood_dark", Vector3(0, 0.06, -3.27), Vector3(iw - 0.04, 0.12, 0.04))
	sm.box("wood_dark", Vector3(-3.67, 0.06, cz), Vector3(0.04, 0.12, id - 0.04))
	sm.box("wood_dark", Vector3(3.67, 0.06, cz), Vector3(0.04, 0.12, id - 0.04))
	sm.box("wood_mid", Vector3(0, 0.96, -3.275), Vector3(iw - 0.08, 0.045, 0.03))
	sm.box("wood_mid", Vector3(3.675, 0.96, cz), Vector3(0.03, 0.045, id - 0.08))
	sm.box("wood_mid", Vector3(-3.675, 0.96, 1.38), Vector3(0.03, 0.045, 2.2))
	for px in [-3.64, 3.64]:
		for pz in [-3.24, 2.44]:
			sm.box("wood_dark", Vector3(px, h * 0.5, pz), Vector3(0.11, h - 0.12, 0.11))
	# Bacheca appunti/architettura su parete Ovest (libera da finestra e postazione dipendente) + quadro blueprint Torino su parete Nord-Ovest
	sm.box("wood_dark", Vector3(-3.66, 1.72, 1.15), Vector3(0.04, 0.82, 0.96))
	sm.box("burlap", Vector3(-3.635, 1.72, 1.15), Vector3(0.02, 0.72, 0.86))
	sm.box("awning_yellow", Vector3(-3.62, 1.88, 0.96), Vector3(0.015, 0.16, 0.16))
	sm.box("cyan_accent", Vector3(-3.62, 1.76, 1.18), Vector3(0.015, 0.18, 0.18))
	sm.box("fabric_red", Vector3(-3.62, 1.62, 1.36), Vector3(0.015, 0.15, 0.15))
	sm.box("wood_dark", Vector3(-1.55, 1.92, -3.26), Vector3(0.84, 0.62, 0.04))
	sm.box("glass_cool", Vector3(-1.55, 1.92, -3.235), Vector3(0.74, 0.52, 0.02))
	# Davanzale interno finestra Ovest
	sm.box("stone_trim", Vector3(-3.55, 0.94, -0.45), Vector3(0.22, 0.05, 1.34))
	# Finestra luminosa con telaio bianco e traversini sul lato ovest (esterno lucido / interno soleggiato)
	sm.box("wood_dark", Vector3(-3.72, 1.55, -0.45), Vector3(0.32, 1.20, 1.40))
	sm.box("white", Vector3(-3.72, 1.55, -0.45), Vector3(0.34, 1.08, 1.28))
	sm.box("glass_exterior", Vector3(-3.84, 1.55, -0.45), Vector3(0.14, 1.00, 1.20))
	sm.box("glass_studio_day", Vector3(-3.555, 1.55, -0.45), Vector3(0.03, 1.00, 1.20))
	sm.box("white", Vector3(-3.72, 1.55, -0.45), Vector3(0.38, 0.04, 1.20))
	sm.box("white", Vector3(-3.72, 1.55, -0.45), Vector3(0.38, 1.00, 0.04))
	# Due finestre frontali ai lati della porta esterna
	_add_window(sm, Vector3(-2.45, 1.58, 2.5 + wt), 0.0, "fabric_blue", "flower_yellow")
	_add_window(sm, Vector3(2.45, 1.58, 2.5 + wt), 0.0, "fabric_blue", "flower_red")
	# Rivestimento esterno e zoccolo in pietra (ben staccato dagli stipiti |X|>=1.02 senza Z-fighting)
	sm.box("ashlar", Vector3(0, 0.28, -3.3 - wt - 0.025), Vector3(iw + wt * 2.0 + 0.08, 0.56, 0.05))
	sm.box("ashlar", Vector3(-3.7 - wt - 0.025, 0.28, cz), Vector3(0.05, 0.56, id + wt * 2.0))
	sm.box("ashlar", Vector3(3.7 + wt + 0.025, 0.28, cz), Vector3(0.05, 0.56, id + wt * 2.0))
	sm.box("ashlar", Vector3(-2.51, 0.28, 2.5 + wt + 0.025), Vector3(2.96, 0.56, 0.05))
	sm.box("ashlar", Vector3(2.51, 0.28, 2.5 + wt + 0.025), Vector3(2.96, 0.56, 0.05))
	# Cornicione sottotetto ben staccato dal soffitto interno (bottom Y=3.25 > ceiling Y=3.20, zero Z-fighting!)
	sm.box("stone_trim", Vector3(0, h + 0.10, cz), Vector3(iw + wt * 2.0 + 0.24, 0.10, id + wt * 2.0 + 0.24))
	_add_sloped_awning(sm, "awning_blue", 0.0, 2.66, 2.5 + wt + 0.02, 2.48, 0.92, 0.24)
	sm.gable("roof_terracotta", "plaster_ochre", Vector3(0, h + 0.16, cz), iw + 1.0, id + 1.0, 1.75, true)
	# Comignolo in mattoni con cappello in pietra
	sm.box("brick", Vector3(2.4, h + 1.2, -1.7), Vector3(0.45, 1.1, 0.45))
	sm.box("stone_trim", Vector3(2.4, h + 1.77, -1.7), Vector3(0.55, 0.08, 0.55))

# ------------------------------------------------------------------ Letto & Frigo nello Studio
static func add_bed(sm: StyleMesh, pos: Vector3, rot: float = 0.0) -> void:
	var m := StyleMesh.new()
	m.box("wood_dark", Vector3(0, 0.18, 0), Vector3(0.95, 0.12, 1.85), {"col": true})
	for lx in [-0.42, 0.42]:
		for lz in [-0.86, 0.86]:
			m.cyl("wood_dark", Vector3(lx, 0.0, lz), 0.042, 0.036, 0.13, 8)
	m.box("wood_dark", Vector3(0, 0.48, -0.88), Vector3(0.95, 0.54, 0.08))
	m.ellipsoid("white", Vector3(0, 0.30, 0.02), Vector3(0.45, 0.08, 0.87), 5, 10)
	m.box("fabric_blue", Vector3(0, 0.33, 0.26), Vector3(0.91, 0.13, 1.24))
	m.ellipsoid("white", Vector3(0, 0.41, -0.62), Vector3(0.28, 0.06, 0.18), 5, 10)
	_merge_transformed(sm, m, pos, rot)

static func add_fridge(sm: StyleMesh, pos: Vector3, rot: float = 0.0) -> void:
	var m := StyleMesh.new()
	m.box("white", Vector3(0, 0.72, 0), Vector3(0.68, 1.44, 0.64), {"col": true})
	m.box("steel", Vector3(0, 0.92, 0.325), Vector3(0.64, 0.03, 0.02))
	m.box("steel", Vector3(-0.24, 1.15, 0.335), Vector3(0.035, 0.26, 0.03))
	m.box("steel", Vector3(-0.24, 0.60, 0.335), Vector3(0.035, 0.22, 0.03))
	_merge_transformed(sm, m, pos, rot)

# ------------------------------------------------------------------ Edifici del Borgo (case decorative)
static func add_house(sm: StyleMesh, center: Vector3, w: float, d: float, floors: int = 2, opts: Dictionary = {}) -> void:
	var wall_key: String = opts.get("wall", "plaster_cream")
	var roof_key: String = opts.get("roof", "roof_terracotta")
	var shutter_key: String = opts.get("shutter", "fabric_green")
	var rot: float = float(opts.get("rot", 0.0))
	var h := float(floors) * 2.85 + 0.45

	var m := StyleMesh.new()
	# Zoccolo in pietra + corpo principale
	m.box("ashlar", Vector3(0, 0.28, 0), Vector3(w + 0.06, 0.56, d + 0.06))
	m.box(wall_key, Vector3(0, 0.56 + (h - 0.56) * 0.5, 0), Vector3(w, h - 0.56, d), {"col": true})
	# Bugnato d'angolo in pietra chiaro
	for qx in [-w * 0.5 + 0.04, w * 0.5 - 0.04]:
		for qz in [-d * 0.5 + 0.04, d * 0.5 - 0.04]:
			for qi in range(int(floor((h - 0.7) / 0.65))):
				var qy := 0.85 + float(qi) * 0.65
				m.box("stone_trim", Vector3(qx, qy, qz), Vector3(0.24, 0.30, 0.24))
	# Marcapiano + cornicione sottotetto
	if floors >= 2:
		m.box("stone_trim", Vector3(0, 2.95, 0), Vector3(w + 0.08, 0.08, d + 0.08))
	m.box("stone_trim", Vector3(0, h + 0.07, 0), Vector3(w + 0.22, 0.14, d + 0.22))
	# Tetto a capanna con comignolo
	m.gable(roof_key, wall_key, Vector3(0, h + 0.14, 0), w + 0.45, d + 0.45, 1.55, w >= d)
	m.box("brick", Vector3(w * 0.25, h + 1.0, -d * 0.18), Vector3(0.42, 1.0, 0.42))
	m.box("stone_trim", Vector3(w * 0.25, h + 1.52, -d * 0.18), Vector3(0.52, 0.08, 0.52))
	# Portone frontale (+Z) modanato con cornice pietra e maniglia in ottone
	m.box("stone_trim", Vector3(0, 1.12, d * 0.5 + 0.02), Vector3(1.24, 2.20, 0.07))
	m.box("wood_dark", Vector3(0, 1.06, d * 0.5 + 0.04), Vector3(1.04, 2.08, 0.07))
	m.box("glass_exterior", Vector3(0, 1.65, d * 0.5 + 0.075), Vector3(0.68, 0.44, 0.02))
	m.box("brass", Vector3(0.36, 1.02, d * 0.5 + 0.09), Vector3(0.05, 0.14, 0.05))
	m.box("stone_trim", Vector3(0, 2.24, d * 0.5 + 0.05), Vector3(1.36, 0.14, 0.12))
	# Finestre su ogni piano con traversini bianchi, persiane a stecche e fioriere
	var cols: int = clampi(int(floor(w / 2.6)), 1, 3)
	for f in range(floors):
		var wy := 1.45 + float(f) * 2.75
		for ci in range(cols):
			var wx := (float(ci) - float(cols - 1) * 0.5) * 2.3
			if f == 0 and absf(wx) < 0.9:
				continue
			var flw := "flower_red" if (ci + f) % 2 == 0 else "flower_yellow"
			_add_window(m, Vector3(wx, wy, d * 0.5), 0.0, shutter_key, flw)
			_add_window(m, Vector3(wx, wy, -d * 0.5), PI, shutter_key, "")
	_merge_transformed(sm, m, center, rot)

static func _add_window(m: StyleMesh, pos: Vector3, rot: float, shutter_key: String, flower_key: String = "") -> void:
	var wm := StyleMesh.new()
	# Stipite pietra, telaio scuro, serramento bianco con croce centrale, vetro scuro riflettente
	wm.box("stone_trim", Vector3(0, 0.62, 0.04), Vector3(1.04, 0.10, 0.10))
	wm.box("wood_dark", Vector3(0, 0, 0.015), Vector3(0.94, 1.16, 0.05))
	wm.box("white", Vector3(0, 0, 0.032), Vector3(0.84, 1.06, 0.04))
	wm.box("glass_warm", Vector3(0, 0, 0.046), Vector3(0.74, 0.96, 0.025))
	wm.box("white", Vector3(0, 0, 0.062), Vector3(0.04, 0.96, 0.02))
	wm.box("white", Vector3(0, 0.10, 0.062), Vector3(0.74, 0.04, 0.02))
	wm.box("stone_trim", Vector3(0, -0.60, 0.08), Vector3(1.10, 0.10, 0.18))
	# Persiane laterali con rilievo a stecche
	for sx_sh in [-0.62, 0.62]:
		wm.box(shutter_key, Vector3(sx_sh, 0, 0.045), Vector3(0.30, 1.10, 0.045))
		for sy in [-0.36, -0.18, 0.0, 0.18, 0.36]:
			wm.box(shutter_key, Vector3(sx_sh, sy, 0.072), Vector3(0.24, 0.06, 0.02))
	if flower_key != "":
		wm.box("wood_dark", Vector3(0, -0.49, 0.12), Vector3(0.80, 0.14, 0.16))
		wm.foliage_cluster("leaves_canopy", Vector3(0, -0.35, 0.14), 0.24, int(absf(pos.x * 13 + pos.y * 7)) + 3, 4)
		wm.blob(flower_key, Vector3(-0.18, -0.33, 0.16), Vector3(0.065, 0.055, 0.065), 3, 5, 0.08, 5)
		wm.blob(flower_key, Vector3(0.02, -0.31, 0.17), Vector3(0.06, 0.05, 0.06), 3, 5, 0.08, 6)
		wm.blob(flower_key, Vector3(0.20, -0.34, 0.16), Vector3(0.065, 0.055, 0.065), 3, 5, 0.08, 7)
	_merge_transformed(m, wm, pos, rot)

# ------------------------------------------------------------------ Bottega / Negozio accessibile (+Z fronte)
static func add_shop_building(sm: StyleMesh, center: Vector3, w: float, d: float, opts: Dictionary = {}) -> void:
	var wall_key: String = opts.get("wall", "plaster_terracotta")
	var floor_key: String = opts.get("floor", "tile_rc")
	var awning_key: String = opts.get("awning", "awning_red")
	var roof_key: String = opts.get("roof", "roof_terracotta")
	var counter_top: String = opts.get("counter_top", "marble_light")
	var counter_base: String = opts.get("counter_base", "wood_dark")
	var shutter_key: String = opts.get("shutter", "fabric_green")
	var rot: float = float(opts.get("rot", 0.0))
	var h := 3.2
	var upper_h := 2.4
	var wt := 0.24
	var door_w := minf(2.2, w * 0.42)
	var side_w := (w - door_w) * 0.5

	var m := StyleMesh.new()
	# Pavimento interno (top Y=0.04)
	m.box(floor_key, Vector3(0, 0.02, 0), Vector3(w, 0.04, d), {"col": true, "surface": "tile"})
	m.box("plaster_cream", Vector3(0, h + 0.06, 0), Vector3(w, 0.12, d), {"col": true})
	m.box(wall_key, Vector3(0, h * 0.5, -d * 0.5 + wt * 0.5), Vector3(w, h, wt), {"col": true})
	m.box(wall_key, Vector3(-w * 0.5 + wt * 0.5, h * 0.5, 0), Vector3(wt, h, d - wt), {"col": true})
	m.box(wall_key, Vector3(w * 0.5 - wt * 0.5, h * 0.5, 0), Vector3(wt, h, d - wt), {"col": true})
	# Parete frontale (+Z) con ampia apertura porta e vetrine modanate con traversini a croce
	if side_w > 0.2:
		m.box(wall_key, Vector3(-w * 0.5 + side_w * 0.5, h * 0.5, d * 0.5 - wt * 0.5), Vector3(side_w, h, wt), {"col": true})
		m.box(wall_key, Vector3(w * 0.5 - side_w * 0.5, h * 0.5, d * 0.5 - wt * 0.5), Vector3(side_w, h, wt), {"col": true})
		for sx in [-w * 0.5 + side_w * 0.5, w * 0.5 - side_w * 0.5]:
			var vw := minf(1.48, side_w * 0.76)
			m.box("wood_dark", Vector3(sx, 1.38, d * 0.5 + 0.015), Vector3(vw, 1.42, 0.06))
			m.box("white", Vector3(sx, 1.38, d * 0.5 + 0.032), Vector3(vw - 0.10, 1.30, 0.04))
			m.box("glass_exterior", Vector3(sx, 1.38, d * 0.5 + 0.048), Vector3(vw - 0.18, 1.20, 0.025))
			m.box("white", Vector3(sx, 1.38, d * 0.5 + 0.066), Vector3(0.052, 1.20, 0.022))
			m.box("white", Vector3(sx, 1.66, d * 0.5 + 0.066), Vector3(vw - 0.16, 0.048, 0.022))
			m.box("stone_trim", Vector3(sx, 0.65, d * 0.5 + 0.06), Vector3(vw + 0.14, 0.10, 0.16))
	m.box(wall_key, Vector3(0, 2.45 + (h - 2.45) * 0.5, d * 0.5 - wt * 0.5), Vector3(door_w, h - 2.45, wt), {"col": true})
	m.box("wood_dark", Vector3(-door_w * 0.5, 1.22, d * 0.5 - wt * 0.4), Vector3(0.10, 2.44, wt + 0.06))
	m.box("wood_dark", Vector3(door_w * 0.5, 1.22, d * 0.5 - wt * 0.4), Vector3(0.10, 2.44, wt + 0.06))
	# Zoccolo pietra esterno + battiscopa interno
	m.box("ashlar", Vector3(-w * 0.5 - 0.02, 0.28, 0), Vector3(0.05, 0.56, d + 0.06))
	m.box("ashlar", Vector3(w * 0.5 + 0.02, 0.28, 0), Vector3(0.05, 0.56, d + 0.06))
	m.box("wood_dark", Vector3(0, 0.09, -d * 0.5 + wt + 0.02), Vector3(w - wt * 2.0, 0.10, 0.04))
	# Tenda da sole inclinata con mantovana + tavola insegna modanata
	_add_sloped_awning(m, awning_key, 0.0, 2.86, d * 0.5 + 0.02, w * 0.84, 1.15, 0.30)
	m.box("wood_dark", Vector3(0, 3.12, d * 0.5 + 0.08), Vector3(w * 0.68, 0.44, 0.10))
	# Bancone interno sul fondo (alto 0.93m) con doghe/specchiature in falegnameria e piano in pietra
	var c_w := w * 0.62
	var c_z := -d * 0.18
	m.box(counter_base, Vector3(0, 0.45, c_z), Vector3(c_w, 0.84, 0.74), {"col": true})
	if counter_base == "wood_plank":
		for py in [0.22, 0.44, 0.66]:
			m.box("wood_dark", Vector3(0, py, c_z + 0.376), Vector3(c_w - 0.04, 0.018, 0.014))
		m.box("wood_dark", Vector3(-c_w * 0.49, 0.45, c_z), Vector3(0.05, 0.84, 0.76))
		m.box("wood_dark", Vector3(c_w * 0.49, 0.45, c_z), Vector3(0.05, 0.84, 0.76))
	else:
		var trim_mat := "wood_mid" if counter_base == "wood_dark" else counter_base
		m.box(trim_mat, Vector3(0, 0.085, c_z + 0.380), Vector3(c_w - 0.04, 0.09, 0.018))
		m.box(trim_mat, Vector3(0, 0.825, c_z + 0.380), Vector3(c_w - 0.04, 0.07, 0.018))
		for px in [-c_w * 0.46, 0.0, c_w * 0.46]:
			m.box(trim_mat, Vector3(px, 0.46, c_z + 0.380), Vector3(0.075, 0.68, 0.018))
	m.box(counter_top, Vector3(0, 0.91, c_z), Vector3(w * 0.68, 0.085, 0.88))
	m.box("wood_light", Vector3(0, 0.11, c_z - 0.82), Vector3(w * 0.54, 0.14, 0.95), {"col": true, "surface": "wood"})
	# Piano superiore abitativo + cornicione + tetto a capanna
	var y_up := h + 0.12
	m.box("stone_trim", Vector3(0, y_up - 0.02, 0), Vector3(w + 0.10, 0.10, d + 0.10))
	m.box(wall_key, Vector3(0, y_up + upper_h * 0.5, 0), Vector3(w, upper_h, d), {"col": true})
	m.box("stone_trim", Vector3(0, y_up + upper_h + 0.06, 0), Vector3(w + 0.22, 0.12, d + 0.22))
	var cols: int = clampi(int(floor(w / 2.6)), 1, 3)
	for ci in range(cols):
		var wx := (float(ci) - float(cols - 1) * 0.5) * 2.4
		_add_window(m, Vector3(wx, y_up + 1.25, d * 0.5), 0.0, shutter_key, "flower_red" if ci % 2 == 0 else "")
	m.gable(roof_key, wall_key, Vector3(0, y_up + upper_h + 0.12, 0), w + 0.45, d + 0.45, 1.45, w >= d)
	_merge_transformed(sm, m, center, rot)

# ------------------------------------------------------------------ Edicola Sabrina
static func add_edicola(sm: StyleMesh, pos: Vector3, rot: float = 0.0) -> void:
	var m := StyleMesh.new()
	m.box("ashlar", Vector3(0, 0.12, 0), Vector3(2.8, 0.24, 2.2), {"col": true, "surface": "stone"})
	m.box("plaster_sky", Vector3(0, 1.35, -0.78), Vector3(2.5, 2.25, 0.28), {"col": true})
	m.box("plaster_sky", Vector3(-1.12, 1.35, 0.05), Vector3(0.26, 2.25, 1.75), {"col": true})
	m.box("plaster_sky", Vector3(1.12, 1.35, 0.05), Vector3(0.26, 2.25, 1.75), {"col": true})
	m.box("plaster_sky", Vector3(0, 0.62, 0.84), Vector3(2.0, 0.78, 0.20), {"col": true})
	m.box("plaster_sky", Vector3(0, 2.26, 0.84), Vector3(2.0, 0.44, 0.20), {"col": true})
	m.box("wood_dark", Vector3(0, 1.02, 0.96), Vector3(2.1, 0.10, 0.40))
	m.box("glass_exterior", Vector3(0, 1.98, 0.90), Vector3(1.96, 0.22, 0.04))
	for i in range(4):
		var k: String = ["fabric_red", "fabric_blue", "awning_yellow", "fabric_green"][i]
		m.box(k, Vector3(-0.68 + float(i) * 0.45, 1.11, 1.04), Vector3(0.32, 0.08, 0.24))
	_add_sloped_awning(m, "awning_blue", 0.0, 2.40, 0.90, 2.7, 0.85, 0.22)
	m.box("wood_dark", Vector3(0, 2.40, 1.69), Vector3(2.25, 0.28, 0.06))
	m.hip_roof("roof_slate", Vector3(0, 2.48, 0), 3.1, 2.5, 0.85)
	_merge_transformed(sm, m, pos, rot)

# ------------------------------------------------------------------ Fontana del Borgo
static func add_fountain(sm: StyleMesh, pos: Vector3) -> void:
	# Vasca ottagonale con fondo scuro umido, cordoli scolpiti, acqua increspata e getti parabolici
	sm.cyl("stone_dark", pos + Vector3(0, 0.01, 0), 1.92, 1.92, 0.10, 12, {"smooth": false})
	sm.cyl("stone_trim", pos, 2.15, 2.22, 0.36, 8, {"smooth": false})
	for k in range(8):
		var a := TAU * (float(k) + 0.5) / 8.0
		var bp := pos + Vector3(cos(a) * 1.98, 0.46, sin(a) * 1.98)
		var seg := StyleMesh.new()
		seg.beveled_curb_block("stone_trim", Vector3.ZERO, 0.38, 1.64, 0.24, 0.0)
		_merge_transformed(sm, seg, bp - Vector3(0, 0.12, 0), -a)
	sm.cyl("water", pos + Vector3(0, 0.40, 0), 1.84, 1.84, 0.06, 20, {"smooth": true})
	# Colonna centrale tornita e vasca superiore
	sm.lathe_oval("stone_trim", pos + Vector3(0, 0.42, 0), [
		Vector2(0.56, 0.0), Vector2(0.46, 0.14), Vector2(0.32, 0.48),
		Vector2(0.48, 0.78), Vector2(0.92, 0.94), Vector2(0.86, 1.02), Vector2(0.10, 0.98)
	], 1.0, 1.0, 16)
	sm.cyl("water", pos + Vector3(0, 1.41, 0), 0.78, 0.78, 0.04, 16, {"smooth": true})
	sm.lathe_oval("stone_trim", pos + Vector3(0, 1.42, 0), [
		Vector2(0.24, 0.0), Vector2(0.18, 0.24), Vector2(0.22, 0.42), Vector2(0.12, 0.54)
	], 1.0, 1.0, 14)
	# Zampillo verticale sottile + 8 archi d'acqua parabolici dalla tazza superiore alla vasca
	sm.cyl("water_spray", pos + Vector3(0, 1.94, 0), 0.032, 0.09, 0.54, 12, {"smooth": true, "cap_top": false})
	for ji in range(8):
		var ang := TAU * float(ji) / 8.0
		var dir_xz := Vector3(cos(ang), 0.0, sin(ang))
		var arc_pts: Array[Vector3] = []
		var arc_r: Array[float] = [0.022, 0.026, 0.030, 0.034, 0.040]
		for si in range(5):
			var u := float(si) / 4.0
			var rad := 0.80 + u * 0.48
			var y := 1.43 + sin(u * PI * 0.5) * 0.10 - u * u * 1.04
			arc_pts.append(pos + dir_xz * rad + Vector3(0.0, y, 0.0))
		sm.tube_path("water_spray", arc_pts, arc_r, 6, false)
	sm.add_collider_cyl(pos + Vector3(0, 0.55, 0), 2.25, 1.1)

# ------------------------------------------------------------------ Natura & Arredo Urbano
static func add_tree(sm: StyleMesh, pos: Vector3, seed_val: int = 1, s: float = 1.0) -> void:
	var rnd := RandomNumberGenerator.new()
	rnd.seed = seed_val
	var lean_x := rnd.randf_range(-0.22, 0.22) * s
	var lean_z := rnd.randf_range(-0.22, 0.22) * s
	# Tronco nodoso affusolato + radici alla base + biforcazione rami principali
	var fork := pos + Vector3(lean_x, 1.72 * s, lean_z)
	sm.tube_path("bark", [
		pos + Vector3(0, -0.05, 0),
		pos + Vector3(lean_x * 0.25, 0.45 * s, lean_z * 0.25),
		pos + Vector3(lean_x * 0.75, 1.15 * s, lean_z * 0.75),
		fork,
	], [0.30 * s, 0.21 * s, 0.17 * s, 0.14 * s], 9, false)
	# 3-4 rami contorti + ampi ammassi di fogliame 3D alpha-scissored (proietta ombre frastagliate!)
	var b_angles := [0.4, 2.5, 4.6]
	for bi in range(3):
		var a := float(b_angles[bi]) + rnd.randf_range(-0.35, 0.35)
		var reach := rnd.randf_range(0.75, 1.08) * s
		var tip_y := rnd.randf_range(2.35, 2.85) * s
		var mid_p := fork.lerp(pos + Vector3(cos(a) * reach * 0.55, tip_y * 0.85, sin(a) * reach * 0.55), 0.6)
		var tip_p := pos + Vector3(cos(a) * reach + lean_x * 0.5, tip_y, sin(a) * reach + lean_z * 0.5)
		sm.tube_path("bark", [fork, mid_p, tip_p], [0.11 * s, 0.08 * s, 0.045 * s], 7, true)
		var mat_k := "leaves_canopy" if bi != 1 else "leaves_canopy_dark"
		sm.foliage_cluster(mat_k, tip_p + Vector3(0, 0.22 * s, 0), 1.08 * s, seed_val + bi * 17, 7)
	# Chioma centrale alta luminosa
	sm.foliage_cluster("leaves_canopy", fork + Vector3(0, 1.32 * s, 0), 1.32 * s, seed_val + 53, 8)
	sm.add_collider_cyl(pos + Vector3(0, 1.1 * s, 0), 0.38 * s, 2.2 * s)

static func add_bush(sm: StyleMesh, pos: Vector3, seed_val: int = 2, s: float = 1.0) -> void:
	sm.foliage_cluster("leaves_canopy_dark", pos + Vector3(0, 0.38 * s, 0), 0.62 * s, seed_val, 6)
	sm.foliage_cluster("leaves_canopy", pos + Vector3(0, 0.52 * s, 0), 0.50 * s, seed_val + 11, 5)
	sm.add_collider_cyl(pos + Vector3(0, 0.42 * s, 0), 0.55 * s, 0.85 * s)

static func add_bench(sm: StyleMesh, pos: Vector3, rot: float = 0.0) -> void:
	var m := StyleMesh.new()
	# Gambe in pietra scolpita + doghe in legno smussato + staffe in ferro
	m.add_collider_box(Vector3(0, 0.44, 0), Vector3(1.68, 0.80, 0.56))
	for sx in [-0.66, 0.66]:
		m.beveled_curb_block("stone_trim", Vector3(sx, 0.0, 0.0), 0.14, 0.48, 0.40, 0.0)
		m.box("iron", Vector3(sx, 0.58, -0.22), Vector3(0.05, 0.42, 0.05), {"rot": 0.0})
	for sz in [-0.14, 0.0, 0.14]:
		m.box("wood_light", Vector3(0, 0.43, sz), Vector3(1.68, 0.045, 0.12))
	for sy in [0.64, 0.80]:
		m.box("wood_light", Vector3(0, sy, -0.22), Vector3(1.68, 0.12, 0.05))
	_merge_transformed(sm, m, pos, rot)

static func add_lamp(sm: StyleMesh, pos: Vector3) -> void:
	sm.cyl("iron", pos, 0.18, 0.13, 0.36, 10)
	sm.cyl("iron", pos + Vector3(0, 0.36, 0), 0.11, 0.075, 0.35, 10)
	sm.cyl("iron", pos + Vector3(0, 0.71, 0), 0.068, 0.046, 2.58, 10)
	sm.box("iron", pos + Vector3(0, 3.29, 0), Vector3(0.30, 0.06, 0.30))
	sm.box("lamp_glow", pos + Vector3(0, 3.48, 0), Vector3(0.28, 0.34, 0.28))
	for cx in [-0.15, 0.15]:
		for cz in [-0.15, 0.15]:
			sm.box("iron", pos + Vector3(cx, 3.48, cz), Vector3(0.03, 0.36, 0.03))
	sm.hip_roof("iron", pos + Vector3(0, 3.66, 0), 0.44, 0.44, 0.20)
	sm.cyl("iron", pos + Vector3(0, 3.85, 0), 0.035, 0.01, 0.10, 6)
	sm.add_collider_cyl(pos + Vector3(0, 1.5, 0), 0.18, 3.0)

static func add_table_set(sm: StyleMesh, pos: Vector3, cloth_key: String = "fabric_red") -> void:
	sm.cyl("iron", pos, 0.28, 0.05, 0.72, 10)
	sm.cyl(cloth_key, pos + Vector3(0, 0.72, 0), 0.52, 0.52, 0.06, 14)
	sm.add_collider_cyl(pos + Vector3(0, 0.4, 0), 0.52, 0.8)
	for sx in [-0.72, 0.72]:
		sm.box("wood_dark", pos + Vector3(sx, 0.42, 0), Vector3(0.38, 0.05, 0.38))
		sm.box("wood_dark", pos + Vector3(sx + signf(sx) * 0.16, 0.66, 0), Vector3(0.05, 0.48, 0.38))
		sm.box("iron", pos + Vector3(sx, 0.21, 0), Vector3(0.32, 0.42, 0.32))

static func add_parasol(sm: StyleMesh, pos: Vector3, cloth_key: String = "fabric_cream") -> void:
	sm.cyl("wood_dark", pos + Vector3(0, 0.76, 0), 0.035, 0.03, 1.72, 8)
	sm.cyl(cloth_key, pos + Vector3(0, 2.26, 0), 1.35, 0.12, 0.44, 8, {"smooth": false, "cap_top": false})
	sm.cyl("brass", pos + Vector3(0, 2.69, 0), 0.05, 0.015, 0.10, 6)

# ------------------------------------------------------------------ Auto e furgoni scolpiti (ruote tonde Y=0 esatto)
static func _merge_rotated_x_cyl(sm: StyleMesh, center: Vector3, radius: float, width: float, sides: int, tire_key: String, rim_key: String) -> void:
	# Costruisce una ruota cilindrica con asse su X (bordo inferiore esatto a center.y - radius)
	var m := StyleMesh.new()
	m.cyl(tire_key, Vector3(0, -width * 0.5, 0), radius, radius, width, sides)
	m.cyl(rim_key, Vector3(0, -width * 0.5 - 0.01, 0), radius * 0.58, radius * 0.58, width + 0.02, sides)
	m.cyl("iron", Vector3(0, -width * 0.5 - 0.018, 0), radius * 0.22, radius * 0.22, width + 0.036, 8)
	# Rotazione manuale +90° attorno all'asse Z: (x, y, z) -> (-y, x, z)
	for key in m._surf:
		var s_src: Dictionary = m._surf[key]
		var s_dst: Dictionary = sm._s(key)
		var base: int = s_dst["v"].size()
		var sv: PackedVector3Array = s_src["v"]
		var sn: PackedVector3Array = s_src["n"]
		var suv: PackedVector2Array = s_src["uv"]
		var si: PackedInt32Array = s_src["i"]
		for k in range(sv.size()):
			var p := sv[k]
			var n := sn[k]
			s_dst["v"].append(Vector3(-p.y, p.x, p.z) + center)
			s_dst["n"].append(Vector3(-n.y, n.x, n.z))
			s_dst["uv"].append(suv[k])
		for idx in si:
			s_dst["i"].append(base + idx)

static func add_car_wheel_mesh(tire_key: String = "tire", rim_key: String = "steel", radius: float = 0.30, width: float = 0.22) -> ArrayMesh:
	var m := StyleMesh.new()
	_merge_rotated_x_cyl(m, Vector3.ZERO, radius, width, 18, tire_key, rim_key)
	for si in range(3):
		var a := float(si) * PI / 3.0
		m.box("iron", Vector3(width * 0.505, 0.0, 0.0), Vector3(0.018, radius * 1.12, 0.036), {"rot": 0.0})
		var sp := StyleMesh.new()
		sp.box("iron", Vector3(width * 0.505, 0.0, 0.0), Vector3(0.018, 0.036, radius * 1.10))
		for key in sp._surf:
			var s_src: Dictionary = sp._surf[key]
			var s_dst: Dictionary = m._s(key)
			var base: int = s_dst["v"].size()
			var sv: PackedVector3Array = s_src["v"]
			var sn: PackedVector3Array = s_src["n"]
			var suv: PackedVector2Array = s_src["uv"]
			for k in range(sv.size()):
				s_dst["v"].append(sv[k].rotated(Vector3.RIGHT, a))
				s_dst["n"].append(sn[k].rotated(Vector3.RIGHT, a))
				s_dst["uv"].append(suv[k])
			for idx in s_src["i"]:
				s_dst["i"].append(base + idx)
		m.box("iron", Vector3(-width * 0.505, 0.0, 0.0), Vector3(0.018, radius * 0.4, radius * 0.4))
	return m.to_mesh(Callable(VillageMaterials, "mat"))

static func add_car_body(sm: StyleMesh, pos: Vector3, rot: float = 0.0, color_key: String = "car_red") -> void:
	var m := StyleMesh.new()
	m.add_collider_box(Vector3(0, 0.68, 0), Vector3(1.68, 1.24, 3.60))
	# Fondo scocca scuro + passaruota + minigonne laterali
	m.box("iron_dark", Vector3(0, 0.34, 0), Vector3(1.48, 0.14, 3.36))
	for sx in [-0.74, 0.74]:
		m.box("iron_dark", Vector3(sx, 0.38, 0.0), Vector3(0.16, 0.14, 1.32))
		for wz in [-1.08, 1.08]:
			m.box("iron_dark", Vector3(sx, 0.42, wz), Vector3(0.18, 0.34, 0.72))
			m.box("iron_dark", Vector3(sx + signf(sx) * 0.09, 0.56, wz), Vector3(0.05, 0.14, 0.76))
	# Scocca principale divisa attorno ai passaruota (anteriore, centrale tra le ruote, coda posteriore)
	m.box(color_key, Vector3(0, 0.56, 0.0), Vector3(1.64, 0.44, 1.46))
	m.box(color_key, Vector3(0, 0.58, 1.44), Vector3(1.60, 0.40, 0.48))
	m.box(color_key, Vector3(0, 0.58, -1.44), Vector3(1.60, 0.42, 0.48))
	m.box(color_key, Vector3(0, 0.69, 0.0), Vector3(1.66, 0.20, 3.52))
	# Cofano sagomato inclinato (+Z fronte) + linea di cintura
	m.hexa(color_key, [
		Vector3(-0.80, 0.76, 0.66), Vector3(0.80, 0.76, 0.66), Vector3(0.76, 0.66, 1.78), Vector3(-0.76, 0.66, 1.78),
		Vector3(-0.74, 0.85, 0.70), Vector3(0.74, 0.85, 0.70), Vector3(0.70, 0.72, 1.72), Vector3(-0.70, 0.72, 1.72),
	])
	# Portabagagli / lunotto posteriore (-Z coda)
	m.hexa(color_key, [
		Vector3(-0.79, 0.76, -1.76), Vector3(0.79, 0.76, -1.76), Vector3(0.80, 0.76, -1.06), Vector3(-0.80, 0.76, -1.06),
		Vector3(-0.72, 0.84, -1.72), Vector3(0.72, 0.84, -1.72), Vector3(0.74, 0.84, -1.06), Vector3(-0.74, 0.84, -1.06),
	])
	# Abitacolo rastremato e vetrato con montanti A, B, C e tetto profilato
	m.hexa(color_key, [
		Vector3(-0.76, 0.78, -1.14), Vector3(0.76, 0.78, -1.14), Vector3(0.76, 0.78, 0.74), Vector3(-0.76, 0.78, 0.74),
		Vector3(-0.62, 1.32, -0.84), Vector3(0.62, 1.32, -0.84), Vector3(0.62, 1.32, 0.36), Vector3(-0.62, 1.32, 0.36),
	])
	m.hexa("glass_exterior", [
		Vector3(-0.77, 0.82, -1.02), Vector3(0.77, 0.82, -1.02), Vector3(0.77, 0.82, 0.68), Vector3(-0.77, 0.82, 0.68),
		Vector3(-0.635, 1.26, -0.78), Vector3(0.635, 1.26, -0.78), Vector3(0.635, 1.26, 0.33), Vector3(-0.635, 1.26, 0.33),
	])
	# Montante B verticale & barre tetto
	m.box("iron_dark", Vector3(0, 1.05, -0.14), Vector3(1.43, 0.44, 0.08))
	for rx in [-0.52, 0.52]:
		m.box("iron_dark", Vector3(rx, 1.34, -0.24), Vector3(0.04, 0.03, 1.05))
	# Specchietti su stelo, maniglie porte cromate & fascioni paracolpi
	for sx in [-0.88, 0.88]:
		m.box("iron_dark", Vector3(sx - signf(sx) * 0.06, 0.85, 0.44), Vector3(0.10, 0.035, 0.05))
		m.box(color_key, Vector3(sx, 0.88, 0.43), Vector3(0.14, 0.08, 0.11))
		m.box("steel", Vector3(sx * 0.96, 0.71, 0.12), Vector3(0.03, 0.03, 0.15))
		m.box("steel", Vector3(sx * 0.96, 0.71, -0.52), Vector3(0.03, 0.03, 0.15))
		m.box("iron_dark", Vector3(sx * 0.955, 0.54, 0.0), Vector3(0.03, 0.06, 1.38))
	# Paraurti anteriore & posteriore + calandra + targhe + fari LED + stop posteriori
	m.box("iron_dark", Vector3(0, 0.34, 1.77), Vector3(1.64, 0.18, 0.14))
	m.box("iron_dark", Vector3(0, 0.34, -1.77), Vector3(1.64, 0.18, 0.14))
	m.box("iron_dark", Vector3(0, 0.56, 1.77), Vector3(0.86, 0.18, 0.04))
	m.box("steel", Vector3(0, 0.57, 1.79), Vector3(0.76, 0.03, 0.02))
	m.box("white", Vector3(0, 0.37, 1.845), Vector3(0.42, 0.09, 0.02))
	m.box("white", Vector3(0, 0.44, -1.845), Vector3(0.42, 0.09, 0.02))
	for fx in [-0.58, 0.58]:
		m.box("lamp_glow", Vector3(fx, 0.60, 1.77), Vector3(0.26, 0.12, 0.04))
		m.box("awning_yellow", Vector3(fx + signf(fx) * 0.14, 0.60, 1.765), Vector3(0.07, 0.11, 0.045))
		m.box("fabric_red", Vector3(fx, 0.64, -1.77), Vector3(0.28, 0.12, 0.04))
		m.box("awning_yellow", Vector3(fx + signf(fx) * 0.12, 0.58, -1.775), Vector3(0.10, 0.06, 0.042))
	_merge_transformed(sm, m, pos, rot)

static func add_car(sm: StyleMesh, pos: Vector3, rot: float = 0.0, color_key: String = "car_red") -> void:
	var m := StyleMesh.new()
	var wr := 0.30
	for wx in [-0.76, 0.76]:
		for wz in [-1.06, 1.06]:
			_merge_rotated_x_cyl(m, Vector3(wx, wr, wz), wr, 0.22, 16, "tire", "steel")
	add_car_body(m, Vector3.ZERO, 0.0, color_key)
	_merge_transformed(sm, m, pos, rot)

static func add_delivery_van(sm: StyleMesh, pos: Vector3, rot: float = 0.0, color_key: String = "car_cream") -> void:
	var m := StyleMesh.new()
	var wr := 0.31
	for wx in [-0.85, 0.85]:
		for wz in [-1.24, 1.24]:
			_merge_rotated_x_cyl(m, Vector3(wx, wr, wz), wr, 0.24, 16, "tire", "steel")
	# Cassone furgone europeo classico (anni '90/'00 con nervatura fiancata, tetto leggermente bombato)
	m.box(color_key, Vector3(0, 1.18, -0.52), Vector3(1.86, 1.58, 2.74))
	m.box(color_key, Vector3(0, 1.98, -0.52), Vector3(1.74, 0.08, 2.64))
	m.add_collider_box(Vector3(0, 0.98, 0.0), Vector3(1.86, 1.85, 3.84))
	# Modanatura laterale bassa nera, parafanghi ruota e fascia azzurra aziendale
	m.box("iron", Vector3(0, 0.44, -0.52), Vector3(1.88, 0.12, 2.66))
	m.box("cyan_accent", Vector3(0, 1.12, -0.52), Vector3(1.88, 0.14, 2.40))
	for fx in [-0.91, 0.91]:
		for fz in [-1.24, 1.24]:
			m.box("iron", Vector3(fx, 0.50, fz), Vector3(0.08, 0.12, 0.68))
	# Muso e cabina sagomata (+Z fronte) con parabrezza inclinato e cofano corto
	m.box(color_key, Vector3(0, 0.66, 1.32), Vector3(1.82, 0.66, 1.12))
	m.hexa(color_key, [
		Vector3(-0.88, 0.98, 0.84), Vector3(0.88, 0.98, 0.84), Vector3(0.86, 0.98, 1.54), Vector3(-0.86, 0.98, 1.54),
		Vector3(-0.80, 1.88, 0.86), Vector3(0.80, 1.88, 0.86), Vector3(0.78, 1.72, 1.34), Vector3(-0.78, 1.72, 1.34),
	])
	# Parabrezza frontale, finestrini porta & maniglie cabina
	m.hexa("glass_exterior", [
		Vector3(-0.76, 1.06, 1.48), Vector3(0.76, 1.06, 1.48), Vector3(0.78, 1.06, 1.58), Vector3(-0.78, 1.06, 1.58),
		Vector3(-0.72, 1.66, 1.24), Vector3(0.72, 1.66, 1.24), Vector3(0.72, 1.66, 1.38), Vector3(-0.72, 1.66, 1.38),
	])
	m.box("glass_exterior", Vector3(0, 1.36, 1.18), Vector3(1.80, 0.50, 0.56))
	for sx in [-0.92, 0.92]:
		m.box("iron", Vector3(sx, 0.86, 1.05), Vector3(0.025, 0.045, 0.16))
		m.box("iron", Vector3(sx, 1.00, 0.86), Vector3(0.02, 1.18, 0.025))
	# Portelloni posteriori (-Z = -1.90) con guarnizione centrale, maniglie, targa e fari posteriori
	m.box("iron", Vector3(0.0, 1.18, -1.90), Vector3(0.035, 1.48, 0.03))
	m.box("steel", Vector3(-0.08, 1.02, -1.905), Vector3(0.04, 0.14, 0.035))
	m.box("white", Vector3(0.0, 0.58, -1.905), Vector3(0.46, 0.11, 0.03))
	for rx in [-0.78, 0.78]:
		m.box("fabric_red", Vector3(rx, 0.62, -1.90), Vector3(0.18, 0.28, 0.04))
		m.box("awning_yellow", Vector3(rx, 0.72, -1.905), Vector3(0.16, 0.08, 0.042))
	# Specchietti retrovisori esterni, calandra rigata, fari anteriori + frecce e paraurti
	for sx in [-0.98, 0.98]:
		m.box("iron", Vector3(sx, 1.28, 1.32), Vector3(0.10, 0.24, 0.10))
	m.box("iron", Vector3(0, 0.68, 1.88), Vector3(1.06, 0.30, 0.05))
	m.box("steel", Vector3(0, 0.74, 1.905), Vector3(0.98, 0.03, 0.02))
	m.box("steel", Vector3(0, 0.64, 1.905), Vector3(0.98, 0.03, 0.02))
	m.box("white", Vector3(0, 0.44, 1.90), Vector3(0.46, 0.11, 0.03))
	m.box("iron", Vector3(0, 0.34, 1.90), Vector3(1.82, 0.18, 0.14))
	m.box("iron", Vector3(0, 0.34, -1.92), Vector3(1.82, 0.18, 0.14))
	m.box("lamp_glow", Vector3(-0.66, 0.68, 1.88), Vector3(0.24, 0.18, 0.04))
	m.box("lamp_glow", Vector3(0.66, 0.68, 1.88), Vector3(0.24, 0.18, 0.04))
	m.box("awning_yellow", Vector3(-0.82, 0.68, 1.875), Vector3(0.10, 0.18, 0.045))
	m.box("awning_yellow", Vector3(0.82, 0.68, 1.875), Vector3(0.10, 0.18, 0.045))
	_merge_transformed(sm, m, pos, rot)

# ------------------------------------------------------------------ Arco Stradale, Pozzo & Cartelli (Borgo Valdocco)
static func add_archway_gate(sm: StyleMesh, pos: Vector3, width: float = 6.2, height: float = 3.7, rot: float = 0.0) -> void:
	var m := StyleMesh.new()
	var px := width * 0.5
	for sx in [-px, px]:
		m.box("brick", Vector3(sx, height * 0.5, 0), Vector3(0.74, height, 0.74), {"col": true})
		m.box("stone_trim", Vector3(sx, 0.35, 0), Vector3(0.84, 0.70, 0.84))
		m.box("stone_trim", Vector3(sx, height + 0.12, 0), Vector3(0.92, 0.22, 0.92))
	m.box("wood_dark", Vector3(0, height - 0.18, 0), Vector3(width + 0.6, 0.56, 0.34))
	m.box("stone_trim", Vector3(0, height + 0.14, 0), Vector3(width + 0.7, 0.14, 0.44))
	_merge_transformed(sm, m, pos, rot)

static func add_well(sm: StyleMesh, pos: Vector3) -> void:
	sm.cyl("ashlar", pos, 0.96, 0.92, 0.78, 12, {"smooth": false})
	sm.cyl("stone_trim", pos + Vector3(0, 0.78, 0), 1.04, 1.04, 0.12, 12, {"smooth": false})
	sm.cyl("water", pos + Vector3(0, 0.52, 0), 0.74, 0.74, 0.04, 12, {"smooth": true})
	for sx in [-0.78, 0.78]:
		sm.box("wood_dark", pos + Vector3(sx, 1.48, 0), Vector3(0.14, 1.40, 0.14))
	sm.box("wood_dark", pos + Vector3(0, 1.45, 0), Vector3(1.52, 0.08, 0.08))
	sm.cyl("copper", pos + Vector3(0.22, 1.10, 0), 0.12, 0.14, 0.24, 10)
	sm.gable("roof_terracotta", "wood_mid", pos + Vector3(0, 2.15, 0), 2.15, 1.65, 0.72, true)
	sm.add_collider_cyl(pos + Vector3(0, 0.85, 0), 1.06, 1.7)

static func add_road_sign(sm: StyleMesh, pos: Vector3, rot: float = 0.0) -> void:
	var m := StyleMesh.new()
	m.cyl("iron", Vector3(0, 0, 0), 0.06, 0.05, 2.45, 8)
	m.box("iron", Vector3(0, 2.05, 0), Vector3(1.75, 0.72, 0.08))
	m.box("wood_mid", Vector3(0, 2.05, 0), Vector3(1.62, 0.58, 0.10))
	m.add_collider_cyl(Vector3(0, 1.1, 0), 0.14, 2.2)
	_merge_transformed(sm, m, pos, rot)

# ------------------------------------------------------------------ Officina Meccanica Bellini (accessibile, +Z fronte)
## Costruisce uno stabilimento industriale accessibile 12.0 x 9.6m con impianti d'aspirazione, plafoniere LED, CNC vetrata, quadri elettrici e sedie ergonomiche.
static func add_factory_building(sm: StyleMesh, center: Vector3, w: float = 12.0, d: float = 9.6, rot: float = 0.0) -> void:
	var h := 3.8
	var wt := 0.28
	var door_w := 3.6
	var side_w := (w - door_w) * 0.5

	var m := StyleMesh.new()
	# Pavimento industriale top Y = 0.04 + pedane acciaio zona CNC/Server + soglia pietra
	m.box("tile_gray", Vector3(0, 0.02, 0), Vector3(w, 0.04, d), {"col": true, "surface": "tile"})
	m.box("steel", Vector3(-0.8, 0.022, -3.25), Vector3(1.85, 0.04, 1.55), {"col": true, "surface": "metal"})
	m.box("steel", Vector3(-3.0, 0.022, -2.2), Vector3(1.70, 0.04, 1.90), {"col": true, "surface": "metal"})
	m.box("stone_trim", Vector3(0, 0.02, d * 0.5 + 0.18), Vector3(door_w + 0.2, 0.04, 0.36), {"col": true, "surface": "stone"})
	# Strisce gialle di sicurezza lungo il corridoio centrale interno
	m.box("safety_yellow", Vector3(-1.68, 0.043, 0.35), Vector3(0.11, 0.006, 7.6))
	m.box("safety_yellow", Vector3(1.68, 0.043, 0.35), Vector3(0.11, 0.006, 7.6))
	m.box("safety_yellow", Vector3(0.0, 0.043, -3.45), Vector3(3.46, 0.006, 0.11))

	# Soffitto industriale, travi in acciaio, condotti di ventilazione zincati & plafoniere LED
	m.box("plaster_rough", Vector3(0, h + 0.06, 0), Vector3(w, 0.12, d), {"col": true})
	for tz in [-2.8, 0.0, 2.8]:
		m.box("iron", Vector3(0, h - 0.14, tz), Vector3(w - wt * 2.0, 0.16, 0.18))
		for sx in [-4.0, -1.6, 1.6, 4.0]:
			m.box("iron", Vector3(sx, h - 0.04, tz), Vector3(0.10, 0.10, 0.14))
	# Tubazione d'aspirazione circolare zincata a soffitto verso l'angolo destro & CNC
	m.tube_path("steel_duct", [
		Vector3(-4.1, 1.92, -3.1),
		Vector3(-4.1, 3.36, -3.1),
		Vector3(-4.1, 3.36, -4.15),
		Vector3(0.0, 3.36, -4.15),
		Vector3(0.0, 3.36, 3.8),
	], [0.16, 0.17, 0.19, 0.21, 0.21], 12, true)
	m.tube_path("steel_duct", [
		Vector3(0.0, 3.36, -4.15),
		Vector3(4.95, 3.36, -4.15),
		Vector3(4.95, 3.36, -4.38),
		Vector3(4.95, 0.65, -4.38),
	], [0.18, 0.18, 0.18, 0.18], 12, true)
	# Plafoniere LED lineari rettangolari a soffitto
	for lx in [-3.1, 0.0, 3.1]:
		for lz in [-1.5, 1.6]:
			m.box("iron", Vector3(lx, h - 0.04, lz), Vector3(0.32, 0.06, 1.62))
			m.box("led_white", Vector3(lx, h - 0.075, lz), Vector3(0.24, 0.025, 1.52))
	# Canaline passacavi metalliche con guida dati
	m.box("steel", Vector3(-1.62, 3.44, 0.0), Vector3(0.22, 0.05, 8.2))
	m.box("cyan_accent", Vector3(-1.62, 3.47, 0.0), Vector3(0.06, 0.015, 8.1))

	m.gable("roof_slate", "corrugated_metal", Vector3(0, h + 0.12, 0), w + 0.6, d + 0.6, 1.65, w >= d)
	for cx in [-2.6, 2.6]:
		m.box("steel", Vector3(cx, h + 1.05, -1.2), Vector3(0.65, 0.65, 0.65))
		m.box("glass_exterior", Vector3(cx, h + 1.40, -1.2), Vector3(0.55, 0.08, 0.55))

	# Pareti in cemento industriale grezzo + zoccolo in mattoni esterno
	m.box("plaster_rough", Vector3(0, h * 0.5, -d * 0.5 + wt * 0.5), Vector3(w, h, wt), {"col": true})
	m.box("plaster_rough", Vector3(-w * 0.5 + wt * 0.5, h * 0.5, 0), Vector3(wt, h, d - wt), {"col": true})
	m.box("plaster_rough", Vector3(w * 0.5 - wt * 0.5, h * 0.5, 0), Vector3(wt, h, d - wt), {"col": true})
	m.box("brick", Vector3(0, 0.52, -d * 0.5 - 0.025), Vector3(w + 0.06, 1.04, 0.05))
	m.box("brick", Vector3(-w * 0.5 - 0.025, 0.52, 0), Vector3(0.05, 1.04, d + 0.06))
	m.box("brick", Vector3(w * 0.5 + 0.025, 0.52, 0), Vector3(0.05, 1.04, d + 0.06))
	# Canaline elettriche verticali a parete interna (stile officina reale)
	for px in [-3.8, -0.8, 1.9, 3.8]:
		m.cyl("iron", Vector3(px, 0.2, -d * 0.5 + wt + 0.04), 0.024, 0.024, 3.4, 8)
		m.box("steel", Vector3(px, 1.45, -d * 0.5 + wt + 0.05), Vector3(0.14, 0.16, 0.06))
	for pz in [-3.1, 0.8, 2.9]:
		m.cyl("iron", Vector3(-w * 0.5 + wt + 0.04, 0.2, pz), 0.024, 0.024, 3.4, 8)

	# Finestre industriali ampie sulle pareti laterali con vetro scuro riflettente e traversini
	for wx_side in [-w * 0.5, w * 0.5]:
		var sign_s := signf(wx_side)
		for fz in [-2.2, 2.0]:
			m.box("iron", Vector3(wx_side + sign_s * 0.02, 1.95, fz), Vector3(0.10, 1.35, 2.45))
			m.box("glass_exterior", Vector3(wx_side + sign_s * 0.04, 1.95, fz), Vector3(0.04, 1.18, 2.24))
			m.box("iron", Vector3(wx_side + sign_s * 0.055, 1.95, fz), Vector3(0.03, 0.05, 2.24))
			for mz in [-0.74, 0.0, 0.74]:
				m.box("iron", Vector3(wx_side + sign_s * 0.055, 1.95, fz + mz), Vector3(0.03, 1.18, 0.05))

	# Parete frontale (+Z) con portone carraio aperto (3.6m) e vetrate esterne con telaio a croce
	m.box("plaster_rough", Vector3(-w * 0.5 + side_w * 0.5, h * 0.5, d * 0.5 - wt * 0.5), Vector3(side_w, h, wt), {"col": true})
	m.box("plaster_rough", Vector3(w * 0.5 - side_w * 0.5, h * 0.5, d * 0.5 - wt * 0.5), Vector3(side_w, h, wt), {"col": true})
	m.box("plaster_rough", Vector3(0, 2.80 + (h - 2.80) * 0.5, d * 0.5 - wt * 0.5), Vector3(door_w, h - 2.80, wt), {"col": true})
	for sx in [-w * 0.5 + side_w * 0.5, w * 0.5 - side_w * 0.5]:
		m.box("brick", Vector3(sx, 0.52, d * 0.5 + 0.025), Vector3(side_w, 1.04, 0.05))
		m.box("iron", Vector3(sx, 1.95, d * 0.5 + 0.02), Vector3(2.6, 1.35, 0.08))
		m.box("glass_exterior", Vector3(sx, 1.95, d * 0.5 + 0.04), Vector3(2.4, 1.18, 0.03))
		m.box("iron", Vector3(sx, 1.95, d * 0.5 + 0.055), Vector3(2.4, 0.05, 0.03))
		for mx in [-0.78, 0.0, 0.78]:
			m.box("iron", Vector3(sx + mx, 1.95, d * 0.5 + 0.055), Vector3(0.05, 1.18, 0.03))
	m.box("safety_yellow", Vector3(-door_w * 0.5 - 0.06, 1.40, d * 0.5 + 0.02), Vector3(0.14, 2.80, 0.24))
	m.box("safety_yellow", Vector3(door_w * 0.5 + 0.06, 1.40, d * 0.5 + 0.02), Vector3(0.14, 2.80, 0.24))
	m.box("iron", Vector3(0, 2.94, d * 0.5 + 0.04), Vector3(door_w + 0.28, 0.34, 0.28))
	m.box("safety_yellow", Vector3(0, 2.75, d * 0.5 + 0.04), Vector3(door_w + 0.20, 0.08, 0.26))
	m.box("iron", Vector3(0, 3.44, d * 0.5 + 0.08), Vector3(5.6, 0.52, 0.12))

	# --- INTERNO ZONIZZATO (corridoio centrale X:[-1.6, 1.6] libero!) ---
	# 1. Macchinario CNC dettagliato (sinistra posteriore)
	m.box("iron", Vector3(-4.1, 0.44, -2.6), Vector3(2.24, 0.80, 1.64), {"col": true})
	m.box("fabric_green", Vector3(-4.1, 1.32, -2.6), Vector3(2.08, 0.96, 1.48), {"col": true})
	m.box("iron", Vector3(-3.03, 1.32, -2.6), Vector3(0.08, 0.72, 1.08))
	m.box("glass_exterior", Vector3(-3.00, 1.32, -2.6), Vector3(0.03, 0.58, 0.94))
	m.cyl("steel", Vector3(-3.75, 1.05, -2.6), 0.14, 0.12, 0.46, 10)
	m.box("safety_yellow", Vector3(-4.1, 1.88, -2.6), Vector3(2.14, 0.14, 1.54))
	m.cyl("safety_yellow", Vector3(-3.4, 1.95, -2.1), 0.07, 0.07, 0.18, 10)
	m.cyl("iron", Vector3(-3.45, 0.55, -1.78), 0.24, 0.24, 0.30, 12)
	# Quadro comandi CNC su colonna metallica
	m.box("steel", Vector3(-3.0, 0.68, -1.45), Vector3(0.46, 1.28, 0.46), {"col": true})
	m.box("glass_cool", Vector3(-2.76, 1.15, -1.45), Vector3(0.04, 0.28, 0.34))
	m.box("fabric_red", Vector3(-2.76, 0.92, -1.36), Vector3(0.04, 0.05, 0.05))
	m.box("fabric_green", Vector3(-2.76, 0.92, -1.46), Vector3(0.04, 0.05, 0.05))

	# 2. Banco da lavoro meccanico (lato sinistro davanti) con attrezzatura + pannello portautensili a parete
	m.box("iron", Vector3(-5.1, 0.44, 0.85), Vector3(0.85, 0.80, 2.4), {"col": true})
	m.box("wood_mid", Vector3(-5.1, 0.88, 0.85), Vector3(0.92, 0.08, 2.5))
	m.box("burlap", Vector3(-5.05, 1.04, 0.4), Vector3(0.32, 0.22, 0.36))
	m.box("burlap", Vector3(-5.05, 0.24, 1.15), Vector3(0.42, 0.38, 0.52))
	m.box("steel", Vector3(-5.25, 0.99, 1.48), Vector3(0.24, 0.14, 0.30))
	m.box("iron", Vector3(-5.68, 1.56, 0.85), Vector3(0.04, 0.78, 1.85))
	for ty in [1.38, 1.68]:
		m.box("steel", Vector3(-5.64, ty, 0.85), Vector3(0.03, 0.05, 1.55))
	for tz in [0.22, 0.52, 0.85, 1.18, 1.45]:
		m.box("safety_yellow" if int(tz * 10) % 2 == 0 else "steel", Vector3(-5.63, 1.56, tz), Vector3(0.025, 0.28, 0.05))
	# Carroponte giallo a soffitto (passaggio pedonale sotto Y=3.18 completamente libero!)
	m.box("safety_yellow", Vector3(0.0, 3.24, -0.45), Vector3(w - wt * 2.4, 0.16, 0.22))
	m.box("iron", Vector3(-1.85, 3.10, -0.45), Vector3(0.42, 0.14, 0.28))

	# 3. Armadi elettrici / inverter industriali a muro (fondo sinistra vicino Server)
	for ax in [-3.35, -2.35]:
		m.box("metal_panel", Vector3(ax, 1.18, -4.15), Vector3(0.88, 2.24, 0.64), {"col": true})
		m.box("steel", Vector3(ax, 1.18, -3.82), Vector3(0.76, 2.04, 0.03))
		m.box("fabric_red", Vector3(ax - 0.18, 1.72, -3.80), Vector3(0.06, 0.06, 0.02))
		m.box("fabric_green", Vector3(ax - 0.06, 1.72, -3.80), Vector3(0.06, 0.06, 0.02))
		m.box("safety_yellow", Vector3(ax + 0.10, 1.72, -3.80), Vector3(0.06, 0.06, 0.02))
		m.box("gaming_black", Vector3(ax, 1.38, -3.80), Vector3(0.28, 0.18, 0.02))

	# 4. Basamento & Canalina per Server Xeon (fondo centro-sx)
	m.box("stone_trim", Vector3(-0.8, 0.11, -4.10), Vector3(1.25, 0.14, 0.95), {"col": true})
	m.box("safety_yellow", Vector3(-0.8, 0.19, -3.65), Vector3(1.25, 0.04, 0.06))
	m.box("iron", Vector3(-0.8, 1.35, -4.55), Vector3(0.55, 1.85, 0.10))

	# 5. Quadro Elettrico & Staffa Wi-Fi (parete interna anteriore-sx)
	m.box("iron", Vector3(-2.45, 1.38, 4.34), Vector3(0.68, 0.74, 0.16))
	m.box("safety_yellow", Vector3(-2.45, 1.38, 4.25), Vector3(0.16, 0.16, 0.03))

	# 6. Scrivania direzionale Ing. Bellini (destra centro-retro) con raccoglitori, lampada & orologio a parete
	m.box("wood_dark", Vector3(2.75, 0.40, -2.75), Vector3(1.75, 0.74, 0.72), {"col": true})
	m.box("wood_mid", Vector3(2.75, 0.80, -2.75), Vector3(1.84, 0.06, 0.80))
	m.box("brass", Vector3(2.15, 0.56, -2.38), Vector3(0.14, 0.03, 0.03))
	m.box("brass", Vector3(2.15, 0.34, -2.38), Vector3(0.14, 0.03, 0.03))
	m.box("white", Vector3(2.80, 0.84, -2.75), Vector3(0.62, 0.02, 0.42))
	m.box("fabric_blue", Vector3(2.12, 0.96, -2.86), Vector3(0.08, 0.28, 0.24))
	m.box("iron", Vector3(2.22, 0.96, -2.86), Vector3(0.08, 0.28, 0.24))
	# Bacheca sicurezza & orologio su parete destra/fondo
	m.box("iron", Vector3(5.68, 1.74, 2.35), Vector3(0.04, 0.84, 1.18))
	m.box("white", Vector3(5.65, 1.74, 2.35), Vector3(0.02, 0.72, 1.06))
	m.box("safety_yellow", Vector3(5.63, 1.92, 2.08), Vector3(0.015, 0.20, 0.30))
	m.box("fabric_green", Vector3(5.63, 1.62, 2.52), Vector3(0.015, 0.24, 0.32))
	m.box("iron", Vector3(2.75, 2.28, -4.48), Vector3(0.56, 0.56, 0.05))
	m.box("white", Vector3(2.75, 2.28, -4.45), Vector3(0.46, 0.46, 0.02))

	# 7. Due Scrivanie Ufficio Tecnico CAD (lato destro lungo parete +X) + raccoglitori + sedie girevoli a 5 razze
	for dz in [-2.6, 0.55]:
		m.box("wood_dark", Vector3(4.65, 0.39, dz), Vector3(0.86, 0.72, 1.85), {"col": true})
		m.box("wood_mid", Vector3(4.65, 0.78, dz), Vector3(0.94, 0.06, 1.94))
		# Raccoglitori colorati sul piano
		m.box("fabric_green", Vector3(4.82, 0.96, dz - 0.65), Vector3(0.24, 0.30, 0.07))
		m.box("fabric_blue", Vector3(4.82, 0.96, dz - 0.56), Vector3(0.24, 0.30, 0.07))
		m.box("iron", Vector3(4.82, 0.96, dz - 0.47), Vector3(0.24, 0.30, 0.07))
		# Sedia ergonomica 5-razze ben distanziata davanti alla scrivania (zero clipping!)
		var cx := 3.74
		m.cyl("iron", Vector3(cx, 0.07, dz), 0.032, 0.032, 0.36, 8)
		for ri in range(5):
			var ra := TAU * float(ri) / 5.0
			m.box("iron", Vector3(cx + cos(ra) * 0.14, 0.06, dz + sin(ra) * 0.14), Vector3(0.28, 0.035, 0.04), {"rot": -ra})
			m.cyl("gaming_black", Vector3(cx + cos(ra) * 0.26, 0.0, dz + sin(ra) * 0.26), 0.028, 0.028, 0.05, 8)
		m.box("gaming_black", Vector3(cx, 0.45, dz), Vector3(0.46, 0.07, 0.46), {"col": true})
		m.box("gaming_black", Vector3(cx - 0.21, 0.79, dz), Vector3(0.06, 0.60, 0.44))
		m.box("iron", Vector3(cx - 0.04, 0.58, dz - 0.24), Vector3(0.26, 0.04, 0.05))
		m.box("iron", Vector3(cx - 0.04, 0.58, dz + 0.24), Vector3(0.26, 0.04, 0.05))

	_merge_transformed(sm, m, center, rot)

static func add_factory_installed_wifi(sm: StyleMesh, pos: Vector3) -> void:
	sm.box("steel", pos, Vector3(0.42, 0.14, 0.22))
	sm.box("cyan_accent", pos + Vector3(0, 0.02, -0.115), Vector3(0.28, 0.03, 0.02))
	sm.cyl("iron", pos + Vector3(-0.14, 0.07, 0.02), 0.015, 0.010, 0.26, 8)
	sm.cyl("iron", pos + Vector3(0.14, 0.07, 0.02), 0.015, 0.010, 0.26, 8)

static func add_factory_installed_server(sm: StyleMesh, pos: Vector3) -> void:
	# Armadio Rack Xeon 42U con frontale vetrato scuro, chassis e LED di rete (pos = top plinto Y=0.18)
	sm.box("iron", pos + Vector3(0, 0.80, 0), Vector3(0.86, 1.60, 0.74))
	sm.box("gaming_black", pos + Vector3(0, 0.80, 0.36), Vector3(0.74, 1.44, 0.04))
	sm.box("glass_exterior", pos + Vector3(0, 0.80, 0.382), Vector3(0.66, 1.32, 0.02))
	for ry in [0.34, 0.56, 0.78, 1.00, 1.22, 1.38]:
		sm.box("cyan_accent" if ry > 0.7 else "safety_yellow", pos + Vector3(-0.08, ry, 0.372), Vector3(0.42, 0.028, 0.02))
		sm.box("fabric_red" if int(ry * 10) % 2 == 0 else "fabric_green", pos + Vector3(0.22, ry, 0.372), Vector3(0.04, 0.028, 0.02))

static func add_workstation_pc_prop(sm: StyleMesh, pos: Vector3, rot: float = 0.0) -> void:
	var m := StyleMesh.new()
	m.box("steel", Vector3(0, 0.06, 0.14), Vector3(0.16, 0.12, 0.12))
	m.box("gaming_black", Vector3(0, 0.28, 0.16), Vector3(0.68, 0.40, 0.045))
	m.box("glass_cool", Vector3(0, 0.28, 0.132), Vector3(0.62, 0.34, 0.02))
	m.box("gaming_black", Vector3(0, 0.015, -0.14), Vector3(0.36, 0.025, 0.13))
	m.box("iron", Vector3(0.52, 0.23, 0.04), Vector3(0.22, 0.46, 0.44))
	m.box("cyan_accent", Vector3(0.52, 0.34, -0.185), Vector3(0.04, 0.14, 0.02))
	_merge_transformed(sm, m, pos, rot)

# ------------------------------------------------------------------ Ologrammi Blueprint 3D Officina (semi-trasparenti, ZERO collider!)
static func add_factory_ghost_wifi(sm: StyleMesh, pos: Vector3, ghost_key: String = "ghost_ready") -> void:
	sm.box(ghost_key, pos, Vector3(0.46, 0.18, 0.26))
	sm.cyl(ghost_key, pos + Vector3(-0.15, 0.08, 0.02), 0.02, 0.012, 0.30, 6)
	sm.cyl(ghost_key, pos + Vector3(0.15, 0.08, 0.02), 0.02, 0.012, 0.30, 6)
	if ghost_key == "ghost_ready":
		sm.box("ghost_pad", Vector3(pos.x, 0.055, pos.z - 0.42), Vector3(0.95, 0.025, 0.95))

static func add_factory_ghost_server(sm: StyleMesh, pos: Vector3, ghost_key: String = "ghost_ready") -> void:
	sm.box(ghost_key, pos + Vector3(0, 0.78, 0), Vector3(0.88, 1.60, 0.76))
	for ry in [0.35, 0.70, 1.05, 1.35]:
		sm.box(ghost_key, pos + Vector3(0, ry, 0.39), Vector3(0.62, 0.05, 0.03))
	if ghost_key == "ghost_ready":
		sm.box("ghost_pad", Vector3(pos.x, 0.055, pos.z + 0.85), Vector3(1.15, 0.025, 0.85))

static func add_factory_ghost_pcs(sm: StyleMesh, pos1: Vector3, pos2: Vector3, rot: float = PI * 0.5, ghost_key: String = "ghost_ready") -> void:
	for p in [pos1, pos2]:
		var m := StyleMesh.new()
		m.box(ghost_key, Vector3(0, 0.06, 0.14), Vector3(0.18, 0.12, 0.14))
		m.box(ghost_key, Vector3(0, 0.28, 0.16), Vector3(0.70, 0.42, 0.07))
		m.box(ghost_key, Vector3(0, 0.018, -0.14), Vector3(0.38, 0.03, 0.14))
		m.box(ghost_key, Vector3(0.52, 0.23, 0.04), Vector3(0.24, 0.46, 0.44))
		_merge_transformed(sm, m, p, rot)
	if ghost_key == "ghost_ready":
		sm.box("ghost_pad", Vector3(3.15, 0.055, -1.02), Vector3(0.90, 0.025, 2.25))

# ------------------------------------------------------------------ Arredi Attività Ripetibili & Nuovi Quartieri
static func add_bacheca(sm: StyleMesh, pos: Vector3, rot: float = 0.0) -> void:
	var m := StyleMesh.new()
	m.box("wood_dark", Vector3(-0.72, 1.02, 0), Vector3(0.12, 2.04, 0.12), {"col": true})
	m.box("wood_dark", Vector3(0.72, 1.02, 0), Vector3(0.12, 2.04, 0.12), {"col": true})
	m.box("wood_dark", Vector3(0, 1.48, 0), Vector3(1.56, 1.04, 0.10), {"col": true})
	m.box("wood_light", Vector3(0, 1.48, 0.05), Vector3(1.36, 0.84, 0.04))
	m.box("awning_yellow", Vector3(-0.38, 1.62, 0.08), Vector3(0.30, 0.34, 0.02))
	m.box("white", Vector3(0.0, 1.64, 0.08), Vector3(0.28, 0.32, 0.02))
	m.box("cyan_accent", Vector3(0.38, 1.60, 0.08), Vector3(0.30, 0.36, 0.02))
	m.box("fabric_red", Vector3(-0.22, 1.24, 0.08), Vector3(0.34, 0.24, 0.02))
	m.box("white", Vector3(0.24, 1.24, 0.08), Vector3(0.34, 0.24, 0.02))
	m.gable("roof_terracotta", "wood_dark", Vector3(0, 2.06, 0), 1.84, 0.42, 0.34, true)
	_merge_transformed(sm, m, pos, rot)

static func add_mailbox(sm: StyleMesh, pos: Vector3, rot: float = 0.0) -> void:
	var m := StyleMesh.new()
	m.box("iron", Vector3(0, 0.48, 0), Vector3(0.14, 0.96, 0.14), {"col": true})
	m.box("fabric_red", Vector3(0, 1.18, 0), Vector3(0.42, 0.56, 0.32), {"col": true})
	m.box("iron", Vector3(0, 1.36, 0.17), Vector3(0.28, 0.06, 0.04))
	m.box("white", Vector3(0, 1.12, 0.17), Vector3(0.22, 0.14, 0.02))
	_merge_transformed(sm, m, pos, rot)

static func add_fiber_cabinet(sm: StyleMesh, pos: Vector3, rot: float = 0.0) -> void:
	var m := StyleMesh.new()
	m.box("ashlar", Vector3(0, 0.08, 0), Vector3(0.76, 0.16, 0.46), {"col": true})
	m.box("metal_panel", Vector3(0, 0.84, 0), Vector3(0.68, 1.36, 0.40), {"col": true})
	m.box("fabric_red", Vector3(0, 1.56, 0), Vector3(0.70, 0.12, 0.42))
	m.box("iron", Vector3(0, 0.84, 0.21), Vector3(0.54, 1.08, 0.02))
	m.box("cyan_accent", Vector3(0.18, 1.26, 0.22), Vector3(0.08, 0.08, 0.02))
	_merge_transformed(sm, m, pos, rot)

static func add_cargo_pallet(sm: StyleMesh, pos: Vector3, rot: float = 0.0, is_drop_zone: bool = false) -> void:
	var m := StyleMesh.new()
	m.box("wood_dark", Vector3(0, 0.06, 0), Vector3(1.15, 0.12, 0.95), {"col": true})
	if is_drop_zone:
		m.box("safety_yellow", Vector3(0, 0.13, 0), Vector3(1.02, 0.02, 0.82))
		m.box("burlap", Vector3(-0.24, 0.34, 0.0), Vector3(0.42, 0.40, 0.56), {"col": true})
	else:
		m.box("wood_mid", Vector3(-0.22, 0.38, 0.06), Vector3(0.50, 0.52, 0.52), {"col": true})
		m.box("burlap", Vector3(0.28, 0.33, -0.06), Vector3(0.42, 0.42, 0.48), {"col": true})
		m.box("wood_light", Vector3(-0.04, 0.82, 0.02), Vector3(0.44, 0.36, 0.42), {"col": true})
	_merge_transformed(sm, m, pos, rot)

static func add_park_pond(sm: StyleMesh, pos: Vector3, r_x: float = 4.6, r_z: float = 3.4) -> void:
	sm.cyl("stone_dark", pos + Vector3(0, 0.01, 0), r_x + 0.05, r_x + 0.05, 0.12, 16, {"smooth": false})
	sm.cyl("ashlar", pos, r_x + 0.42, r_x + 0.48, 0.14, 16, {"smooth": false})
	sm.cyl("water", pos + Vector3(0, 0.16, 0), r_x - 0.02, r_x - 0.02, 0.08, 18, {"smooth": true})
	for k in range(16):
		var a := TAU * (float(k) + 0.5) / 16.0
		var rp := pos + Vector3(cos(a) * (r_x + 0.14), 0.10, sin(a) * (r_x + 0.14))
		var rseg := StyleMesh.new()
		rseg.beveled_curb_block("stone_trim", Vector3.ZERO, 0.42, TAU * (r_x + 0.14) / 16.0 + 0.08, 0.20, 0.0)
		_merge_transformed(sm, rseg, rp, -a)
	# Piccola fontanella/zampillo slanciato e trasparente al centro del laghetto (come Rif 1)
	sm.cyl("stone_trim", pos + Vector3(0, 0.16, 0), 0.36, 0.28, 0.18, 10)
	sm.cyl("water_spray", pos + Vector3(0, 0.30, 0), 0.06, 0.20, 0.44, 12, {"smooth": true, "cap_top": false})
	sm.cyl("water_spray", pos + Vector3(0, 0.32, 0), 0.025, 0.075, 0.58, 10, {"smooth": true, "cap_top": false})
	sm.add_collider_cyl(pos + Vector3(0, 0.35, 0), r_x * 0.88, 0.8)
	# Pontile in legno lato est (+X)
	for px in [r_x - 0.9, r_x + 0.3, r_x + 1.4]:
		sm.box("wood_dark", pos + Vector3(px, 0.22, -0.75), Vector3(0.14, 0.44, 0.14))
		sm.box("wood_dark", pos + Vector3(px, 0.22, 0.75), Vector3(0.14, 0.44, 0.14))
	sm.box("wood_light", pos + Vector3(r_x + 0.25, 0.42, 0), Vector3(2.9, 0.10, 1.75), {"col": true, "surface": "wood"})
	# Anatre posate sullo specchio d'acqua
	for dp in [pos + Vector3(-1.3, 0.27, -0.7), pos + Vector3(1.1, 0.27, 1.0)]:
		sm.ellipsoid("white", dp, Vector3(0.24, 0.14, 0.16), 5, 8)
		sm.ellipsoid("white", dp + Vector3(0.18, 0.13, 0), Vector3(0.10, 0.10, 0.10), 4, 7)
		sm.box("orange", dp + Vector3(0.29, 0.12, 0), Vector3(0.10, 0.04, 0.07))
	for bp in [Vector3(-r_x - 0.1, 0.24, 1.2), Vector3(-r_x * 0.5, 0.20, -r_z - 0.5), Vector3(1.5, 0.21, -r_z - 0.6)]:
		sm.blob("stone_dark", pos + bp, Vector3(0.50, 0.30, 0.46), 4, 7, 0.2, int(absf(bp.x) * 7) + 3)

static func add_gazebo(sm: StyleMesh, pos: Vector3, r: float = 2.6) -> void:
	sm.cyl("stone_trim", pos, r + 0.2, r + 0.1, 0.22, 8, {"smooth": false})
	sm.box("stone_trim", pos + Vector3(0, 0.11, 0), Vector3(r * 1.65, 0.22, r * 1.65), {"col": true, "surface": "stone"})
	for k in range(6):
		var ang := TAU * float(k) / 6.0
		var col_p := pos + Vector3(cos(ang) * (r - 0.18), 0.22, sin(ang) * (r - 0.18))
		sm.cyl("iron", col_p, 0.07, 0.06, 2.55, 8)
		sm.add_collider_cyl(col_p + Vector3(0, 1.25, 0), 0.14, 2.5)
	sm.cyl("copper", pos + Vector3(0, 2.75, 0), r + 0.28, 0.12, 1.05, 8, {"smooth": false})
	sm.cyl("brass", pos + Vector3(0, 3.80, 0), 0.08, 0.02, 0.28, 8)
	sm.cyl("wood_dark", pos + Vector3(0, 0.22, 0), 0.42, 0.08, 0.72, 10)
	sm.cyl("wood_light", pos + Vector3(0, 0.94, 0), 0.65, 0.65, 0.07, 12)
	sm.add_collider_cyl(pos + Vector3(0, 0.6, 0), 0.65, 1.0)

static func add_market_stall(sm: StyleMesh, pos: Vector3, rot: float = 0.0, awning_key: String = "awning_red", goods_kind: String = "fruit") -> void:
	var m := StyleMesh.new()
	m.box("wood_dark", Vector3(0, 0.45, 0.35), Vector3(2.8, 0.88, 0.78), {"col": true})
	m.box("wood_light", Vector3(0, 0.92, 0.35), Vector3(2.96, 0.06, 0.88))
	for px in [-1.32, 1.32]:
		m.box("wood_dark", Vector3(px, 1.22, -0.58), Vector3(0.10, 2.44, 0.10), {"col": true})
		m.box("wood_dark", Vector3(px, 1.22, 0.65), Vector3(0.10, 2.44, 0.10), {"col": true})
	m.box(awning_key, Vector3(0, 2.48, 0.06), Vector3(3.2, 0.14, 1.85))
	m.gable(awning_key, "wood_light", Vector3(0, 2.55, 0.06), 3.2, 1.85, 0.48, true)
	if goods_kind == "fruit":
		for bx in [-0.9, 0.0, 0.9]:
			m.box("wicker", Vector3(bx, 1.02, 0.42), Vector3(0.68, 0.14, 0.52))
		m.blob("apple", Vector3(-0.9, 1.15, 0.42), Vector3(0.22, 0.13, 0.18), 4, 8, 0.1, 1)
		m.blob("orange", Vector3(0.0, 1.15, 0.42), Vector3(0.22, 0.13, 0.18), 4, 8, 0.1, 2)
		m.blob("lemon", Vector3(0.9, 1.15, 0.42), Vector3(0.22, 0.13, 0.18), 4, 8, 0.1, 3)
	elif goods_kind == "books":
		for i in range(5):
			var k: String = ["fabric_blue", "fabric_red", "awning_yellow", "fabric_green", "cyan_accent"][i]
			m.box(k, Vector3(-1.0 + float(i) * 0.5, 1.01, 0.36), Vector3(0.36, 0.10, 0.46))
	else:
		m.box("steel", Vector3(-0.65, 1.08, 0.35), Vector3(0.62, 0.24, 0.42))
		m.box("gaming_black", Vector3(0.45, 1.10, 0.35), Vector3(0.75, 0.30, 0.44))
		m.box("cyan_accent", Vector3(0.45, 1.12, 0.58), Vector3(0.62, 0.18, 0.03))
	_merge_transformed(sm, m, pos, rot)

static func add_post_office(sm: StyleMesh, center: Vector3, rot: float = 0.0) -> void:
	var m := StyleMesh.new()
	var w := 7.6
	var d := 5.6
	var h := 4.4
	m.box("ashlar", Vector3(0, 0.32, 0), Vector3(w + 0.12, 0.64, d + 0.12))
	m.box("plaster_ochre", Vector3(0, 0.64 + (h - 0.64) * 0.5, 0), Vector3(w, h - 0.64, d), {"col": true})
	m.box("stone_trim", Vector3(0, h + 0.08, 0), Vector3(w + 0.24, 0.16, d + 0.24))
	m.hip_roof("roof_slate", Vector3(0, h + 0.16, 0), w + 0.45, d + 0.45, 1.35)
	m.box("fabric_blue", Vector3(0, 2.75, d * 0.5 + 0.05), Vector3(w - 0.6, 0.55, 0.08))
	m.box("safety_yellow", Vector3(0, 2.50, d * 0.5 + 0.06), Vector3(w - 0.6, 0.14, 0.09))
	m.box("iron", Vector3(0, 1.25, d * 0.5 + 0.04), Vector3(2.2, 2.30, 0.08))
	m.box("glass_exterior", Vector3(0, 1.25, d * 0.5 + 0.06), Vector3(1.9, 2.05, 0.04))
	m.box("stone_trim", Vector3(0, 0.08, d * 0.5 + 0.35), Vector3(2.8, 0.16, 0.70), {"col": true, "surface": "stone"})
	for wx in [-2.35, 2.35]:
		_add_window(m, Vector3(wx, 1.55, d * 0.5), 0.0, "fabric_blue", "")
	_merge_transformed(sm, m, center, rot)

# ------------------------------------------------------------------ Pizzeria Da Mario v1.4 (forno a legna cupolato & tavoli rossi)
static func add_pizzeria_oven(sm: StyleMesh, pos: Vector3, rot: float = 0.0) -> void:
	var m := StyleMesh.new()
	# Basamento in mattoni con nicchia portalegna + mensola in pietra davanti alla bocca
	m.box("brick", Vector3(0, 0.48, 0), Vector3(1.56, 0.96, 1.38), {"col": true})
	m.box("stone_counter", Vector3(0, 0.96, 0.12), Vector3(1.66, 0.08, 1.56))
	m.box("stone_trim", Vector3(0, 1.01, 0.72), Vector3(0.96, 0.05, 0.24))
	# Ceppi di legna stagionata accatastati alla base laterale del forno
	for li in range(3):
		m.capsule_seg("bark", Vector3(-0.34 + float(li) * 0.12, 0.13, 0.70), Vector3(-0.34 + float(li) * 0.12, 0.13, 0.34), 0.048, 0.044, 6)
	for li2 in range(2):
		m.capsule_seg("bark", Vector3(-0.28 + float(li2) * 0.12, 0.21, 0.70), Vector3(-0.28 + float(li2) * 0.12, 0.21, 0.34), 0.044, 0.040, 6)
	# Cupola in muratura curvilinea, cornice bocca fuoco e mattoni sporgenti
	m.lathe_oval("brick", Vector3(0, 1.00, -0.06), [
		Vector2(0.76, 0.00), Vector2(0.74, 0.28), Vector2(0.66, 0.56),
		Vector2(0.48, 0.78), Vector2(0.24, 0.90)
	], 1.04, 0.92, 16)
	m.box("brick", Vector3(0, 1.34, 0.48), Vector3(1.22, 0.72, 0.42))
	m.box("brick", Vector3(0, 1.51, 0.69), Vector3(0.92, 0.12, 0.09))
	m.box("iron", Vector3(0, 1.24, 0.69), Vector3(0.78, 0.44, 0.05))
	# Braci ardenti, fiamme e ceppi di legno accesi dentro la bocca
	m.box("ember_glow", Vector3(0, 1.21, 0.67), Vector3(0.64, 0.32, 0.06))
	m.ellipsoid("ember_glow", Vector3(0, 1.25, 0.62), Vector3(0.24, 0.16, 0.14), 5, 10)
	m.capsule_seg("bark", Vector3(-0.20, 1.06, 0.62), Vector3(0.16, 1.15, 0.58), 0.036, 0.032, 8)
	m.capsule_seg("bark", Vector3(0.18, 1.06, 0.63), Vector3(-0.14, 1.16, 0.56), 0.034, 0.030, 8)
	# Canna fumaria conica in mattoni fino al soffitto con collare metallico (fumo volumetrico gestito via CPUParticles3D!)
	m.cyl("brick", Vector3(0, 1.84, -0.08), 0.29, 0.21, 1.32, 12)
	m.cyl("stone_dark", Vector3(0, 2.26, -0.08), 0.27, 0.27, 0.05, 12)
	m.cyl("iron", Vector3(0, 1.60, 0.48), 0.16, 0.14, 0.18, 10)
	# Pala da pizzaiolo in legno appoggiata sul lato destro del forno + spolverata farina sul piano
	m.capsule_seg("wood_light", Vector3(0.84, 0.04, 0.74), Vector3(0.78, 1.76, 0.60), 0.018, 0.018, 6)
	m.box("wood_light", Vector3(0.84, 0.25, 0.72), Vector3(0.28, 0.36, 0.025), {"rot": 0.10})
	m.ellipsoid("flour", Vector3(0.62, 1.003, 0.56), Vector3(0.14, 0.004, 0.11), 3, 6)
	_merge_transformed(sm, m, pos, rot)

static var _smoke_tex: ImageTexture = null

static func _get_smoke_texture() -> ImageTexture:
	if _smoke_tex != null:
		return _smoke_tex
	var sz := 64
	var img := Image.create(sz, sz, false, Image.FORMAT_RGBA8)
	var half := float(sz - 1) * 0.5
	for y in range(sz):
		for x in range(sz):
			var dx := (float(x) - half) / half
			var dy := (float(y) - half) / half
			var r2 := dx * dx + dy * dy
			var radial := clampf(1.0 - r2, 0.0, 1.0)
			var alpha := radial * radial * radial
			var puff := 0.88 + 0.12 * sin(dx * 5.2 + dy * 3.7) * cos(dy * 4.1 - dx * 2.9)
			var val := clampf(0.86 + 0.10 * radial, 0.0, 1.0)
			img.set_pixel(x, y, Color(val, val * 0.97, val * 0.94, clampf(alpha * puff, 0.0, 1.0)))
	_smoke_tex = ImageTexture.create_from_image(img)
	return _smoke_tex

static func add_oven_smoke_particles(parent: Node3D, pos: Vector3) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.name = "OvenSmokeParticles"
	p.position = pos
	p.amount = 22
	p.lifetime = 2.2
	p.preprocess = 1.8
	p.explosiveness = 0.0
	p.randomness = 0.45
	p.emitting = true
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 0.14
	p.direction = Vector3(0.06, 1.0, 0.14)
	p.spread = 16.0
	p.gravity = Vector3(0.0, 0.03, 0.0)
	p.initial_velocity_min = 0.22
	p.initial_velocity_max = 0.38
	p.damping_min = 0.12
	p.damping_max = 0.20
	p.scale_amount_min = 0.50
	p.scale_amount_max = 1.05

	var scale_curve := Curve.new()
	scale_curve.add_point(Vector2(0.0, 0.42))
	scale_curve.add_point(Vector2(0.45, 0.92))
	scale_curve.add_point(Vector2(1.0, 1.38))
	p.scale_amount_curve = scale_curve

	var grad := Gradient.new()
	grad.set_color(0, Color(0.94, 0.91, 0.88, 0.0))
	grad.add_point(0.20, Color(0.92, 0.90, 0.87, 0.50))
	grad.add_point(0.65, Color(0.86, 0.84, 0.82, 0.26))
	grad.set_color(1, Color(0.82, 0.80, 0.78, 0.0))
	p.color_ramp = grad

	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.billboard_keep_scale = true
	mat.vertex_color_use_as_albedo = true
	mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	mat.albedo_texture = _get_smoke_texture()

	var qm := QuadMesh.new()
	qm.size = Vector2(0.42, 0.42)
	qm.material = mat
	p.mesh = qm

	parent.add_child(p)
	return p

static func add_pizzeria_table_set(sm: StyleMesh, pos: Vector3, rot: float = 0.0) -> void:
	var m := StyleMesh.new()
	# Base a piedistallo conico in ghisa + piano rotondo rosso laccato
	m.cyl("iron", Vector3(0, 0.0, 0), 0.26, 0.09, 0.28, 12)
	m.cyl("iron", Vector3(0, 0.28, 0), 0.055, 0.055, 0.43, 10)
	m.cyl("red_table", Vector3(0, 0.71, 0), 0.54, 0.54, 0.055, 18)
	m.add_collider_cyl(Vector3(0, 0.38, 0), 0.54, 0.78)
	# Tovaglietta chiara, oliera e porta-tovaglioli sul tavolo
	m.box("white", Vector3(0, 0.768, 0), Vector3(0.46, 0.012, 0.30))
	m.cyl("jar_green", Vector3(-0.08, 0.774, -0.04), 0.028, 0.024, 0.14, 8)
	m.cyl("tin_gold", Vector3(0.08, 0.774, 0.04), 0.032, 0.032, 0.08, 8)
	# Due sedie rustiche a doghe ai lati (+X/-X o orientate tramite rot)
	for side in [-1.0, 1.0]:
		var cx: float = side * 0.68
		var yaw: float = -side * PI * 0.5
		var cm := StyleMesh.new()
		for lx in [-0.15, 0.15]:
			for lz in [-0.15, 0.15]:
				cm.box("wood_dark", Vector3(lx, 0.20, lz), Vector3(0.042, 0.40, 0.042))
		cm.box("wood_dark", Vector3(0, 0.14, -0.15), Vector3(0.32, 0.03, 0.03))
		cm.box("wood_dark", Vector3(0, 0.14, 0.15), Vector3(0.32, 0.03, 0.03))
		cm.box("wood_plank", Vector3(0, 0.415, 0), Vector3(0.38, 0.04, 0.38))
		for lx in [-0.15, 0.15]:
			cm.box("wood_dark", Vector3(lx, 0.63, -0.15), Vector3(0.042, 0.42, 0.042))
		cm.box("wood_plank", Vector3(0, 0.62, -0.15), Vector3(0.34, 0.10, 0.035))
		cm.box("wood_plank", Vector3(0, 0.77, -0.15), Vector3(0.34, 0.12, 0.035))
		_merge_transformed(m, cm, Vector3(cx, 0.0, 0.0), yaw)
	_merge_transformed(sm, m, pos, rot)

# ------------------------------------------------------------------ Alimentari Rosa v1.4 (scaffali pieni & casse/sacchetti)
static func add_alimentari_shelves(sm: StyleMesh, pos: Vector3, rot: float = 0.0) -> void:
	var m := StyleMesh.new()
	# Due mensole in legno chiaro con mensole di sostegno inferiori
	for sy in [1.44, 1.94]:
		m.box("wood_light", Vector3(0, sy, 0), Vector3(1.38, 0.06, 0.30))
		for bx in [-0.48, 0.48]:
			m.box("wood_dark", Vector3(bx, sy - 0.10, -0.05), Vector3(0.06, 0.16, 0.20))
	# Ripiano superiore: barattoli marmellata, olive e barattoli colorati
	for i in range(6):
		var ix := -0.52 + float(i) * 0.208
		var jar_mat: String = ["jar_jam", "tin_gold", "jar_green", "tin_red", "jar_jam", "tin_blue"][i]
		if i % 2 == 0:
			m.cyl(jar_mat, Vector3(ix, 1.97, 0.01), 0.058, 0.058, 0.16, 10)
			m.cyl("brass", Vector3(ix, 2.13, 0.01), 0.062, 0.062, 0.024, 10)
		else:
			m.box(jar_mat, Vector3(ix, 2.06, 0.01), Vector3(0.11, 0.18, 0.11))
	# Ripiano inferiore: frutta lucida (mele, limoni, arance)
	m.blob("apple", Vector3(-0.38, 1.56, 0.02), Vector3(0.12, 0.10, 0.12), 4, 8, 0.05, 4)
	m.blob("lemon", Vector3(0.0, 1.55, 0.02), Vector3(0.12, 0.095, 0.12), 4, 8, 0.05, 7)
	m.blob("orange", Vector3(0.38, 1.56, 0.02), Vector3(0.12, 0.10, 0.12), 4, 8, 0.05, 9)
	_merge_transformed(sm, m, pos, rot)

static func add_alimentari_crates(sm: StyleMesh, pos: Vector3, rot: float = 0.0) -> void:
	var m := StyleMesh.new()
	m.box("wood_plank", Vector3(0, 0.22, 0), Vector3(0.64, 0.44, 0.48), {"col": true})
	m.box("wood_dark", Vector3(0, 0.22, 0.245), Vector3(0.66, 0.04, 0.02))
	m.box("wood_dark", Vector3(0, 0.38, 0.245), Vector3(0.66, 0.04, 0.02))
	# Sacchetti di carta kraft piegati sopra e accanto alla cassa
	m.box("paper_bag", Vector3(-0.14, 0.57, 0.02), Vector3(0.20, 0.26, 0.16), {"rot": 0.12})
	m.box("paper_bag", Vector3(0.16, 0.55, -0.02), Vector3(0.18, 0.22, 0.14), {"rot": -0.15})
	m.blob("apple", Vector3(0.02, 0.48, 0.06), Vector3(0.09, 0.08, 0.09), 4, 7, 0.04, 12)
	_merge_transformed(sm, m, pos, rot)

# ------------------------------------------------------------------ OGR Tech Hub Torino Espanso & Accessibile (v1.4)
static func _add_ogr_pod(m: StyleMesh, center: Vector3, w: float, d: float, face_z: float, door_open: bool, seed_idx: int) -> void:
	var h := 2.85
	var wt := 0.10
	# Telaio container/vetro antracite con zoccolo arancione OGR e porta vetrata (Pod 01 aperta, Pods 02/03/04 chiuse!)
	m.box("iron", center + Vector3(0, 0.04, 0), Vector3(w + 0.12, 0.08, d + 0.12))
	m.box("iron", center + Vector3(0, h + 0.06, 0), Vector3(w + 0.12, 0.14, d + 0.12))
	m.box("ogr_orange", center + Vector3(0, h + 0.10, face_z * (d * 0.5 + 0.06)), Vector3(1.55, 0.08, 0.06))
	# Parete posteriore (opposta alla facciata vetrata)
	var back_z := -face_z * (d * 0.5 - wt * 0.5)
	m.box("iron", center + Vector3(0, h * 0.5, back_z), Vector3(w, h, wt), {"col": true})
	# Pareti laterali in acciaio ondulato scuro
	for sx in [-w * 0.5 + wt * 0.5, w * 0.5 - wt * 0.5]:
		m.box("iron", center + Vector3(sx, h * 0.5, 0), Vector3(wt, h, d - wt), {"col": true})
		for ri in range(5):
			var rz := -d * 0.36 + float(ri) * (d * 0.18)
			m.box("stone_dark", center + Vector3(sx + signf(sx) * 0.055, h * 0.5, rz), Vector3(0.025, h - 0.18, 0.09))
	# Facciata vetrata verso il corridoio centrale
	var front_z := face_z * (d * 0.5 - wt * 0.5)
	var glass_panel_w := (w - 1.55) * 0.5
	if glass_panel_w > 0.2:
		for sg in [-1.0, 1.0]:
			var gx: float = sg * (w * 0.5 - glass_panel_w * 0.5)
			m.box("iron", center + Vector3(gx, 0.36, front_z), Vector3(glass_panel_w, 0.72, wt), {"col": true})
			m.box("glass_exterior", center + Vector3(gx, 1.72, front_z), Vector3(glass_panel_w - 0.12, 1.98, 0.04))
			m.box("iron", center + Vector3(gx, 2.75, front_z), Vector3(glass_panel_w, 0.14, wt))
	if door_open:
		# Pod 01 aperto con porta vetrata scostata lateralmente
		m.box("glass_exterior", center + Vector3(-0.78, 1.38, front_z - face_z * 0.12), Vector3(0.95, 2.50, 0.04))
		m.box("ogr_orange", center + Vector3(0.0, 2.58, front_z + face_z * 0.02), Vector3(1.50, 0.10, 0.09))
	else:
		# Pods 02/03/04 chiusi fisicamente con vetro scuro e serratura
		m.box("glass_exterior", center + Vector3(0, 1.35, front_z), Vector3(1.48, 2.48, 0.05), {"col": true})
		m.box("iron", center + Vector3(0, 1.35, front_z), Vector3(0.06, 2.48, 0.08))
		m.box("brass", center + Vector3(0.14, 1.15, front_z + face_z * 0.05), Vector3(0.06, 0.22, 0.06))
	# Arredo interno visibile attraverso le vetrate
	m.box("wood_plank", center + Vector3(0, 0.75, -face_z * 0.45), Vector3(w * 0.58, 0.06, 0.78))
	m.box("iron", center + Vector3(-w * 0.25, 0.38, -face_z * 0.45), Vector3(0.06, 0.72, 0.68))
	m.box("iron", center + Vector3(w * 0.25, 0.38, -face_z * 0.45), Vector3(0.06, 0.72, 0.68))
	m.box("gaming_black", center + Vector3(-0.45 + float(seed_idx % 2) * 0.2, 1.02, -face_z * 0.52), Vector3(0.62, 0.36, 0.04))
	m.box("glass_cool", center + Vector3(-0.45 + float(seed_idx % 2) * 0.2, 1.02, -face_z * 0.49), Vector3(0.56, 0.30, 0.02))
	m.box("white", center + Vector3(w * 0.24, 1.72, back_z + face_z * 0.08), Vector3(1.35, 0.88, 0.04))

static func _add_ogr_desk_island(m: StyleMesh, center: Vector3, w: float, d: float) -> void:
	m.box("iron", center + Vector3(-w * 0.46, 0.38, 0), Vector3(0.07, 0.74, d * 0.90), {"col": true})
	m.box("iron", center + Vector3(w * 0.46, 0.38, 0), Vector3(0.07, 0.74, d * 0.90), {"col": true})
	m.box("wood_plank", center + Vector3(0, 0.76, 0), Vector3(w, 0.065, d), {"col": true})
	for px in [-w * 0.28, w * 0.28]:
		for pz in [-0.36, 0.36]:
			var face_sign := signf(float(pz))
			# Monitor più vicino su piedistallo + schermo luminoso
			var mz: float = float(pz) * 0.46
			m.box("iron", center + Vector3(px, 0.80, mz), Vector3(0.18, 0.02, 0.14))
			m.box("iron", center + Vector3(px, 0.90, mz - face_sign * 0.02), Vector3(0.04, 0.18, 0.04))
			m.box("gaming_black", center + Vector3(px, 1.05, mz), Vector3(0.54, 0.34, 0.035))
			m.box("glass_cool", center + Vector3(px, 1.05, mz + face_sign * 0.02), Vector3(0.48, 0.28, 0.02))
			# Tastiera meccanica + tasti chiari + tappetino & mouse davanti alla seduta
			var kz: float = float(pz) + face_sign * 0.18
			m.box("iron_dark", center + Vector3(px - 0.04, 0.803, kz), Vector3(0.38, 0.018, 0.135))
			m.box("steel", center + Vector3(px - 0.04, 0.815, kz), Vector3(0.35, 0.008, 0.105))
			m.box("gaming_black", center + Vector3(px + 0.24, 0.796, kz), Vector3(0.18, 0.005, 0.20))
			m.box("steel", center + Vector3(px + 0.24, 0.808, kz + face_sign * 0.01), Vector3(0.055, 0.022, 0.09))
			m.cyl("ogr_orange", center + Vector3(px - 0.32, 0.793, kz - face_sign * 0.05), 0.035, 0.035, 0.075, 10)
			# Sedia girevole con schienale arancione OGR
			var cz: float = pz + face_sign * 0.70
			m.cyl("iron", center + Vector3(px, 0.0, cz), 0.26, 0.04, 0.14, 5)
			m.cyl("iron", center + Vector3(px, 0.14, cz), 0.032, 0.032, 0.32, 8)
			m.box("gaming_black", center + Vector3(px, 0.47, cz), Vector3(0.44, 0.06, 0.44), {"col": true})
			m.box("ogr_orange", center + Vector3(px, 0.79, cz + face_sign * 0.20), Vector3(0.42, 0.56, 0.06))
			m.box("iron", center + Vector3(px, 0.79, cz + face_sign * 0.235), Vector3(0.44, 0.58, 0.025))

static func add_ogr_hall(sm: StyleMesh, center: Vector3, rot: float = 0.0) -> void:
	var m := StyleMesh.new()
	var w := 27.5   # X: -13.75 .. +13.75 (World 96.5 .. 124.0)
	var d := 24.5   # Z: -12.25 .. +12.25 (World -9.5 .. +15.0)
	var h := 6.6
	var wt := 0.36
	var door_w := 4.8

	# 1. Pavimento industriale in cemento lucidato (top Y = 0.04) + canaline/grate metalliche + strisce gialle
	m.box("concrete_ogr", Vector3(0, -0.04, 0), Vector3(w, 0.16, d), {"col": true, "surface": "tile"})
	m.box("slabs", Vector3(-w * 0.5 - 0.18, 0.015, 0), Vector3(0.48, 0.05, door_w + 0.4), {"col": true, "surface": "stone"})
	for gx in [-5.6, 2.8]:
		m.box("grate_dark", Vector3(gx, 0.043, 0), Vector3(0.86, 0.012, 8.8))
		m.box("safety_yellow", Vector3(gx - 0.48, 0.043, 0), Vector3(0.08, 0.008, 8.8))
		m.box("safety_yellow", Vector3(gx + 0.48, 0.043, 0), Vector3(0.08, 0.008, 8.8))

	# 2. Facciata Ovest (-X, ingresso dal Mercato Nord!) con ampio varco aperto (Z: -2.4 .. +2.4)
	var side_wing_z := (d - door_w) * 0.5
	m.box("ashlar", Vector3(-w * 0.5 + wt * 0.5, 0.38, -d * 0.5 + side_wing_z * 0.5), Vector3(wt + 0.08, 0.76, side_wing_z))
	m.box("ashlar", Vector3(-w * 0.5 + wt * 0.5, 0.38, d * 0.5 - side_wing_z * 0.5), Vector3(wt + 0.08, 0.76, side_wing_z))
	m.box("brick_ogr", Vector3(-w * 0.5 + wt * 0.5, h * 0.5, -d * 0.5 + side_wing_z * 0.5), Vector3(wt, h, side_wing_z), {"col": true})
	m.box("brick_ogr", Vector3(-w * 0.5 + wt * 0.5, h * 0.5, d * 0.5 - side_wing_z * 0.5), Vector3(wt, h, side_wing_z), {"col": true})
	m.box("brick_ogr", Vector3(-w * 0.5 + wt * 0.5, 3.85 + (h - 3.85) * 0.5, 0), Vector3(wt, h - 3.85, door_w + 0.2), {"col": true})
	# Pensilina acciaio ingresso OGR & banda ciano/arancione
	m.box("iron", Vector3(-w * 0.5 - 0.72, 3.88, 0), Vector3(1.50, 0.14, door_w + 1.2))
	m.box("ogr_orange", Vector3(-w * 0.5 - 0.16, 4.35, 0), Vector3(0.08, 0.10, door_w + 2.4))
	m.box("cyan_accent", Vector3(-w * 0.5 - 0.16, 4.65, 0), Vector3(0.08, 0.42, door_w + 1.8))

	# 3. Pareti esterne Nord (-Z), Sud (+Z) ed Est (+X) in mattoni OGR + grandi finestre ad arco ad alta navata
	m.box("brick_ogr", Vector3(0, h * 0.5, -d * 0.5 + wt * 0.5), Vector3(w, h, wt), {"col": true})
	m.box("brick_ogr", Vector3(0, h * 0.5, d * 0.5 - wt * 0.5), Vector3(w, h, wt), {"col": true})
	m.box("brick_ogr", Vector3(w * 0.5 - wt * 0.5, h * 0.5, 0), Vector3(wt, h, d - wt), {"col": true})
	# Portale nero scenografico sulla parete Est in fondo (stile foto OGR)
	m.box("gaming_black", Vector3(w * 0.5 - wt - 0.04, 2.35, 0), Vector3(0.10, 4.4, 7.6))
	m.box("iron", Vector3(w * 0.5 - wt - 0.06, 4.65, 0), Vector3(0.14, 0.22, 7.9))

	for wx in [-8.5, -2.5, 3.5, 9.5]:
		# Pilastri interni in acciaio scuro ad H
		for sz in [-5.4, 5.4]:
			m.box("iron", Vector3(wx, h * 0.5, sz), Vector3(0.32, h, 0.32), {"col": true})
			m.box("stone_dark", Vector3(wx, 0.20, sz), Vector3(0.56, 0.34, 0.56))
		# Finestre industriali Nord e Sud con montanti in ferro e vetro luce naturale
		for sz_w in [-d * 0.5 + wt * 0.5, d * 0.5 - wt * 0.5]:
			var out_s := signf(sz_w)
			m.box("iron", Vector3(wx, 3.25, sz_w), Vector3(3.6, 3.4, wt + 0.08))
			m.box("glass_studio_day", Vector3(wx, 3.25, sz_w + out_s * 0.02), Vector3(3.32, 3.10, wt + 0.12))
			for mx in [-1.1, 0.0, 1.1]:
				m.box("iron", Vector3(wx + mx, 3.25, sz_w), Vector3(0.06, 3.12, wt + 0.14))
			m.box("iron", Vector3(wx, 3.25, sz_w), Vector3(3.36, 0.07, wt + 0.14))

	# 4. Capriate reticolari in ferro, copertura e ampio lucernario centrale lungo tutta la navata
	m.gable("roof_slate", "brick_ogr", Vector3(0, h + 0.10, 0), w + 0.5, d + 0.5, 2.4, true)
	m.box("iron", Vector3(0, h + 2.32, 0), Vector3(w - 1.6, 0.22, 4.6))
	m.box("glass_studio_day", Vector3(0, h - 0.06, 0), Vector3(w - 2.4, 0.10, 4.1))
	for tx in [-11.5, -8.5, -5.5, -2.5, 0.5, 3.5, 6.5, 9.5]:
		m.box("iron", Vector3(tx, h - 0.72, 0), Vector3(0.16, 0.22, d - 1.0))
		m.box("iron", Vector3(tx, h - 0.18, 0), Vector3(0.14, 0.24, d - 1.4))
		m.box("led_white", Vector3(tx, h - 0.85, 0), Vector3(0.09, 0.05, 3.8))

	# 5. I 4 Pod Container Vetrati (Bay 01 aperto a Sud-Ovest; Pods 02/03/04 chiusi con cartello "CHIUSO")
	_add_ogr_pod(m, Vector3(-7.6, 0.04, 8.6), 5.6, 4.4, -1.0, true, 1)    # Pod 01 APERTO
	_add_ogr_pod(m, Vector3(-6.2, 0.04, -8.6), 5.4, 4.2, 1.0, false, 2)   # Pod 02 CHIUSO
	_add_ogr_pod(m, Vector3(2.2, 0.04, -8.6), 5.4, 4.2, 1.0, false, 3)    # Pod 03 CHIUSO
	_add_ogr_pod(m, Vector3(6.4, 0.04, 8.6), 5.4, 4.4, -1.0, false, 4)    # Pod 04 CHIUSO

	# 6. Isole Scrivanie Open-Space (lasciano corridoio centrale libero |Z| <= 2.1m!)
	_add_ogr_desk_island(m, Vector3(-1.8, 0.04, -4.1), 4.2, 1.45)
	_add_ogr_desk_island(m, Vector3(1.8, 0.04, 4.1), 4.2, 1.45)

	# 7. Zona Lounge Orientale, listelli acustici & Piante interne
	m.box("lounge_sofa", Vector3(9.4, 0.28, -4.4), Vector3(2.2, 0.42, 0.92), {"col": true})
	m.box("lounge_sofa", Vector3(9.4, 0.62, -4.78), Vector3(2.2, 0.44, 0.18))
	m.box("ogr_orange", Vector3(11.3, 0.34, -3.5), Vector3(0.76, 0.54, 0.76), {"col": true, "rot": -0.35})
	m.box("wood_plank", Vector3(9.4, 0.32, -2.85), Vector3(1.15, 0.06, 0.68))
	m.cyl("iron", Vector3(9.4, 0.04, -2.85), 0.04, 0.04, 0.26, 8)
	# Totem digitale & libreria design nella zona Lounge Est
	m.box("iron", Vector3(13.08, 1.15, -4.35), Vector3(0.42, 2.20, 1.65), {"col": true})
	for sy in [0.65, 1.25, 1.85]:
		m.box("wood_plank", Vector3(13.06, sy, -4.35), Vector3(0.38, 0.05, 1.54))
	m.box("cyan_accent", Vector3(13.02, 1.48, -3.95), Vector3(0.24, 0.36, 0.14))
	m.box("ogr_orange", Vector3(13.02, 0.88, -4.65), Vector3(0.24, 0.34, 0.22))
	# Listelli acustici verticali in legno ai lati del grande portale Est + deflettori soffitto
	for sz_slat in [-5.2, -4.6, 4.6, 5.2]:
		m.box("wood_plank", Vector3(w * 0.5 - wt - 0.04, 2.45, sz_slat), Vector3(0.08, 4.30, 0.18))
	for bx in [-7.0, -1.0, 5.0]:
		m.box("wood_plank", Vector3(bx, h - 1.25, -2.8), Vector3(0.08, 0.28, 1.8))
		m.box("wood_plank", Vector3(bx, h - 1.25, 2.8), Vector3(0.08, 0.28, 1.8))
	for pt in [Vector3(-11.2, 0.04, 4.4), Vector3(7.6, 0.04, -5.0), Vector3(11.6, 0.04, 4.2)]:
		m.cyl("stone_dark", pt, 0.24, 0.30, 0.56, 10)
		m.cyl("bark", pt + Vector3(0, 0.56, 0), 0.05, 0.03, 0.72, 8)
		m.foliage_cluster("leaves_canopy", pt + Vector3(0, 1.38, 0), 0.42, int(absf(pt.x) * 11.0), 5)

	_merge_transformed(sm, m, center, rot)

# ------------------------------------------------------------------ Nuovi Edifici Borgo Po / Lungo Po (v1.5)
static func add_i3p_incubator(sm: StyleMesh, center: Vector3, rot: float = 0.0) -> void:
	var m := StyleMesh.new()
	var w := 11.0
	var d := 6.4
	var h := 5.2
	m.box("ashlar", Vector3(0, 0.35, 0), Vector3(w + 0.14, 0.70, d + 0.14))
	m.box("metal_panel", Vector3(0, 0.70 + (h - 0.70) * 0.5, 0), Vector3(w, h - 0.70, d), {"col": true})
	m.box("iron", Vector3(0, h + 0.10, 0), Vector3(w + 0.36, 0.20, d + 0.36))
	m.box("glass_studio_day", Vector3(0, 2.75, d * 0.5 + 0.03), Vector3(8.2, 2.9, 0.06))
	for mx in [-2.6, 0.0, 2.6]:
		m.box("iron", Vector3(mx, 2.75, d * 0.5 + 0.06), Vector3(0.14, 3.0, 0.08))
	m.box("cyan_accent", Vector3(0, 4.45, d * 0.5 + 0.08), Vector3(7.4, 0.36, 0.06))
	m.box("iron", Vector3(0, 3.65, d * 0.5 + 0.55), Vector3(4.6, 0.12, 1.15))
	m.box("glass_exterior", Vector3(0, 1.15, d * 0.5 + 0.05), Vector3(2.4, 2.15, 0.05))
	m.box("stone_trim", Vector3(0, 0.06, d * 0.5 + 0.45), Vector3(4.2, 0.12, 0.90), {"col": true, "surface": "stone"})
	_merge_transformed(sm, m, center, rot)

static func add_drone_lab(sm: StyleMesh, center: Vector3, rot: float = 0.0) -> void:
	var m := StyleMesh.new()
	var w := 8.6
	var d := 6.0
	var h := 4.0
	m.box("ashlar", Vector3(0, 0.32, 0), Vector3(w + 0.10, 0.64, d + 0.10))
	m.box("plaster_sky", Vector3(0, 0.64 + (h - 0.64) * 0.5, 0), Vector3(w, h - 0.64, d), {"col": true})
	m.box("stone_trim", Vector3(0, h + 0.08, 0), Vector3(w + 0.26, 0.16, d + 0.26))
	m.hip_roof("roof_slate", Vector3(0, h + 0.16, 0), w + 0.48, d + 0.48, 1.25)
	m.box("iron", Vector3(0, 3.65, d * 0.5 + 0.06), Vector3(5.6, 0.46, 0.08))
	m.box("cyan_accent", Vector3(0, 3.38, d * 0.5 + 0.07), Vector3(5.6, 0.08, 0.08))
	m.box("iron", Vector3(0, 1.25, d * 0.5 + 0.04), Vector3(2.2, 2.30, 0.08))
	m.box("glass_cool", Vector3(0, 1.25, d * 0.5 + 0.06), Vector3(1.9, 2.05, 0.04))
	for wx in [-2.65, 2.65]:
		_add_window(m, Vector3(wx, 1.55, d * 0.5), 0.0, "fabric_blue", "")
	# Piazzola atterraggio droni H davanti al laboratorio
	var pad_z := d * 0.5 + 1.85
	m.cyl("stone_dark", Vector3(0, 0.02, pad_z), 1.45, 1.52, 0.06, 16, {"col": true, "surface": "asphalt"})
	m.box("safety_yellow", Vector3(-0.36, 0.056, pad_z), Vector3(0.14, 0.015, 0.92))
	m.box("safety_yellow", Vector3(0.36, 0.056, pad_z), Vector3(0.14, 0.015, 0.92))
	m.box("safety_yellow", Vector3(0.0, 0.056, pad_z), Vector3(0.76, 0.015, 0.14))
	_merge_transformed(sm, m, center, rot)

static func add_riverside_rowboat(sm: StyleMesh, pos: Vector3, rot: float = 0.0) -> void:
	var m := StyleMesh.new()
	m.box("wood_dark", Vector3(0, 0.12, 0), Vector3(1.15, 0.22, 2.55))
	m.box("wood_plank", Vector3(0, 0.26, 0), Vector3(1.04, 0.12, 2.38))
	m.box("wood_dark", Vector3(-0.48, 0.38, 0), Vector3(0.09, 0.24, 2.40))
	m.box("wood_dark", Vector3(0.48, 0.38, 0), Vector3(0.09, 0.24, 2.40))
	m.box("wood_light", Vector3(0, 0.42, -0.35), Vector3(0.92, 0.06, 0.26))
	m.box("wood_light", Vector3(0, 0.42, 0.45), Vector3(0.92, 0.06, 0.26))
	m.box("fabric_blue", Vector3(0, 0.24, 1.24), Vector3(0.96, 0.26, 0.22))
	_merge_transformed(sm, m, pos, rot)

static func add_alpine_backdrop(sm: StyleMesh) -> void:
	# Massicci alpini larghi e sovrapposti in catena continua + dolci colline torinesi a Est (zero collisione!)
	var peaks := [
		[Vector3(-82.0, -0.5, -66.0), 62.0, 44.0, 27.0, true, 101],
		[Vector3(-42.0, -0.5, -72.0), 66.0, 48.0, 31.0, true, 102],
		[Vector3(-2.0,  -0.5, -78.0), 68.0, 48.0, 24.0, true, 103],
		[Vector3(44.0,  -0.5, -72.0), 72.0, 50.0, 34.0, true, 104],
		[Vector3(92.0,  -0.5, -68.0), 68.0, 46.0, 29.0, true, 105],
		[Vector3(140.0, -0.5, -62.0), 64.0, 46.0, 25.0, true, 110],
		[Vector3(-104.0, -0.5, -14.0), 48.0, 56.0, 23.0, true, 106],
		[Vector3(-106.0, -0.5, 34.0), 50.0, 58.0, 21.0, true, 107],
		[Vector3(166.0, -0.5, 16.0), 64.0, 72.0, 9.5, false, 108],
		[Vector3(162.0, -0.5, 58.0), 64.0, 68.0, 9.0, false, 109],
	]
	for pk in peaks:
		var pos: Vector3 = pk[0]
		var w: float = pk[1]
		var d: float = pk[2]
		var h: float = pk[3]
		var snow: bool = pk[4]
		var seed_v: int = pk[5]
		sm.mountain_peak("alpine_peak" if snow else "alpine_hill", pos, w, d, h, seed_v)

# ------------------------------------------------------------------ NPC stilizzati unificati (scolpiti)
static func add_npc_model(parent: Node3D, opts: Dictionary = {}) -> Node3D:
	return VillageCharacters.build(parent, opts)

# ------------------------------------------------------------------ Miniera Alpina Val di Susa (v1.6)
static func add_pine_tree(sm: StyleMesh, pos: Vector3, seed_val: int = 1, s: float = 1.0) -> void:
	var rnd := RandomNumberGenerator.new()
	rnd.seed = seed_val
	var h_scale := s * rnd.randf_range(0.92, 1.14)
	# Tronco slanciato alpino + 4 palchi conici sempreverdi
	sm.cyl("bark", pos + Vector3(0, -0.05, 0), 0.22 * s, 0.08 * s, 3.8 * h_scale, 8)
	var tiers := [
		[1.45, 1.42, 1.35, "leaves_canopy_dark"],
		[2.35, 1.18, 1.25, "leaves_pine"],
		[3.15, 0.90, 1.15, "leaves_pine"],
		[3.88, 0.62, 1.05, "leaves_pine"],
		[4.55, 0.34, 0.85, "leaves_pine"],
	]
	for t in tiers:
		var ty: float = pos.y + float(t[0]) * h_scale
		var tr_b: float = float(t[1]) * s
		var th: float = float(t[2]) * h_scale
		var tmat: String = str(t[3])
		if tmat == "leaves_canopy_dark":
			sm.cyl("leaves_pine", Vector3(pos.x, ty, pos.z), tr_b, tr_b * 0.16, th, 9, {"smooth": false})
		else:
			sm.cyl(tmat, Vector3(pos.x, ty, pos.z), tr_b, tr_b * 0.12, th, 9, {"smooth": false})
	sm.add_collider_cyl(pos + Vector3(0, 1.3 * h_scale, 0), 0.32 * s, 2.6 * h_scale)

static func add_mine_tunnel_portal(sm: StyleMesh, pos: Vector3, rot: float = 0.0) -> void:
	var m := StyleMesh.new()
	# Parete buia profonda all'interno della galleria + colliders di blocco oltre la bocca
	m.box("iron_dark", Vector3(0, 1.45, -2.1), Vector3(3.1, 2.9, 4.2))
	m.box("quarry_rock", Vector3(0, 3.35, -1.8), Vector3(5.6, 1.4, 4.4), {"col": true})
	for sx in [-2.05, 2.05]:
		m.box("quarry_rock", Vector3(sx, 1.75, -1.3), Vector3(1.5, 3.5, 3.6), {"col": true})
	m.add_collider_box(Vector3(0, 1.45, -2.5), Vector3(2.8, 2.8, 0.8))

	# Armatura pesante in travi di larice (portali lungo la galleria + saette)
	for tz in [0.25, -0.75, -1.75]:
		for sx in [-1.28, 1.28]:
			m.box("mine_timber", Vector3(sx, 1.32, tz), Vector3(0.24, 2.64, 0.24), {"col": true})
			m.box("mine_timber", Vector3(sx - signf(sx) * 0.28, 2.26, tz), Vector3(0.16, 0.72, 0.18), {"rot": signf(sx) * 0.68})
		m.box("mine_timber", Vector3(0, 2.70, tz), Vector3(3.26, 0.28, 0.28))
	m.box("mine_timber", Vector3(0, 2.90, -0.75), Vector3(3.38, 0.14, 2.55))

	# Massi & contrafforti laterali dell'ingresso + lampada industriale da galleria
	m.blob("quarry_rock", Vector3(-2.35, 0.75, 0.55), Vector3(0.85, 0.78, 0.72), 4, 7, 0.22, 11)
	m.blob("quarry_rock", Vector3(2.35, 0.75, 0.55), Vector3(0.85, 0.78, 0.72), 4, 7, 0.22, 17)
	m.blob("quarry_rock", Vector3(0.0, 3.45, 0.25), Vector3(2.6, 0.85, 0.75), 4, 8, 0.25, 23)
	m.box("iron_dark", Vector3(0, 2.48, 0.44), Vector3(0.42, 0.16, 0.24))
	m.box("lamp_glow", Vector3(0, 2.42, 0.50), Vector3(0.32, 0.14, 0.12))
	_merge_transformed(sm, m, pos, rot)

static func add_mine_tracks(sm: StyleMesh, start_pos: Vector3, end_pos: Vector3, tie_step: float = 0.65) -> void:
	var delta := end_pos - start_pos
	delta.y = 0.0
	var length := delta.length()
	if length < 0.2:
		return
	var mid := (start_pos + end_pos) * 0.5
	var yaw := atan2(delta.x, delta.z)
	var m := StyleMesh.new()
	var n_ties := maxi(2, int(floor(length / tie_step)))
	for i in range(n_ties + 1):
		var z := -length * 0.5 + (float(i) / float(n_ties)) * length
		m.box("mine_timber", Vector3(0, 0.025, z), Vector3(1.22, 0.05, 0.14))
	for rx in [-0.43, 0.43]:
		m.box("rail_steel", Vector3(rx, 0.075, 0), Vector3(0.06, 0.06, length))
	_merge_transformed(sm, m, Vector3(mid.x, 0.0, mid.z), yaw)

static func add_minecart_wheel_mesh() -> ArrayMesh:
	var m := StyleMesh.new()
	_merge_rotated_x_cyl(m, Vector3.ZERO, 0.15, 0.08, 12, "rail_steel", "iron_dark")
	return m.to_mesh(Callable(VillageMaterials, "mat"))

static func add_minecart_body(sm: StyleMesh, ore_mat: String = "ore_copper") -> void:
	# Carrello minerario su rotaia (scartamento 0.86m, ruote Y=0.16)
	sm.box("iron_dark", Vector3(0, 0.28, 0), Vector3(0.82, 0.12, 1.38))
	sm.hexa("metal", [
		Vector3(-0.36, 0.34, -0.62), Vector3(0.36, 0.34, -0.62), Vector3(0.36, 0.34, 0.62), Vector3(-0.36, 0.34, 0.62),
		Vector3(-0.50, 0.86, -0.74), Vector3(0.50, 0.86, -0.74), Vector3(0.50, 0.86, 0.74), Vector3(-0.50, 0.86, 0.74),
	])
	sm.box("safety_yellow", Vector3(0, 0.88, 0.74), Vector3(1.02, 0.06, 0.05))
	sm.box("safety_yellow", Vector3(0, 0.88, -0.74), Vector3(1.02, 0.06, 0.05))
	sm.box("iron_dark", Vector3(0, 0.28, 0.73), Vector3(0.24, 0.14, 0.10))
	sm.box("iron_dark", Vector3(0, 0.28, -0.73), Vector3(0.24, 0.14, 0.10))
	# Cumulo di minerale grezzo e cristalli dentro il cassone
	sm.blob("quarry_rock", Vector3(0, 0.86, 0), Vector3(0.42, 0.18, 0.56), 4, 8, 0.20, 7)
	sm.blob(ore_mat, Vector3(-0.14, 0.98, 0.12), Vector3(0.16, 0.14, 0.16), 4, 6, 0.26, 13)
	sm.blob("ore_silicon", Vector3(0.16, 0.96, -0.14), Vector3(0.14, 0.16, 0.14), 4, 6, 0.26, 19)

static func add_ore_vein_outcrop(sm: StyleMesh, pos: Vector3, ore_mat: String = "ore_copper", rot: float = 0.0) -> void:
	var m := StyleMesh.new()
	# Massiccio roccioso di cava stratificato con venature minerali angolari (niente capsule arrotondate né coperchi gialli!)
	m.blob("quarry_rock", Vector3(0, 0.42, 0), Vector3(1.18, 0.50, 0.96), 5, 9, 0.25, 31)
	m.blob("quarry_slate", Vector3(-0.56, 0.62, -0.18), Vector3(0.70, 0.58, 0.62), 4, 8, 0.24, 41)
	m.blob("quarry_slate", Vector3(0.58, 0.34, 0.26), Vector3(0.56, 0.36, 0.50), 4, 7, 0.24, 53)
	m.add_collider_box(Vector3(0, 0.58, 0), Vector3(2.10, 1.18, 1.70))

	# Cristalli sfaccettati a prisma esagonale che emergono dalle spaccature della roccia
	var seams := [
		[Vector3(-0.24, 0.72, 0.24), Vector3(-0.46, 1.06, 0.42), 0.095],
		[Vector3(-0.02, 0.78, 0.06), Vector3(-0.08, 1.24, 0.22), 0.115],
		[Vector3(0.22, 0.70, 0.28), Vector3(0.42, 1.04, 0.46), 0.090],
		[Vector3(0.08, 0.62, -0.22), Vector3(0.26, 0.98, -0.34), 0.085],
		[Vector3(-0.34, 0.66, -0.14), Vector3(-0.54, 0.96, -0.28), 0.080],
	]
	for cr in seams:
		var p0: Vector3 = cr[0]
		var p1: Vector3 = cr[1]
		var r0: float = float(cr[2])
		var mid := p0.lerp(p1, 0.68)
		m.tube_path(ore_mat, [p0, mid, p1], [r0, r0 * 0.84, 0.008], 5, false)
	# Venatura metallica incastonata nella fronte rocciosa
	m.box(ore_mat, Vector3(0.05, 0.56, 0.42), Vector3(0.68, 0.14, 0.48), {"rot": 0.38})

	# Cassetta mineraria in legno scuro con rinforzi in ferro + cavalletto faro alogeno
	m.box("mine_timber", Vector3(-1.14, 0.22, 0.52), Vector3(0.56, 0.38, 0.40), {"col": true})
	m.box("iron_dark", Vector3(-1.14, 0.42, 0.52), Vector3(0.58, 0.035, 0.42))
	m.box("iron_dark", Vector3(-1.14, 0.22, 0.725), Vector3(0.58, 0.05, 0.02))
	m.cyl("iron_dark", Vector3(1.18, 0.0, -0.45), 0.22, 0.045, 1.28, 6)
	m.box("iron_dark", Vector3(1.18, 1.30, -0.45), Vector3(0.24, 0.18, 0.18), {"rot": -0.5})
	m.box("lamp_glow", Vector3(1.11, 1.30, -0.38), Vector3(0.18, 0.14, 0.04), {"rot": -0.5})
	_merge_transformed(sm, m, pos, rot)

static func add_ore_refinery_static(sm: StyleMesh, pos: Vector3, rot: float = 0.0) -> void:
	var m := StyleMesh.new()
	# Basamento calcestruzzo industriale
	m.box("concrete", Vector3(0, 0.10, 0), Vector3(3.6, 0.20, 2.5), {"col": true, "surface": "metal"})
	m.box("safety_yellow", Vector3(0, 0.21, 1.20), Vector3(3.55, 0.03, 0.10))
	# Tramoggia carico minerale a sinistra
	m.box("iron_dark", Vector3(-1.05, 0.72, 0), Vector3(1.25, 1.05, 1.45), {"col": true, "surface": "metal"})
	m.hexa("metal", [
		Vector3(-1.58, 1.24, -0.62), Vector3(-0.52, 1.24, -0.62), Vector3(-0.52, 1.24, 0.62), Vector3(-1.58, 1.24, 0.62),
		Vector3(-1.82, 1.88, -0.82), Vector3(-0.28, 1.88, -0.82), Vector3(-0.28, 1.88, 0.82), Vector3(-1.82, 1.88, 0.82),
	])
	# Camera di fusione & frantumazione centrale (mattoni refrattari + acciaio)
	m.box("server_body", Vector3(0.35, 1.02, 0), Vector3(1.55, 1.65, 1.55), {"col": true, "surface": "metal"})
	m.box("ashlar", Vector3(0.35, 0.62, 0.79), Vector3(0.95, 0.88, 0.06))
	m.box("iron_dark", Vector3(0.35, 0.62, 0.83), Vector3(0.76, 0.66, 0.05))
	m.box("orange_accent", Vector3(0.35, 1.86, 0), Vector3(1.62, 0.12, 1.62))
	# Camino alto fumi industriali sul retro-destra
	m.cyl("iron_dark", Vector3(0.78, 1.88, -0.35), 0.28, 0.22, 2.35, 12)
	m.cyl("orange_accent", Vector3(0.78, 3.88, -0.35), 0.24, 0.24, 0.24, 12)
	# Quadro SCADA & controllo flusso laterale destro
	m.box("server_body", Vector3(1.42, 0.78, 0.42), Vector3(0.48, 1.15, 0.54), {"col": true})
	m.box("cyan_accent", Vector3(1.67, 1.04, 0.42), Vector3(0.04, 0.34, 0.38))
	_merge_transformed(sm, m, pos, rot)

static func add_quarry_crane_base(sm: StyleMesh, pos: Vector3) -> void:
	sm.box("concrete", pos + Vector3(0, 0.18, 0), Vector3(2.2, 0.36, 2.2), {"col": true, "surface": "stone"})
	sm.box("safety_yellow", pos + Vector3(0, 0.42, 0), Vector3(1.35, 0.22, 1.35), {"col": true})
	for cx in [-0.42, 0.42]:
		for cz in [-0.42, 0.42]:
			sm.box("safety_yellow", pos + Vector3(cx, 3.25, cz), Vector3(0.14, 5.5, 0.14), {"col": true})
	for hy in [1.2, 2.4, 3.6, 4.8]:
		sm.box("safety_yellow", pos + Vector3(0, hy, -0.42), Vector3(0.92, 0.10, 0.08))
		sm.box("safety_yellow", pos + Vector3(0, hy, 0.42), Vector3(0.92, 0.10, 0.08))
		sm.box("safety_yellow", pos + Vector3(-0.42, hy, 0), Vector3(0.08, 0.10, 0.92))
		sm.box("safety_yellow", pos + Vector3(0.42, hy, 0), Vector3(0.08, 0.10, 0.92))
	sm.cyl("iron_dark", pos + Vector3(0, 5.95, 0), 0.54, 0.54, 0.28, 12)

static func add_quarry_crane_jib_mesh() -> ArrayMesh:
	var m := StyleMesh.new()
	# Braccio orizzontale (+Z braccio carico 5.2m, -Z contrappeso 2.1m) + cabina operatore + gancio sospeso
	m.box("safety_yellow", Vector3(0, 0.22, 1.55), Vector3(0.68, 0.42, 7.2))
	m.box("safety_yellow", Vector3(0, 0.72, 0.0), Vector3(0.54, 0.95, 0.54))
	m.capsule_seg("rail_steel", Vector3(0, 1.15, 0.0), Vector3(0, 0.44, 4.95), 0.025, 0.025, 6)
	m.capsule_seg("rail_steel", Vector3(0, 1.15, 0.0), Vector3(0, 0.44, -1.95), 0.025, 0.025, 6)
	m.box("concrete", Vector3(0, 0.18, -1.85), Vector3(0.96, 0.72, 1.05))
	m.box("iron_dark", Vector3(0.55, -0.18, 0.45), Vector3(0.62, 0.88, 0.84))
	m.box("glass_cool", Vector3(0.55, -0.05, 0.88), Vector3(0.50, 0.48, 0.04))
	# Carrello e gancio di sollevamento verso il basso
	m.box("iron_dark", Vector3(0, -0.06, 4.25), Vector3(0.52, 0.18, 0.62))
	m.cyl("rail_steel", Vector3(0, -2.15, 4.25), 0.022, 0.022, 2.05, 6)
	m.box("safety_yellow", Vector3(0, -2.26, 4.25), Vector3(0.28, 0.24, 0.22))
	return m.to_mesh(Callable(VillageMaterials, "mat"))

static func add_conveyor_structure(sm: StyleMesh, start_pos: Vector3, end_pos: Vector3) -> void:
	var delta := end_pos - start_pos
	delta.y = 0.0
	var length := delta.length()
	if length < 0.2:
		return
	var mid := (start_pos + end_pos) * 0.5
	var yaw := atan2(delta.x, delta.z)
	var m := StyleMesh.new()
	m.box("metal", Vector3(0, 0.56, 0), Vector3(0.72, 0.10, length), {"col": true, "surface": "metal"})
	m.box("iron_dark", Vector3(0, 0.62, 0), Vector3(0.52, 0.03, length - 0.08))
	m.box("safety_yellow", Vector3(-0.34, 0.68, 0), Vector3(0.05, 0.16, length))
	m.box("safety_yellow", Vector3(0.34, 0.68, 0), Vector3(0.05, 0.16, length))
	var legs := maxi(2, int(floor(length / 2.2)) + 1)
	for li in range(legs):
		var z := -length * 0.44 + (float(li) / float(maxi(1, legs - 1))) * (length * 0.88)
		m.box("iron_dark", Vector3(-0.28, 0.28, z), Vector3(0.08, 0.56, 0.08))
		m.box("iron_dark", Vector3(0.28, 0.28, z), Vector3(0.08, 0.56, 0.08))
	_merge_transformed(sm, m, Vector3(mid.x, 0.0, mid.z), yaw)

static func add_quarry_cabin(sm: StyleMesh, pos: Vector3, rot: float = 0.0) -> void:
	var m := StyleMesh.new()
	# Container ufficio geologico & controllo sicurezza (4.4 x 3.2 m)
	m.box("concrete", Vector3(0, 0.12, 0), Vector3(4.5, 0.24, 3.3), {"col": true, "surface": "stone"})
	m.box("corrugated_metal", Vector3(0, 1.54, 0), Vector3(4.2, 2.60, 3.0), {"col": true})
	m.box("safety_yellow", Vector3(0, 2.74, 0), Vector3(4.28, 0.18, 3.08))
	m.box("iron_dark", Vector3(0, 2.90, 0), Vector3(4.36, 0.14, 3.16))
	# Porta d'ingresso + finestre frontali (+Z) + gradino acciaio
	m.box("iron_dark", Vector3(-1.05, 1.28, 1.52), Vector3(0.98, 2.04, 0.08))
	m.box("glass_cool", Vector3(-1.05, 1.65, 1.57), Vector3(0.54, 0.62, 0.04))
	m.box("metal", Vector3(-1.05, 0.16, 1.84), Vector3(1.10, 0.18, 0.62), {"col": true, "surface": "metal"})
	m.box("iron_dark", Vector3(0.85, 1.55, 1.52), Vector3(1.48, 0.96, 0.08))
	m.box("glass_studio_day", Vector3(0.85, 1.55, 1.56), Vector3(1.34, 0.82, 0.04))
	m.box("cyan_accent", Vector3(0.85, 2.26, 1.54), Vector3(1.8, 0.22, 0.04))
	m.cyl("safety_yellow", Vector3(1.75, 3.12, 1.25), 0.10, 0.10, 0.22, 8)
	_merge_transformed(sm, m, pos, rot)

static func add_quarry_truck(sm: StyleMesh, pos: Vector3, rot: float = 0.0) -> void:
	var m := StyleMesh.new()
	var wr := 0.36
	for wx in [-0.88, 0.88]:
		for wz in [-1.25, 1.25]:
			_merge_rotated_x_cyl(m, Vector3(wx, wr, wz), wr, 0.28, 16, "tire", "safety_yellow")
	m.box("iron_dark", Vector3(0, 0.44, 0), Vector3(1.74, 0.20, 3.80), {"col": true})
	# Cabina anteriore (+Z)
	m.box("car_cream", Vector3(0, 0.96, 1.25), Vector3(1.82, 0.88, 1.28), {"col": true})
	m.box("car_cream", Vector3(0, 1.62, 1.08), Vector3(1.70, 0.64, 1.02))
	m.box("glass_exterior", Vector3(0, 1.64, 1.58), Vector3(1.54, 0.52, 0.06))
	m.box("iron_dark", Vector3(0, 0.72, 1.94), Vector3(1.86, 0.26, 0.14))
	m.box("lamp_glow", Vector3(-0.62, 0.96, 1.90), Vector3(0.24, 0.16, 0.04))
	m.box("lamp_glow", Vector3(0.62, 0.96, 1.90), Vector3(0.24, 0.16, 0.04))
	m.box("safety_yellow", Vector3(0, 1.98, 1.15), Vector3(0.95, 0.10, 0.18))
	# Cassone ribaltabile posteriore pieno di roccia & rame
	m.box("safety_yellow", Vector3(0, 1.02, -0.78), Vector3(1.92, 0.92, 2.32), {"col": true})
	m.blob("quarry_rock", Vector3(0, 1.50, -0.78), Vector3(0.84, 0.28, 0.95), 4, 8, 0.22, 71)
	m.blob("ore_copper", Vector3(0.28, 1.62, -0.58), Vector3(0.26, 0.20, 0.26), 4, 6, 0.24, 79)
	_merge_transformed(sm, m, pos, rot)

static func add_spark_particles(parent: Node3D, node_name: String, pos: Vector3, spark_col: Color = Color(1.0, 0.78, 0.25), one_shot: bool = true) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.name = node_name
	p.position = pos
	p.amount = 20 if one_shot else 12
	p.lifetime = 0.55 if one_shot else 0.45
	p.one_shot = one_shot
	p.explosiveness = 0.88 if one_shot else 0.18
	p.randomness = 0.55
	p.emitting = not one_shot
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 0.16
	p.direction = Vector3(0.0, 1.0, 0.0)
	p.spread = 72.0
	p.gravity = Vector3(0.0, -7.8, 0.0)
	p.initial_velocity_min = 1.8
	p.initial_velocity_max = 3.8
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.1

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.albedo_color = spark_col
	mat.emission_enabled = true
	mat.emission = spark_col
	mat.emission_energy_multiplier = 2.4

	var qm := QuadMesh.new()
	qm.size = Vector2(0.075, 0.075)
	qm.material = mat
	p.mesh = qm
	parent.add_child(p)
	return p

static func add_pickaxe_mesh() -> ArrayMesh:
	var m := StyleMesh.new()
	# Piccone da cava con manico in legno e testa curva in acciaio temperato (pivot al manico base)
	m.capsule_seg("wood_mid", Vector3(0, 0.0, 0), Vector3(0, 0.72, 0), 0.022, 0.024, 8)
	m.box("iron_dark", Vector3(0, 0.68, 0), Vector3(0.08, 0.08, 0.09))
	m.capsule_seg("rail_steel", Vector3(0, 0.68, 0.03), Vector3(0, 0.61, 0.30), 0.032, 0.008, 6)
	m.capsule_seg("rail_steel", Vector3(0, 0.68, -0.03), Vector3(0, 0.63, -0.24), 0.032, 0.024, 6)
	return m.to_mesh(Callable(VillageMaterials, "mat"))

static func add_fountain_particles(parent: Node3D, node_name: String, pos: Vector3, is_pond: bool = false) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.name = node_name
	p.position = pos
	p.amount = 34 if not is_pond else 22
	p.lifetime = 0.85
	p.preprocess = 0.8
	p.randomness = 0.35
	p.emitting = true
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 0.07 if not is_pond else 0.12
	p.direction = Vector3(0.0, 1.0, 0.0)
	p.spread = 22.0 if not is_pond else 28.0
	p.gravity = Vector3(0.0, -7.8, 0.0)
	p.initial_velocity_min = 2.1 if not is_pond else 1.7
	p.initial_velocity_max = 3.1 if not is_pond else 2.5
	p.scale_amount_min = 0.45
	p.scale_amount_max = 0.95

	var grad := Gradient.new()
	grad.set_color(0, Color(0.82, 0.95, 1.0, 0.85))
	grad.add_point(0.6, Color(0.68, 0.90, 0.98, 0.65))
	grad.set_color(1, Color(0.90, 0.98, 1.0, 0.0))
	p.color_ramp = grad

	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.vertex_color_use_as_albedo = true
	mat.albedo_color = Color(0.88, 0.96, 1.0, 0.85)
	mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	var qm := QuadMesh.new()
	qm.size = Vector2(0.085, 0.085)
	qm.material = mat
	p.mesh = qm
	parent.add_child(p)
	return p

static func add_torrefazione_interior(sm: StyleMesh) -> void:
	# Macchina espresso a doppia leva + macinacaffè + mensola barattoli di miscele
	sm.box("steel", Vector3(1.15, 1.18, -1.04), Vector3(0.62, 0.44, 0.42))
	sm.box("brass", Vector3(1.15, 1.38, -0.88), Vector3(0.56, 0.08, 0.14))
	sm.box("iron_dark", Vector3(0.45, 1.10, -1.06), Vector3(0.24, 0.28, 0.24))
	sm.cyl("copper", Vector3(0.45, 1.32, -1.06), 0.12, 0.08, 0.24, 10)
	# Tostatrice storica in rame & ghisa sulla sinistra del locale
	sm.box("iron_dark", Vector3(-2.35, 0.46, 0.65), Vector3(0.95, 0.92, 1.25), {"col": true})
	_merge_rotated_x_cyl(sm, Vector3(-2.35, 1.12, 0.65), 0.34, 0.78, 14, "copper", "brass")
	sm.cyl("copper", Vector3(-2.35, 1.48, 0.65), 0.28, 0.08, 0.38, 12)
	sm.cyl("iron_dark", Vector3(-2.35, 1.46, 0.25), 0.09, 0.09, 1.85, 10)
	# Sacchi di juta di caffè verde crudo + mensole con latte torrefazione oro & rosse
	sm.lathe_oval("burlap", Vector3(2.35, 0.04, -1.25), [
		Vector2(0.24, 0.0), Vector2(0.27, 0.18), Vector2(0.23, 0.40), Vector2(0.16, 0.52)
	], 1.0, 0.95, 12)
	sm.box("wood_dark", Vector3(1.75, 1.42, -2.52), Vector3(1.55, 0.08, 0.34))
	sm.box("wood_dark", Vector3(-1.75, 1.42, -2.52), Vector3(1.55, 0.08, 0.34))
	for sx in [-2.15, -1.75, -1.35, 1.35, 1.75, 2.15]:
		var tmat := "tin_gold" if absf(sx) > 1.5 else "tin_red"
		sm.cyl(tmat, Vector3(sx, 1.47, -2.52), 0.09, 0.09, 0.22, 10)
		sm.cyl("brass", Vector3(sx, 1.69, -2.52), 0.095, 0.095, 0.03, 10)
	# Lavagna menu storiche torrefazioni torinesi sul fondo
	sm.box("wood_dark", Vector3(0.0, 2.05, -2.62), Vector3(2.2, 0.92, 0.06))
	sm.box("iron", Vector3(0.0, 2.05, -2.58), Vector3(1.96, 0.74, 0.03))

static func add_bicycle_mesh(sm: StyleMesh, pos: Vector3, rot: float = 0.0) -> void:
	var m := StyleMesh.new()
	var wr := 0.33
	# Ruote ant. (+Z) e post. (-Z) a contatto suolo esatto Y=0.0
	_merge_rotated_x_cyl(m, Vector3(0, wr, -0.54), wr, 0.06, 18, "tire", "steel")
	_merge_rotated_x_cyl(m, Vector3(0, wr, 0.54), wr, 0.06, 18, "tire", "steel")
	# Telaio e-bike in lega ciano/antracite + batteria integrata sul tubo obliquo
	m.capsule_seg("cyan_accent", Vector3(0, wr, -0.54), Vector3(0, 0.84, -0.18), 0.022, 0.024, 8)
	m.capsule_seg("cyan_accent", Vector3(0, 0.36, -0.08), Vector3(0, 0.86, -0.20), 0.026, 0.024, 8)
	m.capsule_seg("cyan_accent", Vector3(0, 0.36, -0.08), Vector3(0, wr, -0.54), 0.018, 0.016, 8)
	m.capsule_seg("iron_dark", Vector3(0, 0.38, -0.06), Vector3(0, 0.84, 0.32), 0.036, 0.034, 8)
	m.capsule_seg("cyan_accent", Vector3(0, 0.82, -0.19), Vector3(0, 0.85, 0.31), 0.022, 0.024, 8)
	# Forcella anteriore & cannotto sterzo
	m.capsule_seg("iron_dark", Vector3(-0.045, wr, 0.54), Vector3(0, 0.88, 0.31), 0.016, 0.020, 8)
	m.capsule_seg("iron_dark", Vector3(0.045, wr, 0.54), Vector3(0, 0.88, 0.31), 0.016, 0.020, 8)
	m.capsule_seg("steel", Vector3(0, 0.86, 0.31), Vector3(0, 1.04, 0.25), 0.020, 0.018, 8)
	# Manubrio ricurvo, manopole, display LED centrale e faro anteriore
	m.capsule_seg("steel", Vector3(-0.27, 1.05, 0.19), Vector3(0.0, 1.06, 0.26), 0.016, 0.018, 8)
	m.capsule_seg("steel", Vector3(0.27, 1.05, 0.19), Vector3(0.0, 1.06, 0.26), 0.016, 0.018, 8)
	m.box("iron_dark", Vector3(-0.25, 1.05, 0.19), Vector3(0.11, 0.036, 0.036), {"rot": -0.25})
	m.box("iron_dark", Vector3(0.25, 1.05, 0.19), Vector3(0.11, 0.036, 0.036), {"rot": 0.25})
	m.box("cyan_accent", Vector3(0, 1.09, 0.27), Vector3(0.10, 0.035, 0.06))
	m.box("lamp_glow", Vector3(0, 0.78, 0.42), Vector3(0.06, 0.06, 0.06))
	# Sella ergonomica, guarnitura/pedali, cavalletto & fanalino rosso
	m.box("iron_dark", Vector3(0, 0.90, -0.21), Vector3(0.15, 0.055, 0.25))
	m.cyl("iron_dark", Vector3(0, 0.36, -0.08), 0.09, 0.09, 0.04, 12)
	m.capsule_seg("iron_dark", Vector3(-0.08, 0.30, -0.14), Vector3(-0.18, 0.02, -0.22), 0.014, 0.012, 6)
	m.box("fabric_red", Vector3(0, 0.66, -0.70), Vector3(0.06, 0.05, 0.05))
	_merge_transformed(sm, m, pos, rot)

static func add_bicycle_cockpit(parent: Node3D) -> Node3D:
	# Cockpit in prima persona montato davanti al giocatore durante la guida (verso -Z)
	var root := Node3D.new()
	root.name = "BikeCockpit"
	root.visible = false
	parent.add_child(root)

	var frame_sm := StyleMesh.new()
	frame_sm.capsule_seg("cyan_accent", Vector3(0, 0.68, 0.02), Vector3(0, 0.96, -0.38), 0.025, 0.025, 8)
	frame_sm.capsule_seg("iron_dark", Vector3(0, 0.50, -0.02), Vector3(0, 0.92, -0.38), 0.038, 0.034, 8)
	var frame_mi := MeshInstance3D.new()
	frame_mi.name = "FrameStub"
	frame_mi.mesh = frame_sm.to_mesh(Callable(VillageMaterials, "mat"))
	frame_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(frame_mi)

	var steer_pivot := Node3D.new()
	steer_pivot.name = "HandlebarPivot"
	steer_pivot.position = Vector3(0.0, 1.06, -0.42)
	root.add_child(steer_pivot)

	var hsm := StyleMesh.new()
	hsm.capsule_seg("steel", Vector3(0, -0.14, 0.02), Vector3(0, 0.14, 0.0), 0.020, 0.020, 8)
	hsm.capsule_seg("steel", Vector3(-0.30, 0.14, 0.05), Vector3(0.0, 0.15, -0.02), 0.016, 0.018, 8)
	hsm.capsule_seg("steel", Vector3(0.30, 0.14, 0.05), Vector3(0.0, 0.15, -0.02), 0.016, 0.018, 8)
	hsm.box("iron_dark", Vector3(-0.27, 0.14, 0.045), Vector3(0.13, 0.038, 0.038), {"rot": 0.20})
	hsm.box("iron_dark", Vector3(0.27, 0.14, 0.045), Vector3(0.13, 0.038, 0.038), {"rot": -0.20})
	hsm.box("steel", Vector3(-0.22, 0.125, -0.01), Vector3(0.10, 0.014, 0.024), {"rot": 0.15})
	hsm.box("steel", Vector3(0.22, 0.125, -0.01), Vector3(0.10, 0.014, 0.024), {"rot": -0.15})
	# Display LCD e-bike centrale & faro anteriore + bracci forcella
	hsm.box("iron_dark", Vector3(0, 0.175, -0.01), Vector3(0.11, 0.025, 0.07))
	hsm.box("cyan_accent", Vector3(0, 0.190, -0.01), Vector3(0.085, 0.008, 0.045))
	hsm.box("lamp_glow", Vector3(0, -0.12, -0.08), Vector3(0.06, 0.06, 0.05))
	hsm.capsule_seg("iron_dark", Vector3(-0.05, -0.10, 0.0), Vector3(-0.05, -0.58, -0.18), 0.016, 0.014, 8)
	hsm.capsule_seg("iron_dark", Vector3(0.05, -0.10, 0.0), Vector3(0.05, -0.58, -0.18), 0.016, 0.014, 8)
	var hmi := MeshInstance3D.new()
	hmi.name = "HandlebarMesh"
	hmi.mesh = hsm.to_mesh(Callable(VillageMaterials, "mat"))
	hmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	steer_pivot.add_child(hmi)

	var fw_pivot := Node3D.new()
	fw_pivot.name = "FrontWheelPivot"
	fw_pivot.position = Vector3(0.0, -0.58, -0.18)
	steer_pivot.add_child(fw_pivot)
	var wmi := MeshInstance3D.new()
	wmi.name = "FrontWheelMesh"
	wmi.mesh = add_car_wheel_mesh("tire", "steel", 0.33, 0.06)
	wmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	fw_pivot.add_child(wmi)

	return root

# ------------------------------------------------------------------ Helper transform merge
static func _merge_transformed(dst: StyleMesh, src: StyleMesh, pos: Vector3, rot: float) -> void:
	for key in src._surf:
		var s_src: Dictionary = src._surf[key]
		var s_dst: Dictionary = dst._s(key)
		var base: int = s_dst["v"].size()
		var sv: PackedVector3Array = s_src["v"]
		var sn: PackedVector3Array = s_src["n"]
		var suv: PackedVector2Array = s_src["uv"]
		var si: PackedInt32Array = s_src["i"]
		for k in range(sv.size()):
			var v := sv[k]
			var n := sn[k]
			if rot != 0.0:
				v = v.rotated(Vector3.UP, rot)
				n = n.rotated(Vector3.UP, rot)
			s_dst["v"].append(v + pos)
			s_dst["n"].append(n)
			s_dst["uv"].append(suv[k])
		for idx in si:
			s_dst["i"].append(base + idx)
	for c in src.colliders:
		var cp: Vector3 = c["pos"]
		if rot != 0.0:
			cp = cp.rotated(Vector3.UP, rot)
		var nc: Dictionary = c.duplicate()
		nc["pos"] = cp + pos
		nc["rot"] = float(c.get("rot", 0.0)) + rot
		dst.colliders.append(nc)
