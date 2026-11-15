class_name OGRVialeInteractable
extends Interactable3D
## OGRVialeInteractable - Dialogo interattivo con Ing. Andrea Viale dentro OGR Tech Hub Torino.

var anim_player: AnimationPlayer = null

func _ready() -> void:
	super._ready()
	prompt_message = "[E] Parla con Ing. Andrea Viale (OGR Tech Hub)"
	_find_anim_player()
	if anim_player and anim_player.has_animation("Idle"):
		anim_player.play("Idle")

func _find_anim_player() -> void:
	if has_node("Model"):
		anim_player = $Model.find_child("AnimationPlayer", true, false)

func _on_interact(_player: Node) -> void:
	FameManager.register_talk("andrea_viale")
	if anim_player and anim_player.has_animation("Interact"):
		anim_player.play("Interact")

	ContractManager.refresh_enterprise_contracts(false)
	var tier := UpgradeManager.get_enterprise_tier() if is_instance_valid(UpgradeManager) else 1
	var stars := UpgradeManager.get_stars() if is_instance_valid(UpgradeManager) else 0
	var avail_count := ContractManager.enterprise_contracts.size()
	var active_ent := 0
	for cid in ContractManager.active_contracts:
		var c = ContractManager.active_contracts[cid]
		if c is Dictionary and bool(c.get("is_enterprise", false)) and str(c.get("status", "")) != "completed":
			active_ent += 1

	var lines := [
		"Benvenuto alle Officine Grandi Riparazioni — il cuore dell'innovazione Enterprise di Torino!",
		"Qui la Bay 01 è aperta per la tua startup: le altre sale (Pod 02, 03 e 04) ospitano consorzi e banche riservati.",
		"Livello Appalti attuale: Tier %d/4 | Bandi Enterprise disponibili su TO-OS: %d | Progetti Enterprise attivi: %d | Stelle ★: %d." % [tier, avail_count, active_ent, stars],
		"Apri l'app 'OGR Enterprise' sul tuo computer per partecipare ai maxi-bandi corporate e usa 'Potenziamenti ★' per sbloccare Tier II, III e IV!"
	]
	var choices := [
		{"text": "Come funzionano i bandi Tier II-IV alle OGR?", "action": "details_ogr"},
		{"text": "Ricevuto Ingegnere, torno subito operativo su TO-OS!", "action": "close"}
	]
	EventBus.dialogue_started.emit("Ing. Andrea Viale (OGR Tech Hub)", lines, choices)
