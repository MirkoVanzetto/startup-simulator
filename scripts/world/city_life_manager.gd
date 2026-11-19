class_name CityLifeManager
extends Node3D
## CityLifeManager - Gestisce la vita urbana di Torino (Sezioni 9 & 10):
## - Reazioni dinamiche e micro-movimenti di lavoro degli NPC nei negozi quando il giocatore si avvicina
## - Cittadini in movimento lungo i marciapiedi e le piazze (con animazione Walk)
## - Automobili in movimento lungo Viale Est e Viale Lungo Po

var _pedestrians: Array[Dictionary] = []
var _moving_cars: Array[Dictionary] = []
var _tracked_npcs: Array[Dictionary] = []
var _time_acc: float = 0.0

func setup_city_life(street: Node3D, pizzeria: Node3D = null) -> void:
	var piz := pizzeria
	if piz == null and street and street.get_parent():
		piz = street.get_parent().get_node_or_null("Pizzeria") as Node3D
	_register_standing_npcs(street, piz)
	_spawn_walking_pedestrians()
	_spawn_moving_traffic()


func _register_standing_npcs(street: Node3D, pizzeria: Node3D) -> void:
	var npc_defs := [
		{"node": pizzeria.get_node_or_null("MarioNPC") if pizzeria else null, "shop_id": "pizzeria"},
		{"node": street.find_child("ElenaNPC", true, false), "shop_id": "cafe"},
		{"node": street.find_child("DavideNPC", true, false), "shop_id": "elettronica_componenti"},
		{"node": street.find_child("BrunoNPC", true, false), "shop_id": "panificio"},
		{"node": street.find_child("RosaNPC", true, false), "shop_id": "alimentari"},
		{"node": street.find_child("SabrinaNPC", true, false), "shop_id": "edicola"},
		{"node": street.find_child("BelliniNPC", true, false), "shop_id": ""},
		{"node": street.find_child("AndreaVialeNPC", true, false), "shop_id": ""},
		{"node": street.find_child("FerreroNPC", true, false), "shop_id": ""},
		{"node": street.find_child("ChiaraNPC", true, false), "shop_id": ""}
	]
	for item in npc_defs:
		var n := item["node"] as Node3D
		if n == null:
			continue
		var model := n.get_node_or_null("Model") as Node3D
		var anim: AnimationPlayer = model.find_child("AnimationPlayer", true, false) if model else null
		if anim and anim.has_animation("Idle"):
			anim.play("Idle")
		_tracked_npcs.append({
			"node": n,
			"model": model,
			"anim": anim,
			"base_rot_y": n.rotation.y,
			"shop_id": str(item["shop_id"]),
			"phase": float(_tracked_npcs.size()) * 1.15
		})

