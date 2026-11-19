extends Control
## WorldMapCanvas - Rendering 2D architettonico ad alta nitidezza di Borgo San Carlo, Parco Valentino, Valdocco & OGR Tech Hub.
## Supporta zoom centrato sul cursore (rotella / pulsanti), drag & pan fluido, e resize continuo in qualsiasi vista.

const MapData := preload("res://scripts/world/world_map_data.gd")

signal poi_clicked(poi_id: String)
signal poi_double_clicked(poi_id: String)
signal zoom_changed(zoom_val: float)

const MIN_ZOOM: float = 0.45
const MAX_ZOOM: float = 4.50

var selected_poi_id: String = "studio"
var hovered_poi_id: String = ""
var _view_bounds: Rect2 = MapData.WORLD_BOUNDS
var _zoom: float = 1.0
var _pan_world: Vector2 = Vector2.ZERO
var _dragging: bool = false
var _drag_moved: bool = false
var _press_pos: Vector2 = Vector2.ZERO
var _press_pan: Vector2 = Vector2.ZERO
var _last_click_id: String = ""
var _last_click_ms: int = 0

func _ready() -> void:
	clip_contents = true
	resized.connect(func():
		_clamp_pan()
		queue_redraw()
	)

func set_view_bounds(view_id: String, preserve_zoom: bool = false) -> void:
	match view_id:
		"miniera":
			_view_bounds = MapData.MINIERA_BOUNDS
		"sancarlo":
			_view_bounds = MapData.SAN_CARLO_BOUNDS
		"parco":
			_view_bounds = MapData.PARCO_BOUNDS
		"valdocco":
			_view_bounds = MapData.VALDOCCO_BOUNDS
		"mercato":
			_view_bounds = MapData.MERCATO_BOUNDS
		"borgopo":
			_view_bounds = MapData.BORGOPO_BOUNDS
		_:
			_view_bounds = MapData.WORLD_BOUNDS
	if not preserve_zoom:
		_zoom = 1.0
		_pan_world = Vector2.ZERO
	_clamp_pan()
	zoom_changed.emit(_zoom)
	queue_redraw()

func get_zoom() -> float:
	return _zoom

func get_pan_world() -> Vector2:
	return _pan_world

func zoom_at(pivot_canvas: Vector2, target_zoom: float) -> void:
	var new_zoom := clampf(target_zoom, MIN_ZOOM, MAX_ZOOM)
	if is_equal_approx(new_zoom, _zoom):
		return
	var world_pivot := canvas_to_world(pivot_canvas)
	_zoom = new_zoom
	var proj := get_projection()
	var sc := maxf(0.0001, float(proj["scale"]))
	var cc: Vector2 = proj["canvas_center"]
	var new_vc := world_pivot - (pivot_canvas - cc) / sc
	var base_center := _view_bounds.position + _view_bounds.size * 0.5
	_pan_world = new_vc - base_center
	_clamp_pan()
	zoom_changed.emit(_zoom)
	queue_redraw()

func zoom_in() -> void:
	zoom_at(size * 0.5, _zoom * 1.25)

func zoom_out() -> void:
	zoom_at(size * 0.5, _zoom / 1.25)

func reset_zoom() -> void:
	_zoom = 1.0
	_pan_world = Vector2.ZERO
	_clamp_pan()
	zoom_changed.emit(_zoom)
	queue_redraw()

func _clamp_pan() -> void:
	var base_center := _view_bounds.position + _view_bounds.size * 0.5
	var vc := base_center + _pan_world
	var safe := MapData.WORLD_BOUNDS.grow(24.0)
	vc.x = clampf(vc.x, safe.position.x, safe.end.x)
	vc.y = clampf(vc.y, safe.position.y, safe.end.y)
	_pan_world = vc - base_center

func get_projection() -> Dictionary:
	var s := size
	var pad := 16.0
	var avail_w := maxf(s.x - pad * 2.0, 40.0)
	var avail_h := maxf(s.y - pad * 2.0, 40.0)
	var base_scale := minf(avail_w / _view_bounds.size.x, avail_h / _view_bounds.size.y)
	var sc := base_scale * _zoom
	var view_center := _view_bounds.position + _view_bounds.size * 0.5 + _pan_world
	var canvas_center := s * 0.5
	return {"scale": sc, "base_scale": base_scale, "view_center": view_center, "canvas_center": canvas_center}

