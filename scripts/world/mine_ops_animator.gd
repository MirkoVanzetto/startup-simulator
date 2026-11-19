class_name MineOpsAnimator
extends Node3D
## MineOpsAnimator - Anima in tempo reale i macchinari della Miniera Alpina Val di Susa:
## - Carrello minerario su rotaia dentro/fuori la Galleria Estrattiva 01 (con ruote rotanti)
## - Volano frantoio + bagliore fornace nella Stazione di Raffinazione
## - Sbraccio rotante lento della Gru di Cava gialla
## - Oscillazione dei cristalli YieldIcon sui 3 filoni minerari
## - Sincronizzazione e movimento dei blocchi di minerale sul Nastro Trasportatore (se installato)

var _t: float = 0.0
var _minecart: Node3D = null
var _cart_wheels: Array[Node3D] = []
var _last_cart_z: float = -33.0

var _crusher_wheel: Node3D = null
var _furnace_mesh: MeshInstance3D = null
var _furnace_mat: ShaderMaterial = null
var _crane_jib: Node3D = null

var _yield_icons: Array[Node3D] = []
var _conveyor_root: Node3D = null
var _conveyor_ores: Array[Node3D] = []

const CART_START_Z := -38.8
const CART_END_Z := -26.8
const CONVEYOR_START := Vector3(-51.0, 0.69, -19.2)
const CONVEYOR_MID := Vector3(-44.0, 0.69, -19.2)
const CONVEYOR_END := Vector3(-36.2, 0.69, -17.6)

func _ready() -> void:
	_minecart = get_node_or_null("MineCart") as Node3D
	if _minecart:
		_last_cart_z = _minecart.position.z
		for i in range(4):
			var w := _minecart.get_node_or_null("Wheel_%d" % i) as Node3D
			if w:
				_cart_wheels.append(w)

	var ref_anim := get_node_or_null("RefineryAnim") as Node3D
	if ref_anim:
		_crusher_wheel = ref_anim.get_node_or_null("CrusherWheel") as Node3D
		_furnace_mesh = ref_anim.get_node_or_null("FurnaceCore") as MeshInstance3D
		if _furnace_mesh and _furnace_mesh.mesh and _furnace_mesh.mesh.get_surface_count() > 0:
			var m := _furnace_mesh.mesh.surface_get_material(0)
			if m is ShaderMaterial:
				_furnace_mat = m

	_crane_jib = get_node_or_null("QuarryCrane/JibPivot") as Node3D

	for en_name in ["ExtractionNode_Copper", "ExtractionNode_Silicon", "ExtractionNode_Alloy"]:
		var node := get_node_or_null(en_name)
		if node:
			var yi := node.get_node_or_null("YieldIcon") as Node3D
			if yi:
				_yield_icons.append(yi)

	_conveyor_root = get_node_or_null("ConveyorBeltRoot") as Node3D
	if _conveyor_root:
		for i in range(5):
			var ore := _conveyor_root.get_node_or_null("ConveyorOre_%d" % i) as Node3D
			if ore:
				_conveyor_ores.append(ore)
		_conveyor_root.visible = is_instance_valid(TechOpsManager) and TechOpsManager.conveyor_installed

func _process(delta: float) -> void:
	if GameManager.current_state == GameManager.GameState.MAIN_MENU or GameManager.current_state == GameManager.GameState.PAUSED:
		return
	_t += delta

	# 1. Carrello minerario avanti/indietro sui binari dalla galleria allo slargo di carico
	if is_instance_valid(_minecart):
		var phase := 0.5 - 0.5 * cos(_t * 0.42)
		var target_z := lerpf(CART_START_Z, CART_END_Z, phase)
		var dz := target_z - _last_cart_z
		_minecart.position.z = target_z
		_last_cart_z = target_z
		var w_rot := dz / 0.15
		for w in _cart_wheels:
			if is_instance_valid(w):
				w.rotate_x(w_rot)

	# 2. Volano frantoio + pulsazione fornace di fusione
	if is_instance_valid(_crusher_wheel):
		_crusher_wheel.rotate_z(delta * 2.1)
	if is_instance_valid(_furnace_mat):
		_furnace_mat.set_shader_parameter("emission_energy", 1.7 + sin(_t * 4.5) * 0.45)

	# 3. Movimento lento e maestoso della Gru di Cava
	if is_instance_valid(_crane_jib):
		_crane_jib.rotation.y = 0.45 + sin(_t * 0.24) * 0.55

	# 4. Fluttuazione cristalli raccoglibili sui filoni
	for idx in range(_yield_icons.size()):
		var yi := _yield_icons[idx]
		if is_instance_valid(yi):
			yi.rotation.y += delta * 1.4
			yi.position.y = 0.56 + sin(_t * 2.4 + float(idx) * 1.3) * 0.08

	# 5. Nastro trasportatore automatico (visibile e animato dopo l'installazione!)
	if is_instance_valid(_conveyor_root):
		var installed := is_instance_valid(TechOpsManager) and TechOpsManager.conveyor_installed
		if _conveyor_root.visible != installed:
			_conveyor_root.visible = installed
		if installed and not _conveyor_ores.is_empty():
			var n := float(_conveyor_ores.size())
			for oi in range(_conveyor_ores.size()):
				var ore := _conveyor_ores[oi]
				if not is_instance_valid(ore):
					continue
				var u := fmod(_t * 0.18 + float(oi) / n, 1.0)
				if u < 0.48:
					ore.position = CONVEYOR_START.lerp(CONVEYOR_MID, u / 0.48)
				else:
					ore.position = CONVEYOR_MID.lerp(CONVEYOR_END, (u - 0.48) / 0.52)
				ore.rotation.y += delta * 0.9
