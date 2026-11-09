class_name ElenaInteractable
extends Interactable3D
## ElenaInteractable - Dialogue initiator for Elena (Barista & Manager of Caffè San Carlo)

func _ready() -> void:
	super._ready()
	prompt_message = "[E] Parla con Elena (Barista Caffè San Carlo)"

func _on_interact(_player: Node) -> void:
	var c = ContractManager.get_contract("caffe_san_carlo")
	var status = c.get("status", "locked")
	
	var lines: Array = []
	var choices: Array = []
	
	if not ContractManager.is_contract_completed("pizzeria_da_mario"):
		lines = [
			"Benvenuto al Caffè San Carlo! Accomodati pure al bancone o a uno dei nostri tavoli storici.",
			"Se cerchi Mario della Pizzeria, la sua bottega è proprio in fondo a via Po dall'altro lato!",
			"Torna a trovarmi quando avrai avviato la tua agenzia informatica, avrei proprio bisogno di una mano con la cassa!"
		]
		choices = [
			{"text": "Grazie Elena, vado prima a completare il lavoro per Mario!", "action": "close"}
		]
	else:
		match status:
			"available":
				lines = [
					"Ciao! Ho sentito Mario che tesseva le tue lodi per quel sito web splendido che gli hai realizzato!",
					"Vedi, qui al Caffè San Carlo la mattina tra marocchini, bicerin e croissant torinesi c'è il caos totale al bancone.",
					"Il nostro vecchio registratore di cassa è lentissimo. Vorrei un sistema touch Web POS moderno:",
					"Menu veloce, gestione comande tavoli e pagamenti digitali contactless integrati.",
					"Il mio budget per questo lavoro è di € 1.250,00 netti. Inoltre, possiamo ospitare il sito sui tuoi server!"
				]
				choices = [
					{"text": "Accetto con piacere Elena! Torno in studio a programmare il tuo Web POS.", "action": "accept_cafe"},
					{"text": "Cosa ti serve in particolare nel sistema di cassa?", "action": "details_cafe"}
				]
			"in_progress":
				lines = [
					"Come procede lo sviluppo del POS?",
					"Ricordati: interfaccia touch rapida, categorie per caffetteria e aperitivi, e prenotazione tavoli.",
					"Usa WebForge sul laptop nel tuo studio per assemblarlo!"
				]
				choices = [
					{"text": "Ci sto lavorando proprio adesso, torno subito al laptop!", "action": "close"}
				]
			"built":
				lines = [
					"Fantastico, mi è arrivata la notifica che la build del Web POS è pronta!",
					"Mandami la consegna ufficiale tramite l'app Posta sul tuo laptop per riscuotere il pagamento."
				]
				choices = [
					{"text": "Vado subito a inviarti il rilascio ufficiale!", "action": "close"}
				]
			"completed":
				lines = [
					"Il Web POS è una meraviglia! I tempi di attesa per i clienti si sono dimezzati!",
					"I € 1.250 sono tutti meritati, e continueremo a pagare l'abbonamento mensile per il cloud hosting sul tuo rack server!",
					"Se hai bisogno di nuovo hardware o server blade, Davide di 'Elettronica TO' proprio qui di fronte cercava un sistemista!"
				]
				choices = [
					{"text": "Grazie mille Elena! Un vero piacere collaborare con il Caffè San Carlo.", "action": "close"}
				]
				
	EventBus.dialogue_started.emit("Elena (Barista Caffè San Carlo)", lines, choices)
