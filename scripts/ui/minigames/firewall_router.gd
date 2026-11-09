extends Control
## FirewallRouter - Cybersecurity & Network Circuit Routing Minigame.
## The player connects numbered network security nodes (1 -> 2 -> 3 -> 4 ...) without crossing lines.
## Configures and deploys real firewalls for corporate Turin clients.

signal routing_completed(client_name: String, payout: float)

@onready var title_label: Label = $Main/Header/HBox/TitleLabel
@onready var mission_label: Label = $Main/Header/HBox/MissionLabel
@onready var exit_btn: Button = $Main/Header/HBox/ExitButton

@onready var grid_container: GridContainer = $Main/Body/HBox/Center/MatrixPanel/VBox/Grid
@onready var status_label: Label = $Main/Body/HBox/RightPanel/VBox/StatusLabel
@onready var logs_label: RichTextLabel = $Main/Body/HBox/RightPanel/VBox/LogsPanel/LogsLabel
@onready var reset_btn: Button = $Main/Body/HBox/RightPanel/VBox/BtnRow/ResetBtn
@onready var undo_btn: Button = $Main/Body/HBox/RightPanel/VBox/BtnRow/UndoBtn
@onready var deploy_btn: Button = $Main/Footer/HBox/DeployButton
@onready var client_picker: OptionButton = $Main/Header/HBox/ClientPicker

const GRID_SIZE: int = 5

var current_level_idx: int = 0
var levels: Array[Dictionary] = [
	{
		"client": "Studio Notarile Cavour",
		"title": "Firewall Perimetrale & DMZ Notarile",
		"payout": 850.00,
		"checkpoints": {
			Vector2i(0, 0): 1,
			Vector2i(0, 3): 2,
			Vector2i(3, 3): 3,
			Vector2i(3, 0): 4
		},
		"max_checkpoint": 4
	},
	{
		"client": "AutoTorino Concessionaria",
		"title": "Routing VPN & Tunneling IPSec Concessionaria",
		"payout": 1450.00,
		"checkpoints": {
			Vector2i(0, 0): 1,
			Vector2i(0, 4): 2,
			Vector2i(2, 2): 3,
			Vector2i(4, 4): 4,
			Vector2i(4, 0): 5
		},
		"max_checkpoint": 5
	},
	{
		"client": "TechLab Politecnico",
		"title": "Zero-Trust Hardening & IDS/IPS Cluster",
		"payout": 2100.00,
		"checkpoints": {
			Vector2i(0, 0): 1,
			Vector2i(0, 4): 2,
			Vector2i(2, 4): 3,
			Vector2i(2, 1): 4,
			Vector2i(4, 1): 5,
			Vector2i(4, 4): 6
		},
		"max_checkpoint": 6
	}
]

var active_path: Array[Vector2i] = []
var next_required_checkpoint: int = 1
var is_level_completed: bool = false
var cell_buttons: Dictionary = {} # Vector2i -> Button

func _ready() -> void:
	visible = false
	EventBus.minigame_started.connect(_on_minigame_started)
	
	exit_btn.pressed.connect(_on_exit_pressed)
	reset_btn.pressed.connect(_reset_path)
	undo_btn.pressed.connect(_undo_step)
	deploy_btn.pressed.connect(_on_deploy_pressed)
	
	client_picker.clear()
	for i in range(levels.size()):
		var l = levels[i]
		client_picker.add_item("%s (€ %0.2f)" % [l["client"], l["payout"]], i)
	client_picker.item_selected.connect(_on_client_selected)
	
	_build_matrix_ui()

func _on_minigame_started(type: String) -> void:
	if type == "firewall_router":
		visible = true
		_load_level(current_level_idx)

func _on_exit_pressed() -> void:
	visible = false
	EventBus.computer_opened.emit()

func _on_client_selected(idx: int) -> void:
	current_level_idx = idx
	SoundManager.play_ui_click()
	_load_level(current_level_idx)

