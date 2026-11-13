extends Node3D
## FactoryVenueSync - Syncs installed 3D props (Router, Server, CAD Workstations) inside Officina Bellini.

@export var wifi_node_path: NodePath = NodePath("InstalledWifi")
@export var server_node_path: NodePath = NodePath("InstalledServer")
@export var pcs_node_path: NodePath = NodePath("InstalledPCs")

func _ready() -> void:
	_refresh()
	if not EventBus.contract_updated.is_connected(_on_contract_updated):
		EventBus.contract_updated.connect(_on_contract_updated)

func _exit_tree() -> void:
	if EventBus.contract_updated.is_connected(_on_contract_updated):
		EventBus.contract_updated.disconnect(_on_contract_updated)

func _on_contract_updated(cid: String, _st: String) -> void:
	if cid == "factory_bellini" or cid == "factory_bellini_web":
		_refresh()

func _refresh() -> void:
	var fac := ContractManager.get_factory_progress_summary()
	var w := get_node_or_null(wifi_node_path) as Node3D
	if w:
		w.visible = bool(fac["wifi_mounted"]) or bool(fac["wifi_done"])
	var s := get_node_or_null(server_node_path) as Node3D
	if s:
		s.visible = bool(fac["server_done"])
	var p := get_node_or_null(pcs_node_path) as Node3D
	if p:
		p.visible = bool(fac["pcs_done"])
