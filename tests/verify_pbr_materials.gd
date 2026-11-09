extends SceneTree

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

const TRIPLANAR_MATERIALS = [
	"turin_cobblestone_river",
	"turin_luserna_flagstones",
	"turin_granite_curb",
	"turin_portico_marble_floor",
	"turin_portico_column_fluted",
	"turin_facade_plaster_ochre",
	"turin_facade_plaster_cream",
	"turin_facade_plaster_terracotta",
	"turin_rustic_bugnato",
	"turin_storefront_wood",
	"startup_server_perforated_metal",
	"startup_brushed_dark_aluminum",
	"startup_desk_wood_veneer",
]

func _init():
	print("============================================================")
	print("VERIFYING PBR MATERIALS IN GODOT 4.3 HEADLESS...")
	print("============================================================")
	
	var all_passed = true
	var total_checked = 0
	
	for mat_name in MATERIALS:
		total_checked += 1
		var res_path = "res://assets/materials/" + mat_name + ".tres"
		var mat = load(res_path) as StandardMaterial3D
		
		if mat == null:
			printerr("[FAIL] Material failed to load: " + res_path)
			all_passed = false
			continue
			
		var checks = []
		
		# Check textures
		if mat.albedo_texture == null:
			checks.append("Missing Albedo")
		if mat.normal_texture == null:
			checks.append("Missing Normal")
		if not mat.normal_enabled:
			checks.append("Normal disabled")
		if mat.roughness_texture == null:
			checks.append("Missing Roughness")
		if mat.ao_texture == null:
			checks.append("Missing AO")
		if not mat.ao_enabled:
			checks.append("AO disabled")
		if mat.metallic_texture == null:
			checks.append("Missing Metallic")
			
		# Check emissive for startup_screen_emissive
		if mat_name == "startup_screen_emissive":
			if not mat.emission_enabled:
				checks.append("Emission disabled")
			if mat.emission_texture == null:
				checks.append("Missing Emission Texture")
			if mat.emission_energy_multiplier < 1.0:
				checks.append("Low emission energy: " + str(mat.emission_energy_multiplier))
				
		# Check triplanar configuration
		var should_triplanar = mat_name in TRIPLANAR_MATERIALS
		if should_triplanar:
			if not mat.uv1_triplanar:
				checks.append("Expected uv1_triplanar=true")
			if abs(mat.uv1_triplanar_sharpness - 4.0) > 0.01:
				checks.append("Expected triplanar_sharpness=4.0, got " + str(mat.uv1_triplanar_sharpness))
		else:
			if mat.uv1_triplanar:
				checks.append("Expected uv1_triplanar=false")
				
		if checks.size() == 0:
			print(" [PASS] %-35s | Alb:OK Nrm:OK Rgh:OK AO:OK Met:OK Triplanar:%-5s Filter:%d" % [
				mat_name,
				str(mat.uv1_triplanar),
				mat.texture_filter
			])
		else:
			printerr(" [FAIL] %-35s | ERRORS: %s" % [mat_name, ", ".join(checks)])
			all_passed = false
			
	print("============================================================")
	if all_passed:
		print("ALL %d PBR MATERIALS VERIFIED SUCCESSFULLY IN GODOT 4.3!" % total_checked)
		print("============================================================")
		quit(0)
	else:
		printerr("VERIFICATION FAILED FOR ONE OR MORE MATERIALS!")
		print("============================================================")
		quit(1)
