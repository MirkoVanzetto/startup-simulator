class_name TechOpsInteractable
extends Interactable3D
## TechOpsInteractable - Interagibile 3D universale per le meccaniche Post-OGR (v1.5):
## - Nodi di estrazione materiali (Rame, Silicio, Alluminio/Terre Rare/Compositi)
## - Stazione di Raffinazione & Consegna Materiali (🔬 RC / € / Nastro Trasportatore)
## - Piazzole Mining Robot MK1 & MK2 (Costruzione fisica, raccolta hopper, manutenzione, upgrade)
## - Banco Assemblaggio Fisico TO-Drone MK1 (7 fasi progressive con modello 3D) e Piazzola H
## - Terminale Dipartimenti CEO presso l'Incubatore Startup Torino
## - NPC Specialisti (Ing. Dario Ferrero alla Miniera Alpina, Dr.ssa Chiara Conti al Lab Droni)
## - Mezzi di trasporto 3D (Bicicletta Tech, Auto Elettrica Aziendale, Fermate Autobus GTT)

@export var station_type: String = "extraction_node"
@export var node_id: String = "node_copper"
@export var station_title: String = ""
@export var robot_slot: int = 1
@export var vehicle_id: String = "bike"
@export var bus_stop_id: String = "bus_sancarlo"
@export var visual_root_path: NodePath = NodePath("VisualRoot")
@export var ghost_root_path: NodePath = NodePath("GhostRoot")
@export var beacon_path: NodePath = NodePath("Beacon")

var _anim_time: float = 0.0
var _visual_node: Node3D = null

func _resolve_visual_node() -> Node3D:
	if not is_instance_valid(_visual_node):
		if not visual_root_path.is_empty():
			_visual_node = get_node_or_null(visual_root_path) as Node3D
		if not is_instance_valid(_visual_node):
			_visual_node = get_node_or_null("VisualRoot") as Node3D
	return _visual_node

func _ready() -> void:
	super._ready()
	if is_instance_valid(EventBus):
		EventBus.tech_ops_updated.connect(_refresh_visuals)
		EventBus.materials_changed.connect(_refresh_visuals)
		EventBus.vehicle_changed.connect(func(_v): _refresh_visuals())
	call_deferred("_refresh_visuals")

func _process(delta: float) -> void:
	_anim_time += delta
	var vnode := _resolve_visual_node()
	if station_type == "robot_pad" and is_instance_valid(vnode) and vnode.visible:
		var head := vnode.get_node_or_null("DrillHead") as Node3D
		var boom := vnode.get_node_or_null("BoomArm") as Node3D
		var sparks := vnode.get_node_or_null("DrillSparks") as CPUParticles3D
		if is_instance_valid(TechOpsManager):
			var st := TechOpsManager.get_robot_state(robot_slot)
			var active := not bool(st.get("jammed", false)) and float(st.get("condition", 100.0)) > 15.0
			if sparks:
				sparks.emitting = active
			if head and active:
				head.rotation.y += delta * 6.5
				head.position.y = 0.56 + sin(_anim_time * 5.2) * 0.05
			if boom and active:
				boom.rotation.x = sin(_anim_time * 2.4) * 0.14
	elif station_type == "drone_bench" and is_instance_valid(vnode):
		if is_instance_valid(TechOpsManager) and TechOpsManager.drone_assembly_step >= 2 and not TechOpsManager.drone_built:
			var p2 := vnode.get_node_or_null("Part2") as Node3D
			if p2 and p2.visible:
				for ri in range(4):
					var r := p2.get_node_or_null("Rotor_%d" % ri) as Node3D
					if r:
						r.rotation.y += delta * 12.0 * (1.0 if ri % 2 == 0 else -1.0)
	elif station_type == "drone_helipad" and is_instance_valid(vnode) and vnode.visible:
		var p2_h := vnode.get_node_or_null("Part2") as Node3D
		if is_instance_valid(TechOpsManager) and not TechOpsManager.active_drone_mission.is_empty():
			# Volo in circuito ellittico panoramico sopra Lab Droni / Borgo Po con rotori ad alta velocità
			var ang := _anim_time * 1.15
			var nx := cos(ang) * 2.8
			var nz := sin(ang) * 1.9
			vnode.position = Vector3(nx, 2.25 + sin(_anim_time * 3.0) * 0.24, nz)
			vnode.rotation.y = atan2(-sin(ang) * 2.8, cos(ang) * 1.9)
			vnode.rotation.x = -0.14
			if p2_h:
				for ri in range(4):
					var rh := p2_h.get_node_or_null("Rotor_%d" % ri) as Node3D
					if rh:
						rh.rotation.y += delta * 28.0 * (1.0 if ri % 2 == 0 else -1.0)
		else:
			vnode.position = Vector3(0, -0.77, 0)
			vnode.rotation = Vector3.ZERO
			if is_instance_valid(TechOpsManager) and TechOpsManager.drone_built and p2_h:
				for ri in range(4):
					var rs := p2_h.get_node_or_null("Rotor_%d" % ri) as Node3D
					if rs:
						rs.rotation.y += delta * 3.0 * (1.0 if ri % 2 == 0 else -1.0)

