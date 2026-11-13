class_name BelliniInteractable
extends Interactable3D
## BelliniInteractable - Dialogue initiator for Ing. Gianluca Bellini at Officina Bellini (Borgo Valdocco).

func _ready() -> void:
	super._ready()
	prompt_message = "[E] Parla con Ing. Bellini (Officina)"

func _on_interact(_player: Node) -> void:
	FameManager.register_talk("bellini")
	var fac := ContractManager.get_factory_progress_summary()
	var lines: Array = []
	var choices: Array = []

	if not bool(fac["accepted"]):
		lines = [
			"Benvenuto all'Officina Meccanica Bellini qui a Borgo Valdocco!",
			"Stiamo ampliando il reparto CNC e dobbiamo modernizzare da zero l'intera infrastruttura IT dell'azienda.",
			"Servono: copertura Wi-Fi 6 & VLAN sicura, un Portale Catalogo WebForge B2B, 1 Server Tower Xeon RAID e 2 Workstation PC CAD.",
			"Prima di ordinare i materiali da Elettronica TO, fai un sopralluogo nelle 4 zone chiave dell'officina. Valore totale oltre € 3.080 + € 1.500 di premio finale!"
		]
		choices = [
			{"text": "Accetto la maxi-commessa! Inizio il sopralluogo delle 4 zone.", "action": "accept_factory_bellini"},
			{"text": "Quali sono i 4 pilastri e le zone da perlustrare?", "action": "details_factory_bellini"},
			{"text": "Passo più tardi, Ing. Bellini.", "action": "close"}
		]
	elif not bool(fac["completed"]):
		var s_txt := "Sopralluogo Officina: %d/4 zone (%s)" % [
			int(fac["scouted_count"]),
			"COMPLETO ✔" if bool(fac["all_scouted"]) else "cerca i beacon gialli in fabbrica"
		]
		var w_txt := "Wi-Fi 6 & VLAN: " + (
			"ATTIVO ✔" if bool(fac["wifi_done"]) else (
				"Router montato — configura VLAN su NetShield ⚡" if bool(fac["wifi_mounted"]) else "Monta 1x Router Wi-Fi 6 sul quadro"
			)
		)
		var web_txt := "Portale WebForge: " + ("ONLINE ✔" if bool(fac["web_done"]) else "Sviluppa & consegna su TO-OS")
		var srv_txt := "Server Tower Xeon: " + ("ATTIVO ✔" if bool(fac["server_done"]) else "Installa 1x Server Tower nel magazzino")
		var pc_txt := "2x Workstation CAD: " + ("OPERATIVE ✔" if bool(fac["pcs_done"]) else "Installa 2x PC Workstation in ufficio")

		lines = [
			"Avanzamento maxi-appalto Officina Bellini (%d/4 pilastri completati):" % int(fac["pillars_done"]),
			"• %s\n• %s\n• %s\n• %s\n• %s" % [s_txt, w_txt, web_txt, srv_txt, pc_txt]
		]
		choices = [
			{"text": "Acquista componenti da Elettronica TO (Router, Server, PC)", "action": "open_hardware_shop"},
			{"text": "Perfetto, continuo i lavori in officina!", "action": "close"}
		]
	else:
		lines = [
			"Complimenti! L'officina viaggia al massimo: Wi-Fi 6 stabile in reparto, Server Xeon operativo e portale B2B già pieno di richieste CAD!",
			"Tutti qui a Borgo Valdocco conoscono ormai la tua startup!"
		]
		choices = [
			{"text": "Grazie Ing. Bellini, è stato un gran progetto!", "action": "close"}
		]

	EventBus.dialogue_started.emit("Ing. Gianluca Bellini (Officina Valdocco)", lines, choices)
