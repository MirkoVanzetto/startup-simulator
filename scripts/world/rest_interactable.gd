class_name RestInteractable
extends Interactable3D
## RestInteractable - Letto dello studio: dormi fino al mattino successivo (07:00), energia al massimo

func _ready() -> void:
	super._ready()
	prompt_message = "[E] Dormi"

func _on_interact(_player: Node) -> void:
	SoundManager.play_ui_click()
	var hours = CalendarSystem.advance_to_next_morning()
	NeedsManager.sleep_full()
	SoundManager.play_ui_success()
	EventBus.notification_posted.emit(
		"Buongiorno!",
		"Hai dormito %d ore. Giorno %d, %s: energia al massimo, ma lo stomaco brontola." % [int(roundf(hours)), CalendarSystem.current_day, CalendarSystem.get_formatted_time()],
		"success"
	)
	SaveManager.request_auto_save()
