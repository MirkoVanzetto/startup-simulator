extends Node
## TechOpsManager - Gestione Espansione Post-OGR (Fase 3 & Fase 4):
## - Raccolta manuale e trasporto fisico materiali tecnologici (Rame, Silicio, Alluminio, Circuiti, Terre Rare, Compositi)
## - Stazione di Raffinazione & Consegna (Vendita in € oppure Crediti di Ricerca 🔬 RC + Magazzino Materiali)
## - Albero Ricerca Tecnologica a 6 Rami (Estrazione, Automazione, Droni & Hardware, Software & AI, Cloud, Sicurezza)
## - Costruzione, produzione nel tempo, usura e potenziamento di Mining Robot MK1, Nastro Trasportatore e Mining Robot MK2
## - Costruzione fisica in 7 fasi del Drone 3D (TO-Drone MK1) al Lab Droni Torino e Missioni Drone
## - Dipartimenti Aziendali Fase 4 (CEO & Tech Giant) presso l'Incubatore Startup Torino
## - Imprevisti dinamici (Produttivi, IT, Aziendali, Ambientali) e Progressione Mobilità Urbana (Bici, Bus GTT, Auto EV)

const MAX_TECH_RANK: int = 3

const MATERIAL_ORDER: Array[String] = [
	"copper",
	"silicon",
	"aluminum",
	"circuits",
	"rare_earths",
	"composites"
]

const MATERIALS: Dictionary = {
	"copper": {
		"id": "copper",
		"name": "Rame Conduttivo",
		"short": "Rame",
		"icon": "🟠",
		"sell_price": 18.0,
		"rc_value": 2,
		"desc": "Conduttori, bobine brushless e cablaggi industriali ad alta efficienza."
	},
	"silicon": {
		"id": "silicon",
		"name": "Silicio Purificato",
		"short": "Silicio",
		"icon": "🔷",
		"sell_price": 26.0,
		"rc_value": 3,
		"desc": "Wafer semiconduttori per microcontroller, sensori ottici e chip logici."
	},
	"aluminum": {
		"id": "aluminum",
		"name": "Alluminio Aeronautico",
		"short": "Alluminio",
		"icon": "⚪",
		"sell_price": 22.0,
		"rc_value": 2,
		"desc": "Leghe leggere ad alta resistenza per telai robotici, scocche e droni."
	},
	"circuits": {
		"id": "circuits",
		"name": "Circuiti Recuperati",
		"short": "Circuiti",
		"icon": "🟢",
		"sell_price": 34.0,
		"rc_value": 4,
		"desc": "Schede PCB, regolatori PWM e moduli elettronici rigenerati."
	},
	"rare_earths": {
		"id": "rare_earths",
		"name": "Terre Rare",
		"short": "Terre Rare",
		"icon": "🟣",
		"sell_price": 55.0,
		"rc_value": 6,
		"desc": "Neodimio e litio ad alta purezza per magneti permanenti, batterie e LiDAR."
	},
	"composites": {
		"id": "composites",
		"name": "Materiali Compositi",
		"short": "Compositi",
		"icon": "⚫",
		"sell_price": 45.0,
		"rc_value": 5,
		"desc": "Fibra di carbonio e polimeri strutturali per velivoli autonomi e robot MK2."
	}
}

const TECH_BRANCH_ORDER: Array[String] = [
	"tech_extraction",
	"tech_automation",
	"tech_drone_avionics",
	"tech_software_ai",
	"tech_cloud_infra",
	"tech_cyber_defense"
]

const TECH_BRANCHES: Dictionary = {
	"tech_extraction": {
		"id": "tech_extraction",
		"title": "Estrazione & Raffinazione",
		"icon": "⛏",
		"category": "Estrazione",
		"summary": "+1 resa materiali/liv., +6 capienza cassa trasporto/liv., +15%/liv. Crediti RC e sblocca Terre Rare & Compositi.",
		"rc_costs": [10, 22, 40],
		"effect_labels": [
			"Base (Cassa 12 unità · Rame/Silicio/Alluminio/Circuiti)",
			"Lv.1 · Sonda Metallurgica (+1 resa · Cassa 18 · Sblocca Terre Rare & Compositi)",
			"Lv.2 · Raffinazione Catalitica (+2 resa · Cassa 24 · +30% RC)",
			"Lv.3 · Estrazione Molecolare (+3 resa · Cassa 30 · +45% RC)"
		]
	},
	"tech_automation": {
		"id": "tech_automation",
		"title": "Automazione & Robotica",
		"icon": "🤖",
		"category": "Automazione",
		"summary": "Lv.1 sblocca Mining Robot MK1 · Lv.2 sblocca Nastro Trasportatore & +35% ciclo · Lv.3 sblocca Mining Robot MK2 & -40% usura.",
		"rc_costs": [12, 26, 45],
		"effect_labels": [
			"Base (Solo raccolta manuale)",
			"Lv.1 · Progetto Mining Robot MK1 sbloccato",
			"Lv.2 · Nastro Trasportatore Automatico & +35% velocità robot",
			"Lv.3 · Progetto Mining Robot MK2 Dual-Core & -40% usura meccanica"
		]
	},
	"tech_drone_avionics": {
		"id": "tech_drone_avionics",
		"title": "Hardware & Avionica Droni",
		"icon": "🚁",
		"category": "Hardware & Droni",
		"summary": "Lv.1 sblocca Assemblaggio TO-Drone MK1 · Lv.2 Sensori LiDAR (+30% compensi & anti-nebbia) · Lv.3 Logistica Droni Automatica (+60%).",
		"rc_costs": [15, 30, 50],
		"effect_labels": [
			"Base (Laboratorio Droni in attesa di brevetto)",
			"Lv.1 · Brevetto Telaio & Flight Controller TO-Drone MK1",
			"Lv.2 · Ottica LiDAR & Telemetria Lungo Raggio (+30% ricavi volo)",
			"Lv.3 · Sciame Logistico Autonomo (+60% ricavi & ritiro hopper automatico)"
		]
	},
	"tech_software_ai": {
		"id": "tech_software_ai",
		"title": "Software & AI Operativa",
		"icon": "🧠",
		"category": "Software",
		"summary": "-0.45s/liv. compilazione WebForge, +15%/liv. velocità incarichi autonomi del Team e auto-correzione bug.",
		"rc_costs": [12, 24, 42],
		"effect_labels": [
			"Base (Compilazione standard)",
			"Lv.1 · AI Code Assistant (-0.45s WebForge · +15% velocità Team)",
			"Lv.2 · Pipeline Neural CI/CD (-0.90s WebForge · +30% velocità Team)",
			"Lv.3 · Autonomous Dev Engine (-1.35s WebForge · +45% velocità Team)"
		]
	},
	"tech_cloud_infra": {
		"id": "tech_cloud_infra",
		"title": "Networking & Cloud Cluster",
		"icon": "☁",
		"category": "Networking",
		"summary": "+15%/liv. rendita giornaliera Server Rack, +10%/liv. compensi B2B/Enterprise e bilanciamento termico.",
		"rc_costs": [14, 28, 46],
		"effect_labels": [
			"Base (Infrastruttura standard)",
			"Lv.1 · Mesh Routing Industriale (+15% Rack · +10% B2B)",
			"Lv.2 · Kubernetes Edge Cluster (+30% Rack · +20% B2B)",
			"Lv.3 · Hyper-Scale Data Center (+45% Rack · +30% B2B)"
		]
	},
	"tech_cyber_defense": {
		"id": "tech_cyber_defense",
		"title": "Sicurezza & AI Predittiva",
		"icon": "🛡",
		"category": "Sicurezza & AI",
		"summary": "Mitigazione automatica imprevisti IT/Cyber (45% / 80% / 100%) e +15%/liv. compensi NetShield.",
		"rc_costs": [14, 28, 48],
		"effect_labels": [
			"Base (Difesa manuale)",
			"Lv.1 · Firewall Euristico (+15% NetShield · 45% blocco attacchi)",
			"Lv.2 · SOC AI Predittivo (+30% NetShield · 80% blocco attacchi)",
			"Lv.3 · Zero-Trust Quantum Shield (+45% NetShield · 100% immunità IT)"
		]
	}
}

const ROBOT_RECIPES: Dictionary = {
	1: {
		"name": "Mining Robot MK1",
		"tech_req": 1,
		"cost_eur": 450.0,
		"materials": {"copper": 4, "silicon": 3, "circuits": 2},
		"hopper_cap": 18,
		"cycle_minutes": 30
	},
	2: {
		"name": "Mining Robot MK2",
		"tech_req": 3,
		"cost_eur": 1200.0,
		"materials": {"aluminum": 5, "rare_earths": 3, "composites": 3, "circuits": 3},
		"hopper_cap": 32,
		"cycle_minutes": 20
	}
}

const CONVEYOR_RECIPE: Dictionary = {
	"name": "Nastro Trasportatore & Smistamento OGR",
	"tech_req": 2,
	"cost_eur": 600.0,
	"materials": {"aluminum": 4, "copper": 3, "circuits": 2}
}

