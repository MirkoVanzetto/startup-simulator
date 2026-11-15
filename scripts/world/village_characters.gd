class_name VillageCharacters
extends RefCounted
## VillageCharacters - Costruttore di personaggi 3D semi-realistici anatomici e sartoriali (Torino v1.4).
## Preserva gerarchia esatta (BodyMesh, HeadPivot, ArmLPivot, ArmRPivot, AnimationPlayer).

static func build(parent: Node3D, opts: Dictionary = {}) -> Node3D:
	var root := Node3D.new()
	root.name = "Model"
	parent.add_child(root)

	if opts.get("seated", false):
		_build_seated_character(root, opts)
	else:
		_build_standing_character(root, opts)
	return root

# ------------------------------------------------------------------ PERSONAGGI IN PIEDI
static func _build_standing_character(root: Node3D, opts: Dictionary) -> void:
	var shirt: String = opts.get("shirt", "fabric_blue")
	var pants: String = opts.get("pants", "denim")
	var apron: String = opts.get("apron", "")
	var vest: String = opts.get("vest", "")
	var female: bool = bool(opts.get("female", false))
	var shoe_key: String = opts.get("shoes", "leather")
	var tie_key: String = opts.get("tie", "")
	var skirt: bool = bool(opts.get("skirt", false))
	var skin_k: String = opts.get("skin", "skin")
	var belt_buckle := "brass"

	var body := StyleMesh.new()

	# 1. Calzature anatomiche con guardolo suola, contrafforte tallone e lacci incrociati (base esatta Y=0)
	var foot_offset := 0.104 if female else 0.112
	for side in [-1.0, 1.0]:
		var sx: float = side * foot_offset
		var foot_yaw: float = -side * 0.06
		# Suola sottile sagomata + guardolo
		body.ellipsoid("sneaker_white" if shoe_key != "leather" else "iron", Vector3(sx, 0.017, 0.036), Vector3(0.056, 0.017, 0.128), 6, 16, Vector3(0, foot_yaw, 0))
		# Tomaia sagomata + punta + contrafforte tallone
		body.ellipsoid(shoe_key, Vector3(sx, 0.044, 0.030), Vector3(0.053, 0.034, 0.118), 7, 16, Vector3(0, foot_yaw, 0))
		body.cyl(shoe_key, Vector3(sx, 0.034, -0.024), 0.044, 0.041, 0.062, 14)
		# Linguetta + 2 coppie di lacci incrociati sul collo del piede
		body.ellipsoid(shoe_key, Vector3(sx, 0.068, 0.044), Vector3(0.034, 0.014, 0.044), 5, 10, Vector3(-0.26, foot_yaw, 0))
		for lz in [0.036, 0.066]:
			body.capsule_seg("white" if shoe_key != "leather" else "skin_warm",
				Vector3(sx - 0.022, 0.072, lz), Vector3(sx + 0.022, 0.072, lz + 0.014), 0.004, 0.004, 6)
			body.capsule_seg("white" if shoe_key != "leather" else "skin_warm",
				Vector3(sx + 0.022, 0.072, lz), Vector3(sx - 0.022, 0.072, lz + 0.014), 0.004, 0.004, 6)

	# 2. Gambe con anatomia reale (caviglia fine -> ventre polpaccio -> ginocchio -> coscia affusolata)
	var calf_k := skin_k if skirt else pants
	for side in [-1.0, 1.0]:
		var sx: float = side * (0.098 if female else 0.106)
		var ankle := Vector3(sx, 0.090, -0.014)
		var mid_calf := Vector3(sx, 0.285, -0.018)
		var knee := Vector3(sx, 0.455, 0.010)
		var mid_thigh := Vector3(sx * 0.94, 0.635, 0.004)
		var hip := Vector3(sx * 0.88, 0.815, 0.0)
		body.capsule_seg(calf_k, ankle, mid_calf, 0.038 if female else 0.044, 0.056 if female else 0.064, 16)
		body.capsule_seg(calf_k, mid_calf, knee, 0.056 if female else 0.064, 0.052 if female else 0.058, 16)
		body.capsule_seg(pants, knee, mid_thigh, 0.055 if female else 0.061, 0.072 if female else 0.080, 16)
		body.capsule_seg(pants, mid_thigh, hip, 0.072 if female else 0.080, 0.078 if female else 0.086, 16)
		if not skirt:
			# Orlo risvolto sul fondo pantalone
			body.cyl(pants, Vector3(sx, 0.096, -0.012), 0.052, 0.052, 0.026, 14)

	# 3. Bacino / Gonna sartoriale
	if skirt:
		body.lathe_oval(pants, Vector3(0, 0.46, 0), [
			Vector2(0.004, 0.0), Vector2(0.194, 0.015), Vector2(0.184, 0.12),
			Vector2(0.168, 0.24), Vector2(0.136, 0.365)
		], 1.12, 0.78, 24)
	else:
		body.ellipsoid(pants, Vector3(0, 0.805, 0.0), Vector3(0.168, 0.100, 0.114), 9, 20)

	# 4. Busto anatomico continuo: fianchi -> vita stretta -> torace -> pettorali -> trapezi/clavicole
	var waist_r := 0.122 if female else 0.144
	var chest_r := 0.156 if female else 0.174
	var sh_top_r := 0.146 if female else 0.168
	var torso_prof := [
		Vector2(0.146, 0.00),
		Vector2(waist_r, 0.11),
		Vector2(waist_r * 1.07, 0.21),
		Vector2(chest_r, 0.34),
		Vector2(sh_top_r, 0.43),
		Vector2(0.108, 0.48),
		Vector2(0.068, 0.525),
	]
	body.lathe_oval(shirt, Vector3(0, 0.805, 0), torso_prof, 1.16, 0.74, 24)

	# Modellazione discreta spalle & petto per continuità con i deltoidi
	var sh_cap_rad := Vector3(0.056, 0.044, 0.060) if vest != "" else Vector3(0.068, 0.058, 0.072)
	for side in [-1.0, 1.0]:
		body.ellipsoid(shirt, Vector3(side * (0.145 if female else 0.162), 1.195, -0.004), sh_cap_rad, 8, 14)
	if female:
		body.ellipsoid(shirt, Vector3(0, 1.115, 0.072), Vector3(0.134, 0.056, 0.058), 7, 14)

	# Placca bottoni frontale (solo camicia senza grembiule né gilet)
	if apron == "" and vest == "":
		body.capsule_seg(shirt, Vector3(0, 0.86, 0.118), Vector3(0, 1.24, 0.112), 0.012, 0.011, 8)
		for by in [0.95, 1.06, 1.16]:
			body.ellipsoid("white", Vector3(0.0, by, 0.128), Vector3(0.007, 0.007, 0.004), 4, 8)

	# 5. Gilet / Giacca sartoriale centrata con margine radiale completo, scollo a V, revers e badge
	if vest != "":
		var vy0 := 0.838
		var v_waist := waist_r + 0.022
		var v_chest := chest_r + 0.022
		var v_sh := sh_top_r + 0.020
		var v_top := 0.146 if female else 0.164
		body.lathe_oval(vest, Vector3(0, vy0, 0.0), [
			Vector2(0.165, 0.000),
			Vector2(v_waist, 0.082),
			Vector2(v_waist + 0.010, 0.180),
			Vector2(v_chest, 0.307),
			Vector2(v_sh, 0.397),
			Vector2(v_top, 0.424),
			Vector2(0.106, 0.436),
		], 1.18, 0.79, 24)
		# Inserto camicia nello scollo a V frontale + bottoni inferiori + revers sartoriali orgogliosi
		body.ellipsoid(shirt, Vector3(0.0, 1.186, 0.131), Vector3(0.056, 0.070, 0.024), 6, 12, Vector3(-0.26, 0.0, 0.0))
		for by in [0.875, 0.945, 1.015]:
			body.ellipsoid("iron", Vector3(0.0, by, 0.140), Vector3(0.008, 0.008, 0.005), 4, 8)
		for side in [-1.0, 1.0]:
			var l0 := Vector3(side * 0.016, 1.072, 0.150)
			var l1 := Vector3(side * 0.044, 1.168, 0.155)
			var l2 := Vector3(side * 0.068, 1.254, 0.132)
			body.capsule_seg(vest, l0, l1, 0.016, 0.018, 10)
			body.capsule_seg(vest, l1, l2, 0.018, 0.014, 10)
		# Badge ID portanome sul petto destro
		body.box("white", Vector3(0.095, 1.140, 0.146), Vector3(0.048, 0.032, 0.008), {"rot": -0.24})
		body.box("cyan_accent", Vector3(0.095, 1.148, 0.151), Vector3(0.042, 0.008, 0.003), {"rot": -0.24})

	# Cintura in pelle & fibbia in ottone (posizionata esattamente sotto l'orlo del gilet)
	if apron == "":
		body.lathe_oval("leather", Vector3(0, 0.804, 0), [
			Vector2(0.164, 0.0), Vector2(0.164, 0.036)
		], 1.18, 0.78, 22)
		body.box(belt_buckle, Vector3(0, 0.822, 0.130), Vector3(0.046, 0.032, 0.014))

	# 6. Colletto sartoriale morbido + cravatta opzionale
	body.lathe_oval("apron_white", Vector3(0, 1.272, 0.008), [
		Vector2(0.126, 0.0), Vector2(0.072, 0.046)
	], 1.04, 0.92, 20)
	for side in [-1.0, 1.0]:
		body.capsule_seg("apron_white", Vector3(side * 0.016, 1.256, 0.106), Vector3(side * 0.056, 1.278, 0.066), 0.015, 0.012, 8)
	if tie_key != "":
		var tz_top := 0.146 if vest != "" else 0.126
		var tz_mid := 0.154 if vest != "" else 0.134
		body.capsule_seg(tie_key, Vector3(0, 1.254, tz_top), Vector3(0, 1.145, tz_mid), 0.016, 0.021, 10)
		body.capsule_seg(tie_key, Vector3(0, 1.145, tz_mid), Vector3(0, 1.005, tz_mid - 0.008), 0.021, 0.024, 10)
		body.ellipsoid(tie_key, Vector3(0, 1.262, tz_top + 0.003), Vector3(0.020, 0.018, 0.013), 5, 10)

	# 7. Grembiule sartoriale con pettorina, bretelle anatomiche curve & fiocco posteriore in vita
	if apron != "":
		var ap_mat := "apron_white" if apron == "white" else apron
		body.lathe_oval(ap_mat, Vector3(0, 0.88, 0.062), [
			Vector2(0.148, 0.0), Vector2(0.154, 0.16), Vector2(0.136, 0.295)
		], 1.04, 0.88, 22)
		for side in [-1.0, 1.0]:
			var sx: float = side * 0.080
			body.capsule_seg(ap_mat, Vector3(sx, 1.168, 0.146), Vector3(sx * 0.98, 1.242, 0.126), 0.012, 0.012, 10)
			body.capsule_seg(ap_mat, Vector3(sx * 0.98, 1.242, 0.126), Vector3(sx * 0.90, 1.300, 0.028), 0.012, 0.012, 10)
			body.capsule_seg(ap_mat, Vector3(sx * 0.90, 1.300, 0.028), Vector3(sx * 0.72, 1.236, -0.098), 0.012, 0.012, 10)
		var bottom_r := 0.214 if skirt else 0.184
		var waist_ap_r := 0.184 if skirt else 0.164
		body.lathe_oval(ap_mat, Vector3(0, 0.54, 0.022), [
			Vector2(bottom_r, 0.0), Vector2(waist_ap_r, 0.18), Vector2(waist_ap_r * 0.96, 0.34)
		], 1.18, 0.84, 24)
		body.lathe_oval(ap_mat, Vector3(0, 0.86, 0.022), [
			Vector2(waist_ap_r * 1.02, 0.0), Vector2(waist_ap_r * 1.02, 0.04)
		], 1.18, 0.84, 20)
		# Nodo e lembi del laccio dietro la schiena
		body.ellipsoid(ap_mat, Vector3(0, 0.875, -0.145), Vector3(0.026, 0.020, 0.018), 5, 10)
		for side in [-1.0, 1.0]:
			body.capsule_seg(ap_mat, Vector3(0, 0.875, -0.148), Vector3(side * 0.036, 0.77, -0.158), 0.009, 0.007, 8)
		var pocket_mat := "fabric_cream" if ap_mat == "apron_white" else "apron_white"
		var pocket_z := 0.194 if skirt else 0.174
		body.ellipsoid(pocket_mat, Vector3(0, 0.72, pocket_z), Vector3(0.068, 0.048, 0.016), 6, 14)

	var body_mi := MeshInstance3D.new()
	body_mi.name = "BodyMesh"
	body_mi.mesh = body.to_mesh(Callable(VillageMaterials, "mat"))
	body_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	root.add_child(body_mi)

	# Pivot Testa al collo (preserva HeadPivot esatto per AnimationPlayer)
	var head_pivot := Node3D.new()
	head_pivot.name = "HeadPivot"
	head_pivot.position = Vector3(0, 1.28, 0)
	root.add_child(head_pivot)
	_build_head(head_pivot, opts, Vector3.ZERO)

	# 8. Braccia articolate con spalla deltoidea, gomito affusolato & mano a 5 dita
	var sleeve: String = opts.get("sleeve", shirt)
	var rolled := bool(opts.get("rolled_sleeves", false))
	var forearm_mat := skin_k if rolled else sleeve
	var sh_x := 0.156 if female else 0.172
	var sh_y := 1.158 if female else 1.168
	for side in [-1.0, 1.0]:
		var arm_pivot := Node3D.new()
		arm_pivot.name = "ArmLPivot" if side < 0 else "ArmRPivot"
		arm_pivot.position = Vector3(side * sh_x, sh_y, 0.0)
		root.add_child(arm_pivot)

		var arm_sm := StyleMesh.new()
		var shoulder := Vector3.ZERO
		var elbow := Vector3(side * 0.072, -0.19, -0.014)
		var wrist := Vector3(side * 0.048, -0.39, 0.088)
		var palm := Vector3(side * 0.036, -0.435, 0.122)

		arm_sm.ellipsoid(sleeve, shoulder + Vector3(-side * 0.010, -0.008, 0.0), Vector3(0.054, 0.056, 0.054), 7, 14)
		arm_sm.capsule_seg(sleeve, shoulder, elbow, 0.040 if female else 0.047, 0.035 if female else 0.041, 14)
		arm_sm.capsule_seg(forearm_mat, elbow, wrist, 0.034 if female else 0.039, 0.025 if female else 0.029, 14)
		if rolled:
			arm_sm.capsule_seg(sleeve, elbow, elbow.lerp(wrist, 0.24), 0.042, 0.040, 12)
		else:
			# Polsino camicia
			arm_sm.capsule_seg("apron_white" if sleeve == shirt else sleeve, elbow.lerp(wrist, 0.85), wrist, 0.030, 0.028, 12)

		# Mano anatomica a 5 dita scolpite (palmo piatto + pollice opponibile + 4 dita graduate)
		_add_sculpted_hand(arm_sm, skin_k, palm, side, false)

		var ami := MeshInstance3D.new()
		ami.name = "Mesh"
		ami.mesh = arm_sm.to_mesh(Callable(VillageMaterials, "mat"))
		ami.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		arm_pivot.add_child(ami)

	_attach_npc_animations(root, false)

