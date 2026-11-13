extends Control
## WorldMapMenu - Mappa interattiva di Borgo San Carlo, Viale Est, Borgo Valdocco e Officina Bellini [CapsLock / M].
## Mostra in tempo reale posizione e direzione del giocatore, obiettivi e segnavia (waypoint) per l'HUD.

const MapData := preload("res://scripts/world/world_map_data.gd")
const MapCanvasScript := preload("res://scripts/ui/world_map_canvas.gd")

var current_view: String = "all" # "all" | "sancarlo" | "valdocco"
var selected_poi_id: String = "studio"

var _panel: PanelContainer
var _close_btn: Button
var _view_buttons: Dictionary = {}
var _map_canvas: Control
var _poi_name_lbl: Label
var _poi_meta_lbl: Label
var _poi_desc_lbl: RichTextLabel
var _set_wp_btn: Button
var _clear_wp_btn: Button
var _quest_wp_btn: Button
var _poi_quick_list: VBoxContainer

func _ready() -> void:
	_build_ui()
	EventBus.waypoint_changed.connect(func(_wp): _refresh_quick_list(); _refresh_sidebar(); if is_instance_valid(_map_canvas): _map_canvas.queue_redraw())
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
	ps.set_content_margin_all(14)
	_panel.add_theme_stylebox_override("panel", ps)
	center.add_child(_panel)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	_panel.add_child(root)

	# Header
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	root.add_child(header)

	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_box)

	var title := Label.new()
	title.text = "MAPPA DEL TERRITORIO — TORINO"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.48))
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title_box.add_child(title)

	var sub := Label.new()
	sub.text = "Clicca un luogo per i dettagli o per impostare un segnavia (bussola HUD)"
	sub.add_theme_font_size_override("font_size", 11)
	sub.add_theme_color_override("font_color", Color(0.75, 0.80, 0.88))
	sub.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title_box.add_child(sub)

	# View Filter buttons
	var views := [
		["all", "Tutto"],
		["sancarlo", "San Carlo"],
		["valdocco", "Valdocco"]
	]
	for v in views:
		var vid: String = v[0]
		var vb := Button.new()
		vb.text = v[1]
		vb.toggle_mode = true
		vb.custom_minimum_size = Vector2(76, 30)
		vb.pressed.connect(func(): _set_view(vid))
		header.add_child(vb)
		_view_buttons[vid] = vb
	_view_buttons["all"].button_pressed = true

	_close_btn = Button.new()
	_close_btn.text = "Chiudi [Caps]"
	_close_btn.custom_minimum_size = Vector2(102, 30)
	_close_btn.pressed.connect(close_map)
	header.add_child(_close_btn)

	var sep := HSeparator.new()
	root.add_child(sep)

	# Body split: Interactive Canvas + Inspector/Directory Sidebar
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 10)
	root.add_child(body)

	var canvas_frame := PanelContainer.new()
	canvas_frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	canvas_frame.size_flags_vertical = Control.SIZE_EXPAND_FILL
	canvas_frame.size_flags_stretch_ratio = 2.4
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
	canvas_frame.add_child(_map_canvas)

	# Right Sidebar
	var side := PanelContainer.new()
	side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	side.size_flags_vertical = Control.SIZE_EXPAND_FILL
	side.size_flags_stretch_ratio = 1.0
	side.custom_minimum_size = Vector2(215, 0)
	var ss := StyleBoxFlat.new()
	ss.bg_color = Color(0.13, 0.16, 0.22, 0.96)
	ss.border_color = Color(0.24, 0.30, 0.42, 0.8)
	ss.set_border_width_all(1)
	ss.set_corner_radius_all(8)
	ss.set_content_margin_all(10)
	side.add_theme_stylebox_override("panel", ss)
	body.add_child(side)

	var svbox := VBoxContainer.new()
	svbox.add_theme_constant_override("separation", 6)
	side.add_child(svbox)

	_poi_name_lbl = Label.new()
	_poi_name_lbl.add_theme_font_size_override("font_size", 15)
	_poi_name_lbl.add_theme_color_override("font_color", Color(1.0, 0.90, 0.55))
	_poi_name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	svbox.add_child(_poi_name_lbl)

	_poi_meta_lbl = Label.new()
	_poi_meta_lbl.add_theme_font_size_override("font_size", 11)
	_poi_meta_lbl.add_theme_color_override("font_color", Color(0.55, 0.85, 1.0))
	_poi_meta_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	svbox.add_child(_poi_meta_lbl)

	_poi_desc_lbl = RichTextLabel.new()
	_poi_desc_lbl.bbcode_enabled = true
	_poi_desc_lbl.custom_minimum_size = Vector2(0, 72)
	_poi_desc_lbl.add_theme_font_size_override("normal_font_size", 12)
	svbox.add_child(_poi_desc_lbl)

	var wp_row := HBoxContainer.new()
	wp_row.add_theme_constant_override("separation", 6)
	svbox.add_child(wp_row)

	_set_wp_btn = Button.new()
	_set_wp_btn.text = "Segnavia Qui"
	_set_wp_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_set_wp_btn.custom_minimum_size = Vector2(0, 28)
	_set_wp_btn.pressed.connect(_on_set_waypoint_pressed)
	wp_row.add_child(_set_wp_btn)

	_clear_wp_btn = Button.new()
	_clear_wp_btn.text = "Rimuovi"
	_clear_wp_btn.custom_minimum_size = Vector2(72, 28)
	_clear_wp_btn.pressed.connect(func(): GameManager.clear_waypoint(); SoundManager.play_ui_click())
	wp_row.add_child(_clear_wp_btn)

	_quest_wp_btn = Button.new()
	_quest_wp_btn.text = "★ Segna Obiettivo Attuale"
	_quest_wp_btn.custom_minimum_size = Vector2(0, 28)
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
	pscroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	svbox.add_child(pscroll)

	_poi_quick_list = VBoxContainer.new()
	_poi_quick_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_poi_quick_list.add_theme_constant_override("separation", 4)
	pscroll.add_child(_poi_quick_list)

