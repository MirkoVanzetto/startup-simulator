class_name OGRGateSync
extends Node3D
## OGRGateSync - Sblocca fisicamente l'accesso alle OGR (Mercato Est) dopo Via Po & Officina Bellini.

@export var body_path: NodePath = NodePath("OGRGateBody/Collider")
@export var gate_visual_path: NodePath = NodePath("GateVisual")
@export var open_banner_path: NodePath = NodePath("OpenBanner")

func _ready() -> void:
	_refresh()
	if not EventBus.ogr_hub_unlocked.is_connected(_on_ogr_unlocked):
		EventBus.ogr_hub_unlocked.connect(_on_ogr_unlocked)
	if not EventBus.contract_updated.is_connected(_on_contract_updated):
		EventBus.contract_updated.connect(_on_contract_updated)

func _exit_tree() -> void:
	if EventBus.ogr_hub_unlocked.is_connected(_on_ogr_unlocked):
		EventBus.ogr_hub_unlocked.disconnect(_on_ogr_unlocked)
	if EventBus.contract_updated.is_connected(_on_contract_updated):
		EventBus.contract_updated.disconnect(_on_contract_updated)

func _on_ogr_unlocked() -> void:
	_refresh()

func _on_contract_updated(_cid: String, _st: String) -> void:
	_refresh()

func _refresh() -> void:
	var unlocked := ContractManager.is_ogr_unlocked() if is_instance_valid(ContractManager) else false
	var col := get_node_or_null(body_path) as CollisionShape3D
	if col:
		col.disabled = unlocked
	var vis := get_node_or_null(gate_visual_path) as Node3D
	if vis:
		vis.visible = not unlocked
	var open_b := get_node_or_null(open_banner_path) as Node3D
	if open_b:
		open_b.visible = unlocked
