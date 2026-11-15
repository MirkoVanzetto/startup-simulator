class_name StyleMesh
extends RefCounted
## StyleMesh - costruttore di geometria low-poly "dipinta" con collisioni accoppiate.
## Ogni forma aggiunta può dichiarare un collider: mesh e collisione nascono dalla
## stessa chiamata, quindi non possono disallinearsi (niente clipping).

var _surf: Dictionary = {}          # chiave materiale -> {v,n,uv,i}
var colliders: Array = []           # {type, pos, size|r|h, surface, tag}
var uv_origin: Vector3 = Vector3.ZERO

func _s(key: String) -> Dictionary:
	if not _surf.has(key):
		_surf[key] = {"v": PackedVector3Array(), "n": PackedVector3Array(), "uv": PackedVector2Array(), "i": PackedInt32Array()}
	return _surf[key]

func is_empty() -> bool:
	return _surf.is_empty()

# ---------------------------------------------------------------- primitive base
func quad(key: String, a: Vector3, b: Vector3, c: Vector3, d: Vector3, uv_mul: Vector2 = Vector2.ONE) -> void:
	var n := (b - a).cross(c - a)
	if n.length() < 0.000001:
		n = (c - a).cross(d - a)
	if n.length() < 0.000001:
		return
	n = n.normalized()
	_emit_quad(key, [a, b, c, d], n, uv_mul)

func tri(key: String, a: Vector3, b: Vector3, c: Vector3, uv_mul: Vector2 = Vector2.ONE) -> void:
	var n := (b - a).cross(c - a)
	if n.length() < 0.000001:
		return
	n = n.normalized()
	var s := _s(key)
	var base: int = s["v"].size()
	for p in [a, b, c]:
		s["v"].append(p)
		s["n"].append(n)
		s["uv"].append(_uv(p, n, a, b - a, uv_mul))
	s["i"].append_array([base, base + 2, base + 1])

func _uv(p: Vector3, n: Vector3, a: Vector3, edge_u: Vector3, uv_mul: Vector2) -> Vector2:
	var w := p + uv_origin
	var an := n.abs()
	var r: Vector2
	if an.x > 0.999:
		r = Vector2(w.z, -w.y)
	elif an.y > 0.999:
		r = Vector2(w.x, w.z)
	elif an.z > 0.999:
		r = Vector2(w.x, -w.y)
	else:
		var u_dir := edge_u.normalized()
		if absf(u_dir.dot(n)) > 0.9:
			u_dir = n.cross(Vector3.UP).normalized()
		var v_dir := n.cross(u_dir).normalized()
		r = Vector2((p - a).dot(u_dir), (p - a).dot(v_dir)) + Vector2(a.x + a.z, a.y)
	return Vector2(r.x * uv_mul.x, r.y * uv_mul.y)

func _emit_quad(key: String, p: Array, n: Vector3, uv_mul: Vector2) -> void:
	var s := _s(key)
	var base: int = s["v"].size()
	var edge_u: Vector3 = p[1] - p[0]
	for q in p:
		s["v"].append(q)
		s["n"].append(n)
		s["uv"].append(_uv(q, n, p[0], edge_u, uv_mul))
	s["i"].append_array([base, base + 2, base + 1, base, base + 3, base + 2])

## Esaedro generico. Ordine corner: 0(-,-,-) 1(+,-,-) 2(+,-,+) 3(-,-,+) 4(-,+,-) 5(+,+,-) 6(+,+,+) 7(-,+,+)
func hexa(key: String, p: Array, top_key: String = "", skip: Array = []) -> void:
	var faces := {
		"px": [2, 1, 5, 6], "nx": [0, 3, 7, 4], "py": [7, 6, 5, 4],
		"ny": [0, 1, 2, 3], "pz": [3, 2, 6, 7], "nz": [1, 0, 4, 5]
	}
	for f in faces:
		if f in skip:
			continue
		var idx: Array = faces[f]
		var k := key
		if f == "py" and top_key != "":
			k = top_key
		quad(k, p[idx[0]], p[idx[1]], p[idx[2]], p[idx[3]])

