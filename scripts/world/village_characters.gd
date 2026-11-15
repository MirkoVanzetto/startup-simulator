class_name VillageCharacters
extends RefCounted
## VillageCharacters - Costruttore di personaggi 3D semi-realistici anatomici e sartoriali (v1.5 PBR + Sculpt).
## Preserva gerarchia esatta (BodyMesh, HeadPivot/HeadMesh, ArmLPivot/Mesh, ArmRPivot/Mesh, AnimationPlayer).

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
	var belt_buckle := "belt_brass"

	var body := StyleMesh.new()

	# 1. Calzature anatomiche con guardolo suola, tallone e lacci incrociati (base Y=0)
	var foot_offset := 0.104 if female else 0.114
	for side in [-1.0, 1.0]:
		var sx: float = side * foot_offset
		var foot_yaw: float = -side * 0.06
		body.ellipsoid("sneaker_white" if shoe_key != "leather" and shoe_key != "shoe_black" else "shoe_black",
			Vector3(sx, 0.017, 0.036), Vector3(0.056, 0.017, 0.128), 6, 16, Vector3(0, foot_yaw, 0))
		body.ellipsoid(shoe_key, Vector3(sx, 0.044, 0.030), Vector3(0.053, 0.034, 0.118), 7, 16, Vector3(0, foot_yaw, 0))
		body.cyl(shoe_key, Vector3(sx, 0.034, -0.024), 0.044, 0.041, 0.062, 14)
		body.ellipsoid(shoe_key, Vector3(sx, 0.068, 0.044), Vector3(0.034, 0.014, 0.044), 5, 10, Vector3(-0.26, foot_yaw, 0))
		if shoe_key == "sneaker_white":
			for lz in [0.036, 0.066]:
				body.capsule_seg("shirt_white", Vector3(sx - 0.020, 0.072, lz), Vector3(sx + 0.020, 0.072, lz + 0.013), 0.0036, 0.0036, 6)
				body.capsule_seg("shirt_white", Vector3(sx + 0.020, 0.072, lz), Vector3(sx - 0.020, 0.072, lz + 0.013), 0.0036, 0.0036, 6)

	# 2. Gambe anatomiche slanciate (caviglia -> polpaccio -> ginocchio -> coscia -> anca)
	var calf_k := skin_k if skirt else pants
	for side in [-1.0, 1.0]:
		var sx: float = side * (0.098 if female else 0.108)
		var ankle := Vector3(sx, 0.088, -0.014)
		var mid_calf := Vector3(sx, 0.295, -0.018)
		var knee := Vector3(sx, 0.475, 0.010)
		var mid_thigh := Vector3(sx * 0.94, 0.660, 0.004)
		var hip := Vector3(sx * 0.88, 0.840, 0.0)
		body.capsule_seg(calf_k, ankle, mid_calf, 0.037 if female else 0.044, 0.056 if female else 0.064, 16)
		body.capsule_seg(calf_k, mid_calf, knee, 0.056 if female else 0.064, 0.052 if female else 0.058, 16)
		body.capsule_seg(pants, knee, mid_thigh, 0.055 if female else 0.062, 0.072 if female else 0.081, 16)
		body.capsule_seg(pants, mid_thigh, hip, 0.072 if female else 0.081, 0.078 if female else 0.088, 16)
		if not skirt:
			body.cyl(pants, Vector3(sx, 0.092, -0.012), 0.051, 0.051, 0.024, 14)

	# 3. Bacino / Gonna sartoriale morbida
	if skirt:
		body.lathe_pleated(pants, Vector3(0, 0.47, 0), [
			Vector3(0.004, 0.0, 0.0),
			Vector3(0.194, 0.016, 1.0),
			Vector3(0.184, 0.13, 0.7),
			Vector3(0.166, 0.26, 0.35),
			Vector3(0.144, 0.375, 0.10),
		], 1.14, 0.78, 28, 10, 0.005)
	else:
		body.ellipsoid(pants, Vector3(0, 0.830, 0.0), Vector3(0.172, 0.098, 0.114), 9, 20)

	# 4. Busto anatomico parametrico continuo (senza sfere sovrapposte sul petto!)
	var stretch_x := 1.14 if female else 1.17
	var stretch_z := 0.74 if female else 0.76

	var neck_style: String = str(opts.get("neck_style", ""))
	if neck_style == "":
		if tie_key != "" or vest != "":
			neck_style = "collar"
		elif apron != "" and not female:
			neck_style = "open_v"
		elif shirt.begins_with("hoodie"):
			neck_style = "hoodie"
		elif apron != "" and female:
			neck_style = "crew"
		else:
			neck_style = "collar"

	_add_sculpted_torso(body, shirt, skin_k, female, stretch_x, stretch_z, neck_style == "open_v")

	# Ponte interno spalla contenuto nel giromanica (zero sbuffi a palloncino o compenetrazioni sul gilet!)
	var sh_cap_rad := Vector3(0.028, 0.024, 0.032) if vest != "" else Vector3(0.036, 0.030, 0.038)
	var sh_cap_x := (0.146 if female else 0.162) if vest != "" else (0.152 if female else 0.168)
	var sh_cap_y := 1.218 if vest != "" else 1.224
	for side in [-1.0, 1.0]:
		body.ellipsoid(shirt, Vector3(side * sh_cap_x, sh_cap_y, -0.004), sh_cap_rad, 7, 14)

	# Moncone interno del collo (il collo visibile unico anatomico nasce in _build_head)
	body.capsule_seg(skin_k, Vector3(0, 1.200, -0.004), Vector3(0, 1.275, -0.006), 0.030 if female else 0.036, 0.028 if female else 0.033, 14, false, false)

	if neck_style == "open_v":
		# Revers/colletto camicia aperta a V risvoltato attorno alla nuca e sul petto (ben staccato dalle bretelle)
		for side_v in [-1.0, 1.0]:
			var s_ov: float = float(side_v)
			var p_low := _torso_point(0.765, PI * 0.5 + s_ov * 0.032, female, stretch_x, stretch_z, 0.0045)
			var p_mid := _torso_point(0.860, PI * 0.5 + s_ov * 0.215, female, stretch_x, stretch_z, 0.0075)
			var p_top := _torso_point(0.955, PI * 0.5 + s_ov * 0.390, female, stretch_x, stretch_z, 0.0085)
			var p_nape := _torso_point(0.985, PI * 0.5 + s_ov * 2.550, female, stretch_x, stretch_z, 0.0085)
			body.cloth_strap(shirt, [p_low, p_mid, p_top, p_nape], 0.0175, 0.0048, 8)
		# Cannoncino centrale della camicia sotto lo scollo a V
		body.cloth_strap(shirt, [
			_torso_point(0.50, PI * 0.5, female, stretch_x, stretch_z, 0.0045),
			_torso_point(0.76, PI * 0.5, female, stretch_x, stretch_z, 0.0055),
		], 0.012, 0.0036, 6)
	elif neck_style == "crew":
		# Bordo morbido tono-su-tono del girocollo (es. maglioncino verde di Rosa / burgundy Elena)
		body.lathe_oval(shirt, Vector3(0, 1.298, 0.006), [
			Vector2(0.066 if female else 0.072, 0.0),
			Vector2(0.060 if female else 0.066, 0.020),
			Vector2(0.052 if female else 0.058, 0.032)
		], 1.02, 0.96, 22)
	elif neck_style == "hoodie":
		body.ellipsoid(shirt, Vector3(0, 1.275, -0.048), Vector3(0.118, 0.052, 0.078), 7, 14)
		for side in [-1.0, 1.0]:
			body.capsule_seg("shirt_white", Vector3(side * 0.026, 1.275, 0.105), Vector3(side * 0.032, 1.150, 0.128), 0.004, 0.0035, 6)
	else:
		# Colletto sartoriale nello stesso tessuto della camicia con vele anteriori distese
		var collar_mat := shirt
		body.lathe_oval(collar_mat, Vector3(0, 1.302, 0.006), [
			Vector2(0.072 if female else 0.078, 0.0), Vector2(0.058 if female else 0.064, 0.034)
		], 1.02, 0.94, 22)
		for side in [-1.0, 1.0]:
			var c0 := _torso_point(0.885, PI * 0.5 + side * 0.11, female, stretch_x, stretch_z, 0.008)
			var c1 := _torso_point(0.955, PI * 0.5 + side * 0.34, female, stretch_x, stretch_z, 0.010)
			var c2 := _torso_point(0.990, PI * 0.5 + side * 0.85, female, stretch_x, stretch_z, 0.010)
			body.cloth_strap(collar_mat, [c0, c1, c2], 0.015, 0.006, 8)

	# Placca bottoni camicia (senza gilet né grembiule)
	if apron == "" and vest == "" and neck_style == "collar":
		for ty_b in [0.28, 0.48, 0.68]:
			var pb := _torso_point(ty_b, PI * 0.5, female, stretch_x, stretch_z, 0.004)
			body.ellipsoid("shirt_white", pb, Vector3(0.0065, 0.0065, 0.0035), 4, 8)

	# Cravatta aderente tra camicia (+0.006m) e scollo gilet (+0.014m)
	if tie_key != "":
		var tie_pts: Array = []
		for ty_t in [0.94, 0.83, 0.70, 0.56, 0.44]:
			tie_pts.append(_torso_point(ty_t, PI * 0.5, female, stretch_x, stretch_z, 0.0065))
		body.cloth_strap(tie_key, tie_pts, 0.019, 0.0048, 8)
		var knot_p := _torso_point(0.955, PI * 0.5, female, stretch_x, stretch_z, 0.009)
		body.ellipsoid(tie_key, knot_p, Vector3(0.016, 0.015, 0.010), 5, 10)

	# 5. Gilet / Giacca sartoriale a V realmente aperta sul petto + revers + bottoni + badge complanare
	if vest != "":
		_add_tailored_vest(body, vest, female, stretch_x, stretch_z)

	# Cintura in pelle & fibbia in ottone
	if apron == "":
		body.lathe_oval("leather", Vector3(0, 0.830, 0), [
			Vector2(0.160 if female else 0.164, 0.0), Vector2(0.160 if female else 0.164, 0.036)
		], stretch_x + 0.02, stretch_z + 0.02, 24)
		var bkl_p := _torso_point(0.02, PI * 0.5, female, stretch_x, stretch_z, 0.014)
		body.box(belt_buckle, bkl_p, Vector3(0.044, 0.030, 0.012))

	# 7. Grembiule sartoriale sagomato sul busto, pieghe morbide, bretelle aderenti & tasca curva
	if apron != "":
		var ap_mat := "apron_white" if apron == "white" else apron
		_add_contoured_apron_bib(body, ap_mat, female, stretch_x, stretch_z)
		# Bretelle morbide che salgono dai vertici della pettorina lungo le clavicole dietro il collo (chiaro stacco dal colletto!)
		for side in [-1.0, 1.0]:
			var s_f: float = float(side)
			var th_front: float = PI * 0.5 + s_f * (0.29 if female else 0.32)
			var th_clav: float = PI * 0.5 + s_f * (0.50 if female else 0.54)
			var th_peak: float = PI * 0.5 + s_f * 1.18
			var th_back1: float = PI * 0.5 + s_f * 2.25
			var th_back2: float = PI * 0.5 + s_f * 2.75
			body.cloth_strap(ap_mat, [
				_torso_point(0.715, th_front, female, stretch_x, stretch_z, 0.0150),
				_torso_point(0.925, th_clav, female, stretch_x, stretch_z, 0.0150),
				_torso_point(0.985, th_peak, female, stretch_x, stretch_z, 0.0135) + Vector3(0.0, 0.006, 0.0),
				_torso_point(0.830, th_back1, female, stretch_x, stretch_z, 0.0135),
				_torso_point(0.420, th_back2, female, stretch_x, stretch_z, 0.0135),
			], 0.012, 0.0036, 8)
		# Gonna grembiule plissettata con cintura aderente e tasca frontale morbida (solo orlo superiore cucito, zero riquadro wireframe)
		var bottom_r := 0.212 if skirt else 0.184
		var waist_ap_r := 0.168 if skirt else 0.153
		body.lathe_pleated(ap_mat, Vector3(0, 0.51, 0.014), [
			Vector3(bottom_r, 0.00, 1.0),
			Vector3(lerpf(bottom_r, waist_ap_r, 0.45), 0.18, 0.65),
			Vector3(waist_ap_r, 0.36, 0.28),
			Vector3(waist_ap_r * 0.96, 0.435, 0.08),
		], 1.16, 0.81, 28, 12, 0.0065)
		body.lathe_oval(ap_mat, Vector3(0, 0.935, 0.013), [
			Vector2(waist_ap_r * 0.98, 0.0), Vector2(waist_ap_r * 0.98, 0.040)
		], 1.16, 0.81, 24)
		body.ellipsoid(ap_mat, Vector3(0, 0.952, -0.130), Vector3(0.022, 0.016, 0.014), 5, 10)
		for side in [-1.0, 1.0]:
			body.cloth_strap(ap_mat, [
				Vector3(0, 0.948, -0.134),
				Vector3(side * 0.026, 0.860, -0.148),
				Vector3(side * 0.044, 0.770, -0.144),
			], 0.011, 0.0035, 6)
		var pr_mid := lerpf(bottom_r, waist_ap_r, 0.64) + 0.008
		var p_pts_top: Array = []
		var p_pts_bot: Array = []
		for pk in range(7):
			var u := float(pk) / 6.0
			var th_p := PI * 0.5 + (u - 0.5) * 0.50
			var px := cos(th_p) * pr_mid * 1.16
			var pz := sin(th_p) * pr_mid * 0.81 + 0.016
			p_pts_top.append(Vector3(px, 0.810, pz))
			p_pts_bot.append(Vector3(px * 0.98, 0.728, pz + 0.001))
		for pk in range(6):
			body.quad(ap_mat, p_pts_bot[pk], p_pts_bot[pk + 1], p_pts_top[pk + 1], p_pts_top[pk])
		body.cloth_strap(ap_mat, p_pts_top, 0.0042, 0.0020, 6)

	var body_mi := MeshInstance3D.new()
	body_mi.name = "BodyMesh"
	body_mi.mesh = body.to_mesh(Callable(VillageMaterials, "mat"))
	body_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	root.add_child(body_mi)

	# Pivot Testa al collo (preserva HeadPivot esatto per AnimationPlayer)
	var head_pivot := Node3D.new()
	head_pivot.name = "HeadPivot"
	head_pivot.position = Vector3(0, 1.32, 0)
	root.add_child(head_pivot)
	_build_head(head_pivot, opts, Vector3.ZERO)

	# 8. Braccia articolate con posa naturale rilassata, spalla scivolata anatomica e mano scolpita 5 dita
	var sleeve: String = opts.get("sleeve", shirt)
	var rolled := bool(opts.get("rolled_sleeves", false))
	var short_slv := bool(opts.get("short_sleeves", false))
	var bare_forearm := rolled or short_slv
	var forearm_mat := skin_k if bare_forearm else sleeve
	var sh_x := 0.156 if female else 0.172
	var sh_y := 1.226 if female else 1.238
	for side in [-1.0, 1.0]:
		var arm_pivot := Node3D.new()
		arm_pivot.name = "ArmLPivot" if side < 0 else "ArmRPivot"
		arm_pivot.position = Vector3(side * sh_x, sh_y, -0.006)
		root.add_child(arm_pivot)

		var arm_sm := StyleMesh.new()
		var shoulder := Vector3.ZERO
		var arm_start := Vector3(0.0, -0.010, 0.0)
		var elbow := Vector3(side * 0.024, -0.214, -0.014)
		var wrist := Vector3(side * 0.016, -0.436, 0.056)
		var palm := Vector3(side * 0.012, -0.478, 0.078)

		var r_sh := 0.038 if female else 0.044
		var r_elb := 0.035 if female else 0.041
		var r_wri := 0.024 if female else 0.028

		var cap_rad := Vector3(0.030, 0.026, 0.032) if vest != "" else Vector3(0.037, 0.033, 0.039)
		arm_sm.ellipsoid(sleeve, shoulder + Vector3(-side * 0.012, -0.018, 0.0), cap_rad, 6, 12)
		if short_slv:
			var mid_arm := arm_start.lerp(elbow, 0.62)
			var r_mid := lerpf(r_sh, r_elb, 0.62)
			arm_sm.capsule_seg(sleeve, arm_start, mid_arm, r_sh, r_mid + 0.004, 16)
			arm_sm.capsule_seg(sleeve, arm_start.lerp(elbow, 0.56), arm_start.lerp(elbow, 0.65), r_mid + 0.007, r_mid + 0.007, 14)
			arm_sm.capsule_seg(skin_k, mid_arm, elbow, r_mid * 0.90, r_elb * 0.94, 16)
		else:
			arm_sm.capsule_seg(sleeve, arm_start, elbow, r_sh, r_elb, 16)

		arm_sm.capsule_seg(forearm_mat, elbow, wrist, r_elb * (0.94 if bare_forearm else 0.98), r_wri * (0.94 if bare_forearm else 1.0), 16)
		if rolled and not short_slv:
			arm_sm.capsule_seg(sleeve, elbow, elbow.lerp(wrist, 0.22), r_elb + 0.005, r_elb + 0.004, 14)
			arm_sm.capsule_seg(sleeve, elbow.lerp(wrist, 0.16), elbow.lerp(wrist, 0.25), r_elb + 0.008, r_elb + 0.007, 14)
		elif not bare_forearm:
			arm_sm.capsule_seg(sleeve, elbow.lerp(wrist, 0.84), wrist, r_wri + 0.004, r_wri + 0.003, 14)

		_add_sculpted_hand(arm_sm, skin_k, palm, side, false)

		var ami := MeshInstance3D.new()
		ami.name = "Mesh"
		ami.mesh = arm_sm.to_mesh(Callable(VillageMaterials, "mat"))
		ami.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		arm_pivot.add_child(ami)

	_attach_npc_animations(root, false)

