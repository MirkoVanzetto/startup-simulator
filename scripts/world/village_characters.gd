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

static func build(parent: Node3D, opts: Dictionary = {}) -> Node3D:
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
		var mesh_dup := body_mi.mesh.duplicate(false) as ArrayMesh
		if mesh_dup != null:
			_apply_surface_materials(mesh_dup, opts)
			body_mi.mesh = mesh_dup

	var is_seated := bool(opts.get("seated", false))
	var ap := model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if ap != null:
		if ap.has_animation_library(""):
			var src_lib := ap.get_animation_library("")
			if src_lib != null:
				var dup_lib := src_lib.duplicate(true) as AnimationLibrary
				ap.remove_animation_library("")
				ap.add_animation_library("", dup_lib)
		for loop_anim in ["Idle", "Sit_Chair_Idle"]:
			if ap.has_animation(loop_anim):
				var anim_res := ap.get_animation(loop_anim)
				if anim_res != null:
					anim_res.loop_mode = Animation.LOOP_LINEAR
		if skel != null and not is_seated:
			_ensure_walk_animation(ap, skel)
		var default_anim := "Sit_Chair_Idle" if is_seated else "Idle"
		ap.set_meta("base_loop_anim", default_anim)
		if ap.has_animation(default_anim):
			ap.assigned_animation = default_anim
			ap.play(default_anim)
			ap.advance(0.0)
			var cb := _on_anim_finished.bind(ap, default_anim)
			if not ap.animation_finished.is_connected(cb):
				ap.animation_finished.connect(cb)

	return model

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

static func _ensure_walk_animation(ap: AnimationPlayer, skel: Skeleton3D) -> void:
	var lib := ap.get_animation_library("")
	if lib == null:
		return
	var anim := Animation.new()
	anim.length = 0.85
	anim.loop_mode = Animation.LOOP_LINEAR

	var root_node := ap.get_node_or_null(ap.root_node)
	var skel_rel := String(root_node.get_path_to(skel)) if root_node != null else "CharacterRoot/Skeleton3D"

	var pelvis_rest := Vector3(0.0, 0.90, 0.0)
	var pelvis_idx := skel.find_bone("pelvis")
	if pelvis_idx >= 0:
		pelvis_rest = skel.get_bone_rest(pelvis_idx).origin

	# Ciclo camminata a 5 keyframe (T=0.85s): appoggio/spinta -> passaggio -> opposto -> passaggio -> chiusura
	var times: Array[float] = [0.0, 0.2125, 0.425, 0.6375, 0.85]
	var pelvis_pos := anim.add_track(Animation.TYPE_POSITION_3D)
	anim.track_set_path(pelvis_pos, "%s:pelvis" % skel_rel)
	var p_dy: Array[float] = [-0.022, 0.012, -0.022, 0.012, -0.022]
	for i in range(times.size()):
		anim.position_track_insert_key(pelvis_pos, times[i], pelvis_rest + Vector3(0.0, p_dy[i], 0.0))

	var bone_eulers: Dictionary = {
		"pelvis": [
			Vector3(0.03, -0.05, 0.025),
			Vector3(0.02, 0.0, -0.02),
			Vector3(0.03, 0.05, -0.025),
			Vector3(0.02, 0.0, 0.02),
			Vector3(0.03, -0.05, 0.025),
		],
		"spine_01": [
			Vector3(0.04, 0.05, 0.0),
			Vector3(0.03, 0.0, 0.0),
			Vector3(0.04, -0.05, 0.0),
			Vector3(0.03, 0.0, 0.0),
			Vector3(0.04, 0.05, 0.0),
		],
		"spine_02": [
			Vector3(0.03, 0.04, 0.0),
			Vector3(0.02, 0.0, 0.0),
			Vector3(0.03, -0.04, 0.0),
			Vector3(0.02, 0.0, 0.0),
			Vector3(0.03, 0.04, 0.0),
		],
		"thigh_l": [
			Vector3(-0.46, 0.0, -0.04),
			Vector3(-0.04, 0.0, -0.04),
			Vector3(0.42, 0.0, -0.04),
			Vector3(-0.28, 0.0, -0.04),
			Vector3(-0.46, 0.0, -0.04),
		],
		"thigh_r": [
			Vector3(0.42, 0.0, 0.04),
			Vector3(-0.28, 0.0, 0.04),
			Vector3(-0.46, 0.0, 0.04),
			Vector3(-0.04, 0.0, 0.04),
			Vector3(0.42, 0.0, 0.04),
		],
		"calf_l": [
			Vector3(0.08, 0.0, 0.0),
			Vector3(0.14, 0.0, 0.0),
			Vector3(0.28, 0.0, 0.0),
			Vector3(0.62, 0.0, 0.0),
			Vector3(0.08, 0.0, 0.0),
		],
		"calf_r": [
			Vector3(0.28, 0.0, 0.0),
			Vector3(0.62, 0.0, 0.0),
			Vector3(0.08, 0.0, 0.0),
			Vector3(0.14, 0.0, 0.0),
			Vector3(0.28, 0.0, 0.0),
		],
		"foot_l": [
			Vector3(-0.14, 0.0, 0.0),
			Vector3(0.02, 0.0, 0.0),
			Vector3(0.18, 0.0, 0.0),
			Vector3(0.04, 0.0, 0.0),
			Vector3(-0.14, 0.0, 0.0),
		],
		"foot_r": [
			Vector3(0.18, 0.0, 0.0),
			Vector3(0.04, 0.0, 0.0),
			Vector3(-0.14, 0.0, 0.0),
			Vector3(0.02, 0.0, 0.0),
			Vector3(0.18, 0.0, 0.0),
		],
		"upperarm_l": [
			Vector3(0.32, 0.0, -0.54),
			Vector3(0.02, 0.0, -0.54),
			Vector3(-0.34, 0.0, -0.54),
			Vector3(0.02, 0.0, -0.54),
			Vector3(0.32, 0.0, -0.54),
		],
		"upperarm_r": [
			Vector3(-0.34, 0.0, 0.54),
			Vector3(0.02, 0.0, 0.54),
			Vector3(0.32, 0.0, 0.54),
			Vector3(0.02, 0.0, 0.54),
			Vector3(-0.34, 0.0, 0.54),
		],
		"lowerarm_l": [
			Vector3(-0.22, 0.0, 0.0),
			Vector3(-0.30, 0.0, 0.0),
			Vector3(-0.46, 0.0, 0.0),
			Vector3(-0.28, 0.0, 0.0),
			Vector3(-0.22, 0.0, 0.0),
		],
		"lowerarm_r": [
			Vector3(-0.46, 0.0, 0.0),
			Vector3(-0.28, 0.0, 0.0),
			Vector3(-0.22, 0.0, 0.0),
			Vector3(-0.30, 0.0, 0.0),
			Vector3(-0.46, 0.0, 0.0),
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
