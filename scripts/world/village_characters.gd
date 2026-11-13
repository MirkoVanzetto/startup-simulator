class_name VillageCharacters
extends RefCounted
## VillageCharacters - Costruttore di personaggi 3D semi-cartoon scolpiti (zero cubi).
## Crea parti articolate (BodyMesh, HeadPivot, ArmLPivot, ArmRPivot) con AnimationPlayer
## usando forme organiche tornite (lathe_oval, ellipsoid, capsule_seg) e shader toon.

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

	var body := StyleMesh.new()

	# Scarpe arrotondate con suola bianca e tomaia scolpita (poggiano esatte a Y=0)
	for sx in [-0.102, 0.102]:
		body.ellipsoid("sneaker_white", Vector3(sx, 0.022, 0.032), Vector3(0.066, 0.022, 0.122), 5, 12)
		body.ellipsoid(shoe_key, Vector3(sx, 0.052, 0.026), Vector3(0.062, 0.042, 0.112), 6, 12)
		body.cyl(shoe_key, Vector3(sx, 0.048, -0.018), 0.050, 0.048, 0.055, 10)

	# Gambe anatomiche affusolate
	var calf_k := skin_k if skirt else pants
	for sx in [-0.098, 0.098]:
		var hip := Vector3(sx * 0.90, 0.78, 0.0)
		var knee := Vector3(sx, 0.44, 0.012)
		var ankle := Vector3(sx, 0.095, -0.01)
		body.capsule_seg(calf_k, ankle, knee, 0.044 if female else 0.050, 0.058 if female else 0.064, 12)
		body.capsule_seg(pants, knee, hip, 0.062 if female else 0.068, 0.078 if female else 0.085, 12)

	# Bacino & gonna opzionale (senza compenetrazioni col grembiule)
	if skirt:
		body.lathe_oval(pants, Vector3(0, 0.48, 0), [
			Vector2(0.002, 0.0), Vector2(0.198, 0.01), Vector2(0.182, 0.18), Vector2(0.142, 0.34)
		], 1.10, 0.76, 20)
	else:
		body.ellipsoid(pants, Vector3(0, 0.79, 0), Vector3(0.170, 0.098, 0.114), 7, 16)

	# Busto sagomato continuo con spalle morbide (fianchi -> vita -> petto -> spalle -> collo)
	var waist_r := 0.130 if female else 0.148
	var chest_r := 0.154 if female else 0.172
	var torso_prof := [
		Vector2(0.148, 0.00),
		Vector2(waist_r, 0.12),
		Vector2(chest_r, 0.33),
		Vector2(chest_r * 0.91, 0.42),
		Vector2(0.104, 0.47),
		Vector2(0.068, 0.51),
	]
	body.lathe_oval(shirt, Vector3(0, 0.80, 0), torso_prof, 1.15, 0.74, 20)

	# Gilet avvolgente sagomato sul busto (per Davide o outfit casual/tech)
	if vest != "":
		body.lathe_oval(vest, Vector3(0, 0.81, -0.012), [
			Vector2(0.160, 0.00), Vector2(waist_r + 0.016, 0.12),
			Vector2(chest_r + 0.014, 0.33), Vector2(0.144, 0.43)
		], 1.16, 0.74, 20)
		# Zip / risvolti frontali e badge tecnico sul petto
		body.capsule_seg("iron", Vector3(0, 0.84, 0.120), Vector3(0, 1.18, 0.124), 0.007, 0.007, 6)
		body.ellipsoid("cyan_accent", Vector3(0.082, 1.12, 0.122), Vector3(0.024, 0.017, 0.008), 5, 10)

	# Cintura in pelle & fibbia (visibile se senza grembiule)
	if apron == "":
		body.lathe_oval("leather", Vector3(0, 0.82, 0), [
			Vector2(0.156, 0.0), Vector2(0.156, 0.044)
		], 1.15, 0.75, 18)
		body.ellipsoid("brass", Vector3(0, 0.842, 0.120), Vector3(0.026, 0.020, 0.010), 5, 10)

	# Colletto morbido della camicia & cravatta opzionale
	body.lathe_oval("apron_white", Vector3(0, 1.26, 0.008), [
		Vector2(0.092, 0.0), Vector2(0.068, 0.045)
	], 1.04, 0.94, 16)
	if tie_key != "":
		body.capsule_seg(tie_key, Vector3(0, 1.25, 0.118), Vector3(0, 1.00, 0.124), 0.019, 0.026, 8)
		body.ellipsoid(tie_key, Vector3(0, 1.255, 0.120), Vector3(0.021, 0.019, 0.014), 4, 8)

	# Grembiule avvolgente scolpito (nettamente davanti a petto/gonna, nessuna compenetrazione)
	if apron != "":
		var ap_mat := "apron_white" if apron == "white" else apron
		# Pettorina frontale ben distanziata davanti al petto fino a Y=1.20
		body.lathe_oval(ap_mat, Vector3(0, 0.88, 0.052), [
			Vector2(0.142, 0.0), Vector2(0.148, 0.16), Vector2(0.132, 0.30)
		], 1.02, 0.86, 18)
		# Bretelle morbide sopra le spalle senza tagliare la camicia
		for sx in [-0.082, 0.082]:
			body.capsule_seg(ap_mat, Vector3(sx, 1.17, 0.132), Vector3(sx * 0.96, 1.29, 0.03), 0.013, 0.013, 8)
			body.capsule_seg(ap_mat, Vector3(sx * 0.96, 1.29, 0.03), Vector3(sx * 0.70, 1.24, -0.09), 0.013, 0.013, 8)
		# Gonna del grembiule + cintura in vita + tasca centrale ben sporgente davanti
		var bottom_r := 0.218 if skirt else 0.188
		var waist_ap_r := 0.188 if skirt else 0.168
		body.lathe_oval(ap_mat, Vector3(0, 0.54, 0.022), [
			Vector2(bottom_r, 0.0), Vector2(waist_ap_r, 0.18), Vector2(waist_ap_r * 0.96, 0.34)
		], 1.18, 0.84, 20)
		body.lathe_oval(ap_mat, Vector3(0, 0.86, 0.022), [
			Vector2(waist_ap_r * 1.02, 0.0), Vector2(waist_ap_r * 1.02, 0.04)
		], 1.18, 0.84, 18)
		var pocket_mat := "fabric_cream" if ap_mat == "apron_white" else "apron_white"
		var pocket_z := 0.194 if skirt else 0.175
		body.ellipsoid(pocket_mat, Vector3(0, 0.72, pocket_z), Vector3(0.066, 0.048, 0.016), 5, 12)

	var body_mi := MeshInstance3D.new()
	body_mi.name = "BodyMesh"
	body_mi.mesh = body.to_mesh(Callable(VillageMaterials, "mat"))
	body_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	root.add_child(body_mi)

	# Testa espressiva continua con pivot al collo
	var head_pivot := Node3D.new()
	head_pivot.name = "HeadPivot"
	head_pivot.position = Vector3(0, 1.28, 0)
	root.add_child(head_pivot)
	_build_head(head_pivot, opts, Vector3.ZERO)

	# Braccia articolate (spalle incassate naturalmente nella curva del busto, senza sfere esterne)
	var sleeve: String = opts.get("sleeve", shirt)
	var rolled := bool(opts.get("rolled_sleeves", false))
	var forearm_mat := skin_k if rolled else sleeve
	var sh_x := 0.158 if female else 0.174
	var sh_y := 1.152 if female else 1.162
	for side in [-1.0, 1.0]:
		var arm_pivot := Node3D.new()
		arm_pivot.name = "ArmLPivot" if side < 0 else "ArmRPivot"
		arm_pivot.position = Vector3(side * sh_x, sh_y, 0.0)
		root.add_child(arm_pivot)

		var arm_sm := StyleMesh.new()
		var shoulder := Vector3.ZERO
		var elbow := Vector3(side * 0.072, -0.19, -0.012)
		var wrist := Vector3(side * 0.048, -0.39, 0.088)
		var hand := Vector3(side * 0.036, -0.44, 0.126)
		arm_sm.capsule_seg(sleeve, shoulder, elbow, 0.040 if female else 0.048, 0.036 if female else 0.042, 12)
		arm_sm.capsule_seg(forearm_mat, elbow, wrist, 0.035 if female else 0.040, 0.029 if female else 0.033, 12)
		if rolled:
			arm_sm.capsule_seg(sleeve, elbow, elbow.lerp(wrist, 0.20), 0.043, 0.042, 10)
		# Mano scolpita con pollice
		arm_sm.ellipsoid(skin_k, hand, Vector3(0.032, 0.043, 0.033), 6, 12, Vector3(0.32, 0, -side * 0.10))
		arm_sm.ellipsoid(skin_k, hand + Vector3(-side * 0.019, 0.012, 0.021), Vector3(0.013, 0.019, 0.014), 5, 8)
		var ami := MeshInstance3D.new()
		ami.name = "Mesh"
		ami.mesh = arm_sm.to_mesh(Callable(VillageMaterials, "mat"))
		ami.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		arm_pivot.add_child(ami)

	_attach_npc_animations(root, false)