func box(key: String, center: Vector3, size: Vector3, opts: Dictionary = {}) -> void:
	var rot: float = opts.get("rot", 0.0)
	var hx := size.x * 0.5
	var hy := size.y * 0.5
	var hz := size.z * 0.5
	var corners: Array = []
	var signs := [[-1, -1, -1], [1, -1, -1], [1, -1, 1], [-1, -1, 1], [-1, 1, -1], [1, 1, -1], [1, 1, 1], [-1, 1, 1]]
	for sg in signs:
		var local := Vector3(sg[0] * hx, sg[1] * hy, sg[2] * hz)
		if rot != 0.0:
			local = local.rotated(Vector3.UP, rot)
		corners.append(center + local)
	hexa(key, corners, opts.get("top", ""), opts.get("skip", []))
	if opts.get("col", false):
		add_collider_box(center, size, rot, opts.get("surface", ""), opts.get("tag", ""))

func add_collider_box(center: Vector3, size: Vector3, rot: float = 0.0, surface: String = "", tag: String = "") -> void:
	colliders.append({"type": "box", "pos": center, "size": size, "rot": rot, "surface": surface, "tag": tag})

func add_collider_cyl(center: Vector3, radius: float, height: float, tag: String = "") -> void:
	colliders.append({"type": "cyl", "pos": center, "r": radius, "h": height, "rot": 0.0, "surface": "", "tag": tag})

## Wedge / tetto a capanna: base rettangolare w x d (centro base = center), altezza h.
## ridge_x=true: colmo lungo X (la sezione triangolare sta nel piano YZ).
func gable(slope_key: String, gable_key: String, center: Vector3, w: float, d: float, h: float, ridge_x: bool = true) -> void:
	var hx := w * 0.5
	var hz := d * 0.5
	var y0 := center.y
	var y1 := center.y + h
	if ridge_x:
		var a := center + Vector3(-hx, 0, -hz)
		var b := center + Vector3(hx, 0, -hz)
		var c := center + Vector3(hx, 0, hz)
		var dd := center + Vector3(-hx, 0, hz)
		var r0 := Vector3(center.x - hx, y1, center.z)
		var r1 := Vector3(center.x + hx, y1, center.z)
		# falda fronte (+z): normale verso +z/+y
		quad(slope_key, dd, c, r1, r0)
		# falda retro (-z)
		quad(slope_key, b, a, r0, r1)
		# timpani laterali
		tri(gable_key, a, dd, r0)
		tri(gable_key, c, b, r1)
		quad(gable_key, a, b, c, dd)
	else:
		var a2 := center + Vector3(-hx, 0, -hz)
		var b2 := center + Vector3(hx, 0, -hz)
		var c2 := center + Vector3(hx, 0, hz)
		var d2 := center + Vector3(-hx, 0, hz)
		var r2 := Vector3(center.x, y1, center.z - hz)
		var r3 := Vector3(center.x, y1, center.z + hz)
		quad(slope_key, c2, b2, r2, r3)   # falda destra (+x)
		quad(slope_key, a2, d2, r3, r2)   # falda sinistra (-x)
		tri(gable_key, d2, c2, r3)        # timpano fronte
		tri(gable_key, b2, a2, r2)        # timpano retro
		_bottom_cap(gable_key, center, hx, hz)

func _bottom_cap(key: String, c: Vector3, hx: float, hz: float) -> void:
	# Normale verso -Y, vista da sotto in senso orario
	quad(key, c + Vector3(-hx, 0, -hz), c + Vector3(hx, 0, -hz), c + Vector3(hx, 0, hz), c + Vector3(-hx, 0, hz))

## Tetto a padiglione (4 falde) base w x d, altezza h; colmo lungo l'asse maggiore.
func hip_roof(key: String, center: Vector3, w: float, d: float, h: float) -> void:
	var hx := w * 0.5
	var hz := d * 0.5
	var a := center + Vector3(-hx, 0, -hz)
	var b := center + Vector3(hx, 0, -hz)
	var c := center + Vector3(hx, 0, hz)
	var dd := center + Vector3(-hx, 0, hz)
	if w >= d:
		var inset := hz
		var r0 := center + Vector3(-hx + inset, h, 0)
		var r1 := center + Vector3(hx - inset, h, 0)
		quad(key, dd, c, r1, r0)
		quad(key, b, a, r0, r1)
		tri(key, a, dd, r0)
		tri(key, c, b, r1)
	else:
		var inset2 := hx
		var r2 := center + Vector3(0, h, -hz + inset2)
		var r3 := center + Vector3(0, h, hz - inset2)
		quad(key, c, b, r2, r3)
		quad(key, a, dd, r3, r2)
		tri(key, dd, c, r3)
		tri(key, b, a, r2)
	_bottom_cap(key, center, hx, hz)

