extends Node
## SideJobManager - Autoload per attività ripetibili e lavoretti rapidi di quartiere (v1.2.0).
## Permette di guadagnare capitale e reputazione in autonomia oltre ai contratti B2B:
## 1) Volantinaggio Quartiere (5 cassette postali)
## 2) Corriere Espresso / Rider Pizza & Caffè (ritiro + consegne a domicilio con bonus rapidità)
## 3) Ripristino Quadri Fibra & POS (calibrazione cabine e terminali cittadini)
## 4) Scarico Merci & Logistica (navetta casse tra Hub/Furgone, Mercato e Officina)

const SIDE_JOBS: Dictionary = {
	"volantinaggio": {
		"id": "volantinaggio",
		"title": "Volantinaggio Quartiere",
		"short_tag": "Volantini",
		"summary": "Distribuisci 5 pacchi di volantini nelle cassette postali tra San Carlo, Parco Valentino e Valdocco.",
		"base_pay": 42.0,
		"rep_reward": 4,
		"energy_cost_per_step": 2.5,
		"cooldown_minutes": 90,
		"fast_limit_sec": 180.0,
		"fast_bonus": 6.0,
		"pool": [
			"mailbox_sancarlo_ovest",
			"mailbox_sancarlo_est",
			"mailbox_parco_villa_nord",
			"mailbox_parco_villa_sud",
			"mailbox_valdocco_casa",
			"mailbox_mercato_nord"
		],
		"step_count": 5,
		"verb": "Imbuca volantini"
	},
	"corriere_espresso": {
		"id": "corriere_espresso",
		"title": "Corriere Espresso Quartiere",
		"short_tag": "Rider",
		"summary": "Ritira ordinazioni calde (pizzeria/caffè) e consegnale alle porte di ville, OGR Coworking e portoni.",
		"base_pay": 58.0,
		"rep_reward": 5,
		"energy_cost_per_step": 3.0,
		"cooldown_minutes": 120,
		"fast_limit_sec": 150.0,
		"fast_bonus": 14.0,
		"pickup_pool": ["pickup_pizzeria_rider", "pickup_cafe_rider"],
		"drop_pool": ["delivery_parco_villa", "delivery_ogr_cowork", "delivery_sancarlo_est", "delivery_valdocco_porta"],
		"step_count": 4,
		"verb": "Consegna ordine"
	},
	"riparazione_rapida": {
		"id": "riparazione_rapida",
		"title": "Ripristino Quadri Fibra & POS",
		"short_tag": "Tecnico",
		"summary": "Ispeziona e riavvia 3 armadi stradali Fibra / POS tra San Carlo, Parco Valentino e Mercato Rionale.",
		"base_pay": 72.0,
		"rep_reward": 6,
		"energy_cost_per_step": 3.5,
		"cooldown_minutes": 150,
		"fast_limit_sec": 210.0,
		"fast_bonus": 10.0,
		"pool": [
			"repair_cab_via_po",
			"repair_cab_parco",
			"repair_cab_valdocco",
			"repair_cab_mercato"
		],
		"step_count": 3,
		"verb": "Ripristina quadro Fibra"
	},
	"logistica_merci": {
		"id": "logistica_merci",
		"title": "Scarico Merci & Logistica",
		"short_tag": "Logistica",
		"summary": "Sposta casse da Ufficio Postale e Furgone Est verso Mercato Rionale e Officina Bellini (2 tratte).",
		"base_pay": 68.0,
		"rep_reward": 5,
		"energy_cost_per_step": 4.5,
		"cooldown_minutes": 120,
		"fast_limit_sec": 190.0,
		"fast_bonus": 12.0,
		"pairs": [
			["crate_hub_poste", "crate_drop_mercato"],
			["crate_hub_furgone", "crate_drop_officina"]
		],
		"step_count": 4,
		"verb": "Carica/Scarica cassa"
	}
}

