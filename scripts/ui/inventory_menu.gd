extends Control
## InventoryMenu - Zaino personale, Magazzino Hardware B2B, Gadget da Campo e Dotazioni Studio [Tab].
## Responsive su tutte le risoluzioni (800x600, 1024x520, 1280x720, 1920x1080).

const MapData := preload("res://scripts/world/world_map_data.gd")
const CATEGORY_ALL := "all"
const CATEGORY_CONSUMABLES := "consumables"
const CATEGORY_HARDWARE := "hardware"
const CATEGORY_GEAR := "gear"

const UPGRADE_CATALOG := {
	"monitor_upgrade": {
		"name": "Dual Monitor 27\" 4K Studio",
		"desc": "Postazione dual screen dello studio: riduce il tempo di build su WebForge (-1.5s)."
	},
	"chair_gaming_upgrade": {
		"name": "Sedia Ergonomica Racing Pro",
		"desc": "Seduta professionale anti-affaticamento: velocizza lo sviluppo software (-0.8s)."
	},
	"plant_aloe": {
		"name": "Pianta Aloe Torino (Design)",
		"desc": "Verde decorativo naturale posizionabile liberamente nello studio [B]."
	},
	"plant_aloe_upgrade": {
		"name": "Pianta Aloe Torino (Design)",
		"desc": "Verde decorativo naturale posizionabile liberamente nello studio [B]."
	},
	"server_rack_upgrade": {
		"name": "Server Rack 19\" & Domini Cloud",
		"desc": "Attiva il Rack Manager su TO-OS per ospitare i domini clienti con rendita giornaliera."
	}
}

var current_category: String = CATEGORY_ALL
var selected_entry: Dictionary = {}
var _entries: Array[Dictionary] = []

var _panel: PanelContainer
var _title_lbl: Label
var _stats_lbl: Label
var _close_btn: Button
var _tab_buttons: Dictionary = {}
var _items_box: VBoxContainer
var _empty_lbl: Label

# Inspector panel (right side)
var _inspector_panel: PanelContainer
var _detail_badge: Label
var _detail_title: Label
var _detail_qty: Label
var _detail_desc: RichTextLabel
var _detail_action_btn: Button
var _detail_secondary_btn: Button

func _ready() -> void:
	_build_ui()
	EventBus.backpack_updated.connect(_on_inventory_changed)
	EventBus.needs_changed.connect(func(_h, _e): if visible: _refresh_stats())
	EventBus.funds_changed.connect(func(_b, _d, _r): if visible: _refresh_stats())
	if ShopManager.has_signal("backpack_changed"):
		ShopManager.backpack_changed.connect(_on_inventory_changed)
	if ShopManager.has_signal("hardware_changed"):
		ShopManager.hardware_changed.connect(_on_inventory_changed)
	EventBus.item_purchased.connect(func(_id, _c): _on_inventory_changed())
	get_viewport().size_changed.connect(_fit_to_viewport)
	_fit_to_viewport()

func _on_inventory_changed() -> void:
	if visible:
		_refresh_stats()
		_rebuild_entries()

func open_inventory() -> void:
	_fit_to_viewport()
	_refresh_stats()
	_rebuild_entries()
	GameManager.change_state(GameManager.GameState.INVENTORY)

func close_inventory() -> void:
	visible = false
	if GameManager.current_state == GameManager.GameState.INVENTORY:
		GameManager.change_state(GameManager.GameState.FIRST_PERSON)