# ---------------------------------------------------------------- curve & forme organiche
func cyl(key: String, base: Vector3, r_bottom: float, r_top: float, h: float, sides: int = 10, opts: Dictionary = {}) -> void:
	var s := _s(key)
	var smooth: bool = opts.get("smooth", true)
	var ring_start: int = s["v"].size()
	var circ := TAU * maxf(r_bottom, r_top)
	for k in range(sides + 1):
		var ang := TAU * float(k) / float(sides)
		var dir := Vector3(cos(ang), 0, sin(ang))
		var slope := (r_bottom - r_top) / maxf(h, 0.0001)
		var nrm := Vector3(dir.x, slope, dir.z).normalized()
		var u: float = float(k) / float(sides) * circ * float(opts.get("uv_u", 1.0))
		for j in range(2):
			var rr := r_bottom if j == 0 else r_top
			var p := base + dir * rr + Vector3(0, h * j, 0)
			s["v"].append(p)
			s["n"].append(nrm if smooth else nrm)
			s["uv"].append(Vector2(u, -h * j))
	for k in range(sides):
		var i0 := ring_start + k * 2
		var i1 := ring_start + (k + 1) * 2
		# Winding orario guardando dall'esterno (front-facing in Godot 4)
		s["i"].append_array([i0, i1, i1 + 1, i0, i1 + 1, i0 + 1])
	if opts.get("cap_top", true) and r_top > 0.001:
		_disc(key, base + Vector3(0, h, 0), r_top, sides, true)
	if opts.get("cap_bottom", false) and r_bottom > 0.001:
		_disc(key, base, r_bottom, sides, false)

func _disc(key: String, c: Vector3, r: float, sides: int, up: bool) -> void:
	var s := _s(key)
	var base: int = s["v"].size()
	var n := Vector3.UP if up else Vector3.DOWN
	s["v"].append(c)
	s["n"].append(n)
	s["uv"].append(Vector2(0.5, 0.5))
	for k in range(sides + 1):
		var ang := TAU * float(k) / float(sides)
		s["v"].append(c + Vector3(cos(ang) * r, 0, sin(ang) * r))
		s["n"].append(n)
		s["uv"].append(Vector2(0.5 + cos(ang) * 0.5, 0.5 + sin(ang) * 0.5))
	for k in range(sides):
		if up:
			s["i"].append_array([base, base + 1 + k, base + 2 + k])
		else:
			s["i"].append_array([base, base + 2 + k, base + 1 + k])

## Sfera/blob con normali morbide e leggera deformazione deterministica (chiome, cespugli).
func blob(key: String, center: Vector3, radius: Vector3, rings: int = 5, segs: int = 9, jitter: float = 0.12, seed_val: int = 1) -> void:
	var s := _s(key)
	var rnd := RandomNumberGenerator.new()
	rnd.seed = seed_val
	var base: int = s["v"].size()
	var table: Array = []
	for r in range(rings + 1):
		var row: Array = []
		for k in range(segs):
			row.append(1.0 + (rnd.randf() - 0.5) * 2.0 * jitter)
		table.append(row)
	for r in range(rings + 1):
		var phi := PI * float(r) / float(rings)
		for k in range(segs + 1):
			var th := TAU * float(k) / float(segs)
			var j: float = table[r][k % segs]
			if r == 0 or r == rings:
				j = 1.0
			var dir := Vector3(sin(phi) * cos(th), cos(phi), sin(phi) * sin(th))
			var p := center + Vector3(dir.x * radius.x, dir.y * radius.y, dir.z * radius.z) * j
			s["v"].append(p)
			s["n"].append(Vector3(dir.x / maxf(radius.x, 0.001), dir.y / maxf(radius.y, 0.001), dir.z / maxf(radius.z, 0.001)).normalized())
			s["uv"].append(Vector2(float(k) / segs * 2.0, float(r) / rings * 2.0))
	for r in range(rings):
		for k in range(segs):
			var i0 := base + r * (segs + 1) + k
			var i1 := i0 + 1
			var i2 := i0 + (segs + 1)
			var i3 := i2 + 1
			s["i"].append_array([i0, i2, i1, i1, i2, i3])

