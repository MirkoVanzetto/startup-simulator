class_name VillageCharacters
extends RefCounted
## VillageCharacters - Caricatore di personaggi MakeHuman CC0 (.glb) leggeri e riggati (~5.5k vertici, Skeleton3D).
## Preserva la gerarchia attesa da test e interazioni (Model -> Skeleton3D/BodyMesh, HeadPivot BoneAttachment3D, AnimationPlayer).

const ARCHETYPES := {
	"chef_mario": "res://assets/models/characters/mh_chef_mario.glb",
	"baker_bruno": "res://assets/models/characters/mh_baker_bruno.glb",
	"female_skirt_apron": "res://assets/models/characters/mh_female_skirt_apron.glb",
	"female_ponytail_apron": "res://assets/models/characters/mh_female_ponytail_apron.glb",
	"female_bob_vest": "res://assets/models/characters/mh_female_bob_vest.glb",
	"female_seated": "res://assets/models/characters/mh_female_seated.glb",
	"male_tech_vest": "res://assets/models/characters/mh_male_tech_vest.glb",
	"male_engineer_hardhat": "res://assets/models/characters/mh_male_engineer_hardhat.glb",
	"male_suit": "res://assets/models/characters/mh_male_suit.glb",
	"male_hoodie": "res://assets/models/characters/mh_male_hoodie.glb",
}

static var _scene_cache: Dictionary = {}
static var _cleaned_mesh_cache: Dictionary = {}

static func build(parent: Node3D, opts: Dictionary = {}) -> Node3D:
	var custom_glb := str(opts.get("custom_glb", ""))
	if custom_glb != "":
		return _build_custom_glb_character(parent, custom_glb, opts)

	var arch_key := _select_archetype(opts)
	var scene_path: String = str(ARCHETYPES.get(arch_key, ARCHETYPES["male_hoodie"]))
	var packed := _load_archetype_scene(scene_path)
	if packed == null:
		push_error("VillageCharacters: impossibile caricare archetipo %s (%s)" % [arch_key, scene_path])
		var fallback := Node3D.new()
		fallback.name = "Model"
		parent.add_child(fallback)
		return fallback

	var model := packed.instantiate() as Node3D
	model.name = "Model"
	parent.add_child(model)

	var skel := model.find_child("Skeleton3D", true, false) as Skeleton3D
	if skel != null and skel.get_node_or_null("HeadPivot") == null:
		var head_idx := skel.find_bone("head")
		if head_idx >= 0:
			var head_pivot := BoneAttachment3D.new()
			head_pivot.name = "HeadPivot"
			head_pivot.bone_name = "head"
			skel.add_child(head_pivot)

	var body_mi := model.find_child("BodyMesh", true, false) as MeshInstance3D
	if body_mi != null and body_mi.mesh != null:
		body_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		var base_clean := _get_cleaned_mesh(arch_key, body_mi.mesh)
		var mesh_dup := base_clean.duplicate(false) as ArrayMesh
		if mesh_dup != null:
			_apply_surface_materials(mesh_dup, opts)
			body_mi.mesh = mesh_dup

	var is_seated := bool(opts.get("seated", false))
	var is_typing := bool(opts.get("typing", false))
	var ap := model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if ap != null:
		if ap.has_animation_library(""):
			var src_lib := ap.get_animation_library("")
			if src_lib != null:
				var dup_lib := src_lib.duplicate(true) as AnimationLibrary
				ap.remove_animation_library("")
				ap.add_animation_library("", dup_lib)
		if skel != null:
			_refine_idle_animation(ap, skel)
			if is_seated:
				_ensure_sit_typing_animation(ap, skel)
			else:
				_ensure_walk_animation(ap, skel)
		for loop_anim in ["Idle", "Sit_Chair_Idle", "Sit_Typing", "Walk"]:
			if ap.has_animation(loop_anim):
				var anim_res := ap.get_animation(loop_anim)
				if anim_res != null:
					anim_res.loop_mode = Animation.LOOP_LINEAR
		var default_anim := "Sit_Typing" if (is_seated and is_typing) else ("Sit_Chair_Idle" if is_seated else "Idle")
		ap.set_meta("base_loop_anim", default_anim)
		if ap.has_animation(default_anim):
			ap.assigned_animation = default_anim
			ap.play(default_anim)
			ap.advance(0.0)
			var cb := _on_anim_finished.bind(ap, default_anim)
			if not ap.animation_finished.is_connected(cb):
				ap.animation_finished.connect(cb)

	return model