const DRONE_STEPS: Array[Dictionary] = [
	{
		"step": 1,
		"id": "frame",
		"title": "Fase 1/7 · Posizionamento Telaio Aeronautico",
		"desc": "Assembla la struttura portante in alluminio e fibra composita sul banco del Lab Droni.",
		"materials": {"aluminum": 3, "composites": 1},
		"rc_reward": 4
	},
	{
		"step": 2,
		"id": "motors",
		"title": "Fase 2/7 · Installazione 4 Motori Brushless",
		"desc": "Monta i rotori ad alta coppia con avvolgimenti in rame e magneti alle terre rare.",
		"materials": {"copper": 3, "rare_earths": 1},
		"rc_reward": 5
	},
	{
		"step": 3,
		"id": "wiring",
		"title": "Fase 3/7 · Cablaggio di Potenza & Bus Dati",
		"desc": "Collega gli ESC e il distributore di tensione ai bracci del quadricottero.",
		"materials": {"copper": 2, "circuits": 1},
		"rc_reward": 4
	},
	{
		"step": 4,
		"id": "pcb",
		"title": "Fase 4/7 · Montaggio Scheda Flight Controller",
		"desc": "Installa l'unità centrale IMU ridondata con processori al silicio e circuiti integrati.",
		"materials": {"silicon": 3, "circuits": 2},
		"rc_reward": 6
	},
	{
		"step": 5,
		"id": "battery_sensors",
		"title": "Fase 5/7 · Installazione Batteria Li-Po & Sensori LiDAR",
		"desc": "Integra il pacco batterie ad alta densità e la torretta ottica multispettrale.",
		"materials": {"rare_earths": 2, "silicon": 2},
		"rc_reward": 6
	},
	{
		"step": 6,
		"id": "firmware",
		"title": "Fase 6/7 · Configurazione Software & Telemetria",
		"desc": "Carica il firmware di navigazione autonoma TO-OS e calibra il giroscopio a 6 assi.",
		"materials": {},
		"rc_reward": 5
	},
	{
		"step": 7,
		"id": "flight_test",
		"title": "Fase 7/7 · Collaudo Finale di Volo (Piazzola H)",
		"desc": "Esegui il decollo verticale di collaudo e sblocca le Operazioni Aeree Industriali!",
		"materials": {},
		"rc_reward": 15
	}
]

const DRONE_MISSIONS: Dictionary = {
	"drone_lidar_survey": {
		"id": "drone_lidar_survey",
		"title": "Rilievo LiDAR & Mappatura 3D Cantiere",
		"duration_mins": 90,
		"reward_eur": 680.0,
		"reward_rc": 12,
		"reward_rep": 10,
		"desc": "Scansione laser centimetrica per i cantieri direzionali di Torino."
	},
	"drone_infra_inspect": {
		"id": "drone_infra_inspect",
		"title": "Ispezione Termografica Ponti & Rete Elettrica Po",
		"duration_mins": 120,
		"reward_eur": 920.0,
		"reward_rc": 16,
		"reward_rep": 14,
		"desc": "Analisi predittiva ad alta quota dei piloni e delle cabine lungo il Fiume Po."
	},
	"drone_net_relay": {
		"id": "drone_net_relay",
		"title": "Ponte Radio Temporaneo & Telemetria OGR",
		"duration_mins": 150,
		"reward_eur": 1180.0,
		"reward_rc": 22,
		"reward_rep": 18,
		"desc": "Copertura aerea a bassa latenza per i laboratori industriali e il polo OGR."
	}
}

const DEPARTMENTS: Dictionary = {
	"dept_hardware": {
		"id": "dept_hardware",
		"title": "Dipartimento Hardware & Robotica",
		"head": "Ing. Dario Ferrero",
		"cost_eur": 2400.0,
		"cost_rc": 30,
		"daily_eur": 180.0,
		"daily_rc": 6,
		"desc": "Manutenzione automatica dei Mining Robot, +25% resa estrattiva e +€ 180/g (+6 RC/g)."
	},
	"dept_cloud_ai": {
		"id": "dept_cloud_ai",
		"title": "Divisione Cloud, AI & Data Center",
		"head": "Lead Architect AI",
		"cost_eur": 3200.0,
		"cost_rc": 40,
		"daily_eur": 260.0,
		"daily_rc": 8,
		"desc": "+25% velocità incarichi autonomi del Team, +25% rendita Server Rack e +€ 260/g (+8 RC/g)."
	},
	"dept_aerospace": {
		"id": "dept_aerospace",
		"title": "Divisione Droni & Logistica Avanzata",
		"head": "Dr.ssa Chiara Conti",
		"cost_eur": 4000.0,
		"cost_rc": 50,
		"daily_eur": 350.0,
		"daily_rc": 12,
		"desc": "+40% compensi missioni Drone, logistica aerea continua e +€ 350/g (+12 RC/g)."
	}
}

const VEHICLES: Dictionary = {
	"foot": {
		"id": "foot",
		"icon": "🚶",
		"name": "A Piedi",
		"cost": 0.0,
		"speed_mult": 1.0,
		"carry_bonus": 0,
		"desc": "Spostamento standard a piedi per le vie di Torino."
	},
	"bike": {
		"id": "bike",
		"icon": "🚲",
		"name": "Bicicletta Tech Elettrica",
		"cost": 240.0,
		"speed_mult": 1.42,
		"carry_bonus": 4,
		"desc": "+42% velocità di spostamento urbano, +4 capienza cassa materiali e -35% fatica sprint."
	},
	"bus_pass": {
		"id": "bus_pass",
		"icon": "🚌",
		"name": "Abbonamento GTT Smart Mobility",
		"cost": 90.0,
		"speed_mult": 1.0,
		"carry_bonus": 0,
		"desc": "Viaggio rapido istantaneo gratuito tra tutte le 5 Fermate Autobus GTT della città (incl. Miniera Alpina)."
	},
	"company_ev": {
		"id": "company_ev",
		"icon": "🚗",
		"name": "Auto Elettrica Aziendale TO-EV",
		"cost": 2800.0,
		"speed_mult": 1.85,
		"carry_bonus": 10,
		"desc": "+85% velocità di trasferimento, +10 capienza cassa materiali e +15 Reputazione corporate."
	}
}

const BUS_STOPS: Dictionary = {
	"bus_sancarlo": {
		"id": "bus_sancarlo",
		"name": "Fermata GTT · Borgo San Carlo (Piazzetta)",
		"pos": Vector3(10.8, 0.2, 16.0),
		"poi_id": "studio"
	},
	"bus_valdocco": {
		"id": "bus_valdocco",
		"name": "Fermata GTT · Borgo Valdocco (Viale Est)",
		"pos": Vector3(38.0, 0.2, 26.2),
		"poi_id": "officina_bellini"
	},
	"bus_ogr": {
		"id": "bus_ogr",
		"name": "Fermata GTT · Mercato Nord & Polo OGR",
		"pos": Vector3(82.5, 0.2, 12.6),
		"poi_id": "coworking_ogr"
	},
	"bus_borgopo": {
		"id": "bus_borgopo",
		"name": "Fermata GTT · Borgo Po & Lab Droni / Incubatore",
		"pos": Vector3(11.5, 0.2, 53.5),
		"poi_id": "lab_droni"
	},
	"bus_miniera": {
		"id": "bus_miniera",
		"name": "Fermata GTT · Miniera Alpina Val di Susa",
		"pos": Vector3(-42.8, 0.2, 6.2),
		"poi_id": "miniera_alpina"
	}
}

const DRONE_MISSION_ORDER: Array[String] = [
	"drone_lidar_survey",
	"drone_infra_inspect",
	"drone_net_relay"
]

const DEPT_ORDER: Array[String] = [
	"dept_hardware",
	"dept_cloud_ai",
	"dept_aerospace"
]

const INCIDENT_DEFS: Dictionary = {
	"inc_robot_jam": {
		"id": "inc_robot_jam",
		"category": "productive",
		"title": "Inceppamento Testa di Scavo Mining Robot",
		"desc": "Detriti rocciosi bloccano il Mining Robot alla Miniera Alpina. Esegui manutenzione sul posto o da TO-OS.",
		"fix_cost_eur": 65.0
	},
	"inc_power_dip": {
		"id": "inc_power_dip",
		"category": "productive",
		"title": "Calo Tensione Cabina Raffineria Miniera",
		"desc": "Sbalzo elettrico nella linea d'estrazione (-35% velocità). Riallinea il quadro alla Raffineria Miniera Alpina.",
		"fix_cost_eur": 50.0
	},
	"inc_cyber_breach": {
		"id": "inc_cyber_breach",
		"category": "it",
		"title": "Attacco DDoS / Ransomware su Rete Aziendale",
		"desc": "Traffico anomalo verso i server. Mitiga l'attacco dal terminale TO-OS o tramite Sicurezza & AI.",
		"fix_cost_eur": 90.0
	},
	"inc_client_urgent": {
		"id": "inc_client_urgent",
		"category": "business",
		"title": "Escalation Cliente Enterprise Urgente",
		"desc": "Un committente B2B richiede una patch immediata: risolvila per ottenere +€ 220 e +6 Reputazione.",
		"fix_cost_eur": 0.0
	},
	"inc_weather_fog": {
		"id": "inc_weather_fog",
		"category": "weather",
		"title": "Nebbia Fitta sul Lungo Po (Allerta Meteo)",
		"desc": "Visibilità ridotta per i voli a bassa quota: sblocca LiDAR (Avionica Lv.2) o attendi il miglioramento.",
		"fix_cost_eur": 40.0
	}
}

# --- Stato Persistente ---
var post_ogr_quest_started: bool = false
var research_credits: int = 0
var carried_materials: Dictionary = {}
var materials_storage: Dictionary = {}
var tech_ranks: Dictionary = {}

var total_manual_extractions: int = 0
var total_materials_delivered: int = 0
var total_rc_earned: int = 0

var robots: Dictionary = {}
var conveyor_installed: bool = false
var _node_cooldowns: Dictionary = {}

var drone_assembly_step: int = 0 # 0..7 (7 = drone completato e collaudato)
var drone_built: bool = false
var drone_auto_logistics: bool = false
var active_drone_mission: Dictionary = {} # {"id": String, "remaining_mins": int, "total_mins": int}
var completed_drone_missions_count: int = 0

var unlocked_departments: Array[String] = []
var active_incidents: Dictionary = {} # inc_id -> Dictionary

var owned_vehicles: Array[String] = ["foot"]
var active_vehicle: String = "foot"

# --- Alias di compatibilità UI/Test ---
var ogr_tech_mission_started: bool:
	get:
		return post_ogr_quest_started
	set(v):
		post_ogr_quest_started = v