static func _torso_base_radius(ty: float, female: bool) -> float:
	var stops_t := [0.00, 0.22, 0.45, 0.68, 0.85, 0.94, 1.00]
	var stops_f := [0.150, 0.123, 0.138, 0.156, 0.152, 0.112, 0.064]
	var stops_m := [0.160, 0.148, 0.164, 0.184, 0.180, 0.128, 0.072]
	var arr := stops_f if female else stops_m
	var ct := clampf(ty, 0.0, 1.0)
	for i in range(stops_t.size() - 1):
		if ct <= stops_t[i + 1]:
			var seg_t: float = (ct - stops_t[i]) / maxf(stops_t[i + 1] - stops_t[i], 0.0001)
			var sm_t: float = seg_t * seg_t * (3.0 - 2.0 * seg_t)
			return lerpf(arr[i], arr[i + 1], sm_t)
	return arr[arr.size() - 1]

static func _torso_point(ty: float, th: float, female: bool, sx: float, sz: float, radial_off: float = 0.0) -> Vector3:
	var r_base := _torso_base_radius(ty, female) + radial_off
	var nx := cos(th)
	var nz := sin(th)
	var front := clampf((nz - 0.08) / 0.85, 0.0, 1.0)
	front = front * front * (3.0 - 2.0 * front)
	var bust_belt := exp(-pow((ty - 0.63) / 0.175, 2.0))
	var bust_push := 0.0
	if female:
		var lobe := 0.78 + 0.22 * exp(-pow((absf(nx) - 0.42) / 0.28, 2.0))
		bust_push = 0.024 * front * bust_belt * lobe
	else:
		bust_push = 0.011 * front * bust_belt
	var back := clampf((-nz - 0.15) / 0.75, 0.0, 1.0)
	back = back * back * (3.0 - 2.0 * back)
	var back_curve := -0.010 * back * exp(-pow((ty - 0.24) / 0.16, 2.0)) + 0.008 * back * exp(-pow((ty - 0.76) / 0.16, 2.0))
	var y := lerpf(0.835, 1.325, ty)
	return Vector3(nx * r_base * sx, y, nz * r_base * sz + bust_push + back_curve)