# ------------------------------------------------------------------ DIPENDENTE SEDUTO (LUCA / COLLEGA OGR)
static func _build_seated_character(root: Node3D, opts: Dictionary) -> void:
	var shirt: String = opts.get("shirt", "hoodie_teal")
	var pants: String = opts.get("pants", "denim")
	var skin_k: String = opts.get("skin", "skin")
	var female: bool = bool(opts.get("female", false))

	var body := StyleMesh.new()

	for side in [-1.0, 1.0]:
		var sx: float = side * 0.102
		body.ellipsoid("sneaker_white", Vector3(sx, 0.019, 0.365), Vector3(0.058, 0.019, 0.118), 6, 14)
		body.ellipsoid("iron", Vector3(sx, 0.046, 0.360), Vector3(0.054, 0.036, 0.110), 6, 14)
		body.capsule_seg("white", Vector3(sx - 0.018, 0.070, 0.365), Vector3(sx + 0.018, 0.070, 0.382), 0.004, 0.004, 6)
		body.capsule_seg(pants, Vector3(sx, 0.07, 0.33), Vector3(sx, 0.470, 0.31), 0.044, 0.058, 14)
		body.capsule_seg(pants, Vector3(sx * 0.90, 0.482, 0.02), Vector3(sx, 0.475, 0.31), 0.070, 0.058, 14)

	body.ellipsoid(pants, Vector3(0, 0.492, 0.0), Vector3(0.164, 0.084, 0.120), 8, 18)

	var chest_r := 0.156 if female else 0.172
	body.lathe_oval(shirt, Vector3(0, 0.505, 0.015), [
		Vector2(0.146, 0.00),
		Vector2(0.144, 0.11),
		Vector2(chest_r, 0.30),
		Vector2(0.154, 0.40),
		Vector2(0.102, 0.45),
		Vector2(0.068, 0.485),
	], 1.15, 0.75, 22)
	# Collo / Cappuccio felpa morbido
	body.ellipsoid(shirt, Vector3(0, 0.922, -0.072), Vector3(0.116, 0.050, 0.080), 7, 14)
	body.lathe_oval("apron_white", Vector3(0, 0.935, 0.022), [Vector2(0.074, 0.0), Vector2(0.064, 0.042)], 1.0, 0.94, 16)

	var body_mi := MeshInstance3D.new()
	body_mi.name = "BodyMesh"
	body_mi.mesh = body.to_mesh(Callable(VillageMaterials, "mat"))
	body_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	root.add_child(body_mi)

	var head_pivot := Node3D.new()
	head_pivot.name = "HeadPivot"
	head_pivot.position = Vector3(0, 0.97, 0.022)
	root.add_child(head_pivot)
	_build_head(head_pivot, opts, Vector3.ZERO)

	for side in [-1.0, 1.0]:
		var arm_pivot := Node3D.new()
		arm_pivot.name = "ArmLPivot" if side < 0 else "ArmRPivot"
		arm_pivot.position = Vector3(side * 0.170, 0.875, 0.018)
		root.add_child(arm_pivot)

		var arm_sm := StyleMesh.new()
		var shoulder := Vector3.ZERO
		var elbow := Vector3(side * 0.044, -0.14, 0.12)
		var wrist := Vector3(-side * 0.036, -0.095, 0.34)
		var palm := Vector3(-side * 0.052, -0.104, 0.382)
		arm_sm.ellipsoid(shirt, shoulder + Vector3(-side * 0.008, -0.006, 0.0), Vector3(0.052, 0.052, 0.052), 6, 12)
		arm_sm.capsule_seg(shirt, shoulder, elbow, 0.045, 0.039, 14)
		arm_sm.capsule_seg(shirt, elbow, wrist, 0.037, 0.029, 14)
		_add_sculpted_hand(arm_sm, skin_k, palm, side, true)
		var ami := MeshInstance3D.new()
		ami.name = "Mesh"
		ami.mesh = arm_sm.to_mesh(Callable(VillageMaterials, "mat"))
		ami.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		arm_pivot.add_child(ami)

	_attach_npc_animations(root, true)

