extends Control
## WorldMapMenu - Mappa interattiva di Borgo San Carlo, Parco Valentino, Valdocco, Officina Bellini & OGR Tech Hub [CapsLock / M].
## Supporta zoom centrato sul cursore, trascinamento libero, ridimensionamento viewport continuo e filtri distretto senza blocco.

const MapData := preload("res://scripts/world/world_map_data.gd")
const MapCanvasScript := preload("res://scripts/ui/world_map_canvas.gd")

var current_view: String = "all" # "all" | "parco" | "sancarlo" | "valdocco" | "mercato"
var selected_poi_id: String = "studio"

var _panel: PanelContainer
var _close_btn: Button
var _view_buttons: Dictionary = {}
var _view_group: ButtonGroup
var _map_canvas: Control
var _zoom_out_btn: Button
var _zoom_reset_btn: Button
var _zoom_in_btn: Button
var _zoom_info_lbl: Label
var _poi_name_lbl: Label
var _poi_meta_lbl: Label
var _poi_desc_lbl: RichTextLabel
var _set_wp_btn: Button
var _clear_wp_btn: Button
var _quest_wp_btn: Button
var _poi_quick_list: VBoxContainer

func _ready() -> void:
	_build_ui()
	EventBus.waypoint_changed.connect(func(_wp):
		_refresh_quick_list()
		_refresh_sidebar()
		if is_instance_valid(_map_canvas):
			_map_canvas.queue_redraw()
	)
	resized.connect(_fit_to_viewport)
	if get_viewport() != null:
		get_viewport().size_changed.connect(_fit_to_viewport)
	_fit_to_viewport()
	select_poi("studio")

func open_map() -> void:
	_fit_to_viewport()
	var rec_id := GameManager.get_recommended_quest_poi_id()
	if not GameManager.active_waypoint.is_empty():
		select_poi(str(GameManager.active_waypoint.get("id", rec_id)))
	elif rec_id != "":
		select_poi(rec_id)
	_refresh_quick_list()
	_refresh_sidebar()
	if is_instance_valid(_map_canvas):
		_map_canvas.queue_redraw()
	GameManager.change_state(GameManager.GameState.MAP)

func close_map() -> void:
	visible = false
	if GameManager.current_state == GameManager.GameState.MAP:
		GameManager.change_state(GameManager.GameState.FIRST_PERSON)

func _process(_delta: float) -> void:
	if visible and is_instance_valid(_map_canvas):
		_map_canvas.queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_EQUAL or event.keycode == KEY_PLUS or event.keycode == KEY_KP_ADD:
			zoom_in()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_MINUS or event.keycode == KEY_KP_SUBTRACT:
			zoom_out()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_0 or event.keycode == KEY_KP_0:
			reset_zoom()
			get_viewport().set_input_as_handled()

func zoom_in() -> void:
	if is_instance_valid(_map_canvas):
		_map_canvas.zoom_in()
		SoundManager.play_ui_click()

func zoom_out() -> void:
	if is_instance_valid(_map_canvas):
		_map_canvas.zoom_out()
		SoundManager.play_ui_click()

func reset_zoom() -> void:
	if is_instance_valid(_map_canvas):
		_map_canvas.reset_zoom()
		SoundManager.play_ui_click()

