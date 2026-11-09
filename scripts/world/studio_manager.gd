extends Node3D
## StudioManager - Controls studio interactive elements, lighting, purchased upgrades, and employee workstation

@onready var monitor_upgrade: Node3D = $Upgrades/MonitorUpgradeProp
@onready var chair_office: Node3D = $Furniture/ChairOfficeProp
@onready var chair_gaming: Node3D = $Upgrades/ChairGamingUpgradeProp
@onready var plant_aloe: Node3D = $Upgrades/PlantAloeUpgrade
@onready var server_rack_upgrade: Node3D = $Upgrades/ServerRackUpgradeProp
@onready var employee_workstation: Node3D = $EmployeeWorkstation
@onready var employee_nametag: Label3D = $EmployeeWorkstation/EmployeeNameTag

func _ready() -> void:
	EventBus.item_purchased.connect(_on_item_purchased)
	EventBus.employee_hired.connect(_on_employee_changed)
	EventBus.employee_fired.connect(_on_employee_changed)
	update_installed_upgrades()
	update_employee_workstation()

func update_installed_upgrades() -> void:
	var has_monitor = "monitor_upgrade" in GameManager.studio_upgrades_installed
	var has_gaming_chair = "chair_gaming_upgrade" in GameManager.studio_upgrades_installed
	var has_plant = "plant_aloe" in GameManager.studio_upgrades_installed
	var has_server = "server_rack_upgrade" in GameManager.studio_upgrades_installed
	
	if monitor_upgrade:
		monitor_upgrade.visible = has_monitor
		monitor_upgrade.process_mode = Node.PROCESS_MODE_INHERIT if has_monitor else Node.PROCESS_MODE_DISABLED
		
	if chair_gaming and chair_office:
		chair_gaming.visible = has_gaming_chair
		chair_gaming.process_mode = Node.PROCESS_MODE_INHERIT if has_gaming_chair else Node.PROCESS_MODE_DISABLED
		chair_office.visible = not has_gaming_chair
		chair_office.process_mode = Node.PROCESS_MODE_DISABLED if has_gaming_chair else Node.PROCESS_MODE_INHERIT

	if plant_aloe:
		plant_aloe.visible = has_plant
		plant_aloe.process_mode = Node.PROCESS_MODE_INHERIT if has_plant else Node.PROCESS_MODE_DISABLED

	if server_rack_upgrade:
		server_rack_upgrade.visible = has_server
		server_rack_upgrade.process_mode = Node.PROCESS_MODE_INHERIT if has_server else Node.PROCESS_MODE_DISABLED

func update_employee_workstation() -> void:
	if not employee_workstation:
		return
		
	var hired = EmployeeManager.get_hired_employees()
	if hired.size() > 0:
		employee_workstation.visible = true
		employee_workstation.process_mode = Node.PROCESS_MODE_INHERIT
		if employee_nametag:
			var emp = hired[0]
			employee_nametag.text = "%s\n★ %s ★\n[In Studio - Operativo]" % [emp["name"], emp["role"]]
	else:
		employee_workstation.visible = false
		employee_workstation.process_mode = Node.PROCESS_MODE_DISABLED

func _on_item_purchased(_item_id: String, _cost: float) -> void:
	update_installed_upgrades()

func _on_employee_changed(_emp_id: String, _emp_name: String = "") -> void:
	update_employee_workstation()