static func _torso_out_normal(ty: float, th: float, sx: float, sz: float) -> Vector3:
	var n := Vector3(cos(th) / maxf(sx, 0.01), 0.0, sin(th) / maxf(sz, 0.01))
	return n.normalized()

static func _add_sculpted_torso(sm: StyleMesh, mat_key: String, skin_k: String, female: bool, sx: float, sz: float, open_v: bool) -> void:
	var rows := 16
	var cols := 28
	var s := sm._s(mat_key)
	var base: int = s["v"].size()
	var start_i: int = s["i"].size()
	var stride := cols + 1
	for r in range(rows):
		var ty := float(r) / float(rows - 1)
		for k in range(stride):
			var th := TAU * float(k) / float(cols)
			var rad_off := 0.0
			if open_v and ty > 0.72:
				var ang_front := absf(wrapf(th - PI * 0.5, -PI, PI))
				var v_w := lerpf(0.04, 0.46, clampf((ty - 0.72) / 0.26, 0.0, 1.0))
				if ang_front < v_w:
					rad_off = -0.005 * (1.0 - ang_front / maxf(v_w, 0.01))
			var p := _torso_point(ty, th, female, sx, sz, rad_off)
			s["v"].append(p)
			s["n"].append(_torso_out_normal(ty, th, sx, sz))
			s["uv"].append(Vector2(float(k) / float(cols), ty * 0.85))
	for r in range(rows - 1):
		for k in range(cols):
			var i0 := base + r * stride + k
			var i1 := i0 + 1
			var i2 := i0 + stride
			var i3 := i2 + 1
			s["i"].append_array([i0, i1, i2, i1, i3, i2])
	sm._recompute_smooth_grid_normals(s, base, rows, stride, start_i, true)

	if open_v:
		# Inserto anatomico in pelle nella scollatura aperta a V (+0.002m sopra la camicia incavata)
		var v_rows := 7
		var v_cols := 8
		var sv := sm._s(skin_k)
		var v_base: int = sv["v"].size()
		var v_start_i: int = sv["i"].size()
		var v_stride := v_cols + 1
		for vr in range(v_rows):
			var ft := float(vr) / float(v_rows - 1)
			var ty := lerpf(0.730, 0.995, ft)
			var spread := lerpf(0.05, 0.43, ft)
			for vk in range(v_stride):
				var u := float(vk) / float(v_cols)
				var th := PI * 0.5 + (u - 0.5) * 2.0 * spread
				var p := _torso_point(ty, th, female, sx, sz, 0.003)
				sv["v"].append(p)
				sv["n"].append(_torso_out_normal(ty, th, sx, sz))
				sv["uv"].append(Vector2(u * 0.4, ft * 0.4))
		for vr in range(v_rows - 1):
			for vk in range(v_cols):
				var i0 := v_base + vr * v_stride + vk
				var i1 := i0 + 1
				var i2 := i0 + v_stride
				var i3 := i2 + 1
				sv["i"].append_array([i0, i1, i2, i1, i3, i2])
		sm._recompute_smooth_grid_normals(sv, v_base, v_rows, v_stride, v_start_i, false)

