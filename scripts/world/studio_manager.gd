extends Node3D
## StudioManager - Controls studio interactive elements, lighting, and purchased upgrades

@onready var monitor_upgrade: Node3D = $Upgrades/MonitorUpgradeProp
@onready var chair_office: Node3D = $Furniture/ChairOfficeProp
@onready var chair_gaming: Node3D = $Upgrades/ChairGamingUpgradeProp
@onready var plant_aloe: Node3D = $Upgrades/PlantAloeUpgrade

func _ready() -> void:
	EventBus.item_purchased.connect(_on_item_purchased)
	update_installed_upgrades()

func update_installed_upgrades() -> void:
	var has_monitor = "monitor_upgrade" in GameManager.studio_upgrades_installed
	var has_gaming_chair = "chair_gaming_upgrade" in GameManager.studio_upgrades_installed
	var has_plant = "plant_aloe" in GameManager.studio_upgrades_installed
	
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

func _on_item_purchased(_item_id: String, _cost: float) -> void:
	update_installed_upgrades()