# ------------------------------------------------------------------ DIPENDENTE SEDUTO (LUCA)
static func _build_seated_character(root: Node3D, opts: Dictionary) -> void:
	var shirt: String = opts.get("shirt", "hoodie_teal")
	var pants: String = opts.get("pants", "denim")
	var skin_k: String = opts.get("skin", "skin")

	var body := StyleMesh.new()

	# Scarpe poggiate piatte a terra (Y=0) sotto il piano scrivania, Z = +0.34
	for sx in [-0.10, 0.10]:
		body.ellipsoid("sneaker_white", Vector3(sx, 0.022, 0.365), Vector3(0.064, 0.022, 0.116), 5, 12)
		body.ellipsoid("iron", Vector3(sx, 0.050, 0.360), Vector3(0.058, 0.040, 0.108), 6, 12)
		body.capsule_seg(pants, Vector3(sx, 0.07, 0.33), Vector3(sx, 0.470, 0.31), 0.048, 0.060, 12)
		body.capsule_seg(pants, Vector3(sx * 0.90, 0.482, 0.02), Vector3(sx, 0.475, 0.31), 0.070, 0.060, 12)

	# Bacino appoggiato a filo sul cuscino della sedia (top cuscino = 0.428m)
	body.ellipsoid(pants, Vector3(0, 0.492, 0.0), Vector3(0.164, 0.084, 0.120), 7, 16)

	# Busto eretto con spalle morbide (inclinato verso tastiera/monitor)
	body.lathe_oval(shirt, Vector3(0, 0.505, 0.015), [
		Vector2(0.148, 0.00),
		Vector2(0.146, 0.11),
		Vector2(0.170, 0.30),
		Vector2(0.152, 0.40),
		Vector2(0.100, 0.45),
		Vector2(0.068, 0.48),
	], 1.15, 0.75, 20)
	# Cappuccio morbido sulle spalle + colletto t-shirt compatto dentro la felpa
	body.ellipsoid(shirt, Vector3(0, 0.92, -0.075), Vector3(0.120, 0.055, 0.084), 6, 12)
	body.lathe_oval("apron_white", Vector3(0, 0.935, 0.022), [Vector2(0.074, 0.0), Vector2(0.064, 0.042)], 1.0, 0.94, 14)

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

	# Braccia che si posano davanti sulla tastiera (senza compenetrare lo schienale)
	for side in [-1.0, 1.0]:
		var arm_pivot := Node3D.new()
		arm_pivot.name = "ArmLPivot" if side < 0 else "ArmRPivot"
		arm_pivot.position = Vector3(side * 0.172, 0.875, 0.018)
		root.add_child(arm_pivot)

		var arm_sm := StyleMesh.new()
		var shoulder := Vector3.ZERO
		var elbow := Vector3(side * 0.044, -0.14, 0.12)
		var wrist := Vector3(-side * 0.036, -0.095, 0.34)
		var hand := Vector3(-side * 0.056, -0.105, 0.388)
		arm_sm.capsule_seg(shirt, shoulder, elbow, 0.046, 0.040, 12)
		arm_sm.capsule_seg(shirt, elbow, wrist, 0.038, 0.031, 12)
		arm_sm.ellipsoid(skin_k, hand, Vector3(0.032, 0.021, 0.042), 5, 10)
		var ami := MeshInstance3D.new()
		ami.name = "Mesh"
		ami.mesh = arm_sm.to_mesh(Callable(VillageMaterials, "mat"))
		ami.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		arm_pivot.add_child(ami)

	_attach_npc_animations(root, true)

