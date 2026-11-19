extends CharacterBody3D
## PlayerController - 3D First-Person controller with physics, interaction ray, and foley

@export var walk_speed: float = 3.6
@export var sprint_speed: float = 5.8
@export var jump_velocity: float = 4.2
@export var mouse_sensitivity: float = 0.0022
@export var gravity: float = 9.8

@onready var neck: Node3D = $Neck
@onready var camera: Camera3D = $Neck/Camera3D
@onready var interaction_ray: RayCast3D = $Neck/Camera3D/InteractionRay

var current_target: Interactable3D = null
var footstep_timer: float = 0.0
var step_interval: float = 0.45
var is_moving: bool = false
var ground_ray: RayCast3D = null

var _step_distance: float = 0.0
var _left_foot_next: bool = true
var _was_on_floor: bool = true
var _peak_fall_speed: float = 0.0

const VALID_SURFACES: Array[String] = ["grass", "stone", "wood", "tile", "asphalt", "metal"]
const WALK_STRIDE_METERS: float = 1.68
const SPRINT_STRIDE_METERS: float = 2.15

func _ready() -> void:
	GameManager.player_node = self
	# Layer 1 (mondo) + layer 2 (interattivi): i muri bloccano il raggio di interazione
	interaction_ray.collision_mask = 3
	interaction_ray.enabled = true
	
	# Raggio verso il basso per riconoscere la superficie sotto i piedi (meta 'surface')
	ground_ray = RayCast3D.new()
	ground_ray.name = "GroundRay"
	ground_ray.position = Vector3(0, 0.5, 0)
	ground_ray.target_position = Vector3(0, -1.2, 0)
	ground_ray.collision_mask = 1 # Solo il mondo
	ground_ray.exclude_parent = true
	ground_ray.enabled = true
	add_child(ground_ray)

var _bike_cockpit: Node3D = null
var _bike_handlebar: Node3D = null
var _bike_front_wheel: Node3D = null
var _bike_speed: float = 0.0
var _bike_steer: float = 0.0
var _bike_wheel_spin: float = 0.0
var _bike_cam_cache: Camera3D = null
var _bike_head_cache: Node3D = null
var _bike_signal_bound: bool = false

func _ensure_bike_cockpit() -> void:
	if _bike_cockpit == null or not is_instance_valid(_bike_cockpit):
		_bike_cockpit = get_node_or_null("BikeCockpit") as Node3D
		if _bike_cockpit == null:
			_bike_cockpit = VillageProps.add_bicycle_cockpit(self)
		_bike_handlebar = _bike_cockpit.get_node_or_null("HandlebarPivot") as Node3D
		_bike_front_wheel = _bike_cockpit.get_node_or_null("HandlebarPivot/FrontWheelPivot") as Node3D
		_bike_head_cache = get_node_or_null("Neck") as Node3D
		if _bike_head_cache == null:
			_bike_head_cache = get_node_or_null("Head") as Node3D
		_bike_cam_cache = get_node_or_null("Neck/Camera3D") as Camera3D
		if _bike_cam_cache == null:
			_bike_cam_cache = get_node_or_null("Head/Camera3D") as Camera3D
		if _bike_cam_cache == null:
			_bike_cam_cache = find_child("Camera3D", true, false) as Camera3D
	if not _bike_signal_bound and is_instance_valid(EventBus) and EventBus.has_signal("vehicle_changed"):
		EventBus.vehicle_changed.connect(_on_vehicle_changed_bike)
		_bike_signal_bound = true
	if _bike_cockpit and is_instance_valid(TechOpsManager):
		_bike_cockpit.visible = (TechOpsManager.active_vehicle == "bike")

func _on_vehicle_changed_bike(v_id: String) -> void:
	var on_bike := (v_id == "bike")
	if _bike_cockpit and is_instance_valid(_bike_cockpit):
		_bike_cockpit.visible = on_bike
	if not on_bike:
		_bike_speed = 0.0
		_bike_steer = 0.0
		if _bike_head_cache and is_instance_valid(_bike_head_cache):
			_bike_head_cache.rotation.z = 0.0
		if _bike_cam_cache and is_instance_valid(_bike_cam_cache):
			_bike_cam_cache.fov = 75.0

