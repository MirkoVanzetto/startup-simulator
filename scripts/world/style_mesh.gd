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

# ---------------------------------------------------------------- output
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
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		mesh.surface_set_material(mesh.get_surface_count() - 1, lib.call(key))
		mesh.surface_set_name(mesh.get_surface_count() - 1, key)
	return mesh