const DEFAULT_SPOTS: Dictionary = {
	"mailbox_sancarlo_ovest": {"label": "Cassetta Piazzetta Ovest", "pos": Vector3(-9.8, 0.0, 15.6), "kind": "mailbox"},
	"mailbox_sancarlo_est": {"label": "Cassetta Piazzetta Est", "pos": Vector3(9.8, 0.0, 15.6), "kind": "mailbox"},
	"mailbox_parco_villa_nord": {"label": "Cassetta Villa Valentino Nord", "pos": Vector3(-38.0, 0.0, 19.3), "kind": "mailbox"},
	"mailbox_parco_villa_sud": {"label": "Cassetta Residenza Parco Est", "pos": Vector3(-31.4, 0.0, 29.2), "kind": "mailbox"},
	"mailbox_valdocco_casa": {"label": "Cassetta Borgo Valdocco", "pos": Vector3(64.5, 0.0, 19.6), "kind": "mailbox"},
	"mailbox_mercato_nord": {"label": "Cassetta Coworking OGR", "pos": Vector3(87.8, 0.0, 6.8), "kind": "mailbox"},

	"pickup_pizzeria_rider": {"label": "Ritiro Pizzeria Da Mario", "pos": Vector3(-4.8, 0.0, 27.6), "kind": "pickup"},
	"pickup_cafe_rider": {"label": "Ritiro Caffè San Carlo", "pos": Vector3(-9.6, 0.0, 23.6), "kind": "pickup"},
	"delivery_parco_villa": {"label": "Porta Villa Parco Valentino", "pos": Vector3(-34.0, 0.0, 19.6), "kind": "delivery"},
	"delivery_ogr_cowork": {"label": "Ingresso Coworking OGR", "pos": Vector3(87.4, 0.0, 2.8), "kind": "delivery"},
	"delivery_sancarlo_est": {"label": "Portone San Carlo Sud-Est", "pos": Vector3(11.8, 0.0, 32.2), "kind": "delivery"},
	"delivery_valdocco_porta": {"label": "Portone Residenza Valdocco", "pos": Vector3(66.5, 0.0, 36.0), "kind": "delivery"},

	"repair_cab_via_po": {"label": "Armadio Fibra Via Po Ovest", "pos": Vector3(-17.8, 0.0, 25.0), "kind": "repair"},
	"repair_cab_parco": {"label": "Armadio Fibra Parco Valentino", "pos": Vector3(-29.8, 0.0, 34.0), "kind": "repair"},
	"repair_cab_valdocco": {"label": "Quadro Fibra Borgo Valdocco", "pos": Vector3(63.0, 0.0, 21.8), "kind": "repair"},
	"repair_cab_mercato": {"label": "Terminale POS Mercato Nord", "pos": Vector3(70.4, 0.0, 2.5), "kind": "repair"},

	"crate_hub_poste": {"label": "Bancale Ufficio Postale Nord", "pos": Vector3(69.6, 0.0, 8.8), "kind": "crate_pickup"},
	"crate_drop_mercato": {"label": "Banco Consegne Mercato Rionale", "pos": Vector3(78.5, 0.0, -1.2), "kind": "crate_drop"},
	"crate_hub_furgone": {"label": "Furgone Consegne Viale Est", "pos": Vector3(39.8, 0.0, 23.0), "kind": "crate_pickup"},
	"crate_drop_officina": {"label": "Baia Scarico Officina Bellini", "pos": Vector3(78.6, 0.0, 23.6), "kind": "crate_drop"}
}

var registered_spots: Dictionary = {}
var active_job: Dictionary = {}
var cooldowns_until: Dictionary = {} # job_id -> total game minutes
var completed_counts: Dictionary = {} # job_id -> int
var total_earned: float = 0.0
var _elapsed_active_sec: float = 0.0
var _seq_seed: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta: float) -> void:
	if active_job.is_empty():
		return
	if GameManager.current_state == GameManager.GameState.FIRST_PERSON:
		_elapsed_active_sec += delta

func get_current_total_minutes() -> int:
	return ((CalendarSystem.current_day - 1) * 1440) + (CalendarSystem.current_hour * 60) + CalendarSystem.current_minute

func register_spot(spot_id: String, label: String, world_pos: Vector3, kind: String) -> void:
	registered_spots[spot_id] = {
		"id": spot_id,
		"label": label,
		"pos": world_pos,
		"kind": kind
	}

func get_spot_info(spot_id: String) -> Dictionary:
	if registered_spots.has(spot_id):
		return registered_spots[spot_id]
	if DEFAULT_SPOTS.has(spot_id):
		var d: Dictionary = DEFAULT_SPOTS[spot_id].duplicate()
		d["id"] = spot_id
		return d
	return {"id": spot_id, "label": spot_id, "pos": Vector3.ZERO, "kind": "generic"}

