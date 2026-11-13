class_name VillageProps
extends RefCounted
## VillageProps - Costruttori modulari StyleMesh per il Borgo San Carlo.
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
	# Soffitto interno con travi
	sm.box("plaster_cream", Vector3(cx, h + 0.08, cz), Vector3(iw + wt * 2.0, 0.16, id + wt * 2.0), {"col": true})
	for bx in [-2.3, 0.0, 2.3]:
		sm.box("wood_dark", Vector3(bx, h - 0.08, cz), Vector3(0.18, 0.16, id - 0.1))
	# Pareti (retro Z=-3.3, sinistra X=-3.7, destra X=+3.7)
	sm.box("plaster_studio", Vector3(0, h * 0.5, -3.3 - wt * 0.5), Vector3(iw + wt * 2.0, h, wt), {"col": true})
	sm.box("plaster_studio", Vector3(-3.7 - wt * 0.5, h * 0.5, cz), Vector3(wt, h, id), {"col": true})
	sm.box("plaster_studio", Vector3(3.7 + wt * 0.5, h * 0.5, cz), Vector3(wt, h, id), {"col": true})
	# Parete frontale (+Z = 2.5) con porta aperta X:[-0.9, 0.9], alta 2.35m
	sm.box("plaster_studio", Vector3(-2.42, h * 0.5, 2.5 + wt * 0.5), Vector3(3.04, h, wt), {"col": true})
	sm.box("plaster_studio", Vector3(2.42, h * 0.5, 2.5 + wt * 0.5), Vector3(3.04, h, wt), {"col": true})
	sm.box("plaster_studio", Vector3(0, 2.35 + (h - 2.35) * 0.5, 2.5 + wt * 0.5), Vector3(1.8, h - 2.35, wt), {"col": true})
	# Stipiti porta in legno + soglia
	sm.box("wood_dark", Vector3(-0.94, 1.175, 2.5 + wt * 0.5), Vector3(0.08, 2.35, wt + 0.06))
	sm.box("wood_dark", Vector3(0.94, 1.175, 2.5 + wt * 0.5), Vector3(0.08, 2.35, wt + 0.06))
	sm.box("wood_dark", Vector3(0, 2.38, 2.5 + wt * 0.5), Vector3(1.96, 0.1, wt + 0.06))
	sm.box("stone_trim", Vector3(0, 0.02, 2.5 + wt * 0.5), Vector3(1.9, 0.04, wt + 0.12))
	# Battiscopa interno
	sm.box("wood_dark", Vector3(0, 0.06, -3.27), Vector3(iw - 0.04, 0.12, 0.04))
	sm.box("wood_dark", Vector3(-3.67, 0.06, cz), Vector3(0.04, 0.12, id - 0.04))
	sm.box("wood_dark", Vector3(3.67, 0.06, cz), Vector3(0.04, 0.12, id - 0.04))
	# Finestra luminosa con traversini sul lato ovest (tra armadio NW e frigo SW, centrata a Z=-0.45)
	sm.box("wood_dark", Vector3(-3.72, 1.55, -0.45), Vector3(0.32, 1.18, 1.38))
	sm.box("glass_cool", Vector3(-3.72, 1.55, -0.45), Vector3(0.34, 1.04, 1.24))
	sm.box("wood_dark", Vector3(-3.72, 1.55, -0.45), Vector3(0.36, 0.05, 1.24))
	sm.box("wood_dark", Vector3(-3.72, 1.55, -0.45), Vector3(0.36, 1.04, 0.05))
	# Rivestimento esterno e zoccolo in pietra + tetto a capanna
	sm.box("ashlar", Vector3(0, 0.28, -3.3 - wt - 0.02), Vector3(iw + 0.6, 0.56, 0.06))
	sm.box("ashlar", Vector3(-3.7 - wt - 0.02, 0.28, cz), Vector3(0.06, 0.56, id + 0.5))
	sm.box("ashlar", Vector3(3.7 + wt + 0.02, 0.28, cz), Vector3(0.06, 0.56, id + 0.5))
	sm.box("ashlar", Vector3(-2.42, 0.28, 2.5 + wt + 0.02), Vector3(3.04, 0.56, 0.06))
	sm.box("ashlar", Vector3(2.42, 0.28, 2.5 + wt + 0.02), Vector3(3.04, 0.56, 0.06))
	# Facciata esterna calda + tenda sopra l'ingresso + tetto
	sm.box("plaster_ochre", Vector3(0, h * 0.5 + 0.28, 2.5 + wt + 0.015), Vector3(iw + 0.5, 0.45, 0.04))
	sm.box("awning_blue", Vector3(0, 2.58, 3.15), Vector3(2.6, 0.16, 0.95), {"rot": 0.0})
	sm.gable("roof_terracotta", "plaster_ochre", Vector3(0, h + 0.16, cz), iw + 1.0, id + 1.0, 1.75, true)
	# Comignolo
	sm.box("brick", Vector3(2.4, h + 1.2, -1.7), Vector3(0.45, 1.1, 0.45))
	sm.box("stone_trim", Vector3(2.4, h + 1.77, -1.7), Vector3(0.55, 0.08, 0.55))

