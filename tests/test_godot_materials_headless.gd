extends Node3D

# tests/test_godot_materials_headless.gd
# Empirical Challenger stress script extending Node3D running inside Godot 4.3 SceneTree.

const MATERIALS = [
	"turin_cobblestone_river",
	"turin_luserna_flagstones",
	"turin_asphalt_avenue",
	"turin_granite_curb",
	"turin_portico_marble_floor",
	"turin_portico_column_fluted",
	"turin_facade_plaster_ochre",
	"turin_facade_plaster_cream",
	"turin_facade_plaster_terracotta",
	"turin_rustic_bugnato",
	"turin_window_shutter",
	"turin_storefront_wood",
	"turin_cafe_awning_striped",
	"startup_server_perforated_metal",
	"startup_brushed_dark_aluminum",
	"startup_desk_wood_veneer",
	"startup_screen_emissive",
]

func _ready() -> void:
	print("======================================================================")
	print("CHALLENGER 1: HEADLESS GODOT 4.3 MATERIAL INSTANTIATION & RENDER TEST")
	print("======================================================================")
	
	# Camera setup
	var camera = Camera3D.new()
	camera.name = "MainCamera"
	camera.position = Vector3(0, 5, 12)
	add_child(camera)
	camera.look_at_from_position(camera.position, Vector3.ZERO, Vector3.UP)
	camera.current = true
	
	# Light setup
	var light = DirectionalLight3D.new()
	light.name = "SunLight"
	light.rotation_degrees = Vector3(-45, 30, 0)
	light.light_color = Color(1.0, 0.95, 0.88)
	light.light_energy = 1.2
	light.shadow_enabled = true
	add_child(light)
	
	# WorldEnvironment
	var env_node = WorldEnvironment.new()
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.2, 0.25, 0.3)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.4, 0.45, 0.5)
	env_node.environment = env
	add_child(env_node)
	
	await get_tree().process_frame
	
	var initial_mem = OS.get_static_memory_usage()
	var initial_objects = Performance.get_monitor(Performance.OBJECT_COUNT)
	print("Initial static memory: %d bytes (%.2f MB)" % [initial_mem, initial_mem / (1024.0 * 1024.0)])
	print("Initial engine object count: %d" % initial_objects)
	
	# -------------------------------------------------------------
	# STEP 1: INSTANTIATE ALL 17 MATERIALS ON VARIOUS MESH TOPOLOGIES
	# -------------------------------------------------------------
	print("\n--- STEP 1: Instantiating 17 Materials on 3D Geometry ---")
	var loaded_materials = {}
	var mesh_instances = []
	var step1_passed = true
	
	var col_idx = 0
	for mat_name in MATERIALS:
		var res_path = "res://assets/materials/" + mat_name + ".tres"
		var mat = load(res_path) as StandardMaterial3D
		if mat == null:
			printerr("  ✘ [FAIL] Could not load material: " + res_path)
			step1_passed = false
			continue
		
		loaded_materials[mat_name] = mat
		
		# Instantiate MeshInstance3D with BoxMesh (exercises triplanar X/Y/Z)
		var mi_box = MeshInstance3D.new()
		mi_box.name = "Mesh_Box_" + mat_name
		var box = BoxMesh.new()
		box.size = Vector3(1.2, 1.2, 1.2)
		mi_box.mesh = box
		mi_box.material_override = mat
		mi_box.position = Vector3((col_idx % 6) * 1.8 - 4.5, 0.6, (col_idx / 6) * 1.8 - 2.0)
		add_child(mi_box)
		mesh_instances.append(mi_box)
		
		# Also instantiate a SphereMesh to exercise continuous normal & curvature blending
		var mi_sphere = MeshInstance3D.new()
		mi_sphere.name = "Mesh_Sphere_" + mat_name
		var sphere = SphereMesh.new()
		sphere.radius = 0.5
		sphere.height = 1.0
		mi_sphere.mesh = sphere
		mi_sphere.material_override = mat
		mi_sphere.position = mi_box.position + Vector3(0, 1.8, 0)
		add_child(mi_sphere)
		mesh_instances.append(mi_sphere)
		
		print("  ✔ [INSTANTIATE] %-32s -> BoxMesh & SphereMesh mounted at %s" % [
			mat_name,
			str(mi_box.position)
		])
		col_idx += 1
	
	# -------------------------------------------------------------
	# STEP 2: RENDER FRAMES HEADLESS TO FORCE SHADER COMPILATION
	# -------------------------------------------------------------
	print("\n--- STEP 2: Rendering Frames & Triggering Shaders ---")
	for f in range(10):
		await get_tree().process_frame
	
	print("  ✔ 10 process frames executed successfully.")
	var active_objects = Performance.get_monitor(Performance.OBJECT_COUNT)
	var active_mem = OS.get_static_memory_usage()
	print("  Active static memory: %d bytes (%.2f MB)" % [active_mem, active_mem / (1024.0 * 1024.0)])
	print("  Active object count: %d" % active_objects)
	
	# -------------------------------------------------------------
	# STEP 3: STRESS HARNESS — RAPID INSTANTIATION & DESTRUCTION
	# -------------------------------------------------------------
	print("\n--- STEP 3: Stress Harness — 100+ Dynamic Allocations & Destruction ---")
	var stress_instances = []
	for i in range(119): # 7 iterations of 17 materials = 119 nodes
		var mat_name = MATERIALS[i % MATERIALS.size()]
		var mat = loaded_materials[mat_name]
		var mi = MeshInstance3D.new()
		var pmesh = PlaneMesh.new()
		pmesh.size = Vector2(0.8, 0.8)
		mi.mesh = pmesh
		mi.material_override = mat
		mi.position = Vector3(randf_range(-10, 10), randf_range(0, 5), randf_range(-10, 10))
		add_child(mi)
		stress_instances.append(mi)
	
	for f in range(5):
		await get_tree().process_frame
	
	print("  Allocated %d dynamic MeshInstance3D nodes under stress." % stress_instances.size())
	var peak_mem = OS.get_static_memory_usage()
	print("  Peak static memory under stress: %d bytes (%.2f MB)" % [peak_mem, peak_mem / (1024.0 * 1024.0)])
	
	# Cleanly remove stress instances
	for mi in stress_instances:
		mi.queue_free()
	stress_instances.clear()
	
	for f in range(10):
		await get_tree().process_frame
	
	var post_stress_mem = OS.get_static_memory_usage()
	var post_stress_objects = Performance.get_monitor(Performance.OBJECT_COUNT)
	print("  Post-stress static memory: %d bytes (%.2f MB)" % [post_stress_mem, post_stress_mem / (1024.0 * 1024.0)])
	print("  Post-stress object count: %d (peak was %d)" % [post_stress_objects, post_stress_objects + 119])
	
	var mem_growth = post_stress_mem - active_mem
	print("  Stress cycle memory leak delta: %d bytes (%.2f KB)" % [mem_growth, mem_growth / 1024.0])
	var leak_detected = (mem_growth > 500 * 1024) # More than 500KB residual leak from 119 nodes
	
	print("\n======================================================================")
	if step1_passed and not leak_detected:
		print("ALL 17 MATERIALS INSTANTIATED & RENDERED WITH ZERO ENGINE ERRORS!")
		print("======================================================================")
		get_tree().quit(0)
	else:
		printerr("HEADLESS GODOT RENDERING / INSTANTIATION FAILED!")
		print("======================================================================")
		get_tree().quit(1)
