extends Control
## WorldMapCanvas - Rendering 2D architettonico ad alta nitidezza di Borgo San Carlo & Borgo Valdocco.

const MapData := preload("res://scripts/world/world_map_data.gd")

signal poi_clicked(poi_id: String)
signal poi_double_clicked(poi_id: String)

var selected_poi_id: String = "studio"
var hovered_poi_id: String = ""
var _view_bounds: Rect2 = MapData.WORLD_BOUNDS
var _last_click_id: String = ""
var _last_click_ms: int = 0

func set_view_bounds(view_id: String) -> void:
	match view_id:
		"sancarlo":
			_view_bounds = MapData.SAN_CARLO_BOUNDS
		"valdocco":
			_view_bounds = MapData.VALDOCCO_BOUNDS
		_:
			_view_bounds = MapData.WORLD_BOUNDS
	queue_redraw()

func get_projection() -> Dictionary:
	var s := size
	var pad := 16.0
	var avail_w := maxf(s.x - pad * 2.0, 40.0)
	var avail_h := maxf(s.y - pad * 2.0, 40.0)
	var scale_val := minf(avail_w / _view_bounds.size.x, avail_h / _view_bounds.size.y)
	var drawn_w := _view_bounds.size.x * scale_val
	var drawn_h := _view_bounds.size.y * scale_val
	var ox := (s.x - drawn_w) * 0.5
	var oy := (s.y - drawn_h) * 0.5
	return {"scale": scale_val, "origin": Vector2(ox, oy)}

func world_to_canvas(world_xz: Vector2) -> Vector2:
	var proj := get_projection()
	var sc: float = proj["scale"]
	var org: Vector2 = proj["origin"]
	return org + (world_xz - _view_bounds.position) * sc

func world_rect_to_canvas(r: Rect2) -> Rect2:
	var tl := world_to_canvas(r.position)
	var sc := float(get_projection()["scale"])
	return Rect2(tl, r.size * sc)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var new_hover := _find_poi_at_point(event.position)
		if new_hover != hovered_poi_id:
			hovered_poi_id = new_hover
			mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if hovered_poi_id != "" else Control.CURSOR_ARROW
			queue_redraw()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var hit_id := _find_poi_at_point(event.position)
		if hit_id != "":
			var now_ms := Time.get_ticks_msec()
			if hit_id == _last_click_id and (now_ms - _last_click_ms) < 420:
				poi_double_clicked.emit(hit_id)
			else:
				poi_clicked.emit(hit_id)
			_last_click_id = hit_id
			_last_click_ms = now_ms