# ------------------------------------------------------------------ Letto & Frigo nello Studio
static func add_bed(sm: StyleMesh, pos: Vector3, rot: float = 0.0) -> void:
	# Letto compatto 0.95 x 1.85m
	var m := StyleMesh.new()
	m.box("wood_dark", Vector3(0, 0.18, 0), Vector3(0.95, 0.12, 1.85), {"col": true})
	for lx in [-0.42, 0.42]:
		for lz in [-0.86, 0.86]:
			m.box("wood_dark", Vector3(lx, 0.06, lz), Vector3(0.08, 0.12, 0.08))
	m.box("wood_dark", Vector3(0, 0.48, -0.88), Vector3(0.95, 0.52, 0.08))
	m.box("white", Vector3(0, 0.30, 0.02), Vector3(0.88, 0.14, 1.74))
	m.box("fabric_blue", Vector3(0, 0.32, 0.25), Vector3(0.90, 0.14, 1.24))
	m.box("white", Vector3(0, 0.40, -0.62), Vector3(0.56, 0.10, 0.34))
	_merge_transformed(sm, m, pos, rot)

static func add_fridge(sm: StyleMesh, pos: Vector3, rot: float = 0.0) -> void:
	var m := StyleMesh.new()
	m.box("white", Vector3(0, 0.72, 0), Vector3(0.68, 1.44, 0.64), {"col": true})
	m.box("steel", Vector3(0, 0.92, 0.325), Vector3(0.62, 0.03, 0.02))
	m.box("steel", Vector3(-0.24, 1.15, 0.335), Vector3(0.04, 0.26, 0.03))
	m.box("steel", Vector3(-0.24, 0.60, 0.335), Vector3(0.04, 0.22, 0.03))
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
	# Cornicione sottotetto
	m.box("stone_trim", Vector3(0, h + 0.07, 0), Vector3(w + 0.22, 0.14, d + 0.22))
	# Tetto a capanna
	m.gable(roof_key, wall_key, Vector3(0, h + 0.14, 0), w + 0.45, d + 0.45, 1.55, w >= d)
	# Comignolo
	m.box("brick", Vector3(w * 0.25, h + 1.0, -d * 0.18), Vector3(0.42, 1.0, 0.42))
	# Porta frontale (+Z)
	m.box("wood_dark", Vector3(0, 1.05, d * 0.5 + 0.03), Vector3(1.08, 2.1, 0.08))
	m.box("stone_trim", Vector3(0, 2.16, d * 0.5 + 0.05), Vector3(1.28, 0.14, 0.10))
	# Finestre su ogni piano
	var cols: int = clampi(int(floor(w / 2.6)), 1, 3)
	for f in range(floors):
		var wy := 1.45 + float(f) * 2.75
		for ci in range(cols):
			var wx := (float(ci) - float(cols - 1) * 0.5) * 2.3
			if f == 0 and absf(wx) < 0.9:
				continue
			_add_window(m, Vector3(wx, wy, d * 0.5), 0.0, shutter_key)
			_add_window(m, Vector3(wx, wy, -d * 0.5), PI, shutter_key)
	_merge_transformed(sm, m, center, rot)

static func _add_window(m: StyleMesh, pos: Vector3, rot: float, shutter_key: String) -> void:
	var wm := StyleMesh.new()
	wm.box("wood_dark", Vector3(0, 0, 0.02), Vector3(0.92, 1.14, 0.06))
	wm.box("glass_warm", Vector3(0, 0, 0.04), Vector3(0.78, 0.98, 0.03))
	wm.box("stone_trim", Vector3(0, -0.60, 0.08), Vector3(1.06, 0.10, 0.16))
	wm.box(shutter_key, Vector3(-0.62, 0, 0.05), Vector3(0.28, 1.10, 0.05))
	wm.box(shutter_key, Vector3(0.62, 0, 0.05), Vector3(0.28, 1.10, 0.05))
	_merge_transformed(m, wm, pos, rot)

