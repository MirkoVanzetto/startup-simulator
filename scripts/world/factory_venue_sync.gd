extends Node3D
## FactoryVenueSync - Syncs installed 3D props & semi-transparent 3D hologram blueprints inside Officina Bellini.

@export var wifi_node_path: NodePath = NodePath("InstalledWifi")
@export var server_node_path: NodePath = NodePath("InstalledServer")
@export var pcs_node_path: NodePath = NodePath("InstalledPCs")

@export var ghost_wifi_path: NodePath = NodePath("GhostWifi")
@export var ghost_server_path: NodePath = NodePath("GhostServer")
@export var ghost_pcs_path: NodePath = NodePath("GhostPCs")

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
	var all_scouted := bool(fac.get("all_scouted", false))
	var wifi_installed := bool(fac["wifi_mounted"]) or bool(fac["wifi_done"])
	var srv_installed := bool(fac["server_done"])
	var pcs_installed := bool(fac["pcs_done"])

	var w := get_node_or_null(wifi_node_path) as Node3D
	if w:
		w.visible = wifi_installed
	var s := get_node_or_null(server_node_path) as Node3D
	if s:
		s.visible = srv_installed
	var p := get_node_or_null(pcs_node_path) as Node3D
	if p:
		p.visible = pcs_installed

	_sync_ghost(ghost_wifi_path, not wifi_installed, all_scouted)
	_sync_ghost(ghost_server_path, not srv_installed, all_scouted)
	_sync_ghost(ghost_pcs_path, not pcs_installed, all_scouted)

func _sync_ghost(ghost_path: NodePath, show_ghost: bool, all_scouted: bool) -> void:
	var ghost := get_node_or_null(ghost_path) as Node3D
	if not ghost:
		return
	ghost.visible = show_ghost
	var ready_node := ghost.get_node_or_null("Ready") as Node3D
	var locked_node := ghost.get_node_or_null("Locked") as Node3D
	if ready_node:
		ready_node.visible = show_ghost and all_scouted
	if locked_node:
		locked_node.visible = show_ghost and not all_scouted