# ------------------------------------------------------------------ MANO ANATOMICA 5 DITA SCOLPITA
static func _add_sculpted_hand(sm: StyleMesh, skin_k: String, palm_c: Vector3, side: float, typing_pose: bool) -> void:
	if typing_pose:
		# Mano appoggiata orizzontalmente sulla tastiera
		sm.ellipsoid(skin_k, palm_c, Vector3(0.029, 0.014, 0.036), 6, 12)
		# Pollice verso l'interno
		sm.capsule_seg(skin_k, palm_c + Vector3(-side * 0.024, -0.002, -0.008),
			palm_c + Vector3(-side * 0.038, -0.008, 0.028), 0.0075, 0.0062, 8)
		# 4 dita leggermente arcuate in avanti verso i tasti
		var lengths := [0.044, 0.050, 0.046, 0.036]
		for fi in range(4):
			var fx := (float(fi) - 1.5) * 0.0145 * (-side)
			var base_p := palm_c + Vector3(fx, 0.003, 0.032)
			var mid_p := base_p + Vector3(0.0, 0.002, lengths[fi] * 0.55)
			var tip_p := mid_p + Vector3(0.0, -0.012, lengths[fi] * 0.48)
			sm.capsule_seg(skin_k, base_p, mid_p, 0.0062, 0.0056, 7)
			sm.capsule_seg(skin_k, mid_p, tip_p, 0.0055, 0.0045, 7)
	else:
		# Mano rilassata lungo i fianchi con leggera curvatura naturale
		sm.ellipsoid(skin_k, palm_c, Vector3(0.022, 0.036, 0.031), 6, 12, Vector3(0.24, 0.0, -side * 0.08))
		# Pollice opponibile anteriore-interno
		var th_base := palm_c + Vector3(-side * 0.016, 0.012, 0.018)
		var th_tip := th_base + Vector3(-side * 0.012, -0.024, 0.026)
		sm.capsule_seg(skin_k, th_base, th_tip, 0.0078, 0.0062, 8)
		# 4 dita graduate verso il basso
		var lengths := [0.048, 0.054, 0.049, 0.039]
		for fi in range(4):
			var fz := (1.5 - float(fi)) * 0.0145
			var base_p := palm_c + Vector3(0.0, -0.028, fz)
			var tip_p := base_p + Vector3(-side * 0.014, -lengths[fi], 0.010)
			sm.capsule_seg(skin_k, base_p, tip_p, 0.0060, 0.0046, 7)

