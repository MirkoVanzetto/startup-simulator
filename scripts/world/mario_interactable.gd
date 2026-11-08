class_name MarioInteractable
extends Interactable3D
## MarioInteractable - Dialogue initiator for Mario (Pizzeria owner)

var anim_player: AnimationPlayer = null

func _ready() -> void:
	super._ready()
	prompt_message = "[E] Parla con Mario (Pizzaiolo)"
	_find_anim_player()
	if anim_player and anim_player.has_animation("Idle"):
		anim_player.play("Idle")

func _find_anim_player() -> void:
	if has_node("Model"):
		anim_player = $Model.find_child("AnimationPlayer", true, false)

func _on_interact(_player: Node) -> void:
	if anim_player and anim_player.has_animation("Interact"):
		anim_player.play("Interact")
		
	var tut = ContractManager.get_tutorial_contract()
	var status = tut.get("status", "available")
	
	var lines: Array = []
	var choices: Array = []
	
	match status:
		"available":
			lines = [
				"Ciao ragazzo! Ti manda l'annuncio su Freelance Hub? Finalmente un giovane in gamba!",
				"Vedi, qui alla Pizzeria Da Mario sforniamo la vera pizza a Torino da trent'anni, ma sul web siamo invisibili. I clienti cercano su Google Maps e finiscono nei fast food!",
				"Ho bisogno di un sito web chiaro e moderno: il nostro logo, il menu delle nostre pizze speciali, orari e un sistema per ordinare.",
				"Il mio budget per questo lavoro è di € 350,00 netti. Ci stai?"
			]
			choices = [
				{"text": "Affare fatto Mario! Torno al mio studio e inizio subito lo sviluppo.", "action": "accept"},
				{"text": "Quali elementi sono indispensabili per te?", "action": "details"}
			]
		"in_progress":
			lines = [
				"Bentornato! Come procede lo sviluppo del sito?",
				"Ricordati di inserire il logo, il menu, gli orari e il carrello asporto.",
				"Torna al tuo studio e usa l'app WebForge sul tuo laptop!"
			]
			choices = [
				{"text": "Ci sto lavorando proprio ora, torno subito al laptop!", "action": "close"}
			]
		"built":
			lines = [
				"Ho saputo che il sito è pronto su WebForge!",
				"Accedi alla tua casella di posta sul laptop per inviarmi la consegna ufficiale e ricevere il compenso!"
			]
			choices = [
				{"text": "Perfetto, vado subito a inviarti il progetto!", "action": "close"}
			]
		"completed":
			lines = [
				"Grandissimo lavoro con quel sito web! Abbiamo già registrato le prime prenotazioni online!",
				"Ti sei guadagnato la mia stima e ogni volta che passi da via Po per te la pizza è offerta!",
				"Ora reinvesti quei soldi e fai decollare la tua startup informatica!"
			]
			choices = [
				{"text": "Grazie mille Mario, è stato un piacere collaborare!", "action": "close"}
			]
			
	EventBus.dialogue_started.emit("Mario Esposito (Pizzaiolo)", lines, choices)

func play_cheer() -> void:
	if anim_player and anim_player.has_animation("Cheer"):
		anim_player.play("Cheer")
