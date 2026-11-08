class_name Interactable3D
extends CollisionObject3D
## Interactable3D - Base class for physical interactive objects in the 3D world

signal interacted(player: Node)

@export var prompt_message: String = "[E] Interagisci"
@export var is_interactable: bool = true

func _ready() -> void:
	collision_layer = 2 # Interactive layer
	collision_mask = 0

func get_prompt() -> String:
	return prompt_message if is_interactable else ""

func interact(player: Node) -> void:
	if not is_interactable:
		return
	interacted.emit(player)
	_on_interact(player)

func _on_interact(_player: Node) -> void:
	# Virtual method to be overridden by child classes
	pass