func get_prompt() -> String:
	if not is_interactable:
		return ""
	if not is_instance_valid(TechOpsManager):
		return prompt_message

	match station_type:
		"extraction_node":
			var cur := TechOpsManager.get_carried_total()
			var cap := TechOpsManager.get_max_carry_capacity()
			if cur >= cap:
				return "[Cassa Piena %d/%d] Consegna alla Raffineria Miniera Alpina" % [cur, cap]
			return "[E] Estrai da %s (Cassa: %d/%d)" % [station_title if station_title != "" else "Filone Minerario", cur, cap]

		"processing_station":
			if TechOpsManager.active_incidents.has("inc_power_dip"):
				return "[E] ⚡ Riallinea Quadro Elettrico Raffineria Miniera (Risolvi Imprevisto)"
			var cur := TechOpsManager.get_carried_total()
			if cur > 0:
				return "[E] Raffina & Consegna %d Materiali (+🔬 Crediti di Ricerca / Stock)" % cur
			return "[E] Raffineria Miniera Alpina (Stock: %d · 🔬 %d RC · Nastro / Vendita)" % [
				TechOpsManager.get_stored_total(),
				TechOpsManager.research_credits
			]

		"robot_pad":
			var r_name := "Mining Robot MK1" if robot_slot == 1 else "Mining Robot MK2"
			if not TechOpsManager.is_robot_built(robot_slot):
				var rec: Dictionary = TechOpsManager.ROBOT_RECIPES.get(robot_slot, {})
				return "[E] Assembla %s (€ %.0f + Materiali)" % [r_name, float(rec.get("cost_eur", 450.0))]
			var st := TechOpsManager.get_robot_state(robot_slot)
			var cond := int(roundf(float(st.get("condition", 100.0))))
			if bool(st.get("jammed", false)) or cond <= 35:
				return "[E] 🔧 Ripara & Manutieni %s (Condizione: %d%%)" % [r_name, cond]
			var hop := TechOpsManager.get_robot_hopper_total(robot_slot)
			var hop_cap := int(st.get("hopper_cap", 18))
			if hop > 0:
				return "[E] Raccogli %d/%d Materiali da %s (Cond: %d%%)" % [hop, hop_cap, r_name, cond]
			return "[E] Gestisci / Potenzia %s (Lv.%d · Cond: %d%% · Hopper: 0/%d)" % [
				r_name, int(st.get("level", 1)), cond, hop_cap
			]

		"drone_bench":
			if TechOpsManager.drone_built:
				return "[E] Banco Assemblaggio TO-Drone MK1 (Completato 7/7 ✔ — Vai alla Piazzola H)"
			var step_info := TechOpsManager.get_current_drone_step_info()
			var req_mats: Dictionary = step_info.get("materials", {})
			var req_str := _format_reqs(req_mats)
			return "[E] %s%s" % [str(step_info.get("title", "Assembla Drone")), (" [" + req_str + "]") if req_str != "" else ""]

		"drone_helipad":
			if not TechOpsManager.drone_built:
				if TechOpsManager.drone_assembly_step == 6:
					return "[E] 🚁 Esegui Collaudo Finale di Volo TO-Drone MK1 (Fase 7/7)"
				return "[E] Piazzola H · Completa prima il TO-Drone MK1 sul Banco Assemblaggio (%d/7)" % TechOpsManager.drone_assembly_step
			if not TechOpsManager.active_drone_mission.is_empty():
				return "[E] 🚁 TO-Drone MK1 in Volo: %s (%d min rimasti)" % [
					str(TechOpsManager.active_drone_mission.get("title", "Missione")),
					int(TechOpsManager.active_drone_mission.get("remaining_mins", 0))
				]
			return "[E] 🚁 Centro Operativo Piazzola H · Lancia Missione TO-Drone MK1"

		"incubator_terminal":
			return "[E] 🏛 Direzione Incubatore Startup Torino (Dipartimenti CEO: %d/3)" % TechOpsManager.unlocked_departments.size()

		"npc_ferrero":
			return "[E] Parla con Ing. Dario Ferrero (Capo Cava · Miniera Alpina)"

		"npc_chiara":
			return "[E] Parla con Dr.ssa Chiara Conti (Capo Progetto Lab Droni Torino)"

		"vehicle":
			var vdef: Dictionary = TechOpsManager.VEHICLES.get(vehicle_id, {})
			var vname := str(vdef.get("name", vehicle_id))
			if not TechOpsManager.has_vehicle(vehicle_id):
				return "[E] Acquista & Usa %s (€ %.0f)" % [vname, float(vdef.get("cost", 240.0))]
			if TechOpsManager.active_vehicle == vehicle_id:
				return "[E] Scendi da %s (Torna a piedi)" % vname
			return "[E] Sali su %s (+%d%% Velocità)" % [vname, int(roundf((float(vdef.get("speed_mult", 1.0)) - 1.0) * 100.0))]

		"bus_stop":
			var sdef: Dictionary = TechOpsManager.BUS_STOPS.get(bus_stop_id, {})
			var pass_tag := "Abbonamento Attivo ✔" if TechOpsManager.has_vehicle("bus_pass") else "Corsa € 2,00"
			return "[E] 🚌 %s (%s)" % [str(sdef.get("name", "Fermata GTT")), pass_tag]

	return prompt_message