static func _add_contoured_apron_bib(sm: StyleMesh, ap_mat: String, female: bool, sx: float, sz: float) -> void:
	# Pannello pettorale sagomato con normali verso +Z (u crescente = +X -> -X, r crescente = +Y!)
	var rows := 10
	var cols := 16
	var ty0 := (0.945 - 0.835) / 0.490
	var ty1 := (1.190 - 0.835) / 0.490
	var spread0 := 0.88 if female else 0.92
	var spread1 := 0.30 if female else 0.33
	var s := sm._s(ap_mat)
	var base: int = s["v"].size()
	var start_i: int = s["i"].size()
	var stride := cols + 1
	for r in range(rows):
		var t := float(r) / float(rows - 1)
		var ty := lerpf(ty0, ty1, t)
		var spread := lerpf(spread0, spread1, t * (0.55 + 0.45 * t))
		for k in range(stride):
			var u := float(k) / float(cols)
			var th := PI * 0.5 + (u - 0.5) * 2.0 * spread
			var fold := 0.0028 * cos((u - 0.5) * PI * 4.0) * sin(t * PI)
			var edge_hem := 0.002 * (1.0 - sin(u * PI))
			var p := _torso_point(ty, th, female, sx, sz, 0.014 + fold + edge_hem)
			s["v"].append(p)
			s["n"].append(_torso_out_normal(ty, th, sx, sz))
			s["uv"].append(Vector2(u * 0.85, t * 0.72))
	for r in range(rows - 1):
		for k in range(cols):
			var i0 := base + r * stride + k
			var i1 := i0 + 1
			var i2 := i0 + stride
			var i3 := i2 + 1
			s["i"].append_array([i0, i1, i2, i1, i3, i2])
	sm._recompute_smooth_grid_normals(s, base, rows, stride, start_i, false)

	# Orlo superiore cucito del grembiule
	var top_pts: Array = []
	for k in range(9):
		var u := float(k) / 8.0
		var th := PI * 0.5 + (u - 0.5) * 2.0 * spread1
		top_pts.append(_torso_point(ty1, th, female, sx, sz, 0.015))
	sm.cloth_strap(ap_mat, top_pts, 0.0085, 0.0040, 7)

