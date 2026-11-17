class_name RestInteractable
extends Interactable3D
## RestInteractable - Letto dello studio: dormi fino al mattino successivo (07:00), energia al massimo,
## facendo avanzare anche la produzione automatizzata (Mining Robot / Drone) e i lavori autonomi del Team!

func _ready() -> void:
	super._ready()
	prompt_message = "[E] Dormi fino al mattino (07:00)"

func _on_interact(_player: Node) -> void:
	SoundManager.play_ui_click()
	var hours = CalendarSystem.advance_to_next_morning()
	NeedsManager.sleep_full()

	var extra_notes: Array[String] = []
	if is_instance_valid(TechOpsManager):
		var rob_sim := TechOpsManager.simulate_sleep_hours(hours)
		var r_units := int(rob_sim.get("robot_units", 0))
		if r_units > 0:
			extra_notes.append("Mining Robot: +%d materiali estratti" % r_units)
	if is_instance_valid(EmployeeManager):
		var emp_sim := EmployeeManager.simulate_sleep_hours(hours)
		var e_comp := int(emp_sim.get("completed", 0))
		var e_earned := float(emp_sim.get("earned", 0.0))
		if e_comp > 0:
			extra_notes.append("Team: %d incarichi chiusi (+€ %0.2f)" % [e_comp, e_earned])

	SoundManager.play_ui_success()
	var base_msg := "Hai dormito %d ore. Giorno %d, %s: energia al 100%%!" % [
		int(roundf(hours)),
		CalendarSystem.current_day,
		CalendarSystem.get_formatted_time()
	]
	if not extra_notes.is_empty():
		base_msg += " Durante la notte: " + " · ".join(extra_notes) + "."
	EventBus.notification_posted.emit("Buongiorno!", base_msg, "success")
	SaveManager.request_auto_save()