## Ellissoide liscio (per teste, nasi, occhi, spalle, mani, scarpe arrotondate) con rotazione opzionale.
func ellipsoid(key: String, center: Vector3, radii: Vector3, rings: int = 8, segs: int = 14, rot_euler: Vector3 = Vector3.ZERO) -> void:
	var s := _s(key)
	var base: int = s["v"].size()
	var b := Basis.from_euler(rot_euler) if rot_euler != Vector3.ZERO else Basis.IDENTITY
	for r in range(rings + 1):
		var phi := PI * float(r) / float(rings)
		var sp := sin(phi)
		var cp := cos(phi)
		for k in range(segs + 1):
			var th := TAU * float(k) / float(segs)
			var local_p := Vector3(sp * cos(th) * radii.x, cp * radii.y, sp * sin(th) * radii.z)
			var local_n := Vector3(sp * cos(th) / maxf(radii.x, 0.001), cp / maxf(radii.y, 0.001), sp * sin(th) / maxf(radii.z, 0.001)).normalized()
			s["v"].append(center + b * local_p)
			s["n"].append((b * local_n).normalized())
			s["uv"].append(Vector2(float(k) / segs, float(r) / rings))
	for r in range(rings):
		for k in range(segs):
			var i0 := base + r * (segs + 1) + k
			var i1 := i0 + 1
			var i2 := i0 + (segs + 1)
			var i3 := i2 + 1
			s["i"].append_array([i0, i2, i1, i1, i2, i3])

## Segmento a capsula/tronco di cono orientato tra due giunti (p0 -> p1) con calotte sferiche alle estremità.
func capsule_seg(key: String, p0: Vector3, p1: Vector3, r0: float, r1: float, segs: int = 12, cap0: bool = true, cap1: bool = true) -> void:
	var axis := p1 - p0
	var length := axis.length()
	if length < 0.0005:
		ellipsoid(key, p0, Vector3(r0, r0, r0), 6, segs)
		return
	var up_dir := axis / length
	var ref := Vector3.FORWARD if absf(up_dir.dot(Vector3.UP)) > 0.9 else Vector3.UP
	var x_dir := ref.cross(up_dir).normalized()
	var z_dir := x_dir.cross(up_dir).normalized()
	var slope := (r0 - r1) / length

	var s := _s(key)
	var base: int = s["v"].size()
	for k in range(segs + 1):
		var ang := TAU * float(k) / float(segs)
		var radial := x_dir * cos(ang) + z_dir * sin(ang)
		var nrm := (radial + up_dir * slope).normalized()
		s["v"].append(p0 + radial * r0)
		s["n"].append(nrm)
		s["uv"].append(Vector2(float(k) / segs, 0.0))
		s["v"].append(p1 + radial * r1)
		s["n"].append(nrm)
		s["uv"].append(Vector2(float(k) / segs, length))
	for k in range(segs):
		var i0 := base + k * 2
		var i1 := base + (k + 1) * 2
		s["i"].append_array([i0, i1, i1 + 1, i0, i1 + 1, i0 + 1])

	if cap0:
		ellipsoid(key, p0, Vector3(r0, r0, r0), 5, segs)
	if cap1:
		ellipsoid(key, p1, Vector3(r1, r1, r1), 5, segs)

