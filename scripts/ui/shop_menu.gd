extends Control
## ShopMenu - Interfaccia acquisto cibo, bevande, edicola e frigo dello studio.
## Rimane interamente contenuta nel viewport su tutte le risoluzioni (inclusi 800x600 e 1024x520).

var current_shop_id: String = ""

var _panel: PanelContainer
var _title_lbl: Label
var _subtitle_lbl: Label
var _discount_lbl: Label
var _balance_lbl: Label
var _needs_lbl: Label
var _items_box: VBoxContainer
var _close_btn: Button
var _empty_lbl: Label

func _ready() -> void:
	_build_ui()
	EventBus.shop_opened.connect(open_shop)
	EventBus.funds_changed.connect(func(_b, _d, _r): if visible: _refresh_header())
	EventBus.needs_changed.connect(func(_h, _e): if visible: _refresh_header())
	ShopManager.fridge_changed.connect(func(): if visible and current_shop_id == "fridge": _rebuild_items())
	if ShopManager.has_signal("hardware_changed"):
		ShopManager.hardware_changed.connect(func(): if visible and ShopManager.is_hardware_shop(current_shop_id): _rebuild_items())
	get_viewport().size_changed.connect(_fit_to_viewport)
	_fit_to_viewport()

func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.05, 0.07, 0.10, 0.68)
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	_panel = PanelContainer.new()
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.11, 0.13, 0.17, 0.97)
	panel_style.border_color = Color(0.92, 0.68, 0.28, 0.85)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(12)
	panel_style.set_content_margin_all(16)
	_panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(_panel)

	var root_vbox := VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 10)
	_panel.add_child(root_vbox)

	# Header
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	root_vbox.add_child(header)

	var title_col := VBoxContainer.new()
	title_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_col)

	_title_lbl = Label.new()
	_title_lbl.add_theme_font_size_override("font_size", 20)
	_title_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.55))
	_title_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title_col.add_child(_title_lbl)

	_subtitle_lbl = Label.new()
	_subtitle_lbl.add_theme_font_size_override("font_size", 12)
	_subtitle_lbl.add_theme_color_override("font_color", Color(0.75, 0.80, 0.86))
	_subtitle_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_col.add_child(_subtitle_lbl)

	_close_btn = Button.new()
	_close_btn.text = "Chiudi [Esc]"
	_close_btn.custom_minimum_size = Vector2(105, 34)
	_close_btn.pressed.connect(close_shop)
	header.add_child(_close_btn)

	# Status bar (Saldo, Sconto, Fame/Energia)
	var status_bar := HBoxContainer.new()
	status_bar.add_theme_constant_override("separation", 12)
	root_vbox.add_child(status_bar)

	_balance_lbl = Label.new()
	_balance_lbl.add_theme_font_size_override("font_size", 14)
	_balance_lbl.add_theme_color_override("font_color", Color(0.45, 0.95, 0.65))
	status_bar.add_child(_balance_lbl)

	_needs_lbl = Label.new()
	_needs_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_needs_lbl.add_theme_font_size_override("font_size", 13)
	_needs_lbl.add_theme_color_override("font_color", Color(0.92, 0.94, 0.98))
	status_bar.add_child(_needs_lbl)

	_discount_lbl = Label.new()
	_discount_lbl.add_theme_font_size_override("font_size", 13)
	_discount_lbl.add_theme_color_override("font_color", Color(1.0, 0.82, 0.35))
	status_bar.add_child(_discount_lbl)

	var sep := HSeparator.new()
	root_vbox.add_child(sep)

	# Scrollable items
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root_vbox.add_child(scroll)

	_items_box = VBoxContainer.new()
	_items_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_items_box.add_theme_constant_override("separation", 8)
	scroll.add_child(_items_box)

	_empty_lbl = Label.new()
	_empty_lbl.text = "Il frigo è vuoto! Passa da Alimentari Rosa per fare la spesa."
	_empty_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_empty_lbl.add_theme_color_override("font_color", Color(0.75, 0.78, 0.84))
	_empty_lbl.visible = false
	root_vbox.add_child(_empty_lbl)

func _fit_to_viewport() -> void:
	if not is_instance_valid(_panel):
		return
	var vp := get_viewport_rect().size
	if vp.x <= 0 or vp.y <= 0:
		vp = Vector2(1280, 720)
	var w := clampf(vp.x - 40.0, 320.0, 740.0)
	var h := clampf(vp.y - 40.0, 260.0, 500.0)
	_panel.custom_minimum_size = Vector2(w, h)
	_panel.size = Vector2(w, h)

func open_shop(shop_id: String) -> void:
	if not ShopManager.has_shop(shop_id):
		return
	current_shop_id = shop_id
	_fit_to_viewport()
	_refresh_header()
	_rebuild_items()
	GameManager.change_state(GameManager.GameState.SHOP)

func close_shop() -> void:
	visible = false
	if GameManager.current_state == GameManager.GameState.SHOP:
		GameManager.change_state(GameManager.GameState.FIRST_PERSON)