func _format_reqs(reqs: Dictionary) -> String:
	var parts: Array[String] = []
	for k in reqs:
		var need := int(reqs[k])
		var have := TechOpsManager.get_stored_count(str(k))
		parts.append("%s %d/%d" % [TechOpsManager.get_material_short(str(k)), have, need])
	return ", ".join(parts)

func _on_interact(_player: Node) -> void:
	if not is_instance_valid(TechOpsManager):
		return

	match station_type:
		"extraction_node":
			var sparks := get_node_or_null("MiningSparks") as CPUParticles3D
			if sparks:
				sparks.emitting = false
				sparks.restart()
				sparks.emitting = true
			TechOpsManager.extract_from_node(node_id)
			_refresh_visuals()

		"processing_station":
			if TechOpsManager.active_incidents.has("inc_power_dip"):
				TechOpsManager.resolve_incident("inc_power_dip", true)
				_refresh_visuals()
				return
			if TechOpsManager.get_carried_total() > 0:
				TechOpsManager.deliver_carried_for_research()
				_refresh_visuals()
				return
			_open_processing_dialogue()

		"robot_pad":
			if not TechOpsManager.is_robot_built(robot_slot):
				TechOpsManager.build_mining_robot(robot_slot)
				_refresh_visuals()
				return
			var st := TechOpsManager.get_robot_state(robot_slot)
			if bool(st.get("jammed", false)) or float(st.get("condition", 100.0)) <= 35.0:
				TechOpsManager.maintain_mining_robot(robot_slot)
				_refresh_visuals()
				return
			if TechOpsManager.get_robot_hopper_total(robot_slot) > 0:
				TechOpsManager.collect_robot_hopper(robot_slot)
				_refresh_visuals()
				return
			_open_robot_dialogue()

		"drone_bench":
			if TechOpsManager.drone_built:
				_open_drone_helipad_dialogue()
				return
			TechOpsManager.advance_drone_assembly_step()
			_refresh_visuals()

		"drone_helipad":
			if not TechOpsManager.drone_built and TechOpsManager.drone_assembly_step == 6:
				TechOpsManager.advance_drone_assembly_step()
				_refresh_visuals()
				return
			_open_drone_helipad_dialogue()

		"incubator_terminal":
			_open_incubator_dialogue()

		"npc_ferrero":
			VillageCharacters.play_interact(self)
			FameManager.register_talk("dario_ferrero")
			TechOpsManager.start_post_ogr_expansion()
			_open_ferrero_dialogue()

		"npc_chiara":
			VillageCharacters.play_interact(self)
			FameManager.register_talk("chiara_conti")
			_open_chiara_dialogue()

		"vehicle":
			TechOpsManager.buy_or_toggle_vehicle(vehicle_id)
			_refresh_visuals()

		"bus_stop":
			_open_bus_stop_dialogue()