func _spawn_walking_pedestrians() -> void:
	var routes := [
		{
			"name": "Pedestrian_SanCarlo_1",
			"waypoints": [Vector3(-3.2, 0.0, 5.5), Vector3(-3.2, 0.0, 17.5), Vector3(3.2, 0.0, 17.5), Vector3(3.2, 0.0, 5.5)],
			"speed": 1.42,
			"style": {"shirt": "shirt_sky", "pants": "denim", "shoes": "sneaker_white", "hair": "hair_brown", "hair_style": "quiff"}
		},
		{
			"name": "Pedestrian_Piazza_2",
			"waypoints": [Vector3(-7.5, 0.0, 16.5), Vector3(-7.5, 0.0, 25.0), Vector3(6.0, 0.0, 25.0), Vector3(6.0, 0.0, 16.5)],
			"speed": 1.34,
			"style": {"female": true, "shirt": "shirt_ruby", "pants": "pants_charcoal", "shoes": "shoe_black", "hair": "hair_blonde", "hair_style": "ponytail"}
		},
		{
			"name": "Pedestrian_Valdocco_3",
			"waypoints": [Vector3(64.0, 0.0, 20.5), Vector3(74.5, 0.0, 20.5), Vector3(74.5, 0.0, 33.5), Vector3(64.0, 0.0, 33.5)],
			"speed": 1.48,
			"style": {"shirt": "hoodie_teal", "pants": "denim", "shoes": "sneaker_white", "hair": "hair_dark", "glasses": true}
		},
		{
			"name": "Pedestrian_Mercato_4",
			"waypoints": [Vector3(71.0, 0.0, 0.5), Vector3(85.0, 0.0, 0.5), Vector3(85.0, 0.0, 8.5), Vector3(71.0, 0.0, 8.5)],
			"speed": 1.38,
			"style": {"female": true, "shirt": "shirt_olive_sage", "pants": "denim", "shoes": "shoe_black", "hair": "hair_chestnut", "hair_style": "bob"}
		},
		{
			"name": "Pedestrian_LungoPo_5",
			"waypoints": [Vector3(-14.0, 0.0, 62.5), Vector3(12.0, 0.0, 62.5), Vector3(36.0, 0.0, 62.5), Vector3(12.0, 0.0, 62.5)],
			"speed": 1.52,
			"style": {"shirt": "shirt_linen_cream", "pants": "suit_navy", "shoes": "leather", "hair": "hair_auburn"}
		},
		{
			"name": "Pedestrian_Parco_6",
			"waypoints": [Vector3(-37.5, 0.0, 34.5), Vector3(-37.5, 0.0, 21.2), Vector3(-42.5, 0.0, 21.2), Vector3(-42.5, 0.0, 9.5), Vector3(-42.5, 0.0, 21.2), Vector3(-37.5, 0.0, 21.2)],
			"speed": 1.38,
			"style": {"shirt": "shirt_oatmeal", "pants": "denim", "shoes": "sneaker_white", "hair": "hair_chestnut", "hair_style": "quiff"}
		},
		{
			"name": "Pedestrian_Miniera_7",
			"waypoints": [Vector3(-49.5, 0.0, -11.5), Vector3(-49.5, 0.0, -16.0), Vector3(-40.5, 0.0, -16.0), Vector3(-40.5, 0.0, -11.5)],
			"speed": 1.35,
			"style": {"shirt": "shirt_sky", "pants": "denim", "shoes": "shoe_black", "hair": "hair_dark", "hat": "hardhat", "vest": "vest_safety"}
		}
	]

	for r in routes:
		var holder := Node3D.new()
		holder.name = str(r["name"])
		var wps: Array = r["waypoints"]
		holder.position = wps[0]
		var init_dir := (wps[1] as Vector3) - (wps[0] as Vector3)
		init_dir.y = 0.0
		if init_dir.length_squared() > 0.001:
			holder.rotation.y = atan2(init_dir.x, init_dir.z)
		add_child(holder)

		VillageProps.add_npc_model(holder, r["style"])
		var model := holder.get_node_or_null("Model") as Node3D
		var anim: AnimationPlayer = model.find_child("AnimationPlayer", true, false) if model else null
		var spd := float(r["speed"])
		if anim:
			if anim.has_animation("Walk"):
				anim.set_meta("base_loop_anim", "Walk")
				anim.speed_scale = clampf(spd / 1.38, 0.8, 1.35)
				anim.play("Walk")
				anim.advance(float(_pedestrians.size()) * 0.19)
			elif anim.has_animation("Idle"):
				anim.set_meta("base_loop_anim", "Idle")
				anim.play("Idle")

		_pedestrians.append({
			"node": holder,
			"model": model,
			"anim": anim,
			"waypoints": wps,
			"target_idx": 1,
			"speed": spd,
			"pause_timer": 0.0,
			"state": "Walk"
		})