static func _build_custom_glb_character(parent: Node3D, glb_path: String, opts: Dictionary) -> Node3D:
	var model := Node3D.new()
	model.name = "Model"
	parent.add_child(model)
	var packed := _load_archetype_scene(glb_path)
	if packed == null:
		push_error("VillageCharacters: impossibile caricare custom GLB %s" % glb_path)
		return model

	var custom_vis := Node3D.new()
	custom_vis.name = "CustomVisual"
	var target_h := float(opts.get("height", 1.74))
	# mario compresso_edited.glb: piedi a Y=-1.0 in unità locali, quindi +1.0 interno a CustomVisual li tiene a Y=0.0 anche se CustomVisual viene animato attorno a ZERO
	custom_vis.scale = Vector3.ONE * target_h
	custom_vis.position = Vector3.ZERO
	model.add_child(custom_vis)

	var vis := packed.instantiate() as Node3D
	vis.name = "GlbInstance"
	vis.position = Vector3(0.0, 1.0, 0.0)
	custom_vis.add_child(vis)

	for child in vis.find_children("*", "MeshInstance3D", true, false):
		var mi := child as MeshInstance3D
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		if mi.mesh != null:
			var dup_m := mi.mesh.duplicate(false) as ArrayMesh
			for si in range(dup_m.get_surface_count()):
				var mat := dup_m.surface_get_material(si)
				if mat is StandardMaterial3D:
					var smat := (mat as StandardMaterial3D).duplicate() as StandardMaterial3D
					smat.roughness = maxf(smat.roughness, 0.78)
					smat.metallic = 0.0
					smat.cull_mode = BaseMaterial3D.CULL_DISABLED
					dup_m.surface_set_material(si, smat)
			mi.mesh = dup_m

	var ap := AnimationPlayer.new()
	ap.name = "AnimationPlayer"
	model.add_child(ap)
	var lib := AnimationLibrary.new()

	var idle_anim := Animation.new()
	idle_anim.length = 2.6
	idle_anim.loop_mode = Animation.LOOP_LINEAR
	var tr_s := idle_anim.add_track(Animation.TYPE_SCALE_3D)
	idle_anim.track_set_path(tr_s, "CustomVisual")
	var base_sc := Vector3.ONE * target_h
	idle_anim.scale_track_insert_key(tr_s, 0.0, base_sc)
	idle_anim.scale_track_insert_key(tr_s, 1.3, base_sc * Vector3(1.012, 1.008, 1.012))
	idle_anim.scale_track_insert_key(tr_s, 2.6, base_sc)
	lib.add_animation(&"Idle", idle_anim)

	var int_anim := Animation.new()
	int_anim.length = 0.75
	int_anim.loop_mode = Animation.LOOP_NONE
	var tr_p := int_anim.add_track(Animation.TYPE_POSITION_3D)
	int_anim.track_set_path(tr_p, "CustomVisual")
	int_anim.position_track_insert_key(tr_p, 0.0, Vector3.ZERO)
	int_anim.position_track_insert_key(tr_p, 0.22, Vector3(0.0, 0.035, 0.03))
	int_anim.position_track_insert_key(tr_p, 0.75, Vector3.ZERO)
	lib.add_animation(&"Interact", int_anim)

	var cheer_anim := Animation.new()
	cheer_anim.length = 0.85
	cheer_anim.loop_mode = Animation.LOOP_NONE
	var tr_cp := cheer_anim.add_track(Animation.TYPE_POSITION_3D)
	cheer_anim.track_set_path(tr_cp, "CustomVisual")
	cheer_anim.position_track_insert_key(tr_cp, 0.0, Vector3.ZERO)
	cheer_anim.position_track_insert_key(tr_cp, 0.25, Vector3(0.0, 0.08, 0.0))
	cheer_anim.position_track_insert_key(tr_cp, 0.85, Vector3.ZERO)
	lib.add_animation(&"Cheer", cheer_anim)

	ap.add_animation_library("", lib)
	ap.set_meta("base_loop_anim", "Idle")
	ap.play("Idle")
	var cb := _on_anim_finished.bind(ap, "Idle")
	if not ap.animation_finished.is_connected(cb):
		ap.animation_finished.connect(cb)
	return model

