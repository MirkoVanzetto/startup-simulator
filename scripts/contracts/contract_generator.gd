class_name ContractGenerator
extends RefCounted
## ContractGenerator - Generates authentic procedural tech commissions in Torino

static var client_names = [
	"Elena Valente (Boutique Via Roma)",
	"Avv. Carlo Rinaldi (Studio Legale Crocetta)",
	"Dott.ssa Laura Boero (Farmacia San Salvario)",
	"Giuseppe Moretti (Ristorante Murazzi)",
	"Fabrizio Ferrero (Torneria Mirafiori)",
	"Serena D'Amico (Agenzia Immobiliare Lingotto)",
	"Marco Bellini (Coworking OGR Torino)",
	"Davide Rossi (Pasticceria Baratti & Milano)"
]

static var web_gig_variants = [
	{
		"category": "Web Development",
		"title": "E-Commerce Catalogo & Prenotazioni B2B",
		"brief": "Vogliamo un portale elegante ma scattante: menu catalogo prodotti chiaro, prenotazione appuntamento rapida e stile caldo o minimal.",
		"preferred_tags": ["E-Commerce", "Booking"],
		"preferred_palette": "monochrome",
		"requirements": [
			"Layout Responsive Desktop & Mobile",
			"Modulo Prenotazione o Carrello Online",
			"Ottimizzazione Bundle CSS/JS e Immagini WebP"
		],
		"budget_range": [440.0, 690.0],
		"difficulty": 2,
		"deadline_days": 3
	},
	{
		"category": "Web Development",
		"title": "Portale Istituzionale & Booking Studio Tecnico",
		"brief": "Il cliente cerca credibilità tecnologica, sezione servizi tecnici dettagliata e chiamata rapida a consulenza su dispositivo mobile.",
		"preferred_tags": ["Tech", "Booking"],
		"preferred_palette": "amber",
		"requirements": [
			"Intestazione Istituzionale Professionale",
			"Griglia Servizi & Tabella Capacità",
			"Pulsante Richiesta Preventivo Rapido"
		],
		"budget_range": [520.0, 780.0],
		"difficulty": 3,
		"deadline_days": 4
	},
	{
		"category": "Database & Gestionali",
		"title": "Dashboard Gestionale Cloud & Magazzino SKU",
		"brief": "Serve un'interfaccia tecnica scura o pulita con stato cluster live, tabelle inventario e console esportazione dati sicura.",
		"preferred_tags": ["Tech", "E-Commerce"],
		"preferred_palette": "cyan",
		"requirements": [
			"Schema Dati & Tabella Inventario Live",
			"Controllo Accessi & Export Report PDF",
			"Pipeline Ottimizzazione & Meta SEO"
		],
		"budget_range": [560.0, 820.0],
		"difficulty": 3,
		"deadline_days": 4
	},
	{
		"category": "Automazione & Bot",
		"title": "Web Console Ordini Rapidi & Notifiche Bot",
		"brief": "Velocità assoluta al banco e su smartphone: poche frizioni, comande immediate e stato webhook in tempo reale.",
		"preferred_tags": ["Speed", "Booking"],
		"preferred_palette": "emerald",
		"requirements": [
			"Flusso Ordini Rapido < 500ms",
			"Pagamento Digitale & Satispay Webhook",
			"Bundle Compresso senza Asset Pesanti"
		],
		"budget_range": [420.0, 640.0],
		"difficulty": 2,
		"deadline_days": 3
	}
]

static var cyber_gig_variants = [
	{
		"title": "Audit Firewall Perimetrale & Segmentazione DMZ",
		"budget_range": [480.0, 740.0],
		"difficulty": 3,
		"deadline_days": 4,
		"checkpoints": {
			Vector2i(0, 0): 1,
			Vector2i(0, 4): 2,
			Vector2i(2, 2): 3,
			Vector2i(4, 3): 4,
			Vector2i(4, 0): 5
		},
		"requirements": [
			"Instradamento Zero-Trust su NetShield 5x5",
			"Separazione DMZ Server e LAN Uffici",
			"Regole iptables e audit porte chiuse"
		]
	},
	{
		"title": "Hardening VPN & Tunneling Crittografato PMI",
		"budget_range": [620.0, 890.0],
		"difficulty": 4,
		"deadline_days": 5,
		"checkpoints": {
			Vector2i(0, 1): 1,
			Vector2i(0, 4): 2,
			Vector2i(3, 4): 3,
			Vector2i(3, 1): 4,
			Vector2i(1, 1): 5,
			Vector2i(1, 3): 6
		},
		"requirements": [
			"Tunnel IPSec Multi-Nodo senza Conflitti",
			"Verifica Continuità Circuito 1 -> 6",
			"Certificato TLS 1.3 e Politiche Fail2ban"
		]
	}
]

