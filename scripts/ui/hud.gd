extends Control
## HUD - First-person overlay displaying crosshair, prompts, balance, objectives, and notifications

@onready var reticle: CenterContainer = $Reticle
@onready var prompt_container: CenterContainer = $PromptContainer
@onready var prompt_label: Label = $PromptContainer/PromptPanel/PromptLabel
@onready var balance_label: Label = $TopRight/HBox/BalancePanel/BalanceLabel
@onready var reputation_label: Label = $TopRight/HBox/ReputationPanel/ReputationLabel
@onready var objective_label: Label = $TopLeft/TopLeftVBox/ObjectivePanel/VBox/ObjectiveText
@onready var waypoint_panel: PanelContainer = $TopLeft/TopLeftVBox/WaypointPanel
@onready var waypoint_label: Label = $TopLeft/TopLeftVBox/WaypointPanel/VBox/WaypointText
@onready var toast_container: VBoxContainer = $BottomLeft/ToastContainer
@onready var hints_label: Label = $BottomRight/HintsPanel/HintsLabel
@onready var hunger_bar: ProgressBar = $NeedsPanelMargin/NeedsPanel/VBox/HungerRow/HungerBar
@onready var hunger_value: Label = $NeedsPanelMargin/NeedsPanel/VBox/HungerRow/HungerValue
@onready var energy_bar: ProgressBar = $NeedsPanelMargin/NeedsPanel/VBox/EnergyRow/EnergyBar
@onready var energy_value: Label = $NeedsPanelMargin/NeedsPanel/VBox/EnergyRow/EnergyValue

var _rep_refresh_accum: float = 0.0
var _last_rep_text: String = ""

const QuestManagerClass = preload("res://scripts/core/quest_manager.gd")
const COMPASS_ARROWS := ["↑", "↗", "→", "↘", "↓", "↙", "←", "↖"]
const WAYPOINT_ARRIVAL_METERS := 3.5

var quest_manager: Node = null

func _ready() -> void:
	quest_manager = QuestManagerClass.new()
	add_child(quest_manager)
	quest_manager.objective_updated.connect(_on_quest_objective_updated)
	
	if objective_label:
		objective_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		
	EventBus.prompt_changed.connect(_on_prompt_changed)
	EventBus.funds_changed.connect(_on_funds_changed)
	EventBus.contract_updated.connect(_on_contract_updated)
	EventBus.contract_completed.connect(_on_contract_completed)
	EventBus.item_purchased.connect(_on_item_purchased)
	EventBus.notification_posted.connect(_on_notification_posted)
	EventBus.game_state_changed.connect(_on_game_state_changed)
	EventBus.needs_changed.connect(_on_needs_changed)
	EventBus.fame_tier_changed.connect(func(_i, _n): _update_reputation_label())
	EventBus.waypoint_changed.connect(_on_waypoint_changed)
	EventBus.backpack_updated.connect(_update_hints_label)
	if ShopManager.has_signal("hardware_changed"):
		ShopManager.hardware_changed.connect(_update_hints_label)
	get_viewport().size_changed.connect(_update_hints_label)
	
	if reputation_label:
		reputation_label.add_theme_font_size_override("font_size", 14)
	_setup_need_bar(hunger_bar, Color(1.0, 0.65, 0.25))
	_setup_need_bar(energy_bar, Color(0.4, 0.75, 1.0))
	_update_hud_display()

func _process(delta: float) -> void:
	# La reputazione cambia anche fuori dai contratti (negozi, chiacchierate): aggiorna in modo leggero
	_rep_refresh_accum += delta
	if _rep_refresh_accum >= 0.4:
		_rep_refresh_accum = 0.0
		_update_reputation_label()
	if not GameManager.active_waypoint.is_empty():
		_update_waypoint_tracker()

func _setup_need_bar(bar: ProgressBar, color: Color) -> void:
	var bg = StyleBoxFlat.new()
	bg.bg_color = Color(0.2, 0.22, 0.28, 0.9)
	bg.set_corner_radius_all(3)
	bar.add_theme_stylebox_override("background", bg)
	_set_bar_fill(bar, color)

func _set_bar_fill(bar: ProgressBar, color: Color) -> void:
	var fill = StyleBoxFlat.new()
	fill.bg_color = color
	fill.set_corner_radius_all(3)
	bar.add_theme_stylebox_override("fill", fill)

func _on_needs_changed(hunger: float, energy: float) -> void:
	_update_needs_display(hunger, energy)

func _update_needs_display(hunger: float, energy: float) -> void:
	hunger_bar.value = hunger
	energy_bar.value = energy
	hunger_value.text = str(int(roundf(hunger)))
	energy_value.text = str(int(roundf(energy)))
	_set_bar_fill(hunger_bar, Color(0.95, 0.3, 0.25) if hunger < 30.0 else Color(1.0, 0.65, 0.25))
	_set_bar_fill(energy_bar, Color(0.95, 0.85, 0.3) if energy < 25.0 else Color(0.4, 0.75, 1.0))

func _update_reputation_label() -> void:
	var txt = FameManager.get_hud_label()
	if txt != _last_rep_text:
		_last_rep_text = txt
		reputation_label.text = txt

func _on_prompt_changed(text: String) -> void:
	prompt_container.visible = (text != "")
	prompt_label.text = text