func _spawn_moving_traffic() -> void:
	var lanes := [
		{
			"name": "MovingCar_LungoPo_East",
			"start": Vector3(-20.0, 0.0, 56.7),
			"end": Vector3(50.0, 0.0, 56.7),
			"rot_y": PI * 0.5,
			"speed": 6.2,
			"color": "car_cream"
		},
		{
			"name": "MovingCar_LungoPo_West",
			"start": Vector3(50.0, 0.0, 59.3),
			"end": Vector3(-20.0, 0.0, 59.3),
			"rot_y": -PI * 0.5,
			"speed": 5.8,
			"color": "car_sage"
		},
		{
			"name": "MovingCar_VialeEst",
			"start": Vector3(26.5, 0.0, 29.2),
			"end": Vector3(58.0, 0.0, 29.2),
			"rot_y": PI * 0.5,
			"speed": 5.2,
			"color": "car_blue"
		},
		{
			"name": "MovingCar_Miniera_Haul",
			"start": Vector3(-40.2, 0.0, 10.5),
			"end": Vector3(-40.2, 0.0, -7.0),
			"rot_y": PI,
			"speed": 3.4,
			"color": "car_red"
		}
	]

	var wheel_mesh := VillageProps.add_car_wheel_mesh("tire", "steel", 0.30, 0.22)
	var wheel_offsets: Array[Vector3] = [
		Vector3(-0.76, 0.30, -1.06),
		Vector3(0.76, 0.30, -1.06),
		Vector3(-0.76, 0.30, 1.06),
		Vector3(0.76, 0.30, 1.06)
	]

	for l in lanes:
		var car_node := Node3D.new()
		car_node.name = str(l["name"])
		car_node.position = l["start"]
		car_node.rotation.y = float(l["rot_y"])
		var sm := StyleMesh.new()
		VillageProps.add_car_body(sm, Vector3.ZERO, 0.0, str(l["color"]))
		var mi := MeshInstance3D.new()
		mi.name = "Body"
		mi.mesh = sm.to_mesh(Callable(VillageMaterials, "mat"))
		car_node.add_child(mi)

		var wheels: Array[MeshInstance3D] = []
		for wi in range(wheel_offsets.size()):
			var wmi := MeshInstance3D.new()
			wmi.name = "Wheel_%d" % wi
			wmi.mesh = wheel_mesh
			wmi.position = wheel_offsets[wi]
			wmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
			car_node.add_child(wmi)
			wheels.append(wmi)

		add_child(car_node)

		_moving_cars.append({
			"node": car_node,
			"wheels": wheels,
			"start": l["start"],
			"end": l["end"],
			"rot_forward": float(l["rot_y"]),
			"rot_backward": wrapf(float(l["rot_y"]) + PI, -PI, PI),
			"speed": float(l["speed"]),
			"forward": true
		})

func _process(delta: float) -> void:
	if GameManager.current_state == GameManager.GameState.MAIN_MENU or GameManager.current_state == GameManager.GameState.PAUSED:
		return
	_time_acc += delta
	_update_standing_npcs(delta)
	_update_pedestrians(delta)
	_update_moving_cars(delta)

func _update_standing_npcs(delta: float) -> void:
	var player_pos: Vector3 = GameManager.player_node.global_position if is_instance_valid(GameManager.player_node) else Vector3(0, 0, -999)
	for item in _tracked_npcs:
		var n := item["node"] as Node3D
		if not is_instance_valid(n):
			continue
		var model := item["model"] as Node3D
		if not is_instance_valid(model):
			continue
		var base_rot := float(item["base_rot_y"])
		var phase := float(item["phase"])
		var npc_pos := n.global_position
		var dist := npc_pos.distance_to(player_pos)

		if dist < 5.2:
			# Si orienta dolcemente verso il giocatore quando si avvicina
			var dir := (player_pos - npc_pos)
			dir.y = 0.0
			if dir.length_squared() > 0.01:
				var world_target_yaw := atan2(dir.x, dir.z)
				var parent_yaw := n.get_parent_node_3d().global_rotation.y if n.get_parent_node_3d() else 0.0
				var local_target := world_target_yaw - parent_yaw
				var diff := wrapf(local_target - base_rot, -PI, PI)
				diff = clampf(diff, -0.65, 0.65)
				n.rotation.y = lerp_angle(n.rotation.y, base_rot + diff, delta * 4.5)
		else:
			# Micro-rotazione lavorativa coerente col negozio
			var work_sway := sin(_time_acc * 1.1 + phase) * 0.14
			n.rotation.y = lerp_angle(n.rotation.y, base_rot + work_sway, delta * 2.5)

