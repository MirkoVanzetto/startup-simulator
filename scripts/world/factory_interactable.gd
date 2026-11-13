class_name FactoryInteractable
extends Interactable3D
## FactoryInteractable - Scouting zones & hardware installation stations inside Officina Bellini.

@export var mode: String = "scout" # "scout" | "wifi" | "server" | "pcs"
@export var zone_id: String = ""
@export var zone_title: String = ""
@export var beacon_path: NodePath

func _ready() -> void:
	super._ready()
	_sync_state()
	if not EventBus.contract_updated.is_connected(_on_contract_updated):
		EventBus.contract_updated.connect(_on_contract_updated)
	if ShopManager.has_signal("hardware_changed") and not ShopManager.hardware_changed.is_connected(_on_hardware_changed):
		ShopManager.hardware_changed.connect(_on_hardware_changed)

func _exit_tree() -> void:
	if EventBus.contract_updated.is_connected(_on_contract_updated):
		EventBus.contract_updated.disconnect(_on_contract_updated)
	if ShopManager.has_signal("hardware_changed") and ShopManager.hardware_changed.is_connected(_on_hardware_changed):
		ShopManager.hardware_changed.disconnect(_on_hardware_changed)

func _on_contract_updated(cid: String, _st: String) -> void:
	if cid == "factory_bellini" or cid == "factory_bellini_web":
		_sync_state()

func _on_hardware_changed() -> void:
	_sync_state()

func _sync_state() -> void:
	var fac := ContractManager.get_factory_progress_summary()
	if mode == "scout":
		var done := ContractManager.is_factory_zone_scouted(zone_id)
		is_interactable = not done
		var beacon := get_node_or_null(beacon_path) as Node3D if not beacon_path.is_empty() else null
		if beacon:
			beacon.visible = not done
	else:
		is_interactable = true
	prompt_message = get_prompt()

func get_prompt() -> String:
	var fac := ContractManager.get_factory_progress_summary()
	match mode:
		"scout":
			if not is_interactable or ContractManager.is_factory_zone_scouted(zone_id):
				return ""
			return "[E] Perlustra: %s (%d/4)" % [zone_title, int(fac["scouted_count"])]
		"wifi":
			if bool(fac["wifi_done"]):
				return "✔ Wi-Fi 6 & VLAN Officina Attivi"
			if bool(fac["wifi_mounted"]):
				return "⚡ Router montato — Configura VLAN su NetShield (TO-OS)"
			if not bool(fac["all_scouted"]):
				return "[E] Router Wi-Fi 6 (Prima perlustra 4/4 zone: %d/4)" % int(fac["scouted_count"])
			var qty := ShopManager.get_hardware_count("hw_wifi_router")
			return "[E] Monta Router Wi-Fi 6 (In stock: %d/1)" % qty
		"server":
			if bool(fac["server_done"]):
				return "✔ Server Xeon RAID-10 Attivo"
			if not bool(fac["all_scouted"]):
				return "[E] Banco Server (Prima perlustra 4/4 zone: %d/4)" % int(fac["scouted_count"])
			var sqty := ShopManager.get_hardware_count("hw_server_tower")
			return "[E] Installa Server Tower Xeon (Stock: %d/1 · € 820)" % sqty
		"pcs":
			if bool(fac["pcs_done"]):
				return "✔ 2 Workstation PC CAD Operative"
			if not bool(fac["all_scouted"]):
				return "[E] Ufficio PC (Prima perlustra 4/4 zone: %d/4)" % int(fac["scouted_count"])
			var pqty := ShopManager.get_hardware_count("hw_workstation_pc")
			return "[E] Installa 2x Workstation PC (Stock: %d/2 · € 960)" % pqty
		_:
			return prompt_message

func _on_interact(_player: Node) -> void:
	match mode:
		"scout":
			ContractManager.scout_factory_zone(zone_id, zone_title)
		"wifi":
			var fac := ContractManager.get_factory_progress_summary()
			if bool(fac["wifi_done"]):
				EventBus.notification_posted.emit("Wi-Fi 6 Attivo", "La rete wireless e le VLAN CNC dell'officina funzionano al 100%.", "info")
			elif bool(fac["wifi_mounted"]):
				EventBus.notification_posted.emit("Configura VLAN", "Il router è già fissato a parete! Apri NetShield Cyber dal laptop dello studio.", "info")
			else:
				ContractManager.mount_factory_wifi_hardware()
		"server":
			if bool(ContractManager.factory_state.get("server_done", false)):
				EventBus.notification_posted.emit("Server Operativo", "Il Server Tower Xeon gestisce già backup e file CAD dell'officina.", "info")
			else:
				ContractManager.install_factory_server()
		"pcs":
			if bool(ContractManager.factory_state.get("pcs_done", false)):
				EventBus.notification_posted.emit("Postazioni Attive", "Le 2 Workstation PC CAD sono già operative in ufficio.", "info")
			else:
				ContractManager.install_factory_pcs()

	_sync_state()
	EventBus.prompt_changed.emit(get_prompt())