var warehouse_materials: Dictionary:
	get:
		return materials_storage
var conveyor_unlocked: bool:
	get:
		return conveyor_installed
var drone_step: int:
	get:
		return drone_assembly_step
var drone_assembled: bool:
	get:
		return drone_built
var drone_missions_completed: int:
	get:
		return completed_drone_missions_count

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_init_defaults()
	if is_instance_valid(EventBus):
		EventBus.time_tick.connect(_on_time_tick)
		EventBus.day_passed.connect(_on_day_passed)

func _init_defaults() -> void:
	for m in MATERIAL_ORDER:
		if not carried_materials.has(m):
			carried_materials[m] = 0
		if not materials_storage.has(m):
			materials_storage[m] = 0
	for b in TECH_BRANCH_ORDER:
		if not tech_ranks.has(b):
			tech_ranks[b] = 0
	if not robots.has(1):
		robots[1] = _default_robot_state(1)
	if not robots.has(2):
		robots[2] = _default_robot_state(2)
	if not ("foot" in owned_vehicles):
		owned_vehicles.append("foot")

func _default_robot_state(slot: int) -> Dictionary:
	var rec: Dictionary = ROBOT_RECIPES.get(slot, ROBOT_RECIPES[1])
	return {
		"slot": slot,
		"built": false,
		"level": 1,
		"condition": 100.0,
		"jammed": false,
		"timer_mins": 0,
		"cycle_index": 0,
		"hopper": {},
		"hopper_cap": int(rec.get("hopper_cap", 18)),
		"total_produced": 0
	}

func reset() -> void:
	post_ogr_quest_started = false
	research_credits = 0
	carried_materials.clear()
	materials_storage.clear()
	tech_ranks.clear()
	total_manual_extractions = 0
	total_materials_delivered = 0
	total_rc_earned = 0
	robots.clear()
	conveyor_installed = false
	_node_cooldowns.clear()
	drone_assembly_step = 0
	drone_built = false
	drone_auto_logistics = false
	active_drone_mission.clear()
	completed_drone_missions_count = 0
	unlocked_departments.clear()
	active_incidents.clear()
	owned_vehicles = ["foot"]
	active_vehicle = "foot"
	_init_defaults()
	if is_instance_valid(EventBus):
		EventBus.materials_changed.emit()
		EventBus.tech_ops_updated.emit()

# ==============================================================================
# PROGRESSIONE MISSIONI POST-OGR
# ==============================================================================

func is_post_ogr_unlocked() -> bool:
	if post_ogr_quest_started:
		return true
	if is_instance_valid(ContractManager) and ContractManager.is_ogr_unlocked():
		return true
	return false

func start_post_ogr_expansion() -> void:
	if not post_ogr_quest_started:
		post_ogr_quest_started = true
		EventBus.notification_posted.emit(
			"Fase 3 Avviata: Miniera Alpina & Polo Estrattivo!",
			"L'Ing. Andrea Viale e l'Ing. Dario Ferrero ti hanno aperto la Miniera Alpina Val di Susa (oltre Parco Valentino Nord). Estrai i primi materiali e consegnali alla Raffineria!",
			"contract"
		)
		EventBus.tech_ops_updated.emit()
		SaveManager.request_auto_save()

func start_ogr_tech_mission() -> void:
	start_post_ogr_expansion()

func get_post_ogr_stage() -> String:
	if not is_post_ogr_unlocked():
		return "locked"
	if not post_ogr_quest_started and total_materials_delivered == 0:
		return "talk_viale"
	if total_materials_delivered < 6 and get_tech_rank("tech_automation") == 0 and not is_robot_built(1):
		return "gather_materials"
	if get_tech_rank("tech_automation") < 1 and not is_robot_built(1):
		return "unlock_robot_tech"
	if not is_robot_built(1):
		return "build_robot_mk1"
	if not drone_built:
		if get_tech_rank("tech_drone_avionics") < 1 and drone_assembly_step == 0:
			return "unlock_drone_tech"
		return "assemble_drone"
	if unlocked_departments.is_empty():
		return "expand_departments"
	return "tech_giant"

func get_post_ogr_objective_text() -> String:
	var st := get_post_ogr_stage()
	match st:
		"talk_viale":
			return "OGR Tech Hub: parla con l'Ing. Andrea Viale o con l'Ing. Dario Ferrero alla Miniera Alpina per avviare il Polo Materiali & Robotica."
		"gather_materials":
			var carried := get_carried_total()
			if carried > 0:
				return "Miniera Alpina: consegna i %d materiali trasportati alla Raffineria di Cava per ottenere 🔬 Crediti di Ricerca (%d/6 consegnati)." % [carried, total_materials_delivered]
			return "Miniera Alpina Val di Susa (Nord Parco Valentino): estrai Rame, Silicio e Alluminio dai filoni e consegnali alla Raffineria (%d/6)." % total_materials_delivered
		"unlock_robot_tech":
			return "Apri 'Conoscenza R&D' su TO-OS e sblocca 'Automazione & Robotica Lv.1' (12 🔬 RC, attuali: %d RC)." % research_credits
		"build_robot_mk1":
			return "Miniera Alpina: assembla fisicamente il 'Mining Robot MK1' sulla Piazzola Robot 1 (4 Rame, 3 Silicio, 2 Circuiti, € 450)."
		"unlock_drone_tech":
			return "Raccogli risorse dal Mining Robot MK1 e sblocca 'Hardware & Avionica Droni Lv.1' (15 🔬 RC, attuali: %d RC) su TO-OS." % research_credits
		"assemble_drone":
			var step_info := get_current_drone_step_info()
			return "Lab Droni Torino (Borgo Po): completa '%s' sul Banco Assemblaggio 3D (%d/7 fasi)." % [str(step_info.get("title", "Assemblaggio Drone")), drone_assembly_step]
		"expand_departments":
			return "TO-Drone MK1 operativo! Lancia missioni di volo dalla Piazzola H o fonda il primo Dipartimento Aziendale all'Incubatore Startup Torino (Borgo Po)."
		"tech_giant":
			return "Fase 4 Tech Giant attiva (%d/3 Dipartimenti): gestisci Droni, Robot MK2 e Bandi Enterprise Tier IV!" % unlocked_departments.size()
		_:
			return ""

# ==============================================================================
# MATERIALI, RACCOLTA FISICA E CONSEGNA (VENDITA € / CREDITI RICERCA 🔬 RC)
# ==============================================================================

func get_material_name(mat_id: String) -> String:
	var d: Dictionary = MATERIALS.get(mat_id, {})
	return str(d.get("name", mat_id))

func get_material_short(mat_id: String) -> String:
	var d: Dictionary = MATERIALS.get(mat_id, {})
	return str(d.get("short", mat_id))

func get_carried_count(mat_id: String) -> int:
	return maxi(0, int(carried_materials.get(mat_id, 0)))

func get_carried_total() -> int:
	var tot := 0
	for k in MATERIAL_ORDER:
		tot += get_carried_count(k)
	return tot

func get_stored_count(mat_id: String) -> int:
	return maxi(0, int(materials_storage.get(mat_id, 0)))

func get_stored_total() -> int:
	var tot := 0
	for k in MATERIAL_ORDER:
		tot += get_stored_count(k)
	return tot

func get_max_carry_capacity() -> int:
	var base := 12 + 6 * get_tech_rank("tech_extraction")
	var vdef: Dictionary = VEHICLES.get(active_vehicle, {})
	base += int(vdef.get("carry_bonus", 0))
	return base

func get_warehouse_count(mat_id: String) -> int:
	return get_stored_count(mat_id)

func get_warehouse_total() -> int:
	return get_stored_total()

func get_carry_capacity() -> int:
	return get_max_carry_capacity()

func get_active_vehicle_name() -> String:
	return str(VEHICLES.get(active_vehicle, {}).get("name", "A Piedi"))

func add_research_credits(amount: int, reason: String = "") -> void:
	if amount <= 0:
		return
	research_credits += amount
	total_rc_earned += amount
	if is_instance_valid(EventBus):
		EventBus.research_credits_changed.emit(research_credits, amount, reason)
		EventBus.tech_ops_updated.emit()

func add_stored_material(mat_id: String, qty: int) -> void:
	if qty <= 0 or not MATERIALS.has(mat_id):
		return
	materials_storage[mat_id] = get_stored_count(mat_id) + qty
	if is_instance_valid(EventBus):
		EventBus.materials_changed.emit()
		EventBus.backpack_updated.emit()

func has_stored_materials(reqs: Dictionary) -> bool:
	for k in reqs:
		if get_stored_count(str(k)) < int(reqs[k]):
			return false
	return true

func consume_stored_materials(reqs: Dictionary) -> bool:
	if not has_stored_materials(reqs):
		return false
	for k in reqs:
		var need := int(reqs[k])
		materials_storage[str(k)] = maxi(0, get_stored_count(str(k)) - need)
	if is_instance_valid(EventBus):
		EventBus.materials_changed.emit()
		EventBus.backpack_updated.emit()
	return true