func _build_matrix_ui() -> void:
	for child in grid_container.get_children():
		child.queue_free()
	cell_buttons.clear()
	
	grid_container.columns = GRID_SIZE
	
	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			var pos = Vector2i(x, y)
			var btn = Button.new()
			btn.custom_minimum_size = Vector2(76, 76)
			btn.add_theme_font_size_override("font_size", 18)
			btn.pressed.connect(func(): _on_cell_clicked(pos))
			grid_container.add_child(btn)
			cell_buttons[pos] = btn

func _load_level(idx: int) -> void:
	var lvl = levels[idx]
	mission_label.text = "Cliente: %s | Compenso: € %0.2f" % [lvl["client"], lvl["payout"]]
	title_label.text = "🛡 NetShield — %s" % lvl["title"]
	
	logs_label.text = "[color=#00ccff]Inizializzazione matrice firewall 5x5...[/color]\n"
	logs_label.text += "[color=#ffffff]Traccia un tunnel continuo dal nodo 1 al nodo %d senza incrociare le linee![/color]\n" % lvl["max_checkpoint"]
	
	_reset_path()

func _reset_path() -> void:
	active_path.clear()
	is_level_completed = false
	next_required_checkpoint = 1
	deploy_btn.disabled = true
	deploy_btn.text = "Collega tutti i nodi di sicurezza per distribuire"
	
	# Start with Checkpoint 1
	var lvl = levels[current_level_idx]
	for pos in lvl["checkpoints"].keys():
		if lvl["checkpoints"][pos] == 1:
			active_path.append(pos)
			next_required_checkpoint = 2
			break
			
	_refresh_cell_visuals()
	_update_status_text()

func _undo_step() -> void:
	if active_path.size() > 1:
		var removed = active_path.pop_back()
		SoundManager.play_ui_click()
		
		# If removed cell was a checkpoint, revert next required
		var lvl = levels[current_level_idx]
		if lvl["checkpoints"].has(removed):
			next_required_checkpoint = lvl["checkpoints"][removed]
			
		is_level_completed = false
		deploy_btn.disabled = true
		_refresh_cell_visuals()
		_update_status_text()

func _on_cell_clicked(clicked_pos: Vector2i) -> void:
	if is_level_completed:
		return
		
	var current_head = active_path.back()
	
	# If clicked on the previous node in path -> undo to it
	if active_path.size() >= 2 and clicked_pos == active_path[active_path.size() - 2]:
		_undo_step()
		return
		
	# Check if adjacent (Manhattan distance == 1)
	var diff = clicked_pos - current_head
	var is_adjacent = (abs(diff.x) + abs(diff.y)) == 1
	if not is_adjacent:
		SoundManager.play_ui_error()
		return
		
	# Check non-crossing rule: cell cannot be already in active_path!
	if clicked_pos in active_path:
		SoundManager.play_ui_error()
		logs_label.text += "[color=#ff4444]⚠ Collisione linea! Impossibile incrociare una porta già collegata.[/color]\n"
		return
		
	# Check checkpoint order rule
	var lvl = levels[current_level_idx]
	if lvl["checkpoints"].has(clicked_pos):
		var cp_num = lvl["checkpoints"][clicked_pos]
		if cp_num != next_required_checkpoint:
			SoundManager.play_ui_error()
			logs_label.text += "[color=#ffbb33]⚠ Nodo errato! Devi collegare prima il Nodo %d.[/color]\n" % next_required_checkpoint
			return
		else:
			# Reached expected checkpoint!
			next_required_checkpoint += 1
			SoundManager.play_keyboard_sound()
			logs_label.text += "[color=#44ff88]✔ Checkpoint %d autorizzato e crittografato![/color]\n" % cp_num
			
	active_path.append(clicked_pos)
	SoundManager.play_ui_click()
	_refresh_cell_visuals()
	_update_status_text()
	
	# Check victory: reached max checkpoint!
	if next_required_checkpoint > lvl["max_checkpoint"]:
		_trigger_level_success()

