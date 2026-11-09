extends Node
## ServerRackManager - Milestone 5: Infrastructure & Server Room Simulation
## Manages 19" rack hardware, server blades, client hosting contracts, telemetry, and physical maintenance.

signal telemetry_updated(temp: float, fans: int, bandwidth: float, status: String)
signal hardware_incident_occurred(incident_type: String, title: String, description: String)
signal incident_resolved(incident_type: String)
signal module_installed(module_id: String, module_name: String)

var is_rack_unlocked: bool = false
var installed_modules: Array[String] = []

# Telemetry
var temperature_celsius: float = 46.5
var fan_speed_rpm: int = 2400
var cooling_mode: String = "auto" # "silent", "auto", "boost"
var bandwidth_mbps: float = 340.0
var uptime_percent: float = 99.98
var status_health: String = "normal" # "normal", "warning", "critical"

# Hosted Client Domains & Contracts
var hosted_domains: Array[Dictionary] = []

# Maintenance & Incidents
var active_incident: String = "" # "", "filter_dusty", "drive_degraded", "thermal_throttle"

func _ready() -> void:
	# Check if server rack was already installed in GameManager
	if "server_rack_upgrade" in GameManager.studio_upgrades_installed:
		unlock_server_rack()
		
	EventBus.time_tick.connect(_on_time_tick)
	EventBus.contract_completed.connect(_on_contract_completed)

func unlock_server_rack() -> void:
	is_rack_unlocked = true
	if not "server_rack_base" in installed_modules:
		installed_modules.append("server_rack_base")
	
	# Add initial default hosting client
	if hosted_domains.is_empty():
		add_hosted_client("torinotech-portal.it", "Portale Tech Comunità Torino", 30.00)

func add_hosted_client(domain: String, client_name: String, daily_rate: float) -> void:
	for c in hosted_domains:
		if c.get("domain") == domain:
			return
			
	var client = {
		"domain": domain,
		"client_name": client_name,
		"daily_rate": daily_rate,
		"status": "online"
	}
	hosted_domains.append(client)
	EventBus.notification_posted.emit(
		"Nuovo Dominio in Hosting",
		"Il server rack ospita ora %s per %s (+€ %0.2f/giorno)!" % [domain, client_name, daily_rate],
		"success"
	)

func install_module(module_id: String, module_name: String, cost: float) -> bool:
	if not is_rack_unlocked:
		return false
	if module_id in installed_modules:
		return false
	if not EconomyManager.can_afford(cost):
		EventBus.notification_posted.emit("Fondi Insufficienti", "Ti servono € %0.2f per installare %s." % [cost, module_name], "error")
		return false
		
	EconomyManager.spend(cost, "Acquisto Modulo Rack: " + module_name)
	installed_modules.append(module_id)
	module_installed.emit(module_id, module_name)
	EventBus.notification_posted.emit("Modulo Installato", "%s è ora operativo nel server rack!" % module_name, "success")
	_recalculate_telemetry()
	return true

func set_cooling_mode(mode: String) -> void:
	cooling_mode = mode
	match mode:
		"silent":
			fan_speed_rpm = 1800
			temperature_celsius = max(42.0, temperature_celsius + 4.0)
		"auto":
			fan_speed_rpm = 2600
			temperature_celsius = 48.0
		"boost":
			fan_speed_rpm = 4500
			temperature_celsius = 38.5
			
	SoundManager.play_ui_click()
	_emit_telemetry()

func _on_time_tick(_h: int, _m: int, _d: int) -> void:
	if not is_rack_unlocked:
		return
		
	# Dynamic temperature fluctuation based on hosted sites load
	var base_temp = 44.0 + (hosted_domains.size() * 3.2)
	if cooling_mode == "boost":
		base_temp -= 8.0
	elif cooling_mode == "silent":
		base_temp += 6.0
		
	if active_incident == "filter_dusty":
		base_temp += 14.0
	elif active_incident == "thermal_throttle":
		base_temp += 22.0
		
	temperature_celsius = lerp(temperature_celsius, base_temp, 0.15)
	
	# Update bandwidth
	bandwidth_mbps = 180.0 + (hosted_domains.size() * 85.0) + randf_range(-15.0, 25.0)
	
	# Check health status
	if temperature_celsius > 75.0:
		status_health = "critical"
		if active_incident == "":
			trigger_incident("thermal_throttle", "Surriscaldamento Rack Server", "Temperatura a %0.1f°C! Intervieni fisicamente sul rack o attiva la modalità Boost!" % temperature_celsius)
	elif temperature_celsius > 62.0:
		status_health = "warning"
	else:
		status_health = "normal"
		
	_emit_telemetry()

func trigger_incident(incident_type: String, title: String, desc: String) -> void:
	active_incident = incident_type
	hardware_incident_occurred.emit(incident_type, title, desc)
	EventBus.notification_posted.emit("ALLERTA HARDWARE SERVER", title + ": " + desc, "warning")
	SoundManager.play_ui_error()

func resolve_physical_maintenance() -> void:
	if active_incident != "":
		var prev = active_incident
		active_incident = ""
		temperature_celsius = 44.0
		status_health = "normal"
		incident_resolved.emit(prev)
		EventBus.notification_posted.emit("Manutenzione Completata", "Filtri puliti, ventole calibrate e dischi sincronizzati. Rack in perfetto stato!", "success")
		SoundManager.play_ui_success()
	else:
		EventBus.notification_posted.emit("Ispezione Server Rack", "Il rack funziona a regime ottimale (%0.1f°C, %d RPM, %d siti attivi)." % [temperature_celsius, fan_speed_rpm, hosted_domains.size()], "info")
		SoundManager.play_ui_click()

func calculate_daily_hosting_revenue() -> float:
	if not is_rack_unlocked:
		return 0.0
		
	var total = 0.0
	for c in hosted_domains:
		if c.get("status") == "online":
			total += float(c.get("daily_rate", 20.0))
			
	# Bonus if SAN Storage installed
	if "server_storage_san" in installed_modules:
		total *= 1.25 # +25% database replication fee
		
	# Bonus if DevOps Sara Bellini is hired
	if EmployeeManager and EmployeeManager.is_employee_hired("emp_sara"):
		total *= 1.35 # +35% uptime SLA premium
		
	return total

func _on_contract_completed(contract_id: String, _reward: float, _rep: int) -> void:
	if not is_rack_unlocked:
		return
		
	if contract_id == "pizzeria_da_mario":
		add_hosted_client("pizzeriadamario-torino.it", "Pizzeria Da Mario (E-commerce & Menu)", 38.00)
	elif contract_id == "caffe_san_carlo":
		add_hosted_client("caffesancarlo.to.it", "Caffè San Carlo (Web POS & Prenotazioni)", 45.00)
	elif contract_id == "elettronica_to":
		add_hosted_client("elettronicato.com", "Elettronica TO (Catalogo & Cloud Sync)", 65.00)

func _recalculate_telemetry() -> void:
	_emit_telemetry()

func _emit_telemetry() -> void:
	telemetry_updated.emit(temperature_celsius, fan_speed_rpm, bandwidth_mbps, status_health)
