class_name ShopInteractable
extends Interactable3D
## ShopInteractable - Banco/ingresso di un negozio del borgo: apre il menu acquisti (ShopMenu)
## Rispetta gli orari di apertura/chiusura giornalieri (Sezione 10.1).

@export var shop_id: String = ""
@export var shop_title: String = ""

func _ready() -> void:
	super._ready()
	prompt_message = _build_prompt()

func _build_prompt() -> String:
	var title = shop_title
	if title == "" and shop_id != "" and ShopManager.has_shop(shop_id):
		title = ShopManager.get_shop_title(shop_id)
	if shop_id != "" and not ShopManager.is_shop_open(shop_id):
		var hrs := ShopManager.get_shop_hours_text(shop_id)
		return "[CHIUSO · %s] %s (Torna domani)" % [hrs, title if title != "" else "Negozio"]
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
	if not ShopManager.is_shop_open(shop_id):
		SoundManager.play_ui_error()
		var hrs := ShopManager.get_shop_hours_text(shop_id)
		EventBus.notification_posted.emit(
			"Negozio Chiuso (%s)" % hrs,
			"Il negozio è chiuso. Torna domani durante l'orario di apertura.",
			"warning"
		)
		return
	VillageCharacters.play_interact(self)
	if get_parent():
		for sib in get_parent().get_children():
			if sib != self and sib.name.ends_with("NPC"):
				VillageCharacters.play_interact(sib)
				break
	SoundManager.play_ui_click()
	EventBus.shop_opened.emit(shop_id)