static var hardware_gig_variants = [
	{
		"title": "Installazione Rete Wi-Fi 6 Mesh & Access Point",
		"required_hardware": {"hw_wifi_router": 1},
		"budget": 310.0,
		"difficulty": 1,
		"deadline_days": 3,
		"requirements": [
			"Acquista 1x Router Wi-Fi 6 Dual-Band Mesh (Elettronica TO / TorinoHardware)",
			"Installa e collauda da Freelance Hub"
		]
	},
	{
		"title": "Fornitura & Setup 2 Workstation CAD/Ufficio",
		"required_hardware": {"hw_workstation_pc": 2},
		"budget": 860.0,
		"difficulty": 2,
		"deadline_days": 4,
		"requirements": [
			"Acquista 2x PC Workstation CAD & Ufficio",
			"Consegna e configura tramite Freelance Hub"
		]
	},
	{
		"title": "Installazione Server Tower Xeon RAID-10 Locale",
		"required_hardware": {"hw_server_tower": 1},
		"budget": 740.0,
		"difficulty": 3,
		"deadline_days": 4,
		"requirements": [
			"Acquista 1x Server Tower Xeon 8-Core RAID-10",
			"Installa e consegna tramite Freelance Hub"
		]
	},
	{
		"title": "Kit Sicurezza Rete: Router Wi-Fi + Firewall UTM",
		"required_hardware": {"hw_wifi_router": 1, "hw_firewall_appliance": 1},
		"budget": 490.0,
		"difficulty": 2,
		"deadline_days": 4,
		"requirements": [
			"Acquista 1x Router Wi-Fi 6 + 1x Firewall Hardware UTM",
			"Installa pacchetto completo da Freelance Hub"
		]
	}
]

