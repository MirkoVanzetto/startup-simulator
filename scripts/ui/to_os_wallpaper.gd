extends ColorRect
## ToOsWallpaper - Sfondo geometrico low-poly ocean-teal/cobalt per TO-OS 26.4 Torino Edition.

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw() -> void:
	if size.x <= 2.0 or size.y <= 2.0:
		return
	var w := size.x
	var h := size.y

	# Base ocean-navy -> deep teal diagonal gradient mesh
	var cols := 5
	var rows := 3
	var dx := w / float(cols)
	var dy := h / float(rows)

	var base_colors: Array[Color] = [
		Color(0.032, 0.075, 0.138, 1.0),
		Color(0.044, 0.125, 0.210, 1.0),
		Color(0.056, 0.195, 0.295, 1.0),
		Color(0.040, 0.155, 0.255, 1.0),
		Color(0.028, 0.088, 0.165, 1.0)
	]

	for iy in range(rows):
		for ix in range(cols):
			var p00 := Vector2(float(ix) * dx, float(iy) * dy)
			var p10 := Vector2(float(ix + 1) * dx, float(iy) * dy)
			var p11 := Vector2(float(ix + 1) * dx, float(iy + 1) * dy)
			var p01 := Vector2(float(ix) * dx, float(iy + 1) * dy)

			# Subtle deterministic facet jitter inside interior vertices
			var jitter := Vector2(sin(float(ix * 7 + iy * 13)) * 18.0, cos(float(ix * 11 + iy * 5)) * 14.0)
			var mid := (p00 + p10 + p11 + p01) * 0.25 + jitter

			var idx0 := (ix + iy) % base_colors.size()
			var idx1 := (ix + iy + 1) % base_colors.size()
			var c_a := base_colors[idx0]
			var c_b := c_a.lerp(base_colors[idx1], 0.45).lightened(0.04 * float((ix + iy) % 2))
			var c_c := c_a.darkened(0.08)
			var c_d := base_colors[idx1].lerp(Color(0.09, 0.36, 0.48), 0.22)

			draw_colored_polygon(PackedVector2Array([p00, p10, mid]), c_a)
			draw_colored_polygon(PackedVector2Array([p10, p11, mid]), c_b)
			draw_colored_polygon(PackedVector2Array([p11, p01, mid]), c_c)
			draw_colored_polygon(PackedVector2Array([p01, p00, mid]), c_d)

			# Crisp low-poly shard highlight lines
			var edge_col := Color(0.28, 0.68, 0.84, 0.085)
			draw_line(p00, mid, edge_col, 1.0)
			draw_line(p10, mid, edge_col, 1.0)
			draw_line(p11, mid, edge_col, 1.0)
			draw_line(p01, mid, edge_col, 1.0)

	# Large diagonal translucent Torino aurora ribbons
	draw_colored_polygon(PackedVector2Array([
		Vector2(-w * 0.05, h * 0.72),
		Vector2(w * 0.42, h * 0.16),
		Vector2(w * 0.68, h * 0.24),
		Vector2(w * 0.18, h * 0.92)
	]), Color(0.14, 0.56, 0.72, 0.11))

	draw_colored_polygon(PackedVector2Array([
		Vector2(w * 0.48, h * 0.88),
		Vector2(w * 0.84, h * 0.12),
		Vector2(w * 1.06, h * 0.22),
		Vector2(w * 0.74, h * 0.98)
	]), Color(0.10, 0.42, 0.62, 0.10))

	# Soft ambient center aura
	draw_circle(Vector2(w * 0.5, h * 0.48), minf(w, h) * 0.42, Color(0.18, 0.64, 0.78, 0.065))

	# Minimalist corner reticle watermark
	var grid_col := Color(0.45, 0.82, 0.96, 0.06)
	var step := 48.0
	var x := step
	while x < w:
		var y := step
		while y < h:
			draw_circle(Vector2(x, y), 1.0, grid_col)
			y += step
		x += step