func world_to_canvas(world_xz: Vector2) -> Vector2:
	var proj := get_projection()
	var sc: float = proj["scale"]
	var vc: Vector2 = proj["view_center"]
	var cc: Vector2 = proj["canvas_center"]
	return cc + (world_xz - vc) * sc

func canvas_to_world(canvas_pt: Vector2) -> Vector2:
	var proj := get_projection()
	var sc := maxf(0.0001, float(proj["scale"]))
	var vc: Vector2 = proj["view_center"]
	var cc: Vector2 = proj["canvas_center"]
	return vc + (canvas_pt - cc) / sc

func world_rect_to_canvas(r: Rect2) -> Rect2:
	var tl := world_to_canvas(r.position)
	var sc := float(get_projection()["scale"])
	return Rect2(tl, r.size * sc)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_at(event.position, _zoom * 1.15)
			accept_event()
			return
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_at(event.position, _zoom / 1.15)
			accept_event()
			return
		elif event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_MIDDLE or event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				_dragging = true
				_drag_moved = false
				_press_pos = event.position
				_press_pan = _pan_world
			else:
				var was_click: bool = _dragging and not _drag_moved and event.button_index == MOUSE_BUTTON_LEFT
				_dragging = false
				_drag_moved = false
				mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if hovered_poi_id != "" else Control.CURSOR_ARROW
				if was_click:
					var hit_id := _find_poi_at_point(event.position)
					if hit_id != "":
						var now_ms := Time.get_ticks_msec()
						if hit_id == _last_click_id and (now_ms - _last_click_ms) < 420:
							poi_double_clicked.emit(hit_id)
						else:
							poi_clicked.emit(hit_id)
						_last_click_id = hit_id
						_last_click_ms = now_ms
	elif event is InputEventMouseMotion:
		if _dragging:
			var delta_c: Vector2 = event.position - _press_pos
			if delta_c.length() > 6.0:
				_drag_moved = true
			if _drag_moved:
				var sc := maxf(0.0001, float(get_projection()["scale"]))
				_pan_world = _press_pan - delta_c / sc
				_clamp_pan()
				mouse_default_cursor_shape = Control.CURSOR_DRAG
				queue_redraw()
				return
		var new_hover := _find_poi_at_point(event.position)
		if new_hover != hovered_poi_id:
			hovered_poi_id = new_hover
			mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if hovered_poi_id != "" else Control.CURSOR_ARROW
			queue_redraw()

func _find_poi_at_point(pt: Vector2) -> String:
	var sc := float(get_projection()["scale"])
	var best_id := ""
	var best_d := 999999.0
	for poi in MapData.get_pois():
		var p3: Vector3 = poi["pos"]
		var c := world_to_canvas(Vector2(p3.x, p3.z))
		var fp: Vector2 = poi["footprint"]
		var hit_r := maxf(16.0, maxf(fp.x, fp.y) * sc * 0.55)
		var d := pt.distance_to(c)
		if d <= hit_r and d < best_d:
			best_d = d
			best_id = str(poi["id"])
	return best_id