func _on_funds_changed(new_balance: float, _delta: float, _reason: String) -> void:
	balance_label.text = "€ %0.2f" % new_balance

func _on_contract_updated(_contract_id: String, _status: String) -> void:
	_update_objective_display()

func _on_contract_completed(_id: String, _reward: float, _rep: int) -> void:
	_update_reputation_label()
	_update_objective_display()

func _on_item_purchased(_item_id: String, _cost: float) -> void:
	_update_objective_display()

func _on_quest_objective_updated(text: String, _category: String, _is_complete: bool) -> void:
	if objective_label:
		objective_label.text = text

func _on_waypoint_changed(_wp: Dictionary) -> void:
	_update_waypoint_tracker()

func _update_waypoint_tracker() -> void:
	if not is_instance_valid(waypoint_panel) or not is_instance_valid(waypoint_label):
		return
	var wp := GameManager.active_waypoint
	if wp.is_empty():
		waypoint_panel.visible = false
		return

	waypoint_panel.visible = true
	var wp_name := str(wp.get("name", "Destinazione"))
	var wp_pos: Vector3 = wp.get("pos", Vector3.ZERO)

	if not is_instance_valid(GameManager.player_node):
		waypoint_label.text = "⚑ %s" % wp_name
		return

	var pl: Node3D = GameManager.player_node
	var flat_to := Vector2(wp_pos.x - pl.global_position.x, wp_pos.z - pl.global_position.z)
	var dist := flat_to.length()

	if visible and GameManager.current_state == GameManager.GameState.FIRST_PERSON and dist <= WAYPOINT_ARRIVAL_METERS:
		SoundManager.play_ui_success()
		EventBus.notification_posted.emit("Destinazione Raggiunta!", "Sei arrivato a: %s" % wp_name, "success")
		GameManager.clear_waypoint()
		return

	var arrow := "↑"
	if dist > 0.05:
		var dir := flat_to / dist
		var fwd3 := -pl.global_transform.basis.z
		var right3 := pl.global_transform.basis.x
		var fwd := Vector2(fwd3.x, fwd3.z).normalized()
		var right := Vector2(right3.x, right3.z).normalized()
		var forward_amt := fwd.dot(dir)
		var right_amt := right.dot(dir)
		var rel_angle := atan2(right_amt, forward_amt)
		var sector := posmod(int(roundf(rel_angle / (PI / 4.0))), 8)
		arrow = COMPASS_ARROWS[sector]

	waypoint_label.text = "⚑ %s · %d m  %s" % [wp_name, int(roundf(dist)), arrow]

func _update_hints_label() -> void:
	if not is_instance_valid(hints_label):
		return
	var total := ShopManager.get_total_inventory_count()
	var vp := get_viewport_rect().size
	if vp.x > 0 and vp.x < 780.0:
		hints_label.text = "[TAB] Zaino (%d) · [M] Mappa · [ESC]" % total
	else:
		hints_label.text = "[TAB] Zaino (%d) · [CAPS/M] Mappa · [B] Arreda · [ESC] Pausa" % total

const MAX_TOASTS := 3

func _on_notification_posted(title: String, message: String, _icon_type: String) -> void:
	var vp_h := get_viewport_rect().size.y
	var max_visible := 2 if (vp_h > 0.0 and vp_h < 590.0) else MAX_TOASTS
	while toast_container.get_child_count() >= max_visible:
		var oldest := toast_container.get_child(0)
		toast_container.remove_child(oldest)
		oldest.queue_free()

	var toast = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.15, 0.20, 0.92)
	style.set_corner_radius_all(6)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	toast.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 1)
	var title_lbl = Label.new()
	title_lbl.text = "▶ " + title
	title_lbl.add_theme_font_size_override("font_size", 11)
	title_lbl.add_theme_color_override("font_color", Color(0.2, 0.9, 0.6))
	var msg_lbl = Label.new()
	msg_lbl.text = message
	msg_lbl.add_theme_font_size_override("font_size", 10)
	msg_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	msg_lbl.custom_minimum_size = Vector2(270, 0)
	
	vbox.add_child(title_lbl)
	vbox.add_child(msg_lbl)
	toast.add_child(vbox)
	toast_container.add_child(toast)
	
	# Auto remove after 5 seconds (bound to toast lifetime to avoid freed-target warnings on eviction)
	var tween = toast.create_tween()
	tween.tween_interval(4.5)
	tween.tween_property(toast, "modulate:a", 0.0, 0.5)
	tween.tween_callback(toast.queue_free)

func _on_game_state_changed(new_state: int, _old_state: int) -> void:
	visible = (new_state == GameManager.GameState.FIRST_PERSON)
	if visible:
		_update_hints_label()
		_update_waypoint_tracker()

func _update_objective_display() -> void:
	if objective_label and quest_manager and quest_manager.has_method("get_current_objective"):
		objective_label.text = quest_manager.get_current_objective()

func _update_hud_display() -> void:
	balance_label.text = "€ %0.2f" % EconomyManager.balance
	_update_reputation_label()
	_update_needs_display(NeedsManager.get_hunger(), NeedsManager.get_energy())
	_update_objective_display()
	_update_hints_label()
	_update_waypoint_tracker()
	prompt_container.visible = false