func extract_from_node(node_id: String) -> Dictionary:
	if not post_ogr_quest_started and is_instance_valid(ContractManager) and ContractManager.is_ogr_unlocked():
		post_ogr_quest_started = true

	var cap := get_max_carry_capacity()
	var cur_carried := get_carried_total()
	if cur_carried >= cap:
		SoundManager.play_ui_error()
		EventBus.notification_posted.emit(
			"Cassa di Trasporto Piena (%d/%d)" % [cur_carried, cap],
			"Consegna i materiali alla Raffineria Miniera Alpina prima di estrarre ancora!",
			"warning"
		)
		return {"ok": false, "reason": "full"}

	if is_instance_valid(NeedsManager) and NeedsManager.get_energy() < 5.0:
		SoundManager.play_ui_error()
		EventBus.notification_posted.emit(
			"Energia Insufficiente",
			"Sei troppo stanco per azionare l'estrattore. Bevi un caffè o riposa in studio!",
			"warning"
		)
		return {"ok": false, "reason": "no_energy"}

	var ext_rank := get_tech_rank("tech_extraction")
	var base_yield := 2 + ext_rank
	if "dept_hardware" in unlocked_departments:
		base_yield += 1
	if active_incidents.has("inc_power_dip"):
		base_yield = maxi(1, base_yield - 1)

	var room := cap - cur_carried
	var actual_yield := mini(base_yield, room)
	var gained: Dictionary = {}

	for i in range(actual_yield):
		var mat_id := _pick_material_for_node(node_id, i, ext_rank)
		carried_materials[mat_id] = get_carried_count(mat_id) + 1
		gained[mat_id] = int(gained.get(mat_id, 0)) + 1

	total_manual_extractions += 1
	if is_instance_valid(NeedsManager):
		var energy_cost := maxf(1.5, 3.0 - 0.5 * float(ext_rank))
		NeedsManager.apply_effects(0.0, -energy_cost)

	var summary_parts: Array[String] = []
	for m in gained:
		summary_parts.append("+%d %s" % [int(gained[m]), get_material_short(str(m))])

	SoundManager.play_ui_success()
	EventBus.notification_posted.emit(
		"Materiali Estratti (%d/%d in Cassa)" % [get_carried_total(), cap],
		"%s — Trasportali alla Raffineria Miniera Alpina per ottenere 🔬 Crediti di Ricerca o €!" % ", ".join(summary_parts),
		"info"
	)
	EventBus.materials_changed.emit()
	EventBus.backpack_updated.emit()
	EventBus.tech_ops_updated.emit()
	return {"ok": true, "gained": gained, "carried_total": get_carried_total()}

func _pick_material_for_node(node_id: String, idx: int, ext_rank: int) -> String:
	match node_id:
		"node_copper", "vein_copper":
			if idx % 2 == 0:
				return "copper"
			return "circuits" if (total_manual_extractions + idx) % 2 == 0 else "copper"
		"node_silicon", "vein_silicon":
			if idx % 2 == 0:
				return "silicon"
			return "circuits" if (total_manual_extractions + idx) % 2 == 0 else "silicon"
		"node_alloy", "vein_alloy", _:
			if idx == 0:
				return "aluminum"
			if ext_rank >= 1 or total_materials_delivered >= 6:
				return "rare_earths" if (total_manual_extractions + idx) % 2 == 0 else "composites"
			return "composites" if idx % 2 == 1 else "rare_earths"

## Consegna i materiali trasportati alla Stazione di Raffinazione:
## li deposita nel Magazzino Aziendale (usabili per Robot e Drone) e accredita 🔬 Crediti di Ricerca!
func deliver_carried_for_research() -> Dictionary:
	var tot := get_carried_total()
	if tot <= 0:
		SoundManager.play_ui_error()
		EventBus.notification_posted.emit(
			"Nessun Materiale in Cassa",
			"Estrai prima i materiali dai 3 filoni della Miniera Alpina e portali qui!",
			"warning"
		)
		return {"ok": false, "units": 0, "rc_gained": 0}

	var raw_rc := 0.0
	var parts: Array[String] = []
	for k in MATERIAL_ORDER:
		var q := get_carried_count(k)
		if q <= 0:
			continue
		var def: Dictionary = MATERIALS[k]
		raw_rc += float(q) * float(def.get("rc_value", 2))
		materials_storage[k] = get_stored_count(k) + q
		carried_materials[k] = 0
		parts.append("%dx %s" % [q, get_material_short(k)])

	var mult := 1.0 + 0.15 * float(get_tech_rank("tech_extraction"))
	var rc_gain := maxi(1, int(roundf(raw_rc * mult)))
	total_materials_delivered += tot
	add_research_credits(rc_gain, "Raffinazione Materiali Miniera Alpina")
	GameManager.reputation_points += maxi(1, tot / 2)

	SoundManager.play_ui_success()
	EventBus.notification_posted.emit(
		"Materiali Raffinati & Stoccati!",
		"Consegnati %s al magazzino R&D: +%d 🔬 Crediti di Ricerca (Totale: %d RC)!" % [", ".join(parts), rc_gain, research_credits],
		"success"
	)
	EventBus.materials_changed.emit()
	EventBus.backpack_updated.emit()
	EventBus.tech_ops_updated.emit()
	SaveManager.request_auto_save()
	return {"ok": true, "units": tot, "rc_gained": rc_gain}

## Vende i materiali nella cassa di trasporto per denaro immediato (€).
func sell_carried_materials() -> Dictionary:
	var tot := get_carried_total()
	if tot <= 0:
		SoundManager.play_ui_error()
		EventBus.notification_posted.emit("Cassa Vuota", "Non stai trasportando materiali da vendere.", "warning")
		return {"ok": false, "units": 0, "earned": 0.0}

	var revenue := 0.0
	for k in MATERIAL_ORDER:
		var q := get_carried_count(k)
		if q <= 0:
			continue
		var def: Dictionary = MATERIALS[k]
		revenue += float(q) * float(def.get("sell_price", 20.0))
		carried_materials[k] = 0

	revenue = snappedf(revenue, 0.01)
	total_materials_delivered += tot
	EconomyManager.earn(revenue, "Vendita Materiali Tecnologici Raffinati (%d unità)" % tot)
	SoundManager.play_cash_register()
	EventBus.notification_posted.emit(
		"Materiali Venduti!",
		"Hai incassato € %0.2f per %d unità di materiali grezzi." % [revenue, tot],
		"success"
	)
	EventBus.materials_changed.emit()
	EventBus.backpack_updated.emit()
	EventBus.tech_ops_updated.emit()
	SaveManager.request_auto_save()
	return {"ok": true, "units": tot, "earned": revenue}

func deliver_carried_materials(mode: String = "research") -> Dictionary:
	if mode == "sell":
		var res := sell_carried_materials()
		res["euros"] = float(res.get("earned", 0.0))
		return res
	var res2 := deliver_carried_for_research()
	res2["euros"] = 0.0
	return res2

func sell_stored_material(mat_id: String, qty: int = 1) -> float:
	if qty <= 0 or not MATERIALS.has(mat_id):
		return 0.0
	var avail := get_stored_count(mat_id)
	if avail < qty:
		return 0.0
	var price := float(MATERIALS[mat_id].get("sell_price", 20.0)) * float(qty)
	materials_storage[mat_id] = avail - qty
	EconomyManager.earn(price, "Vendita Stock Magazzino: %dx %s" % [qty, get_material_short(mat_id)])
	SoundManager.play_cash_register()
	EventBus.materials_changed.emit()
	EventBus.tech_ops_updated.emit()
	SaveManager.request_auto_save()
	return price

# ==============================================================================
# ALBERO RICERCA TECNOLOGICA A 6 RAMI (🔬 CREDITI DI RICERCA)
# ==============================================================================

func get_tech_rank(branch_id: String) -> int:
	return clampi(int(tech_ranks.get(branch_id, 0)), 0, MAX_TECH_RANK)

func get_total_tech_rank() -> int:
	var tot := 0
	for b in TECH_BRANCH_ORDER:
		tot += get_tech_rank(b)
	return tot

func get_next_tech_rc_cost(branch_id: String) -> int:
	var def: Dictionary = TECH_BRANCHES.get(branch_id, {})
	if def.is_empty():
		return -1
	var cur := get_tech_rank(branch_id)
	if cur >= MAX_TECH_RANK:
		return -1
	var costs: Array = def.get("rc_costs", [])
	if cur >= costs.size():
		return -1
	return int(costs[cur])

func can_unlock_tech(branch_id: String) -> Dictionary:
	if not TECH_BRANCHES.has(branch_id):
		return {"allowed": false, "reason": "Ramo tecnologico non valido."}
	var cur := get_tech_rank(branch_id)
	if cur >= MAX_TECH_RANK:
		return {"allowed": false, "reason": "Livello massimo raggiunto (3/3).", "cost_rc": -1}
	var cost_rc := get_next_tech_rc_cost(branch_id)
	if research_credits < cost_rc:
		return {
			"allowed": false,
			"reason": "Crediti di Ricerca insufficienti: servono %d 🔬 RC (hai %d RC). Consegna materiali alla Raffineria!" % [cost_rc, research_credits],
			"cost_rc": cost_rc
		}
	return {"allowed": true, "reason": "", "cost_rc": cost_rc}

func unlock_tech(branch_id: String) -> bool:
	var chk := can_unlock_tech(branch_id)
	if not bool(chk.get("allowed", false)):
		SoundManager.play_ui_error()
		EventBus.notification_posted.emit("Ricerca Tecnologica Bloccata", str(chk.get("reason", "")), "warning")
		return false

	var cost_rc := int(chk.get("cost_rc", 0))
	research_credits -= cost_rc
	var new_rk := get_tech_rank(branch_id) + 1
	tech_ranks[branch_id] = new_rk
	var title := str(TECH_BRANCHES[branch_id].get("title", branch_id))

	SoundManager.play_ui_success()
	EventBus.research_credits_changed.emit(research_credits, -cost_rc, "Ricerca: %s Lv.%d" % [title, new_rk])
	EventBus.notification_posted.emit(
		"Tecnologia Sbloccata! (🔬 -%d RC)" % cost_rc,
		"%s potenziata a Livello %d/%d!" % [title, new_rk, MAX_TECH_RANK],
		"success"
	)
	EventBus.tech_ops_updated.emit()
	SaveManager.request_auto_save()
	return true

func research_branch(branch_id: String) -> bool:
	return unlock_tech(branch_id)