func _trigger_level_success() -> void:
	is_level_completed = true
	SoundManager.play_ui_success()
	
	var lvl = levels[current_level_idx]
	deploy_btn.disabled = false
	deploy_btn.text = "★ Distribuisci Regole a %s (€ %0.2f)" % [lvl["client"], lvl["payout"]]
	status_label.text = "CIRCUITO CHIUSO CON SUCCESSO! Tutte le porte verificate."
	
	logs_label.text += "\n[color=#33ff77][b]★ REGOLE FIREWALL SINTETIZZATE CON SUCCESSO![/b][/color]\n"
	logs_label.text += "[color=#00ccff]iptables -A INPUT -p tcp --dport 443 -j ACCEPT\n"
	logs_label.text += "iptables -A FORWARD -m state --state ESTABLISHED -j ACCEPT\n"
	logs_label.text += "iptables -P FORWARD DROP [Zero-Trust Verified][/color]\n"

func _refresh_cell_visuals() -> void:
	var lvl = levels[current_level_idx]
	
	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			var pos = Vector2i(x, y)
			var btn = cell_buttons[pos]
			var is_checkpoint = lvl["checkpoints"].has(pos)
			var cp_val = lvl["checkpoints"].get(pos, 0)
			var in_path_idx = active_path.find(pos)
			var is_in_path = in_path_idx != -1
			var is_head = (pos == active_path.back())
			
			var bg_color = Color(0.12, 0.14, 0.18, 1)
			var border_color = Color(0.2, 0.25, 0.35, 1)
			var text_color = Color(0.7, 0.75, 0.8, 1)
			
			if is_checkpoint:
				btn.text = "● %d" % cp_val
				if is_in_path:
					bg_color = Color(0.1, 0.5, 0.3, 1) # Green connected
					border_color = Color(0.3, 1.0, 0.6, 1)
					text_color = Color(1, 1, 1, 1)
				else:
					bg_color = Color(0.2, 0.35, 0.5, 1) # Blue target
					border_color = Color(0.4, 0.8, 1.0, 1)
					text_color = Color(1, 0.9, 0.4, 1)
			elif is_in_path:
				btn.text = "━"
				bg_color = Color(0.15, 0.35, 0.3, 1)
				border_color = Color(0.3, 0.9, 0.6, 0.8)
				text_color = Color(0.4, 1, 0.7, 1)
			else:
				btn.text = "·"
				
			if is_head:
				border_color = Color(1, 0.9, 0.2, 1) # Glowing yellow head
				bg_color = Color(0.25, 0.45, 0.25, 1)
				
			var st = StyleBoxFlat.new()
			st.bg_color = bg_color
			st.set_border_width_all(2)
			st.border_color = border_color
			st.set_corner_radius_all(6)
			btn.add_theme_stylebox_override("normal", st)
			btn.add_theme_stylebox_override("hover", st)
			btn.add_theme_stylebox_override("pressed", st)
			btn.add_theme_color_override("font_color", text_color)

func _update_status_text() -> void:
	var lvl = levels[current_level_idx]
	if is_level_completed:
		status_label.text = "Stato: REGOLE COMPILATE (100%)"
	else:
		status_label.text = "Prossimo Nodo Richiesto: Nodo %d (Nodi visitati: %d/%d)" % [
			next_required_checkpoint,
			next_required_checkpoint - 1,
			lvl["max_checkpoint"]
		]

func _on_deploy_pressed() -> void:
	if not is_level_completed:
		return
		
	var lvl = levels[current_level_idx]
	var payout = float(lvl["payout"])
	var client = lvl["client"]
	
	EconomyManager.earn(payout, "Consulenza Sicurezza & Firewall: " + client)
	GameManager.reputation_points += 20
	SoundManager.play_ui_success()
	
	EventBus.notification_posted.emit(
		"Configurazione Firewall Distribuita!",
		"Hai completato la consulenza per %s incassando € %0.2f e +20 Reputazione!" % [client, payout],
		"success"
	)
	
	routing_completed.emit(client, payout)
	visible = false
	EventBus.computer_opened.emit()