# ------------------------------------------------------------------ TESTA & VOLTO SEMI-REALISTICO
static func _build_head(head_pivot: Node3D, opts: Dictionary, origin: Vector3) -> void:
	var skin_k: String = opts.get("skin", "skin")
	var hair_k: String = opts.get("hair", "hair_brown")
	var iris_k: String = opts.get("iris", "iris_brown")
	var hair_style: String = opts.get("hair_style", "short")
	var hat: String = opts.get("hat", "")
	var mustache: bool = bool(opts.get("mustache", false))
	var glasses: bool = bool(opts.get("glasses", false))
	var female: bool = bool(opts.get("female", false))

	var sm := StyleMesh.new()
	# Collo muscolare proporzionato (leggera inclinazione naturale cervicale)
	sm.capsule_seg(skin_k, origin + Vector3(0, -0.018, -0.004), origin + Vector3(0, 0.112, 0.008), 0.052 if not female else 0.044, 0.047 if not female else 0.041, 16)

	# Cranio & Mascella scolpiti ad alta risoluzione (mento definito -> linea mandibolare -> zigomi -> tempie -> calotta)
	var head_base := origin + Vector3(0, 0.068, 0.008)
	var stretch_x := 0.87 if female else 0.92
	sm.lathe_oval(skin_k, head_base, [
		Vector2(0.002, 0.000),
		Vector2(0.056, 0.016),
		Vector2(0.098, 0.050),
		Vector2(0.122, 0.098),
		Vector2(0.132, 0.156),
		Vector2(0.130, 0.214),
		Vector2(0.106, 0.268),
		Vector2(0.058, 0.300),
		Vector2(0.002, 0.312),
	], stretch_x, 0.96, 28)

	# Centro volto riferimento
	var hc := head_base + Vector3(0, 0.152, 0)

	# Rilievo zigomi + arcata sopraccigliare + mento anatomico
	for side in [-1.0, 1.0]:
		sm.ellipsoid(skin_k, hc + Vector3(side * 0.056, -0.022, 0.098), Vector3(0.032, 0.018, 0.020), 6, 12, Vector3(0, side * 0.42, 0))
		sm.ellipsoid("skin_cheek", hc + Vector3(side * 0.058, -0.030, 0.095), Vector3(0.022, 0.012, 0.006), 5, 10, Vector3(0, side * 0.44, 0))
		sm.ellipsoid(skin_k, hc + Vector3(side * 0.036, 0.042, 0.116), Vector3(0.026, 0.008, 0.012), 5, 10, Vector3(0, side * 0.20, -side * 0.10))
	sm.ellipsoid(skin_k, hc + Vector3(0.0, -0.102, 0.088), Vector3(0.024, 0.018, 0.016), 6, 10)

	# Orecchie anatomiche (elice esterna + padiglione)
	var ear_x := 0.123 * stretch_x
	for side in [-1.0, 1.0]:
		sm.ellipsoid(skin_k, hc + Vector3(side * ear_x, -0.008, -0.008), Vector3(0.015, 0.034, 0.023), 7, 12, Vector3(0.08, side * 0.28, -side * 0.12))
		sm.ellipsoid("skin_warm", hc + Vector3(side * (ear_x + 0.003), -0.009, -0.006), Vector3(0.009, 0.018, 0.011), 5, 10)

	# Naso scolpito realistico: dorso nasale + punta + due ali/narici laterali
	sm.capsule_seg(skin_k, hc + Vector3(0, 0.022, 0.118), hc + Vector3(0, -0.014, 0.138), 0.011, 0.012, 10)
	sm.ellipsoid(skin_k, hc + Vector3(0, -0.018, 0.136), Vector3(0.014, 0.013, 0.017), 6, 12)
	for side in [-1.0, 1.0]:
		sm.ellipsoid(skin_k, hc + Vector3(side * 0.013, -0.023, 0.126), Vector3(0.009, 0.009, 0.010), 5, 10)

	# Occhi semi-realistici espressivi (proporzioni adulte + palpebre + anello limbale + iride + pupilla + riflesso)
	for side in [-1.0, 1.0]:
		var sx: float = side * 0.042
		var yaw: float = side * 0.22
		# Sclera mandorla + cornice palpebrale sup/inf
		sm.ellipsoid("eye_white", hc + Vector3(sx, 0.015, 0.114), Vector3(0.0175, 0.0115, 0.010), 7, 14, Vector3(0, yaw, 0))
		sm.ellipsoid(iris_k, hc + Vector3(sx * 1.02, 0.015, 0.121), Vector3(0.0096, 0.0096, 0.006), 6, 12, Vector3(0, yaw, 0))
		sm.ellipsoid("limbal_dark", hc + Vector3(sx * 1.022, 0.015, 0.1195), Vector3(0.0106, 0.0106, 0.005), 6, 12, Vector3(0, yaw, 0))
		sm.ellipsoid("limbal_dark", hc + Vector3(sx * 1.03, 0.015, 0.1245), Vector3(0.0052, 0.0054, 0.004), 5, 10, Vector3(0, yaw, 0))
		sm.ellipsoid("eye_white", hc + Vector3(sx + 0.0035, 0.0185, 0.127), Vector3(0.0022, 0.0022, 0.002), 4, 8)
		# Palpebra superiore + linea ciglia + palpebra inferiore
		sm.capsule_seg("hair_dark", hc + Vector3(sx - 0.017, 0.023, 0.115), hc + Vector3(sx, 0.0265, 0.119), 0.0024, 0.0024, 6)
		sm.capsule_seg("hair_dark", hc + Vector3(sx, 0.0265, 0.119), hc + Vector3(sx + 0.017, 0.023, 0.115), 0.0024, 0.0024, 6)
		sm.capsule_seg(skin_k, hc + Vector3(sx - 0.016, 0.0055, 0.114), hc + Vector3(sx + 0.016, 0.0055, 0.114), 0.0032, 0.0032, 6)
		# Sopracciglia arcuate multi-segmento
		sm.capsule_seg(hair_k, hc + Vector3(sx - 0.020 * side, 0.039, 0.117), hc + Vector3(sx, 0.044, 0.120), 0.0038, 0.0036, 7)
		sm.capsule_seg(hair_k, hc + Vector3(sx, 0.044, 0.120), hc + Vector3(sx + 0.020 * side, 0.036, 0.114), 0.0036, 0.0024, 7)

	# Bocca scolpita (labbro superiore arco di Cupido + labbro inferiore pieno)
	for side in [-1.0, 1.0]:
		sm.capsule_seg("lip_warm", hc + Vector3(0.0, -0.056, 0.121), hc + Vector3(side * 0.022, -0.059, 0.113), 0.0044, 0.0032, 8)
	sm.ellipsoid("lip_warm", hc + Vector3(0.0, -0.064, 0.118), Vector3(0.018, 0.0060, 0.008), 5, 12)

	# Baffi a manubrio naturali
	if mustache:
		for side in [-1.0, 1.0]:
			sm.capsule_seg(hair_k, hc + Vector3(0, -0.038, 0.130), hc + Vector3(side * 0.048, -0.046, 0.114), 0.013, 0.007, 10)
			sm.ellipsoid(hair_k, hc + Vector3(side * 0.054, -0.042, 0.110), Vector3(0.010, 0.008, 0.008), 5, 8)

	# Occhiali sottili ed eleganti da tech / dev
	if glasses:
		for sx in [-0.043, 0.043]:
			var gz := 0.133
			sm.capsule_seg("hair_dark", hc + Vector3(sx - 0.023, 0.028, gz), hc + Vector3(sx + 0.023, 0.028, gz), 0.0024, 0.0024, 6)
			sm.capsule_seg("hair_dark", hc + Vector3(sx - 0.023, -0.002, gz), hc + Vector3(sx + 0.023, -0.002, gz), 0.0024, 0.0024, 6)
			sm.capsule_seg("hair_dark", hc + Vector3(sx - 0.023, 0.028, gz), hc + Vector3(sx - 0.023, -0.002, gz), 0.0024, 0.0024, 6)
			sm.capsule_seg("hair_dark", hc + Vector3(sx + 0.023, 0.028, gz), hc + Vector3(sx + 0.023, -0.002, gz), 0.0024, 0.0024, 6)
		sm.capsule_seg("hair_dark", hc + Vector3(-0.020, 0.022, 0.135), hc + Vector3(0.020, 0.022, 0.135), 0.0024, 0.0024, 6)
		for side in [-1.0, 1.0]:
			sm.capsule_seg("hair_dark", hc + Vector3(side * 0.066, 0.022, 0.130), hc + Vector3(side * (ear_x - 0.002), 0.020, -0.002), 0.0024, 0.0024, 6)

	# Capigliatura 3D stratificata
	_add_hair(sm, hair_k, hc, hair_style, hat != "", stretch_x)

	# Copricapo opzionale ben calzato
	if hat == "chef":
		sm.lathe_oval("apron_white", hc + Vector3(0, 0.088, -0.006), [
			Vector2(0.136, 0.0), Vector2(0.142, 0.055), Vector2(0.178, 0.13),
			Vector2(0.184, 0.21), Vector2(0.138, 0.275), Vector2(0.02, 0.295)
		], stretch_x, 0.98, 22)
	elif hat == "baker":
		sm.lathe_oval("fabric_cream", hc + Vector3(0, 0.095, -0.008), [
			Vector2(0.138, 0.0), Vector2(0.165, 0.05), Vector2(0.148, 0.105), Vector2(0.02, 0.125)
		], stretch_x, 1.04, 20)
		sm.ellipsoid("leather", hc + Vector3(0, 0.098, 0.112), Vector3(0.106, 0.013, 0.068), 5, 12, Vector3(0.16, 0, 0))
	elif hat == "hardhat":
		sm.lathe_oval("safety_yellow", hc + Vector3(0, 0.086, -0.004), [
			Vector2(0.144, 0.00), Vector2(0.148, 0.035), Vector2(0.130, 0.085),
			Vector2(0.082, 0.122), Vector2(0.004, 0.132)
		], stretch_x * 1.04, 1.04, 22)
		sm.ellipsoid("safety_yellow", hc + Vector3(0, 0.150, 0.002), Vector3(0.020, 0.078, 0.126), 5, 10)
		sm.ellipsoid("safety_yellow", hc + Vector3(0, 0.092, 0.116), Vector3(0.116, 0.014, 0.066), 5, 12, Vector3(0.14, 0, 0))

	var head_mi := MeshInstance3D.new()
	head_mi.name = "HeadMesh"
	head_mi.mesh = sm.to_mesh(Callable(VillageMaterials, "mat"))
	head_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	head_pivot.add_child(head_mi)