func _open_processing_dialogue() -> void:
	var lines := [
		"Raffineria & Frantoio Miniera Alpina — Crediti di Ricerca: 🔬 %d RC | Materiali in magazzino: %d unità." % [
			TechOpsManager.research_credits, TechOpsManager.get_stored_total()
		],
		"Quando trasporti materiali nella cassa e premi [E] qui, vengono raffinati nel magazzino aziendale e generano subito 🔬 Crediti di Ricerca.",
		"Da questo pannello puoi vendere parte dello stock per liquidità immediata (€) o installare il Nastro Trasportatore Automatico verso i robot."
	]
	var choices: Array = []
	if not TechOpsManager.conveyor_installed:
		choices.append({"text": "Installa Nastro Trasportatore Miniera (4 Alluminio, 3 Rame, 2 Circuiti, € 600)", "action": "techops_build_conveyor"})
	if TechOpsManager.get_stored_total() > 0:
		choices.append({"text": "Vendi 1 lotto di materiali dal magazzino per denaro (€)", "action": "techops_sell_stock_batch"})
	choices.append({"text": "Chiudi pannello", "action": "close"})
	EventBus.dialogue_started.emit("Raffineria Miniera Alpina", lines, choices)

func _open_robot_dialogue() -> void:
	var r_name := "Mining Robot MK1" if robot_slot == 1 else "Mining Robot MK2"
	var st := TechOpsManager.get_robot_state(robot_slot)
	var lvl := int(st.get("level", 1))
	var cond := int(roundf(float(st.get("condition", 100.0))))
	var prod := int(st.get("total_produced", 0))
	var lines := [
		"%s — Livello %d/3 | Condizione meccanica: %d%% | Totale estratto: %d unità." % [r_name, lvl, cond, prod],
		"Il robot scava autonomamente nel tempo e mentre dormi. Svuota il deposito o installa il Nastro Trasportatore verso la raffineria!"
	]
	var choices: Array = []
	if lvl < 3:
		choices.append({
			"text": "Potenzia %s a Lv.%d (€ %.0f + %d 🔬 RC)" % [r_name, lvl + 1, 320.0 * float(lvl), 8 * lvl],
			"action": "techops_upgrade_robot_%d" % robot_slot
		})
	if cond < 100:
		choices.append({"text": "Esegui manutenzione preventiva gratuita (riporta al 100%)", "action": "techops_maintain_robot_%d" % robot_slot})
	choices.append({"text": "Chiudi", "action": "close"})
	EventBus.dialogue_started.emit(r_name, lines, choices)