static var specialty_gig_variants: Array[Dictionary] = [
	{
		"knowledge_track": "web_architecture",
		"category": "Web Architecture & UX",
		"title": "Portale Configuratore 3D & Design System Showroom",
		"brief": "Architettura frontend ad alte prestazioni con configuratore catalogo interattivo, prenotazione appuntamento e stile editoriale pulito.",
		"execution_type": "webforge",
		"preferred_tags": ["E-Commerce", "Tech"],
		"preferred_palette": "monochrome",
		"requirements": [
			"Design System Atomico & Bento Grid",
			"Configuratore Prodotto & Prenotazione Live",
			"Bundle Compresso + WebP + Meta SEO"
		],
		"budget_range": [980.0, 1380.0],
		"difficulty": 4,
		"star_reward": 2,
		"deadline_days": 4
	},
	{
		"knowledge_track": "web_architecture",
		"category": "Web Architecture & UX",
		"title": "Piattaforma Ticketing & Booking Eventi Torino",
		"brief": "Portali ad alta concorrenza per musei e rassegne torinesi: caricamento istantaneo, checkout prenotazioni e alta accessibilità.",
		"execution_type": "webforge",
		"preferred_tags": ["Booking", "Speed"],
		"preferred_palette": "amber",
		"requirements": [
			"Layout Split / Responsive Zero-Latency",
			"Flusso Ticketing & QR Pass",
			"Lighthouse A11y >= 90 & Asset < 380KB"
		],
		"budget_range": [1080.0, 1480.0],
		"difficulty": 4,
		"star_reward": 2,
		"deadline_days": 4
	},
	{
		"knowledge_track": "cloud_devops",
		"category": "Cloud & DevOps",
		"title": "Migrazione Microservizi Cloud & Disaster Recovery PMI",
		"brief": "Console cloud ad alta affidabilità per monitorare replica multi-nodo, telemetria container e deployment zero-downtime.",
		"execution_type": "webforge",
		"preferred_tags": ["Tech", "Speed"],
		"preferred_palette": "cyan",
		"requirements": [
			"Dashboard Telemetria Microservizi",
			"Backup Multi-Zone & SLA Monitor",
			"Pipeline Build & Asset Ottimizzati"
		],
		"budget_range": [1120.0, 1540.0],
		"difficulty": 4,
		"star_reward": 2,
		"deadline_days": 5
	},
	{
		"knowledge_track": "cloud_devops",
		"category": "Cloud & Infrastruttura",
		"title": "Cluster Ibrido: 2x Server Xeon + Firewall UTM Pro",
		"brief": "Fornitura completa di infrastruttura ridondata locale + gateway protetto per azienda manifatturiera torinese.",
		"execution_type": "hardware",
		"required_hardware": {"hw_server_tower": 2, "hw_firewall_appliance": 1},
		"requirements": [
			"Fornitura 2x Server Tower Xeon RAID-10",
			"Fornitura 1x Firewall Hardware UTM",
			"Consegna & Collaudo da Freelance Hub"
		],
		"budget": 1440.0,
		"difficulty": 4,
		"star_reward": 2,
		"deadline_days": 5
	},
	{
		"knowledge_track": "cyber_governance",
		"category": "Cybersecurity & NIS2",
		"title": "Audit Compliance NIS2 & Segmentazione Zero-Trust",
		"brief": "Adeguamento normativo NIS2 con instradamento segmentato a 6 nodi su NetShield Cyber e isolamento sottoreti critiche.",
		"execution_type": "netshield",
		"checkpoints": {
			Vector2i(0, 0): 1,
			Vector2i(0, 4): 2,
			Vector2i(3, 4): 3,
			Vector2i(3, 1): 4,
			Vector2i(1, 1): 5,
			Vector2i(4, 3): 6
		},
		"requirements": [
			"Circuito NetShield 6 Nodi NIS2 Zero-Trust",
			"Isolamento Reparti Produzione & Amministrazione",
			"Report Audit Porte & Regole Firewall"
		],
		"budget_range": [1180.0, 1620.0],
		"difficulty": 5,
		"star_reward": 2,
		"deadline_days": 5
	},
	{
		"knowledge_track": "cyber_governance",
		"category": "Cybersecurity & NIS2",
		"title": "Rete Crittografata Multi-Sede & SOC Monitoring",
		"brief": "Interconnessione cifrata tra stabilimento e uffici direzionali con doppio livello IPSec su NetShield Cyber.",
		"execution_type": "netshield",
		"checkpoints": {
			Vector2i(1, 0): 1,
			Vector2i(1, 3): 2,
			Vector2i(4, 3): 3,
			Vector2i(4, 1): 4,
			Vector2i(2, 1): 5,
			Vector2i(0, 4): 6
		},
		"requirements": [
			"Dorsale NetShield 6 Nodi Ridondata",
			"Tunnel VPN Multi-Sede TLS 1.3",
			"Protezione Anti-Intrusione Perimetrale"
		],
		"budget_range": [1080.0, 1460.0],
		"difficulty": 4,
		"star_reward": 2,
		"deadline_days": 4
	},
	{
		"knowledge_track": "ai_automation",
		"category": "AI & Automazione Industriale",
		"title": "Dashboard AI Vision & Telemetria Robotica Linea Auto",
		"brief": "Interfaccia industriale intelligente con controllo qualità visione AI, alert predittivi e integrazione ordini automatici.",
		"execution_type": "webforge",
		"preferred_tags": ["Tech", "E-Commerce"],
		"preferred_palette": "emerald",
		"requirements": [
			"Console AI Predittiva & Sensoristica",
			"Integrazione Webhook Automazione Magazzino",
			"Ottimizzazione Bundle & Responsive Pro"
		],
		"budget_range": [1280.0, 1760.0],
		"difficulty": 5,
		"star_reward": 3,
		"deadline_days": 5
	},
	{
		"knowledge_track": "ai_automation",
		"category": "AI & Automazione Industriale",
		"title": "Edge AI Node: Server Xeon + 2x Workstation + Firewall",
		"brief": "Installazione nodo di calcolo locale per addestramento modelli industriali e protezione dati on-premise.",
		"execution_type": "hardware",
		"required_hardware": {"hw_server_tower": 1, "hw_workstation_pc": 2, "hw_firewall_appliance": 1},
		"requirements": [
			"1x Server Tower Xeon RAID-10 + 2x PC Workstation",
			"1x Firewall Hardware UTM Perimetrale",
			"Setup & Consegna da Freelance Hub"
		],
		"budget": 1590.0,
		"difficulty": 5,
		"star_reward": 3,
		"deadline_days": 5
	}
]

static var _seq_counter: int = 0

