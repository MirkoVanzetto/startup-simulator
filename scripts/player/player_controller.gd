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

func _ready() -> void:
	GameManager.player_node = self
	interaction_ray.collision_mask = 2 # Interactive layer
	interaction_ray.enabled = true

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
		
	# Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		if Input.is_action_just_pressed("jump"):
			velocity.y = jump_velocity
			
	# Movement input
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	var is_sprinting = Input.is_action_pressed("sprint")
	var speed = sprint_speed if is_sprinting else walk_speed
	
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		is_moving = true
	else:
		velocity.x = move_toward(velocity.x, 0, speed * 8.0 * delta)
		velocity.z = move_toward(velocity.z, 0, speed * 8.0 * delta)
		is_moving = false
		
	move_and_slide()
	_handle_footsteps(delta, is_sprinting)
	_handle_interaction_ray()

func _handle_footsteps(delta: float, is_sprinting: bool) -> void:
	if is_on_floor() and is_moving and velocity.length() > 0.8:
		var current_interval = 0.36 if is_sprinting else 0.52
		footstep_timer += delta
		if footstep_timer >= current_interval:
			footstep_timer = 0.0
			var surface = _detect_surface()
			SoundManager.play_footstep(surface)
	else:
		footstep_timer = 0.0

func _detect_surface() -> String:
	# Check what ground the player is walking on
	# Studio is near origin Z < 2.5 (wood), Street is Z > 2.5 (stone), Pizzeria is Z > 10.0 (terracotta/stone)
	if global_position.z < 2.3:
		return "wood"
	return "stone"

func _handle_interaction_ray() -> void:
	if interaction_ray.is_colliding():
		var collider = interaction_ray.get_collider()
		if collider is Interactable3D and collider.is_interactable:
			if current_target != collider:
				current_target = collider
				EventBus.prompt_changed.emit(current_target.get_prompt())
			return
			
	if current_target != null:
		current_target = null
		EventBus.prompt_changed.emit("")
