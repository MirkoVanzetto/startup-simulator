class_name ShopInteractable
extends Interactable3D
## ShopInteractable - Banco/ingresso di un negozio del borgo: apre il menu acquisti (ShopMenu)

@export var shop_id: String = ""
@export var shop_title: String = ""

func _ready() -> void:
	super._ready()
	prompt_message = _build_prompt()

func _build_prompt() -> String:
	var title = shop_title
	if title == "" and shop_id != "" and ShopManager.has_shop(shop_id):
		title = ShopManager.get_shop_title(shop_id)
	if title == "":
		return "[E] Entra/Acquista"
	return "[E] Entra/Acquista da %s" % title

func get_prompt() -> String:
	if not is_interactable:
		return ""
	return _build_prompt()

func _on_interact(_player: Node) -> void:
	if shop_id == "":
		return
	SoundManager.play_ui_click()
	EventBus.shop_opened.emit(shop_id)