static func generate_specialty_contract(track_id: String, seed_index: int = 0, budget_mult: float = 1.0) -> Dictionary:
	var rng = RandomNumberGenerator.new()
	if seed_index != 0:
		rng.seed = seed_index
	else:
		rng.randomize()

	var matching: Array[Dictionary] = []
	for sv in specialty_gig_variants:
		if str(sv.get("knowledge_track", "")) == track_id:
			matching.append(sv)
	if matching.is_empty():
		return generate_random_contract(seed_index, budget_mult)

	_seq_counter += 1
	var spec: Dictionary = matching[rng.randi_range(0, matching.size() - 1)]
	var client: String = client_names[rng.randi_range(0, client_names.size() - 1)]
	var short_client: String = client.split("(")[0].strip_edges()
	var contract_id: String = "contract_rd_" + str(Time.get_ticks_msec()) + "_" + str(_seq_counter) + "_" + str(rng.randi_range(100, 999))
	var etype := str(spec.get("execution_type", "webforge"))

	var raw_budget: float = 0.0
	if spec.has("budget_range"):
		raw_budget = rng.randf_range(float(spec["budget_range"][0]), float(spec["budget_range"][1])) * budget_mult
	else:
		raw_budget = float(spec.get("budget", 1200.0)) * budget_mult
	var budget: float = round(raw_budget / 10.0) * 10.0
	var rep_reward: int = int(budget / 45.0) + rng.randi_range(10, 18)

	var gig := {
		"id": contract_id,
		"title": str(spec["title"]),
		"client": client,
		"category": str(spec["category"]),
		"execution_type": etype,
		"knowledge_track": track_id,
		"is_knowledge_specialty": true,
		"budget": budget,
		"reputation_reward": rep_reward,
		"star_reward": int(spec.get("star_reward", 2)),
		"difficulty": int(spec.get("difficulty", 4)),
		"deadline_days": int(spec.get("deadline_days", 4)),
		"status": "available",
		"requirements": (spec.get("requirements", []) as Array).duplicate()
	}
	if etype == "webforge":
		gig["brief"] = str(spec.get("brief", ""))
		gig["preferred_tags"] = (spec.get("preferred_tags", ["Tech"]) as Array).duplicate()
		gig["preferred_palette"] = str(spec.get("preferred_palette", "cyan"))
		gig["objective_text"] = "Progetto R&D Avanzato: sviluppa '%s' su WebForge per %s." % [gig["title"], short_client]
	elif etype == "netshield":
		gig["netshield_checkpoints"] = (spec.get("checkpoints", {}) as Dictionary).duplicate()
		gig["objective_text"] = "Progetto R&D Cyber: configura la matrice NetShield per %s." % short_client
	else:
		gig["required_hardware"] = (spec.get("required_hardware", {}) as Dictionary).duplicate()
		gig["objective_text"] = "Progetto R&D Infrastruttura: procurati e installa l'hardware per %s." % short_client
	return gig