func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.04, 0.06, 0.10, 0.72)
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	_panel = PanelContainer.new()
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.10, 0.12, 0.17, 0.98)
	ps.border_color = Color(0.32, 0.76, 0.96, 0.85)
	ps.set_border_width_all(2)
	ps.set_corner_radius_all(12)
	ps.set_content_margin_all(14)
	_panel.add_theme_stylebox_override("panel", ps)
	center.add_child(_panel)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	_panel.add_child(root)

	# Header
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	root.add_child(header)

	var title_col := VBoxContainer.new()
	title_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_col)

	_title_lbl = Label.new()
	_title_lbl.text = "ZAINO & DOTAZIONI STARTUP"
	_title_lbl.add_theme_font_size_override("font_size", 19)
	_title_lbl.add_theme_color_override("font_color", Color(0.55, 0.88, 1.0))
	title_col.add_child(_title_lbl)

	_stats_lbl = Label.new()
	_stats_lbl.add_theme_font_size_override("font_size", 12)
	_stats_lbl.add_theme_color_override("font_color", Color(0.84, 0.88, 0.94))
	_stats_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title_col.add_child(_stats_lbl)

	_close_btn = Button.new()
	_close_btn.text = "Chiudi [Tab]"
	_close_btn.custom_minimum_size = Vector2(110, 32)
	_close_btn.pressed.connect(close_inventory)
	header.add_child(_close_btn)

	# Filter Tabs
	var tab_row := HBoxContainer.new()
	tab_row.add_theme_constant_override("separation", 6)
	root.add_child(tab_row)

	var tab_specs := [
		[CATEGORY_ALL, "Tutti"],
		[CATEGORY_CONSUMABLES, "Zaino & Cibo"],
		[CATEGORY_HARDWARE, "Hardware B2B"],
		[CATEGORY_GEAR, "Dotazioni & Studio"]
	]
	for spec in tab_specs:
		var cid: String = spec[0]
		var btn := Button.new()
		btn.text = spec[1]
		btn.toggle_mode = true
		btn.custom_minimum_size = Vector2(0, 30)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.pressed.connect(func(): _select_category(cid))
		tab_row.add_child(btn)
		_tab_buttons[cid] = btn
	_tab_buttons[CATEGORY_ALL].button_pressed = true

	var sep := HSeparator.new()
	root.add_child(sep)

	# Body Split: Items List + Inspector Details
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 12)
	root.add_child(body)

	var left_col := VBoxContainer.new()
	left_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_col.size_flags_stretch_ratio = 1.45
	left_col.add_theme_constant_override("separation", 6)
	body.add_child(left_col)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left_col.add_child(scroll)

	_items_box = VBoxContainer.new()
	_items_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_items_box.add_theme_constant_override("separation", 6)
	scroll.add_child(_items_box)

	_empty_lbl = Label.new()
	_empty_lbl.text = "Nessun elemento in questa categoria. Visita i negozi del borgo!"
	_empty_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_empty_lbl.add_theme_color_override("font_color", Color(0.72, 0.76, 0.84))
	_empty_lbl.visible = false
	left_col.add_child(_empty_lbl)

	# Inspector Panel
	_inspector_panel = PanelContainer.new()
	_inspector_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_inspector_panel.size_flags_stretch_ratio = 1.0
	var ips := StyleBoxFlat.new()
	ips.bg_color = Color(0.14, 0.17, 0.24, 0.96)
	ips.border_color = Color(0.28, 0.36, 0.50, 0.85)
	ips.set_border_width_all(1)
	ips.set_corner_radius_all(8)
	ips.set_content_margin_all(12)
	_inspector_panel.add_theme_stylebox_override("panel", ips)
	body.add_child(_inspector_panel)

	var dbox := VBoxContainer.new()
	dbox.add_theme_constant_override("separation", 8)
	_inspector_panel.add_child(dbox)

	_detail_badge = Label.new()
	_detail_badge.add_theme_font_size_override("font_size", 11)
	_detail_badge.add_theme_color_override("font_color", Color(1.0, 0.84, 0.38))
	dbox.add_child(_detail_badge)

	_detail_title = Label.new()
	_detail_title.add_theme_font_size_override("font_size", 16)
	_detail_title.add_theme_color_override("font_color", Color(0.95, 0.97, 1.0))
	_detail_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dbox.add_child(_detail_title)

	_detail_qty = Label.new()
	_detail_qty.add_theme_font_size_override("font_size", 12)
	_detail_qty.add_theme_color_override("font_color", Color(0.48, 0.94, 0.68))
	dbox.add_child(_detail_qty)

	var dsep := HSeparator.new()
	dbox.add_child(dsep)

	_detail_desc = RichTextLabel.new()
	_detail_desc.bbcode_enabled = true
	_detail_desc.fit_content = false
	_detail_desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_detail_desc.add_theme_font_size_override("normal_font_size", 13)
	dbox.add_child(_detail_desc)

	_detail_action_btn = Button.new()
	_detail_action_btn.custom_minimum_size = Vector2(0, 34)
	_detail_action_btn.pressed.connect(_on_detail_action_pressed)
	dbox.add_child(_detail_action_btn)

	_detail_secondary_btn = Button.new()
	_detail_secondary_btn.custom_minimum_size = Vector2(0, 30)
	_detail_secondary_btn.pressed.connect(_on_detail_secondary_pressed)
	_detail_secondary_btn.visible = false
	dbox.add_child(_detail_secondary_btn)