# ------------------------------------------------------------------ Bottega / Negozio accessibile (+Z fronte)
## Costruisce un negozio accessibile con interno, bancone, insegna, tenda e piano superiore.
static func add_shop_building(sm: StyleMesh, center: Vector3, w: float, d: float, opts: Dictionary = {}) -> void:
	var wall_key: String = opts.get("wall", "plaster_terracotta")
	var floor_key: String = opts.get("floor", "tile_rc")
	var awning_key: String = opts.get("awning", "awning_red")
	var roof_key: String = opts.get("roof", "roof_terracotta")
	var rot: float = float(opts.get("rot", 0.0))
	var h := 3.2
	var upper_h := 2.4
	var wt := 0.24
	var door_w := minf(2.2, w * 0.42)
	var side_w := (w - door_w) * 0.5

	var m := StyleMesh.new()
	# Pavimento interno (top a Y=0.04 così non clippa con strada Y=0, con rampa/soglia dolce)
	m.box(floor_key, Vector3(0, 0.02, 0), Vector3(w, 0.04, d), {"col": true, "surface": "tile"})
	# Soffitto bottega
	m.box("plaster_cream", Vector3(0, h + 0.06, 0), Vector3(w, 0.12, d), {"col": true})
	# Parete posteriore & laterali
	m.box(wall_key, Vector3(0, h * 0.5, -d * 0.5 + wt * 0.5), Vector3(w, h, wt), {"col": true})
	m.box(wall_key, Vector3(-w * 0.5 + wt * 0.5, h * 0.5, 0), Vector3(wt, h, d - wt), {"col": true})
	m.box(wall_key, Vector3(w * 0.5 - wt * 0.5, h * 0.5, 0), Vector3(wt, h, d - wt), {"col": true})
	# Parete frontale (+Z) con ampia apertura porta
	if side_w > 0.2:
		m.box(wall_key, Vector3(-w * 0.5 + side_w * 0.5, h * 0.5, d * 0.5 - wt * 0.5), Vector3(side_w, h, wt), {"col": true})
		m.box(wall_key, Vector3(w * 0.5 - side_w * 0.5, h * 0.5, d * 0.5 - wt * 0.5), Vector3(side_w, h, wt), {"col": true})
		# Vetrine laterali
		for sx in [-w * 0.5 + side_w * 0.5, w * 0.5 - side_w * 0.5]:
			m.box("wood_dark", Vector3(sx, 1.35, d * 0.5 + 0.02), Vector3(minf(1.4, side_w * 0.72), 1.35, 0.06))
			m.box("glass_warm", Vector3(sx, 1.35, d * 0.5 + 0.04), Vector3(minf(1.25, side_w * 0.64), 1.20, 0.03))
	m.box(wall_key, Vector3(0, 2.45 + (h - 2.45) * 0.5, d * 0.5 - wt * 0.5), Vector3(door_w, h - 2.45, wt), {"col": true})
	# Zoccolo pietra esterno
	m.box("ashlar", Vector3(-w * 0.5 - 0.02, 0.28, 0), Vector3(0.05, 0.56, d + 0.06))
	m.box("ashlar", Vector3(w * 0.5 + 0.02, 0.28, 0), Vector3(0.05, 0.56, d + 0.06))
	# Tenda da sole sporgente + tavola insegna
	m.box(awning_key, Vector3(0, 2.75, d * 0.5 + 0.58), Vector3(w * 0.82, 0.16, 1.15))
	m.box("wood_dark", Vector3(0, 3.12, d * 0.5 + 0.08), Vector3(w * 0.65, 0.42, 0.10))
	# Bancone interno sul fondo (alto 0.93m) + pedana rialzata per il negoziante (top Y=0.18)
	m.box("wood_dark", Vector3(0, 0.46, -d * 0.18), Vector3(w * 0.62, 0.84, 0.75), {"col": true})
	m.box("stone_trim", Vector3(0, 0.905, -d * 0.18), Vector3(w * 0.66, 0.06, 0.82))
	m.box("wood_light", Vector3(0, 0.11, -d * 0.18 - 0.82), Vector3(w * 0.54, 0.14, 0.95), {"col": true, "surface": "wood"})
	# Piano superiore abitativo + tetto a capanna
	var y_up := h + 0.12
	m.box(wall_key, Vector3(0, y_up + upper_h * 0.5, 0), Vector3(w, upper_h, d), {"col": true})
	m.box("stone_trim", Vector3(0, y_up + upper_h + 0.06, 0), Vector3(w + 0.20, 0.12, d + 0.20))
	var cols: int = clampi(int(floor(w / 2.6)), 1, 3)
	for ci in range(cols):
		var wx := (float(ci) - float(cols - 1) * 0.5) * 2.4
		_add_window(m, Vector3(wx, y_up + 1.25, d * 0.5), 0.0, "fabric_green")
	m.gable(roof_key, wall_key, Vector3(0, y_up + upper_h + 0.12, 0), w + 0.45, d + 0.45, 1.45, w >= d)
	_merge_transformed(sm, m, center, rot)