static func generate_random_contract(seed_index: int = 0, budget_mult: float = 1.0, unlocked_specialties: Array = []) -> Dictionary:
	var rng = RandomNumberGenerator.new()
	if seed_index != 0:
		rng.seed = seed_index
	else:
		rng.randomize()

	if not unlocked_specialties.is_empty():
		var valid_tracks: Array[String] = []
		for t in unlocked_specialties:
			var ts := str(t)
			for sv in specialty_gig_variants:
				if str(sv.get("knowledge_track", "")) == ts:
					if not (ts in valid_tracks):
						valid_tracks.append(ts)
					break
		if not valid_tracks.is_empty() and rng.randi_range(0, 99) < 48:
			var picked_track := valid_tracks[rng.randi_range(0, valid_tracks.size() - 1)]
			var next_seed := (seed_index + 7919) if seed_index != 0 else 0
			return generate_specialty_contract(picked_track, next_seed, budget_mult)

	_seq_counter += 1
	var client: String = client_names[rng.randi_range(0, client_names.size() - 1)]
	var short_client: String = client.split("(")[0].strip_edges()
	var roll: int = rng.randi_range(0, 99)
	var contract_id: String = "contract_" + str(Time.get_ticks_msec()) + "_" + str(_seq_counter) + "_" + str(rng.randi_range(100, 999))

	if roll < 32:
		# Hardware & Infrastruttura (richiede componenti acquistabili da Elettronica TO!)
		var hw: Dictionary = hardware_gig_variants[rng.randi_range(0, hardware_gig_variants.size() - 1)]
		var budget: float = round((float(hw["budget"]) * budget_mult) / 10.0) * 10.0
		var rep_reward: int = int(budget / 48.0) + rng.randi_range(6, 12)
		return {
			"id": contract_id,
			"title": hw["title"],
			"client": client,
			"category": "Hardware & Infrastruttura",
			"execution_type": "hardware",
			"required_hardware": hw["required_hardware"].duplicate(),
			"budget": budget,
			"reputation_reward": rep_reward,
			"difficulty": hw["difficulty"],
			"deadline_days": hw["deadline_days"],
			"status": "available",
			"objective_text": "Procurati l'hardware richiesto da Elettronica TO / TorinoHardware e consegnalo a %s." % short_client,
			"requirements": hw["requirements"].duplicate()
		}
	elif roll < 58:
		# Cybersecurity & Rete -> NetShield routing!
		var cyb: Dictionary = cyber_gig_variants[rng.randi_range(0, cyber_gig_variants.size() - 1)]
		var raw_budget: float = rng.randf_range(cyb["budget_range"][0], cyb["budget_range"][1]) * budget_mult
		var budget: float = round(raw_budget / 10.0) * 10.0
		var rep_reward: int = int(budget / 50.0) + rng.randi_range(8, 14)
		return {
			"id": contract_id,
			"title": cyb["title"],
			"client": client,
			"category": "Cybersecurity & Rete",
			"execution_type": "netshield",
			"netshield_checkpoints": cyb["checkpoints"].duplicate(),
			"budget": budget,
			"reputation_reward": rep_reward,
			"difficulty": cyb["difficulty"],
			"deadline_days": cyb["deadline_days"],
			"status": "available",
			"objective_text": "Configura i nodi su NetShield Cyber per mettere in sicurezza la rete di %s." % short_client,
			"requirements": cyb["requirements"].duplicate()
		}
	else:
		# Web / Cloud / Bot -> WebForge!
		var wv: Dictionary = web_gig_variants[rng.randi_range(0, web_gig_variants.size() - 1)]
		var raw_budget: float = rng.randf_range(wv["budget_range"][0], wv["budget_range"][1]) * budget_mult
		var budget: float = round(raw_budget / 10.0) * 10.0
		var rep_reward: int = int(budget / 50.0) + rng.randi_range(6, 12)
		return {
			"id": contract_id,
			"title": wv["title"],
			"client": client,
			"category": wv["category"],
			"execution_type": "webforge",
			"brief": wv["brief"],
			"preferred_tags": wv["preferred_tags"].duplicate(),
			"preferred_palette": wv["preferred_palette"],
			"budget": budget,
			"reputation_reward": rep_reward,
			"difficulty": wv["difficulty"],
			"deadline_days": wv["deadline_days"],
			"status": "available",
			"objective_text": "Sviluppa e consegna '%s' su WebForge per %s." % [wv["title"], short_client],
			"requirements": wv["requirements"].duplicate()
		}

static func generate_initial_marketplace_pool(count: int = 2, budget_mult: float = 1.0, unlocked_specialties: Array = []) -> Array[Dictionary]:
	var pool: Array[Dictionary] = []
	for i in range(count):
		pool.append(generate_random_contract(i + 1, budget_mult, unlocked_specialties))
	return pool