## Tornio a sezione ovale lungo Y: profile = array di Vector2(radius, y). Perfetto per busti, cappelli, gonne, vasi.
func lathe_oval(key: String, center: Vector3, profile: Array, stretch_x: float = 1.0, stretch_z: float = 1.0, segs: int = 16, rot_y: float = 0.0) -> void:
	if profile.size() < 2:
		return
	var s := _s(key)
	var base: int = s["v"].size()
	var rb := Basis(Vector3.UP, rot_y) if rot_y != 0.0 else Basis.IDENTITY
	for i in range(profile.size()):
		var pt: Vector2 = profile[i]
		var r_cur: float = maxf(pt.x, 0.0005)
		var y_cur: float = pt.y
		var prev_p: Vector2 = profile[maxi(i - 1, 0)]
		var next_p: Vector2 = profile[mini(i + 1, profile.size() - 1)]
		var dy := next_p.y - prev_p.y
		var dr := next_p.x - prev_p.x
		# Normale radiale perpendicolare alla tangente (dr, dy)
		var nr := dy
		var ny := -dr
		var inv_l := 1.0 / maxf(sqrt(nr * nr + ny * ny), 0.0001)
		nr *= inv_l
		ny *= inv_l
		for k in range(segs + 1):
			var ang := TAU * float(k) / float(segs)
			var ca := cos(ang)
			var sa := sin(ang)
			var lp := Vector3(ca * r_cur * stretch_x, y_cur, sa * r_cur * stretch_z)
			var ln := Vector3(ca * nr / maxf(stretch_x, 0.01), ny, sa * nr / maxf(stretch_z, 0.01)).normalized()
			s["v"].append(center + rb * lp)
			s["n"].append((rb * ln).normalized())
			s["uv"].append(Vector2(float(k) / segs, y_cur))
	for i in range(profile.size() - 1):
		for k in range(segs):
			var i0 := base + i * (segs + 1) + k
			var i1 := i0 + 1
			var i2 := i0 + (segs + 1)
			var i3 := i2 + 1
			s["i"].append_array([i0, i1, i2, i1, i3, i2])

## Tubo/ramo continuo lungo una polilinea `points: Array[Vector3]` con raggi variabili `radii: Array[float]`.
func tube_path(key: String, points: Array, radii: Array, segs: int = 8, cap_ends: bool = true, uv_scale_len: float = 1.0) -> void:
	if points.size() < 2 or radii.size() < points.size():
		return
	var s := _s(key)
	var base: int = s["v"].size()
	var prev_x := Vector3.RIGHT
	var prev_z := Vector3.FORWARD
	var dist_acc := 0.0
	for i in range(points.size()):
		var p: Vector3 = points[i]
		var r: float = float(radii[i])
		var tan_dir: Vector3
		if i == 0:
			tan_dir = (points[1] - p)
		elif i == points.size() - 1:
			tan_dir = (p - points[i - 1])
		else:
			tan_dir = (points[i + 1] - points[i - 1])
		if tan_dir.length_squared() < 0.000001:
			tan_dir = Vector3.UP
		tan_dir = tan_dir.normalized()

		if i == 0:
			var ref := Vector3.FORWARD if absf(tan_dir.dot(Vector3.UP)) > 0.9 else Vector3.UP
			prev_x = ref.cross(tan_dir).normalized()
			prev_z = tan_dir.cross(prev_x).normalized()
		else:
			dist_acc += p.distance_to(points[i - 1])
			var ortho := prev_x - tan_dir * prev_x.dot(tan_dir)
			if ortho.length_squared() < 0.0001:
				var ref2 := Vector3.FORWARD if absf(tan_dir.dot(Vector3.UP)) > 0.9 else Vector3.UP
				ortho = ref2.cross(tan_dir)
			prev_x = ortho.normalized()
			prev_z = tan_dir.cross(prev_x).normalized()

		var circ := maxf(TAU * r, 0.25)
		for k in range(segs + 1):
			var ang := TAU * float(k) / float(segs)
			var nrm := (prev_x * cos(ang) + prev_z * sin(ang)).normalized()
			s["v"].append(p + nrm * r)
			s["n"].append(nrm)
			s["uv"].append(Vector2(float(k) / float(segs) * circ, dist_acc * uv_scale_len))

	for i in range(points.size() - 1):
		for k in range(segs):
			var i0 := base + i * (segs + 1) + k
			var i1 := i0 + 1
			var i2 := i0 + (segs + 1)
			var i3 := i2 + 1
			s["i"].append_array([i0, i3, i1, i0, i2, i3])

	if cap_ends:
		var r0: float = float(radii[0])
		if r0 > 0.002:
			ellipsoid(key, points[0], Vector3(r0, r0, r0), 4, segs)
		var r1: float = float(radii[points.size() - 1])
		if r1 > 0.002:
			ellipsoid(key, points[points.size() - 1], Vector3(r1, r1, r1), 4, segs)

