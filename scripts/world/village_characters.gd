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
		for loop_anim in ["Idle", "Sit_Chair_Idle"]:
			if ap.has_animation(loop_anim):
				var anim_res := ap.get_animation(loop_anim)
				if anim_res != null:
					anim_res.loop_mode = Animation.LOOP_LINEAR
		var default_anim := "Sit_Chair_Idle" if is_seated else "Idle"
		if ap.has_animation(default_anim):
			ap.assigned_animation = default_anim
			ap.play(default_anim)
			ap.advance(0.0)
			if not ap.animation_finished.is_connected(_on_anim_finished.bind(ap, default_anim)):
				ap.animation_finished.connect(_on_anim_finished.bind(ap, default_anim))

	return model

static func _on_anim_finished(finished_name: StringName, ap: AnimationPlayer, default_anim: String) -> void:
	if str(finished_name) != default_anim and is_instance_valid(ap) and ap.has_animation(default_anim):
		ap.play(default_anim)

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