func get_all_tech_branches() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for b in TECH_BRANCH_ORDER:
		var def: Dictionary = TECH_BRANCHES[b].duplicate(true)
		var rk := get_tech_rank(b)
		var chk := can_unlock_tech(b)
		def["rank"] = rk
		def["max_rank"] = MAX_TECH_RANK
		def["next_rc_cost"] = get_next_tech_rc_cost(b)
		def["next_euro_cost"] = 0.0
		def["can_unlock"] = bool(chk.get("allowed", false))
		def["can_research"] = bool(chk.get("allowed", false))
		def["block_reason"] = str(chk.get("reason", ""))
		out.append(def)
	return out

# --- Moltiplicatori R&D Post-OGR ---
func get_webforge_tech_speed_bonus() -> float:
	return 0.45 * float(get_tech_rank("tech_software_ai"))

func get_employee_tech_speed_mult() -> float:
	var mult := 1.0 + 0.15 * float(get_tech_rank("tech_software_ai"))
	if "dept_cloud_ai" in unlocked_departments:
		mult += 0.25
	return mult

func get_rack_tech_mult() -> float:
	var mult := 1.0 + 0.15 * float(get_tech_rank("tech_cloud_infra"))
	if "dept_cloud_ai" in unlocked_departments:
		mult += 0.25
	return mult

func get_netshield_tech_mult() -> float:
	return 1.0 + 0.15 * float(get_tech_rank("tech_cyber_defense"))

# ==============================================================================
# MINING ROBOT MK1, MK2 & NASTRO TRASPORTATORE (AUTOMAZIONE FASE 3)
# ==============================================================================

func is_robot_built(slot: int = 1) -> bool:
	var r: Dictionary = robots.get(slot, {})
	return bool(r.get("built", false))

func get_robot_state(slot: int = 1) -> Dictionary:
	return robots.get(slot, _default_robot_state(slot))

func get_robot_hopper_total(slot: int = 1) -> int:
	var r: Dictionary = get_robot_state(slot)
	var h: Dictionary = r.get("hopper", {})
	var tot := 0
	for k in h:
		tot += maxi(0, int(h[k]))
	return tot

func get_robot_stored_total(slot: int = 1) -> int:
	return get_robot_hopper_total(slot)

func get_robot_capacity(slot: int = 1) -> int:
	return int(get_robot_state(slot).get("hopper_cap", 18))

func can_build_mining_robot(slot: int = 1) -> Dictionary:
	if not ROBOT_RECIPES.has(slot):
		return {"allowed": false, "reason": "Slot robot non valido."}
	if is_robot_built(slot):
		return {"allowed": false, "reason": "Il Mining Robot nello slot %d è già installato e operativo!" % slot}
	var rec: Dictionary = ROBOT_RECIPES[slot]
	var req_tech := int(rec.get("tech_req", 1))
	if get_tech_rank("tech_automation") < req_tech:
		return {
			"allowed": false,
			"reason": "Richiede ricerca 'Automazione & Robotica Lv.%d' su TO-OS." % req_tech
		}
	var req_mats: Dictionary = rec.get("materials", {})
	var missing: Array[String] = []
	for m in req_mats:
		var need := int(req_mats[m])
		var have := get_stored_count(str(m))
		if have < need:
			missing.append("%s (%d/%d)" % [get_material_short(str(m)), have, need])
	if not missing.is_empty():
		return {
			"allowed": false,
			"reason": "Materiali in magazzino insufficienti: %s. Consegna materiali alla Raffineria Miniera Alpina!" % ", ".join(missing)
		}
	var cost_eur := float(rec.get("cost_eur", 450.0))
	if not EconomyManager.can_afford(cost_eur):
		return {
			"allowed": false,
			"reason": "Fondi insufficienti: servono € %0.2f per i servomotori e il telaio." % cost_eur
		}
	return {"allowed": true, "reason": ""}

func build_mining_robot(slot: int = 1) -> bool:
	var chk := can_build_mining_robot(slot)
	if not bool(chk.get("allowed", false)):
		SoundManager.play_ui_error()
		EventBus.notification_posted.emit("Costruzione Robot Bloccata", str(chk.get("reason", "")), "warning")
		return false

	var rec: Dictionary = ROBOT_RECIPES[slot]
	var cost_eur := float(rec.get("cost_eur", 450.0))
	var req_mats: Dictionary = rec.get("materials", {})
	if not EconomyManager.spend(cost_eur, "Assemblaggio " + str(rec["name"])):
		return false
	consume_stored_materials(req_mats)

	var st := _default_robot_state(slot)
	st["built"] = true
	st["condition"] = 100.0
	robots[slot] = st

	GameManager.reputation_points += 18 if slot == 1 else 28
	add_research_credits(8 if slot == 1 else 15, "Messa in servizio " + str(rec["name"]))
	if is_instance_valid(UpgradeManager):
		UpgradeManager.add_stars(2, str(rec["name"]) + " Costruito!")

	SoundManager.play_ui_success()
	EventBus.notification_posted.emit(
		"%s Operativo!" % str(rec["name"]),
		"Il robot ha iniziato l'estrazione autonoma alla Miniera Alpina! Raccogli periodicamente i materiali dal suo deposito.",
		"success"
	)
	EventBus.tech_ops_updated.emit()
	SaveManager.request_auto_save()
	return true

func upgrade_mining_robot(slot: int = 1) -> bool:
	if not is_robot_built(slot):
		return false
	var r: Dictionary = robots[slot]
	var cur_lvl := int(r.get("level", 1))
	if cur_lvl >= 3:
		EventBus.notification_posted.emit("Potenziamento Massimo", "Questo Mining Robot è già al Livello 3/3!", "info")
		return false
	var cost_eur := 320.0 * float(cur_lvl)
	var cost_rc := 8 * cur_lvl
	if research_credits < cost_rc:
		SoundManager.play_ui_error()
		EventBus.notification_posted.emit("RC Insufficienti", "Servono %d 🔬 RC per potenziare il firmware del robot." % cost_rc, "warning")
		return false
	if not EconomyManager.can_afford(cost_eur):
		SoundManager.play_ui_error()
		EventBus.notification_posted.emit("Fondi Insufficienti", "Servono € %0.2f per potenziare il Mining Robot." % cost_eur, "warning")
		return false
	EconomyManager.spend(cost_eur, "Upgrade Firmware & Trivella Mining Robot #%d Lv.%d" % [slot, cur_lvl + 1])
	research_credits -= cost_rc
	r["level"] = cur_lvl + 1
	r["hopper_cap"] = int(r.get("hopper_cap", 18)) + 8
	r["condition"] = 100.0
	r["jammed"] = false
	SoundManager.play_ui_success()
	EventBus.research_credits_changed.emit(research_credits, -cost_rc, "Upgrade Mining Robot")
	EventBus.notification_posted.emit(
		"Mining Robot Potenziato a Lv.%d!" % (cur_lvl + 1),
		"Velocità d'estrazione aumentata, usura ridotta e capienza hopper estesa a %d unità!" % int(r["hopper_cap"]),
		"success"
	)
	EventBus.tech_ops_updated.emit()
	SaveManager.request_auto_save()
	return true

func maintain_mining_robot(slot: int = 1) -> bool:
	if not is_robot_built(slot):
		return false
	var r: Dictionary = robots[slot]
	r["condition"] = 100.0
	r["jammed"] = false
	if active_incidents.has("inc_robot_jam"):
		active_incidents.erase("inc_robot_jam")
		EventBus.incident_changed.emit()
	SoundManager.play_ui_success()
	EventBus.notification_posted.emit(
		"Manutenzione Robot Completata",
		"Trivelle lubrificate, sensori puliti e batteria al 100%. Il Mining Robot #%d è tornato a pieno regime!" % slot,
		"success"
	)
	EventBus.tech_ops_updated.emit()
	SaveManager.request_auto_save()
	return true

func collect_robot_hopper(slot: int = 1) -> Dictionary:
	if not is_robot_built(slot):
		return {"ok": false, "units": 0, "rc": 0}
	var r: Dictionary = robots[slot]
	var hopper: Dictionary = r.get("hopper", {})
	var tot := 0
	var rc_bonus := 0
	var parts: Array[String] = []
	for k in MATERIAL_ORDER:
		var q := maxi(0, int(hopper.get(k, 0)))
		if q <= 0:
			continue
		tot += q
		materials_storage[k] = get_stored_count(k) + q
		rc_bonus += maxi(1, int(MATERIALS[k].get("rc_value", 2)) * q / 2)
		hopper[k] = 0
		parts.append("%dx %s" % [q, get_material_short(k)])
	r["hopper"] = hopper

	if tot <= 0:
		EventBus.notification_posted.emit(
			"Deposito Robot Vuoto",
			"Il Mining Robot #%d sta ancora scavando (Condizione: %d%%). Torna tra poco!" % [slot, int(r.get("condition", 100.0))],
			"info"
		)
		return {"ok": false, "units": 0, "rc": 0}

	add_research_credits(rc_bonus, "Raccolta Hopper Mining Robot #%d" % slot)
	SoundManager.play_ui_success()
	EventBus.notification_posted.emit(
		"Deposito Mining Robot #%d Svuotato!" % slot,
		"Trasferiti in magazzino %s (+%d 🔬 RC)!" % [", ".join(parts), rc_bonus],
		"success"
	)
	EventBus.materials_changed.emit()
	EventBus.backpack_updated.emit()
	EventBus.tech_ops_updated.emit()
	SaveManager.request_auto_save()
	return {"ok": true, "units": tot, "rc": rc_bonus}

func collect_from_robot(slot: int = 1) -> int:
	return int(collect_robot_hopper(slot).get("units", 0))

