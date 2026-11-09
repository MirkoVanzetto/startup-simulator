class_name DavideInteractable
extends Interactable3D
## DavideInteractable - Dialogue initiator for Davide (Hardware technician at Elettronica TO)

func _ready() -> void:
	super._ready()
	prompt_message = "[E] Parla con Davide (Elettronica TO)"

func _on_interact(_player: Node) -> void:
	var c = ContractManager.get_contract("elettronica_to")
	var status = c.get("status", "locked")
	
	var lines: Array = []
	var choices: Array = []
	
	if not ContractManager.is_contract_completed("caffe_san_carlo"):
		lines = [
			"Ehilà collega! Benvenuto da Elettronica TO.",
			"Abbiamo server blade, schede di rete 10Gbps, moduli RAM e storage SAN per il tuo rack.",
			"Se vuoi commissioni sistemistiche serie, fatti conoscere nel quartiere: Elena al Caffè San Carlo cercava uno sviluppatore!"
		]
		choices = [
			{"text": "Grazie Davide, tornerò quando avrò più esperienza!", "action": "close"}
		]
	else:
		match status:
			"available":
				lines = [
					"Ciao! Elena mi ha fatto vedere il Web POS che hai installato al bar, roba da professionisti veri!",
					"Ascolta, qui da Elettronica TO abbiamo un grosso problema: il nostro gestionale interno gira su un vecchio PC locale che si blocca ogni due giorni.",
					"Dobbiamo migrare tutto su architettura Cloud con backup automatico sul tuo rack server, catalogo live e API protette.",
					"Il budget approvato dalla direzione è di € 1.850,00 netti, più uno sconto permanente del 20% su tutti i nostri componenti hardware!",
					"Ti andrebbe di occuparti dell'infrastruttura?"
				]
				choices = [
					{"text": "Affare fatto Davide! Configuro subito la migrazione e i container su WebForge.", "action": "accept_tech_shop"},
					{"text": "Quali sono i requisiti di affidabilità per il Cloud?", "action": "details_tech_shop"}
				]
			"in_progress":
				lines = [
					"Come va con la configurazione del backend e della sincronizzazione?",
					"Assicurati di includere il cluster database ridondato e il backup notturno sul tuo server rack.",
					"Apri WebForge sul tuo portatile per completare l'architettura!"
				]
				choices = [
					{"text": "Ci sono quasi Davide, compilo subito la build sul laptop!", "action": "close"}
				]
			"built":
				lines = [
					"Vedo dai log di sistema che l'architettura cloud ha superato gli stress test!",
					"Inviami la consegna tramite la tua email su TO-OS per saldare la fattura da € 1.850."
				]
				choices = [
					{"text": "Vado subito a inviare la release ufficiale!", "action": "close"}
				]
			"completed":
				lines = [
					"Sistema impeccabile! Zero downtime da quando siamo live e il catalogo si aggiorna in real-time!",
					"Hai guadagnato la stima di tutti i tecnici di Torino. I € 1.850 sono tuoi e il tuo server rack incassa ora la quota hosting fissa ogni giorno!",
					"Continua così e la tua startup diventerà presto una delle software house più rinomate del Piemonte!"
				]
				choices = [
					{"text": "Grazie mille Davide! Elettronica TO è il miglior fornitore della città.", "action": "close"}
				]
				
	EventBus.dialogue_started.emit("Davide (Tecnico Elettronica TO)", lines, choices)