static func _get_cleaned_mesh(arch_key: String, src_mesh: Mesh) -> ArrayMesh:
	var arr_src := src_mesh as ArrayMesh
	if arr_src == null:
		return ArrayMesh.new()
	if _cleaned_mesh_cache.has(arch_key):
		return _cleaned_mesh_cache[arch_key] as ArrayMesh

	var scount := arr_src.get_surface_count()
	var mdts: Array[MeshDataTool] = []
	var names: Array[String] = []
	var mats: Array[Material] = []
	var shirt_min_y := INF
	var shirt_max_y := -INF
	var pants_max_y := -INF

	for si in range(scount):
		var sname := arr_src.surface_get_name(si)
		var mdt := MeshDataTool.new()
		if mdt.create_from_surface(arr_src, si) != OK:
			mdts.append(null)
		else:
			mdts.append(mdt)
			if sname == "shirt":
				for vi in range(mdt.get_vertex_count()):
					var v := mdt.get_vertex(vi)
					if absf(v.x) < 0.24:
						shirt_min_y = minf(shirt_min_y, v.y)
						shirt_max_y = maxf(shirt_max_y, v.y)
			elif sname == "pants":
				for vi in range(mdt.get_vertex_count()):
					var v := mdt.get_vertex(vi)
					if absf(v.x) < 0.24:
						pants_max_y = maxf(pants_max_y, v.y)
		names.append(sname)
		mats.append(arr_src.surface_get_material(si))

	var has_waist_overlap := shirt_min_y < pants_max_y and shirt_min_y < INF and pants_max_y > -INF
	var out_mesh := ArrayMesh.new()

	for si in range(scount):
		var mdt := mdts[si]
		var sname := names[si]
		if mdt == null:
			continue
		if has_waist_overlap:
			if sname == "pants":
				var y_lo := shirt_min_y - 0.035
				for vi in range(mdt.get_vertex_count()):
					var v := mdt.get_vertex(vi)
					if absf(v.x) < 0.25 and v.y > y_lo:
						var t := clampf((v.y - y_lo) / 0.045, 0.0, 1.0)
						var xz := Vector3(v.x, 0.0, v.z)
						var r := xz.length()
						if r > 0.01:
							mdt.set_vertex(vi, v - (xz / r) * (0.0085 * t))
			elif sname == "shirt":
				var y_hi := pants_max_y + 0.09
				for vi in range(mdt.get_vertex_count()):
					var v := mdt.get_vertex(vi)
					if absf(v.x) < 0.25 and v.y < y_hi:
						var t := 1.0 - clampf((v.y - (pants_max_y - 0.02)) / 0.11, 0.0, 1.0)
						var xz := Vector3(v.x, 0.0, v.z)
						var r := xz.length()
						if r > 0.01:
							mdt.set_vertex(vi, v + (xz / r) * (0.009 * t))
			elif sname == "vest":
				var y_hi_v := pants_max_y + 0.08
				for vi in range(mdt.get_vertex_count()):
					var v := mdt.get_vertex(vi)
					if absf(v.x) < 0.25 and v.y < y_hi_v:
						var t := 1.0 - clampf((v.y - (pants_max_y - 0.01)) / 0.09, 0.0, 1.0)
						var xz := Vector3(v.x, 0.0, v.z)
						var r := xz.length()
						if r > 0.01:
							mdt.set_vertex(vi, v + (xz / r) * (0.005 * t))
		if sname == "skin" and shirt_min_y < INF:
			for vi in range(mdt.get_vertex_count()):
				var v := mdt.get_vertex(vi)
				if absf(v.x) < 0.165 and v.y >= shirt_min_y and v.y <= shirt_max_y - 0.022:
					var xz := Vector3(v.x, 0.0, v.z)
					var r := xz.length()
					if r > 0.01:
						mdt.set_vertex(vi, v - (xz / r) * 0.004)
		var dst_idx := out_mesh.get_surface_count()
		mdt.commit_to_surface(out_mesh)
		out_mesh.surface_set_name(dst_idx, sname)
		if mats[si] != null:
			out_mesh.surface_set_material(dst_idx, mats[si])

	_cleaned_mesh_cache[arch_key] = out_mesh
	return out_mesh