# ------------------------------------------------------------------ TESTA & VOLTO ESPRESSIVO (TORNEO UNICO SENZA GIUNTURE)
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
	# Collo scolpito proporzionato che nasce morbido dal colletto
	sm.capsule_seg(skin_k, origin + Vector3(0, -0.01, 0), origin + Vector3(0, 0.108, 0.005), 0.052 if not female else 0.045, 0.048 if not female else 0.042, 14)

	# Testa continua a profilo organico unico (mento -> guance -> tempie -> calotta)
	var head_base := origin + Vector3(0, 0.072, 0.006)
	var stretch_x := 0.88 if female else 0.93
	sm.lathe_oval(skin_k, head_base, [
		Vector2(0.002, 0.000),
		Vector2(0.072, 0.020),
		Vector2(0.116, 0.056),
		Vector2(0.134, 0.106),
		Vector2(0.140, 0.162),
		Vector2(0.134, 0.220),
		Vector2(0.108, 0.270),
		Vector2(0.060, 0.300),
		Vector2(0.002, 0.310),
	], stretch_x, 0.94, 22)

	# Centro riferimento volto (local_y = 0.152 sopra head_base)
	var hc := head_base + Vector3(0, 0.152, 0)

	# Guance rosate morbide
	for sx in [-0.066, 0.066]:
		sm.ellipsoid("skin_cheek", hc + Vector3(sx, -0.042, 0.098), Vector3(0.022, 0.013, 0.007), 5, 10, Vector3(0, signf(sx) * 0.45, 0))

	# Orecchie scolpite laterali aderenti al cranio
	var ear_x := 0.128 * stretch_x
	for sx in [-ear_x, ear_x]:
		sm.ellipsoid(skin_k, hc + Vector3(sx, -0.012, -0.006), Vector3(0.018, 0.034, 0.024), 6, 10)

	# Naso arrotondato espressivo
	sm.ellipsoid(skin_k, hc + Vector3(0, -0.018, 0.133), Vector3(0.017, 0.020, 0.021), 6, 12)

	# Occhi espressivi incassati a filo sulla curvatura (sclera + ciglia + iride + pupilla + luce)
	for sx in [-0.044, 0.044]:
		var yaw := signf(sx) * 0.26
		sm.ellipsoid("eye_white", hc + Vector3(sx, 0.014, 0.119), Vector3(0.022, 0.027, 0.012), 6, 12, Vector3(0, yaw, 0))
		sm.ellipsoid(iris_k, hc + Vector3(sx * 1.02, 0.014, 0.127), Vector3(0.013, 0.017, 0.008), 5, 10, Vector3(0, yaw, 0))
		sm.ellipsoid("hair_dark", hc + Vector3(sx * 1.03, 0.014, 0.132), Vector3(0.008, 0.010, 0.006), 5, 10, Vector3(0, yaw, 0))
		sm.ellipsoid("eye_white", hc + Vector3(sx + 0.005, 0.021, 0.135), Vector3(0.0038, 0.0038, 0.003), 4, 8)
		sm.capsule_seg(hair_k if female else "hair_dark", hc + Vector3(sx - 0.020, 0.036, 0.119), hc + Vector3(sx + 0.020, 0.036, 0.119), 0.004, 0.004, 6)
		var brow_y := 0.056
		var tilt := -0.16 * signf(sx)
		sm.ellipsoid(hair_k, hc + Vector3(sx, brow_y, 0.118), Vector3(0.024, 0.006, 0.010), 5, 10, Vector3(0, yaw, tilt))

	# Sorriso dolce e pulito
	sm.capsule_seg("lip_warm", hc + Vector3(-0.023, -0.070, 0.116), hc + Vector3(0.0, -0.077, 0.122), 0.0055, 0.006, 8)
	sm.capsule_seg("lip_warm", hc + Vector3(0.0, -0.077, 0.122), hc + Vector3(0.023, -0.070, 0.116), 0.006, 0.0055, 8)

	# Baffi a manubrio curati (Mario / Bruno)
	if mustache:
		for side in [-1.0, 1.0]:
			sm.capsule_seg(hair_k, hc + Vector3(0, -0.043, 0.133), hc + Vector3(side * 0.052, -0.052, 0.118), 0.015, 0.009, 10)
			sm.ellipsoid(hair_k, hc + Vector3(side * 0.058, -0.047, 0.114), Vector3(0.012, 0.010, 0.010), 5, 8)

	# Occhiali sottili ed eleganti da tech / dev
	if glasses:
		for sx in [-0.044, 0.044]:
			var gz := 0.138
			sm.capsule_seg("hair_dark", hc + Vector3(sx - 0.025, 0.030, gz), hc + Vector3(sx + 0.025, 0.030, gz), 0.0028, 0.0028, 6)
			sm.capsule_seg("hair_dark", hc + Vector3(sx - 0.025, -0.004, gz), hc + Vector3(sx + 0.025, -0.004, gz), 0.0028, 0.0028, 6)
			sm.capsule_seg("hair_dark", hc + Vector3(sx - 0.025, 0.030, gz), hc + Vector3(sx - 0.025, -0.004, gz), 0.0028, 0.0028, 6)
			sm.capsule_seg("hair_dark", hc + Vector3(sx + 0.025, 0.030, gz), hc + Vector3(sx + 0.025, -0.004, gz), 0.0028, 0.0028, 6)
		sm.capsule_seg("hair_dark", hc + Vector3(-0.019, 0.022, 0.140), hc + Vector3(0.019, 0.022, 0.140), 0.0028, 0.0028, 6)
		for side in [-1.0, 1.0]:
			sm.capsule_seg("hair_dark", hc + Vector3(side * 0.069, 0.023, 0.135), hc + Vector3(side * (ear_x - 0.004), 0.020, 0.0), 0.0028, 0.0028, 6)

	# Capigliatura 3D scolpita (niente ciuffo frontale sporgente se c'è un cappello!)
	_add_hair(sm, hair_k, hc, hair_style, hat != "", stretch_x)

	# Copricapo opzionale ben calzato sulla fronte
	if hat == "chef":
		sm.lathe_oval("apron_white", hc + Vector3(0, 0.088, -0.006), [
			Vector2(0.140, 0.0), Vector2(0.144, 0.055), Vector2(0.180, 0.13),
			Vector2(0.188, 0.21), Vector2(0.142, 0.275), Vector2(0.02, 0.295)
		], stretch_x, 0.98, 20)
	elif hat == "baker":
		sm.lathe_oval("fabric_cream", hc + Vector3(0, 0.095, -0.008), [
			Vector2(0.142, 0.0), Vector2(0.168, 0.05), Vector2(0.152, 0.105), Vector2(0.02, 0.125)
		], stretch_x, 1.04, 18)
		sm.ellipsoid("leather", hc + Vector3(0, 0.098, 0.114), Vector3(0.108, 0.014, 0.070), 5, 12, Vector3(0.16, 0, 0))

	var head_mi := MeshInstance3D.new()
	head_mi.name = "HeadMesh"
	head_mi.mesh = sm.to_mesh(Callable(VillageMaterials, "mat"))
	head_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	head_pivot.add_child(head_mi)