## Chioma fogliame 3D costituita da carte incrociate orientate nello spazio (alpha-scissored leaf_cluster).
func foliage_cluster(key: String, center: Vector3, radius: float, seed_val: int = 1, cards: int = 7) -> void:
	var s := _s(key)
	var rnd := RandomNumberGenerator.new()
	rnd.seed = seed_val
	for ci in range(cards):
		var yaw := float(ci) * 2.39996 + rnd.randf_range(-0.28, 0.28)
		var tilt := rnd.randf_range(-0.55, 0.55)
		var roll := rnd.randf_range(-0.45, 0.45)
		var card_w := radius * rnd.randf_range(1.38, 1.82)
		var card_h := radius * rnd.randf_range(1.25, 1.65)
		var off := Vector3(
			cos(yaw) * radius * rnd.randf_range(0.05, 0.36),
			rnd.randf_range(-0.24, 0.28) * radius,
			sin(yaw) * radius * rnd.randf_range(0.05, 0.36)
		)
		var b := Basis.from_euler(Vector3(tilt, yaw, roll))
		var cp := center + off
		var hw := card_w * 0.5
		var hh := card_h * 0.5
		var pts := [
			cp + b * Vector3(-hw, -hh, 0.0),
			cp + b * Vector3(hw, -hh, 0.0),
			cp + b * Vector3(hw, hh, 0.0),
			cp + b * Vector3(-hw, hh, 0.0),
		]
		var nrm := (cp - center).lerp(Vector3.UP, 0.55).normalized()
		if nrm.length_squared() < 0.01:
			nrm = Vector3.UP
		var base: int = s["v"].size()
		var uvs := [Vector2(0.0, 1.0), Vector2(1.0, 1.0), Vector2(1.0, 0.0), Vector2(0.0, 0.0)]
		for qi in range(4):
			s["v"].append(pts[qi])
			s["n"].append(nrm)
			s["uv"].append(uvs[qi])
		s["i"].append_array([base, base + 1, base + 2, base, base + 2, base + 3])

## Ciuffo d'erba e fiori di campo a 3 carte incrociate (base a Y=0, UV.y=0 in alto per oscillazione vento).
func grass_tuft(key: String, pos: Vector3, scale: float = 1.0, rot_y: float = 0.0) -> void:
	var s := _s(key)
	var w := 0.48 * scale
	var h := 0.36 * scale
	for k in range(3):
		var ang := rot_y + float(k) * (PI / 3.0)
		var ax := Vector3(cos(ang), 0.0, sin(ang))
		var perp := Vector3(-sin(ang), 0.0, cos(ang))
		var base: int = s["v"].size()
		var hw := w * 0.5
		var p0 := pos - ax * hw
		var p1 := pos + ax * hw
		var p2 := pos + ax * (hw * 1.12) + perp * (0.04 * scale) + Vector3(0.0, h, 0.0)
		var p3 := pos - ax * (hw * 1.12) + perp * (0.04 * scale) + Vector3(0.0, h, 0.0)
		var nrm := (perp + Vector3.UP * 0.7).normalized()
		var pts := [p0, p1, p2, p3]
		var uvs := [Vector2(0.0, 1.0), Vector2(1.0, 1.0), Vector2(1.0, 0.0), Vector2(0.0, 0.0)]
		for qi in range(4):
			s["v"].append(pts[qi])
			s["n"].append(nrm)
			s["uv"].append(uvs[qi])
		s["i"].append_array([base, base + 1, base + 2, base, base + 2, base + 3])