# ------------------------------------------------------------------ Edicola Sabrina
static func add_edicola(sm: StyleMesh, pos: Vector3, rot: float = 0.0) -> void:
	var m := StyleMesh.new()
	m.box("ashlar", Vector3(0, 0.12, 0), Vector3(2.8, 0.24, 2.2), {"col": true, "surface": "stone"})
	# Fondo, pareti laterali e muretto inferiore così lo sportello frontale è aperto (Sabrina visibile!)
	m.box("plaster_sky", Vector3(0, 1.35, -0.78), Vector3(2.5, 2.25, 0.28), {"col": true})
	m.box("plaster_sky", Vector3(-1.12, 1.35, 0.05), Vector3(0.26, 2.25, 1.75), {"col": true})
	m.box("plaster_sky", Vector3(1.12, 1.35, 0.05), Vector3(0.26, 2.25, 1.75), {"col": true})
	m.box("plaster_sky", Vector3(0, 0.62, 0.84), Vector3(2.0, 0.78, 0.20), {"col": true})
	m.box("plaster_sky", Vector3(0, 2.26, 0.84), Vector3(2.0, 0.44, 0.20), {"col": true})
	m.box("wood_dark", Vector3(0, 1.02, 0.96), Vector3(2.1, 0.10, 0.40))
	m.box("glass_cool", Vector3(0, 1.98, 0.90), Vector3(1.96, 0.22, 0.04))
	# Riviste colorate sul banco
	for i in range(4):
		var k: String = ["fabric_red", "fabric_blue", "awning_yellow", "fabric_green"][i]
		m.box(k, Vector3(-0.68 + float(i) * 0.45, 1.11, 1.04), Vector3(0.32, 0.08, 0.24))
	m.box("awning_blue", Vector3(0, 2.38, 1.25), Vector3(2.7, 0.14, 0.85))
	m.box("wood_dark", Vector3(0, 2.40, 1.69), Vector3(2.25, 0.28, 0.06))
	m.hip_roof("roof_slate", Vector3(0, 2.48, 0), 3.1, 2.5, 0.85)
	_merge_transformed(sm, m, pos, rot)

# ------------------------------------------------------------------ Fontana del Borgo
static func add_fountain(sm: StyleMesh, pos: Vector3) -> void:
	# Vasca ottagonale con collisione cilindrica
	sm.cyl("stone_trim", pos, 2.15, 2.22, 0.58, 8, {"smooth": false})
	sm.cyl("water", pos + Vector3(0, 0.42, 0), 1.88, 1.88, 0.06, 8, {"smooth": true})
	sm.cyl("stone_trim", pos + Vector3(0, 0.45, 0), 0.52, 0.42, 0.85, 8, {"smooth": false})
	sm.cyl("stone_trim", pos + Vector3(0, 1.25, 0), 0.88, 0.96, 0.18, 8, {"smooth": false})
	sm.cyl("water", pos + Vector3(0, 1.40, 0), 0.72, 0.72, 0.05, 8, {"smooth": true})
	sm.cyl("stone_trim", pos + Vector3(0, 1.42, 0), 0.22, 0.14, 0.55, 8, {"smooth": false})
	sm.cyl("water", pos + Vector3(0, 1.92, 0), 0.10, 0.24, 0.35, 8, {"smooth": true})
	sm.add_collider_cyl(pos + Vector3(0, 0.55, 0), 2.25, 1.1)

# ------------------------------------------------------------------ Natura & Arredo Urbano
static func add_tree(sm: StyleMesh, pos: Vector3, seed_val: int = 1, s: float = 1.0) -> void:
	sm.cyl("bark", pos, 0.24 * s, 0.14 * s, 2.0 * s, 7)
	sm.blob("leaves", pos + Vector3(0, 2.75 * s, 0), Vector3(1.35, 1.15, 1.35) * s, 5, 9, 0.14, seed_val)
	sm.blob("leaves_dark", pos + Vector3(0.55 * s, 2.25 * s, 0.35 * s), Vector3(0.85, 0.75, 0.85) * s, 4, 8, 0.12, seed_val + 7)
	sm.blob("leaves", pos + Vector3(-0.5 * s, 2.35 * s, -0.3 * s), Vector3(0.90, 0.78, 0.90) * s, 4, 8, 0.12, seed_val + 13)
	sm.add_collider_cyl(pos + Vector3(0, 1.1 * s, 0), 0.40 * s, 2.2 * s)

