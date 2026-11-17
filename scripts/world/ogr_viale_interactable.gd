class_name OGRVialeInteractable
extends Interactable3D
## OGRVialeInteractable - Dialogo interattivo con Ing. Andrea Viale dentro OGR Tech Hub Torino.
## Introduce sia i Bandi Corporate OGR Enterprise sia la nuova Fase 3/4 Post-OGR (Polo Materiali, Robot, Drone & Dipartimenti).

var anim_player: AnimationPlayer = null

func _ready() -> void:
	super._ready()
	prompt_message = "[E] Parla con Ing. Andrea Viale (OGR Tech Hub & Progetti Industriali)"
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

	if is_instance_valid(TechOpsManager):
		TechOpsManager.start_post_ogr_expansion()

	ContractManager.refresh_enterprise_contracts(false)
	var tier := UpgradeManager.get_enterprise_tier() if is_instance_valid(UpgradeManager) else 1
	var stars := UpgradeManager.get_stars() if is_instance_valid(UpgradeManager) else 0
	var avail_count := ContractManager.enterprise_contracts.size()
	var rc := TechOpsManager.research_credits if is_instance_valid(TechOpsManager) else 0
	var stage_txt := TechOpsManager.get_post_ogr_objective_text() if is_instance_valid(TechOpsManager) else ""

	var lines := [
		"Benvenuto alle Officine Grandi Riparazioni — il trampolino di lancio verso l'industria tecnologica torinese!",
		"Oltre ai bandi corporate sulla Bay 01, ho appena autorizzato la tua startup ad accedere al Polo Estrazione & Robotica nel cortile Sud delle OGR (con l'Ing. Dario Ferrero) e al Lab Droni di Borgo Po!",
		"Stato: Bandi Tier %d/4 (%d disponibili) | Stelle ★: %d | Crediti di Ricerca: 🔬 %d RC." % [tier, avail_count, stars, rc],
		"Obiettivo Tecnologico attuale: %s" % (stage_txt if stage_txt != "" else "Raccogli materiali al Polo OGR, sblocca il Mining Robot MK1 e costruisci il TO-Drone MK1!")
	]
	var choices := [
		{"text": "Spiegami il piano Materiali, Mining Robot MK1 e Costruzione Drone 3D!", "action": "details_post_ogr"},
		{"text": "Come funzionano i bandi Tier II-IV alle OGR?", "action": "details_ogr"},
		{"text": "Ricevuto Ingegnere, mi metto subito all'opera!", "action": "close"}
	]
	EventBus.dialogue_started.emit("Ing. Andrea Viale (OGR Tech Hub)", lines, choices)
