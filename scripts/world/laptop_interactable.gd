class_name LaptopInteractable
extends Interactable3D
## LaptopInteractable - Triggers the laptop OS interface (TO-OS)

func _ready() -> void:
	super._ready()
	prompt_message = "[E] Usa Laptop (TO-OS)"

func _on_interact(_player: Node) -> void:
	SoundManager.play_ui_click()
	EventBus.computer_opened.emit()