static func _add_hair(sm: StyleMesh, hair_k: String, hc: Vector3, style: String, has_hat: bool, stretch_x: float) -> void:
	# Calotta anatomica aderente + sfumatura nuca e basette
	sm.ellipsoid(hair_k, hc + Vector3(0, 0.048, -0.024), Vector3(0.140 * stretch_x, 0.118, 0.138), 10, 20)
	sm.ellipsoid(hair_k, hc + Vector3(0, -0.008, -0.068), Vector3(0.130 * stretch_x, 0.104, 0.086), 8, 16)
	for side in [-1.0, 1.0]:
		sm.ellipsoid(hair_k, hc + Vector3(side * 0.116 * stretch_x, 0.024, 0.014), Vector3(0.020, 0.044, 0.038), 6, 10)

	if has_hat:
		return

	match style:
		"ponytail":
			for i in range(3):
				var ox := -0.06 + float(i) * 0.06
				sm.capsule_seg(hair_k, hc + Vector3(ox, 0.132, 0.055), hc + Vector3(ox * 1.1, 0.115, -0.10), 0.036, 0.032, 10)
			sm.ellipsoid(hair_k, hc + Vector3(-0.040, 0.106, 0.058), Vector3(0.086, 0.040, 0.078), 7, 12, Vector3(0.22, 0, 0.20))
			sm.ellipsoid(hair_k, hc + Vector3(0.056, 0.098, 0.058), Vector3(0.072, 0.036, 0.072), 7, 12, Vector3(0.22, 0, -0.22))
			sm.ellipsoid("fabric_red", hc + Vector3(0, 0.080, -0.142), Vector3(0.032, 0.028, 0.028), 5, 10)
			sm.capsule_seg(hair_k, hc + Vector3(0, 0.070, -0.152), Vector3(0, -0.125, -0.198), 0.044, 0.020, 12)
			sm.capsule_seg(hair_k, hc + Vector3(0.015, 0.065, -0.150), Vector3(0.022, -0.105, -0.192), 0.026, 0.014, 10)
		"bob":
			for side in [-1.0, 1.0]:
				sm.ellipsoid(hair_k, hc + Vector3(side * 0.114 * stretch_x, -0.018, 0.012), Vector3(0.034, 0.096, 0.076), 8, 14)
				sm.capsule_seg(hair_k, hc + Vector3(side * 0.030, 0.145, 0.032), hc + Vector3(side * 0.122 * stretch_x, 0.038, 0.050), 0.034, 0.026, 10)
			sm.ellipsoid(hair_k, hc + Vector3(0, 0.015, -0.150), Vector3(0.064, 0.060, 0.050), 7, 12)
		"quiff":
			for i in range(3):
				var ox := -0.05 + float(i) * 0.05
				sm.capsule_seg(hair_k, hc + Vector3(ox, 0.125, 0.078), hc + Vector3(ox + 0.015, 0.148, -0.035), 0.034, 0.040, 10)
			sm.ellipsoid(hair_k, hc + Vector3(0.010, 0.132, 0.048), Vector3(0.102, 0.052, 0.098), 8, 14, Vector3(-0.22, 0.1, -0.08))
			sm.ellipsoid(hair_k, hc + Vector3(-0.078, 0.086, 0.038), Vector3(0.044, 0.042, 0.072), 6, 10)
			sm.ellipsoid(hair_k, hc + Vector3(0.082, 0.086, 0.038), Vector3(0.044, 0.042, 0.072), 6, 10)
		_:
			for i in range(4):
				var ox := -0.065 + float(i) * 0.043
				sm.capsule_seg(hair_k, hc + Vector3(ox, 0.128, 0.055), hc + Vector3(ox, 0.134, -0.060), 0.032, 0.030, 10)
			sm.ellipsoid(hair_k, hc + Vector3(0, 0.118, 0.036), Vector3(0.116 * stretch_x, 0.044, 0.088), 8, 14)