func _open_drone_helipad_dialogue() -> void:
	if not TechOpsManager.drone_built:
		var step_info := TechOpsManager.get_current_drone_step_info()
		var lines := [
			"Piazzola di Volo H — Il TO-Drone MK1 è ancora in fase di assemblaggio sul banco del laboratorio (%d/7 fasi completate)." % TechOpsManager.drone_assembly_step,
			"Prossimo passo richiesto sul Banco Assemblaggio: %s." % str(step_info.get("title", ""))
		]
		EventBus.dialogue_started.emit("Piazzola di Volo H · Lab Droni Torino", lines, [{"text": "Vado al Banco Assemblaggio", "action": "close"}])
		return

	var auto_str := "ATTIVA ✔" if TechOpsManager.drone_auto_logistics else "DISATTIVATA"
	var lines := [
		"Centro di Controllo Volo TO-Drone MK1 — Missioni completate: %d | Logistica Automatica Miniera: %s." % [
			TechOpsManager.completed_drone_missions_count, auto_str
		],
		"Seleziona un'operazione aerea industriale da avviare o attiva la navetta logistica per ritirare automaticamente i materiali dai Mining Robot."
	]
	var choices: Array = [
		{"text": "Avvia Rilievo LiDAR & Mappatura 3D (90m · € 680 + 12 🔬 RC)", "action": "drone_mission_lidar"},
		{"text": "Avvia Ispezione Termografica Ponti Po (120m · € 920 + 16 🔬 RC)", "action": "drone_mission_inspect"},
		{"text": "Avvia Ponte Radio & Telemetria Val di Susa (150m · € 1.180 + 22 🔬 RC)", "action": "drone_mission_relay"},
		{"text": "Attiva/Disattiva Logistica Materiali Automatica", "action": "drone_toggle_logistics"},
		{"text": "Chiudi", "action": "close"}
	]
	EventBus.dialogue_started.emit("Piazzola di Volo H · TO-Drone MK1", lines, choices)

func _open_incubator_dialogue() -> void:
	var lines := [
		"Benvenuto al Terminale Direzionale dell'Incubatore Startup Torino (Fase 4 — Tech Company & CEO).",
		"Dipartimenti attivi: %d/3 | Rendita Giornaliera Dipartimenti: +€ %.0f/g & +%d 🔬 RC/g." % [
			TechOpsManager.unlocked_departments.size(),
			TechOpsManager.calculate_departments_daily_revenue(),
			TechOpsManager.calculate_departments_daily_rc()
		],
		"Fondando i dipartimenti specialistici deleghi la manutenzione dei robot, acceleri i dipendenti su Freelance Hub e potenzi le operazioni droni!"
	]
	var choices: Array = []
	if not TechOpsManager.is_department_unlocked("dept_hardware"):
		choices.append({"text": "Fonda Dipartimento Hardware & Robotica (€ 2.400 + 30 🔬 RC)", "action": "unlock_dept_hardware"})
	if not TechOpsManager.is_department_unlocked("dept_cloud_ai"):
		choices.append({"text": "Fonda Divisione Cloud, AI & Data Center (€ 3.200 + 40 🔬 RC)", "action": "unlock_dept_cloud_ai"})
	if not TechOpsManager.is_department_unlocked("dept_aerospace"):
		choices.append({"text": "Fonda Divisione Droni & Logistica Avanzata (€ 4.000 + 50 🔬 RC)", "action": "unlock_dept_aerospace"})
	choices.append({"text": "Chiudi terminale", "action": "close"})
	EventBus.dialogue_started.emit("Incubatore Startup Torino · Direzione CEO", lines, choices)