static func _add_tailored_vest(sm: StyleMesh, vest: String, female: bool, sx: float, sz: float) -> void:
	# Gilet avvolgente con vero scollo a V frontale aperto e spalle coperte aderenti
	var rows := 13
	var cols := 28
	var s := sm._s(vest)
	var base: int = s["v"].size()
	var start_i: int = s["i"].size()
	var stride := cols + 1
	for r in range(rows):
		var rt := float(r) / float(rows - 1)
		var ty := lerpf(0.04, 0.97, rt)
		var split_t := clampf((ty - 0.50) / 0.47, 0.0, 1.0)
		var v_half := 0.0 if split_t <= 0.001 else lerpf(0.012, 0.48, pow(split_t, 0.85))
		var th_start := PI * 0.5 + v_half
		var th_end := PI * 2.5 - v_half
		for k in range(stride):
			var u := float(k) / float(cols)
			var th := lerpf(th_start, th_end, u)
			var p := _torso_point(ty, th, female, sx, sz, 0.0135)
			s["v"].append(p)
			s["n"].append(_torso_out_normal(ty, th, sx, sz))
			s["uv"].append(Vector2(u, rt * 0.85))
	for r in range(rows - 1):
		for k in range(cols):
			var i0 := base + r * stride + k
			var i1 := i0 + 1
			var i2 := i0 + stride
			var i3 := i2 + 1
			s["i"].append_array([i0, i1, i2, i1, i3, i2])
	sm._recompute_smooth_grid_normals(s, base, rows, stride, start_i, false)

	# Chiusura centrale cucita sulla parte inferiore del gilet (zero fessura verticale)
	var seam_pts: Array = []
	for ti in [0.05, 0.20, 0.35, 0.50]:
		seam_pts.append(_torso_point(float(ti), PI * 0.5, female, sx, sz, 0.015))
	sm.cloth_strap(vest, seam_pts, 0.013, 0.0038, 8)

	# Coprispalla sartoriale + revers lungo i margini dello scollo a V
	for side_v in [-1.0, 1.0]:
		var side: float = float(side_v)
		var lapel_pts: Array = []
		for li in range(5):
			var split_t: float = float(li) / 4.0
			var ty: float = lerpf(0.50, 0.965, split_t)
			var v_half: float = lerpf(0.008, 0.48, pow(split_t, 0.85))
			var th: float = PI * 0.5 + side * v_half
			lapel_pts.append(_torso_point(ty, th, female, sx, sz, 0.0165))
		lapel_pts.append(_torso_point(0.975, PI * 0.5 + side * 2.0, female, sx, sz, 0.0155))
		sm.cloth_strap(vest, lapel_pts, 0.017, 0.006, 8)
		sm.cloth_strap(vest, [
			_torso_point(0.84, PI * 0.5 + side * 1.15, female, sx, sz, 0.0155),
			_torso_point(0.92, PI * 0.5 + side * 1.38, female, sx, sz, 0.0160),
			_torso_point(0.90, PI * 0.5 + side * 1.72, female, sx, sz, 0.0155),
			_torso_point(0.82, PI * 0.5 + side * 1.98, female, sx, sz, 0.0150),
		], 0.024, 0.0055, 8)

	# 3 bottoni lungo la chiusura inferiore del gilet
	for ty_b in [0.13, 0.27, 0.41]:
		var bp := _torso_point(float(ty_b), PI * 0.5, female, sx, sz, 0.017)
		sm.ellipsoid("glass_frame", bp, Vector3(0.0072, 0.0072, 0.0042), 4, 8)

	# Badge identificativo perfettamente complanare sul petto sinistro
	var th_badge := PI * 0.5 + 0.52
	var badge_p := _torso_point(0.71, th_badge, female, sx, sz, 0.017)
	var badge_n := _torso_out_normal(0.71, th_badge, sx, sz)
	var badge_rot := atan2(badge_n.x, badge_n.z)
	sm.box("shirt_white", badge_p, Vector3(0.044, 0.028, 0.006), {"rot": badge_rot})
	sm.box("badge_cyan", badge_p + badge_n * 0.004 + Vector3(0.0, 0.0065, 0.0), Vector3(0.038, 0.007, 0.0025), {"rot": badge_rot})

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
		body.ellipsoid("shoe_black", Vector3(sx, 0.046, 0.360), Vector3(0.054, 0.036, 0.110), 6, 14)
		body.capsule_seg("shirt_white", Vector3(sx - 0.018, 0.070, 0.365), Vector3(sx + 0.018, 0.070, 0.382), 0.0036, 0.0036, 6)
		body.capsule_seg(pants, Vector3(sx, 0.07, 0.33), Vector3(sx, 0.470, 0.31), 0.044, 0.058, 14)
		body.capsule_seg(pants, Vector3(sx * 0.90, 0.482, 0.02), Vector3(sx, 0.475, 0.31), 0.070, 0.058, 14)

	body.ellipsoid(pants, Vector3(0, 0.492, 0.0), Vector3(0.164, 0.084, 0.120), 8, 18)

	var chest_r := 0.160 if female else 0.180
	body.lathe_oval(shirt, Vector3(0, 0.505, 0.015), [
		Vector2(0.148, 0.00),
		Vector2(0.142, 0.11),
		Vector2(chest_r, 0.31),
		Vector2(0.164, 0.41),
		Vector2(0.112, 0.46),
		Vector2(0.066, 0.495),
	], 1.15, 0.75, 24)
	body.capsule_seg(skin_k, Vector3(0, 0.900, 0.020), Vector3(0, 0.955, 0.016), 0.032, 0.031, 14, false, false)
	if shirt.begins_with("hoodie"):
		body.ellipsoid(shirt, Vector3(0, 0.935, -0.068), Vector3(0.118, 0.052, 0.082), 7, 14)
		for side in [-1.0, 1.0]:
			body.capsule_seg("shirt_white", Vector3(side * 0.026, 0.940, 0.115), Vector3(side * 0.032, 0.825, 0.135), 0.0038, 0.0034, 6)
	else:
		body.lathe_oval(shirt, Vector3(0, 0.955, 0.020), [Vector2(0.070, 0.0), Vector2(0.060, 0.032)], 1.0, 0.94, 18)

	var body_mi := MeshInstance3D.new()
	body_mi.name = "BodyMesh"
	body_mi.mesh = body.to_mesh(Callable(VillageMaterials, "mat"))
	body_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	root.add_child(body_mi)

	var head_pivot := Node3D.new()
	head_pivot.name = "HeadPivot"
	head_pivot.position = Vector3(0, 0.990, 0.016)
	root.add_child(head_pivot)
	_build_head(head_pivot, opts, Vector3.ZERO)

	for side in [-1.0, 1.0]:
		var arm_pivot := Node3D.new()
		arm_pivot.name = "ArmLPivot" if side < 0 else "ArmRPivot"
		arm_pivot.position = Vector3(side * 0.168, 0.892, 0.016)
		root.add_child(arm_pivot)

		var arm_sm := StyleMesh.new()
		var shoulder := Vector3.ZERO
		var arm_start := Vector3(0.0, -0.008, 0.0)
		var elbow := Vector3(side * 0.040, -0.142, 0.12)
		var wrist := Vector3(-side * 0.036, -0.100, 0.34)
		var palm := Vector3(-side * 0.052, -0.108, 0.382)
		arm_sm.ellipsoid(shirt, shoulder + Vector3(-side * 0.010, -0.014, 0.0), Vector3(0.036, 0.032, 0.038), 6, 12)
		arm_sm.capsule_seg(shirt, arm_start, elbow, 0.039, 0.036, 14)
		arm_sm.capsule_seg(shirt, elbow, wrist, 0.035, 0.028, 14)
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
		sm.ellipsoid(skin_k, palm_c, Vector3(0.026, 0.012, 0.032), 6, 12)
		sm.capsule_seg(skin_k, palm_c + Vector3(-side * 0.021, -0.002, -0.006),
			palm_c + Vector3(-side * 0.033, -0.008, 0.024), 0.0068, 0.0056, 8)
		var lengths := [0.040, 0.046, 0.042, 0.033]
		for fi in range(4):
			var fx := (float(fi) - 1.5) * 0.0115 * (-side)
			var base_p := palm_c + Vector3(fx, 0.002, 0.028)
			var mid_p := base_p + Vector3(0.0, 0.001, lengths[fi] * 0.55)
			var tip_p := mid_p + Vector3(0.0, -0.011, lengths[fi] * 0.45)
			sm.capsule_seg(skin_k, base_p, mid_p, 0.0056, 0.0050, 7)
			sm.capsule_seg(skin_k, mid_p, tip_p, 0.0049, 0.0042, 7)
	else:
		sm.ellipsoid(skin_k, palm_c, Vector3(0.016, 0.032, 0.025), 6, 12, Vector3(0.18, 0.0, -side * 0.06))
		var th_base := palm_c + Vector3(-side * 0.011, 0.008, 0.015)
		var th_tip := th_base + Vector3(-side * 0.008, -0.022, 0.016)
		sm.capsule_seg(skin_k, th_base, th_tip, 0.0066, 0.0052, 8)
		var lengths := [0.042, 0.048, 0.044, 0.034]
		for fi in range(4):
			var fz := (1.5 - float(fi)) * 0.0112
			var base_p := palm_c + Vector3(0.0, -0.024, fz)
			var mid_p := base_p + Vector3(-side * 0.007, -lengths[fi] * 0.56, 0.004)
			var tip_p := mid_p + Vector3(-side * 0.015, -lengths[fi] * 0.44, -0.002)
			sm.capsule_seg(skin_k, base_p, mid_p, 0.0054, 0.0048, 7)
			sm.capsule_seg(skin_k, mid_p, tip_p, 0.0047, 0.0040, 7)