func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.03, 0.05, 0.09, 0.78)
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	_panel = PanelContainer.new()
	var ps := StyleBoxFlat.new()
	ps.bg_color = Color(0.09, 0.11, 0.16, 0.98)
	ps.border_color = Color(0.95, 0.74, 0.30, 0.88)
	ps.set_border_width_all(2)
	ps.set_corner_radius_all(12)
	ps.set_content_margin_all(10)
	_panel.add_theme_stylebox_override("panel", ps)
	center.add_child(_panel)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 5)
	_panel.add_child(root)

	# Row 1: Header + Zoom Toolbar + Close
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 6)
	root.add_child(header)

	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_box.custom_minimum_size = Vector2(140, 0)
	title_box.add_theme_constant_override("separation", 1)
	header.add_child(title_box)

	var title := Label.new()
	title.text = "MAPPA DEL TERRITORIO — TORINO"
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.48))
	title.clip_text = true
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title_box.add_child(title)

	var sub := Label.new()
	sub.text = "Clicca un luogo per i dettagli · Rotella per zoom · Trascina per spostare"
	sub.add_theme_font_size_override("font_size", 11)
	sub.add_theme_color_override("font_color", Color(0.75, 0.80, 0.88))
	sub.clip_text = true
	sub.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title_box.add_child(sub)

	_zoom_out_btn = Button.new()
	_zoom_out_btn.text = " − "
	_zoom_out_btn.tooltip_text = "Riduci zoom mappa"
	_zoom_out_btn.focus_mode = Control.FOCUS_NONE
	_zoom_out_btn.custom_minimum_size = Vector2(30, 26)
	_zoom_out_btn.add_theme_font_size_override("font_size", 12)
	_zoom_out_btn.pressed.connect(zoom_out)
	header.add_child(_zoom_out_btn)

	_zoom_reset_btn = Button.new()
	_zoom_reset_btn.text = "100%"
	_zoom_reset_btn.tooltip_text = "Ripristina zoom e vista"
	_zoom_reset_btn.focus_mode = Control.FOCUS_NONE
	_zoom_reset_btn.custom_minimum_size = Vector2(52, 26)
	_zoom_reset_btn.add_theme_font_size_override("font_size", 11)
	_zoom_reset_btn.pressed.connect(reset_zoom)
	header.add_child(_zoom_reset_btn)

	_zoom_in_btn = Button.new()
	_zoom_in_btn.text = " + "
	_zoom_in_btn.tooltip_text = "Ingrandisci zoom mappa"
	_zoom_in_btn.focus_mode = Control.FOCUS_NONE
	_zoom_in_btn.custom_minimum_size = Vector2(30, 26)
	_zoom_in_btn.add_theme_font_size_override("font_size", 12)
	_zoom_in_btn.pressed.connect(zoom_in)
	header.add_child(_zoom_in_btn)

	_close_btn = Button.new()
	_close_btn.text = "Chiudi [Caps]"
	_close_btn.focus_mode = Control.FOCUS_NONE
	_close_btn.custom_minimum_size = Vector2(88, 26)
	_close_btn.add_theme_font_size_override("font_size", 11)
	_close_btn.pressed.connect(close_map)
	header.add_child(_close_btn)

	# Row 2: District Filter Bar (ButtonGroup + FOCUS_NONE so resize/zoom never locks)
	var filter_row := HBoxContainer.new()
	filter_row.add_theme_constant_override("separation", 6)
	root.add_child(filter_row)

	_view_group = ButtonGroup.new()
	_view_group.allow_unpress = false
	var views := [
		["all", "Tutto"],
		["parco", "Parco"],
		["sancarlo", "S.Carlo"],
		["valdocco", "Valdocco"],
		["mercato", "Mercato"],
		["borgopo", "Borgo Po"]
	]
	for v in views:
		var vid: String = v[0]
		var vb := Button.new()
		vb.text = v[1]
		vb.toggle_mode = true
		vb.button_group = _view_group
		vb.focus_mode = Control.FOCUS_NONE
		vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vb.custom_minimum_size = Vector2(0, 24)
		vb.add_theme_font_size_override("font_size", 11)
		vb.pressed.connect(func():
			_set_view(vid)
			vb.release_focus()
		)
		filter_row.add_child(vb)
		_view_buttons[vid] = vb
	_view_buttons["all"].button_pressed = true

	_zoom_info_lbl = Label.new()
	_zoom_info_lbl.text = "Zoom: 100%"
	_zoom_info_lbl.add_theme_font_size_override("font_size", 11)
	_zoom_info_lbl.add_theme_color_override("font_color", Color(0.55, 0.88, 1.0))
	filter_row.add_child(_zoom_info_lbl)

	var sep := HSeparator.new()
	root.add_child(sep)

	# Body split: Interactive Canvas + Inspector/Directory Sidebar
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 8)
	root.add_child(body)

	var canvas_frame := PanelContainer.new()
	canvas_frame.clip_contents = true
	canvas_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	canvas_frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	canvas_frame.size_flags_stretch_ratio = 2.4
	canvas_frame.custom_minimum_size = Vector2(240, 140)
	var cf_style := StyleBoxFlat.new()
	cf_style.bg_color = Color(0.06, 0.08, 0.13, 1.0)
	cf_style.border_color = Color(0.24, 0.31, 0.44, 0.9)
	cf_style.set_border_width_all(1)
	cf_style.set_corner_radius_all(8)
	cf_style.set_content_margin_all(4)
	canvas_frame.add_theme_stylebox_override("panel", cf_style)
	body.add_child(canvas_frame)

	_map_canvas = MapCanvasScript.new()
	_map_canvas.name = "MapCanvas"
	_map_canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_map_canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_map_canvas.poi_clicked.connect(_on_canvas_poi_clicked)
	_map_canvas.poi_double_clicked.connect(_on_canvas_poi_double_clicked)
	_map_canvas.zoom_changed.connect(_on_canvas_zoom_changed)
	canvas_frame.add_child(_map_canvas)

	# Right Sidebar
	var side := PanelContainer.new()
	side.clip_contents = true
	side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	side.size_flags_vertical = Control.SIZE_EXPAND_FILL
	side.size_flags_stretch_ratio = 1.0
	side.custom_minimum_size = Vector2(215, 0)
	var ss := StyleBoxFlat.new()
	ss.bg_color = Color(0.13, 0.16, 0.22, 0.96)
	ss.border_color = Color(0.24, 0.30, 0.42, 0.8)
	ss.set_border_width_all(1)
	ss.set_corner_radius_all(8)
	ss.set_content_margin_all(8)
	side.add_theme_stylebox_override("panel", ss)
	body.add_child(side)

	var svbox := VBoxContainer.new()
	svbox.add_theme_constant_override("separation", 4)
	side.add_child(svbox)

	_poi_name_lbl = Label.new()
	_poi_name_lbl.add_theme_font_size_override("font_size", 14)
	_poi_name_lbl.add_theme_color_override("font_color", Color(1.0, 0.90, 0.55))
	_poi_name_lbl.clip_text = true
	_poi_name_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	svbox.add_child(_poi_name_lbl)

	_poi_meta_lbl = Label.new()
	_poi_meta_lbl.add_theme_font_size_override("font_size", 11)
	_poi_meta_lbl.add_theme_color_override("font_color", Color(0.55, 0.85, 1.0))
	_poi_meta_lbl.clip_text = true
	_poi_meta_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	svbox.add_child(_poi_meta_lbl)

	_poi_desc_lbl = RichTextLabel.new()
	_poi_desc_lbl.bbcode_enabled = true
	_poi_desc_lbl.fit_content = false
	_poi_desc_lbl.scroll_active = true
	_poi_desc_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_poi_desc_lbl.size_flags_stretch_ratio = 0.55
	_poi_desc_lbl.custom_minimum_size = Vector2(0, 56)
	_poi_desc_lbl.add_theme_font_size_override("normal_font_size", 12)
	svbox.add_child(_poi_desc_lbl)

	var wp_row := HBoxContainer.new()
	wp_row.add_theme_constant_override("separation", 6)
	svbox.add_child(wp_row)

	_set_wp_btn = Button.new()
	_set_wp_btn.text = "Segnavia Qui"
	_set_wp_btn.focus_mode = Control.FOCUS_NONE
	_set_wp_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_set_wp_btn.custom_minimum_size = Vector2(0, 26)
	_set_wp_btn.add_theme_font_size_override("font_size", 11)
	_set_wp_btn.pressed.connect(_on_set_waypoint_pressed)
	wp_row.add_child(_set_wp_btn)

	_clear_wp_btn = Button.new()
	_clear_wp_btn.text = "Rimuovi"
	_clear_wp_btn.focus_mode = Control.FOCUS_NONE
	_clear_wp_btn.custom_minimum_size = Vector2(68, 26)
	_clear_wp_btn.add_theme_font_size_override("font_size", 11)
	_clear_wp_btn.pressed.connect(func(): GameManager.clear_waypoint(); SoundManager.play_ui_click())
	wp_row.add_child(_clear_wp_btn)

	_quest_wp_btn = Button.new()
	_quest_wp_btn.text = "★ Segna Obiettivo Attuale"
	_quest_wp_btn.focus_mode = Control.FOCUS_NONE
	_quest_wp_btn.custom_minimum_size = Vector2(0, 26)
	_quest_wp_btn.add_theme_font_size_override("font_size", 11)
	_quest_wp_btn.pressed.connect(_on_quest_waypoint_pressed)
	svbox.add_child(_quest_wp_btn)

	var lsep := HSeparator.new()
	svbox.add_child(lsep)

	var dir_lbl := Label.new()
	dir_lbl.text = "LUOGHI DEL BORGO"
	dir_lbl.add_theme_font_size_override("font_size", 11)
	dir_lbl.add_theme_color_override("font_color", Color(0.75, 0.80, 0.88))
	svbox.add_child(dir_lbl)

	var pscroll := ScrollContainer.new()
	pscroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pscroll.size_flags_stretch_ratio = 1.0
	pscroll.custom_minimum_size = Vector2(0, 48)
	pscroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	svbox.add_child(pscroll)

	_poi_quick_list = VBoxContainer.new()
	_poi_quick_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_poi_quick_list.add_theme_constant_override("separation", 3)
	pscroll.add_child(_poi_quick_list)

