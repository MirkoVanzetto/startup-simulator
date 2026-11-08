class_name ContractGenerator
extends RefCounted
## ContractGenerator - Generates authentic procedural tech commissions in Torino

static var client_names = [
	"Elena Valente (Boutique Via Roma)",
	"Avv. Carlo Rinaldi (Studio Legale Crocetta)",
	"Dott.ssa Laura Boero (Farmacia San Salvario)",
	"Giuseppe Moretti (Ristorante Murazzi)",
	"Fabrizio Ferrero (Officina Mirafiori)",
	"Serena D'Amico (Agenzia Immobiliare Lingotto)",
	"Marco Bellini (Coworking OGR Torino)",
	"Davide Rossi (Pasticceria Baratti & Milano)"
]

static var contract_templates = [
	{
		"category": "Web Development",
		"titles": [
			"E-Commerce Catalogo Moda & Pelletteria",
			"Portale Vetrina di Rappresentanza con Prenotazioni",
			"Sito Web Dinamico con Gestione Offerte del Mese",
			"Piattaforma Vetrina per Servizi B2B di Quartiere"
		],
		"requirements": [
			"Layout Responsive per Mobile e Tablet",
			"Integrazione Pagamenti Digitali (Stripe/PayPal)",
			"Galleria Immagini Prodotti ad Alta Definizione",
			"Modulo Contatti Rapidi e Chat WhatsApp"
		],
		"budget_range": [850.0, 1450.0],
		"difficulty": 2,
		"deadline_days": 3
	},
	{
		"category": "Database & Gestionali",
		"titles": [
			"Normalizzazione e Pulizia Database Clienti",
			"Gestionale Scorte di Magazzino e Riordino Automatico",
			"Sistema di Fatturazione Elettronica e Registro IVA",
			"Dashboard Statistiche Vendite Trimestrali"
		],
		"requirements": [
			"Schema Relazionale SQL con Chiavi Univoche",
			"Esportazione Dati in Formato Excel e PDF",
			"Sistema di Controllo Accessi e Ruoli Amministrativi",
			"Backup Automatico Giornaliero su Cloud"
		],
		"budget_range": [950.0, 1600.0],
		"difficulty": 3,
		"deadline_days": 4
	},
	{
		"category": "Automazione & Bot",
		"titles": [
			"Bot Telegram Notifiche Ordini e Prenotazioni",
			"Automazione Flusso Richieste Preventivi via Email",
			"Scraper Monitoraggio Prezzi della Concorrenza Locale",
			"Sincronizzazione Automatica Ordini tra POS e Magazzino"
		],
		"requirements": [
			"Webhook Reattivo con Tempi di Risposta < 500ms",
			"Filtro Antispam e Rate Limiting delle Richieste",
			"Log Dettagliato delle Operazioni di Sincronizzazione",
			"Test di Stress con Invio di 50 Richieste Concorrenti"
		],
		"budget_range": [750.0, 1200.0],
		"difficulty": 2,
		"deadline_days": 2
	},
	{
		"category": "Cybersecurity & Rete",
		"titles": [
			"Audit di Sicurezza e Penetration Testing Rete Studio",
			"Configurazione Firewall Aziendale e VPN Dipendenti",
			"Rilevamento e Bonifica Vulnerabilità Server Web",
			"Policy Sicurezza Password e Autenticazione a Due Fattori"
		],
		"requirements": [
			"Scansione Porte Aperte e Servizi Esposti a Rischi",
			"Certificato SSL/TLS A+ su Tutti i Domini",
			"Relazione Tecnica sulle Vulnerabilità Sanate",
			"Configurazione Regole Antintrusione Fail2ban"
		],
		"budget_range": [1100.0, 1850.0],
		"difficulty": 4,
		"deadline_days": 5
	}
]

static func generate_random_contract(seed_index: int = 0) -> Dictionary:
	var rng = RandomNumberGenerator.new()
	if seed_index != 0:
		rng.seed = seed_index
	else:
		rng.randomize()
		
	var template = contract_templates[rng.randi_range(0, contract_templates.size() - 1)]
	var client = client_names[rng.randi_range(0, client_names.size() - 1)]
	var title = template["titles"][rng.randi_range(0, template["titles"].size() - 1)]
	var budget = round(rng.randf_range(template["budget_range"][0], template["budget_range"][1]) / 10.0) * 10.0
	var rep_reward = int(budget / 50.0) + rng.randi_range(5, 12)
	var contract_id = "contract_" + str(Time.get_ticks_msec()) + "_" + str(rng.randi_range(100, 999))
	
	return {
		"id": contract_id,
		"title": title,
		"client": client,
		"category": template["category"],
		"budget": budget,
		"reputation_reward": rep_reward,
		"difficulty": template["difficulty"],
		"deadline_days": template["deadline_days"],
		"status": "available",
		"objective_text": "Sviluppa e consegna il progetto '" + title + "' per " + client.split("(")[0].strip_edges() + ".",
		"requirements": template["requirements"].duplicate()
	}

static func generate_initial_marketplace_pool(count: int = 4) -> Array[Dictionary]:
	var pool: Array[Dictionary] = []
	for i in range(count):
		pool.append(generate_random_contract(i + 1))
	return pool