static func play_interact(npc: Node) -> void:
	if npc == null or not is_instance_valid(npc):
		return
	var ap := npc.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if ap == null:
		return
	if ap.has_animation("Interact"):
		ap.play("Interact")
	elif ap.has_animation("Cheer"):
		ap.play("Cheer")

static func _on_anim_finished(finished_name: StringName, ap: AnimationPlayer, fallback_anim: String) -> void:
	if not is_instance_valid(ap):
		return
	var target_anim := str(ap.get_meta("base_loop_anim", fallback_anim))
	if str(finished_name) != target_anim and ap.has_animation(target_anim):
		ap.play(target_anim)

static func _refine_idle_animation(ap: AnimationPlayer, skel: Skeleton3D) -> void:
	var lib := ap.get_animation_library("")
	if lib == null:
		return
	var anim := Animation.new()
	anim.length = 2.8
	anim.loop_mode = Animation.LOOP_LINEAR
	var root_node := ap.get_node_or_null(ap.root_node)
	var skel_rel := String(root_node.get_path_to(skel)) if root_node != null else "CharacterRoot/Skeleton3D"

	var pelvis_rest := Vector3(0.0, 0.90, 0.0)
	var pelvis_idx := skel.find_bone("pelvis")
	if pelvis_idx >= 0:
		pelvis_rest = skel.get_bone_rest(pelvis_idx).origin
	var pelvis_pos := anim.add_track(Animation.TYPE_POSITION_3D)
	anim.track_set_path(pelvis_pos, "%s:pelvis" % skel_rel)
	var times: Array[float] = [0.0, 1.4, 2.8]
	for t in times:
		anim.position_track_insert_key(pelvis_pos, t, pelvis_rest)

	# Postura dritta e rilassata: piedi paralleli in avanti (zero piedi a papera!), braccia vicine ai fianchi
	var tracks := {
		"thigh_l": [Vector3(0.0, 0.0, -0.085), Vector3(0.0, 0.0, -0.085), Vector3(0.0, 0.0, -0.085)],
		"thigh_r": [Vector3(0.0, 0.0, 0.085), Vector3(0.0, 0.0, 0.085), Vector3(0.0, 0.0, 0.085)],
		"foot_l": [Vector3(0.0, -0.09, 0.0), Vector3(0.0, -0.09, 0.0), Vector3(0.0, -0.09, 0.0)],
		"foot_r": [Vector3(0.0, 0.09, 0.0), Vector3(0.0, 0.09, 0.0), Vector3(0.0, 0.09, 0.0)],
		"upperarm_l": [Vector3(0.02, 0.06, -0.60), Vector3(0.02, 0.06, -0.57), Vector3(0.02, 0.06, -0.60)],
		"upperarm_r": [Vector3(0.02, -0.06, 0.60), Vector3(0.02, -0.06, 0.57), Vector3(0.02, -0.06, 0.60)],
		"lowerarm_l": [Vector3(-0.16, -0.40, 0.0), Vector3(-0.20, -0.40, 0.0), Vector3(-0.16, -0.40, 0.0)],
		"lowerarm_r": [Vector3(-0.16, 0.40, 0.0), Vector3(-0.20, 0.40, 0.0), Vector3(-0.16, 0.40, 0.0)],
		"spine_02": [Vector3(0.0, 0.0, 0.0), Vector3(0.015, 0.0, 0.0), Vector3(0.0, 0.0, 0.0)],
		"head": [Vector3(0.0, -0.04, 0.0), Vector3(-0.015, 0.05, 0.0), Vector3(0.0, -0.04, 0.0)],
	}
	for bn in tracks:
		if skel.find_bone(bn) < 0:
			continue
		var tr := anim.add_track(Animation.TYPE_ROTATION_3D)
		anim.track_set_path(tr, "%s:%s" % [skel_rel, bn])
		var arr: Array = tracks[bn]
		for i in range(times.size()):
			anim.rotation_track_insert_key(tr, times[i], Basis.from_euler(arr[i], EULER_ORDER_ZYX).get_rotation_quaternion())

	if lib.has_animation(&"Idle"):
		lib.remove_animation(&"Idle")
	lib.add_animation(&"Idle", anim)