const ENTERPRISE_CONTRACTS: Array[Dictionary] = [
	{
		"id": "ogr_fiat_telemetria",
		"tier": 1,
		"title": "Portale Telemetria Flotta EV Torino",
		"client": "Lingotto Mobility SpA (OGR Bay #1)",
		"category": "OGR Enterprise · Web & Cloud",
		"execution_type": "webforge",
		"brief": "Console enterprise per monitorare 400 navette elettriche a Torino in tempo reale: Bento Grid ad alto contrasto Cyan e latenza minima.",
		"preferred_tags": ["Tech", "Speed"],
		"preferred_palette": "cyan",
		"budget": 2400.0,
		"reputation_reward": 40,
		"star_reward": 3,
		"difficulty": 4,
		"deadline_days": 6,
		"requirements": [
			"Dashboard Bento Grid Real-Time Flotta",
			"OTTIMIZZAZIONE Bundle + WebP + Meta",
			"Console Deploy Docker & TLS 1.3"
		]
	},
	{
		"id": "ogr_musei_zero_trust",
		"tier": 1,
		"title": "Rete Zero-Trust & Firewall Musei Reali",
		"client": "Fondazione Cultura Piemonte (OGR Hub)",
		"category": "OGR Enterprise · Cybersecurity",
		"execution_type": "netshield",
		"checkpoints": {
			Vector2i(0, 0): 1,
			Vector2i(0, 4): 2,
			Vector2i(2, 4): 3,
			Vector2i(2, 1): 4,
			Vector2i(4, 1): 5,
			Vector2i(4, 4): 6
		},
		"budget": 2250.0,
		"reputation_reward": 38,
		"star_reward": 3,
		"difficulty": 4,
		"deadline_days": 5,
		"requirements": [
			"Matrice NetShield 6 Nodi Continua",
			"Segmentazione Biglietteria & Archivi",
			"Auditing IPSec & Ridondanza"
		]
	},
	{
		"id": "ogr_pininfarina_cluster",
		"tier": 2,
		"title": "Forno Rack & 4 Workstation CAD Stile",
		"client": "Centro Stile Prototipi (OGR Lab #2)",
		"category": "OGR Enterprise · Infrastruttura",
		"execution_type": "hardware",
		"required_hardware": {"hw_server_tower": 2, "hw_workstation_pc": 4},
		"budget": 4200.0,
		"reputation_reward": 55,
		"star_reward": 4,
		"difficulty": 4,
		"deadline_days": 6,
		"requirements": [
			"Fornitura 2x Server Tower Xeon RAID-10",
			"Fornitura 4x Workstation CAD & Ufficio",
			"Collaudo da OGR Enterprise / Freelance Hub"
		]
	},
	{
		"id": "ogr_aerospace_twin",
		"tier": 3,
		"title": "Digital Twin Stabilimento Aerospazio",
		"client": "Alenia Orbital Labs (OGR Incubator)",
		"category": "OGR Enterprise · Aerospace",
		"execution_type": "webforge",
		"brief": "Portale critico missione con catalogo sensori orbitali, prenotazione collaudi camera bianca e palette Acciaio & Ambra Industriale.",
		"preferred_tags": ["Tech", "Booking"],
		"preferred_palette": "amber",
		"budget": 5200.0,
		"reputation_reward": 70,
		"star_reward": 5,
		"difficulty": 5,
		"deadline_days": 7,
		"requirements": [
			"Architettura Bento & Sensor Grid",
			"Auditorium Prenotazione Test Bench",
			"Zero-Blocking Bundle + SEO Certificato"
		]
	},
	{
		"id": "ogr_intesa_core",
		"tier": 4,
		"title": "Core Banking Firewall & Redundancy Ring",
		"client": "Piemonte Fintech Tower (OGR Vault)",
		"category": "OGR Enterprise · FinTech Elite",
		"execution_type": "netshield",
		"checkpoints": {
			Vector2i(1, 0): 1,
			Vector2i(4, 0): 2,
			Vector2i(4, 3): 3,
			Vector2i(2, 3): 4,
			Vector2i(2, 1): 5,
			Vector2i(0, 4): 6
		},
		"budget": 6800.0,
		"reputation_reward": 90,
		"star_reward": 5,
		"difficulty": 5,
		"deadline_days": 7,
		"requirements": [
			"Topologia Ring Multi-Hop FinTech",
			"Firewall UTM Zero-Loss Latency",
			"Certificazione Tier IV OGR Elite"
		]
	}
]

static func build_enterprise_pool(max_tier: int, completed_ids: Array[String], active_ids: Array, budget_mult: float = 1.0) -> Array[Dictionary]:
	var pool: Array[Dictionary] = []
	for raw in ENTERPRISE_CONTRACTS:
		var cid := str(raw.get("id", ""))
		if int(raw.get("tier", 1)) > max_tier:
			continue
		if cid in completed_ids or cid in active_ids:
			continue
		pool.append(_clone_enterprise_entry(raw, budget_mult))
	if pool.is_empty():
		# Bandi ricorrenti Enterprise se tutti quelli sbloccati sono già stati completati
		var idx := 0
		for raw in ENTERPRISE_CONTRACTS:
			if int(raw.get("tier", 1)) <= max_tier:
				idx += 1
				var copy := _clone_enterprise_entry(raw, budget_mult)
				copy["id"] = "%s_r_%d_%d" % [str(raw["id"]), Time.get_ticks_msec() % 10000, idx]
				pool.append(copy)
	return pool

static func _clone_enterprise_entry(raw: Dictionary, budget_mult: float) -> Dictionary:
	var c := raw.duplicate(true)
	c["status"] = "available"
	c["is_enterprise"] = true
	c["budget"] = round((float(raw.get("budget", 2000.0)) * budget_mult) / 50.0) * 50.0
	c["objective_text"] = "Appalto Enterprise OGR per %s." % str(raw.get("client", "Corporate"))
	return c