func can_build_conveyor() -> Dictionary:
	if conveyor_installed:
		return {"allowed": false, "reason": "Il Nastro Trasportatore OGR è già installato."}
	if get_tech_rank("tech_automation") < 2:
		return {"allowed": false, "reason": "Richiede 'Automazione & Robotica Lv.2' su TO-OS."}
	var req_mats: Dictionary = CONVEYOR_RECIPE["materials"]
	if not has_stored_materials(req_mats):
		return {"allowed": false, "reason": "Servono 4 Alluminio, 3 Rame e 2 Circuiti in magazzino."}
	var cost := float(CONVEYOR_RECIPE["cost_eur"])
	if not EconomyManager.can_afford(cost):
		return {"allowed": false, "reason": "Servono € %0.2f per il Nastro Trasportatore." % cost}
	return {"allowed": true, "reason": ""}

func build_conveyor() -> bool:
	var chk := can_build_conveyor()
	if not bool(chk.get("allowed", false)):
		SoundManager.play_ui_error()
		EventBus.notification_posted.emit("Nastro Trasportatore Bloccato", str(chk.get("reason", "")), "warning")
		return false
	EconomyManager.spend(float(CONVEYOR_RECIPE["cost_eur"]), "Installazione " + str(CONVEYOR_RECIPE["name"]))
	consume_stored_materials(CONVEYOR_RECIPE["materials"])
	conveyor_installed = true
	for slot in [1, 2]:
		if robots.has(slot):
			robots[slot]["hopper_cap"] = int(robots[slot].get("hopper_cap", 18)) + 12
	add_research_credits(10, "Nastro Trasportatore OGR Installato")
	SoundManager.play_ui_success()
	EventBus.notification_posted.emit(
		"Nastro Trasportatore OGR Attivo!",
		"I materiali estratti dai Mining Robot vengono ora convogliati e raffinati automaticamente al 50% direttamente nel magazzino!",
		"success"
	)
	EventBus.tech_ops_updated.emit()
	SaveManager.request_auto_save()
	return true

func unlock_conveyor() -> bool:
	return build_conveyor()

func _tick_robots(minutes: int) -> Dictionary:
	var total_auto_units := 0
	var total_auto_rc := 0
	var auto_rank := get_tech_rank("tech_automation")
	var has_hw_dept := "dept_hardware" in unlocked_departments

	for slot in [1, 2]:
		if not is_robot_built(slot):
			continue
		var r: Dictionary = robots[slot]
		if has_hw_dept:
			r["condition"] = 100.0
			r["jammed"] = false
		if bool(r.get("jammed", false)) or float(r.get("condition", 100.0)) <= 15.0:
			continue

		var base_cycle := int(ROBOT_RECIPES[slot].get("cycle_minutes", 30))
		var lvl := int(r.get("level", 1))
		var eff_cycle := maxi(10, base_cycle - (auto_rank * 4) - ((lvl - 1) * 4))
		if active_incidents.has("inc_power_dip"):
			eff_cycle = int(roundf(float(eff_cycle) * 1.35))

		r["timer_mins"] = int(r.get("timer_mins", 0)) + minutes
		while int(r["timer_mins"]) >= eff_cycle:
			r["timer_mins"] = int(r["timer_mins"]) - eff_cycle
			var cyc := int(r.get("cycle_index", 0))
			r["cycle_index"] = cyc + 1
			var pool: Array[String] = ["copper", "silicon", "aluminum", "circuits"]
			if slot == 2 or get_tech_rank("tech_extraction") >= 1 or lvl >= 2:
				pool.append("rare_earths")
				pool.append("composites")
			var mat_id: String = pool[cyc % pool.size()]
			var yield_qty := 1 + (1 if slot == 2 else 0) + (1 if has_hw_dept and cyc % 2 == 0 else 0)

			if conveyor_installed or (drone_built and drone_auto_logistics):
				materials_storage[mat_id] = get_stored_count(mat_id) + yield_qty
				total_auto_rc += 1
			else:
				var cur_h := get_robot_hopper_total(slot)
				var cap_h := int(r.get("hopper_cap", 18))
				if cur_h < cap_h:
					var h: Dictionary = r.get("hopper", {})
					var add_q := mini(yield_qty, cap_h - cur_h)
					h[mat_id] = int(h.get(mat_id, 0)) + add_q
					r["hopper"] = h

			r["total_produced"] = int(r.get("total_produced", 0)) + yield_qty
			total_auto_units += yield_qty

			if not has_hw_dept:
				var wear := 2.2 * (0.6 if auto_rank >= 3 else 1.0)
				r["condition"] = maxf(0.0, float(r.get("condition", 100.0)) - wear)

	if total_auto_rc > 0:
		research_credits += total_auto_rc
		total_rc_earned += total_auto_rc
	if total_auto_units > 0 and is_instance_valid(EventBus):
		EventBus.materials_changed.emit()
		EventBus.tech_ops_updated.emit()
	return {"units": total_auto_units, "rc": total_auto_rc}

# ==============================================================================
# COSTRUZIONE FISICA DRONE 3D (7 FASI) & OPERAZIONI DI VOLO
# ==============================================================================

func get_current_drone_step_info() -> Dictionary:
	if drone_built or drone_assembly_step >= DRONE_STEPS.size():
		return {
			"step": 7,
			"id": "completed",
			"title": "TO-Drone MK1 Operativo (7/7)",
			"desc": "Il drone quadricottero industriale è assemblato e collaudato sulla Piazzola H!",
			"materials": {},
			"completed": true
		}
	return DRONE_STEPS[drone_assembly_step].duplicate(true)

func can_advance_drone_step() -> Dictionary:
	if drone_built or drone_assembly_step >= DRONE_STEPS.size():
		return {"allowed": false, "reason": "Il TO-Drone MK1 è già stato completato e collaudato!"}
	if get_tech_rank("tech_drone_avionics") < 1:
		return {
			"allowed": false,
			"reason": "Sblocca prima 'Hardware & Avionica Droni Lv.1' (15 🔬 RC) nell'app Conoscenza R&D su TO-OS!"
		}
	var step_def: Dictionary = DRONE_STEPS[drone_assembly_step]
	var req_mats: Dictionary = step_def.get("materials", {})
	var missing: Array[String] = []
	for m in req_mats:
		var need := int(req_mats[m])
		var have := get_stored_count(str(m))
		if have < need:
			missing.append("%s (%d/%d)" % [get_material_short(str(m)), have, need])
	if not missing.is_empty():
		return {
			"allowed": false,
			"reason": "Componenti mancanti in magazzino per %s: %s." % [str(step_def["title"]), ", ".join(missing)]
		}
	return {"allowed": true, "reason": ""}

func advance_drone_assembly_step() -> bool:
	var chk := can_advance_drone_step()
	if not bool(chk.get("allowed", false)):
		SoundManager.play_ui_error()
		EventBus.notification_posted.emit("Assemblaggio Drone Bloccato", str(chk.get("reason", "")), "warning")
		return false

	var step_def: Dictionary = DRONE_STEPS[drone_assembly_step]
	var req_mats: Dictionary = step_def.get("materials", {})
	if not req_mats.is_empty():
		consume_stored_materials(req_mats)

	drone_assembly_step += 1
	var rc_rew := int(step_def.get("rc_reward", 5))
	add_research_credits(rc_rew, str(step_def["title"]))
	GameManager.reputation_points += 5

	if drone_assembly_step >= DRONE_STEPS.size():
		drone_built = true
		if get_tech_rank("tech_drone_avionics") >= 3:
			drone_auto_logistics = true
		GameManager.reputation_points += 30
		if is_instance_valid(UpgradeManager):
			UpgradeManager.add_stars(3, "TO-Drone MK1 Assemblato & Collaudato!")
		SoundManager.play_ui_success()
		EventBus.notification_posted.emit(
			"🚁 TO-DRONE MK1 COMPLETATO & COLLAUDATO (7/7)!",
			"Il tuo drone industriale 3D è pronto sulla Piazzola H del Lab Droni! Puoi lanciare Missioni di Rilievo LiDAR, Ispezioni e Logistica Automatica!",
			"success"
		)
	else:
		var next_def: Dictionary = DRONE_STEPS[drone_assembly_step]
		SoundManager.play_ui_success()
		EventBus.notification_posted.emit(
			"Componente Installato (%d/7)!" % drone_assembly_step,
			"Completata %s (+%d 🔬 RC). Prossimo passo: %s." % [str(step_def["title"]), rc_rew, str(next_def["title"])],
			"success"
		)

	EventBus.tech_ops_updated.emit()
	SaveManager.request_auto_save()
	return true

func install_next_drone_step() -> bool:
	return advance_drone_assembly_step()

func start_drone_mission(mission_id: String) -> bool:
	if not drone_built:
		SoundManager.play_ui_error()
		EventBus.notification_posted.emit("Drone Non Assemblato", "Completa prima le 7 fasi di costruzione sul Banco del Lab Droni!", "warning")
		return false
	if not active_drone_mission.is_empty():
		SoundManager.play_ui_error()
		EventBus.notification_posted.emit("Drone Già in Volo", "Il TO-Drone MK1 è attualmente impegnato in missione (%d min rimanenti)." % int(active_drone_mission.get("remaining_mins", 0)), "info")
		return false
	if not DRONE_MISSIONS.has(mission_id):
		return false

	var def: Dictionary = DRONE_MISSIONS[mission_id]
	var dur := int(def.get("duration_mins", 90))
	if active_incidents.has("inc_weather_fog") and get_tech_rank("tech_drone_avionics") < 2:
		dur = int(roundf(float(dur) * 1.25))

	active_drone_mission = {
		"id": mission_id,
		"title": str(def["title"]),
		"remaining_mins": dur,
		"total_mins": dur
	}
	SoundManager.play_ui_success()
	EventBus.notification_posted.emit(
		"🚁 Missione Drone Avviata!",
		"%s in corso (durata stimata: %d min di gioco)." % [str(def["title"]), dur],
		"info"
	)
	EventBus.tech_ops_updated.emit()
	SaveManager.request_auto_save()
	return true