func dismount_and_park_bike() -> bool:
	if not is_instance_valid(TechOpsManager) or TechOpsManager.active_vehicle != "bike":
		return false
	var world_root := get_tree().root
	var bike_sb := world_root.find_child("BikeStation_Studio", true, false) as Node3D
	if bike_sb:
		var cand_offsets: Array[Vector3] = [
			transform.basis.x * 1.15 - transform.basis.z * 0.35,
			-transform.basis.x * 1.15 - transform.basis.z * 0.35,
			-transform.basis.z * 1.35,
			Vector3.ZERO
		]
		var chosen: Vector3 = global_position + cand_offsets[0]
		var space := get_world_3d().direct_space_state if get_world_3d() else null
		for off in cand_offsets:
			var test_p: Vector3 = global_position + off
			if space == null or off == Vector3.ZERO:
				chosen = test_p
				break
			var rq := PhysicsRayQueryParameters3D.create(global_position + Vector3(0, 0.9, 0), test_p + Vector3(0, 0.9, 0))
			rq.exclude = [get_rid()]
			if space.intersect_ray(rq).is_empty():
				chosen = test_p
				break
		bike_sb.global_position = Vector3(chosen.x, global_position.y + 0.85, chosen.z)
		bike_sb.rotation.y = rotation.y + PI * 0.5
	TechOpsManager.active_vehicle = "foot"
	if is_instance_valid(EventBus):
		EventBus.vehicle_changed.emit("foot")
		EventBus.tech_ops_updated.emit()
		EventBus.notification_posted.emit("Bicicletta Parcheggiata", "Premi [E] vicino alla bici per risalire.", "info")
	return true

func _apply_bike_physics(delta: float, input_dir: Vector2) -> void:
	var forward_in := -input_dir.y
	var steer_in := -input_dir.x
	var is_boosting := Input.is_action_pressed("sprint") and is_instance_valid(NeedsManager) and NeedsManager.get_energy() > 0.0
	var max_fwd := 9.1 if is_boosting else 7.8
	if forward_in > 0.05:
		_bike_speed = move_toward(_bike_speed, max_fwd * forward_in, 6.8 * delta)
		if is_boosting and is_on_floor():
			var drain_mult: float = UpgradeManager.get_sprint_drain_mult() if is_instance_valid(UpgradeManager) else 1.0
			var veh_drain: float = TechOpsManager.get_vehicle_sprint_drain_mult() if is_instance_valid(TechOpsManager) else 1.0
			NeedsManager.consume_sprint(delta * drain_mult * veh_drain * 0.65)
	elif forward_in < -0.05:
		if _bike_speed > 0.2:
			_bike_speed = move_toward(_bike_speed, 0.0, 13.5 * delta)
		else:
			_bike_speed = move_toward(_bike_speed, -2.2, 4.5 * delta)
	else:
		_bike_speed = move_toward(_bike_speed, 0.0, 2.2 * delta)

	_bike_steer = lerpf(_bike_steer, steer_in, clampf(delta * 8.0, 0.0, 1.0))
	if absf(_bike_speed) > 0.35 and absf(steer_in) > 0.05:
		var turn_sign := 1.0 if _bike_speed >= 0.0 else -1.0
		rotate_y(steer_in * turn_sign * 1.45 * delta)

	var fwd_vec := (-transform.basis.z).normalized()
	var strafe_vec := (transform.basis.x).normalized()
	var side_slip := -steer_in * 1.35 if absf(_bike_speed) < 0.8 else 0.0
	velocity.x = fwd_vec.x * _bike_speed + strafe_vec.x * side_slip
	velocity.z = fwd_vec.z * _bike_speed + strafe_vec.z * side_slip
	is_moving = absf(_bike_speed) > 0.35

	_bike_wheel_spin -= (_bike_speed * delta) / 0.33
	if _bike_handlebar and is_instance_valid(_bike_handlebar):
		_bike_handlebar.rotation.y = _bike_steer * 0.30
	if _bike_front_wheel and is_instance_valid(_bike_front_wheel):
		_bike_front_wheel.rotation.x = _bike_wheel_spin
	if _bike_cockpit and is_instance_valid(_bike_cockpit):
		_bike_cockpit.rotation.z = -_bike_steer * clampf(absf(_bike_speed) / 7.8, 0.0, 1.0) * 0.055
	if _bike_head_cache and is_instance_valid(_bike_head_cache):
		var target_roll := -_bike_steer * clampf(absf(_bike_speed) / 7.8, 0.0, 1.0) * 0.045
		_bike_head_cache.rotation.z = lerpf(_bike_head_cache.rotation.z, target_roll, clampf(delta * 8.0, 0.0, 1.0))
	if _bike_cam_cache and is_instance_valid(_bike_cam_cache):
		var target_fov := 75.0 + clampf(absf(_bike_speed) / 9.0, 0.0, 1.0) * 5.5
		_bike_cam_cache.fov = lerpf(_bike_cam_cache.fov, target_fov, clampf(delta * 6.0, 0.0, 1.0))

