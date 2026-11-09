class_name ServerRackInteractable
extends Interactable3D
## ServerRackInteractable - Allows physical interaction and maintenance of the 19" server rack

func _ready() -> void:
	super._ready()
	prompt_message = "[E] Ispeziona & Manutenzione Server Rack"
	EventBus.time_tick.connect(func(_h, _m, _d): _update_prompt())

func _update_prompt() -> void:
	if ServerRackManager.active_incident != "":
		prompt_message = "[E] RISOLVI ALLERTA SERVER (%s)" % ServerRackManager.active_incident
	else:
		prompt_message = "[E] Ispeziona Server Rack (%0.1f°C | %d RPM)" % [ServerRackManager.temperature_celsius, ServerRackManager.fan_speed_rpm]

func _on_interact(_player: Node) -> void:
	ServerRackManager.resolve_physical_maintenance()
