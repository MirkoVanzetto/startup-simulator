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
		"budget_range": [920.0, 1480.0],
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
		"budget_range": [1050.0, 1620.0],
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
		"budget_range": [1100.0, 1680.0],
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
		"budget_range": [860.0, 1340.0],
		"difficulty": 2,
		"deadline_days": 3
	}
]

static var cyber_gig_variants = [
	{
		"title": "Audit Firewall Perimetrale & Segmentazione DMZ",
		"budget_range": [950.0, 1450.0],
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
		"budget_range": [1250.0, 1850.0],
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
		"budget": 380.0,
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
		"budget": 980.0,
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
		"budget": 860.0,
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
		"budget": 590.0,
		"difficulty": 2,
		"deadline_days": 4,
		"requirements": [
			"Acquista 1x Router Wi-Fi 6 + 1x Firewall Hardware UTM",
			"Installa pacchetto completo da Freelance Hub"
		]
	}
]

static var _seq_counter: int = 0

static func generate_random_contract(seed_index: int = 0, budget_mult: float = 1.0) -> Dictionary:
	var rng = RandomNumberGenerator.new()
	if seed_index != 0:
		rng.seed = seed_index
	else:
		rng.randomize()

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

static func generate_initial_marketplace_pool(count: int = 2, budget_mult: float = 1.0) -> Array[Dictionary]:
	var pool: Array[Dictionary] = []
	for i in range(count):
		pool.append(generate_random_contract(i + 1, budget_mult))
	return pool