func _set_ped_anim(p: Dictionary, anim_name: String, speed_scale_val: float) -> void:
	var anim := p.get("anim", null) as AnimationPlayer
	if not is_instance_valid(anim):
		return
	anim.speed_scale = speed_scale_val
	if str(p.get("state", "")) == anim_name:
		return
	p["state"] = anim_name
	anim.set_meta("base_loop_anim", anim_name)
	if anim.has_animation(anim_name):
		anim.play(anim_name, 0.16)

func _update_pedestrians(delta: float) -> void:
	for p in _pedestrians:
		var node := p["node"] as Node3D
		if not is_instance_valid(node):
			continue
		var pause := float(p["pause_timer"])
		if pause > 0.0:
			p["pause_timer"] = pause - delta
			_set_ped_anim(p, "Idle", 1.0)
			continue
		var wps: Array = p["waypoints"]
		var tidx := int(p["target_idx"])
		var tgt: Vector3 = wps[tidx]
		var cur := node.position
		var to_tgt := tgt - cur
		to_tgt.y = 0.0
		var dist := to_tgt.length()
		var spd := float(p["speed"])
		if dist <= spd * delta + 0.08:
			node.position = Vector3(tgt.x, 0.0, tgt.z)
			p["target_idx"] = (tidx + 1) % wps.size()
			p["pause_timer"] = 0.95
			_set_ped_anim(p, "Idle", 1.0)
		else:
			var dir := to_tgt / dist
			var target_yaw := atan2(dir.x, dir.z)
			node.rotation.y = lerp_angle(node.rotation.y, target_yaw, minf(1.0, delta * 9.5))
			var yaw_err := absf(wrapf(target_yaw - node.rotation.y, -PI, PI))
			var anim_rate := clampf(spd / 1.38, 0.8, 1.35)
			_set_ped_anim(p, "Walk", anim_rate)
			# Avanza solo dopo essersi allineato alla direzione di marcia: zero slittamento laterale!
			if yaw_err < 0.45:
				var forward_vec := Vector3(sin(node.rotation.y), 0.0, cos(node.rotation.y))
				var step := minf(dist, spd * delta)
				node.position += forward_vec * step
			node.position.y = 0.0

func _update_moving_cars(delta: float) -> void:
	var player_pos: Vector3 = GameManager.player_node.global_position if is_instance_valid(GameManager.player_node) else Vector3(0, 0, -999)
	for c in _moving_cars:
		var node := c["node"] as Node3D
		if not is_instance_valid(node):
			continue
		# Rallenta/si ferma se il giocatore attraversa proprio davanti all'auto
		if node.global_position.distance_to(player_pos) < 3.8:
			continue
		var is_fwd := bool(c["forward"])
		var tgt: Vector3 = c["end"] if is_fwd else c["start"]
		var target_yaw: float = float(c["rot_forward"]) if is_fwd else float(c["rot_backward"])
		node.rotation.y = lerp_angle(node.rotation.y, target_yaw, minf(1.0, delta * 4.2))
		var yaw_err := absf(wrapf(target_yaw - node.rotation.y, -PI, PI))
		if yaw_err > 0.28:
			# Sterzata dolce al capolinea prima di ripartire
			continue
		var cur := node.position
		var to_tgt := tgt - cur
		to_tgt.y = 0.0
		var dist := to_tgt.length()
		var spd := float(c["speed"])
		if dist <= spd * delta + 0.15:
			node.position = Vector3(tgt.x, 0.0, tgt.z)
			c["forward"] = not is_fwd
		else:
			var move_dist := minf(dist, spd * delta)
			node.position += (to_tgt / dist) * move_dist
			var wheel_spin := move_dist / 0.30
			for w in (c["wheels"] as Array):
				if is_instance_valid(w):
					(w as Node3D).rotate_x(wheel_spin)