func _fit_to_viewport() -> void:
	if not is_instance_valid(_panel):
		return
	var vp := size
	if vp.x <= 8.0 or vp.y <= 8.0:
		vp = get_viewport_rect().size
	if vp.x <= 0.0 or vp.y <= 0.0:
		vp = Vector2(1280, 720)
	var w := clampf(vp.x - 36.0, 360.0, 1120.0)
	var h := clampf(vp.y - 36.0, 280.0, 620.0)
	_panel.custom_minimum_size = Vector2(w, h)
	_panel.size = Vector2(w, h)
	if is_instance_valid(_map_canvas):
		_map_canvas.queue_redraw()

func _on_canvas_zoom_changed(z: float) -> void:
	var pct := "%d%%" % int(roundf(z * 100.0))
	if is_instance_valid(_zoom_reset_btn):
		_zoom_reset_btn.text = pct
	if is_instance_valid(_zoom_info_lbl):
		_zoom_info_lbl.text = "Zoom: " + pct

func _set_view(view_id: String) -> void:
	current_view = view_id
	for k in _view_buttons:
		_view_buttons[k].set_pressed_no_signal(k == view_id)
	SoundManager.play_ui_click()
	_fit_to_viewport()
	if is_instance_valid(_map_canvas):
		_map_canvas.set_view_bounds(view_id)