func _fit_to_viewport() -> void:
	if not is_instance_valid(_panel):
		return
	var vp := get_viewport_rect().size
	if vp.x <= 0 or vp.y <= 0:
		vp = Vector2(1280, 720)
	var w := clampf(vp.x - 40.0, 360.0, 860.0)
	var h := clampf(vp.y - 40.0, 280.0, 520.0)
	_panel.custom_minimum_size = Vector2(w, h)
	_panel.size = Vector2(w, h)

func _select_category(cat: String) -> void:
	current_category = cat
	for k in _tab_buttons:
		_tab_buttons[k].button_pressed = (k == cat)
	SoundManager.play_ui_click()
	_rebuild_entries()

func _refresh_stats() -> void:
	var h := int(roundf(NeedsManager.get_hunger()))
	var e := int(roundf(NeedsManager.get_energy()))
	_stats_lbl.text = "Saldo: € %0.2f  ·  Fame: %d%%  ·  Energia: %d%%  ·  Zaino: %d  ·  Hardware: %d  ·  Studio: %s" % [
		EconomyManager.balance, h, e,
		ShopManager.get_backpack_count(), ShopManager.get_hardware_count(),
		GameManager.get_company_tier_name()
	]

func _collect_entries() -> Array[Dictionary]:
	var out: Array[Dictionary] = []

	# 1. Portable Backpack Consumables
	for bp in ShopManager.get_backpack_items():
		var bid := str(bp.get("id", ""))
		out.append({
			"kind": CATEGORY_CONSUMABLES,
			"id": bid,
			"name": str(bp.get("name", bid)),
			"qty": int(bp.get("qty", 1)),
			"badge": "ZAINO · CONSUMABILE",
			"color": Color(0.98, 0.72, 0.34),
			"subtitle": ShopManager.describe_effects(bp),
			"item": bp
		})

	# 2. B2B Hardware Stock (including needed hardware hints even if qty=0)
	var needed_hw := _compute_required_hardware()
	var hw_catalog := ShopManager.get_items("elettronica_componenti")
	for hw in hw_catalog:
		if bool(hw.get("is_gadget", false)):
			continue
		var hid := str(hw.get("id", ""))
		var have := ShopManager.get_hardware_count(hid)
		var req := int(needed_hw.get(hid, 0))
		if have > 0 or req > 0:
			var sub := "In magazzino: x%d" % have
			if req > 0:
				sub += " · Richiesto per commesse: %d (%s)" % [req, "PRONTO ✔" if have >= req else "Mancante"]
			out.append({
				"kind": CATEGORY_HARDWARE,
				"id": hid,
				"name": str(hw.get("name", hid)),
				"qty": have,
				"required": req,
				"badge": "HARDWARE B2B",
				"color": Color(0.35, 0.78, 1.0),
				"subtitle": sub,
				"item": hw
			})

	# 3. Gadgets & Studio Upgrades
	for hw in hw_catalog:
		if not bool(hw.get("is_gadget", false)):
			continue
		var gid := str(hw.get("id", ""))
		var owned := ShopManager.has_gadget(gid)
		out.append({
			"kind": CATEGORY_GEAR,
			"id": gid,
			"name": str(hw.get("name", gid)),
			"qty": 1 if owned else 0,
			"owned": owned,
			"badge": "GADGET TECNICO" if owned else "ACQUISTABILE (ELETTRONICA TO)",
			"color": Color(0.45, 0.95, 0.65) if owned else Color(0.60, 0.65, 0.75),
			"subtitle": str(hw.get("desc", "")),
			"item": hw
		})

	var seen_upg := {}
	for upg_id in GameManager.studio_upgrades_installed:
		var uid := str(upg_id)
		var canonical := "plant_aloe" if uid == "plant_aloe_upgrade" else uid
		if seen_upg.has(canonical):
			continue
		seen_upg[canonical] = true
		var uinfo: Dictionary = UPGRADE_CATALOG.get(uid, {"name": uid, "desc": "Potenziamento installato nello studio."})
		out.append({
			"kind": CATEGORY_GEAR,
			"id": uid,
			"name": str(uinfo["name"]),
			"qty": 1,
			"owned": true,
			"badge": "DOTAZIONE STUDIO ATTIVA",
			"color": Color(0.75, 0.62, 1.0),
			"subtitle": str(uinfo["desc"]),
			"item": uinfo
		})

	return out