static func _ensure_sit_typing_animation(ap: AnimationPlayer, skel: Skeleton3D) -> void:
	var lib := ap.get_animation_library("")
	if lib == null:
		return
	var anim := Animation.new()
	anim.length = 0.80
	anim.loop_mode = Animation.LOOP_LINEAR
	var root_node := ap.get_node_or_null(ap.root_node)
	var skel_rel := String(root_node.get_path_to(skel)) if root_node != null else "CharacterRoot/Skeleton3D"

	var pelvis_rest := Vector3(0.0, 0.90, 0.0)
	var pelvis_idx := skel.find_bone("pelvis")
	if pelvis_idx >= 0:
		pelvis_rest = skel.get_bone_rest(pelvis_idx).origin
	var pelvis_seat := Vector3(pelvis_rest.x, pelvis_rest.y * 0.52, -0.04)

	var times: Array[float] = [0.0, 0.20, 0.40, 0.60, 0.80]
	var pelvis_pos := anim.add_track(Animation.TYPE_POSITION_3D)
	anim.track_set_path(pelvis_pos, "%s:pelvis" % skel_rel)
	for t in times:
		anim.position_track_insert_key(pelvis_pos, t, pelvis_seat)

	var tracks := {
		"thigh_l": [Vector3(-1.46, 0.0, -0.05), Vector3(-1.46, 0.0, -0.05), Vector3(-1.46, 0.0, -0.05), Vector3(-1.46, 0.0, -0.05), Vector3(-1.46, 0.0, -0.05)],
		"thigh_r": [Vector3(-1.46, 0.0, 0.05), Vector3(-1.46, 0.0, 0.05), Vector3(-1.46, 0.0, 0.05), Vector3(-1.46, 0.0, 0.05), Vector3(-1.46, 0.0, 0.05)],
		"calf_l": [Vector3(1.46, 0.0, 0.0), Vector3(1.46, 0.0, 0.0), Vector3(1.46, 0.0, 0.0), Vector3(1.46, 0.0, 0.0), Vector3(1.46, 0.0, 0.0)],
		"calf_r": [Vector3(1.46, 0.0, 0.0), Vector3(1.46, 0.0, 0.0), Vector3(1.46, 0.0, 0.0), Vector3(1.46, 0.0, 0.0), Vector3(1.46, 0.0, 0.0)],
		"spine_01": [Vector3(0.06, 0.0, 0.0), Vector3(0.07, 0.01, 0.0), Vector3(0.06, 0.0, 0.0), Vector3(0.07, -0.01, 0.0), Vector3(0.06, 0.0, 0.0)],
		"upperarm_l": [Vector3(-0.56, 0.06, -0.54), Vector3(-0.58, 0.08, -0.54), Vector3(-0.55, 0.04, -0.54), Vector3(-0.57, 0.07, -0.54), Vector3(-0.56, 0.06, -0.54)],
		"upperarm_r": [Vector3(-0.56, -0.06, 0.54), Vector3(-0.55, -0.04, 0.54), Vector3(-0.58, -0.08, 0.54), Vector3(-0.57, -0.05, 0.54), Vector3(-0.56, -0.06, 0.54)],
		"lowerarm_l": [Vector3(-0.38, -0.44, -0.08), Vector3(-0.30, -0.46, -0.08), Vector3(-0.42, -0.42, -0.08), Vector3(-0.32, -0.44, -0.08), Vector3(-0.38, -0.44, -0.08)],
		"lowerarm_r": [Vector3(-0.32, 0.44, 0.08), Vector3(-0.42, 0.42, 0.08), Vector3(-0.30, 0.46, 0.08), Vector3(-0.40, 0.43, 0.08), Vector3(-0.32, 0.44, 0.08)],
		"hand_l": [Vector3(0.06, 0.04, 0.62), Vector3(-0.04, 0.02, 0.62), Vector3(0.08, 0.05, 0.62), Vector3(-0.03, 0.03, 0.62), Vector3(0.06, 0.04, 0.62)],
		"hand_r": [Vector3(-0.03, -0.03, -0.62), Vector3(0.08, -0.05, -0.62), Vector3(-0.04, -0.02, -0.62), Vector3(0.07, -0.04, -0.62), Vector3(-0.03, -0.03, -0.62)],
		"head": [Vector3(0.08, -0.03, 0.0), Vector3(0.10, 0.01, 0.0), Vector3(0.08, 0.03, 0.0), Vector3(0.10, -0.01, 0.0), Vector3(0.08, -0.03, 0.0)],
	}
	for bn in tracks:
		if skel.find_bone(bn) < 0:
			continue
		var tr := anim.add_track(Animation.TYPE_ROTATION_3D)
		anim.track_set_path(tr, "%s:%s" % [skel_rel, bn])
		var arr: Array = tracks[bn]
		for i in range(times.size()):
			anim.rotation_track_insert_key(tr, times[i], Basis.from_euler(arr[i], EULER_ORDER_ZYX).get_rotation_quaternion())

	if lib.has_animation(&"Sit_Typing"):
		lib.remove_animation(&"Sit_Typing")
	lib.add_animation(&"Sit_Typing", anim)