func toggle_drone_auto_logistics() -> bool:
	if not drone_built:
		return false
	drone_auto_logistics = not drone_auto_logistics
	EventBus.notification_posted.emit(
		"Logistica Aerea Drone: %s" % ("ATTIVA" if drone_auto_logistics else "DISATTIVATA"),
		"Il TO-Drone MK1 trasferirà automaticamente i materiali estratti dai Mining Robot al magazzino R&D." if drone_auto_logistics else "Modalità logistica automatica disattivata.",
		"info"
	)
	EventBus.tech_ops_updated.emit()
	return drone_auto_logistics

func _tick_drone_mission(minutes: int) -> void:
	if active_drone_mission.is_empty():
		return
	var rem := int(active_drone_mission.get("remaining_mins", 0)) - minutes
	if rem > 0:
		active_drone_mission["remaining_mins"] = rem
		return

	var mid := str(active_drone_mission.get("id", "drone_lidar_survey"))
	active_drone_mission.clear()
	completed_drone_missions_count += 1

	var def: Dictionary = DRONE_MISSIONS.get(mid, DRONE_MISSIONS["drone_lidar_survey"])
	var av_rank := get_tech_rank("tech_drone_avionics")
	var mult := 1.0 + (0.30 * float(maxi(0, av_rank - 1)))
	if "dept_aerospace" in unlocked_departments:
		mult += 0.40

	var pay := snappedf(float(def.get("reward_eur", 680.0)) * mult, 0.01)
	var rc := int(roundf(float(def.get("reward_rc", 12)) * mult))
	var rep := int(def.get("reward_rep", 10))

	EconomyManager.earn(pay, "Missione TO-Drone MK1: " + str(def["title"]))
	add_research_credits(rc, "Telemetria Volo Drone: " + str(def["title"]))
	GameManager.reputation_points += rep
	if completed_drone_missions_count % 2 == 1 and is_instance_valid(UpgradeManager):
		UpgradeManager.add_stars(1, "Operazione Aerea TO-Drone MK1")

	SoundManager.play_cash_register()
	EventBus.notification_posted.emit(
		"🚁 Missione Drone Completata!",
		"%s conclusa con successo: +€ %0.2f · +%d 🔬 RC · +%d Reputazione!" % [str(def["title"]), pay, rc, rep],
		"success"
	)
	EventBus.tech_ops_updated.emit()

# ==============================================================================
# FASE 4: DIPARTIMENTI AZIENDALI & RUOLO CEO (INCUBATORE STARTUP TORINO)
# ==============================================================================

func is_department_unlocked(dept_id: String) -> bool:
	return dept_id in unlocked_departments

func can_unlock_department(dept_id: String) -> Dictionary:
	if not DEPARTMENTS.has(dept_id):
		return {"allowed": false, "reason": "Dipartimento non valido."}
	if is_department_unlocked(dept_id):
		return {"allowed": false, "reason": "Questo dipartimento è già operativo!"}
	if not drone_built and GameManager.company_tier < 3:
		return {"allowed": false, "reason": "Completa prima il TO-Drone MK1 o espandi l'azienda a Software House Strutturata (Tier 3)."}
	var def: Dictionary = DEPARTMENTS[dept_id]
	var cost_rc := int(def.get("cost_rc", 30))
	var cost_eur := float(def.get("cost_eur", 2400.0))
	if research_credits < cost_rc:
		return {"allowed": false, "reason": "Servono %d 🔬 Crediti di Ricerca (attuali: %d RC)." % [cost_rc, research_credits]}
	if not EconomyManager.can_afford(cost_eur):
		return {"allowed": false, "reason": "Servono € %0.2f di capitale aziendale." % cost_eur}
	return {"allowed": true, "reason": ""}

func unlock_department(dept_id: String) -> bool:
	var chk := can_unlock_department(dept_id)
	if not bool(chk.get("allowed", false)):
		SoundManager.play_ui_error()
		EventBus.notification_posted.emit("Fondazione Dipartimento Bloccata", str(chk.get("reason", "")), "warning")
		return false

	var def: Dictionary = DEPARTMENTS[dept_id]
	var cost_eur := float(def.get("cost_eur", 2400.0))
	var cost_rc := int(def.get("cost_rc", 30))
	if not EconomyManager.spend(cost_eur, "Fondazione " + str(def["title"])):
		return false
	research_credits -= cost_rc
	unlocked_departments.append(dept_id)

	GameManager.reputation_points += 35
	if GameManager.company_tier < 4 and unlocked_departments.size() >= 2:
		GameManager.company_tier = 4
	if is_instance_valid(UpgradeManager):
		UpgradeManager.add_stars(2, "Nuovo Dipartimento: " + str(def["title"]))

	SoundManager.play_ui_success()
	EventBus.research_credits_changed.emit(research_credits, -cost_rc, "Fondazione " + str(def["title"]))
	EventBus.notification_posted.emit(
		"🏛 Dipartimento Aziendale Fondato!",
		"%s è operativo presso l'Incubatore Startup Torino (+€ %0.0f/giorno, +%d 🔬 RC/giorno)!" % [str(def["title"]), float(def["daily_eur"]), int(def["daily_rc"])],
		"success"
	)
	EventBus.tech_ops_updated.emit()
	SaveManager.request_auto_save()
	return true

func upgrade_department(dept_id: String) -> bool:
	return unlock_department(dept_id)

func get_total_department_levels() -> int:
	return unlocked_departments.size()

func calculate_departments_daily_revenue() -> float:
	var tot := 0.0
	for d in unlocked_departments:
		if DEPARTMENTS.has(d):
			tot += float(DEPARTMENTS[d].get("daily_eur", 0.0))
	return tot

func calculate_daily_department_revenue() -> float:
	return calculate_departments_daily_revenue()

func calculate_departments_daily_rc() -> int:
	var tot := 0
	for d in unlocked_departments:
		if DEPARTMENTS.has(d):
			tot += int(DEPARTMENTS[d].get("daily_rc", 0))
	return tot

# ==============================================================================
# IMPREVISTI DINAMICI (PRODUTTIVI, IT, AZIENDALI, METEO)
# ==============================================================================

func trigger_incident(inc_id: String) -> bool:
	var norm_id := inc_id if INCIDENT_DEFS.has(inc_id) else ("inc_" + inc_id)
	if not INCIDENT_DEFS.has(norm_id) or active_incidents.has(norm_id):
		return false
	inc_id = norm_id
	var def: Dictionary = INCIDENT_DEFS[inc_id].duplicate(true)

	# Auto-mitigazione tramite Ricerca / Dipendenti / Dipartimenti
	if inc_id == "inc_cyber_breach":
		var cyber_rk := get_tech_rank("tech_cyber_defense")
		var block_chance := 0.0
		if cyber_rk == 1:
			block_chance = 0.45
		elif cyber_rk == 2:
			block_chance = 0.80
		elif cyber_rk >= 3:
			block_chance = 1.0
		if randf() < block_chance:
			add_research_credits(3, "Attacco Cyber Respinto Automaticamente")
			EventBus.notification_posted.emit(
				"🛡 Scudo AI Cyber Attivo!",
				"Tentativo di intrusione bloccato automaticamente da Sicurezza & AI (+3 🔬 RC)!",
				"success"
			)
			return false
	elif inc_id == "inc_robot_jam" and ("dept_hardware" in unlocked_departments):
		EventBus.notification_posted.emit(
			"🤖 Auto-Riparazione Dipartimento Hardware",
			"Il team dell'Ing. Ferrero ha risolto automaticamente un inceppamento al Mining Robot!",
			"info"
		)
		return false

	active_incidents[inc_id] = def
	if inc_id == "inc_robot_jam" and is_robot_built(1):
		robots[1]["jammed"] = true
	EventBus.incident_changed.emit()
	EventBus.tech_ops_updated.emit()
	EventBus.notification_posted.emit("⚠ IMPREVISTO OPERATIVO: " + str(def["title"]), str(def["desc"]), "warning")
	return true

func resolve_incident(inc_id: String, physical_free: bool = false) -> bool:
	var norm_id := inc_id if active_incidents.has(inc_id) else ("inc_" + inc_id)
	if not active_incidents.has(norm_id):
		return false
	inc_id = norm_id
	var def: Dictionary = active_incidents[inc_id]
	var cost := 0.0 if physical_free else float(def.get("fix_cost_eur", 0.0))
	if cost > 0.0 and not EconomyManager.can_afford(cost):
		SoundManager.play_ui_error()
		EventBus.notification_posted.emit("Fondi Insufficienti", "Servono € %0.2f per risolvere l'imprevisto da remoto (oppure intervieni fisicamente sul posto gratis!)." % cost, "warning")
		return false
	if cost > 0.0:
		EconomyManager.spend(cost, "Risoluzione Imprevisto: " + str(def["title"]))

	active_incidents.erase(inc_id)
	if inc_id == "inc_robot_jam":
		for slot in [1, 2]:
			if robots.has(slot):
				robots[slot]["jammed"] = false
				robots[slot]["condition"] = maxf(65.0, float(robots[slot].get("condition", 100.0)))
	elif inc_id == "inc_client_urgent":
		EconomyManager.earn(220.0, "Bonus Risoluzione Escalation Cliente Enterprise")
		GameManager.reputation_points += 6
	add_research_credits(3, "Analisi Imprevisto: " + str(def["title"]))

	SoundManager.play_ui_success()
	EventBus.incident_changed.emit()
	EventBus.tech_ops_updated.emit()
	EventBus.notification_posted.emit(
		"Imprevisto Risolto! (+3 🔬 RC)",
		"%s ripristinato con successo." % str(def["title"]),
		"success"
	)
	SaveManager.request_auto_save()
	return true

func get_active_incidents_list() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for k in active_incidents:
		out.append(active_incidents[k])
	return out

# ==============================================================================
# TRASPORTI E MOBILITÀ URBANA (PIEDI, BICI TECH, BUS GTT, AUTO EV)
# ==============================================================================

func has_vehicle(vehicle_id: String) -> bool:
	return vehicle_id in owned_vehicles