func _refresh_header() -> void:
	_title_lbl.text = ShopManager.get_shop_title(current_shop_id)
	_subtitle_lbl.text = ShopManager.get_shop_subtitle(current_shop_id)
	_balance_lbl.text = "Saldo: € %0.2f" % EconomyManager.balance
	if ShopManager.is_hardware_shop(current_shop_id):
		_needs_lbl.text = "Magazzino Hardware: %d pz" % ShopManager.get_hardware_count()
		var partner := ContractManager.is_contract_completed("elettronica_to")
		var disc := FameManager.get_discount_percent()
		if partner and disc > 0:
			_discount_lbl.text = "Sconto Partner Davide -20%% + Fame -%d%%" % disc
		elif partner:
			_discount_lbl.text = "Sconto Partner Davide: -20%%"
		elif disc > 0:
			_discount_lbl.text = "Sconto Notorietà: -%d%%" % disc
		else:
			_discount_lbl.text = ""
	else:
		_needs_lbl.text = "Fame: %d%%   Energia: %d%%" % [int(roundf(NeedsManager.get_hunger())), int(roundf(NeedsManager.get_energy()))]
		var disc := FameManager.get_discount_percent()
		if current_shop_id == "fridge":
			_discount_lbl.text = "Scorte personali"
		elif disc > 0:
			_discount_lbl.text = "Sconto Notorietà: -%d%%" % disc
		else:
			_discount_lbl.text = ""

func _rebuild_items() -> void:
	for ch in _items_box.get_children():
		ch.queue_free()

	var items := ShopManager.get_items(current_shop_id)
	_empty_lbl.visible = items.is_empty()
	var is_fridge := (current_shop_id == "fridge")
	var is_hw := ShopManager.is_hardware_shop(current_shop_id)
	var can_stock_fridge := ShopManager.is_fridge_stockable(current_shop_id)
	var disc_pct := FameManager.get_discount_percent()

	for item in items:
		var item_id: String = str(item["id"])
		var row_panel := PanelContainer.new()
		var rs := StyleBoxFlat.new()
		rs.bg_color = Color(0.16, 0.19, 0.25, 0.95)
		rs.set_corner_radius_all(8)
		rs.set_content_margin_all(10)
		row_panel.add_theme_stylebox_override("panel", rs)
		_items_box.add_child(row_panel)

		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		row_panel.add_child(row)

		var info := VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)

		var name_lbl := Label.new()
		var stock_suffix := ""
		if is_fridge:
			stock_suffix = " (x%d)" % int(item.get("stock", 0))
		elif is_hw:
			stock_suffix = " (In magazzino: x%d)" % ShopManager.get_hardware_count(item_id)
		name_lbl.text = str(item["name"]) + stock_suffix
		name_lbl.add_theme_font_size_override("font_size", 15)
		info.add_child(name_lbl)

		var eff_lbl := Label.new()
		eff_lbl.text = ShopManager.describe_effects(item)
		eff_lbl.add_theme_font_size_override("font_size", 12)
		eff_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		eff_lbl.add_theme_color_override("font_color", Color(0.68, 0.86, 0.76))
		info.add_child(eff_lbl)

		var price_box := VBoxContainer.new()
		price_box.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_child(price_box)

		if is_fridge:
			var free_lbl := Label.new()
			free_lbl.text = "Gratis"
			free_lbl.add_theme_color_override("font_color", Color(0.55, 0.95, 0.65))
			price_box.add_child(free_lbl)
		else:
			var base_p := ShopManager.get_base_price(current_shop_id, item_id)
			var final_p := ShopManager.get_price(current_shop_id, item_id)
			if final_p < base_p:
				var old_lbl := Label.new()
				old_lbl.text = "€ %0.2f" % base_p
				old_lbl.add_theme_font_size_override("font_size", 11)
				old_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65))
				price_box.add_child(old_lbl)
			var p_lbl := Label.new()
			p_lbl.text = "€ %0.2f" % final_p
			p_lbl.add_theme_font_size_override("font_size", 15)
			p_lbl.add_theme_color_override("font_color", Color(1.0, 0.86, 0.42))
			price_box.add_child(p_lbl)

		var buy_btn := Button.new()
		buy_btn.text = "Consuma" if is_fridge else "Compra"
		buy_btn.custom_minimum_size = Vector2(88, 34)
		buy_btn.pressed.connect(func():
			ShopManager.buy(current_shop_id, item_id)
			_refresh_header()
			if is_fridge or is_hw:
				_rebuild_items()
		)
		row.add_child(buy_btn)

		if can_stock_fridge:
			var fridge_btn := Button.new()
			fridge_btn.text = "+ Frigo"
			fridge_btn.custom_minimum_size = Vector2(78, 34)
			fridge_btn.pressed.connect(func():
				ShopManager.buy_for_fridge(current_shop_id, item_id)
				_refresh_header()
			)
			row.add_child(fridge_btn)