static func _ensure_walk_animation(ap: AnimationPlayer, skel: Skeleton3D) -> void:
	var lib := ap.get_animation_library("")
	if lib == null:
		return
	var anim := Animation.new()
	anim.length = 0.96
	anim.loop_mode = Animation.LOOP_LINEAR

	var root_node := ap.get_node_or_null(ap.root_node)
	var skel_rel := String(root_node.get_path_to(skel)) if root_node != null else "CharacterRoot/Skeleton3D"

	var pelvis_rest := Vector3(0.0, 0.90, 0.0)
	var pelvis_idx := skel.find_bone("pelvis")
	if pelvis_idx >= 0:
		pelvis_rest = skel.get_bone_rest(pelvis_idx).origin

	# Ciclo camminata naturale a 9 keyframe (0.96s): postura eretta, piedi paralleli dritti in avanti (niente passo a papera!)
	var times: Array[float] = [0.0, 0.12, 0.24, 0.36, 0.48, 0.60, 0.72, 0.84, 0.96]
	var pelvis_pos := anim.add_track(Animation.TYPE_POSITION_3D)
	anim.track_set_path(pelvis_pos, "%s:pelvis" % skel_rel)
	var p_dy: Array[float] = [-0.014, -0.004, 0.012, 0.002, -0.014, -0.004, 0.012, 0.002, -0.014]
	for i in range(times.size()):
		anim.position_track_insert_key(pelvis_pos, times[i], pelvis_rest + Vector3(0.0, p_dy[i], 0.0))

	var bone_eulers: Dictionary = {
		"pelvis": [
			Vector3(0.0, -0.042, 0.008),
			Vector3(0.0, -0.020, 0.012),
			Vector3(0.0, 0.0, 0.004),
			Vector3(0.0, 0.022, -0.004),
			Vector3(0.0, 0.042, -0.008),
			Vector3(0.0, 0.020, -0.012),
			Vector3(0.0, 0.0, -0.004),
			Vector3(0.0, -0.022, 0.004),
			Vector3(0.0, -0.042, 0.008),
		],
		"spine_01": [
			Vector3(0.01, 0.040, 0.0),
			Vector3(0.01, 0.020, 0.0),
			Vector3(0.01, 0.0, 0.0),
			Vector3(0.01, -0.020, 0.0),
			Vector3(0.01, -0.040, 0.0),
			Vector3(0.01, -0.020, 0.0),
			Vector3(0.01, 0.0, 0.0),
			Vector3(0.01, 0.020, 0.0),
			Vector3(0.01, 0.040, 0.0),
		],
		"spine_02": [
			Vector3(0.01, 0.032, 0.0),
			Vector3(0.01, 0.016, 0.0),
			Vector3(0.01, 0.0, 0.0),
			Vector3(0.01, -0.016, 0.0),
			Vector3(0.01, -0.032, 0.0),
			Vector3(0.01, -0.016, 0.0),
			Vector3(0.01, 0.0, 0.0),
			Vector3(0.01, 0.016, 0.0),
			Vector3(0.01, 0.032, 0.0),
		],
		"thigh_l": [
			Vector3(-0.32, 0.0, -0.095),
			Vector3(-0.22, 0.0, -0.095),
			Vector3(-0.02, 0.0, -0.095),
			Vector3(0.18, 0.0, -0.095),
			Vector3(0.28, 0.0, -0.095),
			Vector3(0.20, 0.0, -0.095),
			Vector3(-0.06, 0.0, -0.095),
			Vector3(-0.26, 0.0, -0.095),
			Vector3(-0.32, 0.0, -0.095),
		],
		"thigh_r": [
			Vector3(0.28, 0.0, 0.095),
			Vector3(0.20, 0.0, 0.095),
			Vector3(-0.06, 0.0, 0.095),
			Vector3(-0.26, 0.0, 0.095),
			Vector3(-0.32, 0.0, 0.095),
			Vector3(-0.22, 0.0, 0.095),
			Vector3(-0.02, 0.0, 0.095),
			Vector3(0.18, 0.0, 0.095),
			Vector3(0.28, 0.0, 0.095),
		],
		"calf_l": [
			Vector3(0.06, 0.0, 0.0),
			Vector3(0.24, 0.0, 0.0),
			Vector3(0.10, 0.0, 0.0),
			Vector3(0.14, 0.0, 0.0),
			Vector3(0.42, 0.0, 0.0),
			Vector3(0.82, 0.0, 0.0),
			Vector3(0.62, 0.0, 0.0),
			Vector3(0.24, 0.0, 0.0),
			Vector3(0.06, 0.0, 0.0),
		],
		"calf_r": [
			Vector3(0.42, 0.0, 0.0),
			Vector3(0.82, 0.0, 0.0),
			Vector3(0.62, 0.0, 0.0),
			Vector3(0.24, 0.0, 0.0),
			Vector3(0.06, 0.0, 0.0),
			Vector3(0.24, 0.0, 0.0),
			Vector3(0.10, 0.0, 0.0),
			Vector3(0.14, 0.0, 0.0),
			Vector3(0.42, 0.0, 0.0),
		],
		"foot_l": [
			Vector3(-0.14, -0.095, 0.0),
			Vector3(0.03, -0.095, 0.0),
			Vector3(0.02, -0.095, 0.0),
			Vector3(0.08, -0.095, 0.0),
			Vector3(0.24, -0.095, 0.0),
			Vector3(0.18, -0.095, 0.0),
			Vector3(-0.04, -0.095, 0.0),
			Vector3(-0.10, -0.095, 0.0),
			Vector3(-0.14, -0.095, 0.0),
		],
		"foot_r": [
			Vector3(0.24, 0.095, 0.0),
			Vector3(0.18, 0.095, 0.0),
			Vector3(-0.04, 0.095, 0.0),
			Vector3(-0.10, 0.095, 0.0),
			Vector3(-0.14, 0.095, 0.0),
			Vector3(0.03, 0.095, 0.0),
			Vector3(0.02, 0.095, 0.0),
			Vector3(0.08, 0.095, 0.0),
			Vector3(0.24, 0.095, 0.0),
		],
		"upperarm_l": [
			Vector3(0.20, 0.08, -0.60),
			Vector3(0.11, 0.08, -0.60),
			Vector3(0.0, 0.08, -0.60),
			Vector3(-0.13, 0.08, -0.60),
			Vector3(-0.24, 0.08, -0.60),
			Vector3(-0.13, 0.08, -0.60),
			Vector3(0.0, 0.08, -0.60),
			Vector3(0.11, 0.08, -0.60),
			Vector3(0.20, 0.08, -0.60),
		],
		"upperarm_r": [
			Vector3(-0.24, -0.08, 0.60),
			Vector3(-0.13, -0.08, 0.60),
			Vector3(0.0, -0.08, 0.60),
			Vector3(0.11, -0.08, 0.60),
			Vector3(0.20, -0.08, 0.60),
			Vector3(0.11, -0.08, 0.60),
			Vector3(0.0, -0.08, 0.60),
			Vector3(-0.13, -0.08, 0.60),
			Vector3(-0.24, -0.08, 0.60),
		],
		"lowerarm_l": [
			Vector3(-0.18, -0.44, 0.0),
			Vector3(-0.22, -0.44, 0.0),
			Vector3(-0.28, -0.44, 0.0),
			Vector3(-0.35, -0.44, 0.0),
			Vector3(-0.40, -0.44, 0.0),
			Vector3(-0.34, -0.44, 0.0),
			Vector3(-0.26, -0.44, 0.0),
			Vector3(-0.21, -0.44, 0.0),
			Vector3(-0.18, -0.44, 0.0),
		],
		"lowerarm_r": [
			Vector3(-0.40, 0.44, 0.0),
			Vector3(-0.34, 0.44, 0.0),
			Vector3(-0.26, 0.44, 0.0),
			Vector3(-0.21, 0.44, 0.0),
			Vector3(-0.18, 0.44, 0.0),
			Vector3(-0.22, 0.44, 0.0),
			Vector3(-0.28, 0.44, 0.0),
			Vector3(-0.35, 0.44, 0.0),
			Vector3(-0.40, 0.44, 0.0),
		],
	}
	for bone_name in bone_eulers:
		if skel.find_bone(bone_name) < 0:
			continue
		var tr := anim.add_track(Animation.TYPE_ROTATION_3D)
		anim.track_set_path(tr, "%s:%s" % [skel_rel, bone_name])
		var arr: Array = bone_eulers[bone_name]
		for i in range(times.size()):
			var q := Basis.from_euler(arr[i], EULER_ORDER_ZYX).get_rotation_quaternion()
			anim.rotation_track_insert_key(tr, times[i], q)

	if lib.has_animation(&"Walk"):
		lib.remove_animation(&"Walk")
	lib.add_animation(&"Walk", anim)