func select_poi(poi_id: String) -> void:
	selected_poi_id = poi_id
	if is_instance_valid(_map_canvas):
		_map_canvas.selected_poi_id = poi_id
		_map_canvas.queue_redraw()
	_refresh_sidebar()

func _on_canvas_poi_clicked(poi_id: String) -> void:
	SoundManager.play_ui_click()
	select_poi(poi_id)

func _on_canvas_poi_double_clicked(poi_id: String) -> void:
	select_poi(poi_id)
	_on_set_waypoint_pressed()

func _on_set_waypoint_pressed() -> void:
	var poi := MapData.get_poi(selected_poi_id)
	if poi.is_empty():
		return
	GameManager.set_waypoint(poi["id"], poi["name"], poi["pos"])
	SoundManager.play_ui_success()
	EventBus.notification_posted.emit("Segnavia Impostato", "%s fissato sulla bussola HUD." % poi["name"], "info")
	_refresh_sidebar()

func _on_quest_waypoint_pressed() -> void:
	var rec_id := GameManager.get_recommended_quest_poi_id()
	var poi := MapData.get_poi(rec_id)
	if poi.is_empty():
		return
	select_poi(rec_id)
	GameManager.set_waypoint(poi["id"], poi["name"], poi["pos"])
	SoundManager.play_ui_success()
	EventBus.notification_posted.emit("Segnavia Obiettivo", "Puntato verso: %s" % poi["name"], "info")