func _compute_required_hardware() -> Dictionary:
	var req := {}
	var fac := ContractManager.get_factory_progress_summary()
	if bool(fac.get("accepted", false)) and not bool(fac.get("completed", false)):
		if not bool(fac.get("wifi_mounted", false)) and not bool(fac.get("wifi_done", false)):
			req["hw_wifi_router"] = int(req.get("hw_wifi_router", 0)) + 1
		if not bool(fac.get("server_done", false)):
			req["hw_server_tower"] = int(req.get("hw_server_tower", 0)) + 1
		if not bool(fac.get("pcs_done", false)):
			req["hw_workstation_pc"] = int(req.get("hw_workstation_pc", 0)) + 2
	for cid in ContractManager.active_contracts:
		var c = ContractManager.active_contracts[cid]
		if c is Dictionary and c.get("status", "") == "in_progress" and c.get("execution_type", "") == "hardware":
			var rhw: Dictionary = c.get("required_hardware", {})
			for hid in rhw:
				req[str(hid)] = int(req.get(str(hid), 0)) + int(rhw[hid])
	return req

func _rebuild_entries() -> void:
	for ch in _items_box.get_children():
		ch.queue_free()

	var all := _collect_entries()
	_entries.clear()
	for e in all:
		if current_category == CATEGORY_ALL or str(e["kind"]) == current_category:
			_entries.append(e)

	_empty_lbl.visible = _entries.is_empty()

	var prev_id := str(selected_entry.get("id", ""))
	var found_prev := false

	for e in _entries:
		var eid := str(e["id"])
		var row_panel := PanelContainer.new()
		var is_sel := (eid == prev_id and str(e["kind"]) == str(selected_entry.get("kind", "")))
		if is_sel:
			found_prev = true
		var rs := StyleBoxFlat.new()
		rs.bg_color = Color(0.20, 0.27, 0.38, 0.98) if is_sel else Color(0.15, 0.18, 0.25, 0.95)
		rs.border_color = e["color"] if is_sel else Color(0.25, 0.29, 0.37, 0.5)
		rs.set_border_width_all(1)
		rs.set_corner_radius_all(8)
		rs.set_content_margin_all(8)
		row_panel.add_theme_stylebox_override("panel", rs)
		_items_box.add_child(row_panel)

		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 8)
		row_panel.add_child(hbox)

		var col := VBoxContainer.new()
		col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(col)

		var qty_tag := ""
		if e["kind"] == CATEGORY_CONSUMABLES:
			qty_tag = "  (x%d)" % int(e["qty"])
		elif e["kind"] == CATEGORY_HARDWARE:
			var req_q := int(e.get("required", 0))
			qty_tag = "  (x%d / Richiesti: %d)" % [int(e["qty"]), req_q] if req_q > 0 else "  (x%d)" % int(e["qty"])
		elif e["kind"] == CATEGORY_GEAR:
			qty_tag = "  [ATTIVO ✔]" if bool(e.get("owned", false)) else "  [NON POSSEDUTO]"

		var title := Label.new()
		title.text = str(e["name"]) + qty_tag
		title.add_theme_font_size_override("font_size", 14)
		title.add_theme_color_override("font_color", e["color"] if bool(e.get("owned", true)) else Color(0.68, 0.72, 0.80))
		title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		col.add_child(title)

		var sub := Label.new()
		sub.text = str(e["subtitle"])
		sub.add_theme_font_size_override("font_size", 11)
		sub.add_theme_color_override("font_color", Color(0.76, 0.82, 0.88))
		sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		col.add_child(sub)

		var sel_btn := Button.new()
		sel_btn.text = "Dettagli"
		sel_btn.custom_minimum_size = Vector2(72, 30)
		sel_btn.pressed.connect(func(): _select_entry(e))
		hbox.add_child(sel_btn)

		if e["kind"] == CATEGORY_CONSUMABLES:
			var use_btn := Button.new()
			use_btn.text = "Usa"
			use_btn.custom_minimum_size = Vector2(58, 30)
			use_btn.pressed.connect(func():
				ShopManager.use_backpack_item(eid)
				_refresh_stats()
				_rebuild_entries()
			)
			hbox.add_child(use_btn)

	if not _entries.is_empty():
		if found_prev:
			for e in _entries:
				if str(e["id"]) == prev_id and str(e["kind"]) == str(selected_entry.get("kind", "")):
					_update_inspector(e)
					break
		else:
			_update_inspector(_entries[0])
	else:
		selected_entry = {}
		_clear_inspector()

func _select_entry(entry: Dictionary) -> void:
	selected_entry = entry
	SoundManager.play_ui_click()
	_rebuild_entries()