func _find_poi_at_point(pt: Vector2) -> String:
	var sc := float(get_projection()["scale"])
	var best_id := ""
	var best_d := 999999.0
	for poi in MapData.get_pois():
		var p3: Vector3 = poi["pos"]
		var c := world_to_canvas(Vector2(p3.x, p3.z))
		var fp: Vector2 = poi["footprint"]
		var hit_r := maxf(16.0, maxf(fp.x, fp.y) * sc * 0.65)
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

	# Clip drawing inside canvas bounds
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.06, 0.08, 0.13, 1.0))

	# Subtle 10m architectural grid
	var gx0 := int(floor(_view_bounds.position.x / 10.0)) * 10
	var gx1 := int(ceil(_view_bounds.end.x / 10.0)) * 10
	for gx in range(gx0, gx1 + 1, 10):
		var x_pos := world_to_canvas(Vector2(float(gx), _view_bounds.position.y)).x
		draw_line(Vector2(x_pos, 0), Vector2(x_pos, size.y), Color(1, 1, 1, 0.035), 1.0)
	var gz0 := int(floor(_view_bounds.position.y / 10.0)) * 10
	var gz1 := int(ceil(_view_bounds.end.y / 10.0)) * 10
	for gz in range(gz0, gz1 + 1, 10):
		var y_pos := world_to_canvas(Vector2(_view_bounds.position.x, float(gz))).y
		draw_line(Vector2(0, y_pos), Vector2(size.x, y_pos), Color(1, 1, 1, 0.035), 1.0)

	var geo := MapData.get_roads_and_zones()

	# 1. Grass districts
	for gr in geo["grass"]:
		var r := world_rect_to_canvas(gr)
		draw_rect(r, Color(0.11, 0.21, 0.15, 0.92), true)
		draw_rect(r, Color(0.18, 0.34, 0.23, 0.9), false, 1.5)

	# 2. Cobblestones & plazas
	for cb in geo["cobble"]:
		var cr := world_rect_to_canvas(cb)
		draw_rect(cr, Color(0.32, 0.30, 0.28, 0.95), true)
		draw_rect(cr, Color(0.46, 0.44, 0.40, 0.8), false, 1.0)

	# 3. Asphalt roads & centerline
	for asp in geo["asphalt"]:
		var ar := world_rect_to_canvas(asp)
		draw_rect(ar, Color(0.19, 0.22, 0.27, 0.98), true)
		draw_rect(ar, Color(0.36, 0.40, 0.48, 0.9), false, 1.2)
	for rx in range(25, 61, 4):
		var a := world_to_canvas(Vector2(float(rx), 28.0))
		var b := world_to_canvas(Vector2(float(rx) + 2.0, 28.0))
		draw_line(a, b, Color(0.95, 0.88, 0.55, 0.65), maxf(1.5, 0.22 * sc))

	# 4. Houses (residential context blocks)
	for hr in geo["houses"]:
		var r := world_rect_to_canvas(hr)
		draw_rect(r, Color(0.18, 0.22, 0.30, 0.95), true)
		draw_rect(r, Color(0.30, 0.36, 0.46, 0.85), false, 1.2)

	# 5. Perimeter walls
	for wseg in geo["walls"]:
		var p1 := world_to_canvas(wseg[0])
		var p2 := world_to_canvas(wseg[1])
		draw_line(p1, p2, Color(0.48, 0.54, 0.64, 0.9), maxf(2.0, 0.4 * sc))

	# 6. Water fountain & stone well
	for wc in geo["water_circles"]:
		var cpos := world_to_canvas(wc["pos"])
		var cr := maxf(4.0, float(wc["r"]) * sc)
		draw_circle(cpos, cr, Color(0.24, 0.68, 0.92, 0.85))
		draw_arc(cpos, cr + 2.0, 0.0, TAU, 24, Color(0.60, 0.88, 1.0, 0.7), 1.2)

	# 7. District Watermarks
	_draw_label_centered(font, world_to_canvas(Vector2(-1.0, -5.5)), "BORGO SAN CARLO", 12, Color(0.65, 0.78, 0.88, 0.65))
	_draw_label_centered(font, world_to_canvas(Vector2(43.0, 20.8)), "VIALE EST", 11, Color(0.75, 0.78, 0.84, 0.6))
	_draw_label_centered(font, world_to_canvas(Vector2(76.0, 16.0)), "BORGO VALDOCCO", 12, Color(0.95, 0.84, 0.45, 0.7))

	# 8. Waypoint path from player
	var wp := GameManager.active_waypoint
	var wp_id := str(wp.get("id", ""))
	if not wp.is_empty() and is_instance_valid(GameManager.player_node):
		var pp3: Vector3 = GameManager.player_node.global_position
		var wp3: Vector3 = wp.get("pos", Vector3.ZERO)
		draw_dashed_line(
			world_to_canvas(Vector2(pp3.x, pp3.z)),
			world_to_canvas(Vector2(wp3.x, wp3.z)),
			Color(0.32, 0.92, 1.0, 0.82), 2.0, 6.0
		)

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
		draw_rect(brect, Color(col.r, col.g, col.b, 0.35), true)
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

		# FOV Cone
		var cone_len := maxf(22.0, 4.5 * sc)
		var spread := deg_to_rad(28.0)
		var pts := PackedVector2Array([
			pc,
			pc + Vector2.from_angle(ang - spread) * cone_len,
			pc + Vector2.from_angle(ang + spread) * cone_len
		])
		draw_colored_polygon(pts, Color(0.30, 0.95, 1.0, 0.22))

		# Player arrow triangle
		var tip := pc + dir2 * 10.5
		var left_v := pc + Vector2.from_angle(ang + deg_to_rad(142.0)) * 8.0
		var right_v := pc + Vector2.from_angle(ang - deg_to_rad(142.0)) * 8.0
		draw_colored_polygon(PackedVector2Array([tip, left_v, right_v]), Color(0.25, 0.98, 1.0))
		draw_polyline(PackedVector2Array([tip, left_v, right_v, tip]), Color(0.05, 0.10, 0.16), 1.6)

	# 11. Compass & Scale Bar
	var comp := Vector2(size.x - 28.0, 26.0)
	draw_circle(comp, 16.0, Color(0.08, 0.10, 0.15, 0.85))
	draw_arc(comp, 16.0, 0.0, TAU, 24, Color(0.45, 0.55, 0.70, 0.8), 1.2)
	_draw_label_centered(font, comp + Vector2(0, -10), "N", 10, Color(1.0, 0.84, 0.35))
	_draw_label_centered(font, comp + Vector2(11, 3), "E", 9, Color(0.8, 0.85, 0.9))
	_draw_label_centered(font, comp + Vector2(0, 13), "S", 9, Color(0.8, 0.85, 0.9))
	_draw_label_centered(font, comp + Vector2(-11, 3), "O", 9, Color(0.8, 0.85, 0.9))

	var bar_len := 10.0 * sc
	var bar_p := Vector2(14.0, size.y - 14.0)
	draw_line(bar_p, bar_p + Vector2(bar_len, 0), Color(0.85, 0.90, 0.96, 0.8), 2.0)
	draw_line(bar_p + Vector2(0, -4), bar_p + Vector2(0, 4), Color(0.85, 0.90, 0.96, 0.8), 1.5)
	draw_line(bar_p + Vector2(bar_len, -4), bar_p + Vector2(bar_len, 4), Color(0.85, 0.90, 0.96, 0.8), 1.5)
	draw_string(font, bar_p + Vector2(0, -6), "10 m", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.85, 0.90, 0.96, 0.85))

func _draw_label_centered(font: Font, pos: Vector2, txt: String, fsize: int, col: Color) -> void:
	if font == null or txt == "":
		return
	var sz := font.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize)
	var p := pos + Vector2(-sz.x * 0.5, sz.y * 0.35)
	draw_string(font, p + Vector2(1, 1), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize, Color(0, 0, 0, 0.78))
	draw_string(font, p, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize, col)