func _fit_to_viewport() -> void:
	if not is_instance_valid(_panel):
		return
	var vp := get_viewport_rect().size
	if vp.x <= 0 or vp.y <= 0:
		vp = Vector2(1280, 720)
	var w := clampf(vp.x - 36.0, 360.0, 1040.0)
	var h := clampf(vp.y - 36.0, 280.0, 560.0)
	_panel.custom_minimum_size = Vector2(w, h)
	_panel.size = Vector2(w, h)

func _set_view(view_id: String) -> void:
	current_view = view_id
	for k in _view_buttons:
		_view_buttons[k].button_pressed = (k == view_id)
	SoundManager.play_ui_click()
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

	var dist_txt := ""
	if is_instance_valid(GameManager.player_node):
		var pp: Vector3 = GameManager.player_node.global_position
		var tp: Vector3 = poi["pos"]
		var d := Vector2(pp.x, pp.z).distance_to(Vector2(tp.x, tp.z))
		dist_txt = " · %d m" % int(roundf(d))
	_poi_meta_lbl.text = "%s%s" % [str(poi["district"]), dist_txt]

	var bb := str(poi["desc"])
	var rec_id := GameManager.get_recommended_quest_poi_id()
	if poi["id"] == rec_id:
		bb += "\n\n[color=#ffdd55]★ Consigliato per l'obiettivo attuale![/color]"
	if poi["id"] == "officina_bellini":
		var fac := ContractManager.get_factory_progress_summary()
		if bool(fac.get("completed", false)):
			bb += "\n[color=#55ee88]✔ Maxi-appalto completato (4/4 pilastri)[/color]"
		elif bool(fac.get("accepted", false)):
			bb += "\n[color=#66ccff]Sopralluogo: %d/4 · Pilastri: %d/4[/color]" % [int(fac["scouted_count"]), int(fac["pillars_done"])]
	_poi_desc_lbl.text = bb

	var wp_active := not GameManager.active_waypoint.is_empty()
	_clear_wp_btn.disabled = not wp_active
	var is_current_wp := wp_active and str(GameManager.active_waypoint.get("id", "")) == str(poi["id"])
	_set_wp_btn.text = "Segnavia Attivo ✔" if is_current_wp else "Segnavia Qui"