# ------------------------------------------------------------------ ANIMAZIONI PROCEDURALI
static func _attach_npc_animations(root: Node3D, is_seated: bool) -> void:
	var ap := AnimationPlayer.new()
	ap.name = "AnimationPlayer"

	var lib := AnimationLibrary.new()

	var idle := Animation.new()
	idle.length = 2.6
	idle.loop_mode = Animation.LOOP_LINEAR

	var head := root.get_node_or_null("HeadPivot")
	var arm_l := root.get_node_or_null("ArmLPivot")
	var arm_r := root.get_node_or_null("ArmRPivot")

	if head:
		var t_hy := idle.add_track(Animation.TYPE_VALUE)
		idle.track_set_path(t_hy, "HeadPivot:rotation")
		idle.track_insert_key(t_hy, 0.0, Vector3(0.0, -0.05, 0.0))
		idle.track_insert_key(t_hy, 1.3, Vector3(0.04 if is_seated else -0.02, 0.06, 0.0))
		idle.track_insert_key(t_hy, 2.6, Vector3(0.0, -0.05, 0.0))

	if arm_l and arm_r:
		var t_al := idle.add_track(Animation.TYPE_VALUE)
		idle.track_set_path(t_al, "ArmLPivot:rotation")
		var t_ar := idle.add_track(Animation.TYPE_VALUE)
		idle.track_set_path(t_ar, "ArmRPivot:rotation")
		if is_seated:
			idle.track_insert_key(t_al, 0.0, Vector3(-0.04, 0, 0))
			idle.track_insert_key(t_al, 0.65, Vector3(0.04, 0, 0))
			idle.track_insert_key(t_al, 1.3, Vector3(-0.03, 0, 0))
			idle.track_insert_key(t_al, 1.95, Vector3(0.04, 0, 0))
			idle.track_insert_key(t_al, 2.6, Vector3(-0.04, 0, 0))
			idle.track_insert_key(t_ar, 0.0, Vector3(0.04, 0, 0))
			idle.track_insert_key(t_ar, 0.65, Vector3(-0.04, 0, 0))
			idle.track_insert_key(t_ar, 1.3, Vector3(0.03, 0, 0))
			idle.track_insert_key(t_ar, 1.95, Vector3(-0.04, 0, 0))
			idle.track_insert_key(t_ar, 2.6, Vector3(0.04, 0, 0))
		else:
			idle.track_insert_key(t_al, 0.0, Vector3(0.0, 0, -0.03))
			idle.track_insert_key(t_al, 1.3, Vector3(0.04, 0, -0.06))
			idle.track_insert_key(t_al, 2.6, Vector3(0.0, 0, -0.03))
			idle.track_insert_key(t_ar, 0.0, Vector3(0.0, 0, 0.03))
			idle.track_insert_key(t_ar, 1.3, Vector3(0.04, 0, 0.06))
			idle.track_insert_key(t_ar, 2.6, Vector3(0.0, 0, 0.03))

	if is_seated:
		lib.add_animation("Sit_Chair_Idle", idle)
	else:
		lib.add_animation("Idle", idle)

	var interact := Animation.new()
	interact.length = 1.0
	if arm_r:
		var t_ir := interact.add_track(Animation.TYPE_VALUE)
		interact.track_set_path(t_ir, "ArmRPivot:rotation")
		interact.track_insert_key(t_ir, 0.0, Vector3(0.0, 0.0, 0.04))
		interact.track_insert_key(t_ir, 0.35, Vector3(-0.85, 0.0, 0.35))
		interact.track_insert_key(t_ir, 0.65, Vector3(-0.75, 0.0, 0.15))
		interact.track_insert_key(t_ir, 1.0, Vector3(0.0, 0.0, 0.04))
	lib.add_animation("Interact", interact)
	lib.add_animation("Cheer", interact)

	ap.add_animation_library("", lib)
	ap.autoplay = "Sit_Chair_Idle" if is_seated else "Idle"
	root.add_child(ap)
	ap.play("Sit_Chair_Idle" if is_seated else "Idle")
