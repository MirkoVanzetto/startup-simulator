class_name SideJobInteractable
extends Interactable3D
## SideJobInteractable - Punti 3D interattivi per Bacheca Lavori Rapidi, Cassette Postali,
## Ritiri/Consegne Corriere Express, Quadri Fibra & Bancali Logistica Merci.

@export var spot_kind: String = "bacheca" # "bacheca" | "spot"
@export var spot_id: String = ""
@export var spot_title: String = ""
@export var spot_type: String = "mailbox" # "mailbox" | "pickup" | "delivery" | "repair" | "crate_pickup" | "crate_drop"
@export var beacon_path: NodePath

func _ready() -> void:
	super._ready()
	if spot_kind == "spot" and spot_id != "" and SideJobManager != null:
		SideJobManager.register_spot(spot_id, spot_title, global_position, spot_type)
	_sync_state()
	EventBus.side_job_started.connect(func(_id, _data): _sync_state())
	EventBus.side_job_progressed.connect(func(_id, _s, _t, _l): _sync_state())
	EventBus.side_job_completed.connect(func(_id, _p, _r): _sync_state())
	EventBus.side_job_cancelled.connect(func(_id): _sync_state())

func _sync_state() -> void:
	if spot_kind == "bacheca":
		is_interactable = true
		prompt_message = get_prompt()
		return
	var active := false
	if SideJobManager != null:
		active = SideJobManager.can_interact_target(spot_id)
	is_interactable = active
	var beacon := get_node_or_null(beacon_path) as Node3D if not beacon_path.is_empty() else null
	if beacon:
		beacon.visible = active
	prompt_message = get_prompt()

func get_prompt() -> String:
	if spot_kind == "bacheca":
		if SideJobManager != null and SideJobManager.has_active_job():
			var aj: Dictionary = SideJobManager.active_job
			return "[E] Bacheca Lavori (%s: %d/%d)" % [
				str(aj.get("short_tag", "Attivo")),
				int(aj.get("step", 0)),
				int(aj.get("total", 1))
			]
		return "[E] Bacheca Lavori Rapidi (Volantinaggio, Rider, Fibra, Merci)"
	if SideJobManager == null:
		return ""
	return SideJobManager.get_target_prompt(spot_id)

func _on_interact(_player: Node) -> void:
	if spot_kind == "bacheca":
		_open_bacheca_dialogue()
		return
	if SideJobManager != null and SideJobManager.interact_target(spot_id):
		_sync_state()
		EventBus.prompt_changed.emit(get_prompt())

func _open_bacheca_dialogue() -> void:
	if SideJobManager == null:
		return
	var lines: Array[String] = []
	var opts: Array = []

	if SideJobManager.has_active_job():
		var aj: Dictionary = SideJobManager.active_job
		var title := str(aj.get("title", "Lavoretto"))
		lines.append("Hai un incarico attivo: «%s» (%d/%d tappe)." % [title, int(aj.get("step", 0)), int(aj.get("total", 1))])
		lines.append("Prossima tappa: %s" % SideJobManager.get_active_step_instruction())
		opts.append({"text": "Continua incarico attivo", "action": "close"})
		opts.append({"text": "Annulla «%s»" % title, "action": "cancel_sidejob"})
	else:
		lines.append("Bacheca Lavori Rapidi del Borgo — Scegli una missione ripetibile per finanziare la startup:")
		for d in SideJobManager.get_all_job_defs():
			var job_id := str(d["id"])
			var pay := float(d["base_pay"])
			var cd := SideJobManager.get_cooldown_remaining_minutes(job_id)
			if cd > 0:
				opts.append({"text": "[Pausa %dm] %s (€ %0.0f)" % [cd, d["title"], pay], "action": "close"})
			else:
				var st_count := int(d.get("step_count", 4))
				var bonus := float(d.get("fast_bonus", 0.0))
				opts.append({
					"text": "%s (+€ %0.0f / +€ %0.0f bonus · %d tappe)" % [d["title"], pay, bonus, st_count],
					"action": "start_sidejob_" + job_id
				})
		opts.append({"text": "Chiudi bacheca", "action": "close"})

	EventBus.dialogue_started.emit(
		"Bacheca Lavori Rapidi — Torino",
		lines,
		opts
	)
