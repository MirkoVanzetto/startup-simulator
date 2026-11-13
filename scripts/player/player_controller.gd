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

func _unhandled_input(event: InputEvent) -> void:
	if GameManager.current_state != GameManager.GameState.FIRST_PERSON:
		return
		
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		neck.rotate_x(-event.relative.y * mouse_sensitivity)
		neck.rotation.x = clamp(neck.rotation.x, deg_to_rad(-85), deg_to_rad(85))
		
	if event.is_action_pressed("interact"):
		if current_target != null:
			current_target.interact(self)

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
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	var is_sprinting = Input.is_action_pressed("sprint") and NeedsManager.get_energy() > 0.0
	var gadget_mult: float = 1.18 if ShopManager.has_gadget("gadget_scarpe_pro") else 1.0
	var speed = (sprint_speed if is_sprinting else walk_speed) * NeedsManager.get_speed_multiplier() * gadget_mult
	
	if direction:
		if is_sprinting and is_on_floor():
			NeedsManager.consume_sprint(delta) # lo scatto consuma un po' di energia
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
	# 2) Fallback spaziale accurato (Studio legno, Negozi piastrelle, Viale Est asfalto, Borghi pietra)
	if global_position.z < 2.3 and absf(global_position.x) < 4.0:
		return "wood"
	if global_position.x > 79.0 and global_position.x < 91.5 and absf(global_position.z - 27.5) < 6.0:
		return "tile"
	if global_position.x > 24.0 and global_position.x < 62.0 and absf(global_position.z - 28.0) < 2.8:
		return "asphalt"
	return "stone"

func _handle_interaction_ray() -> void:
	if interaction_ray.is_colliding():
		var collider = interaction_ray.get_collider()
		# Il primo collider colpito deve essere un interagibile: i muri azzerano target e prompt
		if collider is Interactable3D and collider.is_interactable:
			if current_target != collider:
				current_target = collider
				EventBus.prompt_changed.emit(current_target.get_prompt())
			return
			
	if current_target != null:
		current_target = null
		EventBus.prompt_changed.emit("")