static func add_bush(sm: StyleMesh, pos: Vector3, seed_val: int = 2, s: float = 1.0) -> void:
	sm.blob("leaves_dark", pos + Vector3(0, 0.42 * s, 0), Vector3(0.65, 0.46, 0.65) * s, 4, 8, 0.15, seed_val)
	sm.add_collider_cyl(pos + Vector3(0, 0.42 * s, 0), 0.55 * s, 0.85 * s)

static func add_bench(sm: StyleMesh, pos: Vector3, rot: float = 0.0) -> void:
	var m := StyleMesh.new()
	m.box("wood_light", Vector3(0, 0.42, 0), Vector3(1.65, 0.08, 0.52), {"col": true})
	m.box("wood_light", Vector3(0, 0.78, -0.22), Vector3(1.65, 0.36, 0.07))
	m.box("iron", Vector3(-0.72, 0.24, 0), Vector3(0.08, 0.48, 0.50))
	m.box("iron", Vector3(0.72, 0.24, 0), Vector3(0.08, 0.48, 0.50))
	_merge_transformed(sm, m, pos, rot)

static func add_lamp(sm: StyleMesh, pos: Vector3) -> void:
	sm.cyl("iron", pos, 0.16, 0.11, 0.45, 8)
	sm.cyl("iron", pos + Vector3(0, 0.45, 0), 0.07, 0.05, 2.85, 8)
	sm.box("lamp_glow", pos + Vector3(0, 3.48, 0), Vector3(0.32, 0.38, 0.32))
	sm.hip_roof("iron", pos + Vector3(0, 3.67, 0), 0.44, 0.44, 0.20)
	sm.add_collider_cyl(pos + Vector3(0, 1.5, 0), 0.18, 3.0)

static func add_table_set(sm: StyleMesh, pos: Vector3, cloth_key: String = "fabric_red") -> void:
	sm.cyl("iron", pos, 0.28, 0.06, 0.72, 8)
	sm.cyl(cloth_key, pos + Vector3(0, 0.72, 0), 0.52, 0.52, 0.07, 10)
	sm.add_collider_cyl(pos + Vector3(0, 0.4, 0), 0.52, 0.8)
	for sx in [-0.72, 0.72]:
		sm.box("wood_dark", pos + Vector3(sx, 0.42, 0), Vector3(0.38, 0.06, 0.38))
		sm.box("wood_dark", pos + Vector3(sx + signf(sx) * 0.16, 0.66, 0), Vector3(0.06, 0.48, 0.38))
		sm.box("iron", pos + Vector3(sx, 0.21, 0), Vector3(0.32, 0.42, 0.32))

# ------------------------------------------------------------------ Auto stilizzata (ruote esatte a Y=0)
static func add_car(sm: StyleMesh, pos: Vector3, rot: float = 0.0, color_key: String = "car_red") -> void:
	var m := StyleMesh.new()
	# Ruote r=0.28 -> centro a Y=0.28 (toccano Y=0 esatto!)
	for wx in [-0.78, 0.78]:
		for wz in [-1.05, 1.05]:
			m.box("tire", Vector3(wx, 0.28, wz), Vector3(0.22, 0.56, 0.56))
	# Scocca inferiore + cabina
	m.box(color_key, Vector3(0, 0.58, 0), Vector3(1.62, 0.56, 3.35), {"col": true})
	m.box(color_key, Vector3(0, 1.08, -0.15), Vector3(1.38, 0.48, 1.75))
	m.box("glass_cool", Vector3(0, 1.08, -0.15), Vector3(1.41, 0.36, 1.48))
	m.box("steel", Vector3(0, 0.36, 1.70), Vector3(1.56, 0.14, 0.10))
	m.box("steel", Vector3(0, 0.36, -1.70), Vector3(1.56, 0.14, 0.10))
	m.box("lamp_glow", Vector3(-0.56, 0.62, 1.69), Vector3(0.24, 0.14, 0.04))
	m.box("lamp_glow", Vector3(0.56, 0.62, 1.69), Vector3(0.24, 0.14, 0.04))
	_merge_transformed(sm, m, pos, rot)

# ------------------------------------------------------------------ NPC stilizzati unificati (scolpiti)
static func add_npc_model(parent: Node3D, opts: Dictionary = {}) -> Node3D:
	return VillageCharacters.build(parent, opts)

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