func _open_ferrero_dialogue() -> void:
	var st := TechOpsManager.get_post_ogr_stage()
	var lines := [
		"Ciao! Sono l'Ing. Dario Ferrero, responsabile della Miniera Alpina Val di Susa — il polo di estrazione e raffinazione della tua azienda ai piedi delle Alpi!",
		"Da questi filoni cristallini estratti nella cava e nella Galleria 01 recuperiamo Rame, Silicio, Alluminio, Circuiti, Terre Rare e Compositi.",
		"1) Estrai dai 3 filoni di cava · 2) Porta il carico alla Raffineria qui accanto per generare 🔬 Crediti di Ricerca · 3) Sblocca 'Automazione & Robotica Lv.1' su TO-OS e monta i Mining Robot sulle piazzole!"
	]
	if st == "assemble_drone" or st == "expand_departments" or st == "tech_giant":
		lines.append("Grandioso lavoro nella Miniera! Con i materiali accumulati in magazzino puoi assemblare il TO-Drone MK1 al Lab Droni di Borgo Po!")
	var choices := [
		{"text": "Perfetto Ing. Ferrero, vado ai filoni della miniera!", "action": "close"}
	]
	EventBus.dialogue_started.emit("Ing. Dario Ferrero (Miniera Alpina)", lines, choices)

func _open_chiara_dialogue() -> void:
	var lines := [
		"Benvenuto al Lab Droni Torino! Sono la Dr.ssa Chiara Conti, progettista capo di avionica e sistemi autonomi.",
		"Sul nostro Banco Assemblaggio 3D puoi costruire fisicamente il quadricottero industriale TO-Drone MK1 in 7 fasi: Telaio, 4 Motori Brushless, Cablaggi, Scheda Flight Controller, Batteria & LiDAR, Firmware e Collaudo Finale!",
		"Assicurati di aver sbloccato 'Hardware & Avionica Droni Lv.1' su TO-OS (Conoscenza R&D) e di avere Rame, Silicio, Alluminio, Circuiti, Terre Rare e Compositi dalla Miniera Alpina."
	]
	var choices := [
		{"text": "Grazie Dr.ssa Conti, procedo al Banco Assemblaggio!", "action": "close"}
	]
	EventBus.dialogue_started.emit("Dr.ssa Chiara Conti (Lab Droni Torino)", lines, choices)

func _open_bus_stop_dialogue() -> void:
	var has_pass := TechOpsManager.has_vehicle("bus_pass")
	var lines := [
		"Rete Elettrica GTT Smart Mobility Torino — Spostamento rapido tra quartieri e Miniera Alpina.",
		"Stato titolo di viaggio: %s." % ("Abbonamento GTT Illimitato Attivo ✔" if has_pass else "Biglietto corsa singola € 2,00 (oppure acquista l'Abbonamento a € 90)")
	]
	var choices: Array = []
	for sid in ["bus_sancarlo", "bus_valdocco", "bus_ogr", "bus_borgopo", "bus_miniera"]:
		if sid == bus_stop_id:
			continue
		var sdef: Dictionary = TechOpsManager.BUS_STOPS[sid]
		choices.append({"text": "Viaggia verso: %s" % str(sdef["name"]), "action": "bus_travel_" + sid})
	if not has_pass:
		choices.append({"text": "Acquista Abbonamento GTT Smart Mobility (€ 90,00)", "action": "bus_buy_pass"})
	choices.append({"text": "Resta a questa fermata", "action": "close"})
	EventBus.dialogue_started.emit("Fermata Autobus GTT Torino", lines, choices)

func _refresh_visuals() -> void:
	var vnode := _resolve_visual_node()
	if not is_instance_valid(TechOpsManager) or not is_instance_valid(vnode):
		return
	match station_type:
		"robot_pad":
			var built := TechOpsManager.is_robot_built(robot_slot)
			vnode.visible = built
			var ghost := get_node_or_null(ghost_root_path) as Node3D if not ghost_root_path.is_empty() else (get_node_or_null("GhostRoot") as Node3D)
			if ghost:
				ghost.visible = not built
		"drone_bench":
			var step := TechOpsManager.drone_assembly_step
			for i in range(1, 7):
				var part := vnode.get_node_or_null("Part%d" % i) as Node3D
				if part:
					part.visible = (step >= i) and not TechOpsManager.drone_built
		"drone_helipad":
			vnode.visible = TechOpsManager.drone_built or TechOpsManager.drone_assembly_step >= 6