func _unhandled_input(event: InputEvent) -> void:
	if GameManager.current_state != GameManager.GameState.FIRST_PERSON:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var kev := event as InputEventKey
		if kev.keycode == KEY_F and is_instance_valid(TechOpsManager) and TechOpsManager.active_vehicle == "bike":
			if dismount_and_park_bike():
				return
		elif kev.keycode == KEY_G and is_instance_valid(TechOpsManager) and TechOpsManager.active_vehicle == "bike":
			if is_instance_valid(SoundManager) and SoundManager.has_method("play_bike_bell"):
				SoundManager.play_bike_bell()
		
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		neck.rotate_x(-event.relative.y * mouse_sensitivity)
		neck.rotation.x = clamp(neck.rotation.x, deg_to_rad(-85), deg_to_rad(85))
		
	if event.is_action_pressed("interact"):
		if current_target != null:
			current_target.interact(self)
			if is_instance_valid(current_target):
				EventBus.prompt_changed.emit(current_target.get_prompt())

func _physics_process(delta: float) -> void:
	if GameManager.current_state != GameManager.GameState.FIRST_PERSON:
		velocity.x = move_toward(velocity.x, 0.0, walk_speed)
		velocity.z = move_toward(velocity.z, 0.0, walk_speed)
		move_and_slide()
		return
		
	# Gravity & jump
	if not is_on_floor():
		velocity.y -= gravity * delta
		_peak_fall_speed = maxf(_peak_fall_speed, -velocity.y)
	else:
		if Input.is_action_just_pressed("jump"):
			velocity.y = jump_velocity
			SoundManager.play_jump()
			_was_on_floor = false
			_peak_fall_speed = 0.0
			
	# Movement input
	_ensure_bike_cockpit()
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var riding_bike := is_instance_valid(TechOpsManager) and TechOpsManager.active_vehicle == "bike" and GameManager.current_state == GameManager.GameState.FIRST_PERSON
	var is_sprinting = Input.is_action_pressed("sprint") and NeedsManager.get_energy() > 0.0

	if riding_bike:
		_apply_bike_physics(delta, input_dir)
	else:
		var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		var gadget_mult: float = 1.18 if ShopManager.has_gadget("gadget_scarpe_pro") else 1.0
		var skill_mult: float = UpgradeManager.get_speed_mult() if is_instance_valid(UpgradeManager) else 1.0
		var vehicle_mult: float = TechOpsManager.get_vehicle_speed_mult() if is_instance_valid(TechOpsManager) else 1.0
		var speed = (sprint_speed if is_sprinting else walk_speed) * NeedsManager.get_speed_multiplier() * gadget_mult * skill_mult * vehicle_mult

		if direction:
			if is_sprinting and is_on_floor():
				var drain_mult: float = UpgradeManager.get_sprint_drain_mult() if is_instance_valid(UpgradeManager) else 1.0
				var veh_drain: float = TechOpsManager.get_vehicle_sprint_drain_mult() if is_instance_valid(TechOpsManager) else 1.0
				NeedsManager.consume_sprint(delta * drain_mult * veh_drain) # lo scatto consuma un po' di energia
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
			is_moving = true
		else:
			velocity.x = move_toward(velocity.x, 0, speed * 8.0 * delta)
			velocity.z = move_toward(velocity.z, 0, speed * 8.0 * delta)
			is_moving = false

	move_and_slide()

	var grounded_now := is_on_floor()
	if grounded_now and not _was_on_floor and _peak_fall_speed > 2.2:
		SoundManager.play_land(_detect_surface(), _peak_fall_speed)
		_step_distance = 0.0
	_peak_fall_speed = 0.0 if grounded_now else maxf(_peak_fall_speed, -velocity.y)
	_was_on_floor = grounded_now

	if not riding_bike:
		_handle_footsteps(delta, is_sprinting)
	_handle_interaction_ray()