## Massiccio alpino frattale suddiviso con creste asimmetriche e contrafforti larghi per il terrain shader.
func mountain_peak(key: String, center: Vector3, width: float, depth: float, height: float, seed_val: int = 1) -> void:
	var s := _s(key)
	var nx := 18
	var nz := 18
	var rnd := RandomNumberGenerator.new()
	rnd.seed = seed_val
	var ridge_ang := rnd.randf_range(-0.65, 0.65)
	var ridge_dir := Vector2(cos(ridge_ang), sin(ridge_ang))
	var spur_ang := ridge_ang + rnd.randf_range(0.75, 1.35)
	var ca := cos(ridge_ang * 1.6)
	var sa := sin(ridge_ang * 1.6)
	var sh_off1 := Vector2(rnd.randf_range(-0.34, -0.14), rnd.randf_range(-0.22, 0.22))
	var sh_off2 := Vector2(rnd.randf_range(0.14, 0.36), rnd.randf_range(-0.24, 0.24))

	var grid: Array = []
	for iz in range(nz + 1):
		var row: Array = []
		var fz := (float(iz) / float(nz)) * 2.0 - 1.0
		for ix in range(nx + 1):
			var fx := (float(ix) / float(nx)) * 2.0 - 1.0
			var rx := fx * width * 0.5
			var rz := fz * depth * 0.5
			var d_main := Vector2(fx, fz).length()
			# Bordo dolce e versanti ampi (zero coni appuntiti a piramide!)
			var base_t := clampf(1.0 - maxf(absf(fx), absf(fz)) * 0.14 - d_main * 0.80, 0.0, 1.0)
			var falloff := base_t * base_t * (2.2 - 1.2 * base_t)
			# Cresta principale allungata + due spalle rocciose laterali
			var perp := fx * ridge_dir.y - fz * ridge_dir.x
			var ridge := pow(1.0 - clampf(absf(perp) * 1.05, 0.0, 1.0), 1.45)
			var spur := pow(1.0 - clampf(absf(fx * sin(spur_ang) - fz * cos(spur_ang)) * 1.25, 0.0, 1.0), 1.6)
			var sh1 := pow(clampf(1.0 - Vector2(fx - sh_off1.x, fz - sh_off1.y).length() * 1.15, 0.0, 1.0), 1.35)
			var sh2 := pow(clampf(1.0 - Vector2(fx - sh_off2.x, fz - sh_off2.y).length() * 1.15, 0.0, 1.0), 1.35)
			var saddle := 0.52 + 0.30 * ridge + 0.24 * sh1 + 0.22 * sh2 + 0.14 * spur
			var crag := 0.88 + 0.18 * sin((fx * ca - fz * sa) * 6.8 + float(seed_val)) * cos((fx * sa + fz * ca) * 5.6 + float(seed_val) * 0.7)
			var h_raw := height * falloff * saddle * crag
			# Ammorbidisce le guglie estreme in creste seghettate realistiche
			var h_val := minf(h_raw, height * (0.76 + 0.12 * sin(fx * 9.0 + fz * 7.0 + float(seed_val))))
			if ix == 0 or ix == nx or iz == 0 or iz == nz:
				h_val = 0.0
			row.append(center + Vector3(rx, h_val, rz))
		grid.append(row)

	# Accumula normali morbide sui vertici della griglia (orientate verso +Y)
	var ngrid: Array = []
	for iz in range(nz + 1):
		var nrow: Array = []
		for ix in range(nx + 1):
			nrow.append(Vector3.ZERO)
		ngrid.append(nrow)

	for iz in range(nz):
		for ix in range(nx):
			var p00: Vector3 = grid[iz][ix]
			var p10: Vector3 = grid[iz][ix + 1]
			var p01: Vector3 = grid[iz + 1][ix]
			var p11: Vector3 = grid[iz + 1][ix + 1]
			var n1 := (p11 - p00).cross(p10 - p00)
			var n2 := (p01 - p00).cross(p11 - p00)
			ngrid[iz][ix] += n1 + n2
			ngrid[iz][ix + 1] += n1
			ngrid[iz + 1][ix + 1] += n1 + n2
			ngrid[iz + 1][ix] += n2

	var base: int = s["v"].size()
	for iz in range(nz + 1):
		for ix in range(nx + 1):
			s["v"].append(grid[iz][ix])
			var nn: Vector3 = ngrid[iz][ix]
			s["n"].append(nn.normalized() if nn.length_squared() > 0.0001 else Vector3.UP)
			s["uv"].append(Vector2(float(ix) / float(nx) * 4.0, float(iz) / float(nz) * 4.0))

	for iz in range(nz):
		for ix in range(nx):
			var i0 := base + iz * (nx + 1) + ix
			var i1 := i0 + 1
			var i2 := i0 + (nx + 1)
			var i3 := i2 + 1
			s["i"].append_array([i0, i1, i3, i0, i3, i2])