static func _load_archetype_scene(path: String) -> PackedScene:
	if not _scene_cache.has(path):
		_scene_cache[path] = load(path)
	return _scene_cache[path] as PackedScene

static func _select_archetype(opts: Dictionary) -> String:
	var explicit := str(opts.get("archetype", ""))
	if explicit != "" and ARCHETYPES.has(explicit):
		return explicit

	var hat := str(opts.get("hat", ""))
	var female := bool(opts.get("female", false))
	var seated := bool(opts.get("seated", false))
	var skirt := bool(opts.get("skirt", false))
	var apron := str(opts.get("apron", ""))
	var vest := str(opts.get("vest", ""))
	var tie := str(opts.get("tie", ""))

	if hat == "chef":
		return "chef_mario"
	if hat == "baker":
		return "baker_bruno"
	if hat == "hardhat":
		return "male_engineer_hardhat"
	if female:
		if skirt:
			return "female_skirt_apron"
		if seated:
			return "female_seated"
		if apron != "":
			return "female_ponytail_apron"
		return "female_bob_vest"
	if tie != "":
		return "male_suit"
	if vest != "":
		return "male_tech_vest"
	return "male_hoodie"

static func _apply_surface_materials(mesh: ArrayMesh, opts: Dictionary) -> void:
	var female := bool(opts.get("female", false))
	var seated := bool(opts.get("seated", false))
	var hat := str(opts.get("hat", ""))
	var apron := str(opts.get("apron", ""))
	var vest := str(opts.get("vest", ""))
	var tie := str(opts.get("tie", ""))
	var hair_k := str(opts.get("hair", "hair_brown"))

	var brow_k := "eyebrow_dark"
	if hair_k in ["hair_blonde", "hair_auburn", "hair_chestnut"]:
		brow_k = "hair_brown"
	elif hair_k == "hair_salt":
		brow_k = "hair_salt"

	var default_shirt := "hoodie_teal" if (seated and not female) else "shirt_white"

	for si in range(mesh.get_surface_count()):
		var sname := mesh.surface_get_name(si)
		var mat_key := "shirt_white"
		match sname:
			"skin":
				mat_key = str(opts.get("skin", "skin"))
			"lip":
				mat_key = str(opts.get("lip", "lip_rose" if female else "lip_warm"))
			"hair":
				mat_key = hair_k
			"eyebrow":
				mat_key = brow_k
			"eye_white":
				mat_key = "eye_white"
			"iris":
				mat_key = str(opts.get("iris", "iris_brown"))
			"limbal_dark":
				mat_key = "limbal_dark"
			"shirt":
				mat_key = str(opts.get("shirt", default_shirt))
			"pants":
				mat_key = str(opts.get("pants", "denim"))
			"apron":
				if apron == "" or apron == "white":
					mat_key = "apron_white"
				else:
					mat_key = apron
			"vest":
				mat_key = "vest_charcoal" if vest == "" else vest
			"tie":
				mat_key = "shirt_sky" if tie == "" else tie
			"shoes":
				mat_key = str(opts.get("shoes", "leather"))
			"hat":
				if hat == "chef":
					mat_key = "hat_chef"
				elif hat == "baker":
					mat_key = "hat_baker"
				elif hat == "hardhat":
					mat_key = "safety_yellow"
				else:
					mat_key = "hat_chef"
			"ribbon":
				mat_key = str(opts.get("ribbon", "ribbon_red"))
			"glass_frame":
				mat_key = "glass_frame"
			_:
				if sname != "":
					mat_key = sname

		mesh.surface_set_material(si, VillageMaterials.mat(mat_key))