func get_all_job_defs() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for jid in ["volantinaggio", "corriere_espresso", "riparazione_rapida", "logistica_merci"]:
		if SIDE_JOBS.has(jid):
			out.append(SIDE_JOBS[jid])
	return out

func get_job_def(job_id: String) -> Dictionary:
	return SIDE_JOBS.get(job_id, {})

func has_active_job() -> bool:
	return not active_job.is_empty()

func get_cooldown_remaining_minutes(job_id: String) -> int:
	if not cooldowns_until.has(job_id):
		return 0
	var rem := int(cooldowns_until[job_id]) - get_current_total_minutes()
	return maxi(0, rem)

func is_job_on_cooldown(job_id: String) -> bool:
	return get_cooldown_remaining_minutes(job_id) > 0

func start_job(job_id: String) -> bool:
	if not SIDE_JOBS.has(job_id):
		return false
	if has_active_job():
		EventBus.notification_posted.emit(
			"Attività Già Attiva",
			"Completa o annulla prima «%s» prima di iniziare un altro lavoretto." % str(active_job.get("title", "")),
			"warning"
		)
		return false
	var rem := get_cooldown_remaining_minutes(job_id)
	if rem > 0:
		EventBus.notification_posted.emit(
			"Turno in Pausa",
			"Questo incarico tornerà disponibile tra %d minuti di gioco." % rem,
			"warning"
		)
		return false
	if NeedsManager.get_energy() < 8.0:
		EventBus.notification_posted.emit(
			"Energia Insufficiente",
			"Sei troppo stanco (<8 Energia)! Bevi un caffè o riposa un'ora nel tuo studio.",
			"warning"
		)
		SoundManager.play_ui_error()
		return false

	var def: Dictionary = SIDE_JOBS[job_id]
	var targets := _build_route_for_job(job_id, def)
	if targets.is_empty():
		return false

	_elapsed_active_sec = 0.0
	active_job = {
		"id": job_id,
		"title": str(def["title"]),
		"short_tag": str(def["short_tag"]),
		"step": 0,
		"total": targets.size(),
		"targets": targets,
		"carrying_label": ""
	}
	_sync_active_waypoint()
	SoundManager.play_ui_success()
	EventBus.side_job_started.emit(job_id, active_job.duplicate(true))
	EventBus.side_job_progressed.emit(job_id, 0, targets.size(), get_active_step_instruction())
	EventBus.notification_posted.emit(
		"Lavoretto Avviato: %s" % active_job["title"],
		"%s (%d tappe) — Segui la bussola ⚑!" % [get_active_step_instruction(), targets.size()],
		"contract"
	)
	SaveManager.request_auto_save()
	return true

func _build_route_for_job(job_id: String, def: Dictionary) -> Array[String]:
	var rng := RandomNumberGenerator.new()
	_seq_seed += 1
	rng.seed = Time.get_ticks_usec() + _seq_seed * 97
	var targets: Array[String] = []

	if job_id == "corriere_espresso":
		var pickups: Array = def["pickup_pool"].duplicate()
		var p_idx := rng.randi_range(0, pickups.size() - 1)
		targets.append(str(pickups[p_idx]))
		var drops: Array = def["drop_pool"].duplicate()
		_shuffle_with_rng(drops, rng)
		for i in range(mini(3, drops.size())):
			targets.append(str(drops[i]))
	elif job_id == "logistica_merci":
		var pairs: Array = def["pairs"].duplicate(true)
		if rng.randi_range(0, 1) == 1:
			pairs.reverse()
		for pair in pairs:
			targets.append(str(pair[0]))
			targets.append(str(pair[1]))
	else:
		var pool: Array = def["pool"].duplicate()
		_shuffle_with_rng(pool, rng)
		var count := mini(int(def.get("step_count", 4)), pool.size())
		for i in range(count):
			targets.append(str(pool[i]))
	return targets

func _shuffle_with_rng(arr: Array, rng: RandomNumberGenerator) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp

func cancel_active_job() -> void:
	if active_job.is_empty():
		return
	var jid := str(active_job.get("id", ""))
	var ttl := str(active_job.get("title", ""))
	active_job.clear()
	_elapsed_active_sec = 0.0
	if str(GameManager.active_waypoint.get("id", "")).begins_with("sidejob_"):
		GameManager.clear_waypoint()
	EventBus.side_job_cancelled.emit(jid)
	EventBus.notification_posted.emit("Lavoretto Annullato", "Hai interrotto «%s»." % ttl, "info")
	SaveManager.request_auto_save()

func get_current_target_id() -> String:
	if active_job.is_empty():
		return ""
	var targets: Array = active_job.get("targets", [])
	var idx := int(active_job.get("step", 0))
	if idx < 0 or idx >= targets.size():
		return ""
	return str(targets[idx])

func can_interact_target(target_id: String) -> bool:
	return not active_job.is_empty() and get_current_target_id() == target_id

func get_current_target_info() -> Dictionary:
	var tid := get_current_target_id()
	if tid == "":
		return {}
	return get_spot_info(tid)

func get_active_step_instruction() -> String:
	if active_job.is_empty():
		return ""
	var jid := str(active_job.get("id", ""))
	var tid := get_current_target_id()
	var info := get_spot_info(tid)
	var lbl := str(info.get("label", tid))
	if jid == "volantinaggio":
		return "Imbuca volantini → %s" % lbl
	elif jid == "corriere_espresso":
		if int(active_job.get("step", 0)) == 0:
			return "Ritira ordinazioni calde → %s" % lbl
		return "Consegna a → %s" % lbl
	elif jid == "riparazione_rapida":
		return "Calibra → %s" % lbl
	elif jid == "logistica_merci":
		if str(info.get("kind", "")) == "crate_pickup":
			return "Preleva cassa → %s" % lbl
		return "Scarica cassa → %s" % lbl
	return "Raggiungi → %s" % lbl

func get_target_prompt(target_id: String) -> String:
	if not can_interact_target(target_id):
		return ""
	var jid := str(active_job.get("id", ""))
	var info := get_spot_info(target_id)
	var lbl := str(info.get("label", target_id))
	match jid:
		"volantinaggio":
			return "[E] Imbuca Volantini (%s)" % lbl
		"corriere_espresso":
			if int(active_job.get("step", 0)) == 0:
				return "[E] Ritira Borse Calde (%s)" % lbl
			return "[E] Consegna Ordine Espresso (%s)" % lbl
		"riparazione_rapida":
			return "[E] Ripristina & Calibra (%s)" % lbl
		"logistica_merci":
			if str(info.get("kind", "")) == "crate_pickup":
				return "[E] Carica Cassa Merci (%s)" % lbl
			return "[E] Scarica Cassa Merci (%s)" % lbl
		_:
			return "[E] Completa Tappa (%s)" % lbl