func _refresh_quick_list() -> void:
	if not is_instance_valid(_poi_quick_list):
		return
	for ch in _poi_quick_list.get_children():
		ch.queue_free()
	var rec_id := GameManager.get_recommended_quest_poi_id()
	var wp_id := str(GameManager.active_waypoint.get("id", ""))
	for poi in MapData.get_pois():
		var pid: String = poi["id"]
		var btn := Button.new()
		var prefix := ""
		if pid == wp_id:
			prefix += "⚑ "
		if pid == rec_id:
			prefix += "★ "
		btn.text = prefix + str(poi["name"])
		btn.focus_mode = Control.FOCUS_NONE
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		btn.custom_minimum_size = Vector2(0, 26)
		btn.pressed.connect(func(): select_poi(pid); SoundManager.play_ui_click())
		_poi_quick_list.add_child(btn)

func _refresh_sidebar() -> void:
	if not is_instance_valid(_poi_name_lbl):
		return
	var poi := MapData.get_poi(selected_poi_id)
	if poi.is_empty():
		return
	_poi_name_lbl.text = str(poi["name"])
	_poi_name_lbl.tooltip_text = str(poi["name"])

	var dist_txt := ""
	if is_instance_valid(GameManager.player_node):
		var pp: Vector3 = GameManager.player_node.global_position
		var tp: Vector3 = poi["pos"]
		var d := Vector2(pp.x, pp.z).distance_to(Vector2(tp.x, tp.z))
		dist_txt = " · %d m" % int(roundf(d))
	_poi_meta_lbl.text = "%s%s" % [str(poi["district"]), dist_txt]
	_poi_meta_lbl.tooltip_text = _poi_meta_lbl.text

	var bb := "[b][color=#ffe688]%s[/color][/b]\n%s" % [str(poi["name"]), str(poi["desc"])]
	var rec_id := GameManager.get_recommended_quest_poi_id()
	if poi["id"] == rec_id:
		bb += "\n\n[color=#ffdd55]★ Consigliato per l'obiettivo attuale![/color]"
	if poi["id"] == "officina_bellini":
		var fac := ContractManager.get_factory_progress_summary()
		if bool(fac.get("completed", false)):
			bb += "\n[color=#55ee88]✔ Maxi-appalto completato (4/4 pilastri)[/color]"
		elif bool(fac.get("accepted", false)):
			bb += "\n[color=#66ccff]Sopralluogo: %d/4 · Pilastri: %d/4[/color]" % [int(fac["scouted_count"]), int(fac["pillars_done"])]
	elif poi["id"] == "coworking_ogr":
		if ContractManager.is_ogr_unlocked():
			bb += "\n[color=#55ee88]✔ Cancelli OGR APERTI · Bay 01 attiva (Ing. Andrea Viale)[/color]"
		else:
			bb += "\n[color=#ff8866]🔒 Cancello chiuso · Completa Via Po + Officina Bellini[/color]"
	_poi_desc_lbl.text = bb

	var wp_active := not GameManager.active_waypoint.is_empty()
	_clear_wp_btn.disabled = not wp_active
	var is_current_wp := wp_active and str(GameManager.active_waypoint.get("id", "")) == str(poi["id"])
	_set_wp_btn.text = "Segnavia Attivo ✔" if is_current_wp else "Segnavia Qui"