# ------------------------------------------------------------------ TESTA & VOLTO SEMI-REALISTICO SCOLPITO
static func _build_head(head_pivot: Node3D, opts: Dictionary, origin: Vector3) -> void:
	var skin_k: String = opts.get("skin", "skin")
	var hair_k: String = opts.get("hair", "hair_brown")
	var iris_k: String = opts.get("iris", "iris_brown")
	var hair_style: String = opts.get("hair_style", "short")
	var hat: String = opts.get("hat", "")
	var mustache: bool = bool(opts.get("mustache", false))
	var glasses: bool = bool(opts.get("glasses", false))
	var female: bool = bool(opts.get("female", false))
	var lip_k: String = opts.get("lip", "lip_rose" if female else "lip_warm")

	var sm := StyleMesh.new()
	# Collo anatomico arretrato rispetto al mento (stacco netto mascella-collo e svasatura sul trapezio)
	var nf: float = 0.86 if female else 0.96
	sm.lathe_oval(skin_k, origin + Vector3(0, -0.046, -0.008), [
		Vector2(0.060 * nf, 0.000),
		Vector2(0.048 * nf, 0.042),
		Vector2(0.044 * nf, 0.088),
		Vector2(0.048 * nf, 0.130),
	], 1.00, 0.94, 24)

	# Testa scolpita proporzionata al busto (mento ben definito e leggermente sporgente sopra il collo)
	var radii := Vector3(0.095, 0.123, 0.106) if female else Vector3(0.102, 0.129, 0.114)
	var hc := origin + Vector3(0, 0.168, 0.014)
	sm.sculpt_head_mesh(skin_k, hc, radii, 36, 24, female)

	var rx := radii.x
	var ry := radii.y
	var rz := radii.z

	# Leggero rossore naturale sulle guance (sotto-piano sfumato)
	for side_v in [-1.0, 1.0]:
		var side: float = float(side_v)
		sm.ellipsoid("skin_cheek", hc + Vector3(side * 0.44 * rx, -0.05 * ry, 0.78 * rz), Vector3(0.019, 0.009, 0.004), 5, 10, Vector3(0, side * 0.40, 0))

	# Orecchie anatomiche (elice + conca)
	var ear_x := 0.96 * rx
	for side_v in [-1.0, 1.0]:
		var side: float = float(side_v)
		sm.ellipsoid(skin_k, hc + Vector3(side * ear_x, -0.02 * ry, -0.05 * rz), Vector3(0.012, 0.026, 0.018), 7, 12, Vector3(0.08, side * 0.28, -side * 0.10))
		sm.ellipsoid("skin_crevice", hc + Vector3(side * (ear_x + 0.003), -0.03 * ry, -0.04 * rz), Vector3(0.006, 0.013, 0.008), 5, 10)

	# Naso scolpito realistico: ponte slanciato + punta raffinata + ali nasali contenute
	sm.capsule_seg(skin_k, hc + Vector3(0, 0.11 * ry, 0.875 * rz), hc + Vector3(0, -0.098 * ry, 1.005 * rz), 0.0052, 0.0064, 12)
	sm.ellipsoid(skin_k, hc + Vector3(0, -0.118 * ry, 1.005 * rz), Vector3(0.0084 if not female else 0.0072, 0.0068, 0.0094), 6, 12)
	for side_v in [-1.0, 1.0]:
		var side: float = float(side_v)
		sm.ellipsoid(skin_k, hc + Vector3(side * 0.0068, -0.138 * ry, 0.945 * rz), Vector3(0.0046, 0.0045, 0.0056), 5, 10)

	# Sopracciglia sempre leggibili ma naturali
	var brow_k := "hair_brown" if (hair_k == "hair_blonde" or hair_k == "hair_auburn" or hair_k == "hair_chestnut") else ("hair_salt" if hair_k == "hair_salt" else "eyebrow_dark")

	# Occhi umani espressivi e distesi (~9.4mm apertura visibile, iride leggibile su sclera a mandorla)
	for side_v in [-1.0, 1.0]:
		var s_f: float = float(side_v)
		var ex: float = s_f * 0.345 * rx
		var ey: float = 0.062 * ry
		var ez: float = 0.778 * rz
		var yaw: float = s_f * 0.06

		# Sclera a mandorla naturale (mostra angoli caldi ai lati dell'iride)
		sm.ellipsoid("eye_white", hc + Vector3(ex, ey, ez), Vector3(0.122 * rx, 0.058 * ry, 0.088 * rz), 8, 14, Vector3(0, yaw, 0))
		# Anello limbale + iride proporzionata + pupilla centrata in asse + micro-riflesso corneale
		sm.ellipsoid("limbal_dark", hc + Vector3(ex, ey, ez + 0.068 * rz), Vector3(0.0072, 0.0072, 0.0036), 6, 12, Vector3(0, yaw * 0.3, 0))
		sm.ellipsoid(iris_k, hc + Vector3(ex, ey, ez + 0.075 * rz), Vector3(0.0066, 0.0066, 0.0035), 6, 12, Vector3(0, yaw * 0.2, 0))
		sm.ellipsoid("limbal_dark", hc + Vector3(ex, ey, ez + 0.083 * rz), Vector3(0.0032, 0.0032, 0.0028), 5, 10, Vector3(0, yaw * 0.2, 0))
		sm.ellipsoid("eye_glint", hc + Vector3(ex + 0.0018, ey + 0.0020, ez + 0.091 * rz), Vector3(0.0013, 0.0013, 0.0010), 4, 8)

		# Palpebra superiore naturale posata sul 15% superiore dell'iride + linea cigliare sottile
		sm.capsule_seg(skin_k, hc + Vector3(ex - 0.0132, ey + 0.0044, ez + 0.072 * rz), hc + Vector3(ex, ey + 0.0072, ez + 0.092 * rz), 0.0022, 0.0024, 8)
		sm.capsule_seg(skin_k, hc + Vector3(ex, ey + 0.0072, ez + 0.092 * rz), hc + Vector3(ex + 0.0132, ey + 0.0044, ez + 0.072 * rz), 0.0024, 0.0022, 8)
		sm.capsule_seg("eyebrow_dark", hc + Vector3(ex - 0.0124, ey + 0.0036, ez + 0.082 * rz), hc + Vector3(ex, ey + 0.0056, ez + 0.096 * rz), 0.00075, 0.00075, 6)
		sm.capsule_seg("eyebrow_dark", hc + Vector3(ex, ey + 0.0056, ez + 0.096 * rz), hc + Vector3(ex + 0.0124, ey + 0.0036, ez + 0.082 * rz), 0.00075, 0.00075, 6)

		# Palpebra inferiore leggera sotto l'iride
		sm.capsule_seg(skin_k, hc + Vector3(ex - 0.0120, ey - 0.0050, ez + 0.072 * rz), hc + Vector3(ex, ey - 0.0066, ez + 0.090 * rz), 0.0017, 0.0018, 7)
		sm.capsule_seg(skin_k, hc + Vector3(ex, ey - 0.0066, ez + 0.090 * rz), hc + Vector3(ex + 0.0120, ey - 0.0050, ez + 0.072 * rz), 0.0018, 0.0017, 7)

		# Sopracciglia arcuate lungo l'arcata orbitaria ben visibili e distese (zero compenetrazione interna!)
		var by_in := (0.212 if female else 0.208) * ry
		var by_mid := (0.244 if female else 0.236) * ry
		var by_out := (0.216 if female else 0.206) * ry
		var bz_in := (0.930 if female else 0.942) * rz
		var bz_mid := (0.900 if female else 0.912) * rz
		var bz_out := (0.816 if female else 0.822) * rz
		var br_in := 0.0020 if female else 0.0024
		var br_mid := 0.0019 if female else 0.0022
		var br_out := 0.0012 if female else 0.0014
		sm.capsule_seg(brow_k, hc + Vector3(ex - 0.0155 * s_f, by_in, bz_in), hc + Vector3(ex + 0.001 * s_f, by_mid, bz_mid), br_in, br_mid, 7)
		sm.capsule_seg(brow_k, hc + Vector3(ex + 0.001 * s_f, by_mid, bz_mid), hc + Vector3(ex + 0.0155 * s_f, by_out, bz_out), br_mid, br_out, 7)

	# Bocca naturale distesa con angoli adagiati sulla curvatura del volto (zero affossamento ai lati!)
	for side_v in [-1.0, 1.0]:
		var side: float = float(side_v)
		sm.capsule_seg(lip_k, hc + Vector3(0.0, -0.382 * ry, 0.906 * rz), hc + Vector3(side * 0.0095, -0.377 * ry, 0.898 * rz), 0.0022, 0.0019, 8)
		sm.capsule_seg(lip_k, hc + Vector3(side * 0.0095, -0.377 * ry, 0.898 * rz), hc + Vector3(side * 0.0185, -0.362 * ry, 0.880 * rz), 0.0019, 0.0013, 8)
		sm.capsule_seg("skin_crevice", hc + Vector3(0.0, -0.391 * ry, 0.903 * rz), hc + Vector3(side * 0.0092, -0.385 * ry, 0.895 * rz), 0.0006, 0.00055, 6)
		sm.capsule_seg("skin_crevice", hc + Vector3(side * 0.0092, -0.385 * ry, 0.895 * rz), hc + Vector3(side * 0.0180, -0.369 * ry, 0.878 * rz), 0.00055, 0.00045, 6)
	sm.ellipsoid(lip_k, hc + Vector3(0.0, -0.405 * ry, 0.895 * rz), Vector3(0.0130, 0.0036, 0.0046), 5, 12)

	# Baffi curati e compatti sopra il labbro superiore (Mario, Bruno & Bellini)
	if mustache:
		for side_v in [-1.0, 1.0]:
			var side: float = float(side_v)
			sm.tube_path(hair_k, [
				hc + Vector3(0.0, -0.252 * ry, 0.962 * rz),
				hc + Vector3(side * 0.013, -0.264 * ry, 0.942 * rz),
				hc + Vector3(side * 0.024, -0.296 * ry, 0.896 * rz),
			], [0.0052, 0.0058, 0.0024], 10, true)

	# Occhiali sottili centrati sulle orbite (lasciano occhi e iridi ben leggibili)
	if glasses:
		var gz := 1.030 * rz
		var gy_top := 0.138 * ry
		var gy_bot := -0.042 * ry
		var gr := 0.0013
		for sx_g in [-0.345 * rx, 0.345 * rx]:
			sm.capsule_seg("glass_frame", hc + Vector3(sx_g - 0.018, gy_top, gz), hc + Vector3(sx_g + 0.018, gy_top, gz), gr, gr, 6)
			sm.capsule_seg("glass_frame", hc + Vector3(sx_g - 0.018, gy_bot, gz), hc + Vector3(sx_g + 0.018, gy_bot, gz), gr, gr, 6)
			sm.capsule_seg("glass_frame", hc + Vector3(sx_g - 0.018, gy_top, gz), hc + Vector3(sx_g - 0.018, gy_bot, gz), gr, gr, 6)
			sm.capsule_seg("glass_frame", hc + Vector3(sx_g + 0.018, gy_top, gz), hc + Vector3(sx_g + 0.018, gy_bot, gz), gr, gr, 6)
		sm.capsule_seg("glass_frame", hc + Vector3(-0.014, 0.082 * ry, gz + 0.002), hc + Vector3(0.014, 0.082 * ry, gz + 0.002), gr, gr, 6)
		for side_v in [-1.0, 1.0]:
			var side: float = float(side_v)
			sm.capsule_seg("glass_frame", hc + Vector3(side * 0.052, 0.082 * ry, gz - 0.003), hc + Vector3(side * (ear_x - 0.002), 0.065 * ry, -0.02 * rz), gr, gr, 6)

	# Capigliatura volumetrica scolpita senza compenetrazioni sulla fronte
	_add_hair(sm, hair_k, hc, radii, hair_style, hat)

	# Copricapi sartoriali plissettati & caschetto sicurezza (compenetrati nella fascia senza fessure scure!)
	if hat == "chef":
		var chef_rot := Vector3(-0.08, 0.0, 0.02)
		sm.lathe_pleated("apron_white", hc + Vector3(0, 0.43 * ry, -0.020), [
			Vector3(0.95 * rx, -0.005, 0.0), Vector3(1.03 * rx, 0.010, 0.0), Vector3(1.04 * rx, 0.044, 0.0)
		], 1.02, 1.08, 28, 12, 0.0, chef_rot)
		sm.lathe_pleated("apron_white", hc + Vector3(0, 0.43 * ry + 0.022, -0.022), [
			Vector3(1.02 * rx, 0.000, 0.14),
			Vector3(1.22 * rx, 0.042, 0.80),
			Vector3(1.36 * rx, 0.088, 1.00),
			Vector3(1.22 * rx, 0.132, 0.68),
			Vector3(0.78 * rx, 0.156, 0.25),
			Vector3(0.04 * rx, 0.168, 0.00),
		], 1.02, 1.07, 36, 16, 0.0085, chef_rot)
	elif hat == "baker":
		var baker_rot := Vector3(-0.10, 0.0, -0.10)
		sm.lathe_pleated("apron_cream", hc + Vector3(0, 0.41 * ry, -0.020), [
			Vector3(0.95 * rx, -0.005, 0.0), Vector3(1.03 * rx, 0.008, 0.0), Vector3(1.04 * rx, 0.034, 0.0)
		], 1.02, 1.10, 28, 12, 0.0, baker_rot)
		sm.lathe_pleated("apron_cream", hc + Vector3(0.005, 0.41 * ry + 0.016, -0.022), [
			Vector3(1.02 * rx, 0.000, 0.20),
			Vector3(1.24 * rx, 0.028, 0.82),
			Vector3(1.29 * rx, 0.058, 1.00),
			Vector3(0.98 * rx, 0.084, 0.48),
			Vector3(0.06 * rx, 0.096, 0.00),
		], 1.04, 1.11, 34, 14, 0.0050, baker_rot)
	elif hat == "hardhat":
		sm.lathe_oval("safety_yellow", hc + Vector3(0, 0.45 * ry, -0.006), [
			Vector2(1.02 * rx, -0.005), Vector2(1.11 * rx, 0.012), Vector2(1.12 * rx, 0.032),
			Vector2(0.98 * rx, 0.068), Vector2(0.58 * rx, 0.095), Vector2(0.04 * rx, 0.104)
		], 1.05, 1.11, 26)
		sm.ellipsoid("safety_yellow", hc + Vector3(0, 0.91 * ry, 0.0), Vector3(0.016, 0.052, 0.100), 5, 10)
		sm.ellipsoid("safety_yellow", hc + Vector3(0, 0.50 * ry, 0.90 * rz), Vector3(0.090, 0.011, 0.054), 5, 12, Vector3(0.14, 0, 0))

	var head_mi := MeshInstance3D.new()
	head_mi.name = "HeadMesh"
	head_mi.mesh = sm.to_mesh(Callable(VillageMaterials, "mat"))
	head_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	head_pivot.add_child(head_mi)

