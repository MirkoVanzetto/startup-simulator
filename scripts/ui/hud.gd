extends Control
## HUD - First-person overlay displaying crosshair, prompts, balance, objectives, and notifications

@onready var reticle: CenterContainer = $Reticle
@onready var prompt_container: CenterContainer = $PromptContainer
@onready var prompt_label: Label = $PromptContainer/PromptPanel/PromptLabel
@onready var balance_label: Label = $TopRight/HBox/BalancePanel/BalanceLabel
@onready var reputation_label: Label = $TopRight/HBox/ReputationPanel/ReputationLabel
@onready var objective_label: Label = $TopLeft/ObjectivePanel/VBox/ObjectiveText
@onready var toast_container: VBoxContainer = $BottomLeft/ToastContainer

const QuestManagerClass = preload("res://scripts/core/quest_manager.gd")
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
	
	_update_hud_display()

func _on_prompt_changed(text: String) -> void:
	prompt_container.visible = (text != "")
	prompt_label.text = text

func _on_funds_changed(new_balance: float, _delta: float, _reason: String) -> void:
	balance_label.text = "€ %0.2f" % new_balance

func _on_contract_updated(_contract_id: String, _status: String) -> void:
	_update_objective_display()

func _on_contract_completed(_id: String, _reward: float, _rep: int) -> void:
	reputation_label.text = "★ %d Rep" % GameManager.reputation_points
	_update_objective_display()

func _on_item_purchased(_item_id: String, _cost: float) -> void:
	_update_objective_display()

func _on_quest_objective_updated(text: String, _category: String, _is_complete: bool) -> void:
	if objective_label:
		objective_label.text = text

func _on_notification_posted(title: String, message: String, _icon_type: String) -> void:
	var toast = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.15, 0.20, 0.92)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(8)
	toast.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	var title_lbl = Label.new()
	title_lbl.text = "▶ " + title
	title_lbl.add_theme_color_override("font_color", Color(0.2, 0.9, 0.6))
	var msg_lbl = Label.new()
	msg_lbl.text = message
	msg_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	msg_lbl.custom_minimum_size = Vector2(280, 0)
	
	vbox.add_child(title_lbl)
	vbox.add_child(msg_lbl)
	toast.add_child(vbox)
	toast_container.add_child(toast)
	
	# Auto remove after 5 seconds
	var tween = create_tween()
	tween.tween_interval(4.5)
	tween.tween_property(toast, "modulate:a", 0.0, 0.5)
	tween.tween_callback(toast.queue_free)

func _on_game_state_changed(new_state: int, _old_state: int) -> void:
	visible = (new_state == GameManager.GameState.FIRST_PERSON)

func _update_objective_display() -> void:
	if objective_label and quest_manager and quest_manager.has_method("get_current_objective"):
		objective_label.text = quest_manager.get_current_objective()

func _update_hud_display() -> void:
	balance_label.text = "€ %0.2f" % EconomyManager.balance
	reputation_label.text = "★ %d Rep" % GameManager.reputation_points
	_update_objective_display()
	prompt_container.visible = false