func _handle_footsteps(delta: float, is_sprinting: bool) -> void:
	var horiz_speed := Vector2(velocity.x, velocity.z).length()
	if is_on_floor() and is_moving and horiz_speed > 0.8:
		var stride := SPRINT_STRIDE_METERS if is_sprinting else WALK_STRIDE_METERS
		_step_distance += horiz_speed * delta
		if _step_distance >= stride:
			_step_distance = fmod(_step_distance, stride)
			var surface := _detect_surface()
			SoundManager.play_footstep(surface, is_sprinting, _left_foot_next)
			_left_foot_next = not _left_foot_next
	else:
		# Precarica 65% della falcata così appena ricominci a camminare il primo passo è reattivo
		_step_distance = WALK_STRIDE_METERS * 0.65

func _detect_surface() -> String:
	# 1) Meta-tag 'surface' sul collider sotto i piedi (o su un suo antenato diretto)
	if ground_ray != null and ground_ray.is_inside_tree():
		ground_ray.force_raycast_update()
		if ground_ray.is_colliding():
			var node: Node = ground_ray.get_collider() as Node
			var depth = 0
			while node != null and depth < 4:
				if node.has_meta("surface"):
					var tagged = str(node.get_meta("surface"))
					if tagged in VALID_SURFACES:
						return tagged
				node = node.get_parent()
				depth += 1
	# 2) Fallback spaziale accurato (Studio legno, Officina piastrelle, OGR cemento/tile, Viale Est asfalto, Borghi/Parco/Mercato pietra)
	if global_position.z < 2.3 and absf(global_position.x) < 4.0:
		return "wood"
	if global_position.x > 79.0 and global_position.x < 91.5 and absf(global_position.z - 27.5) < 6.0:
		return "tile"
	if global_position.x > 96.0 and absf(global_position.z - 2.8) < 12.5:
		return "tile"
	if global_position.x > 24.0 and global_position.x < 62.0 and absf(global_position.z - 28.0) < 2.8:
		return "asphalt"
	if global_position.x < -24.0 and global_position.z < 33.5 and global_position.x > -42.0:
		return "stone"
	return "stone"

func _handle_interaction_ray() -> void:
	var reach := 3.4 + (UpgradeManager.get_interaction_reach_bonus() if is_instance_valid(UpgradeManager) else 0.0)
	if interaction_ray:
		interaction_ray.target_position = Vector3(0, 0, -reach)

	if interaction_ray.is_colliding():
		var collider = interaction_ray.get_collider()
		# Il primo collider colpito deve essere un interagibile: i muri azzerano target e prompt
		if collider is Interactable3D and collider.is_interactable:
			if current_target != collider:
				current_target = collider
				EventBus.prompt_changed.emit(current_target.get_prompt())
			return

	# Cono visivo ravvicinato con controllo muri (aiuta stazione Wi-Fi a parete e pannelli)
	var fallback := _find_cone_interactable(reach)
	if fallback != null:
		if current_target != fallback:
			current_target = fallback
			EventBus.prompt_changed.emit(current_target.get_prompt())
		return
			
	if current_target != null:
		current_target = null
		EventBus.prompt_changed.emit("")

func _find_cone_interactable(reach: float) -> Interactable3D:
	if camera == null or not is_inside_tree():
		return null
	var origin := camera.global_position
	var forward := -camera.global_transform.basis.z.normalized()
	var space := get_world_3d().direct_space_state if get_world_3d() else null
	if space == null:
		return null

	var best: Interactable3D = null
	var best_score := -1.0
	var max_dist := reach + 0.35
	for cand in get_tree().get_nodes_in_group("interactable"):
		if not (cand is Interactable3D):
			continue
		var ic := cand as Interactable3D
		if not ic.is_interactable or not ic.is_inside_tree():
			continue
		var tgt_pos := ic.global_position
		var to_tgt := tgt_pos - origin
		var dist := to_tgt.length()
		if dist < 0.15 or dist > max_dist:
			continue
		var dir := to_tgt / dist
		var align := forward.dot(dir)
		if align < 0.87:
			continue
		# Verifica linea visiva non bloccata da pareti/muri (collision layer 1)
		var q := PhysicsRayQueryParameters3D.create(origin, origin + dir * maxf(dist - 0.35, 0.1), 1)
		q.exclude = [get_rid(), ic.get_rid()]
		var hit := space.intersect_ray(q)
		if not hit.is_empty():
			continue
		var score := align * 2.0 - (dist / max_dist) * 0.6
		if score > best_score:
			best_score = score
			best = ic
	return best