func interact_target(target_id: String) -> bool:
	if not can_interact_target(target_id):
		return false
	var jid := str(active_job.get("id", ""))
	var def: Dictionary = SIDE_JOBS.get(jid, {})
	if NeedsManager.get_energy() < 3.0:
		EventBus.notification_posted.emit("Troppo Stanco", "Energia esaurita! Riprendi fiato con uno spuntino o riposo.", "warning")
		SoundManager.play_ui_error()
		return false

	var e_cost := float(def.get("energy_cost_per_step", 2.5))
	NeedsManager.apply_effects(-0.6, -e_cost)

	var step := int(active_job.get("step", 0)) + 1
	var total := int(active_job.get("total", 1))
	active_job["step"] = step

	if step < total:
		SoundManager.play_ui_success()
		_sync_active_waypoint()
		var detail := get_active_step_instruction()
		EventBus.side_job_progressed.emit(jid, step, total, detail)
		EventBus.notification_posted.emit(
			"%s (%d/%d)" % [str(def["title"]), step, total],
			"Ottimo! Prossima tappa: %s" % detail,
			"info"
		)
		SaveManager.request_auto_save()
		return true

	# Giro completo -> Calcolo compenso, bonus rapidità / gadget e reputazione!
	var pay := float(def.get("base_pay", 45.0))
	var bonus_notes: Array[String] = []
	if _elapsed_active_sec > 0.0 and _elapsed_active_sec <= float(def.get("fast_limit_sec", 180.0)):
		var fb := float(def.get("fast_bonus", 8.0))
		pay += fb
		bonus_notes.append("+€ %0.0f mancia rapidità" % fb)
	if jid == "volantinaggio" and ShopManager.has_gadget("gadget_scarpe_pro"):
		pay += 6.0
		bonus_notes.append("+€ 6 Sneakers Tech")
	if jid == "riparazione_rapida" and ShopManager.has_gadget("gadget_scanner_wifi"):
		pay += 12.0
		bonus_notes.append("+€ 12 Scanner Wi-Fi")

	var upg_mult := UpgradeManager.get_side_job_pay_mult() if is_instance_valid(UpgradeManager) else 1.0
	if upg_mult > 1.001:
		pay = snappedf(pay * upg_mult, 0.01)
		bonus_notes.append("+%d%% Optics ★" % int(roundf((upg_mult - 1.0) * 100.0)))

	var rep := int(def.get("rep_reward", 4))
	EconomyManager.earn(pay, "Lavoretto Quartiere: %s" % str(def["title"]))
	FameManager.add_reputation(rep)
	total_earned += pay
	completed_counts[jid] = int(completed_counts.get(jid, 0)) + 1
	cooldowns_until[jid] = get_current_total_minutes() + int(def.get("cooldown_minutes", 90))

	if is_instance_valid(UpgradeManager) and get_completed_total() % 2 == 0:
		UpgradeManager.add_stars(1, "Traguardo %d Lavoretti Quartiere" % get_completed_total())

	var finished_title := str(def["title"])
	active_job.clear()
	_elapsed_active_sec = 0.0
	if str(GameManager.active_waypoint.get("id", "")).begins_with("sidejob_"):
		GameManager.clear_waypoint()

	SoundManager.play_cash_register()
	EventBus.side_job_completed.emit(jid, pay, rep)
	var extra_str := (" (" + ", ".join(bonus_notes) + ")") if not bonus_notes.is_empty() else ""
	EventBus.notification_posted.emit(
		"Lavoretto Completato!",
		"%s: incassati € %0.2f%s e +%d Rep!" % [finished_title, pay, extra_str, rep],
		"success"
	)
	SaveManager.request_auto_save()
	return true

func _sync_active_waypoint() -> void:
	if active_job.is_empty():
		return
	var info := get_current_target_info()
	if info.is_empty():
		return
	var wp_name := "%s (%d/%d): %s" % [
		str(active_job.get("short_tag", "Lavoretto")),
		int(active_job.get("step", 0)) + 1,
		int(active_job.get("total", 1)),
		str(info.get("label", ""))
	]
	GameManager.set_waypoint("sidejob_" + str(info.get("id", "")), wp_name, info.get("pos", Vector3.ZERO))

func get_completed_total() -> int:
	var s := 0
	for k in completed_counts:
		s += int(completed_counts[k])
	return s

func reset() -> void:
	active_job.clear()
	cooldowns_until.clear()
	completed_counts.clear()
	total_earned = 0.0
	_elapsed_active_sec = 0.0
	EventBus.side_job_cancelled.emit("")

func serialize() -> Dictionary:
	return {
		"active_job": active_job.duplicate(true),
		"cooldowns_until": cooldowns_until.duplicate(),
		"completed_counts": completed_counts.duplicate(),
		"total_earned": total_earned,
		"elapsed_active_sec": _elapsed_active_sec
	}

func deserialize(data: Dictionary) -> void:
	reset()
	if data.is_empty():
		return
	var aj = data.get("active_job", {})
	if aj is Dictionary and not aj.is_empty():
		active_job = aj.duplicate(true)
	var cd = data.get("cooldowns_until", {})
	if cd is Dictionary:
		for k in cd:
			cooldowns_until[str(k)] = int(cd[k])
	var cc = data.get("completed_counts", {})
	if cc is Dictionary:
		for k in cc:
			completed_counts[str(k)] = int(cc[k])
	total_earned = float(data.get("total_earned", 0.0))
	_elapsed_active_sec = float(data.get("elapsed_active_sec", 0.0))
	if not active_job.is_empty():
		EventBus.side_job_started.emit(str(active_job.get("id", "")), active_job.duplicate(true))