func _draw() -> void:
	if size.x <= 4.0 or size.y <= 4.0:
		return
	var font: Font = ThemeDB.fallback_font
	var proj := get_projection()
	var sc: float = proj["scale"]

	draw_rect(Rect2(Vector2.ZERO, size), Color(0.06, 0.08, 0.13, 1.0))

	# Architectural 10m grid spanning visible canvas
	var w_tl := canvas_to_world(Vector2.ZERO)
	var w_br := canvas_to_world(size)
	var gx0 := int(floor(minf(w_tl.x, w_br.x) / 10.0)) * 10
	var gx1 := int(ceil(maxf(w_tl.x, w_br.x) / 10.0)) * 10
	for gx in range(gx0, gx1 + 1, 10):
		var x_pos := world_to_canvas(Vector2(float(gx), 0.0)).x
		draw_line(Vector2(x_pos, 0), Vector2(x_pos, size.y), Color(1, 1, 1, 0.035), 1.0)
	var gz0 := int(floor(minf(w_tl.y, w_br.y) / 10.0)) * 10
	var gz1 := int(ceil(maxf(w_tl.y, w_br.y) / 10.0)) * 10
	for gz in range(gz0, gz1 + 1, 10):
		var y_pos := world_to_canvas(Vector2(0.0, float(gz))).y
		draw_line(Vector2(0, y_pos), Vector2(size.x, y_pos), Color(1, 1, 1, 0.035), 1.0)

	var geo := MapData.get_roads_and_zones()

	# 1. Grass districts
	for gr in geo["grass"]:
		var r := world_rect_to_canvas(gr)
		draw_rect(r, Color(0.11, 0.21, 0.15, 0.92), true)
		draw_rect(r, Color(0.18, 0.34, 0.23, 0.9), false, 1.5)

	# 1b. Quarry yard & Gravel paths (Miniera Alpina + Parco)
	if geo.has("quarry"):
		for qr in geo["quarry"]:
			var qrect := world_rect_to_canvas(qr)
			draw_rect(qrect, Color(0.28, 0.24, 0.19, 0.95), true)
			draw_rect(qrect, Color(0.68, 0.56, 0.34, 0.90), false, 1.6)
	if geo.has("gravel"):
		for gv in geo["gravel"]:
			var gvr := world_rect_to_canvas(gv)
			draw_rect(gvr, Color(0.40, 0.37, 0.32, 0.92), true)
			draw_rect(gvr, Color(0.56, 0.52, 0.45, 0.72), false, 1.0)

	# 2. Cobblestones & plazas
	for cb in geo["cobble"]:
		var cr := world_rect_to_canvas(cb)
		draw_rect(cr, Color(0.32, 0.30, 0.28, 0.95), true)
		draw_rect(cr, Color(0.46, 0.44, 0.40, 0.8), false, 1.0)

	# 2b. Stone slabs & OGR concrete nave floor
	if geo.has("slabs"):
		for sl in geo["slabs"]:
			var sr := world_rect_to_canvas(sl)
			draw_rect(sr, Color(0.28, 0.31, 0.36, 0.92), true)
			draw_rect(sr, Color(0.46, 0.56, 0.66, 0.85), false, 1.1)

	# 2c. Po River & Wooden Molo Pier
	if geo.has("rivers"):
		for rv in geo["rivers"]:
			var rr := world_rect_to_canvas(rv)
			draw_rect(rr, Color(0.10, 0.36, 0.58, 0.88), true)
			draw_rect(rr, Color(0.28, 0.64, 0.88, 0.85), false, 1.3)
	if geo.has("wood_piers"):
		for wp_r in geo["wood_piers"]:
			var pr_w := world_rect_to_canvas(wp_r)
			draw_rect(pr_w, Color(0.48, 0.33, 0.20, 0.96), true)
			draw_rect(pr_w, Color(0.76, 0.58, 0.38, 0.9), false, 1.2)

	# 3. Asphalt roads & centerline
	for asp in geo["asphalt"]:
		var ar := world_rect_to_canvas(asp)
		draw_rect(ar, Color(0.19, 0.22, 0.27, 0.98), true)
		draw_rect(ar, Color(0.36, 0.40, 0.48, 0.9), false, 1.2)
	for rx in range(25, 61, 4):
		var a := world_to_canvas(Vector2(float(rx), 28.0))
		var b := world_to_canvas(Vector2(float(rx) + 2.0, 28.0))
		draw_line(a, b, Color(0.95, 0.88, 0.55, 0.65), maxf(1.5, 0.22 * sc))
	for rx_s in range(-19, 53, 4):
		if rx_s >= 5 and rx_s <= 11:
			continue
		var a_s := world_to_canvas(Vector2(float(rx_s), 58.0))
		var b_s := world_to_canvas(Vector2(float(rx_s) + 1.9, 58.0))
		draw_line(a_s, b_s, Color(0.95, 0.88, 0.55, 0.65), maxf(1.5, 0.22 * sc))

	# 3b. Mine Cart Rail Track (Galleria 01)
	if geo.has("rails"):
		for rseg in geo["rails"]:
			var ra := world_to_canvas(rseg[0])
			var rb := world_to_canvas(rseg[1])
			draw_line(ra, rb, Color(0.84, 0.88, 0.94, 0.92), maxf(2.0, 0.55 * sc))
			draw_dashed_line(ra, rb, Color(0.36, 0.24, 0.14, 0.95), maxf(3.0, 0.95 * sc), maxf(3.0, 0.55 * sc))

	# 4. Houses (residential & quarry buildings)
	for hr in geo["houses"]:
		var r := world_rect_to_canvas(hr)
		draw_rect(r, Color(0.18, 0.22, 0.30, 0.95), true)
		draw_rect(r, Color(0.30, 0.36, 0.46, 0.85), false, 1.2)

	# 5. Perimeter walls & Parco->Miniera Archway indicator
	for wseg in geo["walls"]:
		var p1 := world_to_canvas(wseg[0])
		var p2 := world_to_canvas(wseg[1])
		draw_line(p1, p2, Color(0.48, 0.54, 0.64, 0.9), maxf(2.0, 0.4 * sc))
	var mg_a := world_to_canvas(Vector2(-44.5, 12.0))
	var mg_b := world_to_canvas(Vector2(-38.5, 12.0))
	draw_line(mg_a, mg_b, Color(0.98, 0.80, 0.30, 0.95), maxf(2.2, 0.42 * sc))

	# 5b. OGR Bay 01 vs Closed Pods floor detail + Gate line
	var bay1 := world_rect_to_canvas(Rect2(Vector2(99.5, 9.0), Vector2(6.3, 5.5)))
	draw_rect(bay1, Color(0.22, 0.65, 0.52, 0.32), true)
	draw_rect(bay1, Color(0.35, 0.95, 0.72, 0.85), false, 1.2)
	for closed_pod in [
		Rect2(Vector2(100.9, -9.1), Vector2(6.3, 5.5)),
		Rect2(Vector2(109.3, -9.1), Vector2(6.3, 5.5)),
		Rect2(Vector2(113.5, 9.0), Vector2(6.3, 5.5))
	]:
		var pr := world_rect_to_canvas(closed_pod)
		draw_rect(pr, Color(0.38, 0.22, 0.24, 0.35), true)
		draw_rect(pr, Color(0.85, 0.46, 0.38, 0.75), false, 1.0)
	var gate_a := world_to_canvas(Vector2(96.15, 0.35))
	var gate_b := world_to_canvas(Vector2(96.15, 5.15))
	var ogr_open := is_instance_valid(ContractManager) and ContractManager.is_ogr_unlocked()
	draw_line(gate_a, gate_b, Color(0.35, 0.98, 0.68, 0.95) if ogr_open else Color(1.0, 0.42, 0.34, 0.95), maxf(2.5, 0.45 * sc))

	# 6. Water fountain, well & pond
	for wc in geo["water_circles"]:
		var cpos := world_to_canvas(wc["pos"])
		var cr := maxf(4.0, float(wc["r"]) * sc)
		draw_circle(cpos, cr, Color(0.24, 0.68, 0.92, 0.85))
		draw_arc(cpos, cr + 2.0, 0.0, TAU, 24, Color(0.60, 0.88, 1.0, 0.7), 1.2)

	# 7. District Watermarks
	_draw_label_centered(font, world_to_canvas(Vector2(-47.0, -43.5)), "MINIERA ALPINA · VAL DI SUSA", 11, Color(1.0, 0.84, 0.45, 0.88))
	_draw_label_centered(font, world_to_canvas(Vector2(-40.0, 44.0)), "PARCO VALENTINO", 11, Color(0.55, 0.90, 0.65, 0.75))
	_draw_label_centered(font, world_to_canvas(Vector2(-1.0, -11.4)), "BORGO SAN CARLO", 12, Color(0.65, 0.78, 0.88, 0.72))
	_draw_label_centered(font, world_to_canvas(Vector2(43.0, 20.8)), "VIALE EST", 11, Color(0.75, 0.78, 0.84, 0.6))
	_draw_label_centered(font, world_to_canvas(Vector2(76.0, 16.2)), "BORGO VALDOCCO", 12, Color(0.95, 0.84, 0.45, 0.7))
	_draw_label_centered(font, world_to_canvas(Vector2(92.0, -12.0)), "MERCATO NORD · OGR TECH HUB", 11, Color(0.62, 0.92, 1.0, 0.82))
	_draw_label_centered(font, world_to_canvas(Vector2(36.0, 62.8)), "BORGO PO · LUNGO PO", 11, Color(0.60, 0.92, 1.0, 0.80))
	_draw_label_centered(font, world_to_canvas(Vector2(-6.0, 71.5)), "FIUME PO", 12, Color(0.72, 0.92, 1.0, 0.88))

	# 8. Waypoint path from player
	var wp := GameManager.active_waypoint
	var wp_id := str(wp.get("id", ""))
	if not wp.is_empty():
		var wp3: Vector3 = wp.get("pos", Vector3.ZERO)
		var wp2 := world_to_canvas(Vector2(wp3.x, wp3.z))
		if is_instance_valid(GameManager.player_node):
			var pp3: Vector3 = GameManager.player_node.global_position
			draw_dashed_line(
				world_to_canvas(Vector2(pp3.x, pp3.z)),
				wp2,
				Color(0.32, 0.92, 1.0, 0.82), 2.0, 6.0
			)
		if wp_id.begins_with("sidejob_"):
			draw_circle(wp2, 5.5, Color(0.24, 0.96, 0.84, 0.9))
			draw_arc(wp2, 9.5, 0.0, TAU, 24, Color(0.24, 0.96, 0.84, 0.85), 2.0)
			_draw_label_centered(font, wp2 + Vector2(0, -14.0), "⚑ " + str(wp.get("name", "Tappa")), 10, Color(0.55, 1.0, 0.90))

	# 9. Interactive POIs
	var rec_id := GameManager.get_recommended_quest_poi_id()
	var pulse := 0.5 + 0.5 * sin(float(Time.get_ticks_msec()) * 0.006)
	for poi in MapData.get_pois():
		var pid: String = poi["id"]
		var p3: Vector3 = poi["pos"]
		var c := world_to_canvas(Vector2(p3.x, p3.z))
		var fp: Vector2 = poi["footprint"]
		var col: Color = poi["color"]

		var bw := maxf(10.0, fp.x * sc)
		var bh := maxf(10.0, fp.y * sc)
		var brect := Rect2(c - Vector2(bw, bh) * 0.5, Vector2(bw, bh))
		var fill_alpha := 0.22 if pid == "miniera_alpina" else (0.30 if pid == "coworking_ogr" else 0.35)
		draw_rect(brect, Color(col.r, col.g, col.b, fill_alpha), true)
		draw_rect(brect, col, false, 2.0 if (pid == selected_poi_id or pid == hovered_poi_id) else 1.3)

		var dot_r := 6.5 if (pid == selected_poi_id or pid == hovered_poi_id) else 5.0
		draw_circle(c, dot_r, col)
		draw_circle(c, dot_r * 0.45, Color(0.98, 0.99, 1.0))

		if pid == rec_id:
			var ring_r := dot_r + 4.0 + pulse * 4.5
			draw_arc(c, ring_r, 0.0, TAU, 28, Color(1.0, 0.85, 0.25, 0.5 + 0.5 * pulse), 2.2)

		if pid == wp_id:
			draw_arc(c, dot_r + 7.5, 0.0, TAU, 24, Color(0.30, 0.96, 1.0, 0.95), 2.0)

		if pid == selected_poi_id:
			draw_arc(c, dot_r + 3.0, 0.0, TAU, 24, Color.WHITE, 1.6)

		var tag_txt := str(poi["short"])
		if pid == rec_id:
			tag_txt = "★ " + tag_txt
		if pid == wp_id:
			tag_txt = "⚑ " + tag_txt
		var ldir := str(poi.get("label_dir", "bottom"))
		if ldir == "top":
			_draw_label_centered(font, c + Vector2(0, -bh * 0.5 - 10.0), tag_txt, 10, Color(0.95, 0.96, 1.0))
		elif ldir == "right":
			var lp := c + Vector2(bw * 0.5 + 8.0, 4.0)
			draw_string(font, lp + Vector2(1, 1), tag_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0, 0, 0, 0.78))
			draw_string(font, lp, tag_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.95, 0.96, 1.0))
		elif ldir == "left":
			var sz := font.get_string_size(tag_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 10)
			var lp := c + Vector2(-bw * 0.5 - 8.0 - sz.x, 4.0)
			draw_string(font, lp + Vector2(1, 1), tag_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0, 0, 0, 0.78))
			draw_string(font, lp, tag_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.95, 0.96, 1.0))
		else:
			_draw_label_centered(font, c + Vector2(0, bh * 0.5 + 12.0), tag_txt, 10, Color(0.95, 0.96, 1.0))

	# 10. Live Player Position & FOV Cone
	if is_instance_valid(GameManager.player_node):
		var pl: Node3D = GameManager.player_node
		var pc := world_to_canvas(Vector2(pl.global_position.x, pl.global_position.z))
		var fwd := -pl.global_transform.basis.z
		var dir2 := Vector2(fwd.x, fwd.z)
		if dir2.length_squared() < 0.001:
			dir2 = Vector2(0.0, -1.0)
		dir2 = dir2.normalized()
		var ang := dir2.angle()

		var cone_len := maxf(22.0, 4.5 * sc)
		var spread := deg_to_rad(28.0)
		var pts := PackedVector2Array([
			pc,
			pc + Vector2.from_angle(ang - spread) * cone_len,
			pc + Vector2.from_angle(ang + spread) * cone_len
		])
		draw_colored_polygon(pts, Color(0.30, 0.95, 1.0, 0.22))

		var tip := pc + dir2 * 10.5
		var left_v := pc + Vector2.from_angle(ang + deg_to_rad(142.0)) * 8.0
		var right_v := pc + Vector2.from_angle(ang - deg_to_rad(142.0)) * 8.0
		draw_colored_polygon(PackedVector2Array([tip, left_v, right_v]), Color(0.25, 0.98, 1.0))
		draw_polyline(PackedVector2Array([tip, left_v, right_v, tip]), Color(0.05, 0.10, 0.16), 1.6)

	# 11. Compass & Scale Bar + Zoom pill
	var comp := Vector2(size.x - 28.0, 26.0)
	draw_circle(comp, 16.0, Color(0.08, 0.10, 0.15, 0.85))
	draw_arc(comp, 16.0, 0.0, TAU, 24, Color(0.45, 0.55, 0.70, 0.8), 1.2)
	_draw_label_centered(font, comp + Vector2(0, -10), "N", 10, Color(1.0, 0.84, 0.35))
	_draw_label_centered(font, comp + Vector2(11, 3), "E", 9, Color(0.8, 0.85, 0.9))
	_draw_label_centered(font, comp + Vector2(0, 13), "S", 9, Color(0.8, 0.85, 0.9))
	_draw_label_centered(font, comp + Vector2(-11, 3), "O", 9, Color(0.8, 0.85, 0.9))

	var bar_len := clampf(10.0 * sc, 24.0, 140.0)
	var meters := roundi(bar_len / maxf(0.01, sc))
	var bar_p := Vector2(14.0, size.y - 14.0)
	draw_line(bar_p, bar_p + Vector2(bar_len, 0), Color(0.85, 0.90, 0.96, 0.8), 2.0)
	draw_line(bar_p + Vector2(0, -4), bar_p + Vector2(0, 4), Color(0.85, 0.90, 0.96, 0.8), 1.5)
	draw_line(bar_p + Vector2(bar_len, -4), bar_p + Vector2(bar_len, 4), Color(0.85, 0.90, 0.96, 0.8), 1.5)
	draw_string(font, bar_p + Vector2(0, -6), "%d m · Zoom %d%%" % [meters, int(roundf(_zoom * 100.0))], HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.85, 0.90, 0.96, 0.88))

func _draw_label_centered(font: Font, pos: Vector2, txt: String, fsize: int, col: Color) -> void:
	if font == null or txt == "":
		return
	var sz := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize)
	var p := pos + Vector2(-sz.x * 0.5, sz.y * 0.35)
	draw_string(font, p + Vector2(1, 1), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize, Color(0, 0, 0, 0.78))
	draw_string(font, p, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize, col)