static func _add_hair(sm: StyleMesh, hair_k: String, hc: Vector3, radii: Vector3, style: String, hat: String) -> void:
	var rx := radii.x
	var ry := radii.y
	var rz := radii.z

	# Calotta cranica e nuca arretrate per lasciare sempre fronte e sopracciglia completamente libere
	sm.ellipsoid(hair_k, hc + Vector3(0, 0.40 * ry, -0.34 * rz), Vector3(0.99 * rx, 0.70 * ry, 0.82 * rz), 10, 22)
	sm.ellipsoid(hair_k, hc + Vector3(0, -0.04 * ry, -0.58 * rz), Vector3(0.94 * rx, 0.64 * ry, 0.56 * rz), 8, 18)

	# Basette / tempie pulite davanti alle orecchie (aderenti al profilo laterale del volto)
	for side_v in [-1.0, 1.0]:
		var side: float = float(side_v)
		sm.ellipsoid(hair_k, hc + Vector3(side * 0.92 * rx, 0.18 * ry, -0.02 * rz), Vector3(0.011, 0.032, 0.018), 6, 12, Vector3(-0.18, side * 0.20, 0.0))

	if hat != "":
		# Sotto il cappello: attaccatura alta e raccolta sopra la fronte (fronte ampia e sopracciglia ben distanti dal bordo!)
		sm.ellipsoid(hair_k, hc + Vector3(0.0, 0.58 * ry, -0.18 * rz), Vector3(0.95 * rx, 0.18 * ry, 0.76 * rz), 8, 18, Vector3(-0.08, 0.0, 0.0))
		return

	match style:
		"updo_wavy":
			# Acconciatura raccolta alta e morbida con fronte ampia completamente scoperta e chignon posteriore (Rosa)
			sm.ellipsoid(hair_k, hc + Vector3(0.0, 0.74 * ry, -0.10 * rz), Vector3(0.99 * rx, 0.30 * ry, 0.82 * rz), 9, 20, Vector3(-0.12, 0.0, 0.0))
			for side_v in [-1.0, 1.0]:
				var side: float = float(side_v)
				sm.tube_path(hair_k, [
					hc + Vector3(side * 0.012, 0.85 * ry, 0.34 * rz),
					hc + Vector3(side * 0.68 * rx, 0.72 * ry, 0.28 * rz),
					hc + Vector3(side * 0.96 * rx, 0.30 * ry, 0.06 * rz),
					hc + Vector3(side * 0.86 * rx, -0.04 * ry, -0.34 * rz),
					hc + Vector3(side * 0.32 * rx, 0.16 * ry, -0.92 * rz),
				], [0.013, 0.018, 0.021, 0.019, 0.015], 10, true)
			sm.lathe_pleated(hair_k, hc + Vector3(0.0, 0.48 * ry, -0.66 * rz), [
				Vector3(0.62 * rx, -0.01, 0.35),
				Vector3(0.78 * rx, 0.020, 0.78),
				Vector3(0.74 * rx, 0.048, 0.72),
				Vector3(0.46 * rx, 0.070, 0.35),
				Vector3(0.04 * rx, 0.080, 0.00),
			], 1.0, 0.96, 28, 12, 0.004, Vector3(-0.56, 0.0, 0.0))
			sm.ellipsoid(hair_k, hc + Vector3(0.0, 0.12 * ry, -0.98 * rz), Vector3(0.050, 0.046, 0.038), 8, 16)
		"ponytail":
			# Calotta bionda tirata indietro liscia (fronte aperta) + onde laterali sulle tempie + coda alta con fiocco rosso (Elena)
			sm.ellipsoid(hair_k, hc + Vector3(0.0, 0.72 * ry, -0.10 * rz), Vector3(0.99 * rx, 0.30 * ry, 0.82 * rz), 10, 22, Vector3(-0.10, 0.0, 0.0))
			for side_v in [-1.0, 1.0]:
				var side: float = float(side_v)
				sm.tube_path(hair_k, [
					hc + Vector3(side * 0.012, 0.84 * ry, 0.34 * rz),
					hc + Vector3(side * 0.68 * rx, 0.70 * ry, 0.28 * rz),
					hc + Vector3(side * 0.93 * rx, 0.28 * ry, 0.08 * rz),
					hc + Vector3(side * 0.78 * rx, 0.14 * ry, -0.45 * rz),
				], [0.012, 0.016, 0.016, 0.014], 9, true)
			sm.ellipsoid("ribbon_red", hc + Vector3(0, 0.46 * ry, -1.03 * rz), Vector3(0.025, 0.022, 0.022), 6, 12)
			sm.tube_path(hair_k, [
				hc + Vector3(0, 0.42 * ry, -1.06 * rz),
				hc + Vector3(0.008, -0.22 * ry, -1.28 * rz),
				hc + Vector3(0.012, -0.94 * ry, -1.36 * rz),
			], [0.035, 0.028, 0.015], 10, true)
		"bob":
			# Caschetto morbido ed elegante ben staccato dagli occhiali (Sabrina)
			sm.ellipsoid(hair_k, hc + Vector3(0.0, 0.66 * ry, -0.04 * rz), Vector3(1.01 * rx, 0.36 * ry, 0.86 * rz), 10, 22, Vector3(-0.12, 0.0, 0.0))
			for side_v in [-1.0, 1.0]:
				var side: float = float(side_v)
				sm.tube_path(hair_k, [
					hc + Vector3(side * 0.22 * rx, 0.82 * ry, 0.38 * rz),
					hc + Vector3(side * 0.90 * rx, 0.58 * ry, 0.34 * rz),
					hc + Vector3(side * 0.99 * rx, -0.02 * ry, 0.10 * rz),
					hc + Vector3(side * 0.90 * rx, -0.74 * ry, -0.02 * rz),
				], [0.020, 0.025, 0.027, 0.018], 10, true)
			sm.ellipsoid(hair_k, hc + Vector3(0, 0.10 * ry, -0.96 * rz), Vector3(0.054, 0.050, 0.040), 7, 14)
		"quiff":
			# Taglio moderno scolpito con ciuffo pettinato alto sulla fronte (Davide & Luca)
			sm.ellipsoid(hair_k, hc + Vector3(0.0, 0.66 * ry, -0.04 * rz), Vector3(1.00 * rx, 0.34 * ry, 0.86 * rz), 10, 22, Vector3(-0.12, 0.0, 0.0))
			sm.ellipsoid(hair_k, hc + Vector3(0.012, 0.78 * ry, 0.18 * rz), Vector3(0.74 * rx, 0.24 * ry, 0.58 * rz), 9, 18, Vector3(-0.18, 0.14, -0.08))
			sm.ellipsoid(hair_k, hc + Vector3(-0.012, 0.68 * ry, 0.28 * rz), Vector3(0.56 * rx, 0.16 * ry, 0.44 * rz), 7, 14, Vector3(-0.20, -0.10, 0.06))
		_:
			# Taglio classico ordinato da manager/imprenditore (Andrea Viale)
			sm.ellipsoid(hair_k, hc + Vector3(0.0, 0.64 * ry, -0.04 * rz), Vector3(0.99 * rx, 0.34 * ry, 0.84 * rz), 10, 22, Vector3(-0.12, 0.0, 0.0))
			sm.ellipsoid(hair_k, hc + Vector3(0.010, 0.72 * ry, 0.16 * rz), Vector3(0.74 * rx, 0.18 * ry, 0.52 * rz), 8, 16, Vector3(-0.16, 0.10, -0.04))

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