func _clear_inspector() -> void:
	_detail_badge.text = "NESSUNA SELEZIONE"
	_detail_title.text = "Zaino Vuoto"
	_detail_qty.text = ""
	_detail_desc.text = "Acquista snack da asporto o hardware da Elettronica TO per trovarli qui nello zaino."
	_detail_action_btn.visible = false
	_detail_secondary_btn.visible = false

func _update_inspector(e: Dictionary) -> void:
	selected_entry = e
	_detail_badge.text = str(e.get("badge", "ARTICOLO"))
	_detail_badge.add_theme_color_override("font_color", e.get("color", Color.WHITE))
	_detail_title.text = str(e.get("name", ""))

	var kind := str(e.get("kind", ""))
	if kind == CATEGORY_CONSUMABLES:
		var item: Dictionary = e.get("item", {})
		_detail_qty.text = "Quantità in zaino: x%d" % int(e.get("qty", 0))
		var bb := "[b]Effetti al consumo:[/b]\n%s\n\n" % ShopManager.describe_effects(item)
		bb += "Puoi consumarlo immediatamente ovunque ti trovi (anche a Borgo Valdocco durante i lavori).\n\n"
		bb += "[color=#88ccff]Fame attuale: %d%% | Energia: %d%%[/color]" % [int(roundf(NeedsManager.get_hunger())), int(roundf(NeedsManager.get_energy()))]
		_detail_desc.text = bb
		_detail_action_btn.visible = true
		_detail_action_btn.disabled = false
		_detail_action_btn.text = "Consuma Ora"
		_detail_secondary_btn.visible = false
	elif kind == CATEGORY_HARDWARE:
		var have := int(e.get("qty", 0))
		var req := int(e.get("required", 0))
		var item: Dictionary = e.get("item", {})
		_detail_qty.text = "In magazzino: x%d" % have + ("  (Richiesti: x%d)" % req if req > 0 else "")
		var bb := "[b]Specifiche Tecniche:[/b]\n%s\n\n" % str(item.get("desc", ""))
		bb += "[b]Utilizzo:[/b] Consegna ai clienti da [i]Freelance Hub (TO-OS)[/i] o installa direttamente nelle stazioni dell'[i]Officina Bellini (Borgo Valdocco)[/i]."
		_detail_desc.text = bb
		_detail_action_btn.visible = true
		_detail_action_btn.disabled = false
		if have < maxi(1, req):
			_detail_action_btn.text = "Segna Elettronica TO sulla Mappa"
		else:
			_detail_action_btn.text = "Segna Officina Bellini sulla Mappa"
		_detail_secondary_btn.visible = false
	else:
		var owned := bool(e.get("owned", false))
		var item: Dictionary = e.get("item", {})
		_detail_qty.text = "Stato: Attivo ✔" if owned else "Acquistabile da Elettronica TO"
		var bb := "[b]Dettagli & Bonus:[/b]\n%s\n\n" % str(item.get("desc", e.get("subtitle", "")))
		bb += "[b]Sede Attuale:[/b] %s (Livello %d/4)" % [GameManager.get_company_tier_name(), GameManager.company_tier]
		_detail_desc.text = bb
		if owned:
			_detail_action_btn.visible = true
			_detail_action_btn.disabled = true
			_detail_action_btn.text = "Dotazione Attiva ✔"
		else:
			_detail_action_btn.visible = true
			_detail_action_btn.disabled = false
			_detail_action_btn.text = "Segna Elettronica TO sulla Mappa"
		_detail_secondary_btn.visible = false

func _on_detail_action_pressed() -> void:
	if selected_entry.is_empty():
		return
	var kind := str(selected_entry.get("kind", ""))
	if kind == CATEGORY_CONSUMABLES:
		ShopManager.use_backpack_item(str(selected_entry.get("id", "")))
		_refresh_stats()
		_rebuild_entries()
	elif kind == CATEGORY_HARDWARE or (kind == CATEGORY_GEAR and not bool(selected_entry.get("owned", false))):
		var have := int(selected_entry.get("qty", 0))
		var req := int(selected_entry.get("required", 0))
		var poi_id := "elettronica_to"
		if kind == CATEGORY_HARDWARE and have >= maxi(1, req):
			poi_id = "officina_bellini"
		var poi: Dictionary = MapData.get_poi(poi_id)
		if not poi.is_empty():
			GameManager.set_waypoint(poi["id"], poi["name"], poi["pos"])
			SoundManager.play_ui_success()
			EventBus.notification_posted.emit("Segnavia Impostato", "Bussola HUD puntata verso %s!" % poi["name"], "info")
			close_inventory()

func _on_detail_secondary_pressed() -> void:
	pass