static func _add_hair(sm: StyleMesh, hair_k: String, hc: Vector3, style: String, has_hat: bool, stretch_x: float) -> void:
	# Calotta base avvolgente dietro la testa
	sm.ellipsoid(hair_k, hc + Vector3(0, 0.048, -0.024), Vector3(0.146 * stretch_x, 0.122, 0.142), 9, 18)
	sm.ellipsoid(hair_k, hc + Vector3(0, -0.008, -0.068), Vector3(0.138 * stretch_x, 0.108, 0.090), 7, 14)
	# Basette pulite lungo le tempie
	for side in [-1.0, 1.0]:
		sm.ellipsoid(hair_k, hc + Vector3(side * 0.122 * stretch_x, 0.022, 0.016), Vector3(0.024, 0.048, 0.042), 5, 10)

	if has_hat:
		return

	match style:
		"ponytail":
			sm.ellipsoid(hair_k, hc + Vector3(-0.042, 0.112, 0.062), Vector3(0.098, 0.048, 0.084), 7, 12, Vector3(0.22, 0, 0.18))
			sm.ellipsoid(hair_k, hc + Vector3(0.060, 0.102, 0.062), Vector3(0.080, 0.044, 0.076), 7, 12, Vector3(0.22, 0, -0.22))
			sm.ellipsoid("fabric_red", hc + Vector3(0, 0.080, -0.148), Vector3(0.036, 0.032, 0.032), 5, 10)
			sm.capsule_seg(hair_k, hc + Vector3(0, 0.070, -0.158), Vector3(0, -0.125, -0.205), 0.048, 0.022, 12)
		"bob":
			for side in [-1.0, 1.0]:
				sm.ellipsoid(hair_k, hc + Vector3(side * 0.122 * stretch_x, -0.022, 0.015), Vector3(0.038, 0.102, 0.080), 7, 12)
			sm.ellipsoid(hair_k, hc + Vector3(0, 0.118, 0.056), Vector3(0.120 * stretch_x, 0.042, 0.080), 6, 12)
			sm.ellipsoid(hair_k, hc + Vector3(0, 0.015, -0.158), Vector3(0.068, 0.062, 0.052), 6, 12)
		"quiff":
			sm.ellipsoid(hair_k, hc + Vector3(0.012, 0.136, 0.052), Vector3(0.112, 0.060, 0.108), 7, 14, Vector3(-0.22, 0.1, -0.08))
			sm.ellipsoid(hair_k, hc + Vector3(-0.080, 0.090, 0.042), Vector3(0.050, 0.046, 0.080), 6, 10)
			sm.ellipsoid(hair_k, hc + Vector3(0.088, 0.090, 0.042), Vector3(0.050, 0.046, 0.080), 6, 10)
		_:
			sm.ellipsoid(hair_k, hc + Vector3(0, 0.122, 0.040), Vector3(0.126 * stretch_x, 0.050, 0.094), 7, 12)

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
