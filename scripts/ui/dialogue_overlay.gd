extends Control
## DialogueOverlay - Interactive conversation interface with characters in Torino

@onready var speaker_label: Label = $Panel/Margin/VBox/SpeakerHeader/SpeakerName
@onready var dialogue_text: RichTextLabel = $Panel/Margin/VBox/DialogueText
@onready var choices_container: VBoxContainer = $Panel/Margin/VBox/ChoicesContainer
@onready var continue_button: Button = $Panel/Margin/VBox/ContinueButton

var lines_queue: Array = []
var active_choices: Array = []

func _ready() -> void:
	visible = false
	EventBus.dialogue_started.connect(_on_dialogue_started)
	continue_button.pressed.connect(_on_continue_pressed)

func _on_dialogue_started(speaker_name: String, text_lines: Array, choices: Array) -> void:
	visible = true
	speaker_label.text = speaker_name
	lines_queue = text_lines.duplicate()
	active_choices = choices.duplicate()
	_show_next_line()

func _show_next_line() -> void:
	if lines_queue.size() > 0:
		var current_line = lines_queue.pop_front()
		dialogue_text.text = current_line
		choices_container.visible = false
		continue_button.visible = true
		SoundManager.play_ui_click()
	else:
		_show_choices()

func _show_choices() -> void:
	continue_button.visible = false
	for child in choices_container.get_children():
		child.queue_free()
		
	if active_choices.is_empty():
		_close_dialogue()
		return
		
	choices_container.visible = true
	for i in range(active_choices.size()):
		var choice = active_choices[i]
		var btn = Button.new()
		btn.text = "➔ " + str(choice.get("text", ""))
		btn.add_theme_font_size_override("font_size", 14)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var action = choice.get("action", "")
		btn.pressed.connect(func(): _on_choice_clicked(action))
		choices_container.add_child(btn)

func _on_continue_pressed() -> void:
	_show_next_line()

func _on_choice_clicked(action: String) -> void:
	SoundManager.play_ui_click()
	match action:
		"accept":
			ContractManager.advance_tutorial_to_in_progress()
			_close_dialogue()
		"details":
			lines_queue = [
				"Nel dettaglio: voglio che il cliente veda il logo della nostra Mole Antonelliana in alto, la lista delle nostre specialità come la Margherita DOC e la pizza al Tartufo, i nostri orari di apertura e un bel pulsante per prenotare un tavolo online!",
				"Se il sito è completo ed elegante, i € 650 sono tuoi all'istante!"
			]
			active_choices = [
				{"text": "Chiarissimo Mario, mi metto subito al lavoro!", "action": "accept"}
			]
			_show_next_line()
		"close", _:
			_close_dialogue()

func _close_dialogue() -> void:
	visible = false
	EventBus.dialogue_ended.emit()
