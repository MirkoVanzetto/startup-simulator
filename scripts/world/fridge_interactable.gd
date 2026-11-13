class_name FridgeInteractable
extends Interactable3D
## FridgeInteractable - Frigo dello studio: apre il negozio 'fridge' con le scorte comprate all'Alimentari

func _ready() -> void:
	super._ready()
	prompt_message = "[E] Apri il frigo"

func _on_interact(_player: Node) -> void:
	SoundManager.play_ui_click()
	EventBus.shop_opened.emit("fridge")