func buy_or_toggle_vehicle(vehicle_id: String) -> bool:
	if not VEHICLES.has(vehicle_id):
		return false
	var def: Dictionary = VEHICLES[vehicle_id]
	if not has_vehicle(vehicle_id):
		var cost := float(def.get("cost", 0.0))
		if not EconomyManager.can_afford(cost):
			SoundManager.play_ui_error()
			EventBus.notification_posted.emit(
				"Fondi Insufficienti",
				"Servono € %0.2f per acquistare «%s»." % [cost, str(def["name"])],
				"warning"
			)
			return false
		EconomyManager.spend(cost, "Mobilità Aziendale: " + str(def["name"]))
		owned_vehicles.append(vehicle_id)
		if vehicle_id == "company_ev":
			GameManager.reputation_points += 15
		SoundManager.play_cash_register()
		EventBus.notification_posted.emit(
			"Nuovo Mezzo Sbloccato!",
			"Hai acquistato %s (%s)!" % [str(def["name"]), str(def["desc"])],
			"success"
		)

	if vehicle_id == "bus_pass":
		EventBus.tech_ops_updated.emit()
		SaveManager.request_auto_save()
		return true

	if active_vehicle == vehicle_id and vehicle_id != "foot":
		active_vehicle = "foot"
		EventBus.notification_posted.emit("Mobilità Urbana", "Sei sceso dal mezzo: ti muovi ora a piedi.", "info")
	else:
		active_vehicle = vehicle_id
		EventBus.notification_posted.emit(
			"Mezzo Attivo: " + str(def["name"]),
			str(def["desc"]),
			"success"
		)
	SoundManager.play_ui_click()
	EventBus.vehicle_changed.emit(active_vehicle)
	EventBus.tech_ops_updated.emit()
	SaveManager.request_auto_save()
	return true

func get_vehicle_speed_mult() -> float:
	var def: Dictionary = VEHICLES.get(active_vehicle, {})
	return float(def.get("speed_mult", 1.0))

func get_vehicle_sprint_drain_mult() -> float:
	if active_vehicle == "bike":
		return 0.65
	if active_vehicle == "company_ev":
		return 0.35
	return 1.0

func unlock_and_toggle_vehicle(vehicle_id: String) -> bool:
	return buy_or_toggle_vehicle(vehicle_id)

func fast_travel_to_bus_stop(stop_id: String) -> bool:
	var norm_id := stop_id
	if not BUS_STOPS.has(norm_id) and norm_id.begins_with("stop_"):
		norm_id = "bus_" + norm_id.substr(5)
	if not BUS_STOPS.has(norm_id):
		return false
	var stop: Dictionary = BUS_STOPS[norm_id]
	if not has_vehicle("bus_pass"):
		var ticket_cost := 2.00
		if not EconomyManager.can_afford(ticket_cost):
			SoundManager.play_ui_error()
			EventBus.notification_posted.emit("Biglietto GTT (€ 2,00)", "Fondi insufficienti per la corsa urbana GTT (€ 2,00).", "warning")
			return false
		EconomyManager.spend(ticket_cost, "Biglietto Corsa Singola GTT -> " + str(stop["name"]))
	if is_instance_valid(GameManager.player_node):
		GameManager.player_node.global_position = stop["pos"]
	SoundManager.play_ui_success()
	EventBus.notification_posted.emit(
		"🚌 Linea Elettrica GTT Torino",
		"Arrivato a: %s." % str(stop["name"]),
		"info"
	)
	return true

func travel_by_bus(stop_id: String) -> bool:
	return fast_travel_to_bus_stop(stop_id)

# ==============================================================================
# SIMULAZIONE NEL TEMPO & DURANTE IL SONNO
# ==============================================================================

func _on_time_tick(_h: int, _m: int, _d: int) -> void:
	_tick_robots(1)
	_tick_drone_mission(1)

func _on_day_passed(new_day: int) -> void:
	var dept_eur := calculate_departments_daily_revenue()
	var dept_rc := calculate_departments_daily_rc()
	if dept_eur > 0.0:
		EconomyManager.earn(dept_eur, "Rendita Operativa Dipartimenti Aziendali (Giorno %d)" % new_day)
	if dept_rc > 0:
		add_research_credits(dept_rc, "Ricerca Quotidiana Dipartimenti (Giorno %d)" % new_day)
	if dept_eur > 0.0 or dept_rc > 0:
		EventBus.notification_posted.emit(
			"Report Giornaliero Dipartimenti",
			"I tuoi dipartimenti hanno generato +€ %0.2f e +%d 🔬 Crediti di Ricerca!" % [dept_eur, dept_rc],
			"success"
		)

	# Valuta un imprevisto dinamico post-OGR (se non ce ne sono già troppi attivi)
	if is_post_ogr_unlocked() and active_incidents.size() < 2 and new_day > 2:
		if randf() < 0.35:
			var pool: Array[String] = ["inc_client_urgent", "inc_cyber_breach", "inc_weather_fog"]
			if is_robot_built(1):
				pool.append("inc_robot_jam")
				pool.append("inc_power_dip")
			var pick: String = pool[randi() % pool.size()]
			trigger_incident(pick)

## Avanza la produzione dei robot e delle missioni drone durante le ore di sonno!
func simulate_sleep_hours(hours: float) -> Dictionary:
	var mins := maxi(0, int(roundf(hours * 60.0)))
	if mins <= 0:
		return {"robot_units": 0, "extracted": 0, "robot_rc": 0}
	var rob_res := _tick_robots(mins)
	_tick_drone_mission(mins)
	var units := int(rob_res.get("units", 0))
	return {
		"robot_units": units,
		"extracted": units,
		"robot_rc": int(rob_res.get("rc", 0))
	}

# ==============================================================================
# SERIALIZZAZIONE SALVATAGGIO
# ==============================================================================

func serialize() -> Dictionary:
	return {
		"post_ogr_quest_started": post_ogr_quest_started,
		"research_credits": research_credits,
		"carried_materials": carried_materials.duplicate(),
		"materials_storage": materials_storage.duplicate(),
		"tech_ranks": tech_ranks.duplicate(),
		"total_manual_extractions": total_manual_extractions,
		"total_materials_delivered": total_materials_delivered,
		"total_rc_earned": total_rc_earned,
		"robots": robots.duplicate(true),
		"conveyor_installed": conveyor_installed,
		"drone_assembly_step": drone_assembly_step,
		"drone_built": drone_built,
		"drone_auto_logistics": drone_auto_logistics,
		"active_drone_mission": active_drone_mission.duplicate(true),
		"completed_drone_missions_count": completed_drone_missions_count,
		"unlocked_departments": unlocked_departments.duplicate(),
		"active_incidents": active_incidents.duplicate(true),
		"owned_vehicles": owned_vehicles.duplicate(),
		"active_vehicle": active_vehicle
	}

func deserialize(data: Dictionary) -> void:
	reset()
	post_ogr_quest_started = bool(data.get("post_ogr_quest_started", false))
	research_credits = maxi(0, int(data.get("research_credits", 0)))

	var cm = data.get("carried_materials", {})
	if cm is Dictionary:
		for k in MATERIAL_ORDER:
			carried_materials[k] = maxi(0, int(cm.get(k, 0)))

	var ms = data.get("materials_storage", {})
	if ms is Dictionary:
		for k in MATERIAL_ORDER:
			materials_storage[k] = maxi(0, int(ms.get(k, 0)))

	var tr = data.get("tech_ranks", {})
	if tr is Dictionary:
		for b in TECH_BRANCH_ORDER:
			tech_ranks[b] = clampi(int(tr.get(b, 0)), 0, MAX_TECH_RANK)

	total_manual_extractions = maxi(0, int(data.get("total_manual_extractions", 0)))
	total_materials_delivered = maxi(0, int(data.get("total_materials_delivered", 0)))
	total_rc_earned = maxi(0, int(data.get("total_rc_earned", 0)))

	var raw_robots = data.get("robots", {})
	if raw_robots is Dictionary:
		for slot in [1, 2]:
			var s_key := str(slot)
			var r_data = raw_robots.get(slot, raw_robots.get(s_key, {}))
			if r_data is Dictionary and not r_data.is_empty():
				var st := _default_robot_state(slot)
				for rk in r_data:
					st[rk] = r_data[rk]
				robots[slot] = st

	conveyor_installed = bool(data.get("conveyor_installed", false))
	drone_assembly_step = clampi(int(data.get("drone_assembly_step", 0)), 0, DRONE_STEPS.size())
	drone_built = bool(data.get("drone_built", drone_assembly_step >= DRONE_STEPS.size()))
	drone_auto_logistics = bool(data.get("drone_auto_logistics", false))

	var adm = data.get("active_drone_mission", {})
	if adm is Dictionary:
		active_drone_mission = adm.duplicate(true)
	completed_drone_missions_count = maxi(0, int(data.get("completed_drone_missions_count", 0)))

	unlocked_departments.clear()
	for d in data.get("unlocked_departments", []):
		var ds := str(d)
		if DEPARTMENTS.has(ds) and not (ds in unlocked_departments):
			unlocked_departments.append(ds)

	active_incidents.clear()
	var inc = data.get("active_incidents", {})
	if inc is Dictionary:
		for ik in inc:
			if inc[ik] is Dictionary:
				active_incidents[str(ik)] = inc[ik].duplicate(true)

	owned_vehicles = ["foot"]
	for v in data.get("owned_vehicles", []):
		var vs := str(v)
		if VEHICLES.has(vs) and not (vs in owned_vehicles):
			owned_vehicles.append(vs)
	var av := str(data.get("active_vehicle", "foot"))
	active_vehicle = av if (av in owned_vehicles) else "foot"

	if is_instance_valid(EventBus):
		EventBus.materials_changed.emit()
		EventBus.tech_ops_updated.emit()
		EventBus.vehicle_changed.emit(active_vehicle)