## Singolo cordolo stradale smussato in pietra con micro-giunto (per viali e marciapiedi realistici).
func beveled_curb_block(key: String, pos: Vector3, length_x: float, width_z: float, height_y: float, rot_y: float = 0.0) -> void:
	var hx := length_x * 0.5
	var hz := width_z * 0.5
	var bev := minf(0.035, minf(length_x, width_z) * 0.14)
	var b := Basis(Vector3.UP, rot_y) if rot_y != 0.0 else Basis.IDENTITY
	var pts := [
		Vector3(-hx, 0.0, -hz), Vector3(hx, 0.0, -hz), Vector3(hx, 0.0, hz), Vector3(-hx, 0.0, hz),
		Vector3(-hx + bev, height_y, -hz + bev), Vector3(hx - bev, height_y, -hz + bev),
		Vector3(hx - bev, height_y, hz - bev), Vector3(-hx + bev, height_y, hz - bev)
	]
	for k in range(8):
		pts[k] = pos + b * pts[k]
	hexa(key, pts, "", ["ny"])

# ---------------------------------------------------------------- output & tangenti PBR
func _compute_tangents(v: PackedVector3Array, n: PackedVector3Array, uv: PackedVector2Array, indices: PackedInt32Array) -> PackedFloat32Array:
	var count := v.size()
	var tan1 := PackedVector3Array()
	var tan2 := PackedVector3Array()
	tan1.resize(count)
	tan2.resize(count)
	for ti in range(0, indices.size(), 3):
		var i0 := indices[ti]
		var i1 := indices[ti + 1]
		var i2 := indices[ti + 2]
		var v0 := v[i0]
		var v1 := v[i1]
		var v2 := v[i2]
		var w0 := uv[i0]
		var w1 := uv[i1]
		var w2 := uv[i2]
		var e1 := v1 - v0
		var e2 := v2 - v0
		var x1 := w1.x - w0.x
		var x2 := w2.x - w0.x
		var y1 := w1.y - w0.y
		var y2 := w2.y - w0.y
		var det := x1 * y2 - x2 * y1
		if absf(det) < 0.000001:
			continue
		var r := 1.0 / det
		var sdir := (e1 * y2 - e2 * y1) * r
		var tdir := (e2 * x1 - e1 * x2) * r
		tan1[i0] += sdir
		tan1[i1] += sdir
		tan1[i2] += sdir
		tan2[i0] += tdir
		tan2[i1] += tdir
		tan2[i2] += tdir

	var tangents := PackedFloat32Array()
	tangents.resize(count * 4)
	for vi in range(count):
		var nn := n[vi].normalized()
		var t := tan1[vi]
		t = t - nn * nn.dot(t)
		if t.length_squared() < 0.00001:
			var fallback := Vector3.RIGHT if absf(nn.dot(Vector3.UP)) > 0.9 else Vector3.UP
			t = fallback.cross(nn)
		t = t.normalized()
		var handedness := -1.0 if nn.cross(t).dot(tan2[vi]) < 0.0 else 1.0
		var o := vi * 4
		tangents[o] = t.x
		tangents[o + 1] = t.y
		tangents[o + 2] = t.z
		tangents[o + 3] = handedness
	return tangents

func to_mesh(lib: Callable) -> ArrayMesh:
	var mesh := ArrayMesh.new()
	for key in _surf:
		var s: Dictionary = _surf[key]
		if s["i"].size() == 0:
			continue
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = s["v"]
		arrays[Mesh.ARRAY_NORMAL] = s["n"]
		arrays[Mesh.ARRAY_TEX_UV] = s["uv"]
		arrays[Mesh.ARRAY_INDEX] = s["i"]
		arrays[Mesh.ARRAY_TANGENT] = _compute_tangents(s["v"], s["n"], s["uv"], s["i"])
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		mesh.surface_set_material(mesh.get_surface_count() - 1, lib.call(key))
		mesh.surface_set_name(mesh.get_surface_count() - 1, key)
	return mesh

